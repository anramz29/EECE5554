% Load mural images
imageDir = fullfile(pwd);
buildingScene = imageDatastore(imageDir, 'FileExtensions', '.jpg', ...
    'IncludeSubfolders', false);
muralFiles = buildingScene.Files(contains(buildingScene.Files, 'R15_overlap_'));
buildingScene = imageDatastore(muralFiles);

figure;
montage(buildingScene.Files)
saveas(gcf, 'overlap_montage_15.jpg');

numImages = numel(buildingScene.Files);
tforms(numImages) = projtform2d;
imageSize = zeros(numImages, 2);

% Initialize features for first image
I = readimage(buildingScene, 1);
grayImage = im2double(im2gray(I));
imageSize(1,:) = size(grayImage);
[r, c, ~] = harris(grayImage, 500, 'tile', [4 4]);
points = cornerPoints([c, r]);
[features, points] = extractFeatures(grayImage, points);

% Loop over remaining images
for n = 2:numImages
    pointsPrevious = points;
    featuresPrevious = features;

    I = readimage(buildingScene, n);
    grayImage = im2double(im2gray(I));
    imageSize(n,:) = size(grayImage);

    [r, c, ~] = harris(grayImage, 500, 'tile', [4 4]);
    points = cornerPoints([c, r]);
    [features, points] = extractFeatures(grayImage, points);

    indexPairs = matchFeatures(features, featuresPrevious, ...
        'MatchThreshold', 80, 'MaxRatio', 0.9, 'Unique', true);
    
    fprintf('Image %d: %d matches\n', n, size(indexPairs,1));

    matchedPoints = points(indexPairs(:,1), :);
    matchedPointsPrev = pointsPrevious(indexPairs(:,2), :);

    if size(indexPairs,1) < 4
        fprintf('Not enough matches for image %d, using previous transform\n', n);
        tforms(n).A = tforms(n-1).A;
    else
        tforms(n) = estgeotform2d(matchedPoints, matchedPointsPrev, ...
            'projective', 'Confidence', 99.9, 'MaxNumTrials', 2000, 'MaxDistance', 4);
        tforms(n).A = tforms(n-1).A * tforms(n).A;
    end
end

% Center the panorama
for idx = 1:numel(tforms)
    [xlim(idx,:), ylim(idx,:)] = outputLimits(tforms(idx), ...
        [1 imageSize(idx,2)], [1 imageSize(idx,1)]);
end

avgXLim = mean(xlim, 2);
[~, idx] = sort(avgXLim);
centerIdx = floor((numel(tforms)+1)/2);
centerImageIdx = idx(centerIdx);
Tinv = invert(tforms(centerImageIdx));
for idx = 1:numel(tforms)
    tforms(idx).A = Tinv.A * tforms(idx).A;
end

% Build panorama
for idx = 1:numel(tforms)
    [xlim(idx,:), ylim(idx,:)] = outputLimits(tforms(idx), ...
        [1 imageSize(idx,2)], [1 imageSize(idx,1)]);
end

maxImageSize = max(imageSize);
xMin = min([1; xlim(:)]);
xMax = max([maxImageSize(2); xlim(:)]);
yMin = min([1; ylim(:)]);
yMax = max([maxImageSize(1); ylim(:)]);

width  = round(xMax - xMin);
height = round(yMax - yMin);

I = readimage(buildingScene, 1);
panorama = zeros([height width 3], 'like', I);
panoramaView = imref2d([height width], [xMin xMax], [yMin yMax]);

for idx = 1:numImages
    I = readimage(buildingScene, idx);
    warpedImage = imwarp(I, tforms(idx), 'OutputView', panoramaView);
    mask = imwarp(true(size(I,1), size(I,2)), tforms(idx), 'OutputView', panoramaView);
    panorama = imblend(warpedImage, panorama, mask, 'foregroundopacity', 1);
end

figure;
imshow(panorama)
imwrite(panorama, 'overlap_mosaic_15.jpg');
title('Mural Mosaic')
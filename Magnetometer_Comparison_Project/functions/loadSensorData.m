function [magX, magY, magZ, fs] = loadSensorData(filepath, sensor)
% Loads magnetometer CSV and returns data in uT
% sensor: 'iphone' or 'vn100'

    data = readtable(filepath);

    switch lower(sensor)
        case 'iphone'
            magX = data.x;
            magY = data.y;
            magZ = data.z;
        case 'vn100'
            magX = data.mag_x * 1e6;
            magY = data.mag_y * 1e6;
            magZ = data.mag_z * 1e6;
        otherwise
            error('Unknown sensor type: %s. Use iphone or vn100.', sensor);
    end

    if ismember('timestamp', data.Properties.VariableNames)
        dt = mean(diff(double(data.timestamp))) * 1e-9;
    else
        dt = mean(diff(data.seconds_elapsed));
    end
    fs = 1/dt;

    fprintf('Loaded: %s | Sensor: %s | Samples: %d | Rate: %.1f Hz\n', ...
        filepath, sensor, length(magX), fs);
end
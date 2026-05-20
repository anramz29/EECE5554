% Intrinsic and Extrinsic Camera Parameters
%
% This script file can be directly executed under Matlab to recover the camera intrinsic and extrinsic parameters.
% IMPORTANT: This file contains neither the structure of the calibration objects nor the image coordinates of the calibration points.
%            All those complementary variables are saved in the complete matlab data file Calib_Results.mat.
% For more information regarding the calibration model visit http://www.vision.caltech.edu/bouguetj/calib_doc/


%-- Focal length:
fc = [ 4651.960048078674845 ; 4643.060464080722340 ];

%-- Principal point:
cc = [ 2127.790924211311449 ; 2714.287082687376369 ];

%-- Skew coefficient:
alpha_c = 0.000000000000000;

%-- Distortion coefficients:
kc = [ 0.052778123793803 ; -0.086703819873354 ; -0.003816766905597 ; 0.000539461212622 ; 0.000000000000000 ];

%-- Focal length uncertainty:
fc_error = [ 165.219014774266498 ; 160.252936160588575 ];

%-- Principal point uncertainty:
cc_error = [ 34.722452071026034 ; 101.578417019381618 ];

%-- Skew coefficient uncertainty:
alpha_c_error = 0.000000000000000;

%-- Distortion coefficients uncertainty:
kc_error = [ 0.020090793982742 ; 0.047570357913312 ; 0.002764258464963 ; 0.002531869981869 ; 0.000000000000000 ];

%-- Image size:
nx = 4284;
ny = 5712;


%-- Various other variables (may be ignored if you do not use the Matlab Calibration Toolbox):
%-- Those variables are used to control which intrinsic parameters should be optimized

n_ima = 5;						% Number of calibration images
est_fc = [ 1 ; 1 ];					% Estimation indicator of the two focal variables
est_aspect_ratio = 1;				% Estimation indicator of the aspect ratio fc(2)/fc(1)
center_optim = 1;					% Estimation indicator of the principal point
est_alpha = 0;						% Estimation indicator of the skew coefficient
est_dist = [ 1 ; 1 ; 1 ; 1 ; 0 ];	% Estimation indicator of the distortion coefficients


%-- Extrinsic parameters:
%-- The rotation (omc_kk) and the translation (Tc_kk) vectors for every calibration image and their uncertainties

%-- Image #1:
omc_1 = [ 2.110146e+00 ; 2.106760e+00 ; -1.546016e-01 ];
Tc_1  = [ -9.145154e+01 ; -1.506040e+02 ; 3.464162e+02 ];
omc_error_1 = [ 7.286822e-03 ; 7.205250e-03 ; 1.256441e-02 ];
Tc_error_1  = [ 2.624027e+00 ; 7.185732e+00 ; 1.245916e+01 ];

%-- Image #2:
omc_2 = [ 2.154541e+00 ; 2.175690e+00 ; -1.486497e-01 ];
Tc_2  = [ -1.253153e+02 ; -1.200187e+02 ; 3.667749e+02 ];
omc_error_2 = [ 5.946230e-03 ; 6.753219e-03 ; 1.329735e-02 ];
Tc_error_2  = [ 2.751849e+00 ; 7.762023e+00 ; 1.295064e+01 ];

%-- Image #3:
omc_3 = [ 1.938051e+00 ; 1.906655e+00 ; -5.375783e-01 ];
Tc_3  = [ -1.030285e+02 ; -1.680247e+02 ; 3.813809e+02 ];
omc_error_3 = [ 1.246678e-02 ; 1.375066e-02 ; 1.853492e-02 ];
Tc_error_3  = [ 2.879153e+00 ; 8.128066e+00 ; 1.298976e+01 ];

%-- Image #4:
omc_4 = [ 7.183537e-01 ; 2.757216e+00 ; -7.688940e-01 ];
Tc_4  = [ 6.030954e+01 ; -1.663071e+02 ; 4.759268e+02 ];
omc_error_4 = [ 4.818924e-03 ; 1.440770e-02 ; 2.627598e-02 ];
Tc_error_4  = [ 3.535189e+00 ; 1.019485e+01 ; 1.613944e+01 ];

%-- Image #5:
omc_5 = [ 2.177740e+00 ; 2.180222e+00 ; 1.331516e-02 ];
Tc_5  = [ -9.733814e+01 ; -1.212866e+02 ; 2.590800e+02 ];
omc_error_5 = [ 5.704082e-03 ; 5.129682e-03 ; 1.098944e-02 ];
Tc_error_5  = [ 1.991919e+00 ; 5.624681e+00 ; 9.012619e+00 ];


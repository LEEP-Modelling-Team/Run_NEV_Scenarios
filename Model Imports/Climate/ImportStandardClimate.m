%% ImportStandardClimate.m
% ========================
% Author: Mattia Mancini
% Last modified: 22/11/2021 by Mattia Mancini
%
% DESCRIPTION
% Import the climate data required for running all of the NEV modules.
% This needs to be run any time the climate scenario of interest is
% changed. More details available within the function fcn_import_climate.m
% called in this script.
% ------------------------------------------------------------------------

%% (0) Set up
%  ==========
clear

% (a) Database connection
% -----------------------
server_flag = false;
conn = fcn_connect_database(server_flag);

% Set path for the climate import output
SetDataPaths;
Climate_data_mat = strcat(climate_data_folder, 'Climate_data.mat');

% (b) Set climate of interest
% ---------------------------
climate_scenario = 'rcp60';
pct_temp = 50;
pct_rain = 50;

%% (1) RUN CLIMATE IMPORT 
%  ======================
ClimateData = fcn_import_climate(conn, climate_scenario, pct_temp, pct_rain);

%% (2) SAVE ON DISK
%  =================
save(Climate_data_mat, 'ClimateData', '-mat', '-v7.3');




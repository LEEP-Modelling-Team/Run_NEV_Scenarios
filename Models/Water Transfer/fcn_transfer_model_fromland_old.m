function subctch_lu = fcn_transfer_model_fromland_old(water_transfer_data_folder, ...
                                                      subctch_info, ...
                                                      decade_str)

% !!! this is old code - use fcn_transfer_model_fromland
% !!! this calls to R and runs the model object (slow)
                                                  
%% (1) Set up data needed to run models
%  ====================================
% (a) Set up decade-dependent info
% --------------------------------
switch decade_str
    case '_20'
        weather_folder = '2020';
        ndays = 3653;
    case '_30'
        weather_folder = '2030';
        ndays = 3652;
    case '_40'
        weather_folder = '2040';
        ndays = 3653;
    case '_50'
        weather_folder = '2050';
        ndays = 3652;
end

% (b) Load and prepare weather data
% ---------------------------------
% Read precipitation data for selected subcatchment
fileID = fopen([water_transfer_data_folder, ...
                'Weather/', ...
                weather_folder, ...
                '/p', ...
                subctch_info.subctch_id{1}, ...
                '.txt']);
rain = fscanf(fileID, '%f');
fclose(fileID);

% Calculate 1-5 day lags, apply log(pcp + 1) transformation, save to table
lagged_rain = lagmatrix(rain, 0:5);
lagged_rain = lagged_rain(6:end, :);
lagged_rain = log(lagged_rain + 1);
subctch_log1pcp = array2table(lagged_rain, ...
                              'VariableNames', ...
                              {'log1pcp', 'log1pcp1', 'log1pcp2', 'log1pcp3', 'log1pcp4', 'log1pcp5'});

% Read maximum temperature data for selected subcatchment                          
fileID = fopen([water_transfer_data_folder, ...
                'Weather/', ...
                weather_folder, ...
                '/tmax', ...
                subctch_info.subctch_id{1}, ...
                '.txt']);
maxtmp = fscanf(fileID, '%f');
fclose(fileID);

% Save to table
subctch_maxtmp = array2table(maxtmp, 'VariableNames', {'maxtmp'});                       

% (c) Combine weather data with subcatchment info
% -----------------------------------------------
% (area and land use, repeated for ndays)
lu_mod_data = [repmat(subctch_info(:, 2:end), ndays, 1), subctch_log1pcp, subctch_maxtmp];

%% (2) Run land use flow transfer model by calling R code
%  ======================================================
% (a) Set path where files will be temporarily saved
% --------------------------------------------------
% This is how we communicate between R and MATLAB
path_to_temp_save = 'C:/Temp/';

% (b) Write model data table to .csv file
% ---------------------------------------
% Use random number between 1 and 1 billion in file name to make file naming
% different every time
% Check file/number does not already exist
% Could be better way to do this...
while true
    random_string = num2str(randi(1e+9));    
    random_filename = [path_to_temp_save, 'lu_mod_data', random_string, '.csv'];
    if ~isfile(random_filename)
        writetable(lu_mod_data, random_filename);
        break
    else
        % File already exists, try different random number
    end
end

% (c) Run model by executing R script
% -----------------------------------
% See 'predict_flow_lu_matlab.R' for more info
% path_to_temp_save must be set in this function too, and must match
% Set up Rscript command to call to R
% Use date string as argument

% Water quantity (flow)
command = ['"C:/Program Files/R/R-3.6.1/bin/Rscript" ' ...
           '"C:/Users/neo204/OneDrive - University of Exeter/NEV/Models/Water Transfer/predict_flow_lu_from_matlab.R" ', ...
           random_string];
system(command);

% Water quality
command = ['"C:/Program Files/R/R-3.6.1/bin/Rscript" ' ...
           '"C:/Users/neo204/OneDrive - University of Exeter/NEV/Models/Water Transfer/predict_wq_lu_from_matlab.R" ', ...
           random_string];
system(command);

% (d) Retrieve model predictions from .csv file
% ---------------------------------------------
% Store in subctch_lu structure
% Set 9999 values back to NaN

% flow
subctch_lu.flow = csvread([path_to_temp_save, 'flow_lu_mod_pred', random_string, '.csv'], 1, 0);
subctch_lu.flow(subctch_lu.flow == 9999) = NaN;

% orgn
subctch_lu.orgn = csvread([path_to_temp_save, 'orgn_lu_mod_pred', random_string, '.csv'], 1, 0);
subctch_lu.orgn(subctch_lu.orgn == 9999) = NaN;

% orgp
subctch_lu.orgp = csvread([path_to_temp_save, 'orgp_lu_mod_pred', random_string, '.csv'], 1, 0);
subctch_lu.orgp(subctch_lu.orgp == 9999) = NaN;

% no3
subctch_lu.no3 = csvread([path_to_temp_save, 'no3_lu_mod_pred', random_string, '.csv'], 1, 0);
subctch_lu.no3(subctch_lu.no3 == 9999) = NaN;

% no2
% No land use component, set to zero
subctch_lu.no2 = zeros(size(subctch_lu.orgn));

% nh4
% No land use component, set to zero
subctch_lu.nh4 = zeros(size(subctch_lu.orgn));

% minp
subctch_lu.minp = csvread([path_to_temp_save, 'minp_lu_mod_pred', random_string, '.csv'], 1, 0);
subctch_lu.minp(subctch_lu.minp == 9999) = NaN;

% disox
subctch_lu.disox = csvread([path_to_temp_save, 'disox_lu_mod_pred', random_string, '.csv'], 1, 0);
subctch_lu.disox(subctch_lu.disox == 9999) = NaN;

% (e) Delete CSV files created
% ----------------------------
% Model predictions
delete([path_to_temp_save, 'flow_lu_mod_pred', random_string, '.csv'])
delete([path_to_temp_save, 'orgn_lu_mod_pred', random_string, '.csv'])
delete([path_to_temp_save, 'orgp_lu_mod_pred', random_string, '.csv'])
delete([path_to_temp_save, 'no3_lu_mod_pred', random_string, '.csv'])
delete([path_to_temp_save, 'minp_lu_mod_pred', random_string, '.csv'])
delete([path_to_temp_save, 'disox_lu_mod_pred', random_string, '.csv'])

% Model data
delete([path_to_temp_save, 'lu_mod_data', random_string, '.csv'])

end
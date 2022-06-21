function subctch_lu = fcn_transfer_model_fromland(water_transfer_data_folder, ...
                                                  subctch_info, ...
                                                  decade_str, ...
                                                  models_lu)

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

% Read maximum temperature data for selected subcatchment                          
fileID = fopen([water_transfer_data_folder, ...
                'Weather/', ...
                weather_folder, ...
                '/tmax', ...
                subctch_info.subctch_id{1}, ...
                '.txt']);
maxtmp = fscanf(fileID, '%f');
fclose(fileID);

% (c) Set up linear terms
% -----------------------
Xlinear = repmat([subctch_info.p_watr, ...
                  subctch_info.p_urml, ...
                  subctch_info.p_rnge, ...
                  subctch_info.p_frst, ...
                  subctch_info.p_past, ...
                  subctch_info.p_agrl, ...
                  subctch_info.p_wwht, ...
                  subctch_info.p_wbar, ...
                  subctch_info.p_canp, ...
                  subctch_info.p_pota, ...
                  subctch_info.p_sgbt, ...
                  subctch_info.p_corn, ...
                  subctch_info.p_oats, ...
                  log(subctch_info.sbsn_area)], ndays, 1);

% (d) Set up smooth terms
% -----------------------
smooth_names = {'log1pcp', 'log1pcp1', 'log1pcp2', 'log1pcp3', 'log1pcp4', 'log1pcp5', 'maxtmp'};

smooth_terms = [lagged_rain, maxtmp];
smooth_terms = array2table(smooth_terms, 'VariableNames', smooth_names);

Xsmooth_flow = fcn_create_Xsmooth(models_lu.flow.flow_test, smooth_terms, smooth_names, ndays);
Xsmooth_orgn = fcn_create_Xsmooth(models_lu.orgn.transfer, smooth_terms, smooth_names, ndays);
Xsmooth_orgp = fcn_create_Xsmooth(models_lu.orgp.transfer, smooth_terms, smooth_names, ndays);
Xsmooth_no3 = fcn_create_Xsmooth(models_lu.no3.transfer, smooth_terms, smooth_names, ndays);
Xsmooth_minp = fcn_create_Xsmooth(models_lu.minp.transfer, smooth_terms, smooth_names, ndays);
Xsmooth_disox = fcn_create_Xsmooth(models_lu.disox.transfer, smooth_terms, smooth_names, ndays);

% (e) Model predictions
% ---------------------
% flow
subctch_lu.flow = exp([Xlinear, Xsmooth_flow] * models_lu.flow.flow_test.coef);

% orgn
subctch_lu.orgn = exp([Xlinear, Xsmooth_orgn] * models_lu.orgn.transfer.coef);

% orgp
subctch_lu.orgp = exp([Xlinear, Xsmooth_orgp] * models_lu.orgp.transfer.coef);

% no3
subctch_lu.no3 = exp([Xlinear, Xsmooth_no3] * models_lu.no3.transfer.coef);

% no2
% No land use component, set to zero
subctch_lu.no2 = zeros(size(subctch_lu.flow));

% nh4
% No land use component, set to zero
subctch_lu.nh4 = zeros(size(subctch_lu.flow));

% minp
subctch_lu.minp = exp([Xlinear, Xsmooth_minp] * models_lu.minp.transfer.coef);

% disox
subctch_lu.disox = exp([Xlinear, Xsmooth_disox] * models_lu.disox.transfer.coef);


end
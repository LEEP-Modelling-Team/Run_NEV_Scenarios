% ImportBiodiversityUCLold
% ========================
% Author: Nathan Owen
% Last modified: 18/09/2019
% Import all data required for running the UCL biodiversity models. Store
% in Biodiversity structure in a .mat file, to be loaded from within 
% fcn_run_biodiversity_ucl_old.m

% NB. this is for the old set of models, i.e. just pollinator species and
% no principal component analysis regression

%% (0) Set up
%  ==========
clear

% (a) Flags
% ---------
csv_calls_flag = false;          % Load, prepare and save data
test_function_flag = true;      % Test model

% (b) Database connection
% -----------------------
server_flag = false;
conn = fcn_connect_database(server_flag);

% (c) Set paths for storing imported data
% ---------------------------------------
SetDataPaths;

%% (1) Load, prepare and save data
%  ===============================
if csv_calls_flag
    tic
    
    % Set file name for storing data
    NEVO_Biodiversity_data_mat = strcat(biodiversity_data_folder, 'NEVO_Biodiversity_UCL_data_old.mat');
    
    % (a) Grid cell data needed for the models
    % ----------------------------------------
    % Firstly, variables from seer data table
    % Note: coast, fwater, marine, ocean converted to [0,400] hectare scale
    % Note: tbarley_10 and tosr_10 converted to logical where positive
    sqlquery = ['SELECT new2kid, ' ...
                    '4 * coast_07 AS coast_ha, ', ...
                    '4 * fwater_07 AS fwater_ha, ', ...
                    '4 * marine_07 AS marine_ha, ', ...
                    '4 * ocean AS ocean_ha, ', ...
                    'tbarley_10 > 0 AS mask_tbarley, ', ...
                    'tosr_10 > 0 AS mask_tosr ', ...
                'FROM seer.seer_landuse ORDER BY new2kid'];
    setdbprefs('DataReturnFormat','table');
    dataReturn = fetch(exec(conn, sqlquery));
    data_cells1 = dataReturn.Data;
    
    % Secondly, data from nevo data table
    % Note: specifically these are proportions for splitting land uses into
    % subcategories, eg. wood_ha into fwood_ha and nfwood_ha
    sqlquery = ['SELECT ' ...
                    'new2kid, ' ...
                    'p_fwood, ' ...
                    'p_maize, ' ...
                    'p_othcer, ' ...
                    'p_hort, ' ...
                    'p_othcrps, ' ...
                    'p_othfrm, ' ...
                    'p_wosr, ' ...
                    'p_sosr ' ...
                'FROM nevo.nevo_variables ORDER BY new2kid'];
    setdbprefs('DataReturnFormat','table');
    dataReturn  = fetch(exec(conn,sqlquery));
    data_cells2 = dataReturn.Data;
    
%     % Check new2kid cells match in both cases
%     isequal(data_cells1.new2kid, data_cells2.new2kid)
         
    % Save new2kid cells separately
    Biodiversity.new2kid = data_cells1.new2kid;
    
    % Rest goes into Biodiversity.Data_cells table
    Biodiversity.Data_cells = [data_cells1(:, 2:end), data_cells2(:, 2:end)];
    
    % (b) Coefficients and thresholds for the 472 pollinator models
    % -------------------------------------------------------------
    % Note: Prepared by Henry Ferguson-Gow (UCL)
    filename    = 'poll_landuse_parameters.csv';
    sheetIn     = 1;
    rangeIn     = 'A2:RE29';
    
    [Data, ~, ~] = xlsread(strcat(biodiversity_data_folder, filename), sheetIn, rangeIn); 
    Data(isnan(Data)) = 0;
    
    Biodiversity.Coefficients_Pollinators   = Data(2:end, 1:end);
    Biodiversity.Thresholds_Pollinators     = Data(1, 1:end);
    
    %% !!! priority species coefficients to go here !!!
    
    % (c) Climate envelope masks for the 472 pollinators
    % --------------------------------------------------
    % Note: Prepared by Henry Ferguson-Gow (UCL)
    % Current climate envelope
    filename    = 'poll_climate_now.csv';
    Data = table2array(readtable(strcat(biodiversity_data_folder, filename), 'TreatAsEmpty', 'NA'));
    Data        = sortrows(Data,1); % Sort Rows by New2kid
    Biodiversity.Mask_Pollinators_cells_now = Data(:,2:end);
    
    % Climate envelope for RCP 6.0 scenario in decades 2020-2029, 
    % 2030-2039, 2040-2049, 2050-2059
    filename    = 'poll_climate_rcp60_21t30.csv';
    Data = table2array(readtable(strcat(biodiversity_data_folder, filename), 'TreatAsEmpty', 'NA'));
    Data        = sortrows(Data,1); % Sort Rows by New2kid
    Biodiversity.Mask_Pollinators_cells_rcp60_20 = Data(:,2:end);
    
    filename    = 'poll_climate_rcp60_31t40.csv';
    Data = table2array(readtable(strcat(biodiversity_data_folder, filename), 'TreatAsEmpty', 'NA'));
    Data        = sortrows(Data,1); % Sort Rows by New2kid
    Biodiversity.Mask_Pollinators_cells_rcp60_30 = Data(:,2:end);
    
    filename    = 'poll_climate_rcp60_41t50.csv';
    Data = table2array(readtable(strcat(biodiversity_data_folder, filename), 'TreatAsEmpty', 'NA'));
    Data        = sortrows(Data,1); % Sort Rows by New2kid
    Biodiversity.Mask_Pollinators_cells_rcp60_40 = Data(:,2:end);
    
    filename    = 'poll_climate_rcp60_51t60.csv';
    Data = table2array(readtable(strcat(biodiversity_data_folder, filename), 'TreatAsEmpty', 'NA'));
    Data        = sortrows(Data,1); % Sort Rows by New2kid
    Biodiversity.Mask_Pollinators_cells_rcp60_50 = Data(:,2:end);

    % Climate envelope for RCP 8.5 scenario in decades 2020-2029, 
    % 2030-2039, 2040-2049, 2050-2059
    filename    = 'poll_climate_rcp85_21t30.csv';
    Data = table2array(readtable(strcat(biodiversity_data_folder, filename), 'TreatAsEmpty', 'NA'));
    Data        = sortrows(Data,1); % Sort Rows by New2kid
    Biodiversity.Mask_Pollinators_cells_rcp85_20 = Data(:,2:end);
    
    filename    = 'poll_climate_rcp85_31t40.csv';
    Data = table2array(readtable(strcat(biodiversity_data_folder, filename), 'TreatAsEmpty', 'NA'));
    Data        = sortrows(Data,1); % Sort Rows by New2kid
    Biodiversity.Mask_Pollinators_cells_rcp85_30 = Data(:,2:end);
    
    filename    = 'poll_climate_rcp85_41t50.csv';
    Data = table2array(readtable(strcat(biodiversity_data_folder, filename), 'TreatAsEmpty', 'NA'));
    Data        = sortrows(Data,1); % Sort Rows by New2kid
    Biodiversity.Mask_Pollinators_cells_rcp85_40 = Data(:,2:end);
    
    filename    = 'poll_climate_rcp85_51t60.csv';
    Data = table2array(readtable(strcat(biodiversity_data_folder, filename), 'TreatAsEmpty', 'NA'));
    Data        = sortrows(Data,1); % Sort Rows by New2kid
    Biodiversity.Mask_Pollinators_cells_rcp85_50 = Data(:,2:end);
    
    %% !!! Priority species climate masks to go here !!!
    
    % Save data in Biodiversity structure to .mat file
    save(NEVO_Biodiversity_data_mat, 'Biodiversity', '-mat', '-v6')
    
    toc
end

%% (2) Test function
%  =================
if test_function_flag
    % (a) Set climate scenario string
    % -------------------------------
    parameters = fcn_set_parameters();
%     climate_scen_string = 'current';
    climate_scen_string = parameters.clim_scen_string;
%     climate_scen_string = 'rcp85';
    
    % (b) Set up landuses table
    % -------------------------
    switch climate_scen_string
        case 'current'
            sqlquery = ['SELECT ', ...
                            'new2kid, ', ...
                            '4 * urban_07 AS urban_ha, ', ...
                            '4 * grsnfrm_10 AS sngrass_ha, ', ...
                            '4 * (nfwood_10 + fwood_10) AS wood_ha, ', ...
                            '4 * permg_10 AS pgrass_ha, ', ...
                            '4 * tempg_10 AS tgrass_ha, ', ...
                            '4 * rgraz_10 AS rgraz_ha, ', ...
                            '4 * wheat_10 AS wheat_ha, ', ...
                            '4 * wbarley_10 AS wbar_ha, ', ...
                            '4 * (sbarley_10 + tbarley_10) AS sbar_ha, ', ...
                            '4 * pots_10 AS pot_ha, ', ...
                            '4 * sugarbeet_10 AS sb_ha, ', ...
                            '4 * (tosr_10 + sosr_10 + wosr_10) AS osr_ha, ', ...
                            '4 * (othcer_10 + maize_10 + hort_10 + othfrm_10 + othcrps_10) AS other_ha ', ...
                        'FROM seer.seer_landuse ORDER BY new2kid'];
            setdbprefs('DataReturnFormat','table');
            dataReturn  = fetch(exec(conn,sqlquery));
            landuses = dataReturn.Data;
        case {'rcp60', 'rcp85'}
            sqlquery = ['SELECT ', ...
                            'new2kid, ', ...
                            'wood_ha, ', ...
                            'urban_ha, ', ...
                            'sngrass_ha, ', ...                    
                            'wheat_ha_20, wheat_ha_30, wheat_ha_40, wheat_ha_50, ', ...
                            'osr_ha_20, osr_ha_30, osr_ha_40, osr_ha_50, ', ...
                            'wbar_ha_20, wbar_ha_30, wbar_ha_40, wbar_ha_50, ', ...
                            'sbar_ha_20, sbar_ha_30, sbar_ha_40, sbar_ha_50, ', ...
                            'pot_ha_20, pot_ha_30, pot_ha_40, pot_ha_50, ', ...
                            'sb_ha_20, sb_ha_30, sb_ha_40, sb_ha_50, ', ...
                            'other_ha_20, other_ha_30, other_ha_40, other_ha_50, ', ...
                            'pgrass_ha_20, pgrass_ha_30, pgrass_ha_40, pgrass_ha_50, ', ...
                            'tgrass_ha_20, tgrass_ha_30, tgrass_ha_40, tgrass_ha_50, ', ...
                            'rgraz_ha_20, rgraz_ha_30, rgraz_ha_40, rgraz_ha_50 ', ...
                        'FROM nevo_explore.explore_2km ORDER BY new2kid'];
            setdbprefs('DataReturnFormat','table');
            dataReturn  = fetch(exec(conn,sqlquery));
            landuses = dataReturn.Data;
        otherwise
            error('Please choose a climate scenario from ''current'', ''rcp60'' or ''rcp85''.')
    end
    
    % (c) Run model
    % -------------
    tic
        es_biodiversity_ucl = fcn_run_biodiversity_ucl_old(biodiversity_data_folder, landuses, climate_scen_string, 'baseline');
    toc
end

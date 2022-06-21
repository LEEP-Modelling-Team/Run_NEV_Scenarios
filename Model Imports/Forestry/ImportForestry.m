% ImportForestry
% ==============
% Author: Brett Day, Nathan Owen, Amy Binner
% Last modified: 26/05/2020
% Import all data required for running the NEV forestry and forestry 
% greenhouse gas models. Store in ForestTimber and ForestGHG structures in
% .mat files, to be loaded from within fcn_run_forestry.m.

%% (0) Set up
%  ==========
clear 

% (a) Flags
% ---------
database_calls_flag = true;
test_function_flag = true;

% (b) Database connection
% -----------------------
server_flag = false;
conn = fcn_connect_database(server_flag);

% (c) Set paths for storing imported data
% ---------------------------------------
SetDataPaths;

%% (1) Load, prepare and save data
%  ===============================
if database_calls_flag
    % (a) Set filenames for storing imported data
    % -------------------------------------------
    NEVO_ForestTimber_data_mat = strcat(forest_data_folder, 'NEVO_ForestTimber_data.mat');
    NEVO_ForestGHG_data_mat = strcat(forestghg_data_folder, 'NEVO_ForestGHG_data.mat');
    
    % (b) Import forestry timber and forestry GHG data
    % ------------------------------------------------
    tic
        [ForestTimber, es_forestry] = ImportForestTimber(conn, ...
                                                         climate_data_folder, ...
                                                         'ukcp18', ...
                                                         'rcp60', ... 
                                                         50, ... 
                                                         50, ...
                                                         2020, ...
                                                         2060);
        ForestGHG = ImportForestGHG(conn, ForestTimber, es_forestry);
    toc
    
    % (c) Save data in structures to .mat files
    % -----------------------------------------
    save(NEVO_ForestTimber_data_mat, 'ForestTimber', 'es_forestry', '-mat', '-v6')
    save(NEVO_ForestGHG_data_mat, 'ForestGHG', '-mat', '-v6')
end

%% (2) Test function
%  =================
if test_function_flag
    run_baseline = false;
    run_scenario = true;
    
    % BASELINE RUN OF FORESTRY MODEL
    if run_baseline
        % (a) Set up forestry model parameters
        % ------------------------------------
        parameters = fcn_set_parameters();
        
        % (b) Set up land use changes
        % ---------------------------
        % Load new2kid cells
        sqlquery = 'SELECT new2kid FROM nevo.nevo_variables ORDER BY new2kid';
        setdbprefs('DataReturnFormat', 'numeric');
        dataReturn  = fetch(exec(conn, sqlquery));
        landuses_chg.new2kid = dataReturn.Data;
        num_cells = length(landuses_chg.new2kid);
        
        % Set up land use changes - all zero in baseline
        landuses_chg.wood_ha_chg = zeros(num_cells, 1);
        landuses_chg.sngrass_ha_chg = zeros(num_cells, 1);
        landuses_chg.arable_ha_chg = zeros(num_cells, 1);
        landuses_chg.tgrass_ha_chg = zeros(num_cells, 1);
        landuses_chg.pgrass_ha_chg = zeros(num_cells, 1);
        landuses_chg.rgraz_ha_chg = zeros(num_cells, 1);
        
        % (c) Set up carbon price
        % -----------------------
        carbon_price = fcn_get_carbon_price(conn, parameters.carbon_price)
        
        % (e) Run forestry function
        % -------------------------
        tic
            es_forestry = fcn_run_forestry(forest_data_folder, forestghg_data_folder, parameters, landuses_chg, carbon_price);
        toc
    end
    
    % SCENARIO RUN OF FORESTRY MODEL
    if run_scenario
        % (a) Run agriculture model first
        % -------------------------------
        % Set paths to agriculture model data
        SetDataPaths; 
        
        % Set up agriculture model parameters
        agparam = fcn_set_parameters();
        agparam.run_ghg = false;
        
        % Set up landuses for agriculture model
        sqlquery = ['SELECT ', ...
                        'new2kid, ', ...
                        'farm_ha, ', ...
                        'wood_ha, ', ...
                        'sngrass_ha ', ...
                    'FROM nevo.nevo_variables ORDER BY new2kid'];
        setdbprefs('DataReturnFormat','table');
        dataReturn  = fetch(exec(conn,sqlquery));
        landuses = dataReturn.Data;
        num_cells = size(landuses, 1);
        
        % Run agriculture model
        es_agriculture = fcn_run_agriculture(agriculture_data_folder, ...
                                             climate_data_folder,...
                                             agricultureghg_data_folder, ...
                                             agparam, ...
                                             landuses); 
        
        % (b) Run forestry model
        % ----------------------
        frstparam = fcn_set_parameters();
        
        % (b) Set up land use changes
        % ---------------------------
        landuses_chg.new2kid = landuses.new2kid;
        
        % E.g. all arable land to woodland
        arable_20 = mean(es_agriculture.arable_ha(:, 1:10), 2);
        landuses_chg.arable_ha_chg = -arable_20;
        landuses_chg.wood_ha_chg = arable_20;
        landuses_chg.sngrass_ha_chg = zeros(num_cells, 1);
        landuses_chg.tgrass_ha_chg = zeros(num_cells, 1);
        landuses_chg.pgrass_ha_chg = zeros(num_cells, 1);
        landuses_chg.rgraz_ha_chg = zeros(num_cells, 1);
        
        % (c) Set up carbon price
        % -----------------------
        % Use non_trade_central value from greenbook.c02_val_2018 table_ext
        parameters = fcn_set_parameters();
        carbon_price = fcn_get_carbon_price(conn, parameters.carbon_price);
        
        % (e) Run forestry function
        % -------------------------
        tic
            es_forestry = fcn_run_forestry(forest_data_folder, forestghg_data_folder, frstparam, landuses_chg, carbon_price);
        toc
    end
end

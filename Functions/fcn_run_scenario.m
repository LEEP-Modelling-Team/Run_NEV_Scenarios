%% fcn_run_scenario.m
%  ==================
%  Author: Mattia Mancini, Rebecca Collins
%  Created: 25 Feb 2022
%  Last modified: 11 Jul 2022
%  ---------------------------------------
%
%  DESCRIPTION
%  Wrapper function to run selected models in the NEV suite of models based
%  on a land use and set of parameters specified in the arguments. This is
%  used to run scenario analyses where the scenario is a land use array for
%  the whole or a specified subset of the cells in the SEER 2km grid.
%  Scenarios can be baseline scenarios (e.g. current land uses from land
%  cover maps), or hypothetical ones, again described in terms of a land
%  use map.
% =========================================================================

function  [benefits, costs, env_outs, es_outs] = fcn_run_scenario(model_flags, ...
                                     parameters, ...
                                     baseline_landuse, ...
                                     scenario_landuse)
    %% (0) SETUP
    %  =========
    % (a) Database connection
    % -----------------------
    
    disp('Running model imports')
    disp('---------------------')
    server_flag = false;
    conn = fcn_connect_database(server_flag);

    % (b) Run model imports if needed
    % -------------------------------
    fcn_run_imports(model_flags, parameters, conn);
    
    % (c) Deal with land uses passed
    %  -----------------------------
    baseline_land_cover = fcn_prepare_landuses(baseline_landuse, model_flags, conn);
    if exist('scenario_landuse', 'var')
        scenario_land_cover = fcn_prepare_landuses(scenario_landuse, model_flags, conn);
        
        % deal with the case in which woodland has increased. In this case,
        % new woodland added to the baseline is assumed to be managed, and
        % hence the wood_mgmt_ha as well as the proportions change from
        % the baseline. The 'fcn_prepare_landuse' function calculates
        % proportions based on the data passed. AAA: if data on managed
        % woodland is passed in both baseline and scenario, but the change
        % between baseline and scenario wood_ha is not equal to the change 
        % beteen baseline and scenario wood_mgmt_ha, then the function will
        % overwrite wood_mgmt_ha to be equal to the change in wood_ha to
        % guarantee that only managed woodland is created. This is because
        % the GHG forestry model cannot estimate changes in GHG emissions
        % from the introduction of unmanaged woodland. 
        scenario_land_cover  = fcn_adjust_woodland(baseline_land_cover, scenario_land_cover);
        
        if height(scenario_land_cover) ~= height(baseline_land_cover)
            error('baseline and scenario land covers have different numbers of cell!')
        end
    end
    
    % Cells in the study area
    cell_info.new2kid = baseline_land_cover.new2kid;
    cell_info.ncells = length(cell_info.new2kid);   


    %% (1) RUN AGRICULTURAL MODEL
    %      1.1. Run the Agricultural model
    %      1.2. Identify unique land use changes
    %  =========================================
    disp('Running agricultural model')
    disp('--------------------------')

    % 1.1. Run agricultural model with the specified GHG model flag
    % -------------------------------------------------------------
    parameters.run_ghg = model_flags.run_ghg;
    carbon_price = fcn_get_carbon_price(conn, parameters.carbon_price);

    [ag_data_path, climate_data_path, ghg_data_path] = fcn_create_path(parameters);
    
    
    es_agriculture_baseline = fcn_run_agriculture(ag_data_path, ...
                                             climate_data_path, ...
                                             ghg_data_path, ...
                                             parameters, ...
                                             model_flags, ...
                                             baseline_land_cover, ...
                                             carbon_price);
    
    % add output to baseline structure
    baseline.es_agriculture = es_agriculture_baseline;
    baseline.ghg_farm = es_agriculture_baseline.ghg_farm;

   
    % run scenario if exists
    if exist('scenario_landuse', 'var')
        es_agriculture_scenario = fcn_run_agriculture(ag_data_path, ...
                                             climate_data_path, ...
                                             ghg_data_path, ...
                                             parameters, ...
                                             model_flags, ...
                                             scenario_land_cover, ...
                                             carbon_price);
        
        % add output to scenario structure
        scenario.es_agriculture = es_agriculture_scenario;
        scenario.ghg_farm = es_agriculture_scenario.ghg_farm;
    end
    
    % 1.2. Identify unique land use changes based on land uses passed 
    % ---------------------------------------------------------------
    % Possible land use changes
    options = parameters.options;
    % Identify for each cell the option/s implemented
    disp('Identifying land use changes by cell')
    disp('------------------------------------')
    tic
    scenario_opts = fcn_find_option(options, scenario_land_cover, baseline_land_cover, baseline, scenario);
    toc

    % Identify unique options that happen on the landscape
    [~, col] = find(table2array(scenario_opts));
    unique_opts = unique(col);
    unique_opts(1) = [];
    unique_opts = scenario_opts.Properties.VariableNames(unique_opts);

    % land use change for all unique options
    lcs_scenario_options = fcn_calc_option_lc(options, unique_opts, baseline_land_cover, scenario_land_cover, baseline, scenario);                                                            
    
    % Hectares in each unique option
    num_ha = zeros(cell_info.ncells, 1);
    for i = 1:numel(unique_opts)
        option = unique_opts{i};
        ha_option = lcs_scenario_options.(option).hectares;
        num_ha = num_ha + ha_option;
    end

    
    %% (2) RUN FORESTRY MODULE
    %  ========================
    if model_flags.run_forestry
        disp('Running forestry model')
        disp('----------------------')

        
        % 2.1. Baseline forestry
        % ----------------------
        % Set land use changes to pass to the forestry model
        num_cells = cell_info.ncells;
        landuses_chg.new2kid = baseline_land_cover.new2kid;
        landuses_chg.wood_ha_chg = zeros(num_cells, 1);
        landuses_chg.sngrass_ha_chg = zeros(num_cells, 1);
        landuses_chg.arable_ha_chg = zeros(num_cells, 1);
        landuses_chg.tgrass_ha_chg = zeros(num_cells, 1);
        landuses_chg.pgrass_ha_chg = zeros(num_cells, 1);
        landuses_chg.rgraz_ha_chg = zeros(num_cells, 1);
        
        % Run forestry function (carbon prices have been defined above)
        tic
            es_forestry_baseline = fcn_run_forestry(parameters, ...
                                                    baseline_land_cover, ...
                                                    landuses_chg, ...
                                                    carbon_price);
        toc
        
        % Add forestry output to baseline structure
        baseline.es_forestry = es_forestry_baseline;
        baseline.timber_mixed_ann = es_forestry_baseline.Timber.ValAnn.Mix6040;
        baseline.timber_mixed_benefit_ann = es_forestry_baseline.Timber.BenefitAnn.Mix6040;
        baseline.timber_mixed_cost_ann = es_forestry_baseline.Timber.CostAnn.Mix6040;
        baseline.timber_mixed_fixed_cost = es_forestry_baseline.Timber.FixedCost.Mix6040;
        baseline.ghg_mixed_yr = es_forestry_baseline.TimberC.QntYr.Mix6040;
        baseline.ghg_mixed_yrUB = es_forestry_baseline.TimberC.QntYrUB.Mix6040;
        baseline.ghg_mixed_ann = es_forestry_baseline.TimberC.ValAnn.Mix6040;

        
        
        % 2.2. Scenario Forestry
        % ----------------------
        if exist('scenario_landuse', 'var')
            
            % compute land use change to pass to the forestry model
            baseline_highlevel = baseline_land_cover(:, {'new2kid', 'farm_ha', ...
                                                     'wood_ha', 'wood_mgmt_ha', ...
                                                     'sng_ha', 'urban_ha', ...
                                                     'water_ha'}); 
            scenario_highlevel = scenario_land_cover(:, {'new2kid', 'farm_ha', ...
                                                     'wood_ha', 'wood_mgmt_ha', ...
                                                     'sng_ha', 'urban_ha', ...
                                                     'water_ha'}); 
            baseline_aggr_lc = fcn_collect_output_simple(baseline_highlevel, es_agriculture_baseline);                        
            scenario_aggr_lc = fcn_collect_output_simple(scenario_highlevel, es_agriculture_scenario);
            
            
            landuses_chg.new2kid = baseline_land_cover.new2kid;
            landuses_chg.wood_ha_chg = scenario_aggr_lc.wood_ha - baseline_aggr_lc.wood_ha;
            landuses_chg.sngrass_ha_chg = scenario_aggr_lc.sngrass_ha - baseline_aggr_lc.sngrass_ha;
            landuses_chg.arable_ha_chg = scenario_aggr_lc.arable_ha_20 - baseline_aggr_lc.arable_ha_20;
            landuses_chg.tgrass_ha_chg = scenario_aggr_lc.tgrass_ha_20 - baseline_aggr_lc.tgrass_ha_20;
            landuses_chg.pgrass_ha_chg = scenario_aggr_lc.pgrass_ha_20 - baseline_aggr_lc.pgrass_ha_20;
            landuses_chg.rgraz_ha_chg = scenario_aggr_lc.rgraz_ha_20 - baseline_aggr_lc.rgraz_ha_20;
            tic
            es_forestry_scenario = fcn_run_forestry(parameters, ...
                                                    baseline_land_cover, ...
                                                    landuses_chg, ...
                                                    carbon_price);
            toc
           
            % Add forestry output to scenario structure
            scenario.es_forestry = es_forestry_scenario;
            scenario.timber_mixed_ann = es_forestry_scenario.Timber.ValAnn.Mix6040;
            scenario.timber_mixed_benefit_ann = es_forestry_scenario.Timber.BenefitAnn.Mix6040;
            scenario.timber_mixed_cost_ann = es_forestry_scenario.Timber.CostAnn.Mix6040;
            scenario.timber_mixed_fixed_cost = es_forestry_scenario.Timber.FixedCost.Mix6040;
            scenario.ghg_mixed_yr = es_forestry_scenario.TimberC.QntYr.Mix6040;
            scenario.ghg_mixed_yrUB = es_forestry_scenario.TimberC.QntYrUB.Mix6040;
            scenario.ghg_mixed_ann = es_forestry_scenario.TimberC.ValAnn.Mix6040;
        end
    end

    %% (3) RUN BIODIVERSITY MODULE (JNCC)
    %  ==================================
    if model_flags.run_biodiversity
        disp('Running biodiversity model')
        disp('--------------------------')
        % 3.1 JNCC baseline biodiversity
        % ------------------------------
        bio_baseline_lc = fcn_create_jncc_lc(baseline_land_cover, es_agriculture_baseline, parameters.biodiversity_climate_string);       
        es_baseline_jncc = fcn_run_biodiversity_jncc(parameters.biodiversity_data_folder_jncc, ...
                                                         bio_baseline_lc, ... 
                                                         parameters.biodiversity_climate_string, ...
                                                         parameters.other_ha);
        if strcmp(parameters.biodiversity_climate_string, 'current')
            baseline.sr_100_20 = es_baseline_jncc.sr_100;
            baseline.sr_100_30 = es_baseline_jncc.sr_100;
            baseline.sr_100_40 = es_baseline_jncc.sr_100;
            baseline.sr_100_50 = es_baseline_jncc.sr_100;
        else
            baseline.sr_100_20 = es_baseline_jncc.sr_100_20;
            baseline.sr_100_30 = es_baseline_jncc.sr_100_30;
            baseline.sr_100_40 = es_baseline_jncc.sr_100_40;
            baseline.sr_100_50 = es_baseline_jncc.sr_100_50;
        end
        
        % 3.2 JNCC scenario biodiversity
        % ------------------------------
        if exist('scenario_landuse', 'var')
            bio_scenario_lc = fcn_create_jncc_lc(scenario_land_cover, es_agriculture_scenario, parameters.biodiversity_climate_string);            
            es_scenario_jncc = fcn_run_biodiversity_jncc(parameters.biodiversity_data_folder_jncc, ...
                                                             bio_scenario_lc, ... 
                                                             parameters.biodiversity_climate_string, ...
                                                             parameters.other_ha);
            if strcmp(parameters.biodiversity_climate_string, 'current')
                scenario.sr_100_20 = es_scenario_jncc.sr_100;
                scenario.sr_100_30 = es_scenario_jncc.sr_100;
                scenario.sr_100_40 = es_scenario_jncc.sr_100;
                scenario.sr_100_50 = es_scenario_jncc.sr_100;
                es_scenario_jncc.sr_100_20 = es_scenario_jncc.sr_100;
                es_scenario_jncc.sr_100_30 = es_scenario_jncc.sr_100;
                es_scenario_jncc.sr_100_40 = es_scenario_jncc.sr_100;
                es_scenario_jncc.sr_100_50 = es_scenario_jncc.sr_100;
            else
                scenario.sr_100_20 = es_scenario_jncc.sr_100_20;
                scenario.sr_100_30 = es_scenario_jncc.sr_100_30;
                scenario.sr_100_40 = es_scenario_jncc.sr_100_40;
                scenario.sr_100_50 = es_scenario_jncc.sr_100_50;
            end
        end
    end
    
    
    %% (4) PREPARE UK DATA FOR RECREATION AND HYDROLOGY
    %  ================================================
    if model_flags.run_recreation || model_flags.run_hydrology
        disp('Preparing data for recreation and hydrology models')
        disp('--------------------------------------------------')
        
        % 4.1. UK LCM
        %      Run baseline agricultural model for the whole of the UK and
        %      store the results.
        %      We need to do this because the scenario analyis might not 
        %      cover the whole of the UK, but some of the catchments and 
        %      subcatchments affected by the land use change in the 
        %      scenario analysis will fall outside the area of the scenario
        %      analysis,representing an externality that we want to account 
        %      for in the sceanario analysis. 
        % -----------------------------------------------------------------
        % (a) UK lcm
        base_lcm_data = strcat(parameters.lcm_data_folder, 'lcm_aggr_', parameters.base_ceh_lcm, '.csv');
        uk_lcm = readtable(base_lcm_data);
        
        required_wood = {'wood_mgmt_ha'};
        sqlquery = ['SELECT ', ...
                        'new2kid, ', ...
                        strjoin(required_wood, ', '), ...
                    ' FROM nevo.nevo_variables ', ...
                    'ORDER BY new2kid'];
        setdbprefs('DataReturnFormat', 'table');
        dataReturn = fetch(exec(conn, sqlquery));
        cell_data = dataReturn.Data;
        uk_lcm = outerjoin(uk_lcm, cell_data, 'Type','Left','MergeKeys',true);
        
        % Run NEV agriculture model
        es_agriculture_uk = fcn_run_agriculture(ag_data_path, ...
                                                climate_data_path, ...
                                                ghg_data_path, ...
                                                parameters, ...
                                                model_flags, ...
                                                uk_lcm, ...
                                                carbon_price); 
                                            
        uk_high_level_lcs = uk_lcm(:, {'new2kid', 'farm_ha', ...
                                     'wood_ha', 'wood_mgmt_ha', ...
                                     'sng_ha', 'urban_ha', ...
                                     'water_ha'});                              
        uk_landuses = fcn_collect_output_simple(uk_high_level_lcs, es_agriculture_uk);
        
        % 4.2. Replace the data for the UK LCM calculated in 4.1. with the 
        %      data passed in the baseline run of the agricultural model, 
        %      i.e. the baseline data defined in run_NEV.m 2.1. with the
        %      additional data on individual crops determined by the farm
        %      model. This is used to compute recreational values and water
        %      flooding/water quality values
        % -----------------------------------------------------------------
        
        % Baseline
        base_high_level_lcs = baseline_land_cover(:, {'new2kid', 'farm_ha', ...
                                     'wood_ha', 'wood_mgmt_ha', ...
                                     'sng_ha', 'urban_ha', ...
                                     'water_ha'});                              
        study_landuses = fcn_collect_output_simple(base_high_level_lcs, es_agriculture_baseline);

        % replace LCM agricultural model output with agricultural model
        % output for the baseline area passed in run_NEV.m section 2.1
        [~, ind] = intersect(uk_landuses.new2kid, study_landuses.new2kid);
        uk_landuses(ind, :) = study_landuses;
        
        % 4.3. Hash this newly created UK Land cover, based on LCM for
        %      areas outisde the study region where baseline and scenario 
        %      apply, and the data provided in the baseline.The imports for 
        %      recreation and hydrology take a long time to run, but need 
        %      to be run every time a new baseline is passed. Here we hash 
        %      the baseline data, which we use to create unique folder 
        %      names where the import data is saved. Whenever a new 
        %      baseline data table is passed, a new folder named after the 
        %      new hash is created, and data is stored. This allows to skip 
        %      running the import if already present.
        % -----------------------------------------------------------------
        hash = fcn_hash_data(table2array(uk_landuses)); 
    end
    
    %% (5) RECREATION MODEL
    %  ====================
    if model_flags.run_recreation
        disp('Running recreation model')
        disp('------------------------')
        
        % 5.1. Import recreation data
        % ---------------------------
        rec_folder = strcat(parameters.rec_data_folder, hash);
        if isfolder(rec_folder)
            if dirsize(rec_folder) == 0
                tic
                NEVO_ORVal_chgsite_data = fcn_import_recreation(uk_landuses, parameters, conn, hash);
                save(strcat(rec_folder, '\NEVO_ORVal_chgsite_data.mat'));
                toc
            end
        else
            mkdir(rec_folder)
            tic
            NEVO_ORVal_chgsite_data = fcn_import_recreation(uk_landuses, parameters, conn, hash);
            save(strcat(rec_folder, '\NEVO_ORVal_chgsite_data.mat'));
            toc
        end
        
        % 5.2. Set recreation model parameters
        % ------------------------------------
        site_type = 'path_chg';
        visval_type = 'simultaneous';
        path_agg_method = 'agg_to_changed_cells';
        minsitesize = 10;
        
        % 5.3. Run baseline recreation
        % ----------------------------
        
        % Set baseline landuses 
        rec_baseline_lu = [es_agriculture_baseline.new2kid ...
        baseline_land_cover.wood_ha ...
        mean(es_agriculture_baseline.arable_ha(:, 1:10),2) ...
        mean(es_agriculture_baseline.pgrass_ha(:, 1:10),2)+mean(es_agriculture_baseline.tgrass_ha(:, 1:10),2) ...
        mean(es_agriculture_baseline.rgraz_ha(:, 1:10),2)+baseline_land_cover.sng_ha ...
        baseline_land_cover.wood_ha ...
        mean(es_agriculture_baseline.arable_ha(:, 11:20),2) ...
        mean(es_agriculture_baseline.pgrass_ha(:, 11:20),2)+mean(es_agriculture_baseline.tgrass_ha(:, 11:20),2) ...
        mean(es_agriculture_baseline.rgraz_ha(:, 11:20),2)+baseline_land_cover.sng_ha ...
        baseline_land_cover.wood_ha ...
        mean(es_agriculture_baseline.arable_ha(:, 21:30),2) ...
        mean(es_agriculture_baseline.pgrass_ha(:, 21:30),2)+mean(es_agriculture_baseline.tgrass_ha(:, 21:30),2) ...
        mean(es_agriculture_baseline.rgraz_ha(:, 21:30),2)+baseline_land_cover.sng_ha ...
        baseline_land_cover.wood_ha ...
        mean(es_agriculture_baseline.arable_ha(:, 31:40),2) ...
        mean(es_agriculture_baseline.pgrass_ha(:, 31:40),2)+mean(es_agriculture_baseline.tgrass_ha(:, 31:40),2) ...
        mean(es_agriculture_baseline.rgraz_ha(:, 31:40),2)+baseline_land_cover.sng_ha];
        
        % set scenario landuses

        % Run baseline recreation 
        es_recreation_baseline = fcn_run_recreation(parameters, ...
                                                    hash, ...
                                                    rec_baseline_lu, ...
                                                    site_type, ...
                                                    visval_type, ...
                                                    path_agg_method, ...
                                                    minsitesize, ...
                                                    conn);
                                               
        % 5.4. Run scenario recreation
        % ----------------------------
        if exist('scenario_landuse', 'var')
            
            % set scenario landuses
            rec_scenario_lu = [es_agriculture_scenario.new2kid ...
                                scenario_land_cover.wood_ha ...
                                mean(es_agriculture_scenario.arable_ha(:, 1:10),2) ...
                                mean(es_agriculture_scenario.pgrass_ha(:, 1:10),2)+mean(es_agriculture_scenario.tgrass_ha(:, 1:10),2) ...
                                mean(es_agriculture_scenario.rgraz_ha(:, 1:10),2)+scenario_land_cover.sng_ha ...
                                scenario_land_cover.wood_ha ...
                                mean(es_agriculture_scenario.arable_ha(:, 11:20),2) ...
                                mean(es_agriculture_scenario.pgrass_ha(:, 11:20),2)+mean(es_agriculture_scenario.tgrass_ha(:, 11:20),2) ...
                                mean(es_agriculture_scenario.rgraz_ha(:, 11:20),2)+scenario_land_cover.sng_ha ...
                                scenario_land_cover.wood_ha ...
                                mean(es_agriculture_scenario.arable_ha(:, 21:30),2) ...
                                mean(es_agriculture_scenario.pgrass_ha(:, 21:30),2)+mean(es_agriculture_scenario.tgrass_ha(:, 21:30),2) ...
                                mean(es_agriculture_scenario.rgraz_ha(:, 21:30),2)+scenario_land_cover.sng_ha ...
                                scenario_land_cover.wood_ha ...
                                mean(es_agriculture_scenario.arable_ha(:, 31:40),2) ...
                                mean(es_agriculture_scenario.pgrass_ha(:, 31:40),2)+mean(es_agriculture_scenario.tgrass_ha(:, 31:40),2) ...
                                mean(es_agriculture_scenario.rgraz_ha(:, 31:40),2)+scenario_land_cover.sng_ha];
            
            % run scenario recreation
            es_recreation_scenario = fcn_run_recreation(parameters, ...
                                                    hash, ...
                                                    rec_scenario_lu, ...
                                                    site_type, ...
                                                    visval_type, ...
                                                    path_agg_method, ...
                                                    minsitesize, ...
                                                    conn);  
            
           
            % 5.5. Run SNG rec model
            %      For land use changes to woodland, it takes time to 
            %      establish a new forest. Hence, we assume that the rec 
            %      values from forest in year 1 to end increase smoothly. 
            %      Newly established forests will have a rec value in year 
            %      1 = to sng rec value for that same area, and over time, 
            %      while woodland rec values increase, sng values decrease 
            %      reciprocally. We calculate here rec values for a 
            %      hypothetical land use conversion to sng, to use if
            %      required
            % -------------------------------------------------------------
            
            % set landuses
            wood_change = scenario_land_cover{:,'wood_ha'} - baseline_land_cover{:,'wood_ha'};
            wood_increase_ind = (wood_change > 0);
            
            sng_rec_for_wood = scenario_land_cover;
            sng_rec_for_wood{wood_increase_ind, 'sng_ha'} = sng_rec_for_wood{wood_increase_ind, 'sng_ha'} + wood_change(wood_increase_ind);
            sng_rec_for_wood{wood_increase_ind, 'wood_ha'} = 0;
            
            rec_sng_lu = [es_agriculture_scenario.new2kid ...
                          sng_rec_for_wood.wood_ha ...
                          mean(es_agriculture_scenario.arable_ha(:, 1:10),2) ...
                          mean(es_agriculture_scenario.pgrass_ha(:, 1:10),2)+mean(es_agriculture_scenario.tgrass_ha(:, 1:10),2) ...
                          mean(es_agriculture_scenario.rgraz_ha(:, 1:10),2)+sng_rec_for_wood.sng_ha ...
                          sng_rec_for_wood.wood_ha ...
                          mean(es_agriculture_scenario.arable_ha(:, 11:20),2) ...
                          mean(es_agriculture_scenario.pgrass_ha(:, 11:20),2)+mean(es_agriculture_scenario.tgrass_ha(:, 11:20),2) ...
                          mean(es_agriculture_scenario.rgraz_ha(:, 11:20),2)+sng_rec_for_wood.sng_ha ...
                          sng_rec_for_wood.wood_ha ...
                          mean(es_agriculture_scenario.arable_ha(:, 21:30),2) ...
                          mean(es_agriculture_scenario.pgrass_ha(:, 21:30),2)+mean(es_agriculture_scenario.tgrass_ha(:, 21:30),2) ...
                          mean(es_agriculture_scenario.rgraz_ha(:, 21:30),2)+sng_rec_for_wood.sng_ha ...
                          sng_rec_for_wood.wood_ha ...
                          mean(es_agriculture_scenario.arable_ha(:, 31:40),2) ...
                          mean(es_agriculture_scenario.pgrass_ha(:, 31:40),2)+mean(es_agriculture_scenario.tgrass_ha(:, 31:40),2) ...
                          mean(es_agriculture_scenario.rgraz_ha(:, 31:40),2)+sng_rec_for_wood.sng_ha];
            
            % run recreation model for sng
            es_recreation_sng_for_wood = fcn_run_recreation(parameters, ...
                                                            hash, ...
                                                            rec_sng_lu, ...
                                                            site_type, ...
                                                            visval_type, ...
                                                            path_agg_method, ...
                                                            minsitesize, ...
                                                            conn);  
        end
    end
    
    %% (5) HYDROLOGY MODULES 
    %      Values of ecosystem services are only expressed as value changes
    %      from a land use change. Hence, the hydrology models cannot be 
    %      run if no land use scenario has been declared in run_NEV.m 
    %      section 2.2.
    %      ------------------
    %      5.1.  Water transfer model imports
    %      5.2.  Base Runs
    %      5.3.  Summarise base run data
    %      5.4.  Baseline flow for flooding model
    %      5.5.  Flooding transfer model imports
    %      5.6.  Define all possible land use changes to identify
    %            representative cells
    %      5.7.  Identify for each availabel land use change a 
    %            representative cell
    %      5.8.  Run the representative cells for each possible land use 
    %            change
    %      5.9.  Add non-use water quality to the representative cells
    %      5.10. Add water treatment values to representative cells
    %      5.11. Use teh represetnative cells to compute values from the
    %            land use changes defined by the baseline and scenario
    %            landuses passed in run_NEV.m sections 2.1. and 2.2.
    %  ====================================================================
    if model_flags.run_hydrology
        if ~exist('scenario_landuse', 'var')
            error('To compute ecosystem service values for flooding and water quality a scenario land use is required')
        else
            
            % 5.1. Run the water imports and save the data
            % --------------------------------------------
            disp('Importing hydrology data')
            disp('------------------------')

            fcn_ImportWaterTransfer(uk_landuses, es_agriculture_uk, parameters, model_flags, conn);


            % 5.2. Base runs. These need to be done only once for each 
            %      baseline land use passed. Whenever a new baseline land 
            %      use is passed, we hash it, run the water functions to 
            %      compute baseline flow and we store the results into a 
            %      folder whose name is the hash and the location is 
            %      Model Data\Water Transfer\Base Run\'hash key'. This 
            %      allows us to check whether the base run data already 
            %      exists for thespecified baseline land use.
            % -------------------------------------------------------------
            disp('Baseline runs for the hydrology models')
            disp('--------------------------------------')

            base_run_folder = strcat(parameters.water_transfer_data_folder, ...
                                     'Base Run\', hash);
            if isfolder(base_run_folder)
                if dirsize(base_run_folder) == 0
                    tic
                    fcn_WaterTransfer_base_run(uk_landuses, parameters, hash);
                    toc
                end
            else
                mkdir(base_run_folder)
                tic
                fcn_WaterTransfer_base_run(uk_landuses, parameters, hash);
                toc
            end

            % 5.3. Summarise base_run data
            % ----------------------------
            disp('Summarise baseline hydrology runs')
            disp('---------------------------------')

            base_run_summary_folder = strcat(parameters.water_transfer_data_folder, ...
                                             'Base Run Summary\', hash);
            if isfolder(base_run_summary_folder)
                if dirsize(base_run_summary_folder) == 0
                    tic
                    subctch_summary = fcn_get_baseline_summary_data(parameters, hash);
                    save([base_run_summary_folder, '\baseline_summary_data.mat'], 'subctch_summary')
                    toc
                end
            else
                mkdir(base_run_summary_folder)
                tic
                subctch_summary = fcn_get_baseline_summary_data(parameters, hash);
                save([base_run_summary_folder, '\baseline_summary_data.mat'], 'subctch_summary')
                toc
            end

            % 5.4. Get baseline flow for the flooding model
            % ---------------------------------------------
            disp('Calculate baseline flow for flooding')
            disp('------------------------------------')

            base_flow_folder = strcat(parameters.water_transfer_data_folder, ...
                                             'Baseline Flow Transfer\', hash);
            if isfolder(base_flow_folder)
                if dirsize(base_flow_folder) == 0
                    tic
                    flow_results = fcn_get_baseline_flow_transfer(parameters, hash);
                    save([base_flow_folder, '\baseline_flow_transfer.mat'], 'flow_results', 'subctch_ids')
                    toc
                end
            else
                mkdir(base_flow_folder)
                tic
                [flow_results, subctch_ids] = fcn_get_baseline_flow_transfer(parameters, hash);
                save([base_flow_folder, '\baseline_flow_transfer.mat'], 'flow_results', 'subctch_ids')
                toc
            end

            % 5.5. Import flooding transfer
            % -----------------------------
            flooding_folder = strcat(parameters.flooding_transfer_data_folder, ...
                                     hash);

            if isfolder(flooding_folder)
                if dirsize(flooding_folder) == 0
                    tic
                    FloodingTransfer = fcn_ImportFloodingTransfer(parameters, hash, conn);
                    save([flooding_folder, '\NEVO_Flooding_Transfer_data_', num2str(parameters.event_parameter), '.mat'], 'FloodingTransfer');
                    toc
                end
            else
                mkdir(flooding_folder)
                tic
                FloodingTransfer = fcn_ImportFloodingTransfer(parameters, hash, conn);
                save([flooding_folder, '\NEVO_Flooding_Transfer_data_', num2str(parameters.event_parameter), '.mat'], 'FloodingTransfer');
                toc
            end                     

            % 5.6. Run all possible land use changes that allow to compute
            %      water quality and flooding values per hectare when we 
            %      run the water and flooding models for the representative 
            %      cells in each sub-basin.
            %      AAA: this is not to be confused with the land use change 
            %      from the baseline to the scenario defined in 2.1. and 
            %      2.2. in run_NEV.m
            %
            %      (script1_run_landuse_change in Github\water-runs or 
            %      defra-elms water runs)
            % -------------------------------------------------------------
            disp('Set land use changes for representative cells')
            disp('---------------------------------------------')

            fcn_run_landuse_change(uk_landuses, options, parameters, hash)


            % 5.7. Identify representative cells for all posible land use
            %      changes. This are going to be 1) arable, 2) farm 
            %      grassland, 3) woodland, 4) seminatural grassland, 
            %      5) farmland. 
            %      (script2_get_rep_cells in Github\water-runs or 
            %      defra-elms water runs)
            % -----------------------------------------------------------
            disp('Identify representative cells')
            disp('-----------------------------')

            land_from = {};
            for i = 1:length(options)
                from = split(options(i), '2');
                from = from(1);
                land_from(i) = from;
            end

            land_from = unique(land_from);

            rep_cell_folder = strcat(parameters.water_transfer_data_folder, ...
                                     'Representative Cells\', hash);
            % if the rep. cells for the specified set of options already
            % exist, skip, else create folder for specified hashed land use
            % and find and save representative cells. 
            if isfolder(rep_cell_folder)
                file_list = dir(rep_cell_folder); 
                file_list = file_list(cellfun(@(a)a > 0, {file_list.bytes}));
                req_fields = strcat('rep_cell_', land_from, '.mat');
                avail_fields = {file_list(:).name};
                intsct = intersect(req_fields, avail_fields);
                if length(intsct) < length(land_from)
                    fcn_get_rep_cells(uk_landuses, land_from, parameters, hash);
                else
                    disp('    Representative cells already identified')
                end
            else
                mkdir(rep_cell_folder)
                fcn_get_rep_cells(uk_landuses, parameters, hash);
            end

            % 5.8. Run the representative cells for the land use changes
            %     AAA: it takes about 10 hours for each land use change!!!
            %     (script3_run_rep_cells in Github\water-runs or 
            %     defra-elms water runs)
            % ------------------------------------------------------------
            disp('Run representative cells')
            disp('------------------------')

            if isfolder(rep_cell_folder)
                file_list = dir(rep_cell_folder); 
                file_list = file_list(cellfun(@(a)a > 0, {file_list.bytes}));
                req_fields = strcat('water_', options, '.mat');
                avail_fields = {file_list(:).name};
                intsct = intersect(req_fields, avail_fields);
                missing_options = setdiff(req_fields, avail_fields);
                if ~isempty(missing_options)
                    fcn_run_rep_cells(missing_options, parameters, hash);
                else
                    disp('    Representative cells already run')
                end
            else
                error('No folder was found containing data for the representative cells.')
            end

            % 5.9. Add non-use water quality to representative cells
            %      (script4_add_non_use_water_quality in Github\water-runs  
            %      or defra-elms water runs)
            % -------------------------------------------------------------
            disp('Add water quality values')
            disp('------------------------')

            for i = 1:numel(options)
                file = load(strcat(rep_cell_folder, '\', req_fields{i}));
                input_struct = fieldnames(file);
                input_struct = input_struct{1};
                file = file.(input_struct);
                colnames = {'non_use_value_20', 'non_use_value_30', ...
                    'non_use_value_40', 'non_use_value_50'};
                diff = setdiff(colnames, file.Properties.VariableNames);
                if ~isempty(diff)
                    fcn_add_non_use_wq(options, parameters, hash)
                else
                    disp('    Water quality values already added')
                end
            end

            % 5.10. Add water treatment costs/savings to representative
            %       cells.
            %       (script5_add_water_treatment in Github\water-runs or 
            %       defra-elms water runs)
            % ----------------------------------------------------------
            disp('Add water treatment savings/costs')
            disp('---------------------------------')

            for i = 1:numel(options)
                file = load(strcat(rep_cell_folder, '\', req_fields{i}));
                input_struct = fieldnames(file);
                input_struct = input_struct{1};
                file = file.(input_struct);
                colnames = {'wt_totn_20', 'wt_totn_30', 'wt_totn_40', ...
                    'wt_totn_50', 'wt_totp_20', 'wt_totp_30', ...
                    'wt_totp_40', 'wt_totp_50'};
                diff = setdiff(colnames, file.Properties.VariableNames);
                if ~isempty(diff)
                    fcn_add_water_treatment(options, parameters, hash, conn);
                else
                    disp('    Water treatment values already added')
                end
            end
            
            run_folder = strcat(parameters.water_transfer_data_folder, ...
                'Runs\', hash, '\');
            if ~isfolder(run_folder)
                mkdir(run_folder);
            end

            % 5.11. Use representative cells for the land use changes from 
            %       the baseline as passed in run_NEV.m 2.1. and 2.2.
            %       (script6_use_rep_cells in Github\water-runs or 
            %       defra-elms water runs)
            % ------------------------------------------------------------
            disp('Use representative cells')
            disp('------------------------')

            % Load representative cells for unique options
            [water_results, water_cell2subctch, nfm_data] = fcn_load_rep_cells(parameters, ...
                                                                               unique_opts, ...
                                                                               conn, ...
                                                                               hash);

            % Loop for unique options
            num_ha = zeros(cell_info.ncells, 1);
            for i = 1:numel(unique_opts)
                option = unique_opts{i};
                ha_option = lcs_scenario_options.(option).hectares;

                % Run rep. cells for unique options: Water quality transfer table
                water_quality_transfer_table = fcn_run_water_quality_transfer_from_results(cell_info, option, ha_option, water_results, water_cell2subctch);

                % Run rep. cells for unique options: Water quality transfer non use table
                water_non_use_transfer_table = fcn_run_water_transfer_non_use_from_results(cell_info, option, ha_option, water_results, water_cell2subctch, parameters.assumption_nonuse);

                % Run rep. cells for unique options: Flooding
                flooding_transfer_table = fcn_run_flooding_transfer_from_results(cell_info, option, ha_option, water_results, water_cell2subctch, nfm_data, parameters.assumption_flooding);

                % !!! temporary: move chgq5 from non use to flooding
                flooding_transfer_table = [flooding_transfer_table, water_non_use_transfer_table(:, {'chgq5_20', 'chgq5_30', 'chgq5_40', 'chgq5_50'})];
                water_non_use_transfer_table = water_non_use_transfer_table(:, {'new2kid', 'non_use_value_20', 'non_use_value_30', 'non_use_value_40', 'non_use_value_50'});

                water_tables.(option).water_quality_transfer_table = water_quality_transfer_table;
                water_tables.(option).water_non_use_transfer_table = water_non_use_transfer_table;
                water_tables.(option).flooding_transfer_table = flooding_transfer_table;

                num_ha = num_ha + ha_option;
            end

            % sum values and benefits together if more than one option 
            list_tables = fieldnames(water_tables);
            if length(list_tables) > 1
                first_table = water_tables.(list_tables{1});
                water_quality_transfer_table = first_table.water_quality_transfer_table;
                water_non_use_transfer_table = first_table.water_non_use_transfer_table;
                flooding_transfer_table = first_table.flooding_transfer_table;
                for j = 2:length(list_tables)
                    temp_table = water_tables.(list_tables{j});
                    water_quality_transfer_table{:, 2:end} = water_quality_transfer_table{:, 2:end} + temp_table.water_quality_transfer_table{:, 2:end};
                    water_non_use_transfer_table{:, 2:end} = water_non_use_transfer_table{:, 2:end} + temp_table.water_non_use_transfer_table{:, 2:end};
                    flooding_transfer_table{:, 2:end} = flooding_transfer_table{:, 2:end} + temp_table.flooding_transfer_table{:, 2:end};
                end
            else
                first_table = water_tables.(list_tables{1});
                water_quality_transfer_table = first_table.water_quality_transfer_table;
                water_non_use_transfer_table = first_table.water_non_use_transfer_table;
                flooding_transfer_table = first_table.flooding_transfer_table;
            end

            run_folder = strcat(parameters.water_transfer_data_folder, ...
                'Runs\', hash, '\');
            file_list = dir(run_folder); 
            file_list = file_list(cellfun(@(a)a > 0, {file_list.bytes}));
            
            save(strcat(run_folder, 'water_results.mat'), 'water_quality_transfer_table', 'water_non_use_transfer_table', 'flooding_transfer_table');
        end
    end
    
    %% (6) COLLECT OUTPUT: BENEFITS AND COSTS
    %  ======================================
    disp('Computing output')
    disp('----------------')

    % 6.1. Calculate benefits and costs
    % --------------------------------- 
    
    % Calculate discount constants
    discount_constants = fcn_calc_discount_constants(parameters.discount_rate);
    
    % Prepare data
    out = fcn_collect_output(parameters, model_flags, scenario_land_cover, scenario, carbon_price);
    
    % Add recreation valuse to out: AAA we need to pass the difference
    % between scenario and baseline
    if model_flags.run_recreation
        rec_var_names = {'new2kid', 'rec_val_20', 'rec_val_30','rec_val_40', 'rec_val_50'};
        rec_val_diff = es_recreation_scenario(:, rec_var_names);
        rec_val_diff{:, 2:end} = es_recreation_scenario{:, rec_var_names(2:end)} - es_recreation_baseline{:, rec_var_names(2:end)};
        out = table2struct(join(struct2table(out), rec_val_diff), 'ToScalar', true);
    end

    opt_arguments = struct();
    if model_flags.run_recreation
        % AAA pass difference between scenario and baseline
        rec_var_names = {'new2kid', 'rec_val_20', 'rec_val_30','rec_val_40', 'rec_val_50'};
        rec_sng_diff = es_recreation_sng_for_wood(:, rec_var_names);
        rec_sng_diff{:, 2:end} = es_recreation_sng_for_wood{:, rec_var_names(2:end)} - es_recreation_baseline{:, rec_var_names(2:end)};
        opt_arguments.sng_rec_for_wood = rec_sng_diff;
    end
    if model_flags.run_hydrology
        run_folder = strcat(parameters.water_transfer_data_folder, ...
                'Runs\', hash, '\');
        load(strcat(run_folder, 'water_results.mat'));
        opt_arguments.water_quality_transfer_table = water_quality_transfer_table;
        opt_arguments.water_non_use_transfer_table = water_non_use_transfer_table;
        opt_arguments.flooding_transfer_table = flooding_transfer_table;
    end
    
    % Calculate benefits
    [benefits_npv_table, costs_npv_table] = fcn_calc_benefits(parameters, ...
                                                              model_flags, ...
                                                              1, ...
                                                              discount_constants, ...
                                                              carbon_price, ...
                                                              baseline, ...
                                                              scenario, ...
                                                              out, ...
                                                              opt_arguments);

    % 6.2. Add cost of establishing recreation paths
    % ----------------------------------------------
    if model_flags.run_recreation
        if site_type == "path_chg"
            % Set to zero under existing paths
            costs_npv_table.rec = zeros(size(costs_npv_table, 1), 1);
        else
            % Calculate length of paths around perimeter of new area (taken from rec code)
            pathlen  = min(2 * pi * sqrt(num_ha * 10000 / pi), 10000);
            % values from: https://www.pathsforall.org.uk/resources/resource/estimating-price-guide-for-path-projects
            costs_npv_table.rec = (4.23 + 16.95) * pathlen + 534.31;
        end
    else
        costs_npv_table.rec = zeros(size(costs_npv_table, 1), 1);
    end

    % Calculate total cost
    costs_npv_table.total = costs_npv_table.farm + costs_npv_table.forestry + costs_npv_table.rec;

    % 6.3. Calculate benefit cost ratio using NPVs
    %     !!! introduces NaN and Inf values by dividing by zero
    %     !!! all of these cases are where there is no farm_ha to start 
    %     !!! with these are removed in payment mechanisms so shouldn't be 
    %     !!! a problem
    benefit_cost_ratio = benefits_npv_table.total ./ costs_npv_table.total;

    %% (7) ENVIRONMENTAL OUTCOMES
    %      Calculate change in environmental outcomes from baseline
    %  ============================================================
    
    % 7.1. Prepare data
    % -----------------
    opt_arguments = struct();
    if model_flags.run_biodiversity
        opt_arguments.es_biodiversity_jncc = es_scenario_jncc;
    end
    if model_flags.run_recreation
        opt_arguments.baseline_land_cover = baseline_land_cover;
        opt_arguments.scenario_land_cover = scenario_land_cover;
        opt_arguments.options = scenario_opts;
    end
    if model_flags.run_hydrology
        run_folder = strcat(parameters.water_transfer_data_folder, ...
                'Runs\', hash, '\');
        load(strcat(run_folder, 'water_results.mat'));
        opt_arguments.water_quality_transfer_table = water_quality_transfer_table;
        opt_arguments.water_non_use_transfer_table = water_non_use_transfer_table;
        opt_arguments.flooding_transfer_table = flooding_transfer_table;
    end


    % 7.2. Calculate environmental quantities
    % ---------------------------------------
    env_outs_table = fcn_calc_quantities(model_flags, ...
                                         1, ...
                                         parameters.landuse_change_timeframe, ...
                                         baseline, ...
                                         scenario.es_agriculture, ...
                                         out, ...
                                         options, ...
                                         opt_arguments);

    %% (8) ECOSYSTEM SERVICES
    %      Use benefits calculated above
    %  =================================

    % 8.1. Combine GHG benefits
    % -------------------------
    combined_ghg = nansum(table2array(benefits_npv_table(:, {'ghg_farm', 'ghg_forestry', 'ghg_soil_forestry'})), 2);

    % 8.2. Create table with combined GHGs and other benefits from above
    % ------------------------------------------------------------------
    es_outs_table = [array2table(combined_ghg, 'VariableNames', {'ghg'}), ...
                       benefits_npv_table(:, {'rec', ...
                                                'flooding', ...
                                                'totn', ...
                                                'totp', ...
                                                'water_non_use'})];

    %% (9) RETURN OUTPUT
    %  =================
    % Have to convert tables to arrays due to array dimensions
    benefits             = benefits_npv_table;
    costs                = costs_npv_table;
    env_outs             = env_outs_table;
    es_outs              = es_outs_table;
    
end





    
    
    
    
    
    
    
    
    
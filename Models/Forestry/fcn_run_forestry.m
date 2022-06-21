function es_forestry = fcn_run_forestry(parameters, ...
                                        baseline_land_uses, ...
                                        landuses_chg, ...
                                        carbon_price)
    % fcn_run_forestry.m
    % ==================
    % Authors: Nathan Owen, Brett Day, Amy Binner
    % Last modified: 26/05/2020
    % Function to run the NEV forestry and forestry GHG models.
    % Inputs:
    % - forest_data_folder: path to forestry model .mat data file.
    % - forestghg_data_folder: path to forestry GHG model .mat data file.
    % - parameters: a structure containing the parameters of the model.
    %   Should include:
    %       - discount_rate: discount rate for financial calculations (default 0.035)
    %       - num_years: number of years to run the model from 2020 (default 40, untested outside of this)
    %       - run_ghg: logical, should we run GHG part of code?
    %       - price_broad_factor: factor to scale price of broadleaf timber (default 1)
    %       - price_conif_factor: factor to scale price of coniferous timber (default 1)
    % - landuses_chg: a structure/table containing cell ids and landuse 
    %   changes from the baseline required to run the model. Should include:
    %       - new2kid: 2km cell IDs
    %       - wood_ha_chg: change in woodland hectares from baseline
    %       - sngrass_ha_chg: change in semi-natural grassland hectares
    %         from baseline.
    %       - arable_ha_chg: change in arable hectares from baseline.
    %       - tgrass_ha_chg: change in temporary grassland hectares from
    %         baseline.
    %       - pgrass_ha_chg: change in permanent grassland hectares from
    %         baseline.
    %       - rgraz_ha_chg: change in rough grazing hectares from baseline.
    % - carbon_price: a vector of carbon prices from 2020 onwards. 300 
    %   years required for calculation of two rotations for Oak trees. Not
    %   required if parameters.run_ghg is false.
    
    %% (1) Set up
    %  ==========
    % (a) Constants
    % -------------
    % Number of cells
    num_cells = length(landuses_chg.new2kid);
    
    % Discount constants
    delta  = 1 / (1 + parameters.discount_rate);
    delta_data_yrs = (delta .^ (1:parameters.num_years))';                              % discount vector for data years (40 year period)
    
    forest_data_folder = parameters.forest_data_folder;
    % (b) Data files
    % --------------
    NEV_ForestTimber_data_mat = strcat(forest_data_folder, 'NEV_ForestTimber_', ...
        parameters.clim_scen_string, '_', parameters.temp_pct_string, '_', ...
        parameters.rain_pct_string, '_', 'data.mat');
    NEV_ForestGHG_data_mat    = strcat(forest_data_folder, 'NEV_ForestGHG_', ...
        parameters.clim_scen_string, '_', parameters.temp_pct_string, '_', ...
        parameters.rain_pct_string, '_', 'data.mat');
    load(NEV_ForestTimber_data_mat, 'es_forestry', 'ForestTimber');
    if parameters.run_ghg
        load(NEV_ForestGHG_data_mat, 'ForestGHG');
    end
    
    % (c) Process inputs
    % ------------------
    % Extract hectare changes in land covers from landuses_chg
    wood_new_ha   = landuses_chg.wood_ha_chg;
    sngrass_new_ha = landuses_chg.sngrass_ha_chg;
    arable_new_ha = landuses_chg.arable_ha_chg;
    tgrass_new_ha = landuses_chg.tgrass_ha_chg;
    pgrass_new_ha = landuses_chg.pgrass_ha_chg;
    rgraz_new_ha = landuses_chg.rgraz_ha_chg;
    
    % Calculate if any woodland hectares have increased
    % Only calculate Forest Soil Carbon output in this case
    wood_gain_ha = wood_new_ha .* (wood_new_ha > 0);
    wood_area_increased = any(wood_gain_ha);
    
    % Calculate useful quantities for Forest Soil Carbon
    if wood_area_increased
        % For forest soil carbon, temporary grassland is considered to be
        % disturbed (arable) soils, and permanent grassland and rough
        % grazing is considered to be undisturbed (non-arable) soils.
        % Convert losses in individual land uses to disturbed and
        % undisturbed soils. 
        
        % Extract hectare losses in arable, tgrass, prgrass, rgraz, sngrass 
        arable_loss_ha = -arable_new_ha .* (arable_new_ha < 0) .* (wood_gain_ha > 0);
        tgrass_loss_ha = -tgrass_new_ha .* (tgrass_new_ha < 0) .* (wood_gain_ha > 0);
        pgrass_loss_ha = -pgrass_new_ha .* (pgrass_new_ha < 0) .* (wood_gain_ha > 0);
        rgraz_loss_ha = -rgraz_new_ha .* (rgraz_new_ha < 0) .* (wood_gain_ha > 0);
        sngrass_loss_ha = -sngrass_new_ha .* (sngrass_new_ha < 0) .* (wood_gain_ha > 0);
        
        % Arable/disturbed: arable + tgrass
        % Non-arable/undisturbed: sngrass + pgrass + rgraz
        arable_loss_ha = arable_loss_ha + tgrass_loss_ha;
        narable_loss_ha = sngrass_loss_ha + pgrass_loss_ha + rgraz_loss_ha;
        
        % Preallocate
        arable2wood_ha_cell = zeros(size(wood_gain_ha));
        narable2wood_ha_cell = zeros(size(wood_gain_ha));
        
        % Woodland expansion where displacing just arable or just non-arable
        arable2wood_ha_cell((arable_loss_ha > 0) & (narable_loss_ha == 0)) = wood_gain_ha((arable_loss_ha > 0) & (narable_loss_ha == 0));
        narable2wood_ha_cell((narable_loss_ha > 0) & (arable_loss_ha == 0)) = wood_gain_ha((narable_loss_ha > 0) & (arable_loss_ha == 0));
        
        % Woodland expansion where displacing a mix of just arable & non-arable
        arable2wood_ha_cell((arable_loss_ha > 0) & (narable_loss_ha > 0))  = wood_gain_ha((arable_loss_ha > 0) & (narable_loss_ha > 0)) .* arable_loss_ha((arable_loss_ha > 0) & (narable_loss_ha > 0)) ./ (arable_loss_ha((arable_loss_ha > 0) & (narable_loss_ha > 0)) + narable_loss_ha((arable_loss_ha > 0) & (narable_loss_ha > 0)));
        narable2wood_ha_cell((arable_loss_ha > 0) & (narable_loss_ha > 0))  = wood_gain_ha((arable_loss_ha > 0) & (narable_loss_ha > 0)) .* narable_loss_ha((arable_loss_ha > 0) & (narable_loss_ha > 0)) ./ (arable_loss_ha((arable_loss_ha > 0) & (narable_loss_ha > 0)) + narable_loss_ha((arable_loss_ha > 0) & (narable_loss_ha > 0)));
    end
    
    %% (2) Reduce to inputted 2km cells
    %  ================================
    % For inputted 2km grid cells, extract rows of relevant tables and
    % arrays in structures
    
    % (a) Forestry Timber
    % -------------------
    % Index for NEVO Input Cells for Forest Timber data so can extract by species subsequently
    [input_cells_ind, input_cell_idx] = ismember(landuses_chg.new2kid, ForestTimber.new2kid);
    input_cell_idx = input_cell_idx(input_cells_ind);
    
    % Hectares of managed woodland
    wood_mgmt_ha = baseline_land_uses.wood_mgmt_ha;
    
    % Proportion of managed deciduous/coniferous woodland
    p_decid_mgmt = baseline_land_uses.p_decid_mgmt;
    p_conif_mgmt = baseline_land_uses.p_conif_mgmt;
    
    % Species-specific information (must be done within species loop)
    for i = 1:height(ForestTimber.SpeciesCode)
        species   = matlab.lang.makeValidName(cell2mat(ForestTimber.SpeciesCode.species(i)));
        
        % Timber quantity per hectare
        ForestTimber.QntPerHa.(species) = ForestTimber.QntPerHa.(species)(input_cell_idx);
        
        % Prediction of yield class
        es_forestry.YC_prediction_cell.(species) = es_forestry.YC_prediction_cell.(species)(input_cell_idx,:);
        
        % Prediction of rotation period
        es_forestry.RotPeriod_cell.(species) = es_forestry.RotPeriod_cell.(species)(input_cell_idx,:);
    end
    
    % (b) Forestry GHG
    % ----------------
    if parameters.run_ghg
        [input_cells_ind_ghg, input_cell_idx_ghg] = ismember(landuses_chg.new2kid, ForestGHG.new2kid);
        input_cell_idx_ghg = input_cell_idx_ghg(input_cells_ind_ghg);
        
        % SoilC_cells
        ForestGHG.SoilC_cells = ForestGHG.SoilC_cells(input_cell_idx_ghg, :);
        
        % (c) Soil Carbon
        if wood_area_increased
            % Species-specific information (must be done within species loop)
            for i = 1:height(ForestTimber.SpeciesCode)
                species   = matlab.lang.makeValidName(cell2mat(ForestTimber.SpeciesCode.species(i)));

                % SoilC_QntYr
                ForestGHG.SoilC_QntYr.narable.(species) = ForestGHG.SoilC_QntYr.narable.(species)(input_cell_idx_ghg);        
                ForestGHG.SoilC_QntYr.arable.(species)  = ForestGHG.SoilC_QntYr.arable.(species)(input_cell_idx_ghg);
                ForestGHG.SoilC_QntYr20.narable.(species) = ForestGHG.SoilC_QntYr20.narable.(species)(input_cell_idx_ghg);        
                ForestGHG.SoilC_QntYr20.arable.(species)  = ForestGHG.SoilC_QntYr20.arable.(species)(input_cell_idx_ghg);
                ForestGHG.SoilC_QntYr30.narable.(species) = ForestGHG.SoilC_QntYr30.narable.(species)(input_cell_idx_ghg);        
                ForestGHG.SoilC_QntYr30.arable.(species)  = ForestGHG.SoilC_QntYr30.arable.(species)(input_cell_idx_ghg);
                ForestGHG.SoilC_QntYr40.narable.(species) = ForestGHG.SoilC_QntYr40.narable.(species)(input_cell_idx_ghg);        
                ForestGHG.SoilC_QntYr40.arable.(species)  = ForestGHG.SoilC_QntYr40.arable.(species)(input_cell_idx_ghg);
                ForestGHG.SoilC_QntYr50.narable.(species) = ForestGHG.SoilC_QntYr50.narable.(species)(input_cell_idx_ghg);        
                ForestGHG.SoilC_QntYr50.arable.(species)  = ForestGHG.SoilC_QntYr50.arable.(species)(input_cell_idx_ghg);
            end
        end
    end
    
    %% (3) Add new woodland onto existing managed woodland
    %  ===================================================
    % Calculate hectares of managed woodland as existing managed woodland +
    % new woodland (can be negative)
    % Timber and GHG outputs will be scaled up by wood_managed_ha NOT wood_ha
    wood_managed_ha = wood_mgmt_ha + wood_new_ha;
    
    % Managed woodland hectares can go negative, set back to zero
    wood_managed_ha(wood_managed_ha < 0) = 0;
    
    %% (4) Adjust timber prices based on model parameters
    %  ==================================================
    % Update value per ha to (possibly new) per ha timber prices
    ForestTimber.TimberValue.PedunculateOak = parameters.price_broad_factor * ForestTimber.TimberValue.PedunculateOak;
    ForestTimber.TimberValue.SitkaSpruce = parameters.price_conif_factor * ForestTimber.TimberValue.SitkaSpruce;
    
    %% (5) Calculate timber & soil output for each species
    %  ===================================================
    % (a) Set proportions of deciduous/coniferous
    % -------------------------------------------
    % Use proportions of managed broadleaf and coniferous for current estimate
    species_prop_cell.PedunculateOak = p_decid_mgmt;
    species_prop_cell.SitkaSpruce    = p_conif_mgmt;

    % 60:40 mix
    species_prop_6040.PedunculateOak = 0.6;
    species_prop_6040.SitkaSpruce    = 0.4;
    
    % (b) Save new managed woodland to es_forestry for use outside function
    % ---------------------------------------------------------------------
    es_forestry.wood_mgmt_ha = wood_managed_ha;
    
    % (c) Initialise vectors for mixed planting outcomes in each cell
    % ---------------------------------------------------------------
    es_forestry.Timber.QntYr.('Mix6040')  = 0;
    es_forestry.Timber.QntYr.('Current')  = 0;
    es_forestry.Timber.QntYr20.('Mix6040')  = 0;
    es_forestry.Timber.QntYr20.('Current')  = 0;
    es_forestry.Timber.QntYr30.('Mix6040')  = 0;
    es_forestry.Timber.QntYr30.('Current')  = 0;
    es_forestry.Timber.QntYr40.('Mix6040')  = 0;
    es_forestry.Timber.QntYr40.('Current')  = 0;
    es_forestry.Timber.QntYr50.('Mix6040')  = 0;
    es_forestry.Timber.QntYr50.('Current')  = 0;
    
    es_forestry.Timber.ValAnn.('Mix6040') = 0;
    es_forestry.Timber.ValAnn.('Current') = 0;
    es_forestry.Timber.BenefitAnn.('Mix6040') = 0;
    es_forestry.Timber.BenefitAnn.('Current') = 0;
    es_forestry.Timber.CostAnn.('Mix6040') = 0;
    es_forestry.Timber.CostAnn.('Current') = 0;
    es_forestry.Timber.FixedCost.('Mix6040') = 0;
    es_forestry.Timber.FixedCost.('Current') = 0;
    es_forestry.Timber.FlowAnn20.('Mix6040') = 0;
    es_forestry.Timber.FlowAnn20.('Current') = 0;
    es_forestry.Timber.FlowAnn30.('Mix6040') = 0;
    es_forestry.Timber.FlowAnn30.('Current') = 0;
    es_forestry.Timber.FlowAnn40.('Mix6040') = 0;
    es_forestry.Timber.FlowAnn40.('Current') = 0;
    es_forestry.Timber.FlowAnn50.('Mix6040') = 0;
    es_forestry.Timber.FlowAnn50.('Current') = 0;
    
    es_forestry.TimberC.QntYr.('Mix6040')  = 0;
    es_forestry.TimberC.QntYr.('Current')  = 0;
    es_forestry.TimberC.QntYrUB.('Mix6040')  = 0;
    es_forestry.TimberC.QntYrUB.('Current')  = 0;
    es_forestry.TimberC.QntYr20.('Mix6040')  = 0;
    es_forestry.TimberC.QntYr20.('Current')  = 0;
    es_forestry.TimberC.QntYr30.('Mix6040')  = 0;
    es_forestry.TimberC.QntYr30.('Current')  = 0;
    es_forestry.TimberC.QntYr40.('Mix6040')  = 0;
    es_forestry.TimberC.QntYr40.('Current')  = 0;
    es_forestry.TimberC.QntYr50.('Mix6040')  = 0;
    es_forestry.TimberC.QntYr50.('Current')  = 0;
    
    es_forestry.TimberC.ValAnn.('Mix6040') = 0;
    es_forestry.TimberC.ValAnn.('Current') = 0;
    es_forestry.TimberC.FlowAnn20.('Mix6040') = 0;
    es_forestry.TimberC.FlowAnn20.('Current') = 0;
    es_forestry.TimberC.FlowAnn30.('Mix6040') = 0;
    es_forestry.TimberC.FlowAnn30.('Current') = 0;
    es_forestry.TimberC.FlowAnn40.('Mix6040') = 0;
    es_forestry.TimberC.FlowAnn40.('Current') = 0;
    es_forestry.TimberC.FlowAnn50.('Mix6040') = 0;
    es_forestry.TimberC.FlowAnn50.('Current') = 0;
    
    es_forestry.SoilC.QntYr.('Mix6040')  = 0;
    es_forestry.SoilC.QntYr.('Current')  = 0;
    es_forestry.SoilC.QntYr20.('Mix6040')  = 0;
    es_forestry.SoilC.QntYr20.('Current')  = 0;
    es_forestry.SoilC.QntYr30.('Mix6040')  = 0;
    es_forestry.SoilC.QntYr30.('Current')  = 0;
    es_forestry.SoilC.QntYr40.('Mix6040')  = 0;
    es_forestry.SoilC.QntYr40.('Current')  = 0;
    es_forestry.SoilC.QntYr50.('Mix6040')  = 0;
    es_forestry.SoilC.QntYr50.('Current')  = 0;
    
    es_forestry.SoilC.ValAnn.('Mix6040') = 0;
    es_forestry.SoilC.ValAnn.('Current') = 0;
    es_forestry.SoilC.FlowAnn20.('Mix6040') = 0;
    es_forestry.SoilC.FlowAnn20.('Current') = 0;
    es_forestry.SoilC.FlowAnn30.('Mix6040') = 0;
    es_forestry.SoilC.FlowAnn30.('Current') = 0;
    es_forestry.SoilC.FlowAnn40.('Mix6040') = 0;
    es_forestry.SoilC.FlowAnn40.('Current') = 0;
    es_forestry.SoilC.FlowAnn50.('Mix6040') = 0;
    es_forestry.SoilC.FlowAnn50.('Current') = 0;
    
    % MAIN LOOP OVER SPECIES
    % ======================
    for i = 1:height(ForestTimber.SpeciesCode)
        % Species Details
        species   = matlab.lang.makeValidName(cell2mat(ForestTimber.SpeciesCode.species(i)));

        % Discount & annuity constants for this species (based on rotation period)
        rotp1 = ForestTimber.RotPeriod_max.(species);
        rotp2 = rotp1*2;
        delta_rot1 = (delta .^ (1:rotp1))';    % discount vector for one rotation
        delta_rot2 = (delta .^ (1:rotp2))';    % discount vector for two rotations
        gamma_rot1 = parameters.discount_rate ./ (1 - (1 + parameters.discount_rate) .^ -(ForestTimber.RotPeriod.(species))); % annuity constant for one rotation
        
        % FOREST TIMBER PRODUCTION
        % ========================
        % (a) Forest Timber: Quantity
        % ---------------------------
        % Brett's per year calculation over full rotation of tree with
        % climate change
        es_forestry.Timber.QntYr.(species)   = ForestTimber.QntPerHa.(species) .* wood_managed_ha;
        es_forestry.Timber.QntYr.('Mix6040') = es_forestry.Timber.QntYr.('Mix6040') + species_prop_6040.(species) .* es_forestry.Timber.QntYr.(species);
        es_forestry.Timber.QntYr.('Current') = es_forestry.Timber.QntYr.('Current') + species_prop_cell.(species) .* es_forestry.Timber.QntYr.(species);
        
        % Other approach is to calculate timber volume flows in each decade
        % Average timber per hectare for each yield class in each decade
        timber_perha_20 = sum(ForestTimber.Timber.(species)(1:10, :), 1);
        timber_perha_30 = sum(ForestTimber.Timber.(species)(11:20, :), 1);
        timber_perha_40 = sum(ForestTimber.Timber.(species)(21:30, :), 1);
        timber_perha_50 = sum(ForestTimber.Timber.(species)(31:40, :), 1);
        
        % Average timber per yr for each cell in each decade, taking into
        % account climate change
        timber_peryr_20 = full(mean(timber_perha_20(es_forestry.YC_prediction_cell.(species)(:, 1:10)), 2));
        timber_peryr_30 = full(mean(timber_perha_30(es_forestry.YC_prediction_cell.(species)(:, 11:20)), 2));
        timber_peryr_40 = full(mean(timber_perha_40(es_forestry.YC_prediction_cell.(species)(:, 21:30)), 2));
        timber_peryr_50 = full(mean(timber_perha_50(es_forestry.YC_prediction_cell.(species)(:, 31:40)), 2));
        
        % Scale by woodland hectares in each cell and define mixes
        es_forestry.Timber.QntYr20.(species) = timber_peryr_20 .* wood_managed_ha;
        es_forestry.Timber.QntYr30.(species) = timber_peryr_30 .* wood_managed_ha;
        es_forestry.Timber.QntYr40.(species) = timber_peryr_40 .* wood_managed_ha;
        es_forestry.Timber.QntYr50.(species) = timber_peryr_50 .* wood_managed_ha;
        
        es_forestry.Timber.QntYr20.('Mix6040') = es_forestry.Timber.QntYr20.('Mix6040') + species_prop_6040.(species) .* es_forestry.Timber.QntYr20.(species);
        es_forestry.Timber.QntYr20.('Current') = es_forestry.Timber.QntYr20.('Current') + species_prop_cell.(species) .* es_forestry.Timber.QntYr20.(species);
        es_forestry.Timber.QntYr30.('Mix6040') = es_forestry.Timber.QntYr30.('Mix6040') + species_prop_6040.(species) .* es_forestry.Timber.QntYr30.(species);
        es_forestry.Timber.QntYr30.('Current') = es_forestry.Timber.QntYr30.('Current') + species_prop_cell.(species) .* es_forestry.Timber.QntYr30.(species);
        es_forestry.Timber.QntYr40.('Mix6040') = es_forestry.Timber.QntYr40.('Mix6040') + species_prop_6040.(species) .* es_forestry.Timber.QntYr40.(species);
        es_forestry.Timber.QntYr40.('Current') = es_forestry.Timber.QntYr40.('Current') + species_prop_cell.(species) .* es_forestry.Timber.QntYr40.(species);
        es_forestry.Timber.QntYr50.('Mix6040') = es_forestry.Timber.QntYr50.('Mix6040') + species_prop_6040.(species) .* es_forestry.Timber.QntYr50.(species);
        es_forestry.Timber.QntYr50.('Current') = es_forestry.Timber.QntYr50.('Current') + species_prop_cell.(species) .* es_forestry.Timber.QntYr50.(species);

        % (b) Forest Timber: Value
        % ------------------------
        % Note: this is calculated in two ways:
        %   1. annuity of annuities over data years + remaining years over one rotation
        %   2. average for each decade in data years only (flow)
        
        % NPV: per ha npv of timber production by yc at new prices & discount rate
        value_minus_cost = ForestTimber.TimberValue.(species) - ForestTimber.TimberCosts.PerHa.(species);
        npv_perha = delta_rot1' * (value_minus_cost);         % one rotation
        npv_ben_perha       = delta_rot1' * (ForestTimber.TimberValue.(species));         % one rotation
        npv_cst_perha       = delta_rot1' * (ForestTimber.TimberCosts.PerHa.(species));         % one rotation
        
        % Annuity: per ha annuity of timber production by yc at new prices & discount rate
        ann_perha = npv_perha' .* gamma_rot1;       % one rotation
        ann_ben_perha  = npv_ben_perha' .* gamma_rot1;       % one rotation
        ann_cst_perha = npv_cst_perha' .* gamma_rot1;       % one rotation

        % Average flow per hectare for each yield class in each decade
        flow_perha_20 = mean(value_minus_cost(1:10, :), 1);    % 2020-2029
        flow_perha_30 = mean(value_minus_cost(11:20, :), 1);   % 2030-2039
        flow_perha_40 = mean(value_minus_cost(21:30, :), 1);   % 2040-2049
        flow_perha_50 = mean(value_minus_cost(31:40, :), 1);   % 2050-2059
        
        % Takes new series of yc predictions for future climate and each 
        % year replaces with annuity for that yield class out to the 
        % cell-specific rotation period for this climate. The npv of that 
        % stream of annual revenues is calculated and finally an 
        % annuity of that npv is derived (an annuity of annuities)
        
        % NPV of annuities for cell evolution of yc with climate ...
        %   ... for years for which have climate data:
        if num_cells == 1
            npv_data_yrs = ann_perha(es_forestry.YC_prediction_cell.(species))' * delta_data_yrs;
            npv_ben_data_yrs    = ann_ben_perha(es_forestry.YC_prediction_cell.(species))' * delta_data_yrs;
            npv_cst_data_yrs    = ann_cst_perha(es_forestry.YC_prediction_cell.(species))' * delta_data_yrs;
        else
            npv_data_yrs = ann_perha(es_forestry.YC_prediction_cell.(species)) * delta_data_yrs;
            npv_ben_data_yrs    = ann_ben_perha(es_forestry.YC_prediction_cell.(species)) * delta_data_yrs;
            npv_cst_data_yrs    = ann_cst_perha(es_forestry.YC_prediction_cell.(species)) * delta_data_yrs;
        end
        
        npv_data_yrs_20 = full(sum(flow_perha_20(es_forestry.YC_prediction_cell.(species)(:, 1:10)), 2));
        npv_data_yrs_30 = full(sum(flow_perha_30(es_forestry.YC_prediction_cell.(species)(:, 11:20)), 2));
        npv_data_yrs_40 = full(sum(flow_perha_40(es_forestry.YC_prediction_cell.(species)(:, 21:30)), 2));
        npv_data_yrs_50 = full(sum(flow_perha_50(es_forestry.YC_prediction_cell.(species)(:, 31:40)), 2));

        % ... remaining years up to end of rotation (uses formula for partial sum of geometric series):
        delta_rot_cell = (delta ^ (parameters.num_years - 1) - delta .^ (parameters.num_years + es_forestry.RotPeriod_cell.(species))) / (1 - delta);
        npv_final_yrs  = delta_rot_cell .* ann_perha(es_forestry.YC_prediction_cell.(species)(:,end));
        npv_ben_final_yrs  = delta_rot_cell .* ann_ben_perha(es_forestry.YC_prediction_cell.(species)(:,end));       
        npv_cst_final_yrs  = delta_rot_cell .* ann_cst_perha(es_forestry.YC_prediction_cell.(species)(:,end));  
        
        npv_perha_cell = npv_data_yrs + npv_final_yrs;
        npv_ben_perha_cell = npv_ben_data_yrs + npv_ben_final_yrs;
        npv_cst_perha_cell = npv_cst_data_yrs + npv_cst_final_yrs;
        
        % NPV of fixed costs based on first year's yc (no need to discount as 1st year)
        npv_fxcst = ForestTimber.TimberCosts.Fixed.(species)(1, es_forestry.YC_prediction_cell.(species)(:, 1))';
                
        % Annuity of Annuities:
        gamma_rot_cell  = parameters.discount_rate ./ (1 - (1 + parameters.discount_rate) .^ -(es_forestry.RotPeriod_cell.(species) - 1));
        es_forestry.Timber.ValAnn.(species) = gamma_rot_cell .* (npv_perha_cell .* wood_managed_ha - npv_fxcst .* (wood_managed_ha > 0));
        
        es_forestry.Timber.BenefitAnn.(species) = gamma_rot_cell .* (npv_ben_perha_cell .* wood_managed_ha);
        es_forestry.Timber.CostAnn.(species)    = gamma_rot_cell .* (npv_cst_perha_cell .* wood_managed_ha);
        es_forestry.Timber.FixedCost.(species)  = npv_fxcst .* (wood_managed_ha > 0);
        
        
        % Average flow in each decade
        es_forestry.Timber.FlowAnn20.(species) = (npv_data_yrs_20 .* wood_managed_ha - npv_fxcst .* (wood_managed_ha > 0)) / 10;   % subtract costs in first decade
        es_forestry.Timber.FlowAnn30.(species) = (npv_data_yrs_30 .* wood_managed_ha) / 10;
        es_forestry.Timber.FlowAnn40.(species) = (npv_data_yrs_40 .* wood_managed_ha) / 10;
        es_forestry.Timber.FlowAnn50.(species) = (npv_data_yrs_50 .* wood_managed_ha) / 10;
        
        % Accumulate Forest Mixes
        es_forestry.Timber.ValAnn.('Mix6040')       = es_forestry.Timber.ValAnn.('Mix6040') + species_prop_6040.(species) .* es_forestry.Timber.ValAnn.(species);
        es_forestry.Timber.ValAnn.('Current')       = es_forestry.Timber.ValAnn.('Current') + species_prop_cell.(species) .* es_forestry.Timber.ValAnn.(species);
        es_forestry.Timber.BenefitAnn.('Mix6040')   = es_forestry.Timber.BenefitAnn.('Mix6040') + species_prop_6040.(species) .* es_forestry.Timber.BenefitAnn.(species);
        es_forestry.Timber.BenefitAnn.('Current')   = es_forestry.Timber.BenefitAnn.('Current') + species_prop_cell.(species) .* es_forestry.Timber.BenefitAnn.(species);
        es_forestry.Timber.CostAnn.('Mix6040')      = es_forestry.Timber.CostAnn.('Mix6040') + species_prop_6040.(species) .* es_forestry.Timber.CostAnn.(species);
        es_forestry.Timber.CostAnn.('Current')      = es_forestry.Timber.CostAnn.('Current') + species_prop_cell.(species) .* es_forestry.Timber.CostAnn.(species);
        es_forestry.Timber.FixedCost.('Mix6040')    = es_forestry.Timber.FixedCost.('Mix6040') + species_prop_6040.(species) .* es_forestry.Timber.FixedCost.(species);
        es_forestry.Timber.FixedCost.('Current')    = es_forestry.Timber.FixedCost.('Current') + species_prop_cell.(species) .* es_forestry.Timber.FixedCost.(species);
        es_forestry.Timber.FlowAnn20.('Mix6040')	= es_forestry.Timber.FlowAnn20.('Mix6040') + species_prop_6040.(species) .* es_forestry.Timber.FlowAnn20.(species);
        es_forestry.Timber.FlowAnn20.('Current')	= es_forestry.Timber.FlowAnn20.('Current') + species_prop_cell.(species) .* es_forestry.Timber.FlowAnn20.(species);
        es_forestry.Timber.FlowAnn30.('Mix6040')	= es_forestry.Timber.FlowAnn30.('Mix6040') + species_prop_6040.(species) .* es_forestry.Timber.FlowAnn30.(species);
        es_forestry.Timber.FlowAnn30.('Current')	= es_forestry.Timber.FlowAnn30.('Current') + species_prop_cell.(species) .* es_forestry.Timber.FlowAnn30.(species);
        es_forestry.Timber.FlowAnn40.('Mix6040')	= es_forestry.Timber.FlowAnn40.('Mix6040') + species_prop_6040.(species) .* es_forestry.Timber.FlowAnn40.(species);
        es_forestry.Timber.FlowAnn40.('Current')	= es_forestry.Timber.FlowAnn40.('Current') + species_prop_cell.(species) .* es_forestry.Timber.FlowAnn40.(species);
        es_forestry.Timber.FlowAnn50.('Mix6040')	= es_forestry.Timber.FlowAnn50.('Mix6040') + species_prop_6040.(species) .* es_forestry.Timber.FlowAnn50.(species);
        es_forestry.Timber.FlowAnn50.('Current')	= es_forestry.Timber.FlowAnn50.('Current') + species_prop_cell.(species) .* es_forestry.Timber.FlowAnn50.(species);

        % FOREST CARBON PRODUCTION
        % ========================
        if parameters.run_ghg        
            % (c) Timber Carbon: Quantity
            % ---------------------------
            % Sum of Carbon quantities per year for years for which have climate data:
            if num_cells == 1
                TimberC_qnt_data_yrs =  sum(ForestGHG.TimberC_QntYr.(species)(es_forestry.YC_prediction_cell.(species)));
                TimberC_qntUB_data_yrs = sum(ForestGHG.TimberC_QntYrUB.(species)(es_forestry.YC_prediction_cell.(species)));
                TimberC_qnt_20 =  sum(ForestGHG.TimberC_QntYr20.(species)(es_forestry.YC_prediction_cell.(species)(:, 1:10)));
                TimberC_qnt_30 =  sum(ForestGHG.TimberC_QntYr30.(species)(es_forestry.YC_prediction_cell.(species)(:, 11:20)));
                TimberC_qnt_40 =  sum(ForestGHG.TimberC_QntYr40.(species)(es_forestry.YC_prediction_cell.(species)(:, 21:30)));
                TimberC_qnt_50 =  sum(ForestGHG.TimberC_QntYr50.(species)(es_forestry.YC_prediction_cell.(species)(:, 31:40)));
            else
                TimberC_qnt_data_yrs =  sum(ForestGHG.TimberC_QntYr.(species)(es_forestry.YC_prediction_cell.(species)), 2);
                TimberC_qntUB_data_yrs = sum(ForestGHG.TimberC_QntYrUB.(species)(es_forestry.YC_prediction_cell.(species)), 2);
                TimberC_qnt_20 =  sum(ForestGHG.TimberC_QntYr20.(species)(es_forestry.YC_prediction_cell.(species)(:, 1:10)), 2);
                TimberC_qnt_30 =  sum(ForestGHG.TimberC_QntYr30.(species)(es_forestry.YC_prediction_cell.(species)(:, 11:20)), 2);
                TimberC_qnt_40 =  sum(ForestGHG.TimberC_QntYr40.(species)(es_forestry.YC_prediction_cell.(species)(:, 21:30)), 2);
                TimberC_qnt_50 =  sum(ForestGHG.TimberC_QntYr50.(species)(es_forestry.YC_prediction_cell.(species)(:, 31:40)), 2);
            end

            % Sum of Carbon quantities remaining years up to end of rotation:
            num_final_yrs  = es_forestry.RotPeriod_cell.(species) - parameters.num_years;
            TimberC_qnt_final_yrs = num_final_yrs .* ForestGHG.TimberC_QntYr.(species)(es_forestry.YC_prediction_cell.(species)(:, end));
            TimberC_qntUB_final_yrs = num_final_yrs .* ForestGHG.TimberC_QntYrUB.(species)(es_forestry.YC_prediction_cell.(species)(:, end));
            
            % Average annual Carbon quantities per cell for this species
            es_forestry.TimberC.QntYr.(species)  = wood_managed_ha .* ((TimberC_qnt_data_yrs + TimberC_qnt_final_yrs) ./ es_forestry.RotPeriod_cell.(species));
            elm_contract_length = 50; % ELM contract length
            es_forestry.TimberC.QntYrUB.(species)  = wood_managed_ha .* ((TimberC_qntUB_data_yrs + TimberC_qntUB_final_yrs) ./ elm_contract_length);
            es_forestry.TimberC.QntYr20.(species) = (wood_managed_ha .* TimberC_qnt_20) / 10;
            es_forestry.TimberC.QntYr30.(species) = (wood_managed_ha .* TimberC_qnt_30) / 10;
            es_forestry.TimberC.QntYr40.(species) = (wood_managed_ha .* TimberC_qnt_40) / 10;
            es_forestry.TimberC.QntYr50.(species) = (wood_managed_ha .* TimberC_qnt_50) / 10;

            % Accumulate Forest Mixes
            es_forestry.TimberC.QntYr.('Mix6040')   = es_forestry.TimberC.QntYr.('Mix6040') + species_prop_6040.(species) .* es_forestry.TimberC.QntYr.(species);
            es_forestry.TimberC.QntYr.('Current')   = es_forestry.TimberC.QntYr.('Current') + species_prop_cell.(species) .* es_forestry.TimberC.QntYr.(species);
            es_forestry.TimberC.QntYrUB.('Mix6040')   = es_forestry.TimberC.QntYrUB.('Mix6040') + species_prop_6040.(species) .* es_forestry.TimberC.QntYrUB.(species);
            es_forestry.TimberC.QntYrUB.('Current')   = es_forestry.TimberC.QntYrUB.('Current') + species_prop_cell.(species) .* es_forestry.TimberC.QntYrUB.(species);
            es_forestry.TimberC.QntYr20.('Mix6040') = es_forestry.TimberC.QntYr20.('Mix6040') + species_prop_6040.(species) .* es_forestry.TimberC.QntYr20.(species);
            es_forestry.TimberC.QntYr20.('Current') = es_forestry.TimberC.QntYr20.('Current') + species_prop_cell.(species) .* es_forestry.TimberC.QntYr20.(species);
            es_forestry.TimberC.QntYr30.('Mix6040') = es_forestry.TimberC.QntYr30.('Mix6040') + species_prop_6040.(species) .* es_forestry.TimberC.QntYr30.(species);
            es_forestry.TimberC.QntYr30.('Current') = es_forestry.TimberC.QntYr30.('Current') + species_prop_cell.(species) .* es_forestry.TimberC.QntYr30.(species);
            es_forestry.TimberC.QntYr40.('Mix6040') = es_forestry.TimberC.QntYr40.('Mix6040') + species_prop_6040.(species) .* es_forestry.TimberC.QntYr40.(species);
            es_forestry.TimberC.QntYr40.('Current') = es_forestry.TimberC.QntYr40.('Current') + species_prop_cell.(species) .* es_forestry.TimberC.QntYr40.(species);
            es_forestry.TimberC.QntYr50.('Mix6040') = es_forestry.TimberC.QntYr50.('Mix6040') + species_prop_6040.(species) .* es_forestry.TimberC.QntYr50.(species);
            es_forestry.TimberC.QntYr50.('Current') = es_forestry.TimberC.QntYr50.('Current') + species_prop_cell.(species) .* es_forestry.TimberC.QntYr50.(species);
            
            % (d) Timber Carbon: Value
            % ------------------------
            % NB. this is calculated in two ways:
            % 1. Annuity of annuities over data years + remaining years over two rotations
            % - Carbon npv calculations done over 2 rotations to capture both
            %   sequestration phase and emissions phase after harvest (i.e.
            %   non-permanent storage). 
            % - Carbon Annuity is over single rotation as assume forest is
            %   replanted so continuous value flow achieved by annualising 
            %   two-rotation npv over one rotation
            % 2. Average for each decade in data years only (flow)
        
            % Annuity for each yc for this species
            
            % npv for each yc of this species
            TimberC_npv     = (delta_rot2 .* carbon_price(1:rotp2))' * ForestGHG.TimberC_TSer.(species);         % two rotations
            
            % annuity for each yc of this species
            TimberC_ann     = gamma_rot1 .* TimberC_npv';    % one rotation

            % average flow per hectare for each yield class in each decade
            timber_carbon_value = carbon_price(1:40) .* ForestGHG.TimberC_TSer.(species)(1:40, :);
            TimberC_flow_20 = mean(timber_carbon_value(1:10, :), 1);    % 2020-2029
            TimberC_flow_30 = mean(timber_carbon_value(11:20, :), 1);   % 2030-2039
            TimberC_flow_40 = mean(timber_carbon_value(21:30, :), 1);   % 2040-2049
            TimberC_flow_50 = mean(timber_carbon_value(31:40, :), 1);   % 2050-2059
               
            % NPV of Carbon annuities for years for which have climate data:
            if num_cells == 1
                TimberC_npv_data_yrs	= TimberC_ann(es_forestry.YC_prediction_cell.(species))' * delta_data_yrs;
            else
                TimberC_npv_data_yrs	= TimberC_ann(es_forestry.YC_prediction_cell.(species)) * delta_data_yrs;
            end
            
            TimberC_npv_data_yrs_20 = full(sum(TimberC_flow_20(es_forestry.YC_prediction_cell.(species)(:, 1:10)), 2));
            TimberC_npv_data_yrs_30 = full(sum(TimberC_flow_30(es_forestry.YC_prediction_cell.(species)(:, 11:20)), 2));
            TimberC_npv_data_yrs_40 = full(sum(TimberC_flow_40(es_forestry.YC_prediction_cell.(species)(:, 21:30)), 2));
            TimberC_npv_data_yrs_50 = full(sum(TimberC_flow_50(es_forestry.YC_prediction_cell.(species)(:, 31:40)), 2));

            % NPV of Carbon annuities remaining years up to end of rotation:
            TimberC_npv_final_yrs = delta_rot_cell .* TimberC_ann(es_forestry.YC_prediction_cell.(species)(:, end));
            
            TimberC_npv_cell = TimberC_npv_data_yrs + TimberC_npv_final_yrs;        
                
            % Annuity of Annuities:
            es_forestry.TimberC.ValAnn.(species) = gamma_rot_cell .* TimberC_npv_cell .* wood_managed_ha;
            
            % Average flow in each decade
            es_forestry.TimberC.FlowAnn20.(species)	= TimberC_npv_data_yrs_20 .* wood_managed_ha / 10;
            es_forestry.TimberC.FlowAnn30.(species)	= TimberC_npv_data_yrs_30 .* wood_managed_ha / 10;
            es_forestry.TimberC.FlowAnn40.(species)	= TimberC_npv_data_yrs_40 .* wood_managed_ha / 10;
            es_forestry.TimberC.FlowAnn50.(species)	= TimberC_npv_data_yrs_50 .* wood_managed_ha / 10;
            
            % Accumulate Forest Mixes
            es_forestry.TimberC.ValAnn.('Mix6040')      = es_forestry.TimberC.ValAnn.('Mix6040') + species_prop_6040.(species) .* es_forestry.TimberC.ValAnn.(species);
            es_forestry.TimberC.ValAnn.('Current')      = es_forestry.TimberC.ValAnn.('Current') + species_prop_cell.(species) .* es_forestry.TimberC.ValAnn.(species);
            es_forestry.TimberC.FlowAnn20.('Mix6040')	= es_forestry.TimberC.FlowAnn20.('Mix6040') + species_prop_6040.(species) .* es_forestry.TimberC.FlowAnn20.(species);
            es_forestry.TimberC.FlowAnn20.('Current')	= es_forestry.TimberC.FlowAnn20.('Current') + species_prop_cell.(species) .* es_forestry.TimberC.FlowAnn20.(species);
            es_forestry.TimberC.FlowAnn30.('Mix6040')	= es_forestry.TimberC.FlowAnn30.('Mix6040') + species_prop_6040.(species) .* es_forestry.TimberC.FlowAnn30.(species);
            es_forestry.TimberC.FlowAnn30.('Current')	= es_forestry.TimberC.FlowAnn30.('Current') + species_prop_cell.(species) .* es_forestry.TimberC.FlowAnn30.(species);
            es_forestry.TimberC.FlowAnn40.('Mix6040')	= es_forestry.TimberC.FlowAnn40.('Mix6040') + species_prop_6040.(species) .* es_forestry.TimberC.FlowAnn40.(species);
            es_forestry.TimberC.FlowAnn40.('Current')	= es_forestry.TimberC.FlowAnn40.('Current') + species_prop_cell.(species) .* es_forestry.TimberC.FlowAnn40.(species);
            es_forestry.TimberC.FlowAnn50.('Mix6040')	= es_forestry.TimberC.FlowAnn50.('Mix6040') + species_prop_6040.(species) .* es_forestry.TimberC.FlowAnn50.(species);
            es_forestry.TimberC.FlowAnn50.('Current')	= es_forestry.TimberC.FlowAnn50.('Current') + species_prop_cell.(species) .* es_forestry.TimberC.FlowAnn50.(species);
            
            if wood_area_increased
                % (e) Soil Carbon: Value
                % ----------------------
                % NB. this is done in two ways
                % 1. Annuity of annuities over data years + remaining years over two rotations
                % - Carbon npv calculations done over 2 rotations to capture
                %   long run soil changes
                % - Carbon annuity is over single rotation which repeats
                %   the timber Carbon calculation but is less defensible 
                %   as the land use change of Woodland expansion is one-off
                % 2. Annuity for each decade in data years only (flow)

                % Calculate npv for each Carbine YC for this Species
                % --------------------------------------------------
                SoilC_narable_ann_cell = [];
                SoilC_narable_flow_cell_20 = [];
                SoilC_narable_flow_cell_30 = [];
                SoilC_narable_flow_cell_40 = [];
                SoilC_narable_flow_cell_50 = [];
                
                SoilC_arable_ann_cell  = [];
                SoilC_arable_flow_cell_20 = [];
                SoilC_arable_flow_cell_30 = [];
                SoilC_arable_flow_cell_40 = [];
                SoilC_arable_flow_cell_50 = [];
                
                colidx = ones(num_cells,1);   
                rowidx = (1:num_cells)';
                
                discount_Cprice = delta_rot2 .* carbon_price(1:rotp2);
                
                for j = 1:length(ForestTimber.Carbine_ycs.(species))
                    yc   = ForestTimber.Carbine_ycs.(species)(j);
                    rotp = ForestTimber.RotPeriod.(species)(yc);

                    % npv for this yc & soil type for this species
                    SoilC_npv_yc	= (discount_Cprice(1:rotp*2))' * ForestGHG.SoilC_TSer.(species){yc};          % two rotations

                    % annuity for this yc & soil type for this species
                    SoilC_ann_yc	= gamma_rot1(yc) * SoilC_npv_yc;    % one rotation

                    % average flow per hectare for each yield class in each decade
                    soil_carbon_value = carbon_price(1:40) .* ForestGHG.SoilC_TSer.(species){yc}(1:40, :);
                    SoilC_flow_yc_20 = mean(soil_carbon_value(1:10, :), 1);    % 2020-2029
                    SoilC_flow_yc_30 = mean(soil_carbon_value(11:20, :), 1);   % 2030-2039
                    SoilC_flow_yc_40 = mean(soil_carbon_value(21:30, :), 1);   % 2040-2049
                    SoilC_flow_yc_50 = mean(soil_carbon_value(31:40, :), 1);   % 2050-2059
                    
                    % annuity for soil mix in each cell (for this yc when displacing arable and non-arable)
                    % (first 4 cols of SoilC_TSer are for non-arable last 4 cols are for arable both in order SLCO)
                    SoilC_narable_ann_cell      = [SoilC_narable_ann_cell; [rowidx  colidx*yc  ForestGHG.SoilC_cells * SoilC_ann_yc(1:4)']];
                    SoilC_narable_flow_cell_20	= [SoilC_narable_flow_cell_20; [rowidx  colidx*yc  ForestGHG.SoilC_cells * SoilC_flow_yc_20(1:4)']];
                    SoilC_narable_flow_cell_30	= [SoilC_narable_flow_cell_30; [rowidx  colidx*yc  ForestGHG.SoilC_cells * SoilC_flow_yc_30(1:4)']];
                    SoilC_narable_flow_cell_40	= [SoilC_narable_flow_cell_40; [rowidx  colidx*yc  ForestGHG.SoilC_cells * SoilC_flow_yc_40(1:4)']];
                    SoilC_narable_flow_cell_50	= [SoilC_narable_flow_cell_50; [rowidx  colidx*yc  ForestGHG.SoilC_cells * SoilC_flow_yc_50(1:4)']];
                    
                    SoilC_arable_ann_cell       = [SoilC_arable_ann_cell;  [rowidx  colidx*yc  ForestGHG.SoilC_cells * SoilC_ann_yc(5:8)']];
                    SoilC_arable_flow_cell_20   = [SoilC_arable_flow_cell_20;  [rowidx  colidx*yc  ForestGHG.SoilC_cells * SoilC_flow_yc_20(5:8)']];
                    SoilC_arable_flow_cell_30	= [SoilC_arable_flow_cell_30;  [rowidx  colidx*yc  ForestGHG.SoilC_cells * SoilC_flow_yc_30(5:8)']];
                    SoilC_arable_flow_cell_40	= [SoilC_arable_flow_cell_40;  [rowidx  colidx*yc  ForestGHG.SoilC_cells * SoilC_flow_yc_40(5:8)']];
                    SoilC_arable_flow_cell_50	= [SoilC_arable_flow_cell_50;  [rowidx  colidx*yc  ForestGHG.SoilC_cells * SoilC_flow_yc_50(5:8)']];
                    
                end
                
                % [N x yc] matrices of npvs for each yc for the particular soil combination in each cell
                SoilC_narable_ann_cell      = sparse(SoilC_narable_ann_cell(:,1), SoilC_narable_ann_cell(:,2), SoilC_narable_ann_cell(:,3));
                SoilC_narable_flow_cell_20	= sparse(SoilC_narable_flow_cell_20(:,1), SoilC_narable_flow_cell_20(:,2), SoilC_narable_flow_cell_20(:,3));
                SoilC_narable_flow_cell_30	= sparse(SoilC_narable_flow_cell_30(:,1), SoilC_narable_flow_cell_30(:,2), SoilC_narable_flow_cell_30(:,3));
                SoilC_narable_flow_cell_40	= sparse(SoilC_narable_flow_cell_40(:,1), SoilC_narable_flow_cell_40(:,2), SoilC_narable_flow_cell_40(:,3));
                SoilC_narable_flow_cell_50	= sparse(SoilC_narable_flow_cell_50(:,1), SoilC_narable_flow_cell_50(:,2), SoilC_narable_flow_cell_50(:,3));
                
                SoilC_arable_ann_cell       = sparse(SoilC_arable_ann_cell(:,1),  SoilC_arable_ann_cell(:,2),  SoilC_arable_ann_cell(:,3));
                SoilC_arable_flow_cell_20	= sparse(SoilC_arable_flow_cell_20(:,1), SoilC_arable_flow_cell_20(:,2), SoilC_arable_flow_cell_20(:,3));
                SoilC_arable_flow_cell_30	= sparse(SoilC_arable_flow_cell_30(:,1), SoilC_arable_flow_cell_30(:,2), SoilC_arable_flow_cell_30(:,3));
                SoilC_arable_flow_cell_40	= sparse(SoilC_arable_flow_cell_40(:,1), SoilC_arable_flow_cell_40(:,2), SoilC_arable_flow_cell_40(:,3));
                SoilC_arable_flow_cell_50	= sparse(SoilC_arable_flow_cell_50(:,1), SoilC_arable_flow_cell_50(:,2), SoilC_arable_flow_cell_50(:,3));

                % Increment YC for each of 40yrs to index into the cell annuity matrix
                YC_prediction_cell_idx = (double(es_forestry.YC_prediction_cell.(species)) - 1)*num_cells + rowidx;                
                                
                % NPV of Carbon annuities for years for which have climate data:
                SoilC_narable_npv_data_yrs      = SoilC_narable_ann_cell(YC_prediction_cell_idx) * delta_data_yrs;
                SoilC_narable_npv_data_yrs_20	= full(sum(SoilC_narable_flow_cell_20(YC_prediction_cell_idx(:,1:10)), 2));
                SoilC_narable_npv_data_yrs_30	= full(sum(SoilC_narable_flow_cell_30(YC_prediction_cell_idx(:,11:20)), 2));
                SoilC_narable_npv_data_yrs_40	= full(sum(SoilC_narable_flow_cell_40(YC_prediction_cell_idx(:,21:30)), 2));
                SoilC_narable_npv_data_yrs_50	= full(sum(SoilC_narable_flow_cell_50(YC_prediction_cell_idx(:,31:40)), 2));
                
                SoilC_arable_npv_data_yrs       = SoilC_arable_ann_cell(YC_prediction_cell_idx) * delta_data_yrs;
                SoilC_arable_npv_data_yrs_20	= full(sum(SoilC_arable_flow_cell_20(YC_prediction_cell_idx(:,1:10)), 2));
                SoilC_arable_npv_data_yrs_30	= full(sum(SoilC_arable_flow_cell_30(YC_prediction_cell_idx(:,11:20)), 2));
                SoilC_arable_npv_data_yrs_40	= full(sum(SoilC_arable_flow_cell_40(YC_prediction_cell_idx(:,21:30)), 2));
                SoilC_arable_npv_data_yrs_50	= full(sum(SoilC_arable_flow_cell_50(YC_prediction_cell_idx(:,31:40)), 2));

                % NPV of Carbon annuities remaining years up to end of rotation:
                SoilC_narable_npv_final_yrs = delta_rot_cell .* SoilC_narable_ann_cell(YC_prediction_cell_idx(:, end));
                SoilC_arable_npv_final_yrs  = delta_rot_cell .* SoilC_arable_ann_cell(YC_prediction_cell_idx(:, end));

                % NPV of Carbon annuities
                SoilC_narable_npv_cell     = SoilC_narable_npv_data_yrs + SoilC_narable_npv_final_yrs;        
                SoilC_arable_npv_cell      = SoilC_arable_npv_data_yrs + SoilC_arable_npv_final_yrs;        

                % Annuity of Annuities for arable & non-arable land areas:
                es_forestry.SoilC.ValAnn.(species) = gamma_rot_cell .* (SoilC_narable_npv_cell .* narable2wood_ha_cell + SoilC_arable_npv_cell .* arable2wood_ha_cell);
                
                % Annuity of Annuities for arable & non-arable land areas:
                es_forestry.SoilC.FlowAnn20.(species) = (SoilC_narable_npv_data_yrs_20 .* narable2wood_ha_cell + SoilC_arable_npv_data_yrs_20 .* arable2wood_ha_cell) / 10;
                es_forestry.SoilC.FlowAnn30.(species) = (SoilC_narable_npv_data_yrs_30 .* narable2wood_ha_cell + SoilC_arable_npv_data_yrs_30 .* arable2wood_ha_cell) / 10;
                es_forestry.SoilC.FlowAnn40.(species) = (SoilC_narable_npv_data_yrs_40 .* narable2wood_ha_cell + SoilC_arable_npv_data_yrs_40 .* arable2wood_ha_cell) / 10;
                es_forestry.SoilC.FlowAnn50.(species) = (SoilC_narable_npv_data_yrs_50 .* narable2wood_ha_cell + SoilC_arable_npv_data_yrs_50 .* arable2wood_ha_cell) / 10;
                
                % Accumulate Forest Mixes
                es_forestry.SoilC.ValAnn.('Mix6040')	= es_forestry.SoilC.ValAnn.('Mix6040') + species_prop_6040.(species) .* es_forestry.SoilC.ValAnn.(species);
                es_forestry.SoilC.ValAnn.('Current')	= es_forestry.SoilC.ValAnn.('Current') + species_prop_cell.(species) .* es_forestry.SoilC.ValAnn.(species);
                es_forestry.SoilC.FlowAnn20.('Mix6040') = es_forestry.SoilC.FlowAnn20.('Mix6040') + species_prop_6040.(species) .* es_forestry.SoilC.FlowAnn20.(species);
                es_forestry.SoilC.FlowAnn20.('Current') = es_forestry.SoilC.FlowAnn20.('Current') + species_prop_cell.(species) .* es_forestry.SoilC.FlowAnn20.(species);
                es_forestry.SoilC.FlowAnn30.('Mix6040') = es_forestry.SoilC.FlowAnn30.('Mix6040') + species_prop_6040.(species) .* es_forestry.SoilC.FlowAnn30.(species);
                es_forestry.SoilC.FlowAnn30.('Current') = es_forestry.SoilC.FlowAnn30.('Current') + species_prop_cell.(species) .* es_forestry.SoilC.FlowAnn30.(species);
                es_forestry.SoilC.FlowAnn40.('Mix6040') = es_forestry.SoilC.FlowAnn40.('Mix6040') + species_prop_6040.(species) .* es_forestry.SoilC.FlowAnn40.(species);
                es_forestry.SoilC.FlowAnn40.('Current') = es_forestry.SoilC.FlowAnn40.('Current') + species_prop_cell.(species) .* es_forestry.SoilC.FlowAnn40.(species);
                es_forestry.SoilC.FlowAnn50.('Mix6040') = es_forestry.SoilC.FlowAnn50.('Mix6040') + species_prop_6040.(species) .* es_forestry.SoilC.FlowAnn50.(species);
                es_forestry.SoilC.FlowAnn50.('Current') = es_forestry.SoilC.FlowAnn50.('Current') + species_prop_cell.(species) .* es_forestry.SoilC.FlowAnn50.(species);
                
                % (e) Soil Carbon: Quantity
                % -------------------------
                % Annuity of Annuities for arable & non-arable land areas:
                es_forestry.SoilC.QntYr.(species) = (ForestGHG.SoilC_QntYr.narable.(species) .* narable2wood_ha_cell + ForestGHG.SoilC_QntYr.arable.(species) .* arable2wood_ha_cell);
                es_forestry.SoilC.QntYr20.(species) = (ForestGHG.SoilC_QntYr20.narable.(species) .* narable2wood_ha_cell + ForestGHG.SoilC_QntYr20.arable.(species) .* arable2wood_ha_cell);
                es_forestry.SoilC.QntYr30.(species) = (ForestGHG.SoilC_QntYr30.narable.(species) .* narable2wood_ha_cell + ForestGHG.SoilC_QntYr30.arable.(species) .* arable2wood_ha_cell);
                es_forestry.SoilC.QntYr40.(species) = (ForestGHG.SoilC_QntYr40.narable.(species) .* narable2wood_ha_cell + ForestGHG.SoilC_QntYr40.arable.(species) .* arable2wood_ha_cell);
                es_forestry.SoilC.QntYr50.(species) = (ForestGHG.SoilC_QntYr50.narable.(species) .* narable2wood_ha_cell + ForestGHG.SoilC_QntYr50.arable.(species) .* arable2wood_ha_cell);
                
                % Accumulate Forest Mixes
                es_forestry.SoilC.QntYr.('Mix6040') = es_forestry.SoilC.QntYr.('Mix6040') + species_prop_6040.(species) .* es_forestry.SoilC.QntYr.(species);
                es_forestry.SoilC.QntYr.('Current') = es_forestry.SoilC.QntYr.('Current') + species_prop_cell.(species) .* es_forestry.SoilC.QntYr.(species);
                es_forestry.SoilC.QntYr20.('Mix6040') = es_forestry.SoilC.QntYr20.('Mix6040') + species_prop_6040.(species) .* es_forestry.SoilC.QntYr20.(species);
                es_forestry.SoilC.QntYr20.('Current') = es_forestry.SoilC.QntYr20.('Current') + species_prop_cell.(species) .* es_forestry.SoilC.QntYr20.(species);
                es_forestry.SoilC.QntYr30.('Mix6040') = es_forestry.SoilC.QntYr30.('Mix6040') + species_prop_6040.(species) .* es_forestry.SoilC.QntYr30.(species);
                es_forestry.SoilC.QntYr30.('Current') = es_forestry.SoilC.QntYr30.('Current') + species_prop_cell.(species) .* es_forestry.SoilC.QntYr30.(species);
                es_forestry.SoilC.QntYr40.('Mix6040') = es_forestry.SoilC.QntYr40.('Mix6040') + species_prop_6040.(species) .* es_forestry.SoilC.QntYr40.(species);
                es_forestry.SoilC.QntYr40.('Current') = es_forestry.SoilC.QntYr40.('Current') + species_prop_cell.(species) .* es_forestry.SoilC.QntYr40.(species);
                es_forestry.SoilC.QntYr50.('Mix6040') = es_forestry.SoilC.QntYr50.('Mix6040') + species_prop_6040.(species) .* es_forestry.SoilC.QntYr50.(species);
                es_forestry.SoilC.QntYr50.('Current') = es_forestry.SoilC.QntYr50.('Current') + species_prop_cell.(species) .* es_forestry.SoilC.QntYr50.(species);               
            end
        end                                 
    end
end

function [ForestTimber, es_forestry] = ImportForestTimber(conn, ...
                                               climate_data_folder,...
                                               clim_string,...
                                               clim_scen_string,...
                                               pct_temp,...
                                               pct_rain, ...
                                               start_year, ...
                                               num_years)
    % ImportForestTimber
    % ==================
    % Authors: Brett Day, Nathan Owen, Amy Binner
    % Last modified: 04/10/2019
    % Import all data required for running the NEV forestry model. To be
    % called from within the ImportForestry.m script. More info:
    % Imports data on yields, revenues and costs of forestry calculated 
    % from FC model for different yield classes (yc) of different species.
    % Uses data on current cell ESC scores to predict future ESC scores for
    % each cell under climate path using Silvia Ferrini's GAM model from 
    % the NEAFO project. ESC scores are rounded to nearest Yield Class with
    % data from FC's Carbine model.
    % Inputs:
    % - conn: a database connection
    % - climate_scenario: optional argument in case the standard 'rcp60' is
    %   not the climate of interest. Other values can be 'rcp26', 'rcp45',
    %   'rcp85', 'a1b'.
    % - pct_temp: optional argument in case the standard 50th percentile 
    %   level from the temperature data is not the one of interest. Other
    %   possible values are 1, 5, 10, 25, 75, 90, 95, 99
    % - pct_rain: optional argument in case the standard 50th percentile 
    %   level from the precipitation data is not the one of interest. Other
    %   possible values are 1, 5, 10, 25, 75, 90, 95, 99
    % Outputs:
    % - ForestTimber
    % - es_forestry
    
    %% (1) Set up
    %  ==========
    % (a) Set parameters
    % ------------------
    base_discount_rate = 0.035;
    forest_species_list = '''ss'', ''pok''';
    es_forestry.base_discount_rate = base_discount_rate;    % Store discount rate to es_forestry

    %% (2) Load data from database
    %  ===========================
    % (a) 2km cell IDs and hectares of managed woodland
    % -------------------------------------------------
    sqlquery = ['SELECT ', ...
                    'new2kid, ', ...
                    'wood_mgmt_ha ', ...
                'FROM nevo.nevo_variables ', ...
                'ORDER BY new2kid'];
    setdbprefs('DataReturnFormat', 'table');
    dataReturn = fetch(exec(conn, sqlquery));
    cell_data = dataReturn.Data;
    ForestTimber.new2kid = cell_data.new2kid;
    ForestTimber.wood_mgmt_ha = cell_data.wood_mgmt_ha;
    
    % (b) Proportion of deciduous/coniferous woodland
    % -----------------------------------------------
    sqlquery = ['SELECT ', ...
                    'p_decid_mgmt, ', ...
                    'p_conif_mgmt ', ...
                'FROM nevo.nevo_variables ', ...
                'ORDER BY new2kid'];
    setdbprefs('DataReturnFormat', 'table');
    dataReturn = fetch(exec(conn, sqlquery));
    proportions = dataReturn.Data;
    ForestTimber.p_decid_mgmt = proportions.p_decid_mgmt;
    ForestTimber.p_conif_mgmt = proportions.p_conif_mgmt;
    
    % (c) List of Species
    % -------------------
    forest_species_list = '''ss'', ''pok''';
    sqlquery    = ['SELECT * ', ...
                   'FROM nevo.forestry_species_list ', ...
                   'WHERE code IN (' forest_species_list ')'];
    setdbprefs('DataReturnFormat', 'table');
    dataReturn  = fetch(exec(conn, sqlquery));
    ForestTimber.SpeciesCode = dataReturn.Data;

    % (d) Timber data
    %  --------------
    sqlquery    = ['SELECT * ', ...
                   'FROM nevo.forestry_timber_data ', ...
                   'ORDER BY code, yield_class, year'];
    setdbprefs('DataReturnFormat','table');
    dataReturn  = fetch(exec(conn,sqlquery));
    timber = dataReturn.Data;

    % (e) Rotation periods
    % --------------------
    sqlquery    = ['SELECT * ', ...
                   'FROM nevo.forestry_rotation_periods ', ...
                   'ORDER BY code, yield_class'];
    setdbprefs('DataReturnFormat','table');
    dataReturn  = fetch(exec(conn,sqlquery));
    rotation    = dataReturn.Data;

    % (f) Cost definitions
    % --------------------
    % Fixed costs (for each woodland):
    sqlquery    = ['SELECT cell_costs ', ...
                   'FROM nevo.forestry_cost_definitions ', ...
                   'WHERE cell_costs IS NOT NULL'];
    setdbprefs('DataReturnFormat','cellarray');
    dataReturn  = fetch(exec(conn,sqlquery));
    CostDefinitions.FixedCosts = dataReturn.Data(:,1)';

    % Variable costs (per ha of woodland):
    sqlquery    = ['SELECT ha_costs ', ...
                   'FROM nevo.forestry_cost_definitions ', ...
                   'WHERE ha_costs IS NOT NULL'];
    setdbprefs('DataReturnFormat','cellarray');
    dataReturn  = fetch(exec(conn,sqlquery));
    CostDefinitions.PerHaCosts = dataReturn.Data(:,1)';
    
    % (g) ESC scores & Climate data & GAM Parameters for Silvias ESC future model
    % ---------------------------------------------------------------------------

    % Assign standard definition for the parameter related to climate when
    % they are not defined as optional arguments of the function
    if ~exist('clim_string', 'var') || isempty('clim_string')
        clim_string = 'ukcp18';
    end
    if ~exist('clim_scen_string', 'var') || isempty('clim_scen_string')
        clim_scen_string = 'rcp60';
    end
    if ~exist('pct_temp', 'var') || isempty('pct_temp')
        pct_temp = 50;
    end
    if ~exist('pct_rain', 'var') || isempty('pct_rain')
        pct_rain = 50;
    end
    
    % load the climate data 
    NEV_clim_data_mat = strcat(climate_data_folder, 'NEV_climate_',...
    clim_scen_string, '_', pct_temp, '_',...
    pct_rain, '_data.mat');
    load(NEV_clim_data_mat, 'ClimateData');
    ClimateData = ClimateData.grow;
    
    % Check that the climate data loaded matches the climate pathway
    % selected in the Forest Timber calculation function (this should be true any
    % time that the optional climate arguments are not declared). 
    temp_pathway = strcat('Climate_cells_', clim_string, '_', clim_scen_string, '_temp_', num2str(pct_temp));
    rain_pathway = strcat('Climate_cells_', clim_string, '_', clim_scen_string, '_rain_', num2str(pct_rain));
    if isfield(ClimateData, temp_pathway) ~= 1 || isfield(ClimateData, rain_pathway) ~= 1
        error('foo:bar', 'The climate data loaded and the climate data declared in the Forest Timber import do not match.\nMake sure you are using the same climate scenarios in the climate and Forest Timber modules')
    end
        
    % Extract temperature and rainfall for this scenario and combine
    temp = ClimateData.(['Climate_cells_', clim_string, '_', clim_scen_string, '_temp_', num2str(pct_temp)]);
    rain = ClimateData.(['Climate_cells_', clim_string, '_', clim_scen_string, '_rain_', num2str(pct_rain)]);
    
    new2kid = temp(:, 'new2kid');
    temp = temp(:, fcn_select_years('temp', start_year:(start_year + num_years - 1)));
    rain = rain(:, fcn_select_years('rain', start_year:(start_year + num_years - 1)));
    
    climate = [new2kid, temp, rain];
    
    sqlquery = ['SELECT ', ...
                    'tbl1.new2kid, ', ...
                    'tbl2.mt_as_6190, ', ...
                    'tbl2.tp_as_6190, ', ...
                    'tbl1.ss, ', ...
                    'tbl1.pok, ', ...
                    'tbl1.sp, ', ...
                    'tbl1.be ' ...
                'FROM nevo.forestry_esc_scores AS tbl1 ' ...
                '  INNER JOIN nevo.nevo_variables AS tbl2 ON tbl1.new2kid = tbl2.new2kid ' ...
                '  ORDER BY tbl1.new2kid'];
    setdbprefs('DataReturnFormat','table');
    dataReturn = fetch(exec(conn,sqlquery));
    esc_cells  = dataReturn.Data;
    
    esc_cells = outerjoin(esc_cells, climate, 'MergeKeys', true);

    % Calculate covariates for Silvia's ESC score model
    esc_cells.Temp12 = (esc_cells.mt_as_6190 > 12) .* (esc_cells.mt_as_6190 - 12);
    esc_cells.Temp9  = (esc_cells.mt_as_6190 > 9) .* (esc_cells.mt_as_6190 - 9);
    esc_cells.Rain1  = (esc_cells.tp_as_6190 > 400) .* (esc_cells.tp_as_6190 - 400);

    esc_cells.Temp12Rain1 = esc_cells.Temp12 .* esc_cells.Rain1;
    esc_cells.TempRain1   = esc_cells.mt_as_6190 .* esc_cells.Rain1;
    esc_cells.Temp12Rain  = esc_cells.Temp12 .* esc_cells.tp_as_6190;
    esc_cells.TempRain    = esc_cells.mt_as_6190 .* esc_cells.tp_as_6190;

    esc_cells.Temp9Rain1  = esc_cells.Temp9 .* esc_cells.Rain1;
    esc_cells.Temp9Rain   = esc_cells.Temp9 .* esc_cells.tp_as_6190;

    %% (3) Set up species-specific data for yields, costs and yield classes
    %  --------------------------------------------------------------------
    % Loop through each species
    for i = 1:height(ForestTimber.SpeciesCode)
        species   = matlab.lang.makeValidName(cell2mat(ForestTimber.SpeciesCode.species(i)));
        spec_code = matlab.lang.makeValidName(cell2mat(ForestTimber.SpeciesCode.code(i)));

        % (a) Rotation Data by Yield Class
        % --------------------------------
        timber_spec = timber(string(timber.code) == string(spec_code), :);
        rot_spec    = rotation(string(rotation.code) == string(spec_code), :);

        year = timber_spec.year2014 + 1; 
        yc   = timber_spec.yield_class;

        ForestTimber.Timber.(species) = sparse(year, yc, timber_spec.volume);
        Timber_total.(species) = sum(ForestTimber.Timber.(species), 1)';

        ForestTimber.TimberValue.(species)  = sparse(year, yc, timber_spec.volume .* timber_spec.price);

        ForestTimber.TimberCosts.Fixed.(species) = sparse(year, yc, sum(timber_spec{:, CostDefinitions.FixedCosts}, 2));
        ForestTimber.TimberCosts.PerHa.(species) = sparse(year, yc, sum(timber_spec{:, CostDefinitions.PerHaCosts}, 2));

        ForestTimber.RotPeriod.(species)     = sparse(rot_spec.yield_class, 1, rot_spec.rotation); 
        ForestTimber.RotPeriod_max.(species) = max(ForestTimber.RotPeriod.(species)); 

        ForestTimber.Carbine_ycs.(species)     = find(ForestTimber.RotPeriod.(species));
        ForestTimber.Carbine_ycs_max.(species) = max(ForestTimber.Carbine_ycs.(species));

        % (c) Predict Future Yield Class for Each NEVO Cell
        % -------------------------------------------------
        yc_future_spec = uint8(zeros(size(esc_cells, 1), num_years));
        for yr = 1:num_years   
            % Predicted YC for this species in this cell over climates for future years (for which we havd data out to num_years)
            yc_future_spec(:, yr) = fcn_future_YC_model(esc_cells, num2str(start_year + yr - 1), species, spec_code, ForestTimber.Carbine_ycs);        
        end    

        % Store YC predictions for NEVO interactive valuation
        es_forestry.YC_prediction_cell.(species) = yc_future_spec;

        % (d) Predict Climate-Adjusted Rotation Period for each NEVO Cell (if planting today)
        % -----------------------------------------------------------------------------------
        % Each year a cell is in yc it contributes 1/F(yc) to the tree's
        % growth. Where F(yc) is the rotation length for that yc. Simply 
        % sum until the tree is fully grown.
        %
        % NB: Past the final year of climate data the tree is assumed to 
        %     grow at the rate of the yc of final year.
        %     No need to account for +1 year preparation as this is    
        %     done in the annuity calculation. We just wish to find an 
        %     adjusted rotation length.

        % Proportion of 'full growth' provided by one year's worth of growth at each yc
        pgrow_yr = 1 ./ ForestTimber.RotPeriod.(species);

        % Climate adjusted rotation using clever index of proportion of growth vector from future yc 
        pgrow_data_yrs = sum(pgrow_yr(yc_future_spec), 2); % Proportion grow in data years
        pgrow_final_yr = pgrow_yr(yc_future_spec(:, end)); % Proportion of year of final year of data

        es_forestry.RotPeriod_cell.(species) = round(num_years + ((1 - pgrow_data_yrs) ./ pgrow_final_yr));

        % (e) Predict Climate-Adjusted Timber yield for each NEVO Cell (if planting today)
        % --------------------------------------------------------------------------------    
        timber_data_yrs  = sum(pgrow_yr(yc_future_spec) .* Timber_total.(species)(yc_future_spec), 2);
        %ForestTimber.timber_data_yrs.(species) = timber_data_yrs;
        timber_final_yrs = (1 - pgrow_data_yrs) .* Timber_total.(species)(yc_future_spec(:, end));

        ForestTimber.QntPerHa.(species) = full((timber_data_yrs + timber_final_yrs) ./ es_forestry.RotPeriod_cell.(species));   
        % Note: this is timber quantity so no discounting & no C permanent
        %       equivalence calculation needed in sum
    end
   end


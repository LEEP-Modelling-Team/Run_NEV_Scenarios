function fcn_run_landuse_change(uk_baseline, options, parameters, hash)
    %% fcn_run_landuse_change.m
    %  ========================
    % Author: Nathan Owen, Mattia Mancini, Rebecca Collins
    % Last modified: 30/05/2022
    % ----------------------------------------------------
    % DESCRIPTION
    % Create .mat files of land use changes for each cell to be used when
    % running the representative cell for each sub-catchment


    %% (0) Set up
    %  ==========
 
    % 1.1. Load and prepare baseline
    % ------------------------------                              
    lcs_baseline = uk_baseline;
    
    % 1.2. Define flags for options
    % -----------------------------
    for i = 1:length(options)
        option = options{i};
        eval(strcat('do_', option, ' = true;'));
    end
    
    % 1.3. Define output folder
    % -------------------------
    save_folder = strcat(parameters.water_transfer_data_folder, ...
                          'Representative Cells\', hash);
    if ~isfolder(save_folder)
        mkdir(save_folder)
    end
        

    %% (1) Scenario land uses: arable2sng
    %  ==================================
    
    % Add arable and tgrass hectares to semi-natural grassland hectares
    % Subtract arable and tgrass hectares from farm hectares
    % Reduce all crops and farm grassland (except permanent grassland and rough grazing) to zero
    if exist('do_arable2sng', 'var')
        lcs_arable2sng = lcs_baseline;
        hectares = lcs_arable2sng.arable_ha_20 + lcs_arable2sng.tgrass_ha_20;
        lcs_arable2sng.hectares = hectares;

        lcs_arable2sng.sngrass_ha = lcs_arable2sng.sngrass_ha + hectares;
        lcs_arable2sng.farm_ha = lcs_arable2sng.farm_ha - hectares;

        % Set appropriate land covers to zero
        cols_to_zero = {'arable_ha_20', 'arable_ha_30', 'arable_ha_40', 'arable_ha_50', ...
                        'wheat_ha_20', 'wheat_ha_30', 'wheat_ha_40', 'wheat_ha_50', ...
                        'osr_ha_20', 'osr_ha_30', 'osr_ha_40', 'osr_ha_50', ...
                        'wbar_ha_20', 'wbar_ha_30', 'wbar_ha_40', 'wbar_ha_50', ...
                        'sbar_ha_20', 'sbar_ha_30', 'sbar_ha_40', 'sbar_ha_50', ...
                        'pot_ha_20', 'pot_ha_30', 'pot_ha_40', 'pot_ha_50', ...
                        'sb_ha_20', 'sb_ha_30', 'sb_ha_40', 'sb_ha_50', ...
                        'other_ha_20', 'other_ha_30', 'other_ha_40', 'other_ha_50', ...
                        'tgrass_ha_20', 'tgrass_ha_30', 'tgrass_ha_40', 'tgrass_ha_50'};
        lcs_arable2sng(:, cols_to_zero) = array2table(zeros(size(lcs_arable2sng, 1), length(cols_to_zero)));

        % Set remaining farmland grass types to 2020s amount
        lcs_arable2sng.rgraz_ha_30 = lcs_arable2sng.rgraz_ha_20;
        lcs_arable2sng.rgraz_ha_40 = lcs_arable2sng.rgraz_ha_20;
        lcs_arable2sng.rgraz_ha_50 = lcs_arable2sng.rgraz_ha_20;

        lcs_arable2sng.pgrass_ha_30 = lcs_arable2sng.pgrass_ha_20;
        lcs_arable2sng.pgrass_ha_40 = lcs_arable2sng.pgrass_ha_20;
        lcs_arable2sng.pgrass_ha_50 = lcs_arable2sng.pgrass_ha_20;

        % Reset total farming grassland
        lcs_arable2sng.grass_ha_20 = lcs_arable2sng.rgraz_ha_20 + lcs_arable2sng.pgrass_ha_20;
        lcs_arable2sng.grass_ha_30 = lcs_arable2sng.rgraz_ha_30 + lcs_arable2sng.pgrass_ha_30;
        lcs_arable2sng.grass_ha_40 = lcs_arable2sng.rgraz_ha_40 + lcs_arable2sng.pgrass_ha_40;
        lcs_arable2sng.grass_ha_50 = lcs_arable2sng.rgraz_ha_50 + lcs_arable2sng.pgrass_ha_50;
        
        % check that land uses sum to 400 hectares and stop it not
        [lcm, top_level, crops] = fcn_landuse_check(lcs_arable2sng);
        
        if top_level ~= 1
            warning('The 5 lcm land uses for the ''arable2sng'' option do not sum to 400 ha!')
        end
        
        if any(top_level == 0)
            decade_list = {'20', '30', '40', '50'};
            warning_vars = {};
            ind = find(top_level == 0);
            for i = 1:length(ind)
                decade = decade_list(ind(i));
                warning_vars = [warning_vars, decade];
            end
            msg = strcat('arable and grassland hectares for the ''arable2sng'' option do not sum to farmland hectares for the following decades: \n', ...
                         repmat('-  %s\n', 1, length(warning_vars))); 
            warning_msg = sprintf(msg, warning_vars{:});
            warning(warning_msg)
        end
            
        if any(crops == 0)
            decade_list = {'20', '30', '40', '50'};
            warning_vars = {};
            ind = find(crops == 0);
            for i = 1:length(ind)
                decade = decade_list(ind(i));
                warning_vars = [warning_vars, decade];
            end
            msg = strcat('Crops and grassland for the ''arable2sng'' option do not sum to farmland hectares for the following decades: \n', ...
                         repmat('-  %s\n', 1, length(warning_vars))); 
            warning_msg = sprintf(msg, warning_vars{:});
            warning(warning_msg)
        end
                  

        % Save to lcs_arable2sng.mat file
        % -------------------------------
        savename = strcat(save_folder, '\lcs_arable2sng.mat');
        save(savename, 'lcs_arable2sng', '-mat', '-v6');
    end
    
    %% (2) Scenario land uses: arable2wood
    %  ===================================
    if exist('do_arable2wood', 'var')
        % Land cover change
        % -----------------
        % Add arable and tgrass hectares to woodland hectares
        % Subtract arable and tgrass hectares from farm hectares
        % Reduce all crops and farm grassland (except permanent grassland and rough grazing) to zero
        lcs_arable2wood = lcs_baseline;
        hectares = lcs_arable2wood.arable_ha_20 + lcs_arable2wood.tgrass_ha_20;
        lcs_arable2wood.hectares = hectares;

        lcs_arable2wood.wood_ha = lcs_arable2wood.wood_ha + hectares;
        lcs_arable2wood.farm_ha = lcs_arable2wood.farm_ha - hectares;

        % Set appropriate land covers to zero
        cols_to_zero = {'arable_ha_20', 'arable_ha_30', 'arable_ha_40', 'arable_ha_50', ...
                        'wheat_ha_20', 'wheat_ha_30', 'wheat_ha_40', 'wheat_ha_50', ...
                        'osr_ha_20', 'osr_ha_30', 'osr_ha_40', 'osr_ha_50', ...
                        'wbar_ha_20', 'wbar_ha_30', 'wbar_ha_40', 'wbar_ha_50', ...
                        'sbar_ha_20', 'sbar_ha_30', 'sbar_ha_40', 'sbar_ha_50', ...
                        'pot_ha_20', 'pot_ha_30', 'pot_ha_40', 'pot_ha_50', ...
                        'sb_ha_20', 'sb_ha_30', 'sb_ha_40', 'sb_ha_50', ...
                        'other_ha_20', 'other_ha_30', 'other_ha_40', 'other_ha_50', ...
                        'tgrass_ha_20', 'tgrass_ha_30', 'tgrass_ha_40', 'tgrass_ha_50'};
        lcs_arable2wood(:, cols_to_zero) = array2table(zeros(size(lcs_arable2wood, 1), length(cols_to_zero)));

        % Set remaining farmland grass types to 2020s amount
        lcs_arable2wood.rgraz_ha_30 = lcs_arable2wood.rgraz_ha_20;
        lcs_arable2wood.rgraz_ha_40 = lcs_arable2wood.rgraz_ha_20;
        lcs_arable2wood.rgraz_ha_50 = lcs_arable2wood.rgraz_ha_20;

        lcs_arable2wood.pgrass_ha_30 = lcs_arable2wood.pgrass_ha_20;
        lcs_arable2wood.pgrass_ha_40 = lcs_arable2wood.pgrass_ha_20;
        lcs_arable2wood.pgrass_ha_50 = lcs_arable2wood.pgrass_ha_20;

        % Reset total farming grassland
        lcs_arable2wood.grass_ha_20 = lcs_arable2wood.rgraz_ha_20 + lcs_arable2wood.pgrass_ha_20;
        lcs_arable2wood.grass_ha_30 = lcs_arable2wood.rgraz_ha_30 + lcs_arable2wood.pgrass_ha_30;
        lcs_arable2wood.grass_ha_40 = lcs_arable2wood.rgraz_ha_40 + lcs_arable2wood.pgrass_ha_40;
        lcs_arable2wood.grass_ha_50 = lcs_arable2wood.rgraz_ha_50 + lcs_arable2wood.pgrass_ha_50;
        
        % check that land uses sum to 400 hectares and stop it not
        [lcm, top_level, crops] = fcn_landuse_check(lcs_arable2sng);
        
        if top_level ~= 1
            warning('The 5 lcm land uses for the ''arable2wood'' option do not sum to 400 ha!')
        end
        
        if any(top_level == 0)
            decade_list = {'20', '30', '40', '50'};
            warning_vars = {};
            ind = find(top_level == 0);
            for i = 1:length(ind)
                decade = decade_list(ind(i));
                warning_vars = [warning_vars, decade];
            end
            msg = strcat('arable and grassland hectares for the ''arable2wood'' option do not sum to farmland hectares for the following decades: \n', ...
                         repmat('-  %s\n', 1, length(warning_vars))); 
            warning_msg = sprintf(msg, warning_vars{:});
            warning(warning_msg)
        end
            
        if any(crops == 0)
            decade_list = {'20', '30', '40', '50'};
            warning_vars = {};
            ind = find(crops == 0);
            for i = 1:length(ind)
                decade = decade_list(ind(i));
                warning_vars = [warning_vars, decade];
            end
            msg = strcat('Crops and grassland for the ''arable2wood'' option do not sum to farmland hectares for the following decades: \n', ...
                         repmat('-  %s\n', 1, length(warning_vars))); 
            warning_msg = sprintf(msg, warning_vars{:});
            warning(warning_msg)
        end

        % Save to lcs_arable2wood.mat file
        % --------------------------------
        savename = strcat(save_folder, '\lcs_arable2wood.mat');
        save(savename, 'lcs_arable2wood', '-mat', '-v6');
    end
    
    %% (3) Scenario land uses: arable2urban
    %  ====================================
    
    % Add arable and tgrass hectares to urban hectares
    % Subtract arable and tgrass hectares from farm hectares
    % Reduce all crops and farm grassland (except permanent grassland and rough grazing) to zero
    if exist('do_arable2urban', 'var')
        lcs_arable2urban = lcs_baseline;
        hectares = lcs_arable2urban.arable_ha_20 + lcs_arable2urban.tgrass_ha_20;
        lcs_arable2urban.hectares = hectares;

        lcs_arable2urban.urban_ha = lcs_arable2urban.urban_ha + hectares;
        lcs_arable2urban.farm_ha = lcs_arable2urban.farm_ha - hectares;

        % Set appropriate land covers to zero
        cols_to_zero = {'arable_ha_20', 'arable_ha_30', 'arable_ha_40', 'arable_ha_50', ...
                        'wheat_ha_20', 'wheat_ha_30', 'wheat_ha_40', 'wheat_ha_50', ...
                        'osr_ha_20', 'osr_ha_30', 'osr_ha_40', 'osr_ha_50', ...
                        'wbar_ha_20', 'wbar_ha_30', 'wbar_ha_40', 'wbar_ha_50', ...
                        'sbar_ha_20', 'sbar_ha_30', 'sbar_ha_40', 'sbar_ha_50', ...
                        'pot_ha_20', 'pot_ha_30', 'pot_ha_40', 'pot_ha_50', ...
                        'sb_ha_20', 'sb_ha_30', 'sb_ha_40', 'sb_ha_50', ...
                        'other_ha_20', 'other_ha_30', 'other_ha_40', 'other_ha_50', ...
                        'tgrass_ha_20', 'tgrass_ha_30', 'tgrass_ha_40', 'tgrass_ha_50'};
        lcs_arable2urban(:, cols_to_zero) = array2table(zeros(size(lcs_arable2urban, 1), length(cols_to_zero)));

        % Set remaining farmland grass types to 2020s amount
        lcs_arable2urban.rgraz_ha_30 = lcs_arable2urban.rgraz_ha_20;
        lcs_arable2urban.rgraz_ha_40 = lcs_arable2urban.rgraz_ha_20;
        lcs_arable2urban.rgraz_ha_50 = lcs_arable2urban.rgraz_ha_20;

        lcs_arable2urban.pgrass_ha_30 = lcs_arable2urban.pgrass_ha_20;
        lcs_arable2urban.pgrass_ha_40 = lcs_arable2urban.pgrass_ha_20;
        lcs_arable2urban.pgrass_ha_50 = lcs_arable2urban.pgrass_ha_20;

        % Reset total farming grassland
        lcs_arable2urban.grass_ha_20 = lcs_arable2urban.rgraz_ha_20 + lcs_arable2urban.pgrass_ha_20;
        lcs_arable2urban.grass_ha_30 = lcs_arable2urban.rgraz_ha_30 + lcs_arable2urban.pgrass_ha_30;
        lcs_arable2urban.grass_ha_40 = lcs_arable2urban.rgraz_ha_40 + lcs_arable2urban.pgrass_ha_40;
        lcs_arable2urban.grass_ha_50 = lcs_arable2urban.rgraz_ha_50 + lcs_arable2urban.pgrass_ha_50;
        
        % check that land uses sum to 400 hectares and stop it not
        [lcm, top_level, crops] = fcn_landuse_check(lcs_arable2sng);
        
        if top_level ~= 1
            warning('The 5 lcm land uses for the ''arable2urban'' option do not sum to 400 ha!')
        end
        
        if any(top_level == 0)
            decade_list = {'20', '30', '40', '50'};
            warning_vars = {};
            ind = find(top_level == 0);
            for i = 1:length(ind)
                decade = decade_list(ind(i));
                warning_vars = [warning_vars, decade];
            end
            msg = strcat('arable and grassland hectares for the ''arable2urban'' option do not sum to farmland hectares for the following decades: \n', ...
                         repmat('-  %s\n', 1, length(warning_vars))); 
            warning_msg = sprintf(msg, warning_vars{:});
            warning(warning_msg)
        end
            
        if any(crops == 0)
            decade_list = {'20', '30', '40', '50'};
            warning_vars = {};
            ind = find(crops == 0);
            for i = 1:length(ind)
                decade = decade_list(ind(i));
                warning_vars = [warning_vars, decade];
            end
            msg = strcat('Crops and grassland for the ''arable2urban'' option do not sum to farmland hectares for the following decades: \n', ...
                         repmat('-  %s\n', 1, length(warning_vars))); 
            warning_msg = sprintf(msg, warning_vars{:});
            warning(warning_msg)
        end

        % Save to lcs_arable2urban.mat file
        % -------------------------------
        savename = strcat(save_folder, '\lcs_arable2urban.mat');
        save(savename, 'lcs_arable2urban', '-mat', '-v6');
    end
    
    %% (4) Scenario land uses: arable2mixed
    %  ====================================
    
    % Add arable and tgrass hectares to a mix of 50% woodland and 50% sng
    % Subtract arable and tgrass hectares from farm hectares
    % Reduce all crops and farm grassland (except permanent grassland and rough grazing) to zero
    if exist('do_arable2mixed', 'var')
        lcs_arable2mixed = lcs_baseline;
        hectares = lcs_arable2mixed.arable_ha_20 + lcs_arable2mixed.tgrass_ha_20;
        lcs_arable2mixed.hectares = hectares;

        lcs_arable2mixed.wood_ha = lcs_arable2mixed.wood_ha + 0.5 .* hectares;
        lcs_arable2mixed.sngrass_ha = lcs_arable2mixed.sngrass_ha + 0.5 .* hectares;
        lcs_arable2mixed.farm_ha = lcs_arable2mixed.farm_ha - hectares;

        % Set appropriate land covers to zero
        cols_to_zero = {'arable_ha_20', 'arable_ha_30', 'arable_ha_40', 'arable_ha_50', ...
                        'wheat_ha_20', 'wheat_ha_30', 'wheat_ha_40', 'wheat_ha_50', ...
                        'osr_ha_20', 'osr_ha_30', 'osr_ha_40', 'osr_ha_50', ...
                        'wbar_ha_20', 'wbar_ha_30', 'wbar_ha_40', 'wbar_ha_50', ...
                        'sbar_ha_20', 'sbar_ha_30', 'sbar_ha_40', 'sbar_ha_50', ...
                        'pot_ha_20', 'pot_ha_30', 'pot_ha_40', 'pot_ha_50', ...
                        'sb_ha_20', 'sb_ha_30', 'sb_ha_40', 'sb_ha_50', ...
                        'other_ha_20', 'other_ha_30', 'other_ha_40', 'other_ha_50', ...
                        'tgrass_ha_20', 'tgrass_ha_30', 'tgrass_ha_40', 'tgrass_ha_50'};
        lcs_arable2mixed(:, cols_to_zero) = array2table(zeros(size(lcs_arable2mixed, 1), length(cols_to_zero)));

        % Set remaining farmland grass types to 2020s amount
        lcs_arable2mixed.rgraz_ha_30 = lcs_arable2mixed.rgraz_ha_20;
        lcs_arable2mixed.rgraz_ha_40 = lcs_arable2mixed.rgraz_ha_20;
        lcs_arable2mixed.rgraz_ha_50 = lcs_arable2mixed.rgraz_ha_20;

        lcs_arable2mixed.pgrass_ha_30 = lcs_arable2mixed.pgrass_ha_20;
        lcs_arable2mixed.pgrass_ha_40 = lcs_arable2mixed.pgrass_ha_20;
        lcs_arable2mixed.pgrass_ha_50 = lcs_arable2mixed.pgrass_ha_20;

        % Reset total farming grassland
        lcs_arable2mixed.grass_ha_20 = lcs_arable2mixed.rgraz_ha_20 + lcs_arable2mixed.pgrass_ha_20;
        lcs_arable2mixed.grass_ha_30 = lcs_arable2mixed.rgraz_ha_30 + lcs_arable2mixed.pgrass_ha_30;
        lcs_arable2mixed.grass_ha_40 = lcs_arable2mixed.rgraz_ha_40 + lcs_arable2mixed.pgrass_ha_40;
        lcs_arable2mixed.grass_ha_50 = lcs_arable2mixed.rgraz_ha_50 + lcs_arable2mixed.pgrass_ha_50;
        
        % check that land uses sum to 400 hectares and stop it not
        [lcm, top_level, crops] = fcn_landuse_check(lcs_arable2sng);
        
        if top_level ~= 1
            warning('The 5 lcm land uses for the ''arable2mixed'' option do not sum to 400 ha!')
        end
        
        if any(top_level == 0)
            decade_list = {'20', '30', '40', '50'};
            warning_vars = {};
            ind = find(top_level == 0);
            for i = 1:length(ind)
                decade = decade_list(ind(i));
                warning_vars = [warning_vars, decade];
            end
            msg = strcat('arable and grassland hectares for the ''arable2mixed'' option do not sum to farmland hectares for the following decades: \n', ...
                         repmat('-  %s\n', 1, length(warning_vars))); 
            warning_msg = sprintf(msg, warning_vars{:});
            warning(warning_msg)
        end
            
        if any(crops == 0)
            decade_list = {'20', '30', '40', '50'};
            warning_vars = {};
            ind = find(crops == 0);
            for i = 1:length(ind)
                decade = decade_list(ind(i));
                warning_vars = [warning_vars, decade];
            end
            msg = strcat('Crops and grassland for the ''arable2mixed'' option do not sum to farmland hectares for the following decades: \n', ...
                         repmat('-  %s\n', 1, length(warning_vars))); 
            warning_msg = sprintf(msg, warning_vars{:});
            warning(warning_msg)
        end

        % Save to lcs_arable2mixed.mat file
        % -------------------------------
        savename = strcat(save_folder, '\lcs_arable2mixed.mat');
        save(savename, 'lcs_arable2mixed', '-mat', '-v6');
    end

    %% (5) Scenario land uses: grass2sng
    %  =================================
    if exist('do_grass2sng', 'var')
        % Land cover change
        % -----------------
        % Add pgrass and rgraz hectares to semi-natural grassland hectares
        % Subtract pgrass and rgraz hectares from farm hectares
        % Reduce pgrass and rgraz to zero
        lcs_grass2sng = lcs_baseline;
        hectares = lcs_grass2sng.pgrass_ha_20 + lcs_grass2sng.rgraz_ha_20;
        lcs_grass2sng.hectares = hectares;

        lcs_grass2sng.sngrass_ha = lcs_grass2sng.sngrass_ha + hectares;
        lcs_grass2sng.farm_ha = lcs_grass2sng.farm_ha - hectares;

        % Set appropriate land covers to zero
        cols_to_zero = {'pgrass_ha_20', 'pgrass_ha_30', 'pgrass_ha_40', 'pgrass_ha_50', ...
                        'rgraz_ha_20', 'rgraz_ha_30', 'rgraz_ha_40', 'rgraz_ha_50'};
        lcs_grass2sng(:, cols_to_zero) = array2table(zeros(size(lcs_grass2sng, 1), length(cols_to_zero)));

        % Set remaining farmland grass types to 2020s amount
        lcs_grass2sng.arable_ha_30 = lcs_grass2sng.arable_ha_20;
        lcs_grass2sng.arable_ha_40 = lcs_grass2sng.arable_ha_20;
        lcs_grass2sng.arable_ha_50 = lcs_grass2sng.arable_ha_20;

        lcs_grass2sng.wheat_ha_30 = lcs_grass2sng.wheat_ha_20;
        lcs_grass2sng.wheat_ha_40 = lcs_grass2sng.wheat_ha_20;
        lcs_grass2sng.wheat_ha_50 = lcs_grass2sng.wheat_ha_20;

        lcs_grass2sng.osr_ha_30 = lcs_grass2sng.osr_ha_20;
        lcs_grass2sng.osr_ha_40 = lcs_grass2sng.osr_ha_20;
        lcs_grass2sng.osr_ha_50 = lcs_grass2sng.osr_ha_20;

        lcs_grass2sng.wbar_ha_30 = lcs_grass2sng.wbar_ha_20;
        lcs_grass2sng.wbar_ha_40 = lcs_grass2sng.wbar_ha_20;
        lcs_grass2sng.wbar_ha_50 = lcs_grass2sng.wbar_ha_20;

        lcs_grass2sng.sbar_ha_30 = lcs_grass2sng.sbar_ha_20;
        lcs_grass2sng.sbar_ha_40 = lcs_grass2sng.sbar_ha_20;
        lcs_grass2sng.sbar_ha_50 = lcs_grass2sng.sbar_ha_20;

        lcs_grass2sng.pot_ha_30 = lcs_grass2sng.pot_ha_20;
        lcs_grass2sng.pot_ha_40 = lcs_grass2sng.pot_ha_20;
        lcs_grass2sng.pot_ha_50 = lcs_grass2sng.pot_ha_20;

        lcs_grass2sng.sb_ha_30 = lcs_grass2sng.sb_ha_20;
        lcs_grass2sng.sb_ha_40 = lcs_grass2sng.sb_ha_20;
        lcs_grass2sng.sb_ha_50 = lcs_grass2sng.sb_ha_20;

        lcs_grass2sng.other_ha_30 = lcs_grass2sng.other_ha_20;
        lcs_grass2sng.other_ha_40 = lcs_grass2sng.other_ha_20;
        lcs_grass2sng.other_ha_50 = lcs_grass2sng.other_ha_20;

        lcs_grass2sng.tgrass_ha_30 = lcs_grass2sng.tgrass_ha_20;
        lcs_grass2sng.tgrass_ha_40 = lcs_grass2sng.tgrass_ha_20;
        lcs_grass2sng.tgrass_ha_50 = lcs_grass2sng.tgrass_ha_20;

        % Reset total farming grassland
        lcs_grass2sng.grass_ha_20 = lcs_grass2sng.tgrass_ha_20;
        lcs_grass2sng.grass_ha_30 = lcs_grass2sng.tgrass_ha_30;
        lcs_grass2sng.grass_ha_40 = lcs_grass2sng.tgrass_ha_40;
        lcs_grass2sng.grass_ha_50 = lcs_grass2sng.tgrass_ha_50;

        % check that land uses sum to 400 hectares and stop it not
        [lcm, top_level, crops] = fcn_landuse_check(lcs_arable2sng);
        
        if top_level ~= 1
            warning('The 5 lcm land uses for the ''grass2sng'' option do not sum to 400 ha!')
        end
        
        if any(top_level == 0)
            decade_list = {'20', '30', '40', '50'};
            warning_vars = {};
            ind = find(top_level == 0);
            for i = 1:length(ind)
                decade = decade_list(ind(i));
                warning_vars = [warning_vars, decade];
            end
            msg = strcat('arable and grassland hectares for the ''grass2sng'' option do not sum to farmland hectares for the following decades: \n', ...
                         repmat('-  %s\n', 1, length(warning_vars))); 
            warning_msg = sprintf(msg, warning_vars{:});
            warning(warning_msg)
        end
            
        if any(crops == 0)
            decade_list = {'20', '30', '40', '50'};
            warning_vars = {};
            ind = find(crops == 0);
            for i = 1:length(ind)
                decade = decade_list(ind(i));
                warning_vars = [warning_vars, decade];
            end
            msg = strcat('Crops and grassland for the ''grass2sng'' option do not sum to farmland hectares for the following decades: \n', ...
                         repmat('-  %s\n', 1, length(warning_vars))); 
            warning_msg = sprintf(msg, warning_vars{:});
            warning(warning_msg)
        end
        
        % Save to lcs_grass2sng.mat file
        % -------------------------------
        savename = strcat(save_folder, '\lcs_grass2sng.mat');
        save(savename, 'lcs_grass2sng', '-mat', '-v6');
    end

    %% (6) Scenario land uses: grass2wood
    %  ==================================
    if exist('do_grass2wood', 'var')
        % Land cover change
        % -----------------
        % Add pgrass and rgraz hectares to woodland hectares
        % Subtract pgrass and rgraz hectares from farm hectares
        % Reduce pgrass and rgraz to zero
        lcs_grass2wood = lcs_baseline;
        hectares = lcs_grass2wood.pgrass_ha_20 + lcs_grass2wood.rgraz_ha_20;
        lcs_grass2wood.hectares = hectares;

        lcs_grass2wood.wood_ha = lcs_grass2wood.wood_ha + hectares;
        lcs_grass2wood.farm_ha = lcs_grass2wood.farm_ha - hectares;

        % Set appropriate land covers to zero
        cols_to_zero = {'pgrass_ha_20', 'pgrass_ha_30', 'pgrass_ha_40', 'pgrass_ha_50', ...
                        'rgraz_ha_20', 'rgraz_ha_30', 'rgraz_ha_40', 'rgraz_ha_50'};
        lcs_grass2wood(:, cols_to_zero) = array2table(zeros(size(lcs_grass2wood, 1), length(cols_to_zero)));

        % Set remaining farmland grass types to 2020s amount
        lcs_grass2wood.arable_ha_30 = lcs_grass2wood.arable_ha_20;
        lcs_grass2wood.arable_ha_40 = lcs_grass2wood.arable_ha_20;
        lcs_grass2wood.arable_ha_50 = lcs_grass2wood.arable_ha_20;

        lcs_grass2wood.wheat_ha_30 = lcs_grass2wood.wheat_ha_20;
        lcs_grass2wood.wheat_ha_40 = lcs_grass2wood.wheat_ha_20;
        lcs_grass2wood.wheat_ha_50 = lcs_grass2wood.wheat_ha_20;

        lcs_grass2wood.osr_ha_30 = lcs_grass2wood.osr_ha_20;
        lcs_grass2wood.osr_ha_40 = lcs_grass2wood.osr_ha_20;
        lcs_grass2wood.osr_ha_50 = lcs_grass2wood.osr_ha_20;

        lcs_grass2wood.wbar_ha_30 = lcs_grass2wood.wbar_ha_20;
        lcs_grass2wood.wbar_ha_40 = lcs_grass2wood.wbar_ha_20;
        lcs_grass2wood.wbar_ha_50 = lcs_grass2wood.wbar_ha_20;

        lcs_grass2wood.sbar_ha_30 = lcs_grass2wood.sbar_ha_20;
        lcs_grass2wood.sbar_ha_40 = lcs_grass2wood.sbar_ha_20;
        lcs_grass2wood.sbar_ha_50 = lcs_grass2wood.sbar_ha_20;

        lcs_grass2wood.pot_ha_30 = lcs_grass2wood.pot_ha_20;
        lcs_grass2wood.pot_ha_40 = lcs_grass2wood.pot_ha_20;
        lcs_grass2wood.pot_ha_50 = lcs_grass2wood.pot_ha_20;

        lcs_grass2wood.sb_ha_30 = lcs_grass2wood.sb_ha_20;
        lcs_grass2wood.sb_ha_40 = lcs_grass2wood.sb_ha_20;
        lcs_grass2wood.sb_ha_50 = lcs_grass2wood.sb_ha_20;

        lcs_grass2wood.other_ha_30 = lcs_grass2wood.other_ha_20;
        lcs_grass2wood.other_ha_40 = lcs_grass2wood.other_ha_20;
        lcs_grass2wood.other_ha_50 = lcs_grass2wood.other_ha_20;

        lcs_grass2wood.tgrass_ha_30 = lcs_grass2wood.tgrass_ha_20;
        lcs_grass2wood.tgrass_ha_40 = lcs_grass2wood.tgrass_ha_20;
        lcs_grass2wood.tgrass_ha_50 = lcs_grass2wood.tgrass_ha_20;

        % Reset total farming grassland
        lcs_grass2wood.grass_ha_20 = lcs_grass2wood.tgrass_ha_20;
        lcs_grass2wood.grass_ha_30 = lcs_grass2wood.tgrass_ha_30;
        lcs_grass2wood.grass_ha_40 = lcs_grass2wood.tgrass_ha_40;
        lcs_grass2wood.grass_ha_50 = lcs_grass2wood.tgrass_ha_50;
        
        % check that land uses sum to 400 hectares and stop it not
        [lcm, top_level, crops] = fcn_landuse_check(lcs_arable2sng);
        
        if top_level ~= 1
            warning('The 5 lcm land uses for the ''grass2wood'' option do not sum to 400 ha!')
        end
        
        if any(top_level == 0)
            decade_list = {'20', '30', '40', '50'};
            warning_vars = {};
            ind = find(top_level == 0);
            for i = 1:length(ind)
                decade = decade_list(ind(i));
                warning_vars = [warning_vars, decade];
            end
            msg = strcat('arable and grassland hectares for the ''grass2wood'' option do not sum to farmland hectares for the following decades: \n', ...
                         repmat('-  %s\n', 1, length(warning_vars))); 
            warning_msg = sprintf(msg, warning_vars{:});
            warning(warning_msg)
        end
            
        if any(crops == 0)
            decade_list = {'20', '30', '40', '50'};
            warning_vars = {};
            ind = find(crops == 0);
            for i = 1:length(ind)
                decade = decade_list(ind(i));
                warning_vars = [warning_vars, decade];
            end
            msg = strcat('Crops and grassland for the ''grass2wood'' option do not sum to farmland hectares for the following decades: \n', ...
                         repmat('-  %s\n', 1, length(warning_vars))); 
            warning_msg = sprintf(msg, warning_vars{:});
            warning(warning_msg)
        end

        % Save to lcs_grass2wood.mat file
        % -------------------------------
        savename = strcat(save_folder, '\lcs_grass2wood.mat');
        save(savename, 'lcs_grass2wood', '-mat', '-v6');
    end

    
    %% (7) Scenario land uses: grass2urban
    %  ===================================
    if exist('do_grass2urban', 'var')
        % Land cover change
        % -----------------
        % Add pgrass and rgraz hectares to urban hectares
        % Subtract pgrass and rgraz hectares from farm hectares
        % Reduce pgrass and rgraz to zero
        lcs_grass2urban = lcs_baseline;
        hectares = lcs_grass2urban.pgrass_ha_20 + lcs_grass2urban.rgraz_ha_20;
        lcs_grass2urban.hectares = hectares;

        lcs_grass2urban.urban_ha = lcs_grass2urban.urban_ha + hectares;
        lcs_grass2urban.farm_ha = lcs_grass2urban.farm_ha - hectares;

        % Set appropriate land covers to zero
        cols_to_zero = {'pgrass_ha_20', 'pgrass_ha_30', 'pgrass_ha_40', 'pgrass_ha_50', ...
                        'rgraz_ha_20', 'rgraz_ha_30', 'rgraz_ha_40', 'rgraz_ha_50'};
        lcs_grass2urban(:, cols_to_zero) = array2table(zeros(size(lcs_grass2urban, 1), length(cols_to_zero)));

        % Set remaining farmland grass types to 2020s amount
        lcs_grass2urban.arable_ha_30 = lcs_grass2urban.arable_ha_20;
        lcs_grass2urban.arable_ha_40 = lcs_grass2urban.arable_ha_20;
        lcs_grass2urban.arable_ha_50 = lcs_grass2urban.arable_ha_20;

        lcs_grass2urban.wheat_ha_30 = lcs_grass2urban.wheat_ha_20;
        lcs_grass2urban.wheat_ha_40 = lcs_grass2urban.wheat_ha_20;
        lcs_grass2urban.wheat_ha_50 = lcs_grass2urban.wheat_ha_20;

        lcs_grass2urban.osr_ha_30 = lcs_grass2urban.osr_ha_20;
        lcs_grass2urban.osr_ha_40 = lcs_grass2urban.osr_ha_20;
        lcs_grass2urban.osr_ha_50 = lcs_grass2urban.osr_ha_20;

        lcs_grass2urban.wbar_ha_30 = lcs_grass2urban.wbar_ha_20;
        lcs_grass2urban.wbar_ha_40 = lcs_grass2urban.wbar_ha_20;
        lcs_grass2urban.wbar_ha_50 = lcs_grass2urban.wbar_ha_20;

        lcs_grass2urban.sbar_ha_30 = lcs_grass2urban.sbar_ha_20;
        lcs_grass2urban.sbar_ha_40 = lcs_grass2urban.sbar_ha_20;
        lcs_grass2urban.sbar_ha_50 = lcs_grass2urban.sbar_ha_20;

        lcs_grass2urban.pot_ha_30 = lcs_grass2urban.pot_ha_20;
        lcs_grass2urban.pot_ha_40 = lcs_grass2urban.pot_ha_20;
        lcs_grass2urban.pot_ha_50 = lcs_grass2urban.pot_ha_20;

        lcs_grass2urban.sb_ha_30 = lcs_grass2urban.sb_ha_20;
        lcs_grass2urban.sb_ha_40 = lcs_grass2urban.sb_ha_20;
        lcs_grass2urban.sb_ha_50 = lcs_grass2urban.sb_ha_20;

        lcs_grass2urban.other_ha_30 = lcs_grass2urban.other_ha_20;
        lcs_grass2urban.other_ha_40 = lcs_grass2urban.other_ha_20;
        lcs_grass2urban.other_ha_50 = lcs_grass2urban.other_ha_20;

        lcs_grass2urban.tgrass_ha_30 = lcs_grass2urban.tgrass_ha_20;
        lcs_grass2urban.tgrass_ha_40 = lcs_grass2urban.tgrass_ha_20;
        lcs_grass2urban.tgrass_ha_50 = lcs_grass2urban.tgrass_ha_20;

        % Reset total farming grassland
        lcs_grass2urban.grass_ha_20 = lcs_grass2urban.tgrass_ha_20;
        lcs_grass2urban.grass_ha_30 = lcs_grass2urban.tgrass_ha_30;
        lcs_grass2urban.grass_ha_40 = lcs_grass2urban.tgrass_ha_40;
        lcs_grass2urban.grass_ha_50 = lcs_grass2urban.tgrass_ha_50;
        
        % check that land uses sum to 400 hectares and stop it not
        [lcm, top_level, crops] = fcn_landuse_check(lcs_arable2sng);
        
        if top_level ~= 1
            warning('The 5 lcm land uses for the ''grass2urban'' option do not sum to 400 ha!')
        end
        
        if any(top_level == 0)
            decade_list = {'20', '30', '40', '50'};
            warning_vars = {};
            ind = find(top_level == 0);
            for i = 1:length(ind)
                decade = decade_list(ind(i));
                warning_vars = [warning_vars, decade];
            end
            msg = strcat('arable and grassland hectares for the ''grass2urban'' option do not sum to farmland hectares for the following decades: \n', ...
                         repmat('-  %s\n', 1, length(warning_vars))); 
            warning_msg = sprintf(msg, warning_vars{:});
            warning(warning_msg)
        end
            
        if any(crops == 0)
            decade_list = {'20', '30', '40', '50'};
            warning_vars = {};
            ind = find(crops == 0);
            for i = 1:length(ind)
                decade = decade_list(ind(i));
                warning_vars = [warning_vars, decade];
            end
            msg = strcat('Crops and grassland for the ''grass2urban'' option do not sum to farmland hectares for the following decades: \n', ...
                         repmat('-  %s\n', 1, length(warning_vars))); 
            warning_msg = sprintf(msg, warning_vars{:});
            warning(warning_msg)
        end


        % Save to lcs_grass2urban.mat file
        % -------------------------------
        savename = strcat(save_folder, '\lcs_grass2urban.mat');
        save(savename, 'lcs_grass2urban', '-mat', '-v6');
    end
    
    %% (8) Scenario land uses: grass2mixed
    %  ===================================
    if exist('do_grass2mixed', 'var')
        % Land cover change
        % -----------------
        % Add pgrass and rgraz hectares to a mix of 50% wood and 50% sng
        % Subtract pgrass and rgraz hectares from farm hectares
        % Reduce pgrass and rgraz to zero
        lcs_grass2mixed = lcs_baseline;
        hectares = lcs_grass2mixed.pgrass_ha_20 + lcs_grass2mixed.rgraz_ha_20;
        lcs_grass2mixed.hectares = hectares;

        lcs_grass2mixed.wood_ha = lcs_grass2mixed.wood_ha + 0.5 .* hectares;
        lcs_grass2mixed.sngrass_ha = lcs_grass2mixed.sngrass_ha + 0.5 .* hectares;
        lcs_grass2mixed.farm_ha = lcs_grass2mixed.farm_ha - hectares;

        % Set appropriate land covers to zero
        cols_to_zero = {'pgrass_ha_20', 'pgrass_ha_30', 'pgrass_ha_40', 'pgrass_ha_50', ...
                        'rgraz_ha_20', 'rgraz_ha_30', 'rgraz_ha_40', 'rgraz_ha_50'};
        lcs_grass2mixed(:, cols_to_zero) = array2table(zeros(size(lcs_grass2mixed, 1), length(cols_to_zero)));

        % Set remaining farmland grass types to 2020s amount
        lcs_grass2mixed.arable_ha_30 = lcs_grass2mixed.arable_ha_20;
        lcs_grass2mixed.arable_ha_40 = lcs_grass2mixed.arable_ha_20;
        lcs_grass2mixed.arable_ha_50 = lcs_grass2mixed.arable_ha_20;

        lcs_grass2mixed.wheat_ha_30 = lcs_grass2mixed.wheat_ha_20;
        lcs_grass2mixed.wheat_ha_40 = lcs_grass2mixed.wheat_ha_20;
        lcs_grass2mixed.wheat_ha_50 = lcs_grass2mixed.wheat_ha_20;

        lcs_grass2mixed.osr_ha_30 = lcs_grass2mixed.osr_ha_20;
        lcs_grass2mixed.osr_ha_40 = lcs_grass2mixed.osr_ha_20;
        lcs_grass2mixed.osr_ha_50 = lcs_grass2mixed.osr_ha_20;

        lcs_grass2mixed.wbar_ha_30 = lcs_grass2mixed.wbar_ha_20;
        lcs_grass2mixed.wbar_ha_40 = lcs_grass2mixed.wbar_ha_20;
        lcs_grass2mixed.wbar_ha_50 = lcs_grass2mixed.wbar_ha_20;

        lcs_grass2mixed.sbar_ha_30 = lcs_grass2mixed.sbar_ha_20;
        lcs_grass2mixed.sbar_ha_40 = lcs_grass2mixed.sbar_ha_20;
        lcs_grass2mixed.sbar_ha_50 = lcs_grass2mixed.sbar_ha_20;

        lcs_grass2mixed.pot_ha_30 = lcs_grass2mixed.pot_ha_20;
        lcs_grass2mixed.pot_ha_40 = lcs_grass2mixed.pot_ha_20;
        lcs_grass2mixed.pot_ha_50 = lcs_grass2mixed.pot_ha_20;

        lcs_grass2mixed.sb_ha_30 = lcs_grass2mixed.sb_ha_20;
        lcs_grass2mixed.sb_ha_40 = lcs_grass2mixed.sb_ha_20;
        lcs_grass2mixed.sb_ha_50 = lcs_grass2mixed.sb_ha_20;

        lcs_grass2mixed.other_ha_30 = lcs_grass2mixed.other_ha_20;
        lcs_grass2mixed.other_ha_40 = lcs_grass2mixed.other_ha_20;
        lcs_grass2mixed.other_ha_50 = lcs_grass2mixed.other_ha_20;

        lcs_grass2mixed.tgrass_ha_30 = lcs_grass2mixed.tgrass_ha_20;
        lcs_grass2mixed.tgrass_ha_40 = lcs_grass2mixed.tgrass_ha_20;
        lcs_grass2mixed.tgrass_ha_50 = lcs_grass2mixed.tgrass_ha_20;

        % Reset total farming grassland
        lcs_grass2mixed.grass_ha_20 = lcs_grass2mixed.tgrass_ha_20;
        lcs_grass2mixed.grass_ha_30 = lcs_grass2mixed.tgrass_ha_30;
        lcs_grass2mixed.grass_ha_40 = lcs_grass2mixed.tgrass_ha_40;
        lcs_grass2mixed.grass_ha_50 = lcs_grass2mixed.tgrass_ha_50;
        
        % check that land uses sum to 400 hectares and stop it not
        [lcm, top_level, crops] = fcn_landuse_check(lcs_arable2sng);
        
        if top_level ~= 1
            warning('The 5 lcm land uses for the ''grass2mixed'' option do not sum to 400 ha!')
        end
        
        if any(top_level == 0)
            decade_list = {'20', '30', '40', '50'};
            warning_vars = {};
            ind = find(top_level == 0);
            for i = 1:length(ind)
                decade = decade_list(ind(i));
                warning_vars = [warning_vars, decade];
            end
            msg = strcat('arable and grassland hectares for the ''grass2mixed'' option do not sum to farmland hectares for the following decades: \n', ...
                         repmat('-  %s\n', 1, length(warning_vars))); 
            warning_msg = sprintf(msg, warning_vars{:});
            warning(warning_msg)
        end
            
        if any(crops == 0)
            decade_list = {'20', '30', '40', '50'};
            warning_vars = {};
            ind = find(crops == 0);
            for i = 1:length(ind)
                decade = decade_list(ind(i));
                warning_vars = [warning_vars, decade];
            end
            msg = strcat('Crops and grassland for the ''grass2mixed'' option do not sum to farmland hectares for the following decades: \n', ...
                         repmat('-  %s\n', 1, length(warning_vars))); 
            warning_msg = sprintf(msg, warning_vars{:});
            warning(warning_msg)
        end


        % Save to lcs_grass2mixed.mat file
        % -------------------------------
        savename = strcat(save_folder, '\lcs_grass2mixed.mat');
        save(savename, 'lcs_grass2mixed', '-mat', '-v6');
    end
    
    %% (9) Scenario land uses: sng2urban
    %  =================================
    if exist('do_sng2urban', 'var')
        % Land cover change
        % -----------------
        % Add sngrass hectares to urban hectares
        % Reduce sngrass to zero
        lcs_sng2urban = lcs_baseline;
        hectares = lcs_sng2urban.sngrass_ha;
        lcs_sng2urban.hectares = hectares;

        lcs_sng2urban.urban_ha = lcs_sng2urban.urban_ha + hectares;
        lcs_sng2urban.sngrass_ha = lcs_sng2urban.sngrass_ha - hectares;

        % Set remaining farmland grass types to 2020s amount
        lcs_sng2urban.arable_ha_30 = lcs_sng2urban.arable_ha_20;
        lcs_sng2urban.arable_ha_40 = lcs_sng2urban.arable_ha_20;
        lcs_sng2urban.arable_ha_50 = lcs_sng2urban.arable_ha_20;

        lcs_sng2urban.wheat_ha_30 = lcs_sng2urban.wheat_ha_20;
        lcs_sng2urban.wheat_ha_40 = lcs_sng2urban.wheat_ha_20;
        lcs_sng2urban.wheat_ha_50 = lcs_sng2urban.wheat_ha_20;

        lcs_sng2urban.osr_ha_30 = lcs_sng2urban.osr_ha_20;
        lcs_sng2urban.osr_ha_40 = lcs_sng2urban.osr_ha_20;
        lcs_sng2urban.osr_ha_50 = lcs_sng2urban.osr_ha_20;

        lcs_sng2urban.wbar_ha_30 = lcs_sng2urban.wbar_ha_20;
        lcs_sng2urban.wbar_ha_40 = lcs_sng2urban.wbar_ha_20;
        lcs_sng2urban.wbar_ha_50 = lcs_sng2urban.wbar_ha_20;

        lcs_sng2urban.sbar_ha_30 = lcs_sng2urban.sbar_ha_20;
        lcs_sng2urban.sbar_ha_40 = lcs_sng2urban.sbar_ha_20;
        lcs_sng2urban.sbar_ha_50 = lcs_sng2urban.sbar_ha_20;

        lcs_sng2urban.pot_ha_30 = lcs_sng2urban.pot_ha_20;
        lcs_sng2urban.pot_ha_40 = lcs_sng2urban.pot_ha_20;
        lcs_sng2urban.pot_ha_50 = lcs_sng2urban.pot_ha_20;

        lcs_sng2urban.sb_ha_30 = lcs_sng2urban.sb_ha_20;
        lcs_sng2urban.sb_ha_40 = lcs_sng2urban.sb_ha_20;
        lcs_sng2urban.sb_ha_50 = lcs_sng2urban.sb_ha_20;

        lcs_sng2urban.other_ha_30 = lcs_sng2urban.other_ha_20;
        lcs_sng2urban.other_ha_40 = lcs_sng2urban.other_ha_20;
        lcs_sng2urban.other_ha_50 = lcs_sng2urban.other_ha_20;

        lcs_sng2urban.tgrass_ha_30 = lcs_sng2urban.tgrass_ha_20;
        lcs_sng2urban.tgrass_ha_40 = lcs_sng2urban.tgrass_ha_20;
        lcs_sng2urban.tgrass_ha_50 = lcs_sng2urban.tgrass_ha_20;
        
        lcs_sng2urban.pgrass_ha_30 = lcs_sng2urban.pgrass_ha_20;
        lcs_sng2urban.pgrass_ha_40 = lcs_sng2urban.pgrass_ha_20;
        lcs_sng2urban.pgrass_ha_50 = lcs_sng2urban.pgrass_ha_20;

        lcs_sng2urban.rgraz_ha_30 = lcs_sng2urban.rgraz_ha_20;
        lcs_sng2urban.rgraz_ha_40 = lcs_sng2urban.rgraz_ha_20;
        lcs_sng2urban.rgraz_ha_50 = lcs_sng2urban.rgraz_ha_20;


        % Reset total farming grassland
        lcs_sng2urban.grass_ha_20 = lcs_sng2urban.tgrass_ha_20 + lcs_sng2urban.pgrass_ha_20 + lcs_sng2urban.rgraz_ha_20;
        lcs_sng2urban.grass_ha_30 = lcs_sng2urban.tgrass_ha_30 + lcs_sng2urban.pgrass_ha_30 + lcs_sng2urban.rgraz_ha_30;
        lcs_sng2urban.grass_ha_40 = lcs_sng2urban.tgrass_ha_40 + lcs_sng2urban.pgrass_ha_40 + lcs_sng2urban.rgraz_ha_40;
        lcs_sng2urban.grass_ha_50 = lcs_sng2urban.tgrass_ha_50 + lcs_sng2urban.pgrass_ha_50 + lcs_sng2urban.rgraz_ha_50;
        
        % check that land uses sum to 400 hectares and stop it not
        [lcm, top_level, crops] = fcn_landuse_check(lcs_arable2sng);
        
        if top_level ~= 1
            warning('The 5 lcm land uses for the ''sng2urban'' option do not sum to 400 ha!')
        end
        
        if any(top_level == 0)
            decade_list = {'20', '30', '40', '50'};
            warning_vars = {};
            ind = find(top_level == 0);
            for i = 1:length(ind)
                decade = decade_list(ind(i));
                warning_vars = [warning_vars, decade];
            end
            msg = strcat('arable and grassland hectares for the ''sng2urban'' option do not sum to farmland hectares for the following decades: \n', ...
                         repmat('-  %s\n', 1, length(warning_vars))); 
            warning_msg = sprintf(msg, warning_vars{:});
            warning(warning_msg)
        end
            
        if any(crops == 0)
            decade_list = {'20', '30', '40', '50'};
            warning_vars = {};
            ind = find(crops == 0);
            for i = 1:length(ind)
                decade = decade_list(ind(i));
                warning_vars = [warning_vars, decade];
            end
            msg = strcat('Crops and grassland for the ''sng2urban'' option do not sum to farmland hectares for the following decades: \n', ...
                         repmat('-  %s\n', 1, length(warning_vars))); 
            warning_msg = sprintf(msg, warning_vars{:});
            warning(warning_msg)
        end


        % Save to lcs_sng2urban.mat file
        % -------------------------------
        savename = strcat(save_folder, '\lcs_sng2urban.mat');
        save(savename, 'lcs_sng2urban', '-mat', '-v6');
    end
    
    %% (10) Scenario land uses: wood2urban
    %  ===================================
    if exist('do_wood2urban', 'var')
        % Land cover change
        % -----------------
        % Add woodland hectares to urban hectares
        % Reduce sngrass to zero
        lcs_wood2urban = lcs_baseline;
        hectares = lcs_wood2urban.wood_ha;
        lcs_wood2urban.hectares = hectares;

        lcs_wood2urban.urban_ha = lcs_wood2urban.urban_ha + hectares;
        lcs_wood2urban.wood_ha = lcs_wood2urban.wood_ha - hectares;

        % Set remaining farmland grass types to 2020s amount
        lcs_wood2urban.arable_ha_30 = lcs_wood2urban.arable_ha_20;
        lcs_wood2urban.arable_ha_40 = lcs_wood2urban.arable_ha_20;
        lcs_wood2urban.arable_ha_50 = lcs_wood2urban.arable_ha_20;

        lcs_wood2urban.wheat_ha_30 = lcs_wood2urban.wheat_ha_20;
        lcs_wood2urban.wheat_ha_40 = lcs_wood2urban.wheat_ha_20;
        lcs_wood2urban.wheat_ha_50 = lcs_wood2urban.wheat_ha_20;

        lcs_wood2urban.osr_ha_30 = lcs_wood2urban.osr_ha_20;
        lcs_wood2urban.osr_ha_40 = lcs_wood2urban.osr_ha_20;
        lcs_wood2urban.osr_ha_50 = lcs_wood2urban.osr_ha_20;

        lcs_wood2urban.wbar_ha_30 = lcs_wood2urban.wbar_ha_20;
        lcs_wood2urban.wbar_ha_40 = lcs_wood2urban.wbar_ha_20;
        lcs_wood2urban.wbar_ha_50 = lcs_wood2urban.wbar_ha_20;

        lcs_wood2urban.sbar_ha_30 = lcs_wood2urban.sbar_ha_20;
        lcs_wood2urban.sbar_ha_40 = lcs_wood2urban.sbar_ha_20;
        lcs_wood2urban.sbar_ha_50 = lcs_wood2urban.sbar_ha_20;

        lcs_wood2urban.pot_ha_30 = lcs_wood2urban.pot_ha_20;
        lcs_wood2urban.pot_ha_40 = lcs_wood2urban.pot_ha_20;
        lcs_wood2urban.pot_ha_50 = lcs_wood2urban.pot_ha_20;

        lcs_wood2urban.sb_ha_30 = lcs_wood2urban.sb_ha_20;
        lcs_wood2urban.sb_ha_40 = lcs_wood2urban.sb_ha_20;
        lcs_wood2urban.sb_ha_50 = lcs_wood2urban.sb_ha_20;

        lcs_wood2urban.other_ha_30 = lcs_wood2urban.other_ha_20;
        lcs_wood2urban.other_ha_40 = lcs_wood2urban.other_ha_20;
        lcs_wood2urban.other_ha_50 = lcs_wood2urban.other_ha_20;

        lcs_wood2urban.tgrass_ha_30 = lcs_wood2urban.tgrass_ha_20;
        lcs_wood2urban.tgrass_ha_40 = lcs_wood2urban.tgrass_ha_20;
        lcs_wood2urban.tgrass_ha_50 = lcs_wood2urban.tgrass_ha_20;
        
        lcs_wood2urban.pgrass_ha_30 = lcs_wood2urban.pgrass_ha_20;
        lcs_wood2urban.pgrass_ha_40 = lcs_wood2urban.pgrass_ha_20;
        lcs_wood2urban.pgrass_ha_50 = lcs_wood2urban.pgrass_ha_20;

        lcs_wood2urban.rgraz_ha_30 = lcs_wood2urban.rgraz_ha_20;
        lcs_wood2urban.rgraz_ha_40 = lcs_wood2urban.rgraz_ha_20;
        lcs_wood2urban.rgraz_ha_50 = lcs_wood2urban.rgraz_ha_20;


        % Reset total farming grassland
        lcs_wood2urban.grass_ha_20 = lcs_wood2urban.tgrass_ha_20 + lcs_wood2urban.pgrass_ha_20 + lcs_wood2urban.rgraz_ha_20;
        lcs_wood2urban.grass_ha_30 = lcs_wood2urban.tgrass_ha_30 + lcs_wood2urban.pgrass_ha_30 + lcs_wood2urban.rgraz_ha_30;
        lcs_wood2urban.grass_ha_40 = lcs_wood2urban.tgrass_ha_40 + lcs_wood2urban.pgrass_ha_40 + lcs_wood2urban.rgraz_ha_40;
        lcs_wood2urban.grass_ha_50 = lcs_wood2urban.tgrass_ha_50 + lcs_wood2urban.pgrass_ha_50 + lcs_wood2urban.rgraz_ha_50;

        % check that land uses sum to 400 hectares and stop it not
        [lcm, top_level, crops] = fcn_landuse_check(lcs_arable2sng);
        
        if top_level ~= 1
            warning('The 5 lcm land uses for the ''wood2urban'' option do not sum to 400 ha!')
        end
        
        if any(top_level == 0)
            decade_list = {'20', '30', '40', '50'};
            warning_vars = {};
            ind = find(top_level == 0);
            for i = 1:length(ind)
                decade = decade_list(ind(i));
                warning_vars = [warning_vars, decade];
            end
            msg = strcat('arable and grassland hectares for the ''wood2urban'' option do not sum to farmland hectares for the following decades: \n', ...
                         repmat('-  %s\n', 1, length(warning_vars))); 
            warning_msg = sprintf(msg, warning_vars{:});
            warning(warning_msg)
        end
            
        if any(crops == 0)
            decade_list = {'20', '30', '40', '50'};
            warning_vars = {};
            ind = find(crops == 0);
            for i = 1:length(ind)
                decade = decade_list(ind(i));
                warning_vars = [warning_vars, decade];
            end
            msg = strcat('Crops and grassland for the ''wood2urban'' option do not sum to farmland hectares for the following decades: \n', ...
                         repmat('-  %s\n', 1, length(warning_vars))); 
            warning_msg = sprintf(msg, warning_vars{:});
            warning(warning_msg)
        end

        
        % Save to lcs_wood2urban.mat file
        % -------------------------------
        savename = strcat(save_folder, '\lcs_wood2urban.mat');
        save(savename, 'lcs_wood2urban', '-mat', '-v6');
    end
    
    %% (11) Scenario land uses: arable2thirds
    %  ======================================
    
    % Add arable and tgrass hectares to a mix of 330% woodland and 67% sng
    % Subtract arable and tgrass hectares from farm hectares
    % Reduce all crops and farm grassland (except permanent grassland and rough grazing) to zero
    if exist('do_arable2thirds', 'var')
        lcs_arable2thirds = lcs_baseline;
        hectares = lcs_arable2thirds.arable_ha_20 + lcs_arable2thirds.tgrass_ha_20;
        lcs_arable2thirds.hectares = hectares;

        lcs_arable2thirds.wood_ha = lcs_arable2thirds.wood_ha + 0.33 .* hectares;
        lcs_arable2thirds.sngrass_ha = lcs_arable2thirds.sngrass_ha + 0.67 .* hectares;
        lcs_arable2thirds.farm_ha = lcs_arable2thirds.farm_ha - hectares;

        % Set appropriate land covers to zero
        cols_to_zero = {'arable_ha_20', 'arable_ha_30', 'arable_ha_40', 'arable_ha_50', ...
                        'wheat_ha_20', 'wheat_ha_30', 'wheat_ha_40', 'wheat_ha_50', ...
                        'osr_ha_20', 'osr_ha_30', 'osr_ha_40', 'osr_ha_50', ...
                        'wbar_ha_20', 'wbar_ha_30', 'wbar_ha_40', 'wbar_ha_50', ...
                        'sbar_ha_20', 'sbar_ha_30', 'sbar_ha_40', 'sbar_ha_50', ...
                        'pot_ha_20', 'pot_ha_30', 'pot_ha_40', 'pot_ha_50', ...
                        'sb_ha_20', 'sb_ha_30', 'sb_ha_40', 'sb_ha_50', ...
                        'other_ha_20', 'other_ha_30', 'other_ha_40', 'other_ha_50', ...
                        'tgrass_ha_20', 'tgrass_ha_30', 'tgrass_ha_40', 'tgrass_ha_50'};
        lcs_arable2thirds(:, cols_to_zero) = array2table(zeros(size(lcs_arable2thirds, 1), length(cols_to_zero)));

        % Set remaining farmland grass types to 2020s amount
        lcs_arable2thirds.rgraz_ha_30 = lcs_arable2thirds.rgraz_ha_20;
        lcs_arable2thirds.rgraz_ha_40 = lcs_arable2thirds.rgraz_ha_20;
        lcs_arable2thirds.rgraz_ha_50 = lcs_arable2thirds.rgraz_ha_20;

        lcs_arable2thirds.pgrass_ha_30 = lcs_arable2thirds.pgrass_ha_20;
        lcs_arable2thirds.pgrass_ha_40 = lcs_arable2thirds.pgrass_ha_20;
        lcs_arable2thirds.pgrass_ha_50 = lcs_arable2thirds.pgrass_ha_20;

        % Reset total farming grassland
        lcs_arable2thirds.grass_ha_20 = lcs_arable2thirds.rgraz_ha_20 + lcs_arable2thirds.pgrass_ha_20;
        lcs_arable2thirds.grass_ha_30 = lcs_arable2thirds.rgraz_ha_30 + lcs_arable2thirds.pgrass_ha_30;
        lcs_arable2thirds.grass_ha_40 = lcs_arable2thirds.rgraz_ha_40 + lcs_arable2thirds.pgrass_ha_40;
        lcs_arable2thirds.grass_ha_50 = lcs_arable2thirds.rgraz_ha_50 + lcs_arable2thirds.pgrass_ha_50;
        
        % check that land uses sum to 400 hectares and stop it not
        [lcm, top_level, crops] = fcn_landuse_check(lcs_arable2sng);
        
        if top_level ~= 1
            warning('The 5 lcm land uses for the ''arable2mixed_6633'' option do not sum to 400 ha!')
        end
        
        if any(top_level == 0)
            decade_list = {'20', '30', '40', '50'};
            warning_vars = {};
            ind = find(top_level == 0);
            for i = 1:length(ind)
                decade = decade_list(ind(i));
                warning_vars = [warning_vars, decade];
            end
            msg = strcat('arable and grassland hectares for the ''arable2mixed_6633'' option do not sum to farmland hectares for the following decades: \n', ...
                         repmat('-  %s\n', 1, length(warning_vars))); 
            warning_msg = sprintf(msg, warning_vars{:});
            warning(warning_msg)
        end
            
        if any(crops == 0)
            decade_list = {'20', '30', '40', '50'};
            warning_vars = {};
            ind = find(crops == 0);
            for i = 1:length(ind)
                decade = decade_list(ind(i));
                warning_vars = [warning_vars, decade];
            end
            msg = strcat('Crops and grassland for the ''arable2mixed_6633'' option do not sum to farmland hectares for the following decades: \n', ...
                         repmat('-  %s\n', 1, length(warning_vars))); 
            warning_msg = sprintf(msg, warning_vars{:});
            warning(warning_msg)
        end

        % Save to lcs_arable2mixed.mat file
        % -------------------------------
        savename = strcat(save_folder, '\lcs_arable2thirds.mat');
        save(savename, 'lcs_arable2thirds', '-mat', '-v6');
    end
    
%% (8) Scenario land uses: grass2mixed
    %  ===================================
    if exist('do_grass2thirds', 'var')
        % Land cover change
        % -----------------
        % Add pgrass and rgraz hectares to a mix of 50% wood and 50% sng
        % Subtract pgrass and rgraz hectares from farm hectares
        % Reduce pgrass and rgraz to zero
        lcs_grass2thirds = lcs_baseline;
        hectares = lcs_grass2thirds.pgrass_ha_20 + lcs_grass2thirds.rgraz_ha_20;
        lcs_grass2thirds.hectares = hectares;

        lcs_grass2thirds.wood_ha = lcs_grass2thirds.wood_ha + 0.33 .* hectares;
        lcs_grass2thirds.sngrass_ha = lcs_grass2thirds.sngrass_ha + 0.67 .* hectares;
        lcs_grass2thirds.farm_ha = lcs_grass2thirds.farm_ha - hectares;

        % Set appropriate land covers to zero
        cols_to_zero = {'pgrass_ha_20', 'pgrass_ha_30', 'pgrass_ha_40', 'pgrass_ha_50', ...
                        'rgraz_ha_20', 'rgraz_ha_30', 'rgraz_ha_40', 'rgraz_ha_50'};
        lcs_grass2thirds(:, cols_to_zero) = array2table(zeros(size(lcs_grass2thirds, 1), length(cols_to_zero)));

        % Set remaining farmland grass types to 2020s amount
        lcs_grass2thirds.arable_ha_30 = lcs_grass2thirds.arable_ha_20;
        lcs_grass2thirds.arable_ha_40 = lcs_grass2thirds.arable_ha_20;
        lcs_grass2thirds.arable_ha_50 = lcs_grass2thirds.arable_ha_20;

        lcs_grass2thirds.wheat_ha_30 = lcs_grass2thirds.wheat_ha_20;
        lcs_grass2thirds.wheat_ha_40 = lcs_grass2thirds.wheat_ha_20;
        lcs_grass2thirds.wheat_ha_50 = lcs_grass2thirds.wheat_ha_20;

        lcs_grass2thirds.osr_ha_30 = lcs_grass2thirds.osr_ha_20;
        lcs_grass2thirds.osr_ha_40 = lcs_grass2thirds.osr_ha_20;
        lcs_grass2thirds.osr_ha_50 = lcs_grass2thirds.osr_ha_20;

        lcs_grass2thirds.wbar_ha_30 = lcs_grass2thirds.wbar_ha_20;
        lcs_grass2thirds.wbar_ha_40 = lcs_grass2thirds.wbar_ha_20;
        lcs_grass2thirds.wbar_ha_50 = lcs_grass2thirds.wbar_ha_20;

        lcs_grass2thirds.sbar_ha_30 = lcs_grass2thirds.sbar_ha_20;
        lcs_grass2thirds.sbar_ha_40 = lcs_grass2thirds.sbar_ha_20;
        lcs_grass2thirds.sbar_ha_50 = lcs_grass2thirds.sbar_ha_20;

        lcs_grass2thirds.pot_ha_30 = lcs_grass2thirds.pot_ha_20;
        lcs_grass2thirds.pot_ha_40 = lcs_grass2thirds.pot_ha_20;
        lcs_grass2thirds.pot_ha_50 = lcs_grass2thirds.pot_ha_20;

        lcs_grass2thirds.sb_ha_30 = lcs_grass2thirds.sb_ha_20;
        lcs_grass2thirds.sb_ha_40 = lcs_grass2thirds.sb_ha_20;
        lcs_grass2thirds.sb_ha_50 = lcs_grass2thirds.sb_ha_20;

        lcs_grass2thirds.other_ha_30 = lcs_grass2thirds.other_ha_20;
        lcs_grass2thirds.other_ha_40 = lcs_grass2thirds.other_ha_20;
        lcs_grass2thirds.other_ha_50 = lcs_grass2thirds.other_ha_20;

        lcs_grass2thirds.tgrass_ha_30 = lcs_grass2thirds.tgrass_ha_20;
        lcs_grass2thirds.tgrass_ha_40 = lcs_grass2thirds.tgrass_ha_20;
        lcs_grass2thirds.tgrass_ha_50 = lcs_grass2thirds.tgrass_ha_20;

        % Reset total farming grassland
        lcs_grass2thirds.grass_ha_20 = lcs_grass2thirds.tgrass_ha_20;
        lcs_grass2thirds.grass_ha_30 = lcs_grass2thirds.tgrass_ha_30;
        lcs_grass2thirds.grass_ha_40 = lcs_grass2thirds.tgrass_ha_40;
        lcs_grass2thirds.grass_ha_50 = lcs_grass2thirds.tgrass_ha_50;
        
        % check that land uses sum to 400 hectares and stop it not
        [lcm, top_level, crops] = fcn_landuse_check(lcs_arable2sng);
        
        if top_level ~= 1
            warning('The 5 lcm land uses for the ''grass2mixed'' option do not sum to 400 ha!')
        end
        
        if any(top_level == 0)
            decade_list = {'20', '30', '40', '50'};
            warning_vars = {};
            ind = find(top_level == 0);
            for i = 1:length(ind)
                decade = decade_list(ind(i));
                warning_vars = [warning_vars, decade];
            end
            msg = strcat('arable and grassland hectares for the ''grass2mixed'' option do not sum to farmland hectares for the following decades: \n', ...
                         repmat('-  %s\n', 1, length(warning_vars))); 
            warning_msg = sprintf(msg, warning_vars{:});
            warning(warning_msg)
        end
            
        if any(crops == 0)
            decade_list = {'20', '30', '40', '50'};
            warning_vars = {};
            ind = find(crops == 0);
            for i = 1:length(ind)
                decade = decade_list(ind(i));
                warning_vars = [warning_vars, decade];
            end
            msg = strcat('Crops and grassland for the ''grass2mixed'' option do not sum to farmland hectares for the following decades: \n', ...
                         repmat('-  %s\n', 1, length(warning_vars))); 
            warning_msg = sprintf(msg, warning_vars{:});
            warning(warning_msg)
        end


        % Save to lcs_grass2thirds.mat file
        % -------------------------------
        savename = strcat(save_folder, '\lcs_grass2thirds.mat');
        save(savename, 'lcs_grass2thirds', '-mat', '-v6');
    end
end
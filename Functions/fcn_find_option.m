function option_table = fcn_find_option(options, scenario_land_cover, baseline_land_cover, baseline, scenario)
    
    %% (1) Compute difference between scnario and baseline landuse
    %  =========================================================== 
    
    % LCM aggregated land covers
    macro_lc = {'farm_ha', 'sng_ha', 'wood_ha', ...
        'water_ha', 'urban_ha'};
    
    baseline_land_cover = baseline_land_cover(:, macro_lc);
    scenario_land_cover = scenario_land_cover(:, macro_lc);
    landuse_chg = scenario_land_cover{:,:} - baseline_land_cover{:,:};
    landuse_chg = round(landuse_chg, 3);
    landuse_chg = array2table(landuse_chg);
    landuse_chg.Properties.VariableNames = macro_lc;
    
    % Arable and grassland
    arable_t1 = mean(scenario.es_agriculture.arable_ha(:, 1:10), 2);
    arable_t0 = mean(baseline.es_agriculture.arable_ha(:, 1:10), 2);
    landuse_chg.arable_ha =  arable_t1 - arable_t0;
    grass_t1 = mean(scenario.es_agriculture.grass_ha(:, 1:10), 2);
    grass_t0 = mean(baseline.es_agriculture.grass_ha(:, 1:10), 2);
    landuse_chg.grass_ha =  grass_t1 - grass_t0;
    
  
    %% (2) Initialise table containing logical values for each cell and option
    %  =======================================================================
    is_positive = @(x) x > 0;
    is_negative = @(x) x < 0;

    option_table = array2table(baseline.es_agriculture.new2kid);
    option_table.Properties.VariableNames = {'new2kid'};
    option_table = [option_table, array2table(zeros(height(option_table), length(options)))];
    option_table.Properties.VariableNames(2:end) = options;
    
    %% (3) Identify which option applies for each cell based on lu change
    %  ==================================================================  
    for i = 1:height(landuse_chg)
        row = landuse_chg(i, :);
        option_positive = varfun(is_positive, row);
        which_positive = row.Properties.VariableNames(find(table2array(option_positive)));        
        
        option_negative = varfun(is_negative, row);
        which_negative = row.Properties.VariableNames(find(table2array(option_negative)));
        
        % as farm is the combination of arable and grass, the inclusion of
        % the farm2xyz options is redundant
        if any(strcmp(which_negative, 'farm_ha'))
            which_negative(strcmp(which_negative, 'farm_ha')) = [];
        end
        
        option_list = {};
        counter = 1;
        for j = 1:length(which_negative)
            for k = 1:numel(which_positive)
                opt_from = which_negative{j};
                opt_from = split(opt_from, '_');
                opt_from = opt_from{1};
                opt_to = which_positive{k};
                opt_to = split(opt_to, '_');
                opt_to = opt_to{1};
                option_list{counter} = strcat(opt_from, '2', opt_to);
                counter = counter + 1;
            end
        end
        
        if(isempty(option_list))
            continue
        else
%             % as farm is the combination of arable and grass, the inclusion of
%             % the farm2xyz options is redundant
%             if any(contains(option_list, 'farm'))
%                 idx = contains(option_list, 'farm');
%                 option_list(idx) = [];                    
%             end
            option_table{i, option_list} = ones(1, length(option_list));
        end
    end
end
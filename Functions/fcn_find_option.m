function option_table = fcn_find_option(options, scenario_land_cover, baseline_land_cover, baseline, scenario)
    
    %% (1) Compute difference between scnario and baseline landuse
    %  ===========================================================
    landuse_chg = scenario_land_cover{:,:} - baseline_land_cover{:,:};
    landuse_chg = array2table(landuse_chg);
    landuse_chg.Properties.VariableNames = scenario_land_cover.Properties.VariableNames;
    
    top_level_vars = {'arable_ha', 'grass_ha'};
    if ~all(ismember(top_level_vars, landuse_chg.Properties.VariableNames))
        arable_t1 = mean(scenario.es_agriculture.arable_ha(:, 1:10), 2);
        arable_t0 = mean(baseline.es_agriculture.arable_ha(:, 1:10), 2);
        landuse_chg.arable_ha =  arable_t1 - arable_t0;
        grass_t1 = mean(scenario.es_agriculture.grass_ha(:, 1:10), 2);
        grass_t0 = mean(baseline.es_agriculture.grass_ha(:, 1:10), 2);
        landuse_chg.grass_ha =  grass_t1 - grass_t0;
    end
    
    % reduce to macro-land covers including top level agricultural land
    macro_lc = {'arable_ha', 'grass_ha', 'farm_ha', 'sng_ha', 'wood_ha', ...
        'water_ha', 'urban_ha'};
    landuse_chg = landuse_chg(:, macro_lc);
        
   
    %% (2) Initialise table containing logical values for each cell and option
    %  =======================================================================
    is_positive = @(x) x > 0;
    is_negative = @(x) x < 0;

    option_table = scenario_land_cover(:, 1);
    option_table = [option_table, array2table(zeros(height(option_table), length(options)))];
    option_table.Properties.VariableNames(2:end) = options;
    
    %% (3) Identify which option applies for each cell based on lu change
    %  ==================================================================  
    for i = 1:height(landuse_chg)
        row = landuse_chg(i, :);
        option_positive = varfun(is_positive, row);
        which_positive = split(row.Properties.VariableNames{find(table2array(option_positive))}, '_');
        option_to = char(which_positive(1));
        option_negative = varfun(is_negative, row);
        which_negative = row.Properties.VariableNames(find(table2array(option_negative)));
        option_list = {};
        for j = 1:length(which_negative)
            opt = which_negative{j};
            opt = split(opt, '_');
            opt = opt{1};
            option_list{j} = strcat(opt, '2', option_to);
        end
        if ismember('farm2wood', option_list)
            [~, idx] = ismember('farm2wood', option_list);
            option_list(idx) = [];                    
        end
        option_table{i, option_list} = ones(1, length(option_list));
    end
end
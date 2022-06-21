function quantity_rec = fcn_calc_quantity_recreation(start_year, end_year, baseline, scenario, opt_arguments)

    % Environmental quantities for recreation is the hectares of
    % semi-natural grassland (sng) or woodland provided with or without
    % access, multiplied by the length of the scheme
    options = opt_arguments.options;
    scheme_length = (end_year - start_year + 1);
    quantity_rec = array2table(zeros(height(options), width(options)));
    quantity_rec.Properties.VariableNames = options.Properties.VariableNames;
    quantity_rec.new2kid = options.new2kid;
    
    % land uses
    base_high_level_lcs = opt_arguments.baseline_land_cover(:, {'new2kid', 'farm_ha', ...
                                                                 'wood_ha', 'wood_mgmt_ha', ...
                                                                 'sng_ha', 'urban_ha', ...
                                                                 'water_ha'});                              
    baseline_lc = fcn_collect_output_simple(base_high_level_lcs, baseline.es_agriculture);
    
    scen_high_level_lcs = opt_arguments.scenario_land_cover(:, {'new2kid', 'farm_ha', ...
                                                                 'wood_ha', 'wood_mgmt_ha', ...
                                                                 'sng_ha', 'urban_ha', ...
                                                                 'water_ha'});                              
    scenario_lc = fcn_collect_output_simple(scen_high_level_lcs, scenario);
        
    
    colnames = quantity_rec.Properties.VariableNames;
    for i = 2:numel(colnames)
        lands = split(colnames{i}, '2');
        land = lands{1};
        switch land
            case {'arable', 'grass'}
                fieldname = strcat(land, '_ha_20');
                quantity_rec{:, i} = baseline_lc.(fieldname) - scenario_lc.(fieldname);
            case {'sng', 'wood'}
                if strcmp(land, 'sng')
                    land = 'sngrass';
                end
                fieldname = strcat(land, '_ha');
                quantity_rec{:, i} = baseline_lc.(fieldname) - scenario_lc.(fieldname);
        end
    end
    
    % filter by unique options
    quantity_rec{:, 2:end} = quantity_rec{:, 2:end} .* options{:, 2:end};
end
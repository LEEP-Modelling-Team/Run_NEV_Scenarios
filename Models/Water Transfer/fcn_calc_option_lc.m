function lcs_scenario_options = fcn_calc_option_lc(options, unique_options, baseline_land_cover, scenario_land_cover, baseline, scenario);
    %% fcn_calc_option_lc.m
    %  ====================
    %
    %  Authors: Mattia Mancini, Rebecca Collins
    %  Created: 06-Jun-2022
    %  Last modified: 06-Jun-2022
    %  ----------------------------------------
    %
    %  DESCRIPTION
    %  Function that identifies for each cell the hectares changing land
    %  use for each possible land use change option. This is required to
    %  identify, from teh scenario land use passed in run_NEV.m which land 
    %  use change option happens in each cell and how many hectares are
    %  involved. This is necessary to identify the correct representative
    %  cell and the correct areas to compute changes in water quality and
    %  flooding values resulting from the change in land use between the
    %  scenario and the baseline of interest. We need to do this because we
    %  can have different options applying to different cells, as well as
    %  different areas (not necessarily the whole land type in each cell as
    %  done in previous work.
    %  ====================================================================
    
    %% (1) Retrieve land uses.
    %  =======================
    
    % 1.1. LCM aggregated land uses
    % -----------------------------
    baseline_high_level = baseline_land_cover(:, {'new2kid', 'farm_ha', ...
                             'wood_ha', 'wood_mgmt_ha', ...
                             'sng_ha', 'urban_ha', ...
                             'water_ha'});
    baseline_ag_output = fcn_collect_output_simple(baseline_high_level, baseline.es_agriculture);
    
    scenario_high_level = scenario_land_cover(:, {'new2kid', 'farm_ha', ...
                             'wood_ha', 'wood_mgmt_ha', ...
                             'sng_ha', 'urban_ha', ...
                             'water_ha'});
    scenario_ag_output = fcn_collect_output_simple(scenario_high_level, scenario.es_agriculture);

    crop_list = {'wheat', 'osr', 'wbar', 'sbar', 'pot', 'sb', 'other'};
    grass_list = {'pgrass', 'rgraz', 'tgrass'};
    
    %% (2) Calculate land use change tables by available option
    %  ========================================================
    lcs_scenario_options = [];
    for i = 1:numel(options)
        % 2.1. Identify relevant option
        % -----------------------------
        field_name = options{i};
        if any(strcmp(unique_options, field_name))
            land = baseline_ag_output;
            opt_land = split(field_name, '2');
            from = strcat(opt_land{1});
            if strcmp(from, 'sng')
                from = 'sngrass';
            end
            to = strcat(opt_land{2});
            if strcmp(to, 'sng')
                to = 'sngrass';
            end
            col_from = strcat(from, '_ha');
            col_to = strcat(to, '_ha');
            
            % 2.1. Compute hecare change for relevant option
            % ----------------------------------------------
            switch from
                case {'arable', 'grass'} 
                    from_baseline = mean(baseline.es_agriculture.(col_from)(:, 1:10), 2);
                    from_scenario = mean(scenario.es_agriculture.(col_from)(:, 1:10), 2);
                    hectares_chg = abs(from_scenario - from_baseline);
                otherwise
                    hectares_chg = abs(scenario_ag_output.(col_from) - baseline_ag_output.(col_from));
            end
            
            % remove land from 'from'
            switch from
                case {'arable'} 
                    arable_idx_20 = strcat(from, '_ha_20');
                    arable_idx_future =  {strcat(from, '_ha_30'), ...
                                          strcat(from, '_ha_40'), ...
                                          strcat(from, '_ha_50')};
                    crop_idx_20 = strcat(crop_list, '_ha_20');
                    crop_idx_future = [strcat(crop_list, '_ha_30') ...
                                         strcat(crop_list, '_ha_40') ...
                                         strcat(crop_list, '_ha_50')];
                                         
                    % arable crop proportions
                    proportions = land{:, crop_idx_20} ./ land{:, arable_idx_20};
                    
                    % arable land
                    land{:, arable_idx_20} = land{:, arable_idx_20} - hectares_chg;
                    land{:, arable_idx_future} = repmat(land{:, arable_idx_20}, 1, length(arable_idx_future));
                    
                    % crops constituting arable: first find proportions,
                    % then adjust hectares
                    land{:, crop_idx_20} = proportions .* land{:, arable_idx_20};
                    land{:, crop_idx_future} = repmat(land{:, crop_idx_20}, 1, length(arable_idx_future));
                    
                    % add column with hectare change
                    land.hectares = hectares_chg;
                    
                    % remove arable change from farmland
                    land.farm_ha = land.farm_ha - hectares_chg;
                case {'grass'} 
                    arable_idx_20 = strcat(from, '_ha_20');
                    arable_idx_future =  {strcat(from, '_ha_30'), ...
                                          strcat(from, '_ha_40'), ...
                                          strcat(from, '_ha_50')};
                    crop_idx_20 = strcat(grass_list, '_ha_20');
                    crop_idx_future = [strcat(grass_list, '_ha_30') ...
                                         strcat(grass_list, '_ha_40') ...
                                         strcat(grass_list, '_ha_50')];
                                         
                    % arable crop proportions
                    proportions = land{:, crop_idx_20} ./ land{:, arable_idx_20};
                    
                    % arable land
                    land{:, arable_idx_20} = land{:, arable_idx_20} - hectares_chg;
                    land{:, arable_idx_future} = repmat(land{:, arable_idx_20}, 1, length(arable_idx_future));
                    
                    % crops constituting arable: first find proportions,
                    % then adjust hectares
                    land{:, crop_idx_20} = proportions .* land{:, arable_idx_20};
                    land{:, crop_idx_future} = repmat(land{:, crop_idx_20}, 1, length(arable_idx_future));
                    
                    % add column with hectare change
                    land.hectares = hectares_chg;
                    
                    % remove grassland from farmland
                    land.farm_ha = land.farm_ha - hectares_chg;
                case {'wood', 'sngrass'}
                    land{:, col_from} = land{:, col_from} - hectares_chg;
            end
            
            % add land to 'to'
            switch to
                case {'sngrass', 'wood', 'urban'}
                    land{:, col_to} = land{:, col_to} + hectares_chg;
                case 'mixed'
                    land{:, 'wood_ha'} = land{:, 'wood_ha'} + 0.5 .* hectares_chg;
                    land{:, 'sngrass_ha'} = land{:, 'sngrass_ha'} + 0.5 .* hectares_chg;
            end
            lcs_scenario_options.(field_name) = land;
        end
    end   
end


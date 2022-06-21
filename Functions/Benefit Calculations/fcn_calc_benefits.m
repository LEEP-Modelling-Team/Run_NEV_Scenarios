function [benefits_npv_table, costs_npv_table] = fcn_calc_benefits(MP, model_flags, start_year, discount_constants, carbon_price, baseline, scenario, out, opt_arguments)

    %% (0) Setup
    %  =========
    
    % Constants
    % ---------
    % Calculate number of extra years outside 2020-2059 that scheme will
    % run for, based on start_year and scheme_length
    scheme_length = MP.landuse_change_timeframe;
    num_extra_years = max(0, scheme_length - 40 + start_year - 1);
    
    % If there are extra years, calculate discount and annuity constants
    % and add to discount_constants structure
    if (num_extra_years > 0)
        % Discount vector
        discount_constants.delta_extra = 1 ./ ((1 + MP.discount_rate) .^ (1:num_extra_years))';
        % Annuity constant
        discount_constants.gamma_extra = MP.discount_rate / (1 - (1 + MP.discount_rate) ^ (-num_extra_years));
        % Discount decade
        discount_decade_extra = sum(1 ./ ((1 + MP.discount_rate) .^ (((MP.num_years + 1):(MP.num_years + num_extra_years)))));
        discount_constants.discount_decade = [discount_constants.discount_decade; discount_decade_extra];
    end
    
    % Calculate discount vector over length of scheme
    discount_constants.delta_scheme_length = 1 ./ ((1 + MP.discount_rate) .^ (1:scheme_length))';
   
    
    %% (1) Calculate benefits for each ecosystem service as annuities
    %  ==============================================================
    % (a) Agriculture
    % ---------------
    [~, opp_cost_farm_ann] = fcn_calc_benefit_agriculture(start_year, scheme_length, discount_constants, baseline.es_agriculture, scenario.es_agriculture);
    
    % (b) Forestry
    % ------------
    if model_flags.run_forestry
        [benefit_forestry_ann, cost_forestry_ann] = fcn_calc_benefit_forestry(baseline, scenario.es_forestry);
    else
        [benefit_forestry_ann, cost_forestry_ann] = deal(NaN(height(out.new2kid), 1));
    end
    
    % (c) Greenhouse Gases
    % --------------------
    if model_flags.run_ghg
        if model_flags.run_forestry
            [benefit_ghg_farm_ann, benefit_ghg_forestry_ann, benefit_ghg_soil_forestry_ann] = fcn_calc_benefit_ghg(start_year, scheme_length, discount_constants, carbon_price, baseline, scenario, out);
        else
            [benefit_ghg_farm_ann, ~, ~] = fcn_calc_benefit_ghg(start_year, scheme_length, discount_constants, carbon_price, baseline, scenario, out);
            [benefit_ghg_forestry_ann, benefit_ghg_soil_forestry_ann] = deal(NaN(height(out.new2kid), 1));
        end
    else
        benefit_ghg_farm_ann = NaN(height(out.new2kid), length(discount_constants.discount_decade));
        [benefit_ghg_forestry_ann, benefit_ghg_soil_forestry_ann] = deal(NaN(height(out.new2kid), 1));
    end
    
    % (d) Recreation
    % --------------
    if model_flags.run_recreation
        benefit_rec_ann = fcn_calc_benefit_recreation_substitution(start_year, scheme_length, discount_constants, out, opt_arguments.sng_rec_for_wood);
    else
        benefit_rec_ann = NaN(height(out.new2kid), length(discount_constants.discount_decade));
    end
        
    
    % (e) Hydrology
    % -------------
    if model_flags.run_hydrology
        % flooding
        benefit_flooding_ann = opt_arguments.flooding_transfer_table.flood_value;
        % Water quality
        [benefit_totn_ann, benefit_totp_ann] = fcn_calc_benefit_water_quality(start_year, scheme_length, discount_constants, opt_arguments.water_quality_transfer_table);
        % Water quality non-use
        benefit_water_non_use_ann = fcn_calc_benefit_water_non_use(start_year, scheme_length, discount_constants, opt_arguments.water_non_use_transfer_table);
    else
        benefit_flooding_ann = NaN(height(out.new2kid), 1);
        [benefit_totn_ann, benefit_totp_ann, benefit_water_non_use_ann] = deal(NaN(height(out.new2kid), length(discount_constants.discount_decade)));
    end
    
    %% (2) Combine benefits across ecosystem services using NPVs
    %  =========================================================
    % (a) Turn decadal benefit annuities into NPVs using discount decade
    % ------------------------------------------------------------------
    % benefit_farm_npv = benefit_farm_ann * discount_constants.discount_decade;
    benefit_ghg_farm_npv = benefit_ghg_farm_ann * discount_constants.discount_decade;
    benefit_rec_npv = benefit_rec_ann * discount_constants.discount_decade;
    benefit_totn_npv = benefit_totn_ann * discount_constants.discount_decade;
    benefit_totp_npv = benefit_totp_ann * discount_constants.discount_decade;
    benefit_water_non_use_npv = benefit_water_non_use_ann * discount_constants.discount_decade;
    
    % (b) Turn other benefit annuities into NPVs using sum of discount
    % vector over scheme length
    % ----------------------------------------------------------------
    discount_scheme_sum = sum(discount_constants.delta_scheme_length);
    benefit_forestry_npv = benefit_forestry_ann * discount_scheme_sum;
    benefit_ghg_forestry_npv = benefit_ghg_forestry_ann * discount_scheme_sum;
    benefit_ghg_soil_forestry_npv = benefit_ghg_soil_forestry_ann * discount_scheme_sum;
    benefit_flooding_npv = benefit_flooding_ann * discount_scheme_sum;
    
    % (c) Sum to get total benefit NPV
    % --------------------------------
    % Need nansum due to nan's in recreation benefits
    % NB. we DO NOT include forestry benefits here! 
    benefits_npv = nansum([benefit_ghg_farm_npv, ...
                           benefit_rec_npv, ...
                           benefit_ghg_forestry_npv, ...
                           benefit_ghg_soil_forestry_npv, ...
                           benefit_flooding_npv, ...
                           benefit_totn_npv, ...
                           benefit_totp_npv, ...
                           benefit_water_non_use_npv], 2);
    
    %% (3) Calculate costs as NPV
    %  ==========================
    % Farm opportunity costs
    % ----------------------
    opp_cost_farm_npv = opp_cost_farm_ann * discount_constants.discount_decade;
    
    % Forestry costs
    % --------------
    % Convert per hectare cost annuity into npv
    % Add on fixed costs (only for increase hectares of woodland - taken care of in fcn_forestry_elms)
    % Subtract timber benefit npv
    if model_flags.run_forestry
        cost_forestry_npv = cost_forestry_ann * discount_scheme_sum + scenario.es_forestry.Timber.FixedCost.Mix6040 - benefit_forestry_npv;
        if any(cost_forestry_npv < 0)
            error('Forestry costs are negative!');
        end
    else
        cost_forestry_npv = NaN(height(out.new2kid), 1);
    end
    
    %% (4) Combine results to tables for output return
    %  ===============================================
    % (a) Benefits
    % ------------
    var_names = {'total', ...
                 'ghg_farm', ...
                 'forestry', ...
                 'ghg_forestry', ...
                 'ghg_soil_forestry', ...
                 'rec', ...
                 'flooding', ...
                 'totn', ...
                 'totp', ...
                 'water_non_use'};
    combined_benefits = [benefits_npv, ...
                         benefit_ghg_farm_npv, ...
                         benefit_forestry_npv, ...
                         benefit_ghg_forestry_npv, ...
                         benefit_ghg_soil_forestry_npv, ...
                         benefit_rec_npv, ...
                         benefit_flooding_npv, ...
                         benefit_totn_npv, ...
                         benefit_totp_npv, ...
                         benefit_water_non_use_npv];
    benefits_npv_table = array2table(combined_benefits, ...
                                     'VariableNames', ...
                                     var_names);
                                 
    % Costs
    % -----
    var_names = {'farm', ...
                 'forestry'};
    combined_costs = [opp_cost_farm_npv, ...
                      cost_forestry_npv];
    costs_npv_table = array2table(combined_costs, ...
                                  'VariableNames', ...
                                  var_names);

end
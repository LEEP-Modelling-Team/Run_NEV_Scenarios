function quantities_table = fcn_calc_quantities(model_flags, start_year, scheme_length, baseline, es_agriculture, out, options, opt_arguments)

    %% (0) Constants
    %  =============
    % Calculate end year of scheme, and number of extra years outside of
    % 2020-2059 (40 year period) it will run
    end_year = start_year + scheme_length - 1;
    num_extra_years = max(0, end_year - 40);
    
    %% (1) Calculate quantity change from baseline for each ES
    %  =======================================================
    % (a) Greenhouse Gases
    % --------------------
    if model_flags.run_ghg
        quantity_ghg = fcn_calc_quantity_ghg(start_year, end_year, num_extra_years, baseline, es_agriculture, out);
    else
        quantity_ghg = NaN(length(out.new2kid), 1);
    end
    
    % (b) Recreation
    % --------------
    if model_flags.run_recreation
        quantity_rec = fcn_calc_quantity_recreation(start_year, end_year, baseline, es_agriculture, opt_arguments);
    else
        quantity_rec = array2table([out.new2kid, NaN(length(out.new2kid), length(options))]);
        quantity_rec.Properties.VariableNames = ['new2kid', options];
    end
    
    % (c) Hydrology
    % -------------
    % !!! This is using old flow emulator !!!
    if model_flags.run_hydrology
        % flooding
        quantity_flooding = fcn_calc_quantity_flood(start_year, end_year, num_extra_years, opt_arguments.flooding_transfer_table);
        % water quality
        [quantity_totn, quantity_totp] = fcn_calc_quantity_water_quality(start_year, end_year, num_extra_years, opt_arguments.water_quality_transfer_table);
    else
        [quantity_flooding, quantity_totn, quantity_totp] = deal(NaN(length(out.new2kid), 1));
    end
    
%     % (f) Pollination
%     % ---------------
%     quantity_pollination = fcn_calc_quantity_pollination(start_year, end_year, num_extra_years, baseline, es_biodiversity_ucl);
    
    % (g) Biodiversity
    % ----------------
    if model_flags.run_biodiversity
        quantity_bio = fcn_calc_quantity_bio(start_year, end_year, num_extra_years, baseline, opt_arguments.es_biodiversity_jncc);
    else
        quantity_bio = NaN(length(out.new2kid), 1);
    end
        
    %% (2) Combine quantities into a table
    %  ====================================
    var_names = {'ghg', ...
                 'rec_ha_arable2sng', ...
                 'rec_ha_arable2wood', ...
                 'rec_ha_arable2urban', ...
                 'rec_ha_arable2mixed', ...
                 'rec_ha_grass2sng', ...
                 'rec_ha_grass2wood', ...
                 'rec_ha_grass2urban', ...
                 'rec_ha_grass2mixed', ...
                 'rec_ha_sng2urban', ...
                 'rec_ha_wood2urban', ...
                 'flooding', ...
                 'totn', ...
                 'totp', ...
                 'bio'};
    combined_quantities = [quantity_ghg, ...
                           quantity_rec.arable2sng, ...
                           quantity_rec.arable2wood, ...
                           quantity_rec.arable2urban, ...
                           quantity_rec.arable2mixed, ...
                           quantity_rec.grass2sng, ...
                           quantity_rec.grass2wood, ...
                           quantity_rec.grass2urban, ...
                           quantity_rec.grass2mixed, ...
                           quantity_rec.sng2urban, ...
                           quantity_rec.wood2urban, ...
                           quantity_flooding, ...
                           quantity_totn, ...
                           quantity_totp, ...
                           quantity_bio];
    quantities_table = array2table(combined_quantities, ...
                                   'VariableNames', ...
                                   var_names);

end
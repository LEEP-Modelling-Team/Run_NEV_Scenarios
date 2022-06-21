function benefit_rec_ann = fcn_calc_benefit_recreation_substitution(start_year, scheme_length, discount_constants, out, rec_val_grass)

    % Calculate the year in the 4 decades which relates to1 the end of the
    % current scheme, if the scheme ends after the fourth decade set to 40
    % and add _ann_extra
    end_year = min(40, start_year + (scheme_length - 1));
 
    % Time series of recreation value for 40 years
    rec_val_scenario = [repmat(out.rec_val_20, 1, 10) ...
        repmat(out.rec_val_30, 1, 10) ...
        repmat(out.rec_val_40, 1, 10) ...
        repmat(out.rec_val_50, 1, 10)];
    rec_val_weights = 1 - exp(-0.05 * (0:39));
    rec_val_weights(40) = 1;
    
    rec_val_grass = [repmat(rec_val_grass.rec_val_20, 1, 10) ...
        repmat(rec_val_grass.rec_val_30, 1, 10) ...
        repmat(rec_val_grass.rec_val_40, 1, 10) ...
        repmat(rec_val_grass.rec_val_50, 1, 10)];
    
    % replace weighted wood recreation with weighted sng rec values. This
    % is done because woodland takes time to get estrablished and deliver
    % the full amount of ecosystem services
    rec_val_scenario = rec_val_scenario .* rec_val_weights + rec_val_grass .* (1 - rec_val_weights);
    
    % Decades adjusted by weights
    rec_val_diff_20 = rec_val_scenario(:, 1:10);
    rec_val_diff_30 = rec_val_scenario(:, 11:20);
    rec_val_diff_40 = rec_val_scenario(:, 21:30);
    rec_val_diff_50 = rec_val_scenario(:, 31:40);
    
    benefit_rec_ann_20 = (rec_val_diff_20 * discount_constants.delta_10) * discount_constants.gamma_10;
    benefit_rec_ann_30 = (rec_val_diff_30 * discount_constants.delta_10) * discount_constants.gamma_10;
    benefit_rec_ann_40 = (rec_val_diff_40 * discount_constants.delta_10) * discount_constants.gamma_10;
    benefit_rec_ann_50 = (rec_val_diff_50 * discount_constants.delta_10) * discount_constants.gamma_10;
    
    % Combine into a matrix
    if (end_year < 40)
        benefit_rec_ann = [benefit_rec_ann_20, benefit_rec_ann_30, benefit_rec_ann_40, benefit_rec_ann_50];
    else
        benefit_rec_ann_extra = rec_val_scenario(:,40);
        benefit_rec_ann = [benefit_rec_ann_20, benefit_rec_ann_30, benefit_rec_ann_40, benefit_rec_ann_50, benefit_rec_ann_extra];
    end

end
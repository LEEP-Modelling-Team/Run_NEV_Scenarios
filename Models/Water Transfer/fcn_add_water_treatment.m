function fcn_add_water_treatment(options, parameters, hash, conn)
    %% fcn_add_water_treatment.m
    %  ========================
    % Author: Nathan Owen
    % Last modified: 28/08/2020
    % For land use changes across GB, calculate water treatment savings and
    % add it to data calculated in script3_run_rep_cells.m

    %% (1) Set up
    %  ==========
    % (a) Define land use changes/options
    % -----------------------------------
    num_options = length(options);

    % (a) Subcatchment abstraction data
    % ---------------------------------
    sqlquery = ['SELECT ', ...
                    'subctch_id, ', ...
                    'abstraction_m3_yr ', ...
                'FROM water.wtw_catchment_wfd ', ...
                'ORDER BY subctch_id'];
    setdbprefs('DataReturnFormat', 'table');
    dataReturn  = fetch(exec(conn, sqlquery));
    subctch_abstraction = dataReturn.Data;

    % Remove '0' and 'null' cases
    subctch_abstraction = subctch_abstraction(~strcmp(subctch_abstraction.subctch_id, '0'), :);
    subctch_abstraction = subctch_abstraction(~strcmp(subctch_abstraction.subctch_id, 'null'), :);

    %% (2) Loop over options
    %  =====================
    for i = 1:num_options
        % Get this option name
        option_i = options{i};

        % (a) Load representative cell results for this option
        % ----------------------------------------------------
        % Store in water_option_i
        data_path = strcat(parameters.water_transfer_data_folder, ...
                           'Representative Cells\', ...
                           hash, '\water_', option_i, '.mat');
        load(data_path)
        water_option_i = eval(strcat('water_', option_i));
        eval(strcat('clear water_', option_i)); 

        % (b) Check if non use value has already been calculated
        % ------------------------------------------------------
    %     water_treatment_added = any(strcmp(water_option_i.Properties.VariableNames, 'wt_totn_20'));
        water_treatment_added = false; % Or, force code to add water treatment savings (comment out)

        % If it hasn't, calculate water treatment savings, add into 
        % water_option_i and save
        if ~water_treatment_added
            % (c) Calculate water treatment savings
            % -------------------------------------
            % Preallocate: water treatment (wt) savings as a result of changes
            % in total nitrates (totn) and phosphates (totp)
            num_rep_cell = size(water_option_i, 1);
            wt_totn_20 = zeros(num_rep_cell, 1);
            wt_totn_30 = zeros(num_rep_cell, 1);
            wt_totn_40 = zeros(num_rep_cell, 1);
            wt_totn_50 = zeros(num_rep_cell, 1);
            wt_totp_20 = zeros(num_rep_cell, 1);
            wt_totp_30 = zeros(num_rep_cell, 1);
            wt_totp_40 = zeros(num_rep_cell, 1);
            wt_totp_50 = zeros(num_rep_cell, 1);

            for i = 1:num_rep_cell
                disp(i)
                % Extract downstream subctch_id, totn and totp for this rep cell
                subctch_id_i = water_option_i.downstream_subctch_id{i}';
                chgtotn_20_i = water_option_i.chgtotn_20{i}';
                chgtotn_30_i = water_option_i.chgtotn_30{i}';
                chgtotn_40_i = water_option_i.chgtotn_40{i}';
                chgtotn_50_i = water_option_i.chgtotn_50{i}';
                chgtotp_20_i = water_option_i.chgtotp_20{i}';
                chgtotp_30_i = water_option_i.chgtotp_30{i}';
                chgtotp_40_i = water_option_i.chgtotp_40{i}';
                chgtotp_50_i = water_option_i.chgtotp_50{i}';

                % See if downstream subctch_id contains water abstraction
                [ind_abstraction, idx_abstraction] = ismember(subctch_id_i, subctch_abstraction.subctch_id);
                idx_abstraction = idx_abstraction(ind_abstraction);

                % Calculate water treatment savings and save to vector
                if ~isempty(idx_abstraction)
                    % If there is abstraction, calculate savings
                    % Need - sign as reduction in N/P is a benefit
                    subctch_abstraction_i = subctch_abstraction.abstraction_m3_yr(idx_abstraction);
                    wt_totn_20(i) = -sum(0.0006 * chgtotn_20_i(ind_abstraction) .* subctch_abstraction_i);
                    wt_totn_30(i) = -sum(0.0006 * chgtotn_30_i(ind_abstraction) .* subctch_abstraction_i);
                    wt_totn_40(i) = -sum(0.0006 * chgtotn_40_i(ind_abstraction) .* subctch_abstraction_i);
                    wt_totn_50(i) = -sum(0.0006 * chgtotn_50_i(ind_abstraction) .* subctch_abstraction_i);
                    wt_totp_20(i) = -sum(0.0006 * chgtotp_20_i(ind_abstraction) .* subctch_abstraction_i);
                    wt_totp_30(i) = -sum(0.0006 * chgtotp_30_i(ind_abstraction) .* subctch_abstraction_i);
                    wt_totp_40(i) = -sum(0.0006 * chgtotp_40_i(ind_abstraction) .* subctch_abstraction_i);
                    wt_totp_50(i) = -sum(0.0006 * chgtotp_50_i(ind_abstraction) .* subctch_abstraction_i);
                else
                    % If there is no abstraction, no action needed, savings
                    % remain at zero
                end
            end

            % Save vectors as columns in water_option_i
            water_option_i.wt_totn_20 = wt_totn_20;
            water_option_i.wt_totn_30 = wt_totn_30;
            water_option_i.wt_totn_40 = wt_totn_40;
            water_option_i.wt_totn_50 = wt_totn_50;
            water_option_i.wt_totp_20 = wt_totp_20;
            water_option_i.wt_totp_30 = wt_totp_30;
            water_option_i.wt_totp_40 = wt_totp_40;
            water_option_i.wt_totp_50 = wt_totp_50;

            % (d) Save to water_cell.mat file depending on option
            % ---------------------------------------------------
            save_folder = strcat(parameters.water_transfer_data_folder, ...
                             'Representative Cells\', ...
                             hash);
        
            eval(strcat('water_', option_i, ' = water_option_i;'));
            str_eval = strcat('save(strcat(save_folder, ''/water_', option_i, '''), ''water_', option_i, ''');');
            eval(str_eval);
            clear water_option_i
        else
            disp('Water treatment value already added for this land cover change, skipping...')
        end

    end
end
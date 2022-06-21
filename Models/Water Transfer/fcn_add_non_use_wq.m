function fcn_add_non_use_wq(options, parameters, hash)

    %% script4_add_non_use_water_quality.m
    %  ===================================
    % Author: Nathan Owen
    % Last modified: 06/08/2020
    % For land use changes across GB, calculate non use water quality value and
    % add it to data calculated in script3_run_rep_cells.m

    %% (1) Set up
    %  ==========
    % (a) Define land use changes/options
    % -----------------------------------
    num_options = length(options);


    % (b) Add path to NEV model code
    % ------------------------------
    non_use_wq_transfer_data_folder = parameters.non_use_wq_transfer_data_folder;

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
        non_use_added = any(strcmp(water_option_i.Properties.VariableNames, 'non_use_value_20'));
    %     non_use_added = false; % Or, force code to add non use water quality (comment out)

        % If it hasn't, calculate non use value, add into water_option_i and
        % save
        if ~non_use_added
            % (c) Calculate non use water quality value
            % -----------------------------------------
            % Preallocate
            num_rep_cell = size(water_option_i, 1);
            non_use_value_20 = zeros(num_rep_cell, 1);
            non_use_value_30 = zeros(num_rep_cell, 1);
            non_use_value_40 = zeros(num_rep_cell, 1);
            non_use_value_50 = zeros(num_rep_cell, 1);

            for i = 1:num_rep_cell
                disp(i)
                % Extract downstream subctch_id and minp for this rep cell
                subctch_id_i = water_option_i.downstream_subctch_id{i}';
                chgpmin_20_i = water_option_i.chgpmin_20{i}';
                chgpmin_30_i = water_option_i.chgpmin_30{i}';
                chgpmin_40_i = water_option_i.chgpmin_40{i}';
                chgpmin_50_i = water_option_i.chgpmin_50{i}';

                % Convert to table for input to NEV non use water quality model
                es_water_transfer_i = table(subctch_id_i, ...
                                            chgpmin_20_i, ...
                                            chgpmin_30_i, ...
                                            chgpmin_40_i, ...
                                            chgpmin_50_i);
                es_water_transfer_i.Properties.VariableNames = {'subctch_id', ...
                                                                'chgpmin_20', ...
                                                                'chgpmin_30', ...
                                                                'chgpmin_40', ...
                                                                'chgpmin_50'};

                % Run NEV non use water quality model
                es_non_use_wq_transfer_i = fcn_run_non_use_wq_transfer(non_use_wq_transfer_data_folder, ...
                                                                       es_water_transfer_i);

                % Save output to vector
                non_use_value_20(i) = es_non_use_wq_transfer_i.value_ann_20;
                non_use_value_30(i) = es_non_use_wq_transfer_i.value_ann_30;
                non_use_value_40(i) = es_non_use_wq_transfer_i.value_ann_40;
                non_use_value_50(i) = es_non_use_wq_transfer_i.value_ann_50;
            end

            % Save vectors as columns in water_option_i
            water_option_i.non_use_value_20 = non_use_value_20;
            water_option_i.non_use_value_30 = non_use_value_30;
            water_option_i.non_use_value_40 = non_use_value_40;
            water_option_i.non_use_value_50 = non_use_value_50;

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
            disp('Non use value already added for this land cover change, skipping...')
        end

    end
end
function es_non_use_wq_transfer = fcn_run_non_use_wq_transfer(non_use_wq_transfer_data_folder, ...
                                                              es_water_transfer)
    % fcn_run_non_use_wq
    % ==================
    % Authors: Nathan Owen, Brett Day, Amy Binner
    % Last modified: 03/08/2019
    % Inputs:
    % - non_use_wq_transfer_data_folder: path to the .mat file containing 
    %   the data for the model. The .mat file is generated in
    %   ImportNonUseWQTransfer.m and for me is saved in the path 
    %   C:\Users\neo204\OneDrive - University of Exeter\NEV\Model
    %   Data\NonUseWQTransfer\
    % - es_water_transfer: output from the NEV water transfer model. This
    %   is a table/structure containing water flow and quality output for a
    %   series of subcatchments with unique IDs (subctch_id). The output
    %   used here is the change in mineral phosphorus in the decades 2020s,
    %   2030s, 2040s and 2050s (chgpmin_20, chgpmin_30, chgpmin_40,
    %   chgpmin_50).
    % Outputs:
    % - es_non_use_wq_transfer: a table/structure containing the non use
    %   water quality value in the decades 2020s, 2030s, 2040s and 2050s.
    %   This value is in annualised form and is obtained by applying the
    %   change in mineral phosphorus to 'river cells', seeing whether WFD
    %   ecological class changes in those cells, and estimating the value
    %   that change would deliver to people in surrounding LSOAs. 
    
    %% (1) Set up
    %  ==========
    % (a) Constants
    % -------------
    num_days = 365;
    decade_str = {'_20', '_30', '_40', '_50'};
    num_decades = length(decade_str);
    
    % (b) Data files
    % --------------
    NEVO_NonUseWQ_Transfer_data_mat = strcat(non_use_wq_transfer_data_folder, ...
                                             'NEVO_NonUseWQ_Transfer_data.mat');
    load(NEVO_NonUseWQ_Transfer_data_mat, 'NonUseWQTransfer');
    
    %% (2) Reduce to inputted subcatchments
    %  ====================================
    % Given NEV subcatchments in es_water_transfer, extract affected river cells
    [ind_input_subctch, idx_input_subctch] = ismember(NonUseWQTransfer.subctch_id, ...
                                                      es_water_transfer.subctch_id);
    idx_input_subctch = idx_input_subctch(ind_input_subctch);
    
    % Extract data from NonUseWQTransfer structure for affected river cells
    NonUseWQTransfer.subctch_id = NonUseWQTransfer.subctch_id(ind_input_subctch, :);
    NonUseWQTransfer.cell_data = NonUseWQTransfer.cell_data(ind_input_subctch, :);
    
    % Given affected river cells, find affected LSOAs
    % Are river cells in lsoa's nearest 500 list (closest_idx)?
    % (we use index_2km here / idx_river_cell rather than new2kid)
    idx_river_cell = find(ind_input_subctch);
    [lsoa_ind_mat, lsoa_idx_mat] = ismember(NonUseWQTransfer.closest_idx, idx_river_cell);
    lsoa_ind = any(lsoa_ind_mat); % logical of lsoas affected
    
    % Reduce data in NonUseWQ structure to affected LSOAs
    NonUseWQTransfer.lsoa_data = NonUseWQTransfer.lsoa_data(lsoa_ind, :);
    NonUseWQTransfer.cell_dist_500 = NonUseWQTransfer.cell_dist_500(lsoa_ind, :);
    NonUseWQTransfer.closest_idx = NonUseWQTransfer.closest_idx(:, lsoa_ind);
    lsoa_ind_mat = lsoa_ind_mat(:, lsoa_ind); % for extracting from cell_dist_500 later
    lsoa_idx_mat = lsoa_idx_mat(:, lsoa_ind); % for extracting from cell_dist_500 later
    
    % Number of affected river cells and LSOAs
    num_river_cell = size(NonUseWQTransfer.cell_data, 1);
    num_lsoa = size(NonUseWQTransfer.lsoa_data, 1);
    
    % If there are no river cells in the inputted subcatchments, set non
    % use value to zero and return from function straight away
    if num_river_cell == 0
        es_non_use_wq_transfer.value_ann_20 = 0;
        es_non_use_wq_transfer.value_ann_30 = 0;
        es_non_use_wq_transfer.value_ann_40 = 0;
        es_non_use_wq_transfer.value_ann_50 = 0;
        return
    end
    
    % For reduced list of affected lsoas and river cells, get list of
    % closest river cells to each lsoa (in order nearest to furthest)
    lsoa_river_cells_order = cell(num_lsoa, 1);
    for i = 1:num_lsoa
        lsoa_river_cells_order{i} = lsoa_idx_mat(lsoa_ind_mat(:, i), i);
    end
    
    %% (3) Calculate probability of switching WFD phosphate class
    %  ==========================================================
    % Extract WFD phosphate boundaries
    pho_b = NonUseWQTransfer.cell_data{:, {'pho_high', ...
                                           'pho_good', ...
                                           'pho_moderate', ...
                                           'pho_poor'}};
    
    % Loop over decades
    for i = 1:num_decades
        % Add change in mineral phosphorus to current lower/upper phosphate boundary
        pho_lower_new = NonUseWQTransfer.cell_data.pho_lower + ...
                        es_water_transfer.(['chgpmin', decade_str{i}])(idx_input_subctch);
        pho_upper_new = NonUseWQTransfer.cell_data.pho_upper + ...
                        es_water_transfer.(['chgpmin', decade_str{i}])(idx_input_subctch);

        % New lower/upper boundaries cannot go below zero
        % Set to arbitrary small value
        pho_lower_new(pho_lower_new <= 0) = 1e-8;
        pho_upper_new(pho_upper_new <= 0) = 1e-8;

        % Compare new lower/upper to WFD phosphate boundaries
        % Which phosphate classes are covered now?
        % Add zero minimum (necessary) and 10000 maximum (arbitrary) 
        pho_new_class_logic = pho_lower_new < [pho_b, 10000 * ones(num_river_cell, 1)] & ...
                              pho_upper_new > [zeros(num_river_cell, 1), pho_b];
        % NB. if pho boundaries are NaN then this will be all zeros

        % Preallocate
        pho_new_class_prop = zeros(num_river_cell, 5);
        pho_new_class = cell(num_river_cell, 1);
        
        % Loop over river cells
        % Calculate proportion covered in new classes
        for j = 1:num_river_cell
            % Find which classes are covered now
            % Save in pho_new_class
            [~, pho_new_class_j] = find(pho_new_class_logic(j, :));
            if isempty(pho_new_class_j)
                pho_new_class{j} = NaN;
            else
                pho_new_class{j} = pho_new_class_j;
            end

            % Calculation of proportion changes depending on how many classes
            % are now covered, and whether we are on min/max boundary
            num_new_class = length(pho_new_class_j);
            if num_new_class == 0
                % Then pho boundaries must be NaN
                pho_new_class_prop(j, :) = nan(1, 5);
            elseif num_new_class == 1
                pho_new_class_prop(j, pho_new_class_j) = 1;
            elseif num_new_class == 2
                if pho_new_class_j(1) == 1
                    pho_new_class_prop(j, pho_new_class_j(1)) = (pho_b(j, pho_new_class_j(1)) - pho_lower_new(j)) / ...
                                                                (pho_b(j, pho_new_class_j(1)) - 0);
                    pho_new_class_prop(j, pho_new_class_j(2)) = (pho_upper_new(j) - pho_b(j, pho_new_class_j(2) - 1)) / ...
                                                                (pho_b(j, pho_new_class_j(2)) - pho_b(j, pho_new_class_j(2) - 1));
                elseif pho_new_class_j(2) == 5
                    pho_new_class_prop(j, pho_new_class_j(1)) = (pho_b(j, pho_new_class_j(1)) - pho_lower_new(j)) / ...
                                                                (pho_b(j, pho_new_class_j(1)) - pho_b(j, pho_new_class_j(1) - 1));
                    pho_new_class_prop(j, pho_new_class_j(2)) = 1 - pho_new_class_prop(j, pho_new_class_j(1));
                else
                    pho_new_class_prop(j, pho_new_class_j(1)) = (pho_b(j, pho_new_class_j(1)) - pho_lower_new(j)) / ...
                                                                (pho_b(j, pho_new_class_j(1)) - pho_b(j, pho_new_class_j(1) - 1));
                    pho_new_class_prop(j, pho_new_class_j(2)) = (pho_upper_new(j) - pho_b(j, pho_new_class_j(2) - 1)) / ...
                                                                (pho_b(j, pho_new_class_j(2)) - pho_b(j, pho_new_class_j(2) - 1));
                end
            elseif num_new_class == 3
                if pho_new_class_j(1) == 1
                    pho_new_class_prop(j, pho_new_class_j(1)) = (pho_b(j, pho_new_class_j(1)) - pho_lower_new(j)) / ...
                                                                (pho_b(j, pho_new_class_j(1)) - 0);
                    pho_new_class_prop(j, pho_new_class_j(3)) = (pho_upper_new(j) - pho_b(j, pho_new_class_j(3) - 1)) / ...
                                                                (pho_b(j, pho_new_class_j(3)) - pho_b(j, pho_new_class_j(3) - 1));
                elseif pho_new_class_j(3) == 5
                    pho_new_class_prop(j, pho_new_class_j(1)) = (pho_b(j, pho_new_class_j(1)) - pho_lower_new(j)) / ...
                                                                (pho_b(j, pho_new_class_j(1)) - pho_b(j, pho_new_class_j(1) - 1));
                    pho_new_class_prop(j, pho_new_class_j(3)) = 1 - pho_new_class_prop(j, pho_new_class_j(1));
                else
                    pho_new_class_prop(j, pho_new_class_j(1)) = (pho_b(j, pho_new_class_j(1)) - pho_lower_new(j)) / ...
                                                                (pho_b(j, pho_new_class_j(1)) - pho_b(j, pho_new_class_j(1) - 1));
                    pho_new_class_prop(j, pho_new_class_j(3)) = (pho_upper_new(j) - pho_b(j, pho_new_class_j(3) - 1)) / ...
                                                                (pho_b(j, pho_new_class_j(3)) - pho_b(j, pho_new_class_j(3) - 1));
                end
                pho_new_class_prop(j, pho_new_class_j(2)) = 1;
            elseif num_new_class == 4
                if pho_new_class_j(1) == 1
                    pho_new_class_prop(j, pho_new_class_j(1)) = (pho_b(j, pho_new_class_j(1)) - pho_lower_new(j)) / ...
                                                                (pho_b(j, pho_new_class_j(1)) - 0);
                    pho_new_class_prop(j, pho_new_class_j(4)) = (pho_upper_new(j) - pho_b(j, pho_new_class_j(4) - 1)) / ...
                                                                (pho_b(j, pho_new_class_j(4)) - pho_b(j, pho_new_class_j(4) - 1));
                elseif pho_new_class_j(4) == 5
                    pho_new_class_prop(j, pho_new_class_j(1)) = (pho_b(j, pho_new_class_j(1)) - pho_lower_new(j)) / ...
                                                                (pho_b(j, pho_new_class_j(1)) - pho_b(j, pho_new_class_j(1) - 1));
                    pho_new_class_prop(j, pho_new_class_j(4)) = 1 - pho_new_class_prop(j, pho_new_class_j(1));
                else
                    % Not possible?
                    error('Is this case possible?')
                end
                pho_new_class_prop(j, pho_new_class_j(2)) = 1;
                pho_new_class_prop(j, pho_new_class_j(3)) = 1;
            elseif num_new_class == 5
                pho_new_class_prop(j, pho_new_class_j(1)) = (pho_b(j, pho_new_class_j(1)) - pho_lower_new(j)) / ...
                                                            (pho_b(j, pho_new_class_j(1)) - 0);
                pho_new_class_prop(j, pho_new_class_j(2)) = 1;
                pho_new_class_prop(j, pho_new_class_j(3)) = 1;
                pho_new_class_prop(j, pho_new_class_j(4)) = 1;
                pho_new_class_prop(j, pho_new_class_j(5)) = 1 - pho_new_class_prop(j, pho_new_class_j(1));
            else
                % Not possible?
                error('Is this case possible?')
            end
        end

        % Save possible new classes in structure depending on decade
        new_class.(['pho', decade_str{i}]) = pho_new_class;
        
        % Rescale proportions to sum to one, to give probability of switching class
        % Save probabilities in structure depending on decade
        new_class_prob.(['pho', decade_str{i}]) = pho_new_class_prop ./ sum(pho_new_class_prop, 2);
    end
    
    %% (4) Calculate probability of switching WFD ecological class
    %  ===========================================================
    % Extract data required for fcn_predict_eco_class.m
    % The pho_class column will be overwritten in loop later
    wfd_data = NonUseWQTransfer.cell_data(:, {'bio_class', ...
                                              'sp_class', ...
                                              'hm_class', ...
                                              'pc_class', ...
                                              'amm_class', ...
                                              'dis_class', ...
                                              'pho_class'});
                                          
    % Loop over decades
    for i = 1:num_decades
        % Extract possible new classes and probabilities for this decade
        pho_new_class_i = new_class.(['pho', decade_str{i}]);
        pho_new_class_prob_i = new_class_prob.(['pho', decade_str{i}]);
        
        % Preallocate
        eco_class_prob = zeros(num_river_cell, 5);
        
        % Loop over river cells
        for j = 1:num_river_cell
            % Extract possible new classes and probabilities for this river cell
            pho_new_class_ij = pho_new_class_i{j, :};
            if isnan(pho_new_class_ij)
                pho_new_class_prob_ij = 1;
            else
                pho_new_class_prob_ij = pho_new_class_prob_i(j, pho_new_class_ij);
            end
            
            % Extract wfd_data for this river cell
            wfd_data_j = wfd_data(j, :);
            
            % Calculate number of possible new classes
            num_new_class_ij = length(pho_new_class_ij);
            
            % Loop over possible new classes
            for k = 1:num_new_class_ij
                % Overwrite phosphate class
                wfd_data_j.pho_class = pho_new_class_ij(k);
                
                % Predict ecological class using fcn_predict_eco_class.m
                eco_class_ijk = fcn_predict_eco_class(wfd_data_j);
                
                % Add to eco_class using probability
                eco_class_prob(j, eco_class_ijk) = eco_class_prob(j, eco_class_ijk) + pho_new_class_prob_ij(k);
            end
            
        end
        
        % Save probability of switching ecological class in structure
        % depending on decade
        switch_prob.(['eco_class_prob', decade_str{i}]) = eco_class_prob;
    end
    
    %% (5) Calculate non use water quality value
    %  =========================================
    % Calculate initial class
    % Reformat initial WFD class into logicals (classes 4 & 5 are combined)
    % NB. ordering of classes 1-5 is reversed to match old non use water
    % quality model
    WQual0 = [NonUseWQTransfer.cell_data.eco_class == 5, ...
              NonUseWQTransfer.cell_data.eco_class == 4, ...
              NonUseWQTransfer.cell_data.eco_class == 3, ...
              NonUseWQTransfer.cell_data.eco_class == 2 | NonUseWQTransfer.cell_data.eco_class == 1];
    
    % Loop over decades
    for i = 1:num_decades
        % Extract probability of switching ecological class for this decade
        % NB. ordering of classes 1-5 is reversed to match old non use water
        % quality model
        WQual1 = flip(switch_prob.(['eco_class_prob', decade_str{i}]), 2);
        WQual1(:, 4) = WQual1(:, 4) + WQual1(:, 5);
        WQual1 = WQual1(:, 1:4);
        
        % Preallocate
        vCENU0 = zeros(num_lsoa, 1);
        vCENU1 = zeros(num_lsoa, 1);
        
        % Loop over LSOAs
        for j = 1:num_lsoa
            % Extract distances to necessary river cells and apply distance decay
            DistdeltaNU = NonUseWQTransfer.cell_dist_500(j, lsoa_ind_mat(:, j)) .^ NonUseWQTransfer.deltaNU;
            
            % !!! river length scale flag? !!!
            
            % Extract water quality classes/probability for necessary river cells
            % Change the ordering to be consistent with distances
            % Multiply by beta parameter
            XbQNU0 = WQual0(lsoa_river_cells_order{j}, 2:4) * NonUseWQTransfer.betaQNU;
            XbQNU1 = WQual1(lsoa_river_cells_order{j}, 2:4) * NonUseWQTransfer.betaQNU;

            % Multiply decayed distances by XbQNU matrices, scaled up by num_days
            vCENU0(j) = num_days * DistdeltaNU * XbQNU0;
            vCENU1(j) = num_days * DistdeltaNU * XbQNU1;
        end
        
        % Output is difference in value, scaled by households in lsoa and
        % deltaU parameter
        % Save to es_non_use_wq structure as value_ann_decade
        es_non_use_wq_transfer.(['value_ann', decade_str{i}]) = sum(NonUseWQTransfer.lsoa_data.hhld .* (vCENU1 - vCENU0) / - NonUseWQTransfer.deltaU);
    end
end
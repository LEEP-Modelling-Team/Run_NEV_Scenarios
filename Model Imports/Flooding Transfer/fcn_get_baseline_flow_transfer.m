function [flow_results, subctch_ids] = fcn_get_baseline_flow_transfer(parameters, hash)
    % fcn_get_baseline_flow_transfer.m
    % ============================
    % Author: Nathan Owen
    % Last modified: 11/10/2019
    % Take the base run of the NEV water transfer model for all subcatchments and 
    % store the flow results in baseline_flow_transfer.mat. The .mat file 
    % contains the daily flow for all subcatchments between the years 
    % 2020-2059 (14610 days).
    
    % Load water transfer model data
    load([parameters.water_transfer_data_folder,'NEVO_Water_Transfer_data.mat'])

    % Calculate number of basins and subcatchments
    num_basin = size(basin_ids, 1);
    num_subctch = size(base_lcs_subctch, 1);

    % Pre-allocate arrays to store results
    % number of days in years 2020-2059: 14610
    subctch_ids_unordered = [];   % subbasin ids
    flow_results = nan(size(subctch_basins, 1), 14610);  % daily flow 2020-2059

    % Start a counter for each decade
    count_20 = 1;
    count_30 = 1;
    count_40 = 1;
    count_50 = 1;

    % Loop over all basins
    for i = 1:num_basin

        % Extract this basin id and print to console
        basin_id = basin_ids(i);
        disp(basin_id)

        % Get subcatchment IDs in this basin, in specific order that they
        % were saved in base run
        subctch_ids_basini = subctch_basins.subctch_id(subctch_basins.basin_id == basin_ids(i));

        % Calculate number of subbasins in this basin
        num_subctch_basini = length(subctch_ids_basini);

        % Add subctch_ids to full list
        subctch_ids_unordered = [subctch_ids_unordered; subctch_ids_basini];

        % Loop over the four decades
        for decade = [2029, 2039, 2049, 2059]

            % Load baseline results for this basin in this decade
            load(strcat(parameters.water_transfer_data_folder,'Base Run\', hash, '\base', num2str(basin_id), '_', num2str(decade), '.mat'))

            % Loop over all subbasins in basin
            for j = 1:num_subctch_basini

                % Save flow data into flow_results array depending on decade
                switch decade
                    case 2029
                        % Also construct and store subbasin id here
                        flow_results(count_20, 1:3653) = basin_em_data{j}.flow';
                        count_20 = count_20 + 1;
                    case 2039
                        flow_results(count_30, 3654:7305) = basin_em_data{j}.flow';
                        count_30 = count_30 + 1;
                    case 2049
                        flow_results(count_40, 7306:10958) = basin_em_data{j}.flow';
                        count_40 = count_40 + 1;
                    case 2059
                        flow_results(count_50, 10959:14610) = basin_em_data{j}.flow';
                        count_50 = count_50 + 1;
                end

            end

            % Clear basin data for this decade 
            clear basin_em_data

        end

    end

    % Reorder data so that it is in the order of base_lcs_subctch.subctch_id
    flow_table = table(subctch_ids_unordered, flow_results, 'VariableNames', {'subctch_id', 'flow_results'});
    flow_table_join = outerjoin(base_lcs_subctch, flow_table, 'MergeKeys', true, 'LeftVariables', 'subctch_id');
    [~, idx] = ismember(base_lcs_subctch.subctch_id, flow_table_join.subctch_id);
    flow_table_ordered = flow_table_join(idx, :);

    subctch_ids = flow_table_ordered.subctch_id;
    flow_results = flow_table_ordered.flow_results;

end

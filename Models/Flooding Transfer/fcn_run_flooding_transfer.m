function es_flooding_transfer = fcn_run_flooding_transfer(flooding_transfer_data_folder, input_subctch, flow, event_parameter, limit2reduction)
    % fcn_run_flooding_transfer.m
    % ===========================
    % Author: Nathan Owen, Brett Day
    % Last modified: 09/03/2020
    % Function to run the NEV flooding transfer model, which calculates the 
    % value associated with a reduction in flood damages from a change in 
    % daily flow in a subcatchment (which has arised from a land use 
    % change). The model is constrained to provide value only when the 
    % number of flood events per year has reduced, and zero value otherwise.
    % Inputs:
    % - flooding_transfer_data_folder: path to the .mat file containing the
    %   data for the model. The .mat file is generated in
    %   ImportFloodingTransfer.m and for me is saved in the path 
    %   C:/Data/Flooding Transfer/
    % - input_subctch: a cell array of subcatchment ID numbers, also
    %   referred to as subctch_id number. These should correspond each row 
    %   of the 'flow' input.
    % - flow: a [num_subctch x 14610] matrix containing daily flow between 
    %   2020-2059 for the subcatchments given by the 'input_subctch' input.
    % - event_parameter: a parameter which determines what is considered to
    %   be a flood event. Exceedances of flow above the calculated
    %   threshold which occur within 'event_parameter' days of one another
    %   are clustered into the same flood event. Appropriate values are 1
    %   or 7, with 7 being preferred. 
    % Outputs:
    % - es_flooding_transfer: a table containing the flooding output for 
    %   each subcatchment requested in the 'input_subctch' input. 
    %   Specifically, the value in £/year associated with a reduction in 
    %   flood damages is returned in three formats:
    %   1. assuming the change in flow affects the likelihood of the 30
    %      year flood event only (flood_value_30)
    %   2. assuming the change in flow affects the likelihood of the 30 and
    %      100 year flood events (flood_value_30_1000)
    %   3. assuming the change in flow affects the likelihood of the 30,
    %      100 and 1000 year flood events (flood_value_30_100_1000)
    
    %% (1) Set up
    %  ==========
    % (a) Constants
    % -------------
    if (event_parameter ~= 1 && event_parameter ~= 7)
        error('Event parameter must be 1 or 7.')
    end
    num_subctch = size(input_subctch, 1);
    day_seq = 1:14610;
    
    % (b) Data files
    % --------------
    NEVO_Flooding_data_mat = [flooding_transfer_data_folder, 'NEVO_Flooding_Transfer_data_', num2str(event_parameter), '.mat'];
    load(NEVO_Flooding_data_mat, 'FloodingTransfer');
    
    %% (2) Reduced to inputted subcatchments
    %  =====================================
    [input_subctch_ind, input_subctch_idx] = ismember(input_subctch, FloodingTransfer.subctch_id);
    input_subctch_idx = input_subctch_idx(input_subctch_ind);
    
    % Flooding structure
    FloodingTransfer = FloodingTransfer(input_subctch_idx, :);
    
    %% (3) Calculate flooding outputs
    %  ==============================
    % Preallocate outputs
    % -------------------
    % Change in probabality of different events
    diff_prob_10 = zeros(num_subctch, 1);
    diff_prob_30 = zeros(num_subctch, 1);
    diff_prob_100 = zeros(num_subctch, 1);
    diff_prob_200 = zeros(num_subctch, 1);
    diff_prob_1000 = zeros(num_subctch, 1);
    
    % First difference in damage costs (different for England & Wales / Scotland)
    diff_damage_10_ew = zeros(num_subctch, 1);
    diff_damage_30_ew = zeros(num_subctch, 1);
    diff_damage_100_ew = zeros(num_subctch, 1);
    diff_damage_1000_ew = zeros(num_subctch, 1);
    
    diff_damage_30_s = zeros(num_subctch, 1);
    diff_damage_200_s = zeros(num_subctch, 1);
    
    % Area / expected reduction in damage cost associated with different
    % events (different for England & Wales / Scotland)
    area_10_ew = zeros(num_subctch, 1);
    area_30_ew = zeros(num_subctch, 1);
    area_100_ew = zeros(num_subctch, 1);
    area_1000_ew = zeros(num_subctch, 1);
    
    area_30_s = zeros(num_subctch, 1);
    area_200_s = zeros(num_subctch, 1);
    
    % Total flood mitigation benefit
    % Low, medium and high estimates given, these are different
    % combinations of the areas above
    flood_value_low = zeros(num_subctch, 1);
    flood_value_medium = zeros(num_subctch, 1);
    flood_value_high = zeros(num_subctch, 1);
    
    % Loop over subcatchments
    for i = 1:num_subctch
        % (a) Get baseline info for this subbasin
        % ---------------------------------------
        base_threshold = FloodingTransfer.threshold(i);                       % threshold
        base_num_events_per_year = FloodingTransfer.num_events_per_year(i);   % number of events per year
        damage_10 = FloodingTransfer.damage_10(i);                            % damage for 10-year event
        damage_30 = FloodingTransfer.damage_30(i);                            % damage for 30-year event
        damage_100 = FloodingTransfer.damage_100(i);                          % damage for 100-year event
        damage_200 = FloodingTransfer.damage_200(i);                          % damage for 200-year event
        damage_1000 = FloodingTransfer.damage_1000(i);                        % damage for 1000-year event

        % (b) Calculate number of events per year in scenario
        % ---------------------------------------------------
        % Get scenario flow events above baseline threshold
        [day_seq_events, ~] = fcn_get_flow_events(day_seq, flow(i, :), base_threshold, event_parameter);

        % Calculate scenario number of events per year
        scen_num_events = length(day_seq_events);
        scen_num_events_per_year = scen_num_events / 40;

        % (c) Has number of events per year reduced?
        % ------------------------------------------
        % Flood value only generated if number of events per year has
        % reduced
        % Take the minimum of baseline and scenario number events per
        % year
        if limit2reduction == 1
            scen_num_events_per_year = min(base_num_events_per_year, scen_num_events_per_year);
        end

        % (d) Calculate probability of 10, 30, 100, 200 and 1000 year 
        % events in scenario
        % -----------------------------------------------------------
        % Baseline probability is reciprocal of 10, 30, 100, 200 and 1000
        % Reverse order to make calculations easier
        base_prob = [1/1000, 1/200, 1/100, 1/30, 1/10]; 

        % Scenario probability is baseline probability multiplied by
        % factor scen_num_events_per_year / base_num_events_per_year
        % Note: if scenario number of events per year has not reduced
        % this factor is 1, i.e. probabilities remain the same
        scen_prob = (scen_num_events_per_year / base_num_events_per_year) * base_prob;

        % (e) Calculate expected damage reduction / flood benefit
        % -------------------------------------------------------
        % Approximate as rectangular area
        % Reduction in probability of 1000, 100 and 30 year events
        diff_prob = base_prob - scen_prob;
        
        % Store the reduction in probability for output return
        diff_prob_10(i) = diff_prob(5);
        diff_prob_30(i) = diff_prob(4);
        diff_prob_100(i) = diff_prob(3);
        diff_prob_200(i) = diff_prob(2);
        diff_prob_1000(i) = diff_prob(1);

        % First differences of damages
        % Reverse order to be consistent with order of probabilities
        % Different approach for England & Wales / Scotland
        diff_damage_ew = [damage_1000 - damage_100, ...
                          damage_100 - damage_30, ...
                          damage_30 - damage_10, ...
                          damage_10];
        diff_damage_s = [damage_200 - damage_30, ...
                         damage_30];
        
        % Due to overlap of 30 year event in England, Wales and Scotland we
        % must set some cases to zero
        if any(diff_damage_ew < 0)
            diff_damage_ew = zeros(1, 4);
        end
        if any(diff_damage_s < 0)
            diff_damage_s = zeros(1, 2);
        end
        
        % Store the first difference of damages for output return
        diff_damage_10_ew(i)   = diff_damage_ew(4);
        diff_damage_30_ew(i)   = diff_damage_ew(3);
        diff_damage_100_ew(i)  = diff_damage_ew(2);
        diff_damage_1000_ew(i) = diff_damage_ew(1);
        
        diff_damage_30_s(i)  = diff_damage_s(2);
        diff_damage_200_s(i) = diff_damage_s(1);

        % Calculate areas / expected damage cost reduction associated with 
        % 10, 30, 100, 200 and 1000 year events (approximate as rectangular
        % areas)
        % Store the areas for output return
        area_10_ew(i)   = diff_prob_10(i)   * diff_damage_10_ew(i);
        area_30_ew(i)   = diff_prob_30(i)   * diff_damage_30_ew(i);
        area_100_ew(i)  = diff_prob_100(i)  * diff_damage_100_ew(i);
        area_1000_ew(i) = diff_prob_1000(i) * diff_damage_1000_ew(i);
        
        area_30_s(i) = diff_prob_30(i)   * diff_damage_30_s(i);
        area_200_s(i) = diff_prob_200(i) * diff_damage_200_s(i);

        % Return three outputs...
        % Low estimate: Land use change assumed to affect 10 and 30 year
        %               events in England & Wales
        %               Land use change assumed to affect 30 year event in
        %               Scotland
        % Medium estimate: Land use change assumed to affect 10, 30 and 100 
        %                  year events in England & Wales
        %                  Land use change assumed to affect 30 and 200 
        %                  year events in Scotland
        % High estimate: Land use change assumed to affect 10, 30, 100 and 
        %                1000 year events in England & Wales
        %                Land use change assumed to affect 30 and 200 year 
        %                events in Scotland
        % Due to different approaches in England & Wales / Scotland we must
        % use min/max to extract correct value
        if all(diff_prob < 0)
            flood_value_low(i)      = min(area_10_ew(i) + area_30_ew(i), area_30_s(i));
            flood_value_medium(i)   = min(area_10_ew(i) + area_30_ew(i) + area_100_ew(i), area_30_s(i) + area_200_s(i));
            flood_value_high(i)     = min(area_10_ew(i) + area_30_ew(i) + area_100_ew(i) + area_1000_ew(i), area_30_s(i) + area_200_s(i));
        elseif all(diff_prob > 0 )
            flood_value_low(i)      = max(area_10_ew(i) + area_30_ew(i), area_30_s(i));
            flood_value_medium(i)   = max(area_10_ew(i) + area_30_ew(i) + area_100_ew(i), area_30_s(i) + area_200_s(i));
            flood_value_high(i)     = max(area_10_ew(i) + area_30_ew(i) + area_100_ew(i) + area_1000_ew(i), area_30_s(i) + area_200_s(i));
        elseif all(diff_prob == 0 )
            flood_value_low(i)      = 0;
            flood_value_medium(i)   = 0;
            flood_value_high(i)     = 0;
        elseif all(isnan(diff_prob))
            flood_value_low(i)      = NaN;
            flood_value_medium(i)   = NaN;
            flood_value_high(i)     = NaN;
        else
            error('verify that flows are correct!')
        end
    end
    
    %% (4) Format output
    %  =================
    % Return as table
    es_flooding_transfer = table(input_subctch, ...
                                 diff_prob_10, ...
                                 diff_prob_30, ...
                                 diff_prob_100, ...
                                 diff_prob_200, ...
                                 diff_prob_1000, ...
                                 diff_damage_10_ew, ...
                                 diff_damage_30_ew, ...
                                 diff_damage_100_ew, ...
                                 diff_damage_1000_ew, ...
                                 diff_damage_30_s, ...
                                 diff_damage_200_s, ...
                                 area_10_ew, ...
                                 area_30_ew, ...
                                 area_100_ew, ...
                                 area_1000_ew, ...
                                 area_30_s, ...
                                 area_200_s, ...
                                 flood_value_low, ...
                                 flood_value_medium, ...
                                 flood_value_high, ...
                                 'VariableNames', ...
                                 {'subctch_id', ...
                                  'diff_prob_10', ...
                                  'diff_prob_30', ...
                                  'diff_prob_100', ...
                                  'diff_prob_200', ...
                                  'diff_prob_1000', ...
                                  'diff_damage_10_ew', ...
                                  'diff_damage_30_ew', ...
                                  'diff_damage_100_ew', ...
                                  'diff_damage_1000_ew', ...
                                  'diff_damage_30_s', ...
                                  'diff_damage_200_s', ...
                                  'area_10_ew', ...
                                  'area_30_ew', ...
                                  'area_100_ew', ...
                                  'area_1000_ew', ...
                                  'area_30_s', ...
                                  'area_200_s', ...
                                  'flood_value_low', ...
                                  'flood_value_medium', ...
                                  'flood_value_high'});

end
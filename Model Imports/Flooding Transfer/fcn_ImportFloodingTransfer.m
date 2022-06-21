function FloodingTransfer = fcn_ImportFloodingTransfer(parameters, hash, conn)

    % fcn_ImportFloodingTransfer.m
    % ========================
    % Author: Nathan Owen
    % Last modified: 09/03/2020
    % Import all data required for running the NEV flooding transfer model. 
    % To be loaded from within fcn_run_flooding_transfer.m
    % We run this twice with the event parameter set to 1 and 7.

    %% (1) Load, prepare and save data
    %  ===============================
    tic
    % (a) Load baseline flow data
    % ---------------------------
    load([parameters.water_transfer_data_folder, 'Baseline Flow Transfer\', hash, '\baseline_flow_transfer.mat'])

    % (b) Damage costs
    % ----------------
    % Prepared by Brett and Nathan
    sqlquery = ['SELECT ', ...
                    'subctch_id, ', ...
                    'total_1in10, ', ...
                    'total_1in30, ', ...
                    'total_1in100, ', ...
                    'total_1in200, ', ...
                    'total_1in1000 ', ...
                'FROM flooding.damage_gb_subctch ', ...
                'ORDER BY subctch_id'];
    setdbprefs('DataReturnFormat', 'table')
    dataReturn = fetch(exec(conn, sqlquery));
    damage_costs = dataReturn.Data;

    % (c) Peak over threshold analysis
    % --------------------------------
    % Calculate number of subcatchments
    num_subctch = size(subctch_ids, 1);

    % Set up sequence of days
    day_seq = 1:14610;

    % Model parameters
    target_events_per_year = parameters.target_events_per_year; % number of events per year we want to retain
    event_parameter = parameters.event_parameter; % what we consider to be an event, i.e. days between exceedances
    plot_flag = false;

    % Preallocate table array to store results
    FloodingTransfer = array2table(nan([num_subctch, 4]), ...
                                   'VariableNames', ...
                                   {'subctch_id', ...
                                    'threshold', ...
                                    'event_parameter', ...
                                    'num_events_per_year'});

    % Fill in subcatchment subctch_id
    FloodingTransfer.subctch_id = subctch_ids;

    % Fill in damage costs
    FloodingTransfer.damage_10 = damage_costs.total_1in10;
    FloodingTransfer.damage_30 = damage_costs.total_1in30;
    FloodingTransfer.damage_100 = damage_costs.total_1in100;
    FloodingTransfer.damage_200 = damage_costs.total_1in200;
    FloodingTransfer.damage_1000 = damage_costs.total_1in1000;

    % Perform peak over threshold analysis for each subcatchment
    for i = 1:num_subctch
        % Display current subcatchment id
        disp([i, subctch_ids(i)])

        % Extract flow for this subcatchment
        flow = flow_results(i, :);

        if any(isnan(flow))
            % If any NaN flow, skip this subctch
            continue
        else
            % Else, run fcn_peak_over_threshold function
            [parameters_i, num_events_per_year_i, ~, ~, ~] = fcn_peak_over_threshold(day_seq, flow, target_events_per_year, event_parameter, plot_flag);

            % Store results in FloodingTransfer table
            FloodingTransfer.threshold(i) = parameters_i(1);
            FloodingTransfer.event_parameter(i) = event_parameter;
            FloodingTransfer.num_events_per_year(i) = num_events_per_year_i;
        end
    end
    toc
end
function thresh = fcn_set_threshold(day_seq, flow, target_events_per_year, event_parameter)

    % Set a threshold
    % Calculate thresholds to keep average of 5 events per year
    % Use clustering in fcn_get_flow_events with event_parameter
    thresh_min = quantile(flow, 0.9);
    thresh_max = quantile(flow, 0.999);

    tol = 0.001;
    iterations = 0;
    max_iterations = 1000;
    num_events_per_year = 0;
    
    while abs(num_events_per_year - target_events_per_year) > tol

        thresh = mean([thresh_min, thresh_max]);
        [day_seq_events, ~] = fcn_get_flow_events(day_seq, flow, thresh, event_parameter);
        num_events = length(day_seq_events);
        num_events_per_year = num_events / 40;

        if num_events_per_year > target_events_per_year + tol
            thresh_min = thresh;
        elseif num_events_per_year < target_events_per_year - tol
            thresh_max = thresh;
        end
        
        iterations = iterations + 1;
        
        if iterations > max_iterations
            % Then it's not possible to get num_events_per_year events with
            % any threshold and event_parameter.
            break
        end

    end
    
end
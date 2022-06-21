function [parameters, num_events_per_year, day_seq_events, flow_events, return_levels] = fcn_peak_over_threshold(day_seq, flow, target_events_per_year, event_parameter, plot_flag)

    % Set a threshold
    % Calculate thresholds to keep average of 5 events per year
    thresh = fcn_set_threshold(day_seq, flow, target_events_per_year, event_parameter);
    
    % Get flow events above this threshold
    [day_seq_events, flow_events] = fcn_get_flow_events(day_seq, flow, thresh, event_parameter);
    num_events = length(day_seq_events);
    num_events_per_year = num_events / 40; % this should be close to target events per year
    
    % Turn flow events into exceedances by subtracting threshold
    flow_exceed = flow_events - thresh;
    
    % Fit Generalized Pareto distribution to flow exceedances
    % Can get parameter confidence intervals as
    [parm_hat, ~] = gpfit(flow_exceed);
    shape_hat = parm_hat(1);    % shape parameter estimate
    scale_hat = parm_hat(2);    % scale parameter estimate
    
    % Collect parameters into a vector (for return)
    parameters = [thresh, shape_hat, scale_hat];
    
    % Model checking plots
    if plot_flag
        fcn_model_checking_plots(flow_events, num_events_per_year, shape_hat, scale_hat, thresh)
    end
    
    % Calculate return levels for 30-year, 100-year and 1000-year event
    % Assume mean number of events per year is 5
    return_periods = [30, 100, 1000];
    p = 1 ./ (num_events_per_year .* return_periods);
    return_levels = gpinv(1 - p, shape_hat, scale_hat, thresh);

end
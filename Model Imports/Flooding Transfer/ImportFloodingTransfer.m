% ImportFloodingTransfer.m
% ========================
% Author: Nathan Owen
% Last modified: 09/03/2020
% Import all data required for running the NEV flooding transfer model. 
% To be loaded from within fcn_run_flooding_transfer.m
% We run this twice with the event parameter set to 1 and 7.
clear

%% (0) Set up
%  ==========
% (a) Flags
% ---------
database_calls_flag = true;     % Load, prepare and save data
test_function_flag = false;      % Test model

% (b) Database connection
% -----------------------
server_flag = false;
conn = fcn_connect_database(server_flag);

% (c) Set paths for storing imported data
% ---------------------------------------
SetDataPaths;

%% (1) Load, prepare and save data
%  ===============================
if database_calls_flag
    tic
	% (a) Load baseline flow data
    % ---------------------------
	load([flooding_transfer_data_folder, 'baseline_flow_transfer.mat'])
    
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
	target_events_per_year = 5; % number of events per year we want to retain
	event_parameter = 7; % what we consider to be an event, i.e. days between exceedances
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
    
    % Save Flooding table and flow_results to .mat file
	save([flooding_transfer_data_folder, 'NEVO_Flooding_Transfer_data_', num2str(event_parameter), '.mat'], 'FloodingTransfer');
    
    toc
end

%% (2) Test function
%  =================
% NB. IMPORTANT
% Land use change for the purposes of flood mitigation benefit (Natural
% Flood Management, NFM) is not always possible like this NEV flooding
% model predicts. The predictions should be masked afterwards with
% information on whether the changed cell has a potential for NFM. This was
% done in the Defra ELMs project, see the file 
% fcn_run_flooding_transfer_from_results in the ELM Options folder. Per
% hectare flooding benefits are scaled up by the possible potential
% hectares for NFM, taken from the government's WWNP project.
if test_function_flag
    
    % Choose example to run
    run_example1_flag = true;   % take baseline flow and reduce by a percentage
    run_example2_flag = false;  % run water transfer model under a land cover change
    
    if run_example1_flag
        % EXAMPLE 1: TAKE BASELINE FLOW AND REDUCE BY A PERCENTAGE
        % ========================================================
        % (a) Load baseline flow fom .mat file
        % ------------------------------------
        load([flooding_transfer_data_folder, 'baseline_flow_transfer.mat'])

        % (b) Select subcatchments to test flooding model
        % -------------------------------------------
    %     subctch_id = {'6300_0'; '3081_0'; '1708_0'};
        subctch_id = subctch_ids;

        % Reduce flow results to these subcatchments
        [~, idx] = ismember(subctch_id, subctch_ids);
        flow = flow_results(idx, :);

        % (c) Reduce the flow uniformly by a percentage
        % ---------------------------------------------
        percentage_reduct = 0.9;
        flow = percentage_reduct * flow;

        % (d) Run flooding model
        % ----------------------
        tic
        es_water_flood_transfer = fcn_run_flooding_transfer(flooding_transfer_data_folder, subctch_id, flow, 7, false);
        toc
    end
    
    if run_example2_flag
        % EXAMPLE 2: RUN WATER TRANSFER MODEL UNDER LAND COVER CHANGE,
        % CALCULATE FLOODING BENEFIT
        % ============================================================
        % (a) Identify cell(s) and overlapping/downstream subcatchment(s)
        % ---------------------------------------------------------------
        % NB input_subctch must be in column vector
%         cell_id = 103620;
%         input_subctch = {'3594_0'};

%         cell_id = 103620;
%         input_subctch = {'3594_0'; '3594_1'};

        cell_id = [57880; ...
                    (58527:58530)'; ...
                    (59176:59181)'; ...
                    (59826:59831)'; ...
                    (60476:60480)'; ...
                    (61128:61130)'; ...
                    (61778:61780)'; ...
                    (62428:62429)'];
        input_subctch = {'4050_0'; ...
                          '4069_0'; ...
                          '4068_0'; ...
                          '60_0'};

        % (b) Get cell landuses from database
        % -----------------------------------
        if length(cell_id) > 1
            sqlquery = ['SELECT ', ...
                        'new2kid, ', ...
                        'water_ha, ', ...
                        'urban_ha, ', ...
                        'sngrass_ha, ', ...
                        'wood_ha, ', ...
                        'pgrass_ha_20, pgrass_ha_30, pgrass_ha_40, pgrass_ha_50, ', ...
                        'tgrass_ha_20, tgrass_ha_30, tgrass_ha_40, tgrass_ha_50, ', ...
                        'rgraz_ha_20, rgraz_ha_30, rgraz_ha_40, rgraz_ha_50, ', ...
                        'wheat_ha_20, wheat_ha_30, wheat_ha_40, wheat_ha_50, ', ...
                        'wbar_ha_20, wbar_ha_30, wbar_ha_40, wbar_ha_50, ', ...
                        'sbar_ha_20, sbar_ha_30, sbar_ha_40, sbar_ha_50, ', ...
                        'osr_ha_20, osr_ha_30, osr_ha_40, osr_ha_50, ', ...
                        'pot_ha_20, pot_ha_30, pot_ha_40, pot_ha_50, ', ...
                        'sb_ha_20, sb_ha_30, sb_ha_40, sb_ha_50, ', ...
                        'other_ha_20, other_ha_30, other_ha_40, other_ha_50 ', ...
                    'FROM nevo_explore.explore_2km ', ...
                    'WHERE new2kid IN (', strrep(strrep(jsonencode(cell_id), '[', ''), ']', ''), ')'];
        else
            sqlquery = ['SELECT ', ...
                        'new2kid, ', ...
                        'water_ha, ', ...
                        'urban_ha, ', ...
                        'sngrass_ha, ', ...
                        'wood_ha, ', ...
                        'pgrass_ha_20, pgrass_ha_30, pgrass_ha_40, pgrass_ha_50, ', ...
                        'tgrass_ha_20, tgrass_ha_30, tgrass_ha_40, tgrass_ha_50, ', ...
                        'rgraz_ha_20, rgraz_ha_30, rgraz_ha_40, rgraz_ha_50, ', ...
                        'wheat_ha_20, wheat_ha_30, wheat_ha_40, wheat_ha_50, ', ...
                        'wbar_ha_20, wbar_ha_30, wbar_ha_40, wbar_ha_50, ', ...
                        'sbar_ha_20, sbar_ha_30, sbar_ha_40, sbar_ha_50, ', ...
                        'osr_ha_20, osr_ha_30, osr_ha_40, osr_ha_50, ', ...
                        'pot_ha_20, pot_ha_30, pot_ha_40, pot_ha_50, ', ...
                        'sb_ha_20, sb_ha_30, sb_ha_40, sb_ha_50, ', ...
                        'other_ha_20, other_ha_30, other_ha_40, other_ha_50 ', ...
                    'FROM nevo_explore.explore_2km ', ...
                    'WHERE new2kid IN (', num2str(cell_id), ')'];
        end
        setdbprefs('DataReturnFormat', 'table')
        dataReturn = fetch(exec(conn, sqlquery));
        landuses_base = dataReturn.Data;

        % (c) Create scenario with landuses change
        % ----------------------------------------
        % E.g. add 50 hectares to woodland from wheat
        landuses_scen = landuses_base;
        landuses_scen.wood_ha = landuses_scen.wood_ha + 50;
        landuses_scen.pgrass_ha_20 = landuses_scen.pgrass_ha_20 - 50;
        landuses_scen.pgrass_ha_30 = landuses_scen.pgrass_ha_30 - 50;
        landuses_scen.pgrass_ha_40 = landuses_scen.pgrass_ha_40 - 50;
        landuses_scen.pgrass_ha_50 = landuses_scen.pgrass_ha_50 - 50;
        % !!! this land use change may not actually 'work' !!!

        % (d) Run water model
        % -------------------
        SetDataPaths;
        other_ha_string = 'baseline';
        [es_water_transfer, flow_transfer] = fcn_run_water_transfer(water_transfer_data_folder, landuses_scen, input_subctch, 0, 0, other_ha_string);

        % (e) Run flooding model using scenario flow
        % ------------------------------------------
        es_flooding_transfer = fcn_run_flooding_transfer(flooding_transfer_data_folder, input_subctch, flow_transfer, 7);
    end

end

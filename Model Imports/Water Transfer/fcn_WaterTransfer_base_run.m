function fcn_WaterTransfer_base_run(uk_baseline, parameters, hash)
    %% (1) Base run
    %  ============
    % Here we run the water transfer model for all subcatchments/basins
    % under baseline land uses as predicted by NEV agriculture model
    % The flow in each decade for each basin is saved in 
    % /Model Data/Base Run
    % This then allows us to run the function for each subcatchment, as
    % upstream flow can be loaded from the base run

    % (a) Deal with land uses
    % -----------------------
    % Take decadal averages                                 
    landuses = uk_baseline;

    % (b) Select subcatchments to run base flow for
    % ---------------------------------------------
    % Default is all subcatchments
    load([parameters.water_transfer_data_folder,'NEVO_Water_Transfer_data.mat'], 'base_lcs_subctch');
    subctch_ids = base_lcs_subctch.subctch_id;

    % (c) Run water model for these subcatchments
    % -------------------------------------------
    % NB. base_run must be set to 1! This saves base runs in /Model Data
    tic
        [es_water_transfer, flow_transfer] = fcn_run_water_transfer(parameters.water_transfer_data_folder, ...
                                                                    landuses, ...
                                                                    subctch_ids, ...
                                                                    1, ...
                                                                    'baseline', ...
                                                                    hash);
    toc


end
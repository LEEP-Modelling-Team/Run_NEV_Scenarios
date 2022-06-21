function [water_transfer_results, water_transfer_cell2subctch, nfm_data] = fcn_load_rep_cells(parameters, unique_opts, conn, hash)
    % fcn_import_water_quality_info.m
    % ===============================
    % Load data necessary for calculating water quality benefits in the 
    % two_run_elm_options.m code. Specifically the outputs of this function
    % are used in fcn_run_water_quality_from_results.m

    % (a) Load water quality results from .mat file
    % ---------------------------------------------
    for i = 1:numel(unique_opts)
        load(strcat(parameters.water_transfer_data_folder, ...
                    'Representative Cells\', ...
                    hash, ...
                    '\water_', ...
                    unique_opts{i}, ...
                    '.mat'), strcat('water_', unique_opts{i}));
        water_transfer_results.(unique_opts{i}) = eval(strcat('water_', unique_opts{i}));
    end
    
    % (b) Cell to subcatchment lookup from database
    % ---------------------------------------------
    sqlquery = ['SELECT * FROM regions_keys.key_grid_wfd_subcatchments' ...
                ' ORDER BY new2kid ASC;'];
    setdbprefs('DataReturnFormat', 'table');
    dataReturn = fetch(exec(conn, sqlquery));
    water_transfer_cell2subctch = dataReturn.Data;
    
    % (c) Natural flood management areas
    % ----------------------------------
    sqlquery = ['SELECT ', ...
                    'new2kid, ', ...
                    'nfm_cell, ', ...
                    'nfm_area_ha ', ...
                'FROM flooding.nfm_cells_gb ', ...
                'ORDER BY new2kid'];
    setdbprefs('DataReturnFormat', 'table');
    dataReturn = fetch(exec(conn, sqlquery));
    nfm_data = dataReturn.Data;
end
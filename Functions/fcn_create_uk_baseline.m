function [landuse, ind] = fcn_create_uk_baseline(parameters, baseline_land_cover, conn)
    %% fcn_create_uk_baseline
    % =======================
    %  Author: Mattia Mancini, Rebecca Collins
    %  Created: 27 May 2022
    %  Last modified: 27 May 2022
    %  ---------------------------------------
    %
    %  DESCRIPTION
    %  This function takes the 5 top level land uses from a selected land
    %  cover map of the UK, modified (if needed) with the land uses passed
    %  from a baseline specified in run_NEV.m section 2.1. 
    %  The output is then used for running the hydrology models, which can
    %  extend outside the boundaries of the baseline areas specified in
    %  run_NEV.m section 2.1.
    %% ====================================================================
    
    %% (1) Load Land cover map for the UK
    %  ==================================
    base_lcm_data = strcat(parameters.lcm_data_folder, 'lcm_aggr_', parameters.base_ceh_lcm, '.csv');
    uk_lcm = readtable(base_lcm_data);
    
    %% (2) Load from the SQL database data on forestry
    %  ===============================================
    required_wood = {'wood_mgmt_ha', 'p_decid_mgmt', 'p_conif_mgmt'};
    sqlquery = ['SELECT ', ...
                    'new2kid, ', ...
                    strjoin(required_wood, ', '), ...
                ' FROM nevo.nevo_variables ', ...
                'ORDER BY new2kid'];
    setdbprefs('DataReturnFormat', 'table');
    dataReturn = fetch(exec(conn, sqlquery));
    cell_data = dataReturn.Data;
    landuse = outerjoin(uk_lcm, cell_data, 'Type','Left','MergeKeys',true);
    
    col_names = landuse.Properties.VariableNames;
    [~, ind] = intersect(landuse.new2kid, baseline_land_cover.new2kid);
    landuse(ind,:) = baseline_land_cover(:, col_names);
end
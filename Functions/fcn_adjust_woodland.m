function landuse = fcn_adjust_woodland(baseline_landuse, scenario_landuse)
    %% fcn_adjust_woodland.m
    %  =====================
    %  Author: Mattia Mancini, Rebecca Collins
    %  Created: 20-Jun-2022
    %  Last modified: 20-Jun-2022
    %  ---------------------------------------
    %
    %  DESCRIPTION
    %  Function that takes the baseline landuse and the scenario landuses
    %  passed and readjusts the amounts of hectares of managed woodland and
    %  their proportions. This is required because land cover maps do not 
    %  contain data on managed vs. unmanaged woodland, so we take that from
    %  the 2007 proportions stored in the SQL database and apply them to
    %  whichever other LCM is used. Also, new woodland from land use change
    %  can only go into the managed category, hence changing baseline
    %  proportions. 
    %  ====================================================================
    
    %% (1) WOODLAND CHANGE
    %  ===================
    
    % 1.1. Positive wood changes
    %      In this case, all new woodland is managed
    % ----------------------------------------------
    idx = (scenario_landuse.wood_ha - baseline_landuse.wood_ha) > 0;
    wood_chg = scenario_landuse.wood_ha(idx) - baseline_landuse.wood_ha(idx);
    scenario_landuse.wood_mgmt_ha(idx) = baseline_landuse.wood_mgmt_ha(idx) + wood_chg;
    scenario_landuse.p_wood_mgmt(idx) = scenario_landuse.wood_mgmt_ha(idx) ./ scenario_landuse.wood_ha(idx);
    
    % 1.2. Negative wood changes
    %      As woodland overall is reduced, so is managed woodland such that
    %      the proportions do not change compared to the baseline
    % ---------------------------------------------------------------------
    idx = (scenario_landuse.wood_ha - baseline_landuse.wood_ha) < 0;
    scenario_landuse.wood_mgmt_ha(idx) = scenario_landuse.wood_ha(idx) .* baseline_landuse.p_wood_mgmt(idx);
    scenario_landuse.p_wood_mgmt(idx) = scenario_landuse.wood_mgmt_ha(idx) ./ scenario_landuse.wood_ha(idx); 
    
    % 1.3. Function return
    % --------------------
    landuse = scenario_landuse;
end
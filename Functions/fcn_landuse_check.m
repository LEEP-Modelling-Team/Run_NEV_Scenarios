function [check_lcm, check_toplevel, check_crops] = fcn_landuse_check(landuse_table)
    
    %% fcn_landuse_check.m 
    %  ===================
    %
    % Author: Mattia Mancini, Rebecca Collins
    % Created: 31-May-2022
    % Laast modified: 31-May-2022
    % ---------------------------------------
    %
    % DESCRIPTION
    % Script that checks that land uses passed sum to 400 hectares for each
    % new2kid cell. Used in the 'fcn_run_landuse_change.m' script.
    % The check is done for the top level land uses and for the individual
    % crops, aggregated by decade.
    %
    % Output: three arrays, 
    %   - first array: contains a logical value of 1 if the lcm land covers 
    %     for each cell sum to 400, and 0 otherwise
    %   - second array: contains 4 logical values that check whether
    %     farm_ha = arable_ha + grass_ha for each of the 4 decades
    %   - third array: contains 4 logical values that check whether all 
    %     crops sum to farm_ha for each of the 4 decades.
    % =====================================================================
    
    %% (1) Check top level landuses
    %  ============================
    toplevel = {'urban_ha', 'wood_ha', 'farm_ha', 'sngrass_ha', 'water_ha'};
    if sum(round(sum(landuse_table{:, toplevel}, 2),3) == 400) ~= height(landuse_table)
        check_lcm = 0;
    else
        check_lcm = 1;
    end
    
    %% (2) check that arable and grassland sum to farm_ha
    %  ==================================================
    lands = {'arable_ha', 'grass_ha'};
    decades = [20, 30, 40, 50];
    check_toplevel = [];
    for i = 1:length(decades)
        land_col = strcat(lands, '_', string(decades(i)));
        if sum(round(sum(landuse_table{:, land_col}, 2) - landuse_table.farm_ha, 3) ~= 0)
            check_toplevel(i) = 0;
        else
            check_toplevel(i) = 1;
        end
    end
    
    %% (1) Check crops
    %  ===============
    lands = {'wheat_ha', 'osr_ha', 'wbar_ha', 'sbar_ha', 'pot_ha', ... 
             'sb_ha', 'other_ha', 'tgrass_ha', 'pgrass_ha', ...
             'rgraz_ha'};
         
    decades = [20, 30, 40, 50];
    check_crops = [];
    for i = 1:length(decades)
        land_col = strcat(lands, '_', string(decades(i)));
        if sum(round(sum(landuse_table{:, land_col}, 2) - landuse_table.farm_ha, 3) ~= 0)
            check_crops(i) = 0;
        else
            check_crops(i) = 1;
        end
    end
end
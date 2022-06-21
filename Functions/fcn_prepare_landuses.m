function landuses = fcn_prepare_landuses(land_array, model_flags, conn)
    %% FCN_PREPARE_LANDUSES.M
    %  ======================
    %  Author: Mattia Mancini
    %  Created: 29 Mar 2022
    %  Last modified: 31 Mar 2022
    %  --------------------------
    %
    %  DESCRIPTION
    %  This function checks which land uses have been passed and deals with
    %  missing data. For the models to all work the landuse table must
    %  contain at least the following columns (the order does NOT matter):
    %  1) new2kid; 2) urban_ha; 3) sngrass_ha; 4) wood_ha; 5) farm_ha; 
    %  6) water_ha;
    %      
    %  NB: more columns can be passed, to override specific default
    %  landuses:
    %  - wood_mgmt_ha can be passed to override the default values in the
    %    NEV database. The default proportions of coniferous and
    %    deciduous woodland will still be applied, as well as the
    %    proportions for non managed woodland
    %  - it is possible to override the top-level farm model that allocates
    %    land between arable and farm grassland, passing values of grass_ha
    %    (farm grassland) and arable_ha. In this case the farm model will
    %    still allocate arable between the various crop types and grassland
    %    between grassland types. To do this, grass_ha and arable_ha values
    %    must be passed, and the model_flags.run_ag_toplevel must be set to
    %    false. 
    %    !!  AAA  !!: if the top-level farm model is overridden passing 
    %    user-defined values of grassland and arable land, make sure to
    %    appropriately consider the temporal implications! (possibly
    %    setting the parameter num_years to 1 year).
    %  --------------------------------------------------------------------
    %  
    %  - Input: a table containing the following land uses
    %
    % =====================================================================
    
    %% (0) SETUP
    %  =========    
    
    %% (1) READ THE LIST OF LAND USED PREPARE A LAND USE OUTPUT MATRIX
    %      - The land uses passed are exactly those required for a standard
    %        baseline landuse matrix (e.g. farmland will be allocated to
    %        arable-grass by the top level model, manged woodland is the
    %        baseline one, as well as the proportions between tree species.
    %      - More land uses are passed, with the objective to override the
    %        default land-uses. E.g.: in addition to the standard land uses
    %        (urban_ha; sngrass_ha; wood_ha; farm_ha; water_ha;) the user
    %        inputted another column for managed woodland, to override the
    %        defauld one stored in the database). 
    %      - Fewer/inconsistent land uses: throw an error. E.g.: not all
    %        the required landuses passed, or the sum of landuses by cell
    %        not summing to 400ha, or the managed woodland greater than the
    %        total amount of woodland in a cell...
    %  ====================================================================
    
    
    % 1.1. Macro land uses: urban, semi-natural grassland, woodland,
    %      farmland and water hectares
    % --------------------------------------------------------------
    
    % Required variables
    required_vars = {'new2kid', 'urban_ha', 'sng_ha', 'wood_ha', ...
        'farm_ha', 'water_ha'};
    vars_toplevel = {'arable_ha', 'grass_ha'};
    
    
    % variables passed in the land use array
    variable_list = land_array.Properties.VariableNames;
    num_vars = length(variable_list);
    var_missing = setdiff(required_vars, variable_list);
    
    % case 1: all the required land uses have been passed
    if isempty(var_missing)
        % only the 5 top level land uses have been passed: import default
        % values for all other land inputs needed
        if num_vars == 5
            landuses = land_array;
        
        % if more than the 5 top level land uses have been passed, check if
        % the top-level farm model is going to be used or not; if not,
        % check that arable_ha and grass_ha are present to override the
        % top-level farm model
        else
            % Is the top-level farm model to be overridden?
            if model_flags.run_ag_toplevel 
                if all(ismember (vars_toplevel, variable_list))
                    warnText = sprintf(['The top-level model flag ' ...
                        'has been set to run the top level model \n' ...
                        'but values for arable and grassland have ' ...
                        'also been passed. These will be overwritten' ...
                        'by the top level model. \n Please either ' ...
                        'change the run_ag_toplevel flag to false or '...
                        'remove ''arable_ha'', and/or ''grass_ha''']);
                    error(warnText);
                else
                    landuses = land_array;
                end
                % put here the values that need to override the defaults
            else
                % do we have arable_ha and grass_ha to override the top
                % level farm model?
                if all(ismember (vars_toplevel, variable_list))
                    landuses = land_array;
                else
                    warnText = sprintf(['To override the top-level ' ...
                        'farm model, the following land uses are \n' ...
                        'required: ''arable_ha'', and ''grass_ha''.']);
                    error(warnText);
                end
            end
        end
    else
        % do the variables passed allow to construct the missing reqired
        % land uses?
        other_vars = setdiff(variable_list, required_vars);
        
        landuses = land_array;
        warning_vars = {};
        for i = 1:numel(var_missing)
            var = var_missing{i};
            switch var
                case 'farm_ha'
                    % Is the top-level farm model to be overridden?
                    if model_flags.run_ag_toplevel 
                        warnText = sprintf(['The top-level model flag ' ...
                            'has been set to run the top level model \n' ...
                            'but values for arable and grassland have ' ...
                            'also been passed. These will be overwritten' ...
                            'by the top level model. \n Please either ' ...
                            'change the run_ag_toplevel flag to false, or '...
                            'remove ''arable_ha'', and/or ''grass_ha'', or ' ...
                            'pass ''farm_ha''']);
                        error(warnText);
                    else
                        if all(ismember(vars_toplevel, other_vars))
                            landuses.farm_ha = land_array.arable_ha + land_array.grass_ha;
                        else
                            needed = setdiff(vars_toplevel, other_vars);
                            warning_vars = [warning_vars needed];
                        end
                    end
                case 'water_ha'
                    water_vars = {'coast_ha', 'freshwater_ha', 'marine_ha', 'ocean_ha'};
                    if all(ismember (water_vars, other_vars))
                        landuses.water_ha = sum(land_array{:, water_vars}, 2);
                    else
                        warning_vars = [warning_vars 'water_ha'];
                    end
                case 'wood_ha'
                    warning_vars = [warning_vars 'wood_ha'];
                case 'sng_ha'
                    warning_vars = [warning_vars 'sng_ha'];
                case 'urban_ha'
                    warning_vars = [warning_vars 'urban_ha'];
            end
        end
        num_warning_vars = length(warning_vars);
        if num_warning_vars ~= 0
            msg = strcat('The following land uses are missing: \n', ...
                         repmat('-  %s\n', 1, num_warning_vars)); 
            warning_msg = sprintf(msg, warning_vars{:});
            error(warning_msg)
        end
    end
    
    % 1.2. Forestry: managed woodland, and proportions of deciduous and
    %      coniferous woodland.
    % -----------------------------------------------------------------
    required_wood = {'wood_mgmt_ha', 'p_decid_mgmt', 'p_conif_mgmt', 'p_fwood', 'p_decid', 'p_conif'};
    wood_missing = setdiff(required_wood, variable_list);
    if ~isempty(wood_missing)
        sqlquery = ['SELECT ', ...
                        'new2kid, ', ...
                        'wood_ha, ', ...
                        strjoin(wood_missing, ', '), ...
                    ' FROM nevo.nevo_variables ', ...
                    'ORDER BY new2kid'];
        setdbprefs('DataReturnFormat', 'table');
        dataReturn = fetch(exec(conn, sqlquery));
        cell_data = dataReturn.Data;
        
        % calculate proportion of managed vs unmanaged woodland. If no data
        % has been passed for the hectares of managed woodland, we assume
        % that the 2007 proportion is the same as the baseline from all
        % land cover maps. If a scenario land use adds woodland, then the
        % proportions change because the models assume that all new
        % woodland is managed. This change for the scenario is dealt with
        % in the fcn_adjust_woodland function called in fcn_run_scenario.
        if any(strcmp(wood_missing, 'wood_mgmt_ha'))
            % calculate 2007 based proportions of managed woodland out of
            % total woodland
            cell_data.p_wood_mgmt = cell_data.wood_mgmt_ha ./ cell_data.wood_ha;
            cell_data.wood_ha = [];
            cell_data.p_wood_mgmt(isnan(cell_data.p_wood_mgmt)) = 0;
            landuses = outerjoin(landuses, cell_data, 'Type','Left','MergeKeys',true);
            
            % apply 2007 proportions to woodland to compute wood_mgmt_ha
            % (this is different from the hectares obtained from the
            % database, as those only refer to 2007 LCM)
            landuses.wood_mgmt_ha = landuses.p_wood_mgmt .* landuses.wood_ha;
        else
            cell_data.wood_ha = [];
            landuses = outerjoin(landuses, cell_data, 'Type','Left','MergeKeys',true);
            landuses.p_wood_mgmt = landuses.wood_mgmt_ha ./ landuses.wood_ha;
        end
    end
    
    %% (3) CHECKS
    %  ==========
    
    % 3.1. Land uses in each cell must all sum up to 400ha
    % ------------------------------------------------------
    if sum(round(sum(landuses{:, required_vars(2:end)}, 2),2) == 400) ~= height(landuses)
        error('Check inputted landuses: areas do not sum up to 400ha per cell');
    end
    
    % 3.2. Managed woodland must be less or equal wood_ha
    % ---------------------------------------------------
    if sum(round(landuses.wood_ha - landuses.wood_mgmt_ha, 2) < 0) ~= 0
        error('Managed woodland area is greater than total woodland in some of the cells!');
    end
end


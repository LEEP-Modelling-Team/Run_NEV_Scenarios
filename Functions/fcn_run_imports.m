function fcn_run_imports(model_flags, parameters, conn)

   
    %% (1) AGRICULTURAL IMPORT. This needs to be run regardless of the flag
    %  ====================================================================
    NEV_ag_data_mat = strcat(parameters.agriculture_data_folder, 'NEV_ag_',...
    parameters.clim_scen_string, '_', parameters.temp_pct_string, '_',...
    parameters.rain_pct_string, '_data.mat');

    % Does the agricultural data exist?
    if isfile(NEV_ag_data_mat)
        % calculate how old in days the imported file is
        file_date = dir(NEV_ag_data_mat).date;
        current_date = datestr(now, 'dd-mmm-yyyy HH:MM:SS');
        file_age = datenum(current_date) - datenum(file_date);
        if file_age > 30 % older than one month. Modify this if needed
            fprintf('Importing agricultural data from the SQL database\n-------------------------------------------------\n')
            tic
            AgricultureProduction = ImportAgricultureProduction(conn);
            save(NEV_ag_data_mat, 'AgricultureProduction', '-mat', '-v6')
            t = toc;
            fprintf('Data imported in %1.2f seconds\n-----------------------------\n', t)
        end
    else
        tic
        fprintf('Importing agricultural data from the SQL database\n-------------------------------------------------\n')
        AgricultureProduction = ImportAgricultureProduction(conn);
        save(NEV_ag_data_mat, 'AgricultureProduction', '-mat', '-v6')
        t = toc;
        fprintf('Data imported in %1.2f seconds\n-----------------------------\n', t)
    end
    
    %% (2) CLIMATE IMPORT. This needs to be run regardless of the flag
    %  ===============================================================
    NEV_clim_data_mat = strcat(parameters.climate_data_folder, 'NEV_climate_',...
    parameters.clim_scen_string, '_', parameters.temp_pct_string, '_',...
    parameters.rain_pct_string, '_data.mat');

    % Does the climate data exist?
    if isfile(NEV_clim_data_mat)
        % calculate how old in days the imported file is
        file_date = dir(NEV_clim_data_mat).date;
        current_date = datestr(now, 'dd-mmm-yyyy HH:MM:SS');
        file_age = datenum(current_date) - datenum(file_date);
        if file_age > 30 % older than one month. Modify this if needed
            fprintf('Importing climate data from the SQL database\n-------------------------------------------------\n')
            tic
            ClimateData = import_climate(conn, ...
                parameters.clim_scen_string, ...
                parameters.temp_pct_string, ...
                parameters.rain_pct_string);
            save(NEV_clim_data_mat, 'ClimateData', '-mat', '-v6')
            t = toc;
            fprintf('Data imported in %1.2f seconds\n-----------------------------\n', t)
        end
    else
        tic
        fprintf('Importing climate data from the SQL database\n-------------------------------------------------\n')
        ClimateData = import_climate(conn, ...
                parameters.clim_scen_string, ...
                parameters.temp_pct_string, ...
                parameters.rain_pct_string);
        save(NEV_clim_data_mat, 'ClimateData', '-mat', '-v6')
        t = toc;
        fprintf('Data imported in %1.2f seconds\n-----------------------------\n', t)
    end
    
    %% (3) GHG IMPORT. Run this only if flag set to true
    %  =================================================
    if model_flags.run_ghg
       NEV_ghg_data_mat = strcat(parameters.agricultureghg_data_folder, 'NEV_ghg_',...
       parameters.clim_scen_string, '_', parameters.temp_pct_string, '_',...
       parameters.rain_pct_string, '_data.mat');

        % Does the agricultural GHG imported data exist?
        if isfile(NEV_ghg_data_mat)
           % calculate how old in days the imported file is
           file_date = dir(NEV_ghg_data_mat).date;
           current_date = datestr(now, 'dd-mmm-yyyy HH:MM:SS');
           file_age = datenum(current_date) - datenum(file_date);
           if file_age > 30 % older than one month. Modify this if needed
               fprintf('Importing greenhouse gas data from the SQL database\n---------------------------------------------------\n')
               tic
               AgricultureGHG = ImportAgricultureGHG(conn, ...
                   parameters.climate_data_folder, ...
                   parameters.clim_string, ...
                   parameters.clim_scen_string, ...
                   parameters.temp_pct_string, ...
                   parameters.rain_pct_string, ...
                   parameters.start_year, ...
                   parameters.start_year + parameters.num_years - 1);
               save(NEV_ghg_data_mat, 'AgricultureGHG', '-mat', '-v6')
               t = toc;
               fprintf('Data imported in %1.2f seconds\n-----------------------------\n', t)
           end
        else
           tic
           fprintf('Importing greenhouse gas data from the SQL database\n---------------------------------------------------\n')
           AgricultureGHG = ImportAgricultureGHG(conn, ...
                   parameters.climate_data_folder, ...
                   parameters.clim_string, ...
                   parameters.clim_scen_string, ...
                   parameters.temp_pct_string, ...
                   parameters.rain_pct_string, ...
                   parameters.start_year, ...
                   parameters.start_year + parameters.num_years - 1);
           save(NEV_ghg_data_mat, 'AgricultureGHG', '-mat', '-v6')
           t = toc;
           fprintf('Data imported in %1.2f seconds\n-----------------------------\n', t)
        end
    end
    
    %% (4) FORESTRY IMPORT. Run this only if flag set to true
    %      AAA: this includes both forest timber and GHGs from forestry
    %  ================================================================
    if model_flags.run_forestry
        if model_flags.run_ghg
            NEV_ForestTimber_data_mat = strcat(parameters.forest_data_folder, ...
                'NEV_ForestTimber_',...
                parameters.clim_scen_string, '_', ...
                parameters.temp_pct_string, '_', ...
                parameters.rain_pct_string, ...
                '_data.mat');
            NEV_ForestGHG_data_mat = strcat(parameters.forest_data_folder, ...
                'NEV_ForestGHG_',...
                parameters.clim_scen_string, '_', ...
                parameters.temp_pct_string, '_', ...
                parameters.rain_pct_string, ...
                '_data.mat');

            % Does the Forestry data data exist? I do the check only for
            % ForestTimber, and apply whichever result also to ForestGHG
            if isfile(NEV_ForestTimber_data_mat)
               % calculate how old in days the imported file is
               file_date = dir(NEV_ForestTimber_data_mat).date;
               current_date = datestr(now, 'dd-mmm-yyyy HH:MM:SS');
               file_age = datenum(current_date) - datenum(file_date);
               if file_age > 30 % older than one month. Modify this if needed
                   fprintf('Importing forestry data from the SQL database\n---------------------------------------------------\n')
                   tic
                   [ForestTimber, es_forestry] = ImportForestTimber(conn, ...
                       parameters.climate_data_folder, ...
                       parameters.clim_string, ...
                       parameters.clim_scen_string, ...
                       parameters.temp_pct_string, ...
                       parameters.rain_pct_string, ...
                       parameters.start_year, ...
                       parameters.num_years);

                   ForestGHG = ImportForestGHG(conn, ForestTimber, es_forestry);

                   save(NEV_ForestTimber_data_mat, 'ForestTimber', 'es_forestry', '-mat', '-v6')
                   save(NEV_ForestGHG_data_mat, 'ForestGHG', '-mat', '-v6')
                   t = toc;
                   fprintf('Data imported in %1.2f seconds\n-----------------------------\n', t)
               end
            else
               tic
               fprintf('Importing forestry data from the SQL database\n---------------------------------------------------\n')
               [ForestTimber, es_forestry] = ImportForestTimber(conn, ...
                   parameters.climate_data_folder, ...
                   parameters.clim_string, ...
                   parameters.clim_scen_string, ...
                   parameters.temp_pct_string, ...
                   parameters.rain_pct_string, ...
                   parameters.start_year, ...
                   parameters.num_years);

               ForestGHG = ImportForestGHG(conn, ForestTimber, es_forestry);

               save(NEV_ForestTimber_data_mat, 'ForestTimber', 'es_forestry', '-mat', '-v6')
               save(NEV_ForestGHG_data_mat, 'ForestGHG', '-mat', '-v6')
               t = toc;
               fprintf('Data imported in %1.2f seconds\n-----------------------------\n', t)
            end
        end
    end
    
    %% (5) BIODIVERSITY IMPORT. Run this only if flag set to true
    %      AAA: this includes both UCL and JNCC models
    %  ==========================================================
    if model_flags.run_biodiversity
        Bio_JNCC_data_mat = strcat(parameters.biodiversity_data_folder_jncc, ...
            'NEV_biodiversity_JNCC_data.mat');
        if isfile(Bio_JNCC_data_mat)
            % calculate how old in days the imported file is
            file_date = dir(Bio_JNCC_data_mat).date;
            current_date = datestr(now, 'dd-mmm-yyyy HH:MM:SS');
            file_age = datenum(current_date) - datenum(file_date);
            if file_age > 30 % older than one month. Modify this if needed
                fprintf('Importing biodiversity data \n---------------------------\n')
                tic
                Biodiversity = ImportBiodiversityJNCC(conn, parameters);
                save(Bio_JNCC_data_mat, 'Biodiversity', '-mat', '-v6')
                t = toc;
                fprintf('Data imported in %1.2f seconds\n-----------------------------\n', t)
            end
        else
            tic
            fprintf('Importing biodiversity data \n---------------------------\n')
            Biodiversity = ImportBiodiversityJNCC(conn, parameters);
            save(Bio_JNCC_data_mat, 'Biodiversity', '-mat', '-v6')
            t = toc;
            fprintf('Data imported in %1.2f seconds\n-----------------------------\n', t)
        end
    end
end
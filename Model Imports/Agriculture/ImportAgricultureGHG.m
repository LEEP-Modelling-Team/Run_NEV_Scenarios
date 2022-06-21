function AgricultureGHG = ImportAgricultureGHG(conn,...
                                               climate_data_folder,...
                                               clim_string,...
                                               clim_scen_string,...
                                               pct_temp,...
                                               pct_rain,...
                                               year_start,...
                                               year_end)
    % ImportAgricultureGHG
    % ====================
    % Authors: Brett Day, Nathan Owen
    % Last modified: 16/12/2020 by Mattia Mancini
    % Imports soil and temperature data and runs the Cool Farm Tool code 
    % written by Sylvia Vetter (University of Aberdeen) and AJ De-Gol 
    % (University of East Anglia).
    % Inputs:
    % - conn: a database connection
    % - climate_data_folder: a folder containing a limate data structure.
    %   This is created running the 'ImportStandardClimate' function
    %   called by the script 'ImportAgriculture', which loads all the
    %   import functions to run the agricultural model.
    % - Optional arguments: (if not declared, standard values are used)
    %       1) clim_string: a string to identify whether we
    %          'ukcp09' or 'ukcp18' are used. Default: 'ukcp18'
    %       2) clim_scen_string: a string to identify what rcp is used.
    %          Possible choices are 'rcp26', 'rcp45', 'rcp60', rcp84',
    %          'a1b'. The latter only applies to the 'ukcp09' climate.
    %          Default value: 'rcp60'
    %       3) pct_temp: the selected temperature percentile. Default: 50.
    %          Other options: 1, 5, 10, 25, 50, 75, 90, 95, 99 
    %       4) pct_rain: the selected precip percentile. Default: 50.
    %          Other options: 1, 5, 10, 25, 50, 75, 90, 95, 99 
    % Outputs:
    % - AgricultureGHG: a structure containing the following fields:
    %   EmissionsGridPerHa [ncells x 7 table]: 
    %   - Per hectare emissions from grid cells (machinery, land use and 
    %     soils). Divided into 7 agricultural land uses: oil seed rape, 
    %     cereals, root crops, temporary grass, permanent grass, rough 
    %     grazing and other.
    %
    %   EmissionsLivestockPerHead [ncells x 3 x 40 array]:
    %   - Per head emissions from livestock in grid cells over a 40 year
    %     simulation period (2020-2059). Divided into 3 livestock types: 
    %     dairy, beef and sheep.
    %
    % These will be multiplied by hectares of crops and grassland, and 
    % heads of livestock, in the main function for the agriculture model,
    % fcn_run_agriculture.m

    %% (1) Load data from database
    %  ===========================
    % (a) Cell-specific soil data
    % ---------------------------
    % Soil Organic Matter (SOM) class, % of coarse/medium/fine, % of 5 soil PH
    % categories
    sqlquery = ['SELECT ', ...
                    'new2kid, ', ...
                    'som_class, ', ...
                    'pca_coarse, ', ...
                    'pca_med, ', ...
                    'pca_fine, ', ...
                    'pca_ph1, ', ...
                    'pca_ph2, ', ...
                    'pca_ph3, ', ...
                    'pca_ph4, ', ...
                    'pca_ph5 ', ...
                'FROM nevo.nevo_variables ORDER BY new2kid'];
    setdbprefs('DataReturnFormat','table');
    dataReturn  = fetch(exec(conn,sqlquery));
    soil_cells = dataReturn.Data;

    % Save 2km cell id's into AgricultureGHG structure and define number of
    % cells
    AgricultureGHG.new2kid = soil_cells.new2kid;
    ncells = length(AgricultureGHG.new2kid);

    % (b) Cool Farm Tool livestock temperature factor
    % -----------------------------------------------
    sqlquery = 'SELECT * FROM nevo.ag_cft_tempfactor';
    setdbprefs('DataReturnFormat','numeric');
    dataReturn  = fetch(exec(conn,sqlquery));
    ls_temp_factor = dataReturn.Data;

    % (c) Temperature in growing season (for livestock emissions)
    % -----------------------------------------------------------
    
    % Assign standard definition for the parameter related to climate when
    % they are not defined as optional arguments of the function
    if ~exist('clim_string', 'var') || isempty('clim_string')
        clim_string = 'ukcp18';
    end
    if ~exist('clim_scen_string', 'var') || isempty('clim_scen_string')
        clim_scen_string = 'rcp60';
    end
    if ~exist('pct_temp', 'var') || isempty('pct_temp')
        pct_temp = 50;
    end
    if ~exist('pct_rain', 'var') || isempty('pct_rain')
        pct_rain = 50;
    end
    
    % load the climate data 
    NEV_clim_data_mat = strcat(climate_data_folder, 'NEV_climate_',...
    clim_scen_string, '_', pct_temp, '_',...
    pct_rain, '_data.mat');
    load(NEV_clim_data_mat, 'ClimateData');
    ClimateData = ClimateData.grow_restrict;
    
    % Check that the climate data loaded matches the climate pathway
    % selected in the GHG calculation function (this should be true any
    % time that the optional climate arguments are not declared). 
    temp_pathway = strcat('Climate_cells_', clim_string, '_', clim_scen_string, '_temp_', num2str(pct_temp));
    rain_pathway = strcat('Climate_cells_', clim_string, '_', clim_scen_string, '_rain_', num2str(pct_rain));
    if isfield(ClimateData, temp_pathway) ~= 1 || isfield(ClimateData, rain_pathway) ~= 1
        error('foo:bar', 'The climate data loaded and the climate data declared in the GHG function do not match.\nMake sure you are using the same climate scenarios in the climate and GHG import modules!')
    end
        
    % Extract temperature and rainfall for this scenario and combine
    temp = ClimateData.(['Climate_cells_', clim_string, '_', clim_scen_string, '_temp_', num2str(pct_temp)]);
    rain = ClimateData.(['Climate_cells_', clim_string, '_', clim_scen_string, '_rain_', num2str(pct_rain)]);
    
    temp = temp(:, fcn_select_years('temp', year_start:year_end));
    rain = rain(:, fcn_select_years('rain', year_start:year_end));
    climate = [temp, rain];


    %% (2) Calculate soil property variables
    %  =====================================
    % From the variables imported in step (1), additional variables need to
    % be derived for the Cool Farm Tool

    % (a) Soil Texture
    % ----------------
    % A categorial variable defined as 1, 2 or 3 depending on whether the 
    % soil is predominately coarse, medium or fine quality.
    [~, soil_cells.soil_texture] = max([soil_cells.pca_coarse soil_cells.pca_med soil_cells.pca_fine], [], 2);

    % (b) Soil Drainage
    % -----------------
    % A categorical variable defined as 2 for all cells, except for those 
    % cells where Soil Texture = 3, where it is defined as 1.
    soil_cells.soil_drainage = 2*ones(ncells, 1);
    soil_cells.soil_drainage(soil_cells.soil_texture == 3) = 1;

    % (c) Soil PH
    % ---=-------
    % A categorical variable defined as 1 if the soil is predominately ph1
    % or ph2, and 2, 3 or 4 is the soil is predominately ph3, ph4 or ph5
    % respectively.
    [~, ph_category] = max([soil_cells.pca_ph1, soil_cells.pca_ph2, soil_cells.pca_ph3, soil_cells.pca_ph4, soil_cells.pca_ph5], [], 2);
    soil_cells.soil_ph = zeros(ncells, 1);
    soil_cells.soil_ph(ph_category < 3) = 1;
    soil_cells.soil_ph(ph_category > 2) = ph_category(ph_category > 2) - 1;
    
    % (d) Soil Moisture
    % -----------------
    % A categorical variable defined as 1 for all cells (UK soils always 
    % moist)
    soil_cells.soil_moisture = ones(ncells, 1);

    %% (3) Calculate total grid emissions per hectare
    %  ==============================================
    % This is made up of emissions from machinery, land use type, and grid
    
    % Define order of land use types
    order_landuse = {'osrape' 'cer' 'root' 'tgrass' 'pgrass' 'rgraz'}; 

    % (a) Land-type-specific machinery emissions (constant)
    % -----------------------------------------------------
    emissions_machinery = CalcCFTMachEm(order_landuse); 

    % (b) Land-type-specific emissions (constant)
    % -------------------------------------------
    emissions_landuse = CalcCFTLandTypeEm(order_landuse);

    % (c) Cell-specific emissions
    % ---------------------------
    emissions_grid = CalcCFTGridEm(order_landuse, [soil_cells.soil_texture, soil_cells.som_class, soil_cells.soil_ph, soil_cells.soil_drainage, soil_cells.soil_moisture]); 
    
    % (d) Combine to create total emissions
    % -------------------------------------
    % Total grid emissions = machinery + land use + grid
    % Note: need to repeat machinery and landuse emissions for ncells
    emissions_total_grid = repmat(emissions_machinery + emissions_landuse, [ncells 1]) + emissions_grid;

    % Convert total grid emissions to table with column names for land uses
    emissions_total_grid = array2table(emissions_total_grid, 'VariableNames', order_landuse);

    % (e) Create 'other' land use category
    % ------------------------------------
    coef_other = [0.05, 0.15, 0.25, 0.05, 0.05, 0.05];
    emissions_total_grid.other = table2array(emissions_total_grid) * coef_other';

    % (f) Save total grid emissions into AgricultureGHG structure
    % -----------------------------------------------------------
    AgricultureGHG.EmissionsGridPerHa = emissions_total_grid;

    %% (4) Calculate total livestock emissions per head
    %  ================================================
    % Livestock emissions per head are assumed to change over time with
    % temperature increase

    % Define order of livestock types
    order_livestock = {'DAIRY' 'BEEF' 'SHEEP'};

    % Define the sequence of years in the simulation (2020-2059)
    if ~exist("year_start", "var") || ~exist("year_end", "var")
        year_start = 2020;
        year_end = 2059;
    end
    year_seq = year_start:year_end;
    num_years = length(year_seq);

    % Emissions from 3 livestock types (dairy, beef, sheep) to be stored in an
    % array of size ncells x 3 x num_years
    emissions_livestock = zeros(ncells, 3, num_years);

    % Loop over the years in the simulation
    % Predict emissions per head from livestock as a function of temperature in
    % that year
    for n = 1:num_years
        % Extract temperature in current year from climate table
        current_year_temp = eval(['climate.temp', num2str(year_seq(n))]);
        % Predict emissions per head of 3 livestock types in current year
        emissions_livestock(:, :, n) = CalcCFTLSEm(current_year_temp, order_livestock, ls_temp_factor);
    end

    % Save livestock emissions into AgricultureGHG structure
    % Change order of 2nd and 3rd dimensions for ease of use in fcn_agriculture
    emissions_livestock = permute(emissions_livestock, [1, 3, 2]);
    AgricultureGHG.EmissionsLivestockPerHead.dairy = emissions_livestock(:, :, 1);
    AgricultureGHG.EmissionsLivestockPerHead.beef = emissions_livestock(:, :, 2);
    AgricultureGHG.EmissionsLivestockPerHead.sheep = emissions_livestock(:, :, 3);
end

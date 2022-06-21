function es_biodiversity_jncc = fcn_run_biodiversity_jncc(biodiversity_data_folder, landuses, climate_scen_string, other_ha_string)
    % fcn_run_biodiversity_jncc.m
    % ===========================
    % Author: Nathan Owen
    % Last modified: 21/02/2020
    % Function to run the JNCC biodiversity model emulators (100 priority 
    % species) for current climate and future climate scenarios.
    % Inputs:
    % - biodiversity_data_folder: path to the .mat file containing the data
    %   for the model. The .mat file is generated in ImportBiodiversityJNCC.m
    %   and for me it is saved in the path C:/Data/Biodiversity/JNCC/
    % - landuses: a structure or table containing land uses (in hectares) 
    %   for a set of 2km grid cells. Must have a new2kid column/field with 
    %   2km grid IDs. See fcn_create_model_matrix_jncc.m for required land 
    %   uses and how they are used.
    % - climate_scen_string: a string to specify which climate scenario
    %   should be used when making predictions. Can be one of: 'current' or
    %   'future'.
    % - other_ha_string: a string to specify how the other_ha category from
    %   NEV agriculture model should be split into individual crop/farm
    %   categories. Options are: 'baseline' (split using baseline 
    %   proportions), 'maize' (100% maize), 'hort', 'othcer', 'othfrm', ...
    %   'othcrps'.
    % Outputs:
    % - es_biodiversity_jncc: a structure containing multiple fields.
    %   Firstly, the probability of occurrence of all 100 priority species
    %   in each 2km grid cell (species_prob). Secondly, the presence (1) or
    %   absence (0) of all 100 priority species in each 2km grid cell
    %   (species_pres). Lastly, vectors of the species richness of all 100
    %   priority species in each 2km grid cell, i.e. the sum of the
    %   presence table across species (sr_100), and the species richness in
    %   various taxonomic groups (sr_bird, sr_herp, sr_invert, sr_lichen, 
    %   sr_mammal, sr_plant, sr_noplant).
    
    %% (1) Set up
    %  ==========
    % (a) Data files 
    % --------------
    NEV_Biodiversity_data_mat = strcat(biodiversity_data_folder, 'NEV_Biodiversity_JNCC_data.mat');
    load(NEV_Biodiversity_data_mat, 'Biodiversity');
    
    % (b) Choose climate scenario and set up decade info
    % --------------------------------------------------
    switch climate_scen_string
        case 'current'
            ndecades = 1;
            decade_string = {''};
            climate_cells  = Biodiversity.Climate_cells_now;
        case 'future'
            ndecades = 4;
            decade_string = {'_20','_30','_40','_50'};
            climate_cells = Biodiversity.Climate_cells_future;
        otherwise
            error('Please choose a climate scenario from ''current'' or ''future''.')
    end
    
    % (c) Save species numbers for taxonomic groups
    % ---------------------------------------------
    % Note: in NEVO these are needed outside this function 
    % (fcn_aggregate_to_region) so saved to es_biodiversity_jncc structure
    es_biodiversity_jncc.species_nos.all = 1:100;
    es_biodiversity_jncc.species_nos.bird = [1, 3, 8, 16, 19, 33, 34, 56, 58, 64, 66, 70, 76, 77, 89, 94, 97];
    es_biodiversity_jncc.species_nos.herp = 98;
    es_biodiversity_jncc.species_nos.invert = [2, 4, 14, 15, 24, 26, 27, 28, 29, 30, 32, 35, 37, 43, 45, 48, 50, 54, 55, 57, 61, 63, 85, 99, 100];
    es_biodiversity_jncc.species_nos.lichen = [5, 49, 75, 79, 95];
    es_biodiversity_jncc.species_nos.mammal = [12, 38, 51, 52, 60, 62, 65, 67, 68, 71, 78, 83, 84, 87];
    es_biodiversity_jncc.species_nos.plant = [6, 7, 9, 10, 11, 13, 17, 18, 20, 21, 22, 23, 25, 31, 36, 39, 40, 41, 42, 44, 46, 47, 53, 59, 69, 72, 73, 74, 80, 81, 82, 86, 88, 90, 91, 92, 93, 96];
    es_biodiversity_jncc.species_nos.noplant = setdiff(es_biodiversity_jncc.species_nos.all, es_biodiversity_jncc.species_nos.plant);
    
    % (d) Treatment of other_ha category
    % ----------------------------------
    % Decide how other_ha is split up into subcategories
    switch other_ha_string
        case 'baseline'
            % Split up into subcategories based on baseline proportions
            % (no action taken - info contained in Biodiversity structure)
        case 'maize'
            % Convert all other_ha to maize
            ncells_all = length(Biodiversity.Data_cells.p_maize);
            Biodiversity.Data_cells.p_maize = ones(ncells_all, 1);
            Biodiversity.Data_cells.p_hort = zeros(ncells_all, 1);
            Biodiversity.Data_cells.p_othcer = zeros(ncells_all, 1);
            Biodiversity.Data_cells.p_othfrm = zeros(ncells_all, 1);
            Biodiversity.Data_cells.p_othcrps = zeros(ncells_all, 1);
        case 'hort'
            % Convert all other_ha to hort
            ncells_all = length(Biodiversity.Data_cells.p_maize);
            Biodiversity.Data_cells.p_maize = zeros(ncells_all, 1);
            Biodiversity.Data_cells.p_hort = ones(ncells_all, 1);
            Biodiversity.Data_cells.p_othcer = zeros(ncells_all, 1);
            Biodiversity.Data_cells.p_othfrm = zeros(ncells_all, 1);
            Biodiversity.Data_cells.p_othcrps = zeros(ncells_all, 1);
        case 'othcer'
            % Convert all other_ha to othcer
            ncells_all = length(Biodiversity.Data_cells.p_maize);
            Biodiversity.Data_cells.p_maize = zeros(ncells_all, 1);
            Biodiversity.Data_cells.p_hort = zeros(ncells_all, 1);
            Biodiversity.Data_cells.p_othcer = ones(ncells_all, 1);
            Biodiversity.Data_cells.p_othfrm = zeros(ncells_all, 1);
            Biodiversity.Data_cells.p_othcrps = zeros(ncells_all, 1);
        case 'othfrm'
            % Convert all other_ha to othfrm
            ncells_all = length(Biodiversity.Data_cells.p_maize);
            Biodiversity.Data_cells.p_maize = zeros(ncells_all, 1);
            Biodiversity.Data_cells.p_hort = zeros(ncells_all, 1);
            Biodiversity.Data_cells.p_othcer = zeros(ncells_all, 1);
            Biodiversity.Data_cells.p_othfrm = ones(ncells_all, 1);
            Biodiversity.Data_cells.p_othcrps = zeros(ncells_all, 1);
        case 'othcrps'
            % Convert all other_ha to othcrps
            ncells_all = length(Biodiversity.Data_cells.p_maize);
            Biodiversity.Data_cells.p_maize = zeros(ncells_all, 1);
            Biodiversity.Data_cells.p_hort = zeros(ncells_all, 1);
            Biodiversity.Data_cells.p_othcer = zeros(ncells_all, 1);
            Biodiversity.Data_cells.p_othfrm = zeros(ncells_all, 1);
            Biodiversity.Data_cells.p_othcrps = ones(ncells_all, 1);
        otherwise
            error('other_ha_string must be one of: ''baseline'', ''maize'', ''hort'', ''othcer'', ''othfrm'', ''othcrps''');
    end

    %% (2) Reduce to inputted 2km cells
    %  ================================
    % For inputted 2km grid cells, extract rows of relevant tables and
    % arrays in Biodiversity structure
    [input_cells_ind, input_cell_idx] = ismember(landuses.new2kid, Biodiversity.new2kid);
    input_cell_idx = input_cell_idx(input_cells_ind);
    
    % Data cells
    data_cells = Biodiversity.Data_cells(input_cell_idx, :);
    
    % Climate data
    climate_cells = climate_cells(input_cell_idx, :);
    
    %% (3) Calculate biodiversity output
    %  =================================
    for decade = 1:ndecades
        % (a) Create model matrix for this decade
        % ---------------------------------------
        model_matrix = fcn_create_model_matrix_jncc(data_cells, climate_cells, landuses, decade_string{decade});
        
        % (b) Model prediction
        % --------------------
        % Multiply model matrix by coefficients to get logit of probability
        % of occurrence for the 100 species
        species_prob_logit = model_matrix * Biodiversity.Coefficients;
        
        % Apply logistic transformation to get probability of occurrence
        % for the 100 species
        species_prob = 1 ./ (1 + exp(-species_prob_logit));
        
        % Add to output structure as species_prob with decade
        es_biodiversity_jncc.(['species_prob', decade_string{decade}]) = species_prob;
        
        % (c) Convert probability to species presence/absence
        % ---------------------------------------------------
        % Note: use algorithm suggested by Henry Ferguson-Gow (UCL)
        % Calculate total number of species in each cell
        total_species_richness = round(sum(species_prob, 2));
        
        % Preallocate matrix to store results
        species_presence = zeros(size(species_prob));
        
        % Loop over cells
        for i = 1:size(species_prob, 1)
            if (isnan(total_species_richness(i)))
                % If NaN then skip this cell
                continue
            else
                % Else, set top total_species_richness(i) species to 1 and
                % 0 otherwise in this cell
                [~, ind] = maxk(species_prob(i,:), total_species_richness(i));
                species_presence(i, ind) = 1;
            end
        end
        
        % Fill in NaNs
        species_presence(isnan(species_prob)) = NaN;
        
        % Add to output structure as 'species_presence' with decade
        es_biodiversity_jncc.(['species_presence', decade_string{decade}]) = species_presence;
        
        % (d) Calculate metrics for taxonomic groups
        % ------------------------------------------
        % (birds, herptiles, invertebrates, lichen, mammals, vascular plants, all 100)
        % Species richness: number of species present in different taxonomic groups
        sr_bird = sum(species_presence(:, es_biodiversity_jncc.species_nos.bird), 2);
        sr_herp = sum(species_presence(:, es_biodiversity_jncc.species_nos.herp), 2);
        sr_invert = sum(species_presence(:, es_biodiversity_jncc.species_nos.invert), 2);
        sr_lichen = sum(species_presence(:, es_biodiversity_jncc.species_nos.lichen), 2);
        sr_mammal = sum(species_presence(:, es_biodiversity_jncc.species_nos.mammal), 2);
        sr_plant = sum(species_presence(:, es_biodiversity_jncc.species_nos.plant), 2);
        sr_100 = sum(species_presence(:, es_biodiversity_jncc.species_nos.all), 2);
        sr_noplant = sum(species_presence(:, es_biodiversity_jncc.species_nos.noplant), 2);
        
        % Add to output structure as 'sr_taxa' with decade
        es_biodiversity_jncc.(['sr_bird', decade_string{decade}]) = sr_bird;
        es_biodiversity_jncc.(['sr_herp', decade_string{decade}]) = sr_herp;
        es_biodiversity_jncc.(['sr_invert', decade_string{decade}]) = sr_invert;
        es_biodiversity_jncc.(['sr_lichen', decade_string{decade}]) = sr_lichen;
        es_biodiversity_jncc.(['sr_mammal', decade_string{decade}]) = sr_mammal;
        es_biodiversity_jncc.(['sr_plant', decade_string{decade}]) = sr_plant;
        es_biodiversity_jncc.(['sr_100', decade_string{decade}]) = sr_100;
        es_biodiversity_jncc.(['sr_noplant', decade_string{decade}]) = sr_noplant;
    end
end


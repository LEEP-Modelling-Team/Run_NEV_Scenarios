function current_land_cover = fcn_create_jncc_lc(land_cover, es_agriculture, climate_scen_string)
    %% fcn_create_jncc_lc
    % ===================
    % Author: Mattia Mancini, Rebecca Collins
    % Date: 04-May-2022
    % Last modified: 04-May-2022
    % ---------------------------------------
    %
    % DESCRIPTION
    % This function creates a land use matrix containing all of the land
    % categories required to run the JNCC biodiversity model. These are
    % three macro land uses (woodland, urban, seminatural grassland, they
    % can come from any of the CEH land cover maps, or can be user-defined
    % for scenario analysis (e.g. urban expansion), as well as arable and
    % grassland split into the different types predicted by a run of the
    % agricultural model. This function is called in the script
    % 'fcn_run_scenario.m'. There are checks in that script that guarantee
    % that the land uses passed all sum to 400ha. If used elsewhere, such
    % checks need to be enforced!
    %
    % Inputs:
    % 1) land_cover: a matrix containing at least the following categories:
    %    cell new2kid, wood_ha, urban_ha and sng_ha (hectares of woodland,
    %    urban land and seminatural grassland respectively)
    % 2) es_agriculture: the structure obtained running the agricultural
    %    model. 
    % 3) climate_scen_string: a string that identifies whether the
    %    biodiversity model needs to compute current biodiversity outputs
    %    or predictions into the future. It can take the following values:
    %    'current' or 'future'.
    %    AAA: the climate change used in the JNCC biodiversity model is not 
    %    from the UKCP18 climate scenarios, but from the older SRES (A1B). 
    % =====================================================================
    switch climate_scen_string
        case 'current'
            % Get current landuses from land cover map/scenarios and ag model run           
            landuses_non_ag = land_cover(:, {'new2kid', 'wood_ha', 'urban_ha', 'sng_ha'});
            landuses_ag = array2table([es_agriculture.pgrass_ha(:, 1), es_agriculture.tgrass_ha(:, 1), ...
                es_agriculture.rgraz_ha(:, 1), es_agriculture.wheat_ha(:, 1), ... 
                es_agriculture.wbar_ha(:, 1), es_agriculture.sbar_ha(:, 1), ...
                es_agriculture.pot_ha(:, 1), es_agriculture.sb_ha(:, 1), ...
                es_agriculture.osr_ha(:, 1), es_agriculture.other_ha(:, 1)]);
            landuses_ag.Properties.VariableNames = {'pgrass_ha', 'tgrass_ha', ...
                'rgraz_ha', 'wheat_ha', 'wbar_ha', 'sbar_ha', 'pot_ha', ...
                'sb_ha', 'osr_ha', 'other_ha'};
            current_land_cover = [landuses_non_ag landuses_ag];
        case 'future'
            % Get future landuses from land cover map/scenarios and ag model run             
            landuses_non_ag = land_cover(:, {'new2kid', 'wood_ha', 'urban_ha', 'sng_ha'});

            year_intervals = {'1:10', '11:20', '21:30', '31:40'};
            decade = {'20', '30', '40', '50'};
            variable_list = {'pgrass', 'tgrass', 'rgraz', 'wheat', 'wbar',...
                'sbar', 'pot', 'sb', 'osr', 'other'};

            landuses_ag = [];
            variablenames = [];
            for i = 1:length(variable_list)
                for j =1:length(year_intervals)
                    lc = eval(char(strcat('mean(es_agriculture.', ...
                        variable_list(i), '_ha(:, ', year_intervals(j), ...
                        '), 2)')));
                    landuses_ag = horzcat(landuses_ag, lc);
                    variablenames = horzcat(variablenames, strcat(variable_list(i), ...
                        '_ha_', decade(j)));
                end
            end
            landuses_ag = array2table(landuses_ag);
            landuses_ag.Properties.VariableNames = variablenames;
            current_land_cover = [landuses_non_ag landuses_ag];
        otherwise
            error('Please choose a climate scenario from ''current'', ''future''.')
    end
end
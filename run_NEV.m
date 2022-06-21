%% run_NEV.m
%  =========
% Author: Mattia Mancini, Rebecca Collins
% Created: 25 Feb 2022
% Last modified: 14 Jun 2022
% ---------------------------------------
% DESCRIPTION
% Script to run the NEV tool for scenario analysis of changes in ecosystem
% services as a result to changes in land use. 
% It requires a baseline land use and a land use that differs from the
% baseline in order to compute changes in ecosystem services. For the NERC
% Agile-Sprint the baseline is the land uses from the 2020 land cover map
% for the BBOWT - NEP area along the Oxford-Cambridge corridor. This has
% been produced in the script 'calc_baseline_landuses.R'. Scenarios need to
% be passed as land uses in the same format as the baseline landuse.
%
% INPUTS
%   1) Model parameters
%   2) flags
%   3) Land uses
%      For the models to all work the landuse table must
%      contain the following columns (the order does NOT matter):
%      1) new2kid; 2) urban_ha; 3) sngrass_ha; 4) wood_ha; 5) farm_ha; 
%      6) water_ha. As farm is the sum of arable_ha and grass_ha, if those
%      are passed, farm_ha is no longer required. The same applies for
%      water_ha, i.e. the sum of freshwater_ha, marine_ha, coast_ha and
%      ocean_ha.
%      NB: more columns can be passed, to override specific default
%      landuses:
%      - wood_mgmt_ha can be passed to override the default values in the
%        NEV database. The default proportions of coniferous and
%        deciduous woodland will still be applied, as well as the
%        proportions for non managed woodland. 
%         -------   AAA   ------ 
%        if new woodland is created in a scenario, this must be managed for 
%        the correct calculation of GHGs. If wood_mgmt_ha is passed in the 
%        scenario land use, but new woodland from baseline in the scenario 
%        is more than the woodland in wood_mgmt_ha (i.e. 
%        wood_mgmt_ha(scenario) < (wood_ha(scenario) - wood_ha(baseline))
%        then the script will overwrtie the wood_mgmt_ha passed and replace 
%        it with the hectares of new woodland (i.e. wood_mgmt_ha(scenario) 
%        = (wood_ha(scenario) - wood_ha(baseline))
%      - it is possible to override the top-level farm model that allocates
%        land between arable and farm grassland, passing values of grass_ha
%        (farm grassland) and arable_ha. In this case the farm model will
%        still allocate arable between the various crop types and grassland
%        between grassland types. To do this, grass_ha and arable_ha values
%        must be passed, and the model_flags.run_ag_toplevel must be set to
%        false. 
%
%        !!!!!!!!!  AAA  !!!!!!!!
%        scenario land uses assume that the land use change
%        passed happens in YEAR 1 !!!!!!!
% =========================================================================

%% (0) Set up
%      (a) model parameters and selection of modules to run
%  ========================================================
clear

% 1.1. model parameters related to land uses and farm model
% ---------------------------------------------------------
parameters = fcn_set_parameters();
parameters.num_years                   = 40;
parameters.start_year                  = 2020;
parameters.clim_string                 = 'ukcp18';
parameters.clim_scen_string            = 'rcp60';
parameters.temp_pct_string             = '50';
parameters.rain_pct_string             = '50';
parameters.biodiversity_climate_string = 'future';
parameters.other_ha                    = 'baseline'; 
parameters.landuse_change_timeframe    = 50; % land use change remains for these numbers of years

% 1.2. Model parameters for valuation
% -----------------------------------
parameters.assumption_flooding = 'low';
parameters.assumption_nonuse = 0.38; % this could be 0.38, 0.75, 1 
parameters.assumption_pop = 'low';

% 1.3. Land use changes allowed
% -----------------------------
parameters.options = {'arable2sng', 'arable2wood', 'arable2urban', 'arable2mixed', ...
                      'grass2sng', 'grass2wood', 'grass2urban', 'grass2mixed', ...
                      'sng2urban', 'wood2urban'};


% 1.3. Flags to select which models to run
% ----------------------------------------
model_flags.run_ag_toplevel   = true;
model_flags.run_ghg           = true;
model_flags.run_forestry      = true;
model_flags.run_biodiversity  = true;
model_flags.run_hydrology     = true;
model_flags.run_recreation    = true;



%% (2) LOAD LAND USES
%      2.1 - Load baseline land use data
%      2.2 - Run the scenario land use data
%  ========================================

% 2.1. Load baseline land uses. This is either a land cover map from CEH,
%      or a modification of one of the CEH LCMs. When passing a land cover
%      table, we also need to specify which CEH LCM it originates from in
%      order to correclty calculate baselines for each of the NEV modules.
% ------------------------------------------------------------------------
base_ceh_lcm = '2020';
baseline_lu = readtable('nep_baseline_lu.csv');
parameters.base_ceh_lcm = base_ceh_lcm;

baseline_lu.farm_ha = baseline_lu.arable_ha + baseline_lu.grass_ha;
baseline_lu.arable_ha = [];
baseline_lu.grass_ha = [];


% server_flag = false;
% conn = fcn_connect_database(server_flag);
% sqlquery = ['SELECT ', ...
%                     'new2kid, ', ...
%                     'farm_ha, ', ...
%                     'water_ha, ', ...
%                     'urban_ha, ', ...
%                     'sngrass_ha, ', ...
%                     'wood_ha ,', ...
%                     'wood_mgmt_ha ' ...
%                 'FROM nevo.nevo_variables ORDER BY new2kid'];
% setdbprefs('DataReturnFormat','table');
% dataReturn  = fetch(exec(conn,sqlquery));
% baseline_lu = dataReturn.Data;
% baseline_lu.Properties.VariableNames{5} = 'sng_ha';


% 2.2. Load scenario land use
% ---------------------------
scenario_lu = readtable('nep_baseline_lu.csv');
scenario_lu.wood_ha = scenario_lu.wood_ha + scenario_lu.arable_ha + scenario_lu.grass_ha;
scenario_lu.arable_ha = zeros(height(scenario_lu), 1);
scenario_lu.grass_ha = zeros(height(scenario_lu), 1);

scenario_lu.farm_ha = scenario_lu.arable_ha + scenario_lu.grass_ha;
scenario_lu.arable_ha = [];
scenario_lu.grass_ha = [];


%% (3) RUN THE MODELS
%  ==================
[benefits, costs, env_outs, es_outs] = fcn_run_scenario(model_flags, ...
                            parameters, ...
                            baseline_lu, ... 
                            scenario_lu);




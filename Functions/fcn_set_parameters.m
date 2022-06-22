function parameters = fcn_set_parameters()

% FCN_SET_PARAMETERS
% Set baseline parameters in NEV
% Author: Frankie Cho
% Last modified: 18/10/2021
%
% Paths and baseline parameter values modified here will be modified 
% globally across all functions
%
% EXAMPLE:
% % Load baseline parameters, then set num_years to 30
% parameters = fcn_set_parameters();
% parameters.num_years = 30;

% Data paths
% ----------
parent_dir                        = 'D:\Documents\NEV\Model Data\';
parameters.lcm_data_folder        = 'D:\Documents\GitHub\NERC--Agile-Sprint\Data\LCM\LCM_2km\';

parameters.agriculture_data_folder          = [parent_dir, 'Agriculture\'];
parameters.agricultureghg_data_folder       = [parent_dir, 'GHG\'];
parameters.climate_data_folder              = [parent_dir, 'Climate\'];
parameters.biodiversity_data_folder         = [parent_dir, 'Biodiversity\UCL\'];
parameters.biodiversity_data_folder_jncc    = [parent_dir, 'Biodiversity\JNCC\'];
parameters.flooding_data_folder             = [parent_dir, 'Flooding\'];
parameters.flooding_transfer_data_folder    = [parent_dir, 'Flooding Transfer\'];
parameters.forest_data_folder               = [parent_dir, 'Forestry\'];
parameters.forestghg_data_folder            = [parent_dir, 'GHG\'];
parameters.non_use_habitat_data_folder      = [parent_dir, 'NonUseHabitat\'];
parameters.non_use_pollination_data_folder  = [parent_dir, 'NonUsePollination\'];
parameters.non_use_wq_data_folder           = [parent_dir, 'NonUseWQ\'];
parameters.non_use_wq_transfer_data_folder  = [parent_dir, 'NonUseWQ Transfer\'];
parameters.pollination_data_folder          = [parent_dir, 'Pollination\'];
parameters.water_data_folder                = [parent_dir, 'Water\'];
parameters.water_transfer_data_folder       = [parent_dir, 'Water Transfer\'];
parameters.rec_data_folder                  = [parent_dir, 'Recreation\'];


% Agriculture model
% -------------------------------------------
% NB. The standard climate is ukcp09 a1b 50th percentile temperature 
% and 50th percentile precipitation. It is possible to specify another
% climate among the following: 1) clim_string: 'ukcp09', 'ukcp18';
% 2) clim_scen_string: 'rcp26', 'rcp45', 'rcp60', 'rcp85'; 'a1b'; 
% 3) temp_pct_string: 50, 70, 90; 3) rain_pct_string: 50, 70, 90.
% 'a1b' belongs to 'ukcp09', all the RCPs belong to 'ukcp18'

parameters.num_years        = 40;
parameters.start_year       = 2020;
parameters.run_ghg          = true;
parameters.per_ha           = true;
parameters.price_wheat      = 29;
parameters.price_osr        = 78;
parameters.price_wbar       = 18;
parameters.price_sbar       = 20;
parameters.price_pot        = 45;
parameters.price_sb         = -9;
parameters.price_other      = 0;
parameters.price_dairy      = 4;
parameters.price_beef       = 154;
parameters.price_sheep      = 58;
parameters.price_fert       = -11;
parameters.price_quota      = -6;
parameters.gm_beef          = 130; % Nix 2021 deviation from default (200 - 70)
parameters.gm_sheep         = 46;  % Nix 2021 deviation from default (55 - 9)
parameters.irrigation       = true;
parameters.discount_rate    = 0.035;
parameters.clim_string      = 'ukcp18';
parameters.clim_scen_string = 'rcp60';
parameters.temp_pct_string  = '50';
parameters.rain_pct_string  = '50';
parameters.carbon_price     = 'non_trade_central';

% Agricultural land class (ALC) based yield scaling
% First column: agricultural land class; Second column: gross margin scale
% factor
% 
% If yield factors for an ALC is not specified, it will default to 1
parameters.alc_yield_factor = [1, 1.2;
                               2, 1.1;
                               3, 0.95;
                               4, 0.95;
                               5, 0.95;
                               6, 0.95;
                               7, 0.95];

% Forestry model
% -------------------------------------------
parameters.price_broad_factor = 1;
parameters.price_conif_factor = 1;

% Flooding model
% --------------
parameters.event_parameter = 7;
parameters.target_events_per_year = 5;

end
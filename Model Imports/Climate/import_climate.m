function ClimateData = import_climate(conn,...
    climate_scenario,...
    pct_temp,...
    pct_rain)
% ImportClimate
% =============
% Author: Mattia Mancini
% Last modified: 16/12/2020
% Import the climate data required for running the NEV agriculture
% model. To be called from within the ImportStandardClimate.m and 
% ImportAgriculture.m script
% Inputs:
% - conn: a database connection.
% - climate_scenario: optional argument in case the standard 'rcp60' is
%   not the climate of interest. Other values can be 'rcp26', 'rcp45',
%   'rcp85', 'a1b'.
% - pct_temp: optional argument in case the standard 50th percentile
%   level from the temperature data is not the one of interest. Other
%   possible values are 1, 5, 10, 25, 75, 90, 95, 99
% - pct_rain: optional argument in case the standard 50th percentile
%   level from the precipitation data is not the one of interest. Other
%   possible values are 1, 5, 10, 25, 75, 90, 95, 99
% Outputs:
% - ClimateData: a structure containing temperature and precipitation
%   data for the selected climate, yearly and for the growing season,
%   restricted and unrestricted
% ---------------------------------------------------------------------

%% Donload the data from the SQL database
%  ======================================

% Set default arguments
    if ~exist('climate_scenario', 'var') || isempty('climate_scenario')
        climate_scenario = 'rcp60';
    end
    if ~exist('pct_temp', 'var') || isempty('pct_temp')
        pct_temp = 50;
    end
    if ~exist('pct_rain', 'var') || isempty('pct_rain')
        pct_rain = 50;
    end

    type_array = {'annual', 'annual_restrict', 'grow', 'grow_restrict'};

    % Iterate across climate types
    for type = type_array
        str_type = char(type);
        temp_string = [' FROM ukcp18_climate.' , str_type, '_meantemp_',...
            climate_scenario,...
            '_',...
            num2str(pct_temp)];
        rain_string = [' FROM ukcp18_climate.', str_type, '_rainfall_',...
            climate_scenario,...
            '_',...
            num2str(pct_rain)];

        % identify the UKCP scenario based on the selected data for the
        % output names
        if climate_scenario == "a1b"
            clim = "ukcp09";
        else
            clim = "ukcp18";
        end

        % Connect to the database and load the data
        % -----------------------------------------
        % temperature
        sqlquery = ['SELECT * ', ...
                    temp_string];
        setdbprefs('DataReturnFormat', 'table');
        dataReturn  = fetch(exec(conn,sqlquery));
        ClimateData.(str_type).(strcat('Climate_cells_', clim, '_',...
            climate_scenario, '_temp_', num2str(pct_temp))) =...
            dataReturn.Data;

        % precipitation
        sqlquery = ['SELECT * ', ...
                    rain_string];
        setdbprefs('DataReturnFormat', 'table');
        dataReturn  = fetch(exec(conn,sqlquery));
        ClimateData.(str_type).(strcat('Climate_cells_', clim, '_',...
            climate_scenario, '_rain_', num2str(pct_rain))) =...
            dataReturn.Data;
    end
end

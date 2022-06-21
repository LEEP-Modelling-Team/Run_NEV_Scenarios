clear

%% (1) Set up
%  ==========
% Connect to database
% -------------------
server_flag = false;
conn = fcn_connect_to_database(server_flag);

% Path to weather data and processed data
% ---------------------------------------
path_to_weather = 'H:/WFD Package/Data/Weather/HadRM3 25km Grid/';
path_to_save = 'H:/WFD Package/Data/Weather/Processed For Subcatchment/';

% Database calls
% --------------
% Subcatchment IDs
sqlquery = 'SELECT subctch_id FROM water.river_catchments ORDER BY subctch_id';
setdbprefs('DataReturnFormat', 'cellarray');
dataReturn  = fetch(exec(conn, sqlquery));
subctch_id = dataReturn.Data;
num_subctch = length(subctch_id);

% 25km grid IDs
sqlquery = 'SELECT gid FROM water.rotated_25km_grid_27700 ORDER BY gid';
setdbprefs('DataReturnFormat', 'cellarray');
dataReturn  = fetch(exec(conn, sqlquery));
grid25km_id = dataReturn.Data;
num_grid25km = length(grid25km_id);

% Subcatchment / 25km grid cell ID lookup table
sqlquery = 'SELECT subctch_id, gid AS grid25km_id FROM water.lookup_subctch_25km ORDER BY subctch_id';
setdbprefs('DataReturnFormat', 'table');
dataReturn  = fetch(exec(conn, sqlquery));
lookup_subctch_25km = dataReturn.Data;

%% (2) Create weather file for each subcatchment
%  =============================================
% Set up decades
decades = [2020, 2030, 2040, 2050];

% Create sequence to extract correct decade of daily data from full data
% set, which contains daily data between 1950-2089 for 30-day months
% Precipitation sequence contains 5 extra days, since lagged variables are
% used in the transfer model
precip_decade_seq_2020 = 25196:28853;
precip_decade_seq_2030 = 28796:32452;
precip_decade_seq_2040 = 32396:36053;
precip_decade_seq_2050 = 35996:39652;

tempmx_decade_seq_2020 = 25201:28853;
tempmx_decade_seq_2030 = 28801:32452;
tempmx_decade_seq_2040 = 32401:36053;
tempmx_decade_seq_2050 = 36001:39652;

% Loop over decades
for decade_i = decades
    % Loop over subcatchments
    for j = 1:num_subctch
        % Extract subctch and 25km grid ID
        subctch_j = subctch_id{j};
        nearest_grid25km_j = lookup_subctch_25km.grid25km_id(j);
        
        % Read precipitation file for this 25km grid
        precip_file_subctch_j = [path_to_weather, 'p', num2str(nearest_grid25km_j), '.txt'];
        fileID = fopen(precip_file_subctch_j);
        precip_all_subctch_j = fscanf(fileID, '%*d %*d %f');
        fclose(fileID);
        
        % Read maximum temperature file for this 25km grid
        tempmx_file_subctch_j = [path_to_weather, 'tmax', num2str(nearest_grid25km_j), '.txt'];
        fileID = fopen(tempmx_file_subctch_j);
        tempmx_all_subctch_j = fscanf(fileID, '%*d %*d %f');
        fclose(fileID);
        
        % Extract precipitation and maximum temperature data for this decade
        % NB. precipitation includes 5 days previous for lagged terms in transfer model
        % NB. data is actually for 30-day months, we take the correct
        %     number of days for the decade (including leap years)
        switch decade_i
            case 2020
                precip_decade_i_subctch_j = precip_all_subctch_j(precip_decade_seq_2020);
                tempmx_decade_i_subctch_j = tempmx_all_subctch_j(tempmx_decade_seq_2020);
            case 2030
                precip_decade_i_subctch_j = precip_all_subctch_j(precip_decade_seq_2030);
                tempmx_decade_i_subctch_j = tempmx_all_subctch_j(tempmx_decade_seq_2030);
            case 2040
                precip_decade_i_subctch_j = precip_all_subctch_j(precip_decade_seq_2040);
                tempmx_decade_i_subctch_j = tempmx_all_subctch_j(tempmx_decade_seq_2040);
            case 2050
                precip_decade_i_subctch_j = precip_all_subctch_j(precip_decade_seq_2050);
                tempmx_decade_i_subctch_j = tempmx_all_subctch_j(tempmx_decade_seq_2050);
        end
        
        % Set negative precipitation values to zero
        precip_decade_i_subctch_j(precip_decade_i_subctch_j < 0) = 0;
        
        % Write precipitation data to .txt file
        fileID = fopen([path_to_save, num2str(decade_i), '/p', num2str(subctch_j), '.txt'], 'w');
        fprintf(fileID, '%f\n', precip_decade_i_subctch_j);
        fclose(fileID);
        
        % Write maximum temperature data to .txt file
        fileID = fopen([path_to_save, num2str(decade_i), '/tmax', num2str(subctch_j), '.txt'], 'w');
        fprintf(fileID, '%f\n', tempmx_decade_i_subctch_j);
        fclose(fileID);

        disp([num2str(decade_i), ': Processed ', num2str(j), ' of ', num2str(num_subctch), ' subcatchments.'])
    end
end

clear

% Connect to database
% -------------------
server_flag = false;
conn = fcn_connect_to_database(server_flag);

% Path to save data
SetDataPaths;
path_to_save = [water_transfer_data_folder,'Input Output\'];

% Database calls
% --------------
% River catchment input/output table, ordered by basin number/id
sqlquery = 'SELECT basin, outflow_ctch, inflow_ctch FROM water.river_catchments_io ORDER BY basin';
setdbprefs('DataReturnFormat', 'table');
dataReturn  = fetch(exec(conn, sqlquery));
river_catchments_io = dataReturn.Data;

% Add in extra io for basin 3125
extra_io = {3125, '6962_0', '6091_0'};
river_catchments_io = [river_catchments_io; extra_io];

% Alter io for basin 2111
river_catchments_io.outflow_ctch(strcmp('697_0', river_catchments_io.outflow_ctch) & strcmp('697_1', river_catchments_io.inflow_ctch)) = {'697_2'};
river_catchments_io.inflow_ctch(strcmp('664_0', river_catchments_io.outflow_ctch) & strcmp('697_0', river_catchments_io.inflow_ctch)) = {'697_2'};

% Alter io for basin 115
river_catchments_io = river_catchments_io(~(strcmp('5684_0', river_catchments_io.outflow_ctch) & strcmp('0', river_catchments_io.inflow_ctch)), :);
river_catchments_io = river_catchments_io(~(strcmp('8470_0', river_catchments_io.outflow_ctch) & strcmp('5684_0', river_catchments_io.inflow_ctch)), :);
extra_io = {115, '5684_0', '8470_0'; ...
            115, '8470_0', '0'};
river_catchments_io = [river_catchments_io; extra_io];

% Add io for River Dart (basin 3474)
extra_io = {3474, '3334_0', '3804_0'; ...
            3474, '3419_0', '3804_0'; ...
            3474, '3393_0', '3804_0'; ...
            3474, '3727_0', '3801_0'; ...
            3474, '3804_0', '3801_0'; ...
            3474, '3801_0', '3802_0'; ...
            3474, '3421_0', '3802_0'; ...
            3474, '3420_0', '3728_0'; ...
            3474, '3394_0', '3728_0'; ...
            3474, '3728_0', '3802_0'; ...
            3474, '3701_0', '3802_0'; ...
            3474, '3729_0', '3802_0'; ...
            3474, '3698_0', '3701_0'; ...
            3474, '3696_0', '0'; ...
            3474, '3802_0', '0'};
river_catchments_io = [river_catchments_io; extra_io];

%% Deal with issue that a single subbasin has multiple basins
% Basin IDs
% ---------
% Only consider basins with IO entries
basin_ids = unique(river_catchments_io.basin);
num_basins = length(basin_ids);
    
%  Subcatchment / Basins crossover
% -----------------------------------    
basins_long = [];
subctch_long = [];
for i = 1:num_basins
    river_catchments_io_basini = river_catchments_io(river_catchments_io.basin == basin_ids(i), :);
    subctch_ids_basin_i = unique([river_catchments_io_basini.outflow_ctch; river_catchments_io_basini.inflow_ctch]);
    subctch_ids_basin_i = subctch_ids_basin_i(~strcmp('0', subctch_ids_basin_i));
    num_subctch_ids_basin_i = length(subctch_ids_basin_i);
    basins_long = [basins_long; repmat(basin_ids(i), num_subctch_ids_basin_i, 1)];
    subctch_long = [subctch_long; subctch_ids_basin_i];
end
subctch_basins = table(subctch_long, basins_long);
subctch_basins.Properties.VariableNames = {'subctch_id', 'basin_id'};
subctch_basins = sortrows(subctch_basins, 1);

% Remove cases with multiple basins
% ---------------------------------
% Find subctch_ids with more than one basin
X = tabulate(subctch_basins.subctch_id);
duplicate_subctch = X(cell2mat(X(:, 2)) > 1, 1);
num_duplicate_subctch = length(duplicate_subctch);

% For each duplicate subctch, retain 1st basin
% Overwrite all occurrences of other basins with 1st basin
for i = 1:num_duplicate_subctch
    ind_subctch_i = ismember(subctch_basins.subctch_id, duplicate_subctch{i});
    subctch_i_basins = subctch_basins.basin_id(ind_subctch_i);
    subctch_i_selected_basin = subctch_i_basins(1);
    subctch_i_notselected_basins = subctch_i_basins(2:end);
    ind_subctch_i_notselected_basins = ismember(river_catchments_io.basin, subctch_i_notselected_basins);
    river_catchments_io.basin(ind_subctch_i_notselected_basins) = subctch_i_selected_basin;
end

% Remove duplicate rows from river_catchments_io, which have arisen from
% overwrites
river_catchments_io = unique(river_catchments_io);

% Save river_catchments_io to .mat file
save([path_to_save, 'river_catchments_io.mat'], 'river_catchments_io');

%% Work out IO (firstorder/secondorder catchments and how they flow) for each basin
basin_ids = unique(river_catchments_io.basin);
num_basins = length(basin_ids);

for i = 1:num_basins
    river_catchments_io_basin_i = river_catchments_io(river_catchments_io.basin == basin_ids(i),:);
    
    subctch_basin_i = unique([river_catchments_io_basin_i.outflow_ctch; river_catchments_io_basin_i.inflow_ctch]);
    subctch_basin_i = subctch_basin_i(~strcmp('0', subctch_basin_i));
    
    num_subctch_basin_i = length(subctch_basin_i);
    
    firstorder = [];
    secondorder = [];
    
    count = 0;
    outflow_ctch_old = river_catchments_io_basin_i.outflow_ctch(strcmp('0', river_catchments_io_basin_i.inflow_ctch));
    outflow_ctch_old = unique(outflow_ctch_old);    % remove multiple outflows
    
    while count < num_subctch_basin_i
        num_outflow_ctch_old = size(outflow_ctch_old, 1);
        outflow_ctch_new = [];
        for j = 1:num_outflow_ctch_old
            outflow_ctch_new_j = river_catchments_io_basin_i.outflow_ctch(strcmp(outflow_ctch_old(j), river_catchments_io_basin_i.inflow_ctch));
            num_outflow_ctch_new_j = size(outflow_ctch_new_j, 1);
            if num_outflow_ctch_new_j == 0
                firstorder = [outflow_ctch_old(j); firstorder];
                count = count + 1;
            else
                secondorder = [{[outflow_ctch_old(j), outflow_ctch_new_j']}; secondorder];
                count = count + 1;
            end
            outflow_ctch_new = [outflow_ctch_new; outflow_ctch_new_j];
        end
        outflow_ctch_old = outflow_ctch_new;
    end
    
    if num_subctch_basin_i ~= (length(firstorder) + length(secondorder))
        error('Subcatchments not categorised correctly!')
    end
    
    save([path_to_save, 'io', num2str(basin_ids(i)), '.mat'], 'firstorder', 'secondorder');
    
    disp(['Processed basin ', num2str(i), ' of ' num2str(num_basins), ' basins.']);
end

%% Work out firstdownstream table
% I.e for every subcatchment, what is the next subcatchment downstream?
% Used in Defra/ADVENT/FAB-GGR flooding valuation runs

% Get list of all subcatchments in order
sqlquery = 'SELECT subctch_id FROM water.river_catchments ORDER BY subctch_id';
setdbprefs('DataReturnFormat', 'table')
dataReturn = fetch(exec(conn, sqlquery));
subctch_ids = dataReturn.Data;

% Outerjoin river_catchments_io table to subctch_ids on subctch_id = outflow_id
firstdownstream = outerjoin(subctch_ids, ...
                            river_catchments_io(:, {'outflow_ctch', 'inflow_ctch'}), ...
                            'LeftKeys', 'subctch_id', ...
                            'RightKeys', 'outflow_ctch', ...
                            'RightVariables', 'inflow_ctch');

% Sort firstdownstream to original subctch_id order
[~, idx] = ismember(subctch_ids.subctch_id, firstdownstream.subctch_id);
firstdownstream = firstdownstream(idx, :);

% Rename inflow_ctch as firstdownstream
firstdownstream.Properties.VariableNames = {'subctch_id', 'firstdownstream'};

% Set firstdownstream = '' to 'NA' (i.e. no IO at all)
firstdownstream.firstdownstream(strcmp('', firstdownstream.firstdownstream)) = {'NA'};

% Set firstdownstream = '0' to 'end' (i.e. end of catchment, river flows into sea/estuary)
firstdownstream.firstdownstream(strcmp('0', firstdownstream.firstdownstream)) = {'end'};

% Save firstdownstream table to .mat file
save([path_to_save, 'firstdownstream.mat'], 'firstdownstream');
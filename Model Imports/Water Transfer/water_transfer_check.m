clear
conn = fcn_connect_database(false);

% D = struct2table(dir('*2029*'));
% files = D.name;
% num_files = length(files);
% num_subctch = 0;
% for i = 1:num_files
%     load(files{i})
%     num_subctch = num_subctch + size(basin_em_data, 2);
%     disp(i)
% end

load('H:/WFD Package/Data/Land Use/base_lcs_subctch.mat', 'base_lcs_subctch');
all_subctch = base_lcs_subctch.subctch_id;

land_subctch = base_lcs_subctch.subctch_id(~isnan(base_lcs_subctch.watr_20));

load('Model Data\Water Transfer\es_water_base')
base_run_subctch = sort(es_water_base.subctch_id);

sqlquery = ['SELECT DISTINCT(outflow_ctch) AS subctch_id FROM water.river_catchments_io ', ...
            'UNION ', ...
            'SELECT DISTINCT(inflow_ctch) AS subctch_id FROM water.river_catchments_io ', ...
            'ORDER BY subctch_id'];
setdbprefs('DataReturnFormat', 'cellarray');
dataReturn  = fetch(exec(conn,sqlquery));
io_subctch = dataReturn.Data;
io_subctch = io_subctch(~strcmp('0', io_subctch)); % remove 0 (outflow catchment)

ind_base = ismember(all_subctch, base_run_subctch);
base_not_in_all = all_subctch(~ind_base);

ind_land = ismember(all_subctch, land_subctch);
land_not_in_all = all_subctch(~ind_land);

ind_io = ismember(all_subctch, io_subctch);
io_not_in_all = all_subctch(~ind_io);

sum(~ind_base)
sum(~ind_land)
sum(~ind_io)

sum(~ind_land | ~ind_io)
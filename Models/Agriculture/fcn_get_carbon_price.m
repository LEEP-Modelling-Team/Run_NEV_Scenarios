function [carbon_price] = fcn_get_carbon_price(conn, carbon_price_level)
% FCN_GET_CARBON_PRICE
% Quickly retrieve carbon price from SQL database
% Author: Frankie Cho
switch carbon_price_level
    case {'trade_low', 'trade_central', 'trade_high', 'non_trade_low', 'non_trade_central', 'non_trade_high'}
        sqlquery = ['SELECT year, ', carbon_price_level ,' FROM greenbook.c02_val_2018_ext'];
        setdbprefs('DataReturnFormat', 'table');
        dataReturn  = fetch(exec(conn, sqlquery));
        carbon_table = dataReturn.Data;
    case 'scc'
        sqlquery = 'SELECT year, scc_tol FROM nevo.ghg_carbon_prices';
        setdbprefs('DataReturnFormat', 'table');
        dataReturn  = fetch(exec(conn, sqlquery));
        carbon_table = dataReturn.Data;
        carbon_table.Properties.VariableNames = {'year', 'scc'};
    otherwise
        message = sprintf(['carbon_price can only be assigned the following values: \n', ...
            '    trade_low, trade_central, trade_high, \n', ...
            '    non_trade_low, non_trade_central, non_trade_high, ssc']);
        warning(message)
end

% Extract carbon price from 2020 for 300 years
idx_2020 = find(carbon_table.year == 2020);
carbon_price_table = carbon_table.(carbon_price_level);
carbon_price = carbon_price_table(idx_2020:(idx_2020 + 300 - 1));
end
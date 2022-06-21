function subctch_em_upstream = fcn_add_transfer_upstream_out(basin_em_data, upstream_idx)
    num_upstream = length(upstream_idx);
    
    subctch_em_upstream.flow = 0;
    subctch_em_upstream.orgn = 0;
    subctch_em_upstream.orgp = 0;
    subctch_em_upstream.no3 = 0;
    subctch_em_upstream.no2 = 0;
    subctch_em_upstream.nh4 = 0;
    subctch_em_upstream.minp = 0;
    subctch_em_upstream.disox = 0;
    
    for i = 1:num_upstream
        subctch_em_upstream.flow = subctch_em_upstream.flow + basin_em_data{upstream_idx(i)}.flow;
        subctch_em_upstream.orgn = subctch_em_upstream.orgn + basin_em_data{upstream_idx(i)}.orgn;
        subctch_em_upstream.orgp = subctch_em_upstream.orgp + basin_em_data{upstream_idx(i)}.orgp;
        subctch_em_upstream.no3 = subctch_em_upstream.no3 + basin_em_data{upstream_idx(i)}.no3;
        subctch_em_upstream.no2 = subctch_em_upstream.no2 + basin_em_data{upstream_idx(i)}.no2;
        subctch_em_upstream.nh4 = subctch_em_upstream.nh4 + basin_em_data{upstream_idx(i)}.nh4;
        subctch_em_upstream.minp = subctch_em_upstream.minp + basin_em_data{upstream_idx(i)}.minp;
        subctch_em_upstream.disox = subctch_em_upstream.disox + basin_em_data{upstream_idx(i)}.disox;
    end
end
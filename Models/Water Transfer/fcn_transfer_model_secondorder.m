function [subctch_em_summary, subctch_em_out] = fcn_transfer_model_secondorder(water_transfer_data_folder, ...
                                                                               subctch_info, ...
                                                                               decade_str, ...
                                                                               subctch_em_upstream, ...
                                                                               models_lu)
    subctch_em_lu = fcn_transfer_model_fromland(water_transfer_data_folder, ...
                                                subctch_info, ...
                                                decade_str, ...
                                                models_lu);
    
    subctch_em_in.flow = subctch_em_lu.flow + subctch_em_upstream.flow;
    subctch_em_in.orgn = subctch_em_lu.orgn + subctch_em_upstream.orgn;
    subctch_em_in.orgp = subctch_em_lu.orgp + subctch_em_upstream.orgp;
    subctch_em_in.no3 = subctch_em_lu.no3 + subctch_em_upstream.no3;
    subctch_em_in.no2 = subctch_em_lu.no2 + subctch_em_upstream.no2;
    subctch_em_in.nh4 = subctch_em_lu.nh4 + subctch_em_upstream.nh4;
    subctch_em_in.minp = subctch_em_lu.minp + subctch_em_upstream.minp;
    subctch_em_in.disox = subctch_em_lu.disox + subctch_em_upstream.disox;
    
    subctch_em_out = fcn_transfer_model_instream(subctch_em_in);
    
    subctch_em_summary = fcn_subctch_summary_calc(subctch_em_out, ...
                                                  decade_str);
       
end
function eco_class = fcn_predict_eco_class(wfd_data)

% First condition: (third in legislation)
% The ecological status must be classified according to the lowest classed 
% biological or physico-chemical or specific pollutant quality element.
eco_class = max([wfd_data.bio_class, ...
                 wfd_data.sp_class, ...
                 wfd_data.pc_class, ...
                 wfd_data.amm_class, ...
                 wfd_data.dis_class, ...
                 wfd_data.pho_class], [], 2);
             
% Second condition:
% The ecological status of a water body is not to be classified as lower 
% than moderate by reason only of any quality element for a specific 
% pollutant or any physico-chemical quality element in that water body 
% being of a standard lower than moderate.
ind2a = (sum([wfd_data.sp_class, wfd_data.pc_class, wfd_data.amm_class, wfd_data.dis_class, wfd_data.pho_class] > 3, 2) > 0) & ...
    (sum(wfd_data.bio_class > 3, 2) < 1);
ind2b = (sum([wfd_data.sp_class, wfd_data.pc_class, wfd_data.amm_class, wfd_data.dis_class, wfd_data.pho_class] > 4, 2) > 0) & ...
    (sum(wfd_data.bio_class == 4, 2) > 0);
ind2c = (sum([wfd_data.sp_class, wfd_data.pc_class, wfd_data.amm_class, wfd_data.dis_class, wfd_data.pho_class] > 4, 2) > 0) & ...
    (sum(wfd_data.bio_class == 5, 2) > 0);
eco_class(ind2a) = 3;
eco_class(ind2b) = 4;
eco_class(ind2c) = 5;

% Third condition: (first in legislation)
% The ecological status of the water body must be classified as high if�
% the values of all the indicators of biological and physico-chemical 
% quality elements and concentrations of specific pollutants, comply with 
% the highest corresponding standard;
% the water body is classified as high status for hydromorphological 
% quality elements
ind3 = (max([wfd_data.bio_class, ...
             wfd_data.sp_class, ...
             wfd_data.pc_class, ...
             wfd_data.amm_class, ...
             wfd_data.dis_class, ...
             wfd_data.pho_class], [], 2) == 1) & ...
        (wfd_data.hm_class ~= 1);
eco_class(ind3) = 2;

end


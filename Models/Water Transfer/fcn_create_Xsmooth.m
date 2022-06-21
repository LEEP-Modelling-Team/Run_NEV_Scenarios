function Xsmooth = fcn_create_Xsmooth(object, smooth_terms, smooth_names, n)
% fcn_create_Xsmooth.m
% ====================
% Author: Nathan Owen
% Last modified: 19/06/2020
% Function to create regression matrix (X) for smooth terms for a
% generalized additive model with thin plate regression plates. This
% follows the 'mgcv' package in R. 
count = 0;
Xsmooth = zeros(n, length(smooth_names) * 9);
for name = smooth_names
    name_char = name{1};
    x = smooth_terms.(name_char) - object.(['shift_', name_char]);
    r = pdist2(x, object.(['Xu_', name_char]));
    eta = (1/12) * (r .* r .* r);   % for speed
    eta_1x = [eta, ones(n, 1), x];
    X1 = eta_1x * object.(['UZ_', name_char]);
    QX1 = object.(['Q_', name_char])' * X1';
    Xsmooth(:, (1:9) + 9*count) = QX1(2:10, :)';
    count = count + 1;
end

end

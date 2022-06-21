%% fcn_Hash_data.m
%  ===============
% Author: Mattia Mancini - Rebecca Collins
% Created: 25-May-2022
% Last modified: 25-May-2022
% ----------------------------------------
%
% DESCRIPTION
%
% Function that takes a matlab array and converts it into a unique uint-8 
% hash. This is used to check the integrity of the data passed, to create
% unique folders to store data, and to make sure the correct data is stored
% in the correct locations
%% =========================================================================

function hash = fcn_hash_data(array)
    B = typecast(array(:),'uint8');
    % Create an instance of a Java MessageDigest with the desired algorithm:
    md = java.security.MessageDigest.getInstance('SHA-1');
    md.update(B);

    % Properly format the computed hash as an hexadecimal string:
    hash = reshape(dec2hex(typecast(md.digest(),'uint8'))',1,[]);
end
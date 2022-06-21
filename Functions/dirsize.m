%% dirsize.m
%  =========
%  Author: Mattia Mancini, Rebecca Collins
%  Created: 27 May 2022
%  Last modified: 27 May 2022
%  ---------------------------------------
%
%  DESCRIPTION
%  Function that looks at the size of teh elements inside a folder
%  specified into the 'path' argument. This is done to check whether a
%  folder is empty or not.
%% ====================================================================


function [x] = dirsize(path)
    s = dir(path);
    name = {s.name};
    isdir = [s.isdir] & ~strcmp(name,'.') & ~strcmp(name,'..');
    subfolder = fullfile(path, name(isdir));
    x = sum([s(~isdir).bytes cellfun(@dirsize, subfolder)]);
end
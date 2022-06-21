function subctch_id = fcn_get_downstream_subctch_id(subctch_id_overlap, firstdownstream)

% Add downstream subbasins to this list
% Will be some duplicates, may be a better way
subctch_id = {};
count = 1;

for i = 1:size(subctch_id_overlap, 1)

    % If src_id_overlap subbasin not already in list...
    if ~any(strcmp(subctch_id,subctch_id_overlap(i)))

        % Add overlapping subbasin to list and increment counter
        subctch_id(count) = subctch_id_overlap(i);
        count = count + 1;

        % Do loop for downstream subbasins
        while true

            firstdownstream_temp = firstdownstream.firstdownstream(strcmp(firstdownstream.subctch_id, subctch_id{count-1}));

            if strcmp(firstdownstream_temp, 'end') || ...
                    strcmp(firstdownstream_temp, 'NA') || ...
                    any(strcmp(subctch_id, firstdownstream_temp))
                % If firstdownstream = 'end' or 'NA' or is already in list, break
                break
            else
                % Else, add firstdownstream subbasin to list and increment
                % counter
                subctch_id(count) = firstdownstream_temp;
                count = count + 1;
            end

        end

    end

end

% Returns transpose
subctch_id = subctch_id';

end
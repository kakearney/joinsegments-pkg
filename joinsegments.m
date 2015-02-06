function [xc,yc] = joinsegments(x,y)
%JOINSEGMENTS Connect NaN-delimited line segments into one line
%
% [x,y] = joinsegments(x,y)
%
% This function is designed to connect together line segments that together
% form one or more polylines, but whose individual parts may not be
% in the correct order (I find such data often in GIS-derived data).
%
% Input variables:
%
%   x:  vector of x values, with line segments separated by NaNs
%
%   y:  vector of y values, with line segments separated by NaNs
%
% Output variables:
%
%   xc:  vector of x values, reordered and with NaNs removed 
%
%   yc:  vector of y values, reordered and with NaNs removed

% Copyright 2013-2015 Kelly Kearney

% Divide into segments

x = x(:);
y = y(:);
[x,y] = polysplit(x,y);

% Check for segments that are already closed polygons

isclosed = cellfun(@(x,y) x(1)==x(end) && y(1)==y(end), x, y);
xc = x(isclosed);
yc = y(isclosed);
x = x(~isclosed);
y = y(~isclosed);

% Figure out which remaining segments connect to each other

while ~isempty(x)

    % Isolate coordinate of segment connection nodes

    coord1 = cell2mat(cellfun(@(a,b) [a(1) b(1)], x, y, 'uni', 0));
    coord2 = cell2mat(cellfun(@(a,b) [a(end) b(end)], x, y, 'uni', 0));

    coord = unique([coord1; coord2], 'rows');

    [tf, loc1] = ismember(coord1, coord, 'rows');
    [tf, loc2] = ismember(coord2, coord, 'rows');

    % Choose a starting point.  Open polylines will have a specific
    % beginning and end, so start there if possible. If only closed
    % polygons are left, choose the first segment.  

    ismatched = ismember(loc1, loc2, 'rows');
    sidx = find(~ismatched, 1);
    if isempty(sidx)
        sidx = 1;
    end

    order = [loc1(sidx) loc2(sidx)];
    while 1
        tf = (loc1 == order(end));
        if any(tf)

            % Look for matching segments

            idx = find(tf);
            newseg = [loc1(idx) loc2(idx)];

            % Toss segments that would create an infinite loop

            isfound = false(size(idx));
            for in = 1:size(newseg,1)
                isfound(in) = ~isempty(strfind(order, newseg(in,:)));
            end

            idx = idx(~isfound);

            % If still multiple choices, just go with first open path

            if isempty(idx)
                break
            else
                next = loc2(idx(1)); 
                order = [order next];
            end

        else
            break
        end
    end

    segs = [order(1:end-1)' order(2:end)'];
    [tf, segorder] = ismember(segs, [loc1 loc2], 'rows');

    xnew = cat(1, x{segorder});
    ynew = cat(1, y{segorder});

    xc = [xc; xnew];
    yc = [yc; ynew];

    remain = setdiff(1:length(x), segorder);
    x = x(remain);
    y = y(remain);

end
  

% Input image
image = imread('desk.jpg');
image = im2gray(image);
image = im2double(image);

% Smooth the image
image = imbilatfilt(image);

% Record size of image
[m, n] = size(image);

% Get the seed point
imshow(image);
title('Click on the seed point');
[x_seed, y_seed] = ginput(1);

% Get the goal point
title('Click on the goal point');
[x_goal, y_goal] = ginput(1);

% Round the coords
x_seed = round(x_seed);
y_seed = round(y_seed);
x_goal = round(x_goal);
y_goal = round(y_goal);

% Get the max value
maxValue = max(image(:));

% Make a matrix of infinity to be filled in
costs = Inf(m, n);

% Make a list to keep track of parents(where the node point back to)
parents = zeros(m, n, 2);

% Set seed point cost to 0
costs(x_seed, y_seed) = 0;

% Create active and expand list
active_list = [[x_seed, y_seed]];
expand_list = [];


% Start alg
while ~isempty(active_list)
    % Get the min cost node from active list
    [r_x, r_y] = findMinCostNode(costs, active_list);

    % Break loop if goal point show up
    if isequal([r_x, r_y], [x_goal,y_goal])
        break;
    end

    % Remove the min node from active list and add that to expand list
    active_list = setdiff(active_list, [r_x, r_y], 'rows');
    expand_list = [expand_list; [r_x, r_y]];

    % Get neighbor of min node
    neighbors = getNeighbors([r_x, r_y], m, n);

    % Apply to each neighbor
    for i = 1:size(neighbors, 1)
        % X and Y of neighbor
        q_x = neighbors(i, 1);
        q_y = neighbors(i, 2);

        % Calculate the cost and make sure it is not in expand list already
        if costs(q_x, q_y) > (costs(r_x, r_y) + calculateCost(image, [r_x, r_y], [q_x, q_y], maxValue,m,n)) & isempty(find(expand_list(:,1) == q_x & expand_list(:,2) == q_y, 1))
            % Update cost of neighbor
            costs(q_x, q_y) = costs(r_x, r_y) + calculateCost(image, [r_x, r_y], [q_x, q_y], maxValue,m,n);

            % Set the parent of neightbor
            parents(q_x, q_y, 1) = r_x;
            parents(q_x, q_y, 2) = r_y;

            % if not in active list add the cord
            if isempty(find(active_list(:,1) == q_x & active_list(:,2) == q_y, 1)) 
                active_list = [active_list; [q_x, q_y]];
            end
        end
    end

end

% Contruct an array that from goal to seed
path = [[x_goal, y_goal]];
while ~isequal(path(end,:), [x_seed, y_seed])
    parent = squeeze(parents(path(end, 1), path(end, 2), :))';
    path = [path; parent];
    disp(parent)
end

% Draw the line as a White line
for i = 1:size(path, 1)
    image(path(i, 2), path(i, 1)) = 255;
end
imshow(image);


function [r_x, r_y] = findMinCostNode(costs, active_list)

    % Map active_list coordinates to the cost matrix
    active_indices = sub2ind(size(costs), active_list(:,1), active_list(:,2));
    
    % Find the minimum value and its index within active_indices
    [minValue, minIndex] = min(costs(active_indices));
    
    % Convert the index back to subscripts
    [r_x, r_y] = ind2sub(size(costs), active_indices(minIndex));
end

function neighbors = getNeighbors(point, m, n)
    x = point(1);
    y = point(2);

    % Get surrounding neighbors
    neighbors = [x-1, y-1; x-1, y; x-1, y+1; x, y-1; x, y+1; x+1, y-1; x+1, y; x+1, y+1];

    % Filter out the out of bound nodes
    neighbors = neighbors(neighbors(:,1) >= 1 & neighbors(:,1) <= m & neighbors(:,2) >= 1 & neighbors(:,2) <= n, :);
end

function cost = calculateCost(image, p, q, maxValue,m,n)
    % Define the 3x3 kernels
    kernels = {
        { ...
            [0,-1,0; 1,0,0; 0,0,0], [1,0,-1; 1,0,-1; 0,0,0], [0,1,0; 0,0,-1; 0,0,0]
        }, ...
        { ...
            [1,1,0; 0,0,0; -1,-1,0], [0,0,0; 0,0,0; 0,0,0], [0,1,1; 0,0,0; 0,-1,-1]
        }, ...
        { ...
            [0,0,0; 1,0,0; 0,-1,0], [0,0,0; 1,0,-1; 1,0,-1], [0,0,0; 0,0,-1; 0,1,0]
        }
    };

    % Calculate filter_response using the appropriate kernel
    if p(1) == q(1) || p(2) == q(2) % Non-diagonal situation
        length = 1/4;
    else % Diagonal situation
        length = 1/sqrt(2);
    end
    
    % Get the differnce in x and y of p and q
    [dx, dy] = deal(q(2)-p(2)+2, q(1)-p(1)+2);

    % Make sure the neighbor coord are not out of bound
    x_indices = min(max(p(1)-1:p(1)+1, 1), m);
    y_indices = min(max(p(2)-1:p(2)+1, 1), n);
    
    % 3x3 Matrix of neighbor and self
    adjacent = image(x_indices, y_indices);

    % Calculate filter response
    filter_response = sum(sum((adjacent) .* (kernels{dx}{dy})));

    % Caclulate cost
    cost = (maxValue - abs(filter_response)) * length;
end

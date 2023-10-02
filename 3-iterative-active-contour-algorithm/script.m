% Load the image
I = imread('circle.png'); % Replace with your image path
figure;
imshow(I);
title('Original Image');

% Collect list of points from the user
h = impoly(gca);
points = getPosition(h);
delete(h);

% Run SnakeAlgorithm
[new_points] = SnakeAlgorithm(I, points, 0.5);

% Graph the resulting points and old points
% First subplot
figure;
subplot(1,2,1);
imshow(I);
hold on;
plot(points(:,1), points(:,2), 'r', 'LineWidth', 2);
plot([points(1,1), points(end,1)], [points(1,2), points(end,2)], 'r', 'LineWidth', 2);
title('Original Points');

% Second subplot
subplot(1,2,2);
imshow(I);
hold on;
plot(new_points(:,1), new_points(:,2), 'r', 'LineWidth', 2);
plot([new_points(1,1), new_points(end,1)], [new_points(1,2), new_points(end,2)], 'r', 'LineWidth', 2);
title('Modified Points');

function [new_points] = SnakeAlgorithm(I, points, f)
    N = size(points, 1);
    moved_points = N;

    % Loop until the fraction of the moved_points is less than or equal to f
    while ((moved_points / N) > f)
        moved_points = 0;
        % Get the avg distance between points and update it every iteration
        d = ComputeAverageDistance(points);

        % Loop through the set of points
        for i = 1:N
            pi = points(i,:);

            % Get the point and the points before and after it
            pi1 = points(mod(i-2, N) + 1, :);
            pi2 = pi;
            pi3 = points(mod(i, N) + 1, :);

            % Compile the 3 points into a matrix
            p3 = reshape([pi1,pi2,pi3], [3,2]);

            % Compute a 3x3 matrix of the lowest E value
            Ui = U(pi2, p3, d, I);

            % Get the row and col of the min E value
            [~, min_idx] = min(Ui(:));
            [row, col] = ind2sub(size(Ui), min_idx);
            
            % Get the coordinate of the min E value
            min_location = [pi2(1)+(row-2), pi2(2)+(col-2)];

            % Move the point to the min E value location and increment moved_points
            if ~isequal(pi, min_location)
                points(i,:) = min_location;
                moved_points = moved_points + 1;
            end
        end
    end
    % Return new points
    new_points = points;
end

function Ui = U(pi, p3, d, I)
    Ui = zeros(3, 3);

    % Compute E value for 3x3 neighbors
    for r = -1:1
        for c = -1:1
            coord = pi + [r, c];
            Ui(r+2, c+2) = energy(d, coord, p3, I);
        end
    end
end

function E = energy(d, coord, p3, I)
    % Adjusted weights for the energy components
    a = 1;
    b = 2; % Increase smoothness term weight
    c = 1;
    
    % Energy equation
    E = a*Ec(coord,d) + b*Es(coord,p3) + c*Eg(coord, I);
end

function Ec_i = Ec(pi,d)
    % Compute the energy based on the distance from the average distance
    Ec_i = (d - norm(pi))^2;
end

function Es_i = Es(pi,p3)
    % Compute the energy based on the smoothness of the curve
    Es_i = norm((p3(1,:) - 2*pi + p3(3,:))/2)^2;
end

function Eg_i = Eg(pi, I)
    [height, width] = size(I);
    pi = round(pi);

    % Ensure coordinates are within image bounds
    pi(1) = min(max(pi(1), 1), height);
    pi(2) = min(max(pi(2), 1), width);

    % Handle the bounds of the image
    x1 = min(max(pi(1)-1, 1), height);
    x2 = min(max(pi(1)+1, 1), height);
    y1 = min(max(pi(2)-1, 1), width);
    y2 = min(max(pi(2)+1, 1), width);

    % Compute image gradient
    dI_dx = double((I(x2, pi(2)) - I(x1, pi(2))) / 2.0);
    dI_dy = double((I(pi(1), y2) - I(pi(1), y1)) / 2.0);

    dI = [dI_dx, dI_dy];
    
    % Return the norm of the gradient as the energy term
    Eg_i = norm(dI);
end

function d = ComputeAverageDistance(points)
    N = size(points, 1);
    perimeter = 0;
    
    % Sum up the length of the every line
    for i = 1:N
        next_i = mod(i, N) + 1;
        perimeter = perimeter + norm(points(next_i,:) - points(i,:));
    end
    
    % Compute the average distance
    d = perimeter / N;
end

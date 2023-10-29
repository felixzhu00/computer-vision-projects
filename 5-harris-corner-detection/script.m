% Get Image and convert to grayscale
I = imread('brickwall.jpg');
I = double(rgb2gray(I))/255;

% Runs the function
% The returned value will be base on eigen-decomposition Method
% Figure is plotted inside the function
[corners, R] = detectHarrisCorners(I, 1, 3, 10, 100); 

function [corners, R] = detectHarrisCorners(Image, Sigma, N, D, M)
    % Step 1: Apply smoothing with gaussian kernal
    smoothing_kernel = fspecial('gaussian', ceil(3*Sigma)*2+1, Sigma);
    smoothed_image = conv2(Image, smoothing_kernel, 'same');

    % Step 2: Compute gradient images Gx and Gy
    Gx = conv2(smoothed_image, [-1 0 1], 'same');
    Gy = conv2(smoothed_image, [-1; 0; 1], 'same');

    % Step 3: Compute Harris corner R values
    Sx2 = conv2(Gx.^2, ones(N), 'same');
    Sy2 = conv2(Gy.^2, ones(N), 'same');
    Sxy = conv2(Gx.*Gy, ones(N), 'same');
    
    % Harris Corner Method
    k = 0.05;
    R1 = (Sx2.*Sy2 - Sxy.^2) - k*(Sx2 + Sy2).^2;

    % Step 4: Extract M best corner features with non-maximum suppression
    [sortedR, ind] = sort(R1(:), 'descend');
    [rows, cols] = ind2sub(size(R1), ind);
    
    % Mask to filter out corners that is near corners in the corner list
    suppressedMask = false(size(R1)); % Initialize the mask
    
    % Loop and get the M highest corners
    corners1 = [];
    for i = 1:length(sortedR)
        x = cols(i);
        y = rows(i);
        if sortedR(i) > 0 && ~suppressedMask(y, x)
            % Add corner to corner list
            corners1 = [corners1; [x, y]];
            % Mask out D surround neighbors
            suppressedMask(max(1, y-D):min(size(R1,1), y+D), max(1, x-D):min(size(R1,2), x+D)) = true;
        end
        
        % Break after have M amount of corners in the corner list
        if size(corners1, 1) == M
            break;
        end
    end


    % BONUS Eigen-Decomposition Method
    e1 = 0.5 * ((Sx2 + Sy2) - sqrt(4*Sxy.^2 + (Sx2 - Sy2).^2));
    e2 = 0.5 * ((Sx2 + Sy2) + sqrt(4*Sxy.^2 + (Sx2 - Sy2).^2));
    R2 = min(e1,e2);    % Take the smaller of the 2

    % Same Step 4: Extract M best corner features with non-maximum suppression
    [sortedR, ind] = sort(R2(:), 'descend');
    [rows, cols] = ind2sub(size(R2), ind);
    
    % Mask to filter out corners that is near corners in the corner list
    suppressedMask = false(size(R2)); % Initialize the mask
    
    % Loop and get the M highest corners
    corners2 = [];
    for i = 1:length(sortedR)
        x = cols(i);
        y = rows(i);
        if sortedR(i) > 0 && ~suppressedMask(y, x)
            % Add corner to corner list
            corners2 = [corners2; [x, y]];
            % Mask out D surround neighbors
            suppressedMask(max(1, y-D):min(size(R2,1), y+D), max(1, x-D):min(size(R2,2), x+D)) = true;
        end
        
        % Break after have M amount of corners in the corner list
        if size(corners2, 1) == M
            break;
        end
    end
    corners = corners2;
    R = R2;
    
    % Harris Corner Plot
    figure;
    % Subplot 1
    subplot(2, 2, 1);
    imshow(Image);
    hold on;
    boxSize = 10; % Size of the red box on the corners
    
    % Loop and draw box on each corner
    for i = 1:size(corners1, 1)
        x = corners1(i, 1);
        y = corners1(i, 2);
        rectangle('Position', [x-boxSize/2, y-boxSize/2, boxSize, boxSize], 'EdgeColor', 'r', 'LineWidth', 2);
    end
    
    hold off;
    title('Detected Corners - Harris Corner Method');
    
    % Subplot 2
    subplot(2, 2, 2);
    imshow(R1, []);
    title('R-score Image - Harris Corner Method');

    % Subplot 3
    subplot(2, 2, 3);
    imshow(Image);
    hold on;
    
    % Loop and draw box on each corner
    for i = 1:size(corners2, 1)
        x = corners2(i, 1);
        y = corners2(i, 2);
        rectangle('Position', [x-boxSize/2, y-boxSize/2, boxSize, boxSize], 'EdgeColor', 'r', 'LineWidth', 2);
    end
    
    hold off;
    title('Detected Corners - Eigen-Decomposition Method');
    
    % Subplot 4
    subplot(2, 2, 4);
    imshow(R2, []);
    title('R-score Image - Eigen-Decomposition Method');

    set(gcf, 'Position', [100, 100, 1200, 500]); % Adjust the position and size as needed


end
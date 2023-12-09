% Load images
leftGray = rgb2gray(imread('conesLeft.ppm'));
rightGray = rgb2gray(imread('conesRight.ppm'));

% Image I took myself
% leftGray = rgb2gray(imread('img2.jpg'));
% rightGray = rgb2gray(imread('img1.jpg'));

% % Display leftGray
% subplot(1, 2, 1);
% imshow(leftGray);
% title('Left Image');
% 
% % Display rightGray
% subplot(1, 2, 2);
% imshow(rightGray);
% title('Right Image');

% Matrix to store NCC values
numRows = size(leftGray, 1);
numColsLeft = size(leftGray, 2);
numColsRight = size(rightGray, 2);
nccMatrix = zeros(numRows, numColsRight - 4, numColsLeft - 4);  % Adjust dimensions

% Define patch size
patchSize = 5;

% Preallocate matrices for normalized patches
normalizedLeft = zeros(patchSize^2, numColsLeft - 4);
normalizedRight = zeros(patchSize^2, numColsRight - 4);

% Initialize disparity matrix
maxNumPoints = numColsRight - 6;
disparityMatrix = zeros(numRows, maxNumPoints);

% Iterate over rows
for y = 3:numRows-2  % Ignore top 2 and bottom 2 rows
    % Calculate mean and normalization factors for left patches
    for i = 3:numColsLeft-2
        leftPatch = extractPatch(leftGray, y, i, patchSize);
        normalizedLeft(:, i-2) = im2col(leftPatch, [patchSize patchSize]);  % Change to 25x1
    end
    meanLeft = mean(normalizedLeft, 2);
    normFactorLeft = sqrt(sum((normalizedLeft - meanLeft).^2));

    % Calculate mean and normalization factors for right patches
    for j = 3:numColsRight-2
        rightPatch = extractPatch(rightGray, y, j, patchSize);
        normalizedRight(:, j-2) = im2col(rightPatch, [patchSize patchSize]);  % Change to 25x1
    end
    meanRight = mean(normalizedRight, 2);
    normFactorRight = sqrt(sum((normalizedRight - meanRight).^2));

    % Normalize patches
    normalizedLeft = (normalizedLeft - meanLeft) ./ normFactorLeft;
    normalizedRight = (normalizedRight - meanRight) ./ normFactorRight;

    % Compute dissimilarities using matrix operations
    DSI = 1 - normalizedLeft' * normalizedRight;

    % Assign the dissimilarities to the nccMatrix
    nccMatrix(y, :, :) = DSI;

    % Set occlusion value
    occlusion = .11;

    % Create the cost matrix and extract the minimum cost path
    [C, M, pathP, pathQ] = createCostMatrix(squeeze(nccMatrix(y, :, :)), occlusion);

    % Compute disparity for the current row
    disparity = computeDisparity(pathP, pathQ);
    
    % Pad or truncate disparity array to ensure a consistent size
    validIndices = 1:min(maxNumPoints, length(disparity));
    disparityMatrix(y, 1:length(validIndices)) = disparity(validIndices);
end

% % Select the middle row
% middleRow = round(numRows / 2);
% 
% % Extract the dissimilarity matrix for the middle row
% nccMatrixMiddleRow = squeeze(nccMatrix(middleRow+3, :, :));
% 
% % % Display the dissimilarity matrix in grayscale
% figure;
% imagesc(nccMatrixMiddleRow);
% colormap('gray');  % Set the colormap to grayscale
% 
% % Add labels and title
% xlabel('Right Scan Line');
% ylabel('Left Scan Line');
% title('Normalized Cross-Correlation Matrix for Middle Row');
% 
% % Visualize the yellow line on the middle scan rows
% [C, M, pathP, pathQ] = createCostMatrix(nccMatrixMiddleRow, .11);
% visualizeMinimumCostPath(C, M, pathP, pathQ, nccMatrixMiddleRow);


% Flip image horizontally
disparityMatrixFlipped = fliplr(disparityMatrix);
% Calculate the range manually
disparityMin = min(disparityMatrixFlipped(:));
disparityMax = max(disparityMatrixFlipped(:));
disparityRange = disparityMax - disparityMin;

% Normalize and invert the values of the disparity matrix
normalizedDisparityMatrix = 64 - (disparityMatrixFlipped - disparityMin) / disparityRange * 64;

% Visualize the normalized and inverted disparity matrix in grayscale
figure;
imagesc(normalizedDisparityMatrix);
colormap('gray');  % Set the colormap to grayscale
xlabel('X-coordinate');
ylabel('Y-coordinate');
title('Final Disparity Matrix');


function disparity = computeDisparity(pathP, pathQ)
    % Extract the corresponding pixels from the left and right images along the path
    xl_values = pathQ;  % x-coordinate for the left image
    xr_values = pathP;  % y-coordinate for the left image

    % Initialize the disparity array
    disparity = zeros(size(xl_values));

    % Compute the disparity for each point on the path
    for k = 1:numel(xl_values)
        % Check for equality with the next point
        if k < numel(xl_values) && (xl_values(k) == xl_values(k+1))
            continue;  % Skip recording if consecutive points are equal
        end

        xl = xl_values(k);
        xr = xr_values(k);

        % Compute disparity using the formula Disp = xl - xr
        disparity(k) = xl - xr;
    end

    % Remove unused elements
    disparity = disparity(disparity ~= 0);
end

function [C, M, pathP, pathQ] = createCostMatrix(DSI, occlusion)
    [row, col] = size(DSI);
    
    % Initialize cost and direction matrices
    C = zeros(row, col);
    M = zeros(row, col);

    % Initialize the first row and column of the cost matrix
    for i = 1:row
        C(i, 1) = i * occlusion;
        M(i, 1) = 2; % Direction 2: Unmatched in left scanline
    end
    for j = 1:col
        C(1, j) = j * occlusion;
        M(1, j) = 3; % Direction 3: Unmatched in right scanline
    end

    % Fill in the cost and direction matrices
    for i = 2:row
        for j = 2:col
            % Calculate costs for three possible moves
            cost1 = C(i-1, j-1) + DSI(i, j);
            cost2 = C(i-1, j) + occlusion;
            cost3 = C(i, j-1) + occlusion;

            % Find the minimum cost
            [minCost, direction] = min([cost1, cost2, cost3]);

            % Update cost and direction matrices
            C(i, j) = minCost;
            M(i, j) = direction;
        end
    end
    
    % Extract the minimum cost path
    [pathP, pathQ] = extractMinimumCostPath(M);
end

function [pathP, pathQ] = extractMinimumCostPath(M)
    [p, q] = size(M);
    pEnd = p;
    qEnd = q;

    % Initialize arrays to store the path
    pathP = zeros(p*q, 1);
    pathQ = zeros(p*q, 1);
    pathIndex = 1;

    % Starting from the bottom-right corner
    while (pEnd > 0 && qEnd > 0)
        direction = M(pEnd, qEnd);

        % Store the current path
        pathP(pathIndex) = pEnd;
        pathQ(pathIndex) = qEnd;
        pathIndex = pathIndex + 1;

        % Update indices based on the chosen direction
        switch direction
            case 1
                % Matched, move diagonally
                pEnd = pEnd - 1;
                qEnd = qEnd - 1;
            case 2
                % Unmatched in left scanline, move upwards
                pEnd = pEnd - 1;
            case 3
                % Unmatched in right scanline, move leftwards
                qEnd = qEnd - 1;
        end
    end

    % Trim the excess zeros in the arrays
    pathP = pathP(1:pathIndex-1);
    pathQ = pathQ(1:pathIndex-1);
end

function patch = extractPatch(image, row, pixel, patchSize)
    halfSize = floor(patchSize / 2);
    patch = image(row-halfSize:row+halfSize, max(1, pixel - halfSize):min(end, pixel + halfSize));
end

function visualizeMinimumCostPath(C, M, pathP, pathQ, nccMatrixMiddleRow)
    % Display the cost matrix in grayscale
    figure;
    imagesc(C);
    colormap('gray');  % Set the colormap to grayscale

    % Add labels and title
    xlabel('Right Scan Line');
    ylabel('Left Scan Line');
    title('Cost Matrix for Middle Row');

    % Plot the minimum cost path on the cost matrix figure
    hold on;
    plot(pathQ, pathP, 'y-', 'LineWidth', 2);
    hold off;

    % Plot the minimum cost path on the original NCC matrix figure
    figure;
    imagesc(nccMatrixMiddleRow);
    colormap('gray');  % Set the colormap to grayscale

    % Add labels and title
    xlabel('Right Scan Line');
    ylabel('Left Scan Line');
    title('Normalized Cross-Correlation Matrix for Middle Row');

    % Plot the minimum cost path on top of the original NCC matrix figure
    hold on;
    plot(pathQ, pathP, 'y-', 'LineWidth', 2);
    hold off;
end

% Load images
I1 = imread('img1.tif');
I1 = double(rgb2gray(I1))/255;
I2 = imread('img2.tif');
I2 = double(rgb2gray(I2))/255;

% Display image 1 and get points
figure;
imshow(I1);
title('Select points for points1');
points1 = ginput; % Click on points in the image

% Display image 2 and get points
figure;
imshow(I2);
title('Select points for points2');
points2 = ginput; % Click on points in the image

% Convert points to integer format
points1 = round(points1);
points2 = round(points2);

% Pre-define points1 and points2 if you dont want to click
% points1 = [295,116;314,147;329,227;426,203;427,218];
% points2 = [139,118;157,151;173,231;270,207;270,222];

% Call the estimateHomography function
H = estimateHomography(points1, points2);

% Apply interpolation
warped_image1 = forwardWarping(I1, H, I2);
warped_image2 = backwardWarping(I1, H, I2, 'nearest');
warped_image3 = backwardWarping(I1, H, I2, 'bilinear');
warped_image4 = backwardWarping(I1, H, I2, 'interp2');

% Display the images and results as subplots instead
% figure;
% subplot(2, 3, 1);
% imshow(I1);
% hold on;
% plot(points1(:,1), points1(:,2), 'ro', 'MarkerSize', 10);
% title('Image 1 with Points 1');
% subplot(2, 3, 2);
% imshow(I2);
% hold on;
% plot(points2(:,1), points2(:,2), 'bo', 'MarkerSize', 10);
% title('Image 2 with Points 2');
% subplot(2, 3, 3);
% imshow(warped_image1);
% title('Forward Warping');
% subplot(2, 3, 4);
% imshow(warped_image2);
% title('Backward Warping - nearest');
% subplot(2, 3, 5);
% imshow(warped_image3);
% title('Backward Warping - bilinear');
% subplot(2, 3, 6);
% imshow(warped_image4);
% title('Backward Warping - interp2');

% Original Image 1 with Points 1
figure;
imshow(I1);
hold on;
plot(points1(:,1), points1(:,2), 'ro', 'MarkerSize', 10);

% Original Image 2 with Points 2
figure;
imshow(I2);
hold on;
plot(points2(:,1), points2(:,2), 'bo', 'MarkerSize', 10);


% Forward Warping
figure;
imshow(warped_image1);


% Backward Warping (Nearest Neighbor)
figure;
imshow(warped_image2);


% Backward Warping (Bilinear)
figure;
imshow(warped_image3);


% Backward Warping (interp2)
figure;
imshow(warped_image4);


% Part1
function H = estimateHomography(pts1, pts2)
    % Matrx we want to calculate
    A = [];
    % Loop for each points
    for i = 1:size(pts1, 1)
        % x, y, x_prime, y_prime
        x1 = pts1(i, 1);
        y1 = pts1(i, 2);
        x2 = pts2(i, 1);
        y2 = pts2(i, 2);
        %Calculate and Append for each row of A
        A = [A; x1, y1, 1, 0, 0, 0, -(x2*x1), -(x2*y1), -(x2)];
        A = [A; 0, 0, 0, x1, y1, 1, -(y2*x1), -(y2*y1), -(y2)];
    end
    % Normalize to ensure ||h|| = 1

    % SVD method
    [~, ~, V] = svd(A);
    H1 = reshape(V(:,end), 3, 3)';

    % Eign method
    [V, D] = eig(A' * A);
    [~, idx] = min(diag(D));
    h = V(:, idx);
    H2 = reshape(h, 3, 3)';
    H2 = H2 / norm(H2(:));
    
    %return SVD method, H1 and H2 should be the same anyway
    H=H1;
end

%Part 2.1
function warpIm = forwardWarping(im_src, H, im_dest)
    %Get size and initialize warp image
    [nrows_src, ncols_src] = size(im_src);
    warpIm = zeros(size(im_dest));
    [nrows_dest, ncols_dest] = size(warpIm);

    % Loop through each src pixel
    for x = 1:ncols_src
        for y = 1:nrows_src
            % Variable used for calculation
            p = [x; y; 1];
            p_prime = H * p;
            x_prime = p_prime(1) / p_prime(3);
            y_prime = p_prime(2) / p_prime(3);

            % Check if points are within bound
            if x_prime < 1 || x_prime > ncols_dest || y_prime < 1 || y_prime > nrows_dest
                continue;
            end
            
            % Calculated pixel intensity from source
            warpIm(round(y_prime), round(x_prime)) = im_src(y, x);
        end
    end
end

%Part2.2 & Part2.3
function warpIm = backwardWarping(im_src, H, im_dest, method)
    [nrows_src, ncols_src] = size(im_src);
    [nrows_dest, ncols_dest] = size(im_dest);
    warpIm = zeros(nrows_dest, ncols_dest);
    invH = inv(H);

    if strcmp(method, 'interp2')
        cols = ncols_src;
        rows = nrows_src;
        % Define scaling factors and translation values
        scale_x = 0.5;
        scale_y = 0.5;
        trans_x = cols / 2;
        trans_y = rows / 2;
        
        % Create a grid of coordinates
        [xi, yi] = meshgrid(1:cols, 1:rows);
        
        % Define the homography matrix
        h = [1 0 trans_x; 0 1 trans_y; 0 0 1] * [scale_x 0 0; 0 scale_y 0; 0 0 1] * [1 0 -trans_x; 0 1 -trans_y; 0 0 1];
        h_inv = invH; % get the inverse for use with interp2
        
        % Apply the homography transformation
        xx = (h_inv(1,1)*xi + h_inv(1,2)*yi + h_inv(1,3)) ./ (h_inv(3,1)*xi + h_inv(3,2)*yi + h_inv(3,3));
        yy = (h_inv(2,1)*xi + h_inv(2,2)*yi + h_inv(2,3)) ./ (h_inv(3,1)*xi + h_inv(3,2)*yi + h_inv(3,3));
            
        % Use interp2 for bilinear interpolation
        warpIm = interp2(im_src, xx, yy);
    else
        for y_prime = 1:nrows_dest
            for x_prime = 1:ncols_dest

                % Variables used for calculation 
                p_prime = [x_prime; y_prime; 1];
                p = invH * p_prime;
                x = p(1) / p(3);
                y = p(2) / p(3);

                % Check if points are within bound
                if x < 1 || x > ncols_src || y < 1 || y > nrows_src
                    continue;
                end

                % Branch to different interpolation method base on 'method'
                if strcmp(method, 'nearest')
                    % Nearest neighbor
                    warpIm(y_prime, x_prime) = im_src(round(y), round(x));
                elseif strcmp(method, 'bilinear')
                    % Bilinear
                    xfloor = floor(x);
                    xceil = ceil(x);
                    yfloor = floor(y);
                    yceil = ceil(y);
        
                    a = x - xfloor;
                    b = y - yfloor;
                    
                    % Formula for Bilinear weighted average
                    warpIm(y_prime, x_prime) = (1-a)*(1-b)*im_src(yfloor, xfloor) + ...
                                               (a)*(1-b)*im_src(yfloor, xceil) + ...
                                               (1-a)*(b)*im_src(yceil, xfloor) + ...
                                               (a)*(b)*im_src(yceil, xceil);
                else
                    error('Invalid interpolation method');
                end
                
            end
        end
    end
    
end
%



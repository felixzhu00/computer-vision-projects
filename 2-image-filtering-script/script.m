%--------------------------------------------------------------
% Part 1
%--------------------------------------------------------------
% Read the cameraman.tif image
image = imread('cameraman.tif');

% Define a 3x3 and 5x5 box filter
box1 = ones(3) / 9;
box2 = ones(5) / 25;
% Apply the box filter
filteredImage1 = imfilter(image, box1);
filteredImage2 = imfilter(image, box2);

% Visualize the result
figure;
subplot(1,3,1);
imshow(image);title('Original Image');
subplot(1,3,2);
imshow(filteredImage1);title('3x3 Box Filter Image');
subplot(1,3,3);
imshow(filteredImage2);title('5x5 Box Filter Image');

%--------------------------------------------------------------
% Part 2
%--------------------------------------------------------------
% Apply a Gaussian filter with sigma=1.2
sigma1 = 1.2;
sigma2 = 2;
halfwid1 = 3*sigma1
halfwid2 = 3*sigma2

% Create a meshgrid
[xx, yy] = meshgrid(-halfwid1:halfwid1, -halfwid1:halfwid1);
[xxx, yyy] = meshgrid(-halfwid2:halfwid2, -halfwid2:halfwid2);

% Calculate the Gaussian kernel
gau1 = exp(-1/(2*sigma1^2) * (xx.^2 + yy.^2));
gau2 = exp(-1/(2*sigma2^2) * (xxx.^2 + yyy.^2));
% Normalize the kernel
kernel1 = gau1 / sum(gau1(:));
kernel2 = gau2 / sum(gau2(:));

% Apply the Gaussian filter using imfilter
filteredImage3 = imfilter(double(image), kernel1, 'conv', 'replicate');
filteredImage4 = imfilter(double(image), kernel2, 'conv', 'replicate');

% Visualize the original and filtered images
figure;
subplot(1,3,1);
imshow(image);title('Original Image');

subplot(1,3,2);
imshow(uint8(filteredImage3));title(['Gaussian, sigma=1.2']);

subplot(1,3,3);
imshow(uint8(filteredImage4));title(['Gaussian, sigma=2']);
%--------------------------------------------------------------
% Part 3
%--------------------------------------------------------------
% Read the sarah.jpg
image = double(imread('sarah.jpg'));

% Define sigma_s and sigma_r
sigma_s = 3;
sigma_r = 25;

% Define halfwid
halfwid_s = ceil(3*sigma_s);

% Get image dimensions
[nrows, ncols] = size(image);

% Initialize filtered image
filteredImage = zeros(nrows, ncols);

for irow = 1:nrows
    for icol = 1:ncols
        I_p = image(irow, icol);
        p_x = icol;
        p_y = irow;
        
        % Define region of interest (ROI)
        roi_x = max(1, p_x - halfwid_s):min(ncols, p_x + halfwid_s);
        roi_y = max(1, p_y - halfwid_s):min(nrows, p_y + halfwid_s);
        
        I_q = image(roi_y, roi_x);
        [Q_x, Q_y] = meshgrid(roi_x, roi_y);
        
        % Calculate W_s and W_i
        W_s = exp(-((p_x - Q_x).^2 + (p_y - Q_y).^2) / (2*sigma_s^2));
        W_i = exp(-((I_p- I_q).^2) / (2*sigma_r^2));
        
        % Compute bilateral filter response
        tmp = sum(sum(W_s .* W_i .* I_q));
        Wp = sum(W_s(:) .* W_i(:));
        
        % Update filtered image
        filteredImage(irow, icol) = tmp / Wp;
    end
end

% Visualize the original images
figure;
subplot(1,2,1);
imshow(uint8(image));
title('Original Image');

% Splice the 3 rbg channels together
new_rows = size(filteredImage, 1);
new_cols = size(filteredImage, 2) / 3;
filteredImage = reshape(filteredImage, new_rows, new_cols, 3);

% Visualize the filtered images
subplot(1,2,2);
imshow(uint8(filteredImage));
title(['Filtered Image (Bilateral Filter, \sigma_s = ' num2str(sigma_s) ', \sigma_r = ' num2str(sigma_r) ')']);

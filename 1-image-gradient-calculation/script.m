% Read image and cast to double
I = imread('cameraman.tif');
I = double(I);

% Kernels for vertical edges and horizontal edges
vertical_kernel = [-1; 0; 1];
horizontal_kernel = [-1 0 1];

% Apply convolution to get edges
dy = imfilter(I, vertical_kernel, 'conv', 'same');
dx = imfilter(I, horizontal_kernel, 'conv', 'same');

% Visualize the dI/dx and dI/dy
figure;s
subplot(1,3,1)
imshow(uint8(dy)); title('dI/dy');
subplot(1,3,2)
imshow(uint8(dx)); title('dI/dx');

% Calculate the magnitude of the gradient
gradient_magnitude = sqrt(dy.^2 + dx.^2);

% Calculate the orientation of the gradient
gradient_orientation = atan2d(dy,dx);

% Visualize the results
subplot(1,3,3)
imshow(uint8(gradient_magnitude)); title('Gradient Magnitude');
figure;
imagesc(gradient_orientation); title('Gradient Orientation');colormap('jet');

% Make gradient_orientation more squared
caxis([-180 180]);
axis equal tight;

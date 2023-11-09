% Coordinates to be fitted
x = [17 23 35 37 45 57 61 70 80 84];
y = [81 72 73 58 50 56 36 32 32 19];

% Matrix A computed from part 2
n = length(x);
A = [sum(x.^2) sum(x.*y) sum(x);
     sum(x.*y) sum(y.^2) sum(y);
     sum(x) sum(y) n];

% Compute eigenvectors and eigenvalues
[V, D] = eig(A);

% Extract the eigenvector corresponding to the smallest eigenvalue
[min_eigenvalue, min_eigenvalue_index] = min(diag(D));
min_eigenvector = V(:, min_eigenvalue_index);

% Extract coefficients a, b, c
a = min_eigenvector(1);
b = min_eigenvector(2);
c = min_eigenvector(3);

% Visualize the points and fitted line
figure;
scatter(x, y, 'o', 'DisplayName', 'Data Points');
hold on;

% Fitted line equation: ax + by + c = 0
fitted_line = @(x) (-a/b)*x - c/b;
x_range = linspace(min(x), max(x), 100);
plot(x_range, fitted_line(x_range), 'r', 'DisplayName', 'Fitted Line');

title('Line Fitting');
xlabel('X');
ylabel('Y');
legend('show');
grid on;
hold off;

% Display coefficients
fprintf('Coefficients: a = %.4f, b = %.4f, c = %.4f\n', a, b, c);
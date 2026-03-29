%% Publication-style figure from a MATLAB built-in dataset
% Dataset: fisheriris (150 samples, 4 features, 3 species)
% Output files:
%   - iris_publication_figure.png (600 dpi)
%   - iris_publication_figure.pdf (vector)

clear; clc; close all;

%% 1) Load built-in dataset
load fisheriris; % variables: meas, species
X = meas;
group = species;
featureNames = {'Sepal Length', 'Sepal Width', 'Petal Length', 'Petal Width'};

%% 2) Standardize and compute PCA using SVD (base MATLAB, no toolbox PCA call)
mu = mean(X, 1);
sd = std(X, 0, 1);
Xz = (X - mu) ./ sd;

[U, S, V] = svd(Xz, 'econ');
scores = U * S;
eigenVals = (diag(S).^2) ./ (size(Xz, 1) - 1);
explained = 100 * eigenVals / sum(eigenVals);

[groupNames, ~, groupId] = unique(group, 'stable');
nGroups = numel(groupNames);

baseColors = [
    0.0000, 0.4470, 0.7410;
    0.8500, 0.3250, 0.0980;
    0.4660, 0.6740, 0.1880;
];
if nGroups <= size(baseColors, 1)
    colors = baseColors(1:nGroups, :);
else
    colors = lines(nGroups);
end
markers = {'o', 's', '^', 'd', 'v', '>', '<'};

%% 3) Create publication-style figure
fig = figure( ...
    'Color', 'w', ...
    'Units', 'centimeters', ...
    'Position', [2, 2, 18, 8], ...
    'Renderer', 'painters');

layout = tiledlayout(fig, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

% (A) PCA scatter + 95% confidence ellipses + loading vectors
ax1 = nexttile(layout, 1);
hold(ax1, 'on');

for k = 1:nGroups
    idx = (groupId == k);
    markerNow = markers{mod(k - 1, numel(markers)) + 1};

    scatter(ax1, scores(idx, 1), scores(idx, 2), 42, ...
        'Marker', markerNow, ...
        'MarkerEdgeColor', colors(k, :), ...
        'MarkerFaceColor', colors(k, :), ...
        'MarkerFaceAlpha', 0.65, ...
        'LineWidth', 0.8, ...
        'DisplayName', groupNames{k});

    % 95% ellipse in 2D using chi-square quantile for dof=2: 5.991464547
    C = cov(scores(idx, 1:2));
    center = mean(scores(idx, 1:2), 1);
    [vec, val] = eig(C);
    radii = sqrt(max(diag(val), 0));
    theta = linspace(0, 2*pi, 240);
    unitCircle = [cos(theta); sin(theta)];
    scale95 = sqrt(5.991464547);
    ellipse = vec * diag(radii) * unitCircle * scale95;

    plot(ax1, center(1) + ellipse(1, :), center(2) + ellipse(2, :), ...
        'Color', colors(k, :), ...
        'LineWidth', 1.3, ...
        'HandleVisibility', 'off');
end

arrowScale = 2.2;
for j = 1:numel(featureNames)
    quiver(ax1, 0, 0, V(j, 1) * arrowScale, V(j, 2) * arrowScale, 0, ...
        'Color', [0.15, 0.15, 0.15], ...
        'LineWidth', 1.2, ...
        'MaxHeadSize', 0.35, ...
        'HandleVisibility', 'off');

    text(ax1, V(j, 1) * arrowScale * 1.08, V(j, 2) * arrowScale * 1.08, featureNames{j}, ...
        'FontSize', 9, ...
        'Color', [0.15, 0.15, 0.15], ...
        'HorizontalAlignment', 'center');
end

axis(ax1, 'equal');
grid(ax1, 'on');
box(ax1, 'on');
xlabel(ax1, sprintf('PC1 (%.1f%% variance)', explained(1)));
ylabel(ax1, sprintf('PC2 (%.1f%% variance)', explained(2)));
title(ax1, '(A) PCA scores with 95% confidence ellipses');
legend(ax1, 'Location', 'best');

% (B) Heatmap of species-level mean z-scores
ax2 = nexttile(layout, 2);

groupMeanZ = zeros(nGroups, size(Xz, 2));
for k = 1:nGroups
    groupMeanZ(k, :) = mean(Xz(groupId == k, :), 1);
end

imagesc(ax2, groupMeanZ);
colormap(ax2, parula(256));
caxis(ax2, [-2, 2]); % fixed scale for easier cross-plot comparison
cb = colorbar(ax2);
cb.Label.String = 'Mean z-score';

xticks(ax2, 1:numel(featureNames));
xticklabels(ax2, featureNames);
xtickangle(ax2, 28);
yticks(ax2, 1:nGroups);
yticklabels(ax2, groupNames);
title(ax2, '(B) Species-level feature profile');
box(ax2, 'on');

for r = 1:size(groupMeanZ, 1)
    for c = 1:size(groupMeanZ, 2)
        if abs(groupMeanZ(r, c)) > 0.9
            txtColor = [1, 1, 1];
        else
            txtColor = [0.1, 0.1, 0.1];
        end
        text(ax2, c, r, sprintf('%.2f', groupMeanZ(r, c)), ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'middle', ...
            'FontSize', 9, ...
            'Color', txtColor);
    end
end

set([ax1, ax2], ...
    'FontName', 'Times New Roman', ...
    'FontSize', 10, ...
    'LineWidth', 1.0, ...
    'TickDir', 'out');

title(layout, 'Fisher Iris Dataset: Publication-style Overview', ...
    'FontName', 'Times New Roman', ...
    'FontSize', 12, ...
    'FontWeight', 'bold');

%% 4) Export high-resolution outputs
thisFile = mfilename('fullpath');
if isempty(thisFile)
    outDir = pwd;
else
    outDir = fileparts(thisFile);
end

pngFile = fullfile(outDir, 'iris_publication_figure.png');
pdfFile = fullfile(outDir, 'iris_publication_figure.pdf');

exportgraphics(fig, pngFile, 'Resolution', 600);
exportgraphics(fig, pdfFile, 'ContentType', 'vector');

fprintf('Saved figure to:\n%s\n%s\n', pngFile, pdfFile);

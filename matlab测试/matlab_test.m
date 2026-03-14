clear; clc; close all;

% 中国地图绘制脚本（优先使用同目录高精度行政区边界）
% 使用方式：
% 1) 把中国行政区 shp 数据放在本脚本同目录（推荐县级/市级/省级）
% 2) 运行脚本
% 3) 输出 china_detailed_map.png

scriptPath = mfilename('fullpath');
scriptDir = fileparts(scriptPath);

% 优先级：县级 > 市级 > 省级（可按你的数据文件名补充）
candidates = {
    'CHN_adm3.shp', 'gadm41_CHN_3.shp', 'china_county.shp', 'county.shp', ...
    'CHN_adm2.shp', 'gadm41_CHN_2.shp', 'china_city.shp',   'city.shp',   ...
    'CHN_adm1.shp', 'gadm41_CHN_1.shp', 'china_province.shp','province.shp'
};

shpFile = '';
for i = 1:numel(candidates)
    fp = fullfile(scriptDir, candidates{i});
    if exist(fp, 'file')
        shpFile = fp;
        break;
    end
end

hasMapToolbox = license('test', 'MAP_Toolbox');

fig = figure('Color', 'w', 'Position', [100 60 1300 900]);

if ~isempty(shpFile)
    % 有高精度矢量边界：直接绘制
    if hasMapToolbox
        S = shaperead(shpFile, 'UseGeoCoords', true);

        ax1 = axes('Position', [0.05 0.08 0.82 0.86]);
        worldmap([18 54], [73 136]);
        setm(ax1, 'FFaceColor', [0.95 0.97 1.00], 'Frame', 'on', 'Grid', 'on');
        geoshow(S, 'FaceColor', [0.90 0.94 0.98], 'EdgeColor', [0.10 0.20 0.35], 'LineWidth', 0.35);
        title('中国行政区详细地图（自动读取本地高精度 shp）', 'FontSize', 14, 'FontWeight', 'bold');

        % 南海附图
        ax2 = axes('Position', [0.72 0.12 0.22 0.28]);
        worldmap([3 26], [105 125]);
        setm(ax2, 'FFaceColor', [0.95 0.97 1.00], 'Frame', 'on', 'Grid', 'on');
        geoshow(S, 'FaceColor', [0.90 0.94 0.98], 'EdgeColor', [0.10 0.20 0.35], 'LineWidth', 0.30);
        title('南海附图', 'FontSize', 10);
    else
        % 无 Mapping Toolbox：使用基础绘图能力
        T = readgeotable(shpFile);

        ax1 = axes('Position', [0.05 0.08 0.82 0.86]);
        hold(ax1, 'on');
        axis(ax1, [73 136 18 54]);
        axis(ax1, 'equal');
        grid(ax1, 'on');
        box(ax1, 'on');
        title(ax1, '中国行政区详细地图（基础模式）', 'FontSize', 14, 'FontWeight', 'bold');
        xlabel(ax1, '经度'); ylabel(ax1, '纬度');

        geos = T.Shape;
        for k = 1:height(T)
            g = geos(k);
            if isprop(g, 'Longitude') && isprop(g, 'Latitude')
                patch(g.Longitude, g.Latitude, [0.90 0.94 0.98], ...
                    'EdgeColor', [0.10 0.20 0.35], 'LineWidth', 0.25);
            end
        end

        ax2 = axes('Position', [0.72 0.12 0.22 0.28]);
        hold(ax2, 'on');
        axis(ax2, [105 125 3 26]);
        axis(ax2, 'equal');
        grid(ax2, 'on');
        box(ax2, 'on');
        title(ax2, '南海附图', 'FontSize', 10);
        xlabel(ax2, '经度'); ylabel(ax2, '纬度');

        for k = 1:height(T)
            g = geos(k);
            if isprop(g, 'Longitude') && isprop(g, 'Latitude')
                patch(g.Longitude, g.Latitude, [0.90 0.94 0.98], ...
                    'EdgeColor', [0.10 0.20 0.35], 'LineWidth', 0.20);
            end
        end
    end

    [~, n, e] = fileparts(shpFile);
    annotation('textbox', [0.05 0.01 0.9 0.04], 'String', ...
        ['数据源：', n, e, '（同目录本地文件）'], ...
        'EdgeColor', 'none', 'FontSize', 9, 'Color', [0.2 0.2 0.2]);
else
    % 未提供高精度 shp 时的回退方案
    load coastlines;

    ax1 = axes('Position', [0.05 0.08 0.82 0.86]);
    hold(ax1, 'on');
    plot(coastlon, coastlat, 'Color', [0.10 0.20 0.35], 'LineWidth', 0.7);
    axis(ax1, [73 136 18 54]);
    axis(ax1, 'equal');
    grid(ax1, 'on');
    box(ax1, 'on');
    title(ax1, '中国地图（请放置高精度 shp 以获得最详细效果）', 'FontSize', 14, 'FontWeight', 'bold');
    xlabel(ax1, '经度'); ylabel(ax1, '纬度');

    ax2 = axes('Position', [0.72 0.12 0.22 0.28]);
    hold(ax2, 'on');
    plot(coastlon, coastlat, 'Color', [0.10 0.20 0.35], 'LineWidth', 0.6);
    axis(ax2, [105 125 3 26]);
    axis(ax2, 'equal');
    grid(ax2, 'on');
    box(ax2, 'on');
    title(ax2, '南海附图', 'FontSize', 10);

    annotation('textbox', [0.05 0.01 0.9 0.04], 'String', ...
        '未检测到本地中国行政区 shp（如 gadm41_CHN_3.shp）。已绘制海岸线示意图。', ...
        'EdgeColor', 'none', 'FontSize', 9, 'Color', [0.65 0.1 0.1]);
end

outFile = fullfile(scriptDir, 'china_detailed_map.png');
exportgraphics(fig, outFile, 'Resolution', 300);
disp(['地图已保存到: ', outFile]);

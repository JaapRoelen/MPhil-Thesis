clc;
clear;

%% Load data
data_lending   = readtable('Cost of borrowing for households for house purchase , Euro area, Monthly.xlsx');
data_deposit   = readtable('Bank interest rates - deposits from households with an agreed maturity (new business) , Monthly.xlsx');
data_euribor   = readtable('Euribor 3-month - Historical close, average of observations through period, Euro area, Monthly.xlsx');
data_gdp       = readtable('Gross domestic product at market prices, volume2.xlsx');
T = readtable('prc_hicp_manr_excluding energy, food, alcohol and tobacco.xlsx');


%% Get inflation table to right format
colNames = T.Properties.VariableNames;
keepCols = true(1, width(T));
for i = 1:length(colNames)
    if startsWith(colNames{i}, 'Var')
        keepCols(i) = false;
    end
end
T = T(:, keepCols);

countries_hicp = T{:, 1};
dates_hicp     = T.Properties.VariableNames(2:end);

numCols = width(T) - 1;
data_hicp = NaN(height(T), numCols);
for i = 1:numCols
    col = T{:, i+1};
    if iscell(col)
        col = strrep(col, ':', '');
        col = str2double(col);
    end
    data_hicp(:, i) = col;
end

T_transposed = array2table(data_hicp', ...
    'VariableNames', matlab.lang.makeValidName(countries_hicp), ...
    'RowNames', dates_hicp);
writetable(T_transposed, 'output_transposed.xlsx', 'WriteRowNames', true);

data_inflation = T_transposed;
% Comment away below if Core HICP, do not comment away if full HICP
% data_inflation = readtable('HICP Inflation rate - Total - Annual rate of change, Euro area, Monthly.xlsx');

%% ================================
%% COUNTRIES
%% ================================

% Countries for plotting
countries = {'Greece_GR_', 'Malta_MT_','Portugal_PT_', 'Slovenia_SI_' ...
              'Euro_area_'};
legend_labels = strtrim(strrep(countries, '_', ' '));

% All countries for summary statistics
all_countries = {'Austria_AT_',  'Belgium_BE_',  'Cyprus_CY_', 'Germany_DE_', ...
                 'Estonia_EE_', 'Spain_ES_', 'Finland_FI_', 'France_FR_', ...
                 'Greece_GR_', 'Euro_area_', ...
                 'Ireland_IE_', 'Italy_IT_', 'Lithuania_LT_', 'Luxembourg_LU_', ...
                 'Latvia_LV_', 'Malta_MT_', 'Netherlands_NL_', 'Portugal_PT_', ...
                 'Slovakia_SK_','Slovenia_SI_'};
all_labels = {'Austria', 'Belgium', 'Cyprus', 'Germany', 'Estonia', 'Spain', ...
              'Finland', 'France', 'Greece', 'Euro area 20', 'Ireland', 'Italy', ...
              'Lithuania', 'Luxembourg', 'Latvia', 'Malta', 'Netherlands', ...
              'Portugal', 'Slovakia','Slovenia'};

%% ================================
%% STEP 1: PREPARE MONTHLY DATA
%% ================================
dates_monthly = datetime(2003,1,1) + calmonths(0:275);
euribor       = data_euribor.Euribor;

TT_euribor   = timetable(dates_monthly', euribor, 'VariableNames', {'Euribor'});
TT_euribor_q = retime(TT_euribor, 'quarterly', 'mean');
dates_q      = TT_euribor_q.Time;

%% Spreads and rates for ALL countries
deposit_spread_all = table();  lending_spread_all = table();
deposit_rates_all  = table();  lending_rates_all  = table();
deposit_spread_all.Date = dates_monthly';
lending_spread_all.Date = dates_monthly';
deposit_rates_all.Date  = dates_monthly';
lending_rates_all.Date  = dates_monthly';

for i = 1:length(all_countries)
    c = all_countries{i};
    try
        dep_rate  = data_deposit.(c);
        lend_rate = data_lending.(c);
        deposit_spread_all.(c) = euribor - dep_rate;
        lending_spread_all.(c) = lend_rate - euribor;
        deposit_rates_all.(c)  = dep_rate;
        lending_rates_all.(c)  = lend_rate;
    catch
        warning('Spread data not found for: %s', c);
        deposit_spread_all.(c) = NaN(length(dates_monthly), 1);
        lending_spread_all.(c) = NaN(length(dates_monthly), 1);
        deposit_rates_all.(c)  = NaN(length(dates_monthly), 1);
        lending_rates_all.(c)  = NaN(length(dates_monthly), 1);
    end
end

TT_dep_all      = table2timetable(deposit_spread_all);
TT_lend_all     = table2timetable(lending_spread_all);
TT_dep_raw_all  = table2timetable(deposit_rates_all);
TT_lend_raw_all = table2timetable(lending_rates_all);

TT_dep_q_all      = retime(TT_dep_all,      'quarterly', 'mean');
TT_lend_q_all     = retime(TT_lend_all,     'quarterly', 'mean');
TT_dep_raw_q_all  = retime(TT_dep_raw_all,  'quarterly', 'mean');
TT_lend_raw_q_all = retime(TT_lend_raw_all, 'quarterly', 'mean');

%% Spreads and rates for plot countries
deposit_spread = table();  lending_spread = table();
deposit_rates  = table();  lending_rates  = table();
deposit_spread.Date = dates_monthly';
lending_spread.Date = dates_monthly';
deposit_rates.Date  = dates_monthly';
lending_rates.Date  = dates_monthly';

for i = 1:length(countries)
    c = countries{i};
    dep_rate  = data_deposit.(c);
    lend_rate = data_lending.(c);
    deposit_spread.(c) = euribor - dep_rate;
    lending_spread.(c) = lend_rate - euribor;
    deposit_rates.(c)  = dep_rate;
    lending_rates.(c)  = lend_rate;
end

TT_dep      = table2timetable(deposit_spread);
TT_lend     = table2timetable(lending_spread);
TT_dep_raw  = table2timetable(deposit_rates);
TT_lend_raw = table2timetable(lending_rates);

TT_dep_q      = retime(TT_dep,      'quarterly', 'mean');
TT_lend_q     = retime(TT_lend,     'quarterly', 'mean');
TT_dep_raw_q  = retime(TT_dep_raw,  'quarterly', 'mean');
TT_lend_raw_q = retime(TT_lend_raw, 'quarterly', 'mean');

%% ================================
%% STEP 2: PREPARE INFLATION (quarterly)
%% ================================

%% All countries
inflation_monthly_all = table();
inflation_monthly_all.Date = dates_monthly';
for i = 1:length(all_countries)
    c = all_countries{i};
    try
        inflation_monthly_all.(c) = data_inflation.(c);
    catch
        warning('Inflation data not found for: %s', c);
        inflation_monthly_all.(c) = NaN(length(dates_monthly), 1);
    end
end
TT_infl_all   = table2timetable(inflation_monthly_all);
TT_infl_q_all = retime(TT_infl_all, 'quarterly', 'mean');

%% Plot countries
inflation_monthly = table();
inflation_monthly.Date = dates_monthly';
for i = 1:length(countries)
    c = countries{i};
    inflation_monthly.(c) = data_inflation.(c);
end
TT_infl   = table2timetable(inflation_monthly);
TT_infl_q = retime(TT_infl, 'quarterly', 'mean');

%% ================================
%% STEP 3: TAYLOR RULE PARAMETERS
%% ================================
r_star   = 0.5;
pi_star  = 2.0;
C_pi     = 0.5;
C_y      = 0.5;
omega_D  =  0.75;
omega_L  = -0.75;

%% ================================
%% TIME FILTER
%% ================================
date_start    = datetime(2008, 1, 1);
date_end_plot = datetime(2012, 12, 31);

time_idx_plot = dates_q >= date_start & dates_q <= date_end_plot;
dates_q_plot  = dates_q(time_idx_plot);

%% Helper: set one x-tick per year, labelled with the year only
setYearTicks = @(dq) set(gca, ...
    'XTick', datetime(year(dq(1)),1,1) : calyears(1) : datetime(year(dq(end)),1,1));

%% ================================
%% STEP 4: COMPUTE OUTPUT GAPS + TAYLOR RATES
%% ================================
T = length(dates_q);

%% Output gaps for ALL countries
output_gaps_all = array2timetable(NaN(T, length(all_countries)), ...
                  'RowTimes', dates_q, 'VariableNames', all_countries);
for i = 1:length(all_countries)
    c = all_countries{i};
    try
        gdp_raw   = data_gdp.(c);
        valid_idx = ~isnan(gdp_raw);
        gdp_valid = gdp_raw(valid_idx);
        log_gdp   = log(gdp_valid);
        [~, cycle] = hpfilter(log_gdp, 'Smoothing', 1600);
        output_gap_full              = cycle * 100;
        output_gap_padded            = NaN(size(gdp_raw));
        output_gap_padded(valid_idx) = output_gap_full;
        n = min(length(output_gap_padded), T);
        output_gaps_all.(c)(1:n)     = output_gap_padded(1:n);
    catch
        warning('GDP data not found for: %s', c);
    end
end

%% Output gaps + Taylor rates for plot countries
taylor_simple    = array2timetable(NaN(T, length(countries)), ...
                   'RowTimes', dates_q, 'VariableNames', countries);
taylor_augmented = array2timetable(NaN(T, length(countries)), ...
                   'RowTimes', dates_q, 'VariableNames', countries);
output_gaps      = array2timetable(NaN(T, length(countries)), ...
                   'RowTimes', dates_q, 'VariableNames', countries);

for i = 1:length(countries)
    c = countries{i};

    gdp_raw   = data_gdp.(c);
    valid_idx = ~isnan(gdp_raw);
    gdp_valid = gdp_raw(valid_idx);
    log_gdp   = log(gdp_valid);
    [~, cycle] = hpfilter(log_gdp, 'Smoothing', 1600);
    output_gap_full              = cycle * 100;
    output_gap_padded            = NaN(size(gdp_raw));
    output_gap_padded(valid_idx) = output_gap_full;
    n = min(length(output_gap_padded), T);
    output_gaps.(c)(1:n) = output_gap_padded(1:n);

    pi_t    = TT_infl_q.(c);
    dep_sp  = TT_dep_q.(c);
    lend_sp = TT_lend_q.(c);
    n_q     = min(length(pi_t), T);

    for t = 1:n_q
        og  = output_gaps.(c)(t);
        pit = pi_t(t);
        if ~isnan(og) && ~isnan(pit)
            taylor_simple.(c)(t) = r_star + pit ...
                + C_pi * (pit - pi_star) ...
                + C_y  * og;
        end
    end

    for t = 1:n_q
        og     = output_gaps.(c)(t);
        pit    = pi_t(t);
        dep_t  = dep_sp(t);
        lend_t = lend_sp(t);
        if ~isnan(og) && ~isnan(pit) && ~isnan(dep_t) && ~isnan(lend_t)
            taylor_augmented.(c)(t) = r_star + pit ...
                + C_pi    * (pit - pi_star) ...
                + C_y     * og ...
                + omega_D * dep_t ...
                + omega_L * lend_t;
        end
    end
end

%% ================================
%% TAYLOR RATES — ALL COUNTRIES
%% ================================

taylor_simple_all    = array2timetable(NaN(T, length(all_countries)), ...
                       'RowTimes', dates_q, 'VariableNames', all_countries);
taylor_augmented_all = array2timetable(NaN(T, length(all_countries)), ...
                       'RowTimes', dates_q, 'VariableNames', all_countries);

for i = 1:length(all_countries)
    c = all_countries{i};

    pi_t    = TT_infl_q_all.(c);
    dep_sp  = TT_dep_q_all.(c);
    lend_sp = TT_lend_q_all.(c);
    n_q     = min(length(pi_t), T);

    for t = 1:n_q
        og  = output_gaps_all.(c)(t);
        pit = pi_t(t);
        if ~isnan(og) && ~isnan(pit)
            taylor_simple_all.(c)(t) = r_star + pit ...
                + C_pi * (pit - pi_star) ...
                + C_y  * og;
        end
    end

    for t = 1:n_q
        og     = output_gaps_all.(c)(t);
        pit    = pi_t(t);
        dep_t  = dep_sp(t);
        lend_t = lend_sp(t);
        if ~isnan(og) && ~isnan(pit) && ~isnan(dep_t) && ~isnan(lend_t)
            taylor_augmented_all.(c)(t) = r_star + pit ...
                + C_pi    * (pit - pi_star) ...
                + C_y     * og ...
                + omega_D * dep_t ...
                + omega_L * lend_t;
        end
    end
end

euribor_q      = TT_euribor_q.Euribor;
euribor_q_plot = euribor_q(time_idx_plot);
colors         = lines(length(countries));
markers        = {'o', 's', '^', 'd', 'v', 'p'};
marker_step    = 1;

%% ================================
%% FIGURE 1: DEPOSIT SPREADS
%% ================================
figure('Name', 'Deposit Spreads');
hold on;
for i = 1:length(countries)
    plot(dates_q_plot, TT_dep_q.(countries{i})(time_idx_plot), ...
         'Color', colors(i,:), 'LineWidth', 1, ...
         'Marker', markers{mod(i-1,length(markers))+1}, ...
         'MarkerSize', 4, 'MarkerIndices', 1:marker_step:length(dates_q_plot), ...
         'DisplayName', legend_labels{i});
end
plot(dates_q_plot, euribor_q_plot, 'k--', 'LineWidth', 1.2, 'DisplayName', 'Euribor 3m');
title('Deposit Spreads');
xlabel('Date'); ylabel('Spread (pp)');
legend('Location', 'best');
grid on;
setYearTicks(dates_q_plot);
xtickformat('yyyy');

%% ================================
%% FIGURE 2: LENDING SPREADS
%% ================================
figure('Name', 'Lending Spreads');
hold on;
for i = 1:length(countries)
    plot(dates_q_plot, TT_lend_q.(countries{i})(time_idx_plot), ...
         'Color', colors(i,:), 'LineWidth', 1, ...
         'Marker', markers{mod(i-1,length(markers))+1}, ...
         'MarkerSize', 4, 'MarkerIndices', 1:marker_step:length(dates_q_plot), ...
         'DisplayName', legend_labels{i});
end
plot(dates_q_plot, euribor_q_plot, 'k--', 'LineWidth', 1.2, 'DisplayName', 'Euribor 3m');
title('Lending Spreads');
xlabel('Date'); ylabel('Spread (pp)');
legend('Location', 'best');
grid on;
setYearTicks(dates_q_plot);
xtickformat('yyyy');

%% ================================
%% FIGURE 3: DEPOSIT RATES + EURIBOR
%% ================================
figure('Name', 'Deposit Rates');
hold on;
for i = 1:length(countries)
    plot(dates_q_plot, TT_dep_raw_q.(countries{i})(time_idx_plot), ...
         'Color', colors(i,:), 'LineWidth', 1, ...
         'Marker', markers{mod(i-1,length(markers))+1}, ...
         'MarkerSize', 4, 'MarkerIndices', 1:marker_step:length(dates_q_plot), ...
         'DisplayName', legend_labels{i});
end
plot(dates_q_plot, euribor_q_plot, 'k--', 'LineWidth', 1.2, 'DisplayName', 'Euribor 3m');
title('Deposit Rates');
xlabel('Date'); ylabel('Interest Rate (%)');
legend('Location', 'best');
grid on;
setYearTicks(dates_q_plot);
xtickformat('yyyy');

%% ================================
%% FIGURE 4: LENDING RATES + EURIBOR
%% ================================
figure('Name', 'Lending Rates');
hold on;
for i = 1:length(countries)
    plot(dates_q_plot, TT_lend_raw_q.(countries{i})(time_idx_plot), ...
         'Color', colors(i,:), 'LineWidth', 1, ...
         'Marker', markers{mod(i-1,length(markers))+1}, ...
         'MarkerSize', 4, 'MarkerIndices', 1:marker_step:length(dates_q_plot), ...
         'DisplayName', legend_labels{i});
end
plot(dates_q_plot, euribor_q_plot, 'k--', 'LineWidth', 1.2, 'DisplayName', 'Euribor 3m');
title('Lending Rates');
xlabel('Date'); ylabel('Interest Rate (%)');
legend('Location', 'best');
grid on;
setYearTicks(dates_q_plot);
xtickformat('yyyy');


%% Shared y-limits so Simple vs Augmented (Figures 5 & 6) are visually comparable
simple_vals_mat = NaN(length(dates_q_plot), length(countries));
aug_vals_mat    = NaN(length(dates_q_plot), length(countries));
for i = 1:length(countries)
    simple_vals_mat(:,i) = taylor_simple.(countries{i})(time_idx_plot);
    aug_vals_mat(:,i)    = taylor_augmented.(countries{i})(time_idx_plot);
end
combined_vals = [simple_vals_mat(:); aug_vals_mat(:)];
y_lo  = min(combined_vals, [], 'omitnan');
y_hi  = max(combined_vals, [], 'omitnan');
y_pad = 0.05 * (y_hi - y_lo);
taylor_common_ylim = [y_lo - y_pad, y_hi + y_pad];

%% ================================
%% FIGURE 5: SIMPLE TAYLOR — PLOT COUNTRIES
%% ================================
figure('Name', 'Simple Taylor Rates');
hold on;
for i = 1:length(countries)
    plot(dates_q_plot, taylor_simple.(countries{i})(time_idx_plot), ...
         'Color', colors(i,:), 'LineWidth', 1, ...
         'Marker', markers{mod(i-1,length(markers))+1}, ...
         'MarkerSize', 4, 'MarkerIndices', 1:marker_step:length(dates_q_plot), ...
         'DisplayName', legend_labels{i});
end
title('Simple Taylor Rates');
xlabel('Date'); ylabel('Rate (%)');
ylim(taylor_common_ylim);
legend('Location', 'best');
grid on;
setYearTicks(dates_q_plot);
xtickformat('yyyy');

%% ================================
%% FIGURE 6: AUGMENTED TAYLOR — PLOT COUNTRIES
%% ================================
figure('Name', 'Taylor Rates of Imperfect Banking Competition');
hold on;
for i = 1:length(countries)
    plot(dates_q_plot, taylor_augmented.(countries{i})(time_idx_plot), ...
         'Color', colors(i,:), 'LineWidth', 1, ...
         'Marker', markers{mod(i-1,length(markers))+1}, ...
         'MarkerSize', 4, 'MarkerIndices', 1:marker_step:length(dates_q_plot), ...
         'DisplayName', legend_labels{i});
end
title('Taylor Rates of Imperfect Banking Competition');
xlabel('Date'); ylabel('Rate (%)');
ylim(taylor_common_ylim);
legend('Location', 'best');
grid on;
setYearTicks(dates_q_plot);
xtickformat('yyyy');

%% ================================
%% FIGURE 7: OVERVIEW GRID — PLOT COUNTRIES
%% ================================
figure('Name', 'Taylor Rates Overview — Plot Countries');
tiledlayout(ceil(length(countries)/2), 2, 'TileSpacing', 'compact', 'Padding', 'compact');

for i = 1:length(countries)
    c     = countries{i};
    label = legend_labels{i};

    nexttile;
    hold on;
    plot(dates_q_plot, taylor_simple.(c)(time_idx_plot),    'b-',  'LineWidth', 1, ...
         'Marker', 'o', 'MarkerSize', 4, 'MarkerIndices', 1:marker_step:length(dates_q_plot));
    plot(dates_q_plot, taylor_augmented.(c)(time_idx_plot), 'r-',  'LineWidth', 1, ...
         'Marker', 's', 'MarkerSize', 4, 'MarkerIndices', 1:marker_step:length(dates_q_plot));
    title(label);
    xlabel('Date'); ylabel('Rate (%)');
    grid on;
    setYearTicks(dates_q_plot);
    xtickformat('yyyy');
end
lgd = legend({'Simple TR', 'Augmented TR'}, ...
             'Orientation', 'horizontal', 'FontSize', 9);
lgd.Layout.Tile = 'south';

%% ================================
%% FIGURE 8: OUTPUT GAPS — PLOT COUNTRIES
%% ================================
figure('Name', 'Output gaps across the EU');
hold on;
for i = 1:length(countries)
    plot(dates_q_plot, output_gaps.(countries{i})(time_idx_plot), ...
         'Color', colors(i,:), 'LineWidth', 1, ...
         'Marker', markers{mod(i-1,length(markers))+1}, ...
         'MarkerSize', 4, 'MarkerIndices', 1:marker_step:length(dates_q_plot), ...
         'DisplayName', legend_labels{i});
end
title('Output Gaps — Plot Countries (HP Filter)');
xlabel('Date'); ylabel('Output Gap (%)');
legend('Location', 'best');
grid on;
setYearTicks(dates_q_plot);
xtickformat('yyyy');

%% ================================
%% FIGURE 8: INFLATION — PLOT COUNTRIES
%% ================================
figure('Name', 'Inflation across the EU');
hold on;
for i = 1:length(countries)
    plot(dates_q_plot, TT_infl_q.(countries{i})(time_idx_plot), ...
         'Color', colors(i,:), 'LineWidth', 1, ...
         'Marker', markers{mod(i-1,length(markers))+1}, ...
         'MarkerSize', 4, 'MarkerIndices', 1:marker_step:length(dates_q_plot), ...
         'DisplayName', legend_labels{i});
end
yline(2, 'k--', 'LineWidth', 0.9, 'DisplayName', 'ECB Target (2%)');
title('HICP Inflation — Plot Countries');
xlabel('Date'); ylabel('Inflation (%)');
legend('Location', 'best');
grid on;
setYearTicks(dates_q_plot);
xtickformat('yyyy');

%% ================================
%% FIGURE 9: CROSS-SECTIONAL DISPERSION — ALL COUNTRIES
%% ================================
n_q_plot = sum(time_idx_plot);
ts_mat   = NaN(n_q_plot, length(all_countries));
ta_mat   = NaN(n_q_plot, length(all_countries));
for i = 1:length(all_countries)
    ts_mat(:,i) = taylor_simple_all.(all_countries{i})(time_idx_plot);
    ta_mat(:,i) = taylor_augmented_all.(all_countries{i})(time_idx_plot);
end

xc_std_simple    = NaN(n_q_plot, 1);
xc_std_augmented = NaN(n_q_plot, 1);
for t = 1:n_q_plot
    row_s = ts_mat(t, ~isnan(ts_mat(t,:)));
    row_a = ta_mat(t, ~isnan(ta_mat(t,:)));
    if numel(row_s) > 1, xc_std_simple(t)    = std(row_s); end
    if numel(row_a) > 1, xc_std_augmented(t) = std(row_a); end
end

figure('Name', 'Cross-sectional dispersion of Taylor rates');
hold on;
plot(dates_q_plot, xc_std_simple, 'b-', 'LineWidth', 1, ...
     'Marker', 'o', 'MarkerSize', 4, 'MarkerIndices', 1:marker_step:length(dates_q_plot), ...
     'DisplayName', 'Simple TR');
plot(dates_q_plot, xc_std_augmented, 'r-', 'LineWidth', 1, ...
     'Marker', 's', 'MarkerSize', 4, 'MarkerIndices', 1:marker_step:length(dates_q_plot), ...
     'DisplayName', 'Augmented TR');
title('Cross-sectional std of optimal Taylor rates — all euro area members');
xlabel('Date'); ylabel('Std dev (pp)');
legend('Location', 'best');
grid on;
setYearTicks(dates_q_plot);
xtickformat('yyyy');

%% ================================
%% SUMMARY STATISTICS (filtered sample, all countries)
%% ================================
varNames = {'Mean', 'Median', 'Std', 'Min', 'Max', 'Obs'};

%% --- Inflation ---
stats_infl_all = table('Size', [length(all_countries), 6], ...
    'VariableTypes', {'double','double','double','double','double','double'}, ...
    'VariableNames', varNames, 'RowNames', all_labels);
for i = 1:length(all_countries)
    try
        x = TT_infl_q_all.(all_countries{i});
        x = x(time_idx_plot);
        x = x(~isnan(x));
        stats_infl_all{i,:} = [mean(x), median(x), std(x), min(x), max(x), length(x)];
    catch
        warning('Inflation data not found for: %s', all_countries{i});
    end
end
disp('=== Inflation Summary Statistics ==='); disp(stats_infl_all);

%% --- Deposit Spreads ---
stats_dep_all = table('Size', [length(all_countries), 6], ...
    'VariableTypes', {'double','double','double','double','double','double'}, ...
    'VariableNames', varNames, 'RowNames', all_labels);
for i = 1:length(all_countries)
    try
        x = TT_dep_q_all.(all_countries{i});
        x = x(time_idx_plot);
        x = x(~isnan(x));
        stats_dep_all{i,:} = [mean(x), median(x), std(x), min(x), max(x), length(x)];
    catch
        warning('Deposit spread data not found for: %s', all_countries{i});
    end
end
disp('=== Deposit Spread Summary Statistics ==='); disp(stats_dep_all);

%% --- Lending Spreads ---
stats_lend_all = table('Size', [length(all_countries), 6], ...
    'VariableTypes', {'double','double','double','double','double','double'}, ...
    'VariableNames', varNames, 'RowNames', all_labels);
for i = 1:length(all_countries)
    try
        x = TT_lend_q_all.(all_countries{i});
        x = x(time_idx_plot);
        x = x(~isnan(x));
        stats_lend_all{i,:} = [mean(x), median(x), std(x), min(x), max(x), length(x)];
    catch
        warning('Lending spread data not found for: %s', all_countries{i});
    end
end
disp('=== Lending Spread Summary Statistics ==='); disp(stats_lend_all);

%% --- Output Gaps ---
stats_gap_all = table('Size', [length(all_countries), 6], ...
    'VariableTypes', {'double','double','double','double','double','double'}, ...
    'VariableNames', varNames, 'RowNames', all_labels);
for i = 1:length(all_countries)
    try
        x = output_gaps_all.(all_countries{i});
        x = x(time_idx_plot);
        x = x(~isnan(x));
        stats_gap_all{i,:} = [round(mean(abs(x)),4), round(median(abs(x)),4), ...
                               round(std(x),4), round(min(x),4), ...
                               round(max(x),4), length(x)];
    catch
        warning('Output gap data not found for: %s', all_countries{i});
    end
end
disp('=== Output Gap Summary Statistics ==='); disp(stats_gap_all);

%% ================================
%% DESCRIPTIVE STATISTICS — TAYLOR RULES (ALL COUNTRIES)
%% ================================

varNames_tr = {'Mean', 'Std', 'Min', 'Max', 'MeanDevFromEuribor', 'MeanAbsDevFromEuribor', 'Obs'};

stats_tr_simple = table('Size', [length(all_countries), 7], ...
    'VariableTypes', repmat({'double'}, 1, 7), ...
    'VariableNames', varNames_tr, 'RowNames', all_labels);

stats_tr_augmented = table('Size', [length(all_countries), 7], ...
    'VariableTypes', repmat({'double'}, 1, 7), ...
    'VariableNames', varNames_tr, 'RowNames', all_labels);

eu_q = euribor_q(time_idx_plot);

for i = 1:length(all_countries)
    c = all_countries{i};

    ts    = taylor_simple_all.(c)(time_idx_plot);
    valid = ~isnan(ts);
    ts_v  = ts(valid); eu_v = eu_q(valid);
    if numel(ts_v) > 1
        dev_s = ts_v - eu_v;
        stats_tr_simple{i,:} = [mean(ts_v), std(ts_v), min(ts_v), max(ts_v), ...
                                 mean(dev_s), mean(abs(dev_s)), sum(valid)];
    else
        stats_tr_simple{i,:} = [NaN, NaN, NaN, NaN, NaN, NaN, sum(valid)];
    end

    ta    = taylor_augmented_all.(c)(time_idx_plot);
    valid = ~isnan(ta);
    ta_v  = ta(valid); eu_v = eu_q(valid);
    if numel(ta_v) > 1
        dev_a = ta_v - eu_v;
        stats_tr_augmented{i,:} = [mean(ta_v), std(ta_v), min(ta_v), max(ta_v), ...
                                    mean(dev_a), mean(abs(dev_a)), sum(valid)];
    else
        stats_tr_augmented{i,:} = [NaN, NaN, NaN, NaN, NaN, NaN, sum(valid)];
    end
end

disp('=== Simple Taylor Rule — Per-Country Stats ===');    disp(stats_tr_simple);
disp('=== Augmented Taylor Rule — Per-Country Stats ==='); disp(stats_tr_augmented);

%% --- Deviation from Euro area optimal rate (all countries) ---

ea_col       = 'Euro_area_';
ea_simple    = taylor_simple_all.(ea_col)(time_idx_plot);
ea_augmented = taylor_augmented_all.(ea_col)(time_idx_plot);

stats_xc_simple = table('Size', [length(all_countries), 3], ...
    'VariableTypes', repmat({'double'}, 1, 3), ...
    'VariableNames', {'MeanAbsDev_vs_EA', 'MaxAbsDev_vs_EA', 'Obs'}, ...
    'RowNames', all_labels);
stats_xc_augmented = stats_xc_simple;

for i = 1:length(all_countries)
    c = all_countries{i};

    ts    = taylor_simple_all.(c)(time_idx_plot);
    dev   = ts - ea_simple;
    valid = ~isnan(dev);
    dev_v = dev(valid);
    if numel(dev_v) > 0
        stats_xc_simple{i,:} = [mean(abs(dev_v)), max(abs(dev_v)), sum(valid)];
    else
        stats_xc_simple{i,:} = [NaN, NaN, sum(valid)];
    end

    ta    = taylor_augmented_all.(c)(time_idx_plot);
    dev   = ta - ea_augmented;
    valid = ~isnan(dev);
    dev_v = dev(valid);
    if numel(dev_v) > 0
        stats_xc_augmented{i,:} = [mean(abs(dev_v)), max(abs(dev_v)), sum(valid)];
    else
        stats_xc_augmented{i,:} = [NaN, NaN, sum(valid)];
    end
end

disp('=== Simple TR — Deviation from Euro Area Optimal Rate ===');    disp(stats_xc_simple);
disp('=== Augmented TR — Deviation from Euro Area Optimal Rate ==='); disp(stats_xc_augmented);

%% --- Union-wide fit statistic ---
non_ea_mask = ~strcmp(all_labels, 'Euro area 20');

union_fit_simple    = mean(stats_xc_simple{non_ea_mask,    'MeanAbsDev_vs_EA'}, 'omitnan');
union_fit_augmented = mean(stats_xc_augmented{non_ea_mask, 'MeanAbsDev_vs_EA'}, 'omitnan');
union_max_simple    = mean(stats_xc_simple{non_ea_mask,    'MaxAbsDev_vs_EA'},  'omitnan');
union_max_augmented = mean(stats_xc_augmented{non_ea_mask, 'MaxAbsDev_vs_EA'},  'omitnan');

fprintf('\n=== Union-Wide Fit Statistic ===\n');
fprintf('Average per-period mean absolute deviation from Euro area optimal rate\n');
fprintf('Simple Taylor Rule    : %.4f pp per quarter (max: %.4f)\n', union_fit_simple,    union_max_simple);
fprintf('Augmented Taylor Rule : %.4f pp per quarter (max: %.4f)\n', union_fit_augmented, union_max_augmented);
fprintf('Difference (Aug - Sim): %.4f pp per quarter (max: %.4f)\n', union_fit_augmented - union_fit_simple, union_max_augmented - union_max_simple);

%% --- Cross-sectional dispersion summary scalars ---
fprintf('\n=== Cross-sectional dispersion of Taylor rates (all countries) ===\n');
fprintf('Simple    — mean std: %.4f pp,  max: %.4f pp\n', ...
        mean(xc_std_simple,    'omitnan'), max(xc_std_simple,    [], 'omitnan'));
fprintf('Augmented — mean std: %.4f pp,  max: %.4f pp\n', ...
        mean(xc_std_augmented, 'omitnan'), max(xc_std_augmented, [], 'omitnan'));

%% ================================
%% EXPORT ALL SUMMARY STATISTICS TO LATEX
%% ================================

fid = fopen('summary_statistics.tex', 'w');

nl = newline;

all_stat_tables  = {stats_infl_all, stats_dep_all, stats_lend_all, stats_gap_all, ...
                    stats_tr_simple, stats_tr_augmented, ...
                    stats_xc_simple, stats_xc_augmented};
captions = { ...
    'Inflation Summary Statistics', ...
    'Deposit Spread Summary Statistics', ...
    'Lending Spread Summary Statistics', ...
    'Output Gap Summary Statistics', ...
    'Simple Taylor Rule — Per-Country Descriptive Statistics', ...
    'Augmented Taylor Rule — Per-Country Descriptive Statistics', ...
    'Simple TR — Country Deviation from Euro Area Optimal Rate', ...
    'Augmented TR — Country Deviation from Euro Area Optimal Rate'};
labels = { ...
    'tab:inflation', 'tab:deposit', 'tab:lending', 'tab:outputgap', ...
    'tab:tr_simple', 'tab:tr_augmented', ...
    'tab:xc_simple', 'tab:xc_augmented'};

for s = 1:length(all_stat_tables)
    T_out        = all_stat_tables{s};
    col_headers  = T_out.Properties.VariableNames;
    row_headers  = T_out.Properties.RowNames;
    [nrows, ncols] = size(T_out);

    fwrite(fid, ['\begin{table}[htbp]', nl]);
    fwrite(fid, ['\centering', nl]);
    fwrite(fid, ['\caption{', captions{s}, '}', nl]);
    fwrite(fid, ['\label{', labels{s}, '}', nl]);
    fwrite(fid, ['\begin{tabular}{l', repmat('r', 1, ncols), '}', nl]);
    fwrite(fid, ['\hline\hline', nl]);

    hdr = ' ';
    for j = 1:ncols
        hdr = [hdr, ' & ', col_headers{j}];
    end
    fwrite(fid, [hdr, ' \\', nl]);
    fwrite(fid, ['\hline', nl]);

    for i = 1:nrows
        row = row_headers{i};
        for j = 1:ncols
            val = T_out{i,j};
            if j == ncols
                row = [row, sprintf(' & %d', val)];
            else
                row = [row, sprintf(' & %.4f', val)];
            end
        end
        fwrite(fid, [row, ' \\', nl]);
    end

    fwrite(fid, ['\hline\hline', nl]);
    fwrite(fid, ['\end{tabular}', nl]);
    fwrite(fid, ['\end{table}', nl]);
    fwrite(fid, [nl, nl]);
end

%% Append union-wide fit statistic as a small table
fwrite(fid, ['\begin{table}[htbp]', nl]);
fwrite(fid, ['\centering', nl]);
fwrite(fid, ['\caption{Union-Wide Fit Statistic: Average Per-Period Mean Absolute Deviation from Euro Area Optimal Rate}', nl]);
fwrite(fid, ['\label{tab:union_fit}', nl]);
fwrite(fid, ['\begin{tabular}{lr}', nl]);
fwrite(fid, ['\hline\hline', nl]);
fwrite(fid, [' & Mean AbsDev (pp per quarter) \\', nl]);
fwrite(fid, ['\hline', nl]);
fwrite(fid, [sprintf('Simple Taylor Rule    & %.4f \\\\', union_fit_simple),    nl]);
fwrite(fid, [sprintf('Augmented Taylor Rule & %.4f \\\\', union_fit_augmented), nl]);
fwrite(fid, [sprintf('Difference (Aug $-$ Simple) & %.4f \\\\', union_fit_augmented - union_fit_simple), nl]);
fwrite(fid, ['\hline\hline', nl]);
fwrite(fid, ['\end{tabular}', nl]);
fwrite(fid, ['\end{table}', nl]);
fwrite(fid, [nl, nl]);

%% Append cross-sectional dispersion as a small table
xc_mean_simple    = mean(xc_std_simple,    'omitnan');
xc_max_simple     = max(xc_std_simple,     [], 'omitnan');
xc_mean_augmented = mean(xc_std_augmented, 'omitnan');
xc_max_augmented  = max(xc_std_augmented,  [], 'omitnan');

fwrite(fid, ['\begin{table}[htbp]', nl]);
fwrite(fid, ['\centering', nl]);
fwrite(fid, ['\caption{Cross-Sectional Dispersion of Optimal Taylor Rates across Euro Area Members}', nl]);
fwrite(fid, ['\label{tab:xc_dispersion}', nl]);
fwrite(fid, ['\begin{tabular}{lrr}', nl]);
fwrite(fid, ['\hline\hline', nl]);
fwrite(fid, [' & Mean std (pp) & Max std (pp) \\', nl]);
fwrite(fid, ['\hline', nl]);
fwrite(fid, [sprintf('Simple Taylor Rule    & %.4f & %.4f \\\\', xc_mean_simple,    xc_max_simple),    nl]);
fwrite(fid, [sprintf('Augmented Taylor Rule & %.4f & %.4f \\\\', xc_mean_augmented, xc_max_augmented), nl]);
fwrite(fid, [sprintf('Difference (Aug $-$ Simple) & %.4f & %.4f \\\\', ...
             xc_mean_augmented - xc_mean_simple, xc_max_augmented - xc_max_simple), nl]);
fwrite(fid, ['\hline\hline', nl]);
fwrite(fid, ['\end{tabular}', nl]);
fwrite(fid, ['\end{table}', nl]);

fclose(fid);
disp('All LaTeX tables saved to summary_statistics.tex');

%% Fix random seed
rng(117);
%% Generate x series
T=40;
shocks = sqrt(0.5)*randn(T, 1);
rho = 0.7;
x = zeros(T, 1);
x(1) = shocks(1);
for t = 2:T
    x(t) = rho * x(t-1) + shocks(t);
end
%x = repmat([-2;2], T/2,1);
low_swing  = x;
high_swing = 1.5*x;
%% Parameters
r_bar  = 4;
alpha  = 0.05;
a      = 0;
b      = 1;
c      = 8;
d      = 1;
p      = 0.95;
gamma  = 1;
psi    = 1;
omega  = psi;
n_low  = 3;
n_high = 3;
%% Compute components for low swing
Gamma_low = gamma * n_low * (n_low-1)^2;
D1_low    = b*(n_low+1) + Gamma_low;
D2_low    = p*(d*(n_low+1) + Gamma_low);
A_low     = (1-2*psi)*D1_low*D2_low + psi*(b+Gamma_low)*(1-alpha)*D2_low + psi*(d+Gamma_low)*D1_low;
%% Compute components for high swing
Gamma_high = gamma * n_high * (n_high-1)^2;
D1_high    = b*(n_high+1) + Gamma_high;
D2_high    = p*(d*(n_high+1) + Gamma_high);
A_high     = (1-2*psi)*D1_high*D2_high + psi*(b+Gamma_high)*(1-alpha)*D2_high + psi*(d+Gamma_high)*D1_high;
%% r* for each x vector
r_low  = ((r_bar + 0.5*low_swing)  * D1_low*D2_low   + psi*a*n_low*D2_low   - psi*p*c*n_low*D1_low)   / A_low;
r_high = ((r_bar + 0.5*high_swing) * D1_high*D2_high  + psi*a*n_high*D2_high - psi*p*c*n_high*D1_high) / A_high;

%% Numerically solve for n_high* such that r_high == r_low
r_high_fn = @(nh) compute_r_high(nh, r_bar, high_swing, alpha, a, b, c, d, p, gamma, psi);
obj = @(nh) sum((r_high_fn(nh) - r_low).^2);

nh_grid  = linspace(1.01, 30, 5000);
obj_vals = arrayfun(obj, nh_grid);
[~, idx_min] = min(obj_vals);
nh_init = nh_grid(idx_min);

options = optimset('TolX', 1e-14, 'TolFun', 1e-20, 'MaxFunEvals', 1e6);
n_high_star = fminsearch(obj, nh_init, options);

fprintf('\n=== Numerical solution ===\n');
fprintf('n_high* = %.6f\n', n_high_star);
fprintf('Residual (sum sq diff) = %.2e\n', obj(n_high_star));

%% Compute all rates at n_high*
r_star     = r_high_fn(n_high_star);
Gamma_star = gamma * n_high_star * (n_high_star - 1)^2;
D1_star    = b*(n_high_star + 1) + Gamma_star;
D2_star    = p*(d*(n_high_star + 1) + Gamma_star);
rD_star    = ((b + Gamma_star)*(1-alpha)*r_star - a*n_high_star) ./ D1_star;
rL_star    = ((d + Gamma_star)*r_star + p*c*n_high_star)         ./ D2_star;

%% Compute rates at n_low
rD_low = ((b + Gamma_low)*(1-alpha)*r_low - a*n_low) ./ D1_low;
rL_low = ((d + Gamma_low)*r_low + p*c*n_low)         ./ D2_low;

%% Spread-adjusted term: omega*(s^D - s^L)
spread_adj_low  = omega * ((r_low  - rD_low)  - (rL_low  - r_low));
spread_adj_star = omega * ((r_star - rD_star) - (rL_star - r_star));

%% Aggregate quantities
D_low  = b * rD_low;
L_low  = 2*r_bar - b*rL_low;
D_star = b * rD_star;
L_star = 2*r_bar - b*rL_star;

tt = 1:T;

% Subplot title strings
lbl_low  = 'Type s country';
lbl_star = 'Type v country';

%% Percentage deviation in D and L from policy rate (n_low optimal policy rate)
r_D_base_low = ((b + Gamma_low)*(1-alpha)*r_bar - a*n_low) ./ D1_low;
r_L_base_low = ((d + Gamma_low)*r_bar + p*c*n_low)         ./ D2_low;
r_D_base_star    = ((b + Gamma_star)*(1-alpha)*r_bar - a*n_high_star) ./ D1_star;
r_L_base_star    = ((d + Gamma_star)*r_bar + p*c*n_high_star)         ./ D2_star;


D_base_low = b * r_D_base_low;
L_base_low = 2*r_bar - b*r_L_base_low;
D_base_star = b * r_D_base_star;
L_base_star = 2*r_bar - b*r_L_base_star;

D_dev_low  = 100 * (D_base_low  - D_low)  ./ D_base_low;
L_dev_low  = 100 * (L_base_low  - L_low)  ./ L_base_low;
D_dev_star = 100 * (D_base_star - D_star) ./ D_base_star;
L_dev_star = 100 * (L_base_star - L_star) ./ L_base_star;

%% Helper: compute shared y-limits with 5% padding
    function ylims = shared_ylim(varargin)
        all_vals = cellfun(@(v) v(:), varargin, 'UniformOutput', false);
        all_vals = vertcat(all_vals{:});
        lo = min(all_vals); hi = max(all_vals);
        pad = 0.05 * (hi - lo);
        if pad == 0; pad = 0.1; end
        ylims = [lo - pad, hi + pad];
    end

%% ---- Panel 1: r* comparison ----
yl_p1 = shared_ylim(r_low, r_high, r_star);

figure('Position', [100 100 1200 450]);

subplot(1,2,1);
plot(tt, r_low,  'b-',  'LineWidth', 1.5); hold on;
plot(tt, r_high, 'r--', 'LineWidth', 1.5);
ylim(yl_p1);
xlabel('Time', 'FontSize', 13); ylabel('r^*', 'FontSize', 13);
title('Ex-ante competition regime', 'FontSize', 13);
legend(sprintf('n_{s} = %g', n_low), sprintf('n_{v} = %g', n_high), 'Location', 'best');
grid on;

subplot(1,2,2);
plot(tt, r_low,  'b-',  'LineWidth', 1.5); hold on;
plot(tt, r_star, 'r--', 'LineWidth', 1.5);
ylim(yl_p1);
xlabel('Time', 'FontSize', 13); ylabel('r^*', 'FontSize', 13);
title('Optimal Taylor competition regime', 'FontSize', 13);
legend(sprintf('n_{s} = %g', n_low), sprintf('n_{v} = %.4f', n_high_star), 'Location', 'best');
grid on;

sgtitle('Taylor rate comparison', 'FontSize', 14, 'FontWeight', 'bold');

%% Sum of squared differences between the two optimal rates (Panel 1)
sod_orig = sum((r_low - r_high).^2);   % n_low vs n_high (original)
sod_star = sum((r_low - r_star).^2);   % n_low vs n_high* (solved)

fprintf('\n=== Sum of differences in optimal policy rates ===\n');
fprintf('n_low vs n_high  (original): %.6f\n', sod_orig);
fprintf('n_low vs n_high* (solved):   %.6f\n', sod_star);

%% ---- Panel 2: r*, r^D, r^L ----
yl_p2 = shared_ylim(r_low, rD_low, rL_low, r_star, rD_star, rL_star);

figure('Position', [100 100 1200 450]);

subplot(1,2,1);
plot(tt, r_low,  'k-',  'LineWidth', 1.5); hold on;
plot(tt, rD_low, 'b--', 'LineWidth', 1.5);
plot(tt, rL_low, 'r:',  'LineWidth', 1.5);
ylim(yl_p2);
xlabel('Time', 'FontSize', 13); ylabel('Rate', 'FontSize', 13);
title(lbl_low, 'FontSize', 13);
legend('r^*', 'r_s^D', 'r_s^L', 'Location', 'best');
grid on;

subplot(1,2,2);
plot(tt, r_star,  'k-',  'LineWidth', 1.5); hold on;
plot(tt, rD_star, 'b--', 'LineWidth', 1.5);
plot(tt, rL_star, 'r:',  'LineWidth', 1.5);
ylim(yl_p2);
xlabel('Time', 'FontSize', 13); ylabel('Rate', 'FontSize', 13);
title(lbl_star, 'FontSize', 13);
legend('r^*', 'r_v^D', 'r_v^L', 'Location', 'best');
grid on;

sgtitle('Policy, deposit and lending rates', 'FontSize', 14, 'FontWeight', 'bold');

%% ---- Panel 3: spread-adjusted term ----
yl_p3 = shared_ylim(spread_adj_low, spread_adj_star);

figure('Position', [100 100 1200 450]);

subplot(1,2,1);
plot(tt, spread_adj_low, 'b-', 'LineWidth', 1.5);
ylim(yl_p3);
xlabel('Time', 'FontSize', 13); ylabel('\omega(s^D - s^L)', 'FontSize', 13);
title(lbl_low, 'FontSize', 13);
grid on;

subplot(1,2,2);
plot(tt, spread_adj_star, 'r-', 'LineWidth', 1.5);
ylim(yl_p3);
xlabel('Time', 'FontSize', 13); ylabel('\omega(s^D - s^L)', 'FontSize', 13);
title(lbl_star, 'FontSize', 13);
grid on;

sgtitle('Taylor spread term', 'FontSize', 14, 'FontWeight', 'bold');

%% ---- Panel 4: aggregate deposits and lending ----
yl_p4 = shared_ylim(D_low, L_low, D_star, L_star);

figure('Position', [100 100 1200 450]);

subplot(1,2,1);
plot(tt, D_low, 'b-',  'LineWidth', 1.5); hold on;
plot(tt, L_low, 'r--', 'LineWidth', 1.5);
ylim(yl_p4);
xlabel('Time', 'FontSize', 13); ylabel('Quantity', 'FontSize', 13);
title(lbl_low, 'FontSize', 13);
legend('D({r^D_s}^*)', 'L({r^L_s}^*)', 'Location', 'best');
grid on;

subplot(1,2,2);
plot(tt, D_star, 'b-',  'LineWidth', 1.5); hold on;
plot(tt, L_star, 'r--', 'LineWidth', 1.5);
ylim(yl_p4);
xlabel('Time', 'FontSize', 13); ylabel('Quantity', 'FontSize', 13);
title(lbl_star, 'FontSize', 13);
legend('D({r^D_v}^*)', 'L({r^L_v}^*)', 'Location', 'best');
grid on;

sgtitle('Aggregate deposits and lending', 'FontSize', 14, 'FontWeight', 'bold');


%% ---- Panel 5: deposit and lending spreads over time ----

sD_low   = r_low  - rD_low;
sL_low   = rL_low - r_low;
sD_star  = r_star - rD_star;
sL_star  = rL_star - r_star;

yl_spreads = shared_ylim(sD_low, sL_low, sD_star, sL_star);

figure('Position', [100 100 1200 450]);

subplot(1,2,1);
plot(tt, sD_low, 'b-',  'LineWidth', 1.5); hold on;
plot(tt, sL_low, 'r--', 'LineWidth', 1.5);
ylim(yl_spreads);
yline(0, 'k:', 'LineWidth', 1.0);
xlabel('Time', 'FontSize', 13); ylabel('Spread', 'FontSize', 13);
title(lbl_low, 'FontSize', 13);
legend('s^D = r^* - r^D', 's^L = r^L - r^*', 'Location', 'best');
grid on;

subplot(1,2,2);
plot(tt, sD_star, 'b-',  'LineWidth', 1.5); hold on;
plot(tt, sL_star, 'r--', 'LineWidth', 1.5);
ylim(yl_spreads);
yline(0, 'k:', 'LineWidth', 1.0);
xlabel('Time', 'FontSize', 13); ylabel('Spread', 'FontSize', 13);
title(lbl_star, 'FontSize', 13);
legend('s^D = r^* - r^D', 's^L = r^L - r^*', 'Location', 'best');
grid on;

sgtitle('Deposit and lending spreads over time', 'FontSize', 14, 'FontWeight', 'bold');

%% Local function
function r_h = compute_r_high(nh, r_bar, high_swing, alpha, a, b, c, d, p, gamma, psi)
    Gamma_h = gamma * nh * (nh - 1)^2;
    D1_h    = b*(nh + 1) + Gamma_h;
    D2_h    = p*(d*(nh + 1) + Gamma_h);
    A_h     = (1 - 2*psi)*D1_h*D2_h + psi*(b + Gamma_h)*(1 - alpha)*D2_h ...
              + psi*(d + Gamma_h)*D1_h;
    r_h     = ((r_bar + 0.5*high_swing) * D1_h*D2_h + psi*a*nh*D2_h ...
               - psi*p*c*nh*D1_h) / A_h;
end

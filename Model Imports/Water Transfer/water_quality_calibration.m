clear
load([water_transfer_data_folder,'baseline_summary_data.mat'])

% (a) Histogram of totn
% ----------------------
% Add vertical lines of water quality categories used in non use WQ model
figure
histogram(subctch_summary.totn_20)
line([5, 5], [0, 1200], 'Color', 'black')   % High < 5
line([10, 10], [0, 1200], 'Color', 'black') % 5 < Good < 10
line([20, 20], [0, 1200], 'Color', 'black') % 10 < Moderate < 20
line([30, 30], [0, 1200], 'Color', 'black') % 20 < Poor < 30
line([40, 40], [0, 1200], 'Color', 'black') % 30 < Bad < 40
title('Total nitrogen concentration')

% (b) Histogram of totp
% ---------------------
figure
histogram(subctch_summary.totp_20)
line([0.02, 0.02], [0, 700], 'Color', 'black')  % High < 0.02
line([0.06, 0.06], [0, 700], 'Color', 'black')  % 0.02 < Good < 0.06
line([0.1, 0.1], [0, 700], 'Color', 'black')    % 0.06 < Moderate < 0.1
line([0.2, 0.2], [0, 700], 'Color', 'black')    % 0.1 < Poor < 0.2
line([1, 1], [0, 700], 'Color', 'black')        % 0.2 < Bad < 1
title('Total phosphorus concentration')

% (c) Histogram of nh4
% --------------------
figure
histogram(subctch_summary.nh4_20)
line([0.2, 0.2], [0, 1400], 'Color', 'black')
line([0.3, 0.3], [0, 1400], 'Color', 'black')
line([0.75, 0.75], [0, 1400], 'Color', 'black')
line([1.1, 1.1], [0, 1400], 'Color', 'black')
xlim([0, 3])
title('Ammonia concentration')

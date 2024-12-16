close all; clear all; clc; 

BLOCKPATH = '/Users/jennyshin/Documents/MATLAB/fiber photometry/Subject2-230404-110925'

REF_EPOC = 'PtAB'; % event store name. This holds behavioral codes that are
% read through Ports A & B on the front of the RZ
SHOCK_CODE = 64959; % shock onset event code we are interested in
STREAM_STORE1 = 'Dv2A'; % name of the 405 store
STREAM_STORE2 = 'Dv1A'; % name of the 465 store
TRANGE = [-10 20]; % window size [start time relative to epoc onset, window duration]
BASELINE_PER = [-10 -6]; % baseline period within our window
ARTIFACT = Inf; % optionally set an artifact rejection level

% Now read the specified data from our block into a MATLAB structure.
data = TDTbin2mat(BLOCKPATH, 'TYPE', {'epocs', 'scalars', 'streams'});


% Create the time vector for each stream store
ts1 = TRANGE(1) + (1:minLength1) / data.streams.(STREAM_STORE1).fs*N;
ts2 = TRANGE(1) + (1:minLength2) / data.streams.(STREAM_STORE2).fs*N;

% Subtract DC offset to get signals on top of one another
meanSignal1 = meanSignal1 - dcSignal1;
meanSignal2 = meanSignal2 - dcSignal2;

% Plot the 405 and 465 average signals
figure;
subplot(4,1,1)
plot(ts1, meanSignal1, 'color',[0.4660, 0.6740, 0.1880], 'LineWidth', 3); hold on;
plot(ts2, meanSignal2, 'color',[0.8500, 0.3250, 0.0980], 'LineWidth', 3);

% Plot vertical line at epoch onset, time = 0
line([0 0], [min(F465(:) - dcSignal2), max(F465(:)) - dcSignal2], 'Color', [.7 .7 .7], 'LineStyle','-', 'LineWidth', 3)

% Make a legend
legend('405 nm','465 nm','Shock Onset', 'AutoUpdate', 'off');

% Create the standard error bands for the 405 signal
XX = [ts1, fliplr(ts1)];
YY = [meanSignal1 + stdSignal1, fliplr(meanSignal1 - stdSignal1)];
c
% Plot filled standard error bands.
h = fill(XX, YY, 'g');
set(h, 'facealpha',.25,'edgecolor','none')

% Repeat for 465
XX = [ts2, fliplr(ts2)];
YY = [meanSignal2 + stdSignal2, fliplr(meanSignal2 - stdSignal2)];
h = fill(XX, YY, 'r');
set(h, 'facealpha',.25,'edgecolor','none')

% Finish up the plot
axis tight
xlabel('Time, s','FontSize',12)
ylabel('mV', 'FontSize', 12)
title(sprintf('Foot Shock Response, %d Trials (%d Artifacts Removed)', numel(data.streams.(STREAM_STORE1).filtered), numArtifacts))
set(gcf, 'Position',[100, 100, 800, 500])

% Heat Map based on z score of 405 fit subtracted 465

% Fitting 405 channel onto 465 channel to detrend signal bleaching
% Scale and fit data
% Algorithm sourced from Tom Davidson's Github:
% https://github.com/tjd2002/tjd-shared-code/blob/master/matlab/photometry/FP_normalize.m

bls = polyfit(F405(1:end), F465(1:end), 1);
Y_fit_all = bls(1) .* F405 + bls(2);
Y_dF_all = F465 - Y_fit_all;

zall = zeros(size(Y_dF_all));
for i = 1:size(Y_dF_all,1)
    ind = ts2(1,:) < BASELINE_PER(2) & ts2(1,:) > BASELINE_PER(1);
    zb = mean(Y_dF_all(i,ind)); % baseline period mean (-10sec to -6sec)
    zsd = std(Y_dF_all(i,ind)); % baseline period stdev
    zall(i,:)=(Y_dF_all(i,:) - zb)/zsd; % Z score per bin
end

% Standard error of the z-score
zerror = std(zall)/sqrt(size(zall,1));

% Plot heat map
subplot(4,1,2)

imagesc(ts2, 1, zall);
colormap('jet'); % c1 = colorbar;
title(sprintf('Z-Score Heat Map, %d Trials (%d Artifacts Removed)', numel(data.streams.(STREAM_STORE1).filtered), numArtifacts));
ylabel('Trials', 'FontSize', 12);

% Fill band values for second subplot. Doing here to scale onset bar
% correctly
XX = [ts2, fliplr(ts2)];
YY = [mean(zall)-zerror, fliplr(mean(zall)+zerror)];

subplot(4,1,3)
plot(ts2, mean(zall), 'color',[0.8500, 0.3250, 0.0980], 'LineWidth', 3); hold on;
line([0 0], [min(YY), max(YY)], 'Color', [.7 .7 .7], 'LineWidth', 2)

h = fill(XX, YY, 'r');
set(h, 'facealpha',.25,'edgecolor','none')

% Finish up the plot
axis tight
xlabel('Time, s','FontSize',12)
ylabel('Z-score', 'FontSize', 12)
title(sprintf('465 nm Foot Shock Response, %d Trials (%d Artifacts Removed)', numel(data.streams.(STREAM_STORE1).filtered), numArtifacts))
%c2 = colorbar;

% Quantify changes as area under the curve for cue (-5 sec) and shock (0 sec)
AUC=[]; % cue, shock
AUC(1,1)=trapz(mean(zall(:,ts2(1,:) < -3 & ts2(1,:) > -5)));
AUC(1,2)=trapz(mean(zall(:,ts2(1,:) > 0 & ts2(1,:) < 2)));
subplot(4,1,4);
hBar = bar(AUC, 'FaceColor', [.8 .8 .8]);

% Run a two-sample T-Test
[h,p,ci,stats] = ttest2(mean(zall(:,ts2(1,:) < -3 & ts2(1,:) > -5)),mean(zall(:,ts2(1,:) > 0 & ts2(1,:) < 2)));

% Plot significance bar if p < .05
hold on;
centers = get(hBar, 'XData');
plot(centers(1:2), [1 1]*AUC(1,2)*1.1, '-k', 'LineWidth', 2)
p1 = plot(mean(centers(1:2)), AUC(1,2)*1.2, '*k');
set(gca,'xticklabel',{'Cue','Shock'});
title({'Cue vs Shock Response Changes', 'Area under curve'})
legend(p1, 'p < .05','Location','southeast');

set(gcf, 'Position',[100, 100, 500, 1000])
close all; clear all; clc;

%% load data

%insert blockpath for the whole folder
BLOCKPATH = '/Volumes/Ultra Touch/Fiber photometry/Subject2-230404-105923';
data = TDTbin2mat (BLOCKPATH);

GCamp = data.streams.Dv2A.data;
isobestic = data.streams.Dv1A.data;

%% time calculation

%dividing the indices of the data points by the sampling frequency
time = (1:length(GCamp)) / data.streams.Dv1A.fs;

plot (time, GCamp); 
%% artifact removal

%size of the vector for time, isobestic, GCamp are all the same

%input artifact time to remove (in seconds)
timeToRemove = 5;

samplesToRemove = round (timeToRemove * data.streams.Dv1A.fs); %Convert time to number of samples

%Remove the corresponding samples from the front
isobestic = isobestic (samplesToRemove+1:end);
GCamp = GCamp(samplesToRemove+1:end);

time = time(samplesToRemove+1:end);

%check your plot once here
%plot (time,GCamp);

%% selected time range

timeA = 20;
timeB = 50;

% Find indices corresponding to time A and time B
indexA = find(time >= timeA, 1); % Index of the first time point greater than or equal to timeA
indexB = find(time <= timeB, 1, 'last'); % Index of the last time point less than or equal to timeB

% Select data from time A to time B
selectedIsobestic = isobestic(indexA:indexB);
selectedGCamp = GCamp(indexA:indexB);
selectedTime = time(indexA:indexB);

%plot (selectedTime, selectedGCamp);

%% linear regression

%coefficientsG = polyfit(selectedTime, selectedGCamp, 1);
%fittedGCamp = polyval (coefficientsG, selectedTime);

coefficients = polyfit(selectedTime, selectedIsobestic, 1);
fittedIsobestic = polyval (coefficients, selectedTime);


%% dF/F

%subtract GCamp from the fitted isobestic
delta_Gcamp_isobestic = selectedGCamp - fittedIsobestic;

%divide by the fitted isobestic
deltaFoverF = delta_Gcamp_isobestic ./ fittedIsobestic;
deltaFoverF_scaled = deltaFoverF * 100;


plot (selectedTime, deltaFoverF_scaled, 'Color', [0.678, 0.847, 0.902], 'LineWidth', 1);
xlabel  ('Time (s)');
ylabel ('ΔF/F (%)');



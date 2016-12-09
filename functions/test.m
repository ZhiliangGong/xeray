clear;
close all;
clc;
parameters = {'Angle-Offset', 'Scale-Factor', 'Background', 'Concentration', 'Layer'};
load('XeRayDateSet.mat');
x = XeRayDataSet{1};

file = which('bulk.xfluo');

s = XeLayers(file);
s.selectElement('Ca');
s.createPhysicalSystem(10, 0.024, 10.76);
s.system.insert(1, 0.334, Inf, 'H2OCa0.0009Cl0.0018');

%s.system.insert(1, 0.4, 8);
%s.system.insert(1, 0.25, 12);
%a = s.system.incidence.getLayerIntegratedIntensity(s.system.angle, s.system.thickness, 0.024, 10.76);
%a = s.system.getLayerIntegratedIntensity();
%s.plotSignal();
%s.runFluoFit([]);
%s.runFluoFit([],[0, 0.01, 0, 50, 1], [0, 0, 0, 0, 1], [0, 0, 0, 0, 1]);

%lb = [-0.0002, 80, 0, 50, 1];
lb = [-2.3e-5, 92, 0, 50, 1];
ub = [-2.2e-5, 96, 0, 50, 1];
n = 50;

% N = 10;
% diff = cell(1, N);
% chi2 = zeros(1, N);
% scale = linspace(1, 200, N);
% figure;
% hold on;
% for i = 1 : N
%     lb(2) = scale(i);
%     ub(2) = scale(i);
%     diff{i} = s.runFluoFit([], lb, ub);
%     chi2(i) = sum(diff{i}.^2);
%     plot(s.fit.curve,'-o', 'linewidth', 2.4);
%     %plot(diff{i}, '-o', 'linewidth', 2.4);
% end
% plot(s.data.lineshape.signal,'*');
% hold off;

s.runFluoFit([], lb, ub, n);
%s.plotSignal();
%s.plotLikelihood(parameters{1});
s.plotLikelihood(parameters{1});
%a = s.system.updateCalculationWithBounds([0, 1, 0, 0, 1], [0, 1, 0, 0, 1], [0, 1, 0, 1, 1])
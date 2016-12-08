clear;
close all;
clc;

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
lb = [0, 0, 0, 50, 1];
ub = [0, 2, 0, 50, 1];
s.runFluoFit([], lb, ub);
s.plotSignal();
%a = s.system.updateCalculationWithBounds([0, 1, 0, 0, 1], [0, 1, 0, 0, 1], [0, 1, 0, 1, 1])
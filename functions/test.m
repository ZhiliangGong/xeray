clear;
clc;
s = xlayers;
s.updateLayer(1, 0.25, 12);
s.updateLayer(2, 0.4, 8);
s.updateLayer(3, 0.334, Inf, 'H2OCa0.009Cl0.018');
calculateRefractionIndex(s, 10);
angle = linspace(0.001, 0.004, 10);
s.optics(angle);
s.calculateFluoIntensity('Ca');
s

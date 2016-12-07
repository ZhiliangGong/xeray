clear;
clc;

file = '../examples/bulk.xfluo';

s = XeLayers(10, file);
s.system.push(1, 0.334, Inf);
s.system.push(1, 0.25, 12);
s.system.push(2, 0.4, 8);
s.system.push(3, 0.334, Inf, 'H2OCa0.009Cl0.018');
angle = linspace(0.001, 0.004, 10);
%s.selectElement('Ca');
s
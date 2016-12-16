%clear;
clc;
close all;
%this = XeRayGUI();
files = {'/Users/zhilianggong/Documents/MATLAB/XeRay/examples/bulk.xfluo', '/Users/zhilianggong/Documents/MATLAB/XeRay/examples/surf.xfluo'};
this = XeRayGUI(files);
a = this;

%this.loadButton_Callback();
b = this.data{1};
c = this.data{2};
s = c.system;

angles = linspace(0.0017, 0.0032, 100)';
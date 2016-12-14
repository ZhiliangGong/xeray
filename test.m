clear;
clc;
close all;
%this = XeRayGUI();
files = {'/Users/zhilianggong/Documents/MATLAB/XeRay/examples/bulk.xfluo', '/Users/zhilianggong/Documents/MATLAB/XeRay/examples/surf.xfluo'};
this = XeRayGUI(files);
a = this;

%this.loadButton_Callback();
b = this.data{1};
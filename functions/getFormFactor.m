function [f1,f2] = getFormFactor(element,energy)
%form factors for a single element at a given energy

% untis
% energy - keV
    
    load('formFactor.mat');
    data = formFactor(element);
    
    f1 = interp1(data(:,1),data(:,2), energy*1000, 'pchip');
    f2 = interp1(data(:,1),data(:,3), energy*1000, 'pchip');

end
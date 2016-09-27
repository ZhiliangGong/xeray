function [absorption, dispersion] = calculateDisAbs(xresult,d)
    %d: density, can be a vector
    
    %constants
    THOMPSON = 2.81794092e-15;          % m
    c = 299792458;           % m/sec
    h = 6.626068e-34;              % m^2*kg/sec
    ELEMENTCHARGE = 1.60217646e-19;     % Coulombs
    A = 6.02214199e23;           % mole^-1
    
    wl = (c*h/ELEMENTCHARGE)/(xresult.E*1000);
    
    dispersion = zeros(size(d));
    absorption = zeros(size(d));
    
    for i = 1:length(xresult.nAtoms)
        dispersion = dispersion + wl.^2/(2*pi)*THOMPSON*A* d *1e6 / xresult.mw * xresult.nAtoms(i) * xresult.f1(i);
        absorption = absorption + wl.^2/(2*pi)*THOMPSON*A* d *1e6 / xresult.mw * xresult.nAtoms(i) * xresult.f2(i);
    end
    
end
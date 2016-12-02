function xresult = refracOf(formula,E,density)

    %constants
    THOMPSON = 2.81794092e-15;
    c = 299792458;
    h = 6.626068e-34;
    ELEMENTCHARGE = 1.60217646e-19;
    A = 6.02214199e23;

    [elements,stoichiometry] = parseFormula(formula);
    mw = molecularWeight(elements,stoichiometry);
    
    f1 = zeros(size(elements));
    f2 = f1;
    for i = 1:length(elements)
        [f1(i),f2(i)] = getFormFactor(elements{i},E);
    end
    
    wl = (c*h/ELEMENTCHARGE)/(E*1000);
    dispersion = 0;
    absorption = 0;
    for i = 1:length(stoichiometry)
        dispersion = dispersion + wl.^2/(2*pi)*THOMPSON*A* density *1e6 / mw * stoichiometry(i) * f1(i);
        absorption = absorption + wl.^2/(2*pi)*THOMPSON*A* density *1e6 / mw * stoichiometry(i) * f2(i);
    end
    
    xresult.E = E;
    xresult.wavelength = (c*h/ELEMENTCHARGE)./(E*1000.0)*1e10;
    xresult.mw = mw;
    xresult.stoichiometry = stoichiometry;
    xresult.density = density;
    xresult.f1 = f1;
    xresult.f2 = f2;
    xresult.absorption = absorption;
    xresult.dispersion = dispersion;

end
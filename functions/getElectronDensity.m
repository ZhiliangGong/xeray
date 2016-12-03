function electronDensity = getElectronDensity(formula, density)
% calculate the electron density of a given chemical formula and density

% units
% density - g/cm^3
% electron density - A^-3

    values = translateFormula(formula);
    electrons = values(1);
    molecularWeight = values(2);
    
    NA = 6.02214199e23; % Avagadro's Number
    electronDensity = density / molecularWeight * NA * electrons * 1e-24 ;

end
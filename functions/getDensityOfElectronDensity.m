function density = getDensityOfElectronDensity(formula, electronDensity)
% calculate the density from the electron density and chemical formula

% units
% electronDensity - number of electrons per A^3
% formula - any chemical formula
% density - g/cm^3

    values = translateFormula(formula);
    electrons = values(1);
    molecularWeight = values(2);
    
    NA = 6.02214199e23; % Avagadro's Number
    density = electronDensity / electrons / NA * molecularWeight * 1e24;

end
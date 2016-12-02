function dispersion = getDispersion(electonDensity, energy)
% calculate the dispersion part of the refractive index, the real part

% units
% electronDensity - /A^3, for water is 0.3344
% energy - keV
% wavelength - A

    wavelength = getWavelength(energy);
    re = 2.81794092e-5; % classical radius for electron in A
    
    dispersion = re * electonDensity * wavelength^2 / 2 / pi;

end
function wavelength = getWavelength(energy)
% calculate the x-ray wavelength based on the energy
% supports vectorized calculation

% units
% energy - keV
% wavelength - A

    speedOfLight = 299792458;
    planckConstant = 6.626068e-34;
    kev = 1.60218e-16; % convert kev to joule
    
    wavelength = planckConstant * speedOfLight ./ (energy * kev) * 1e10;

end
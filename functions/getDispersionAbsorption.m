function [dispersion, absorption] = getDispersionAbsorption(elements, stoichiometry, energy, density)
% obtain dispersion and absorption from chemical formula and density

% units
% energy - keV
% density - g/cm^3

    %constants
    re = 2.81794092e-15; % classical radius of electrons
    c = 299792458; % speed of light
    h = 6.626068e-34; % planck's constant
    e = 1.60217646e-19; % elemental charge
    NA = 6.02214199e23; % Avagadro's number
    wl = (c * h / e)/( energy * 1000); % wavelength in m

    n = length(elements);
    f1 = zeros(1, n);
    f2 = f1;
    for i = 1:length(elements)
        [f1(i),f2(i)] = getFormFactor(elements{i},energy);
    end

    factor = wl.^2 / (2*pi) * re * NA * density * 1e6 / molecularWeight(elements,stoichiometry);
    dispersion = factor * sum(stoichiometry .* f1);
    absorption = factor * sum(stoichiometry .* f2);

end

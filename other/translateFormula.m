function outputValue = translateFormula(formula, what)
% give back the number of electrons and molecular weight of a given formula

% what - the parameter to be calculated

    % pase the formula into elements and stoichiometry
    [elements, stoichiometry] = parseFormula(formula);
    
    %calculate the number of electrons and molecular weight
    atom = ' H He Li Be B C N O F Ne Na Mg Al Si P S Cl Ar K Ca Sc Ti V Cr Mn Fe Co Ni Cu Zn Ga Ge As Se Br Kr Rb Sr Y Zr Nb Mo Tc Ru Rh Pd Ag Cd In Sn Sb Te I Xe Cs Ba La Ce Pr Nd Pm Sm Eu Gd Tb Dy Ho Er Tm Yb Lu Hf Ta W Re Os Ir Pt Au Hg Tl Pb Bi Po At Rn Fr Ra Ac Th Pa U';
    weight = [1.0079,4.0026,6.941,9.0122,10.81,12.011,14.007,15.999,18.998,20.18,22.99,24.305,26.982,28.085,30.974,32.066,35.453,39.948,39.098,40.078,44.956,47.867,50.941,51.996,54.938,55.845,58.933,58.693,63.546,65.39,69.723,72.61,74.922,78.96,79.904,83.8,85.468,87.62,88.906,91.224,92.906,95.94,98,101.07,102.91,106.42,107.87,112.41,114.82,118.71,121.76,127.6,126.9,131.29,132.91,137.33,138.91,140.12,140.91,144.24,145,150.36,151.96,157.25,158.93,162.5,164.93,167.26,168.93,173.04,174.97,178.49,180.95,183.84,186.21,190.23,192.22,195.08,196.97,200.59,204.38,207.2,208.98,209,210,222,223,226,227,232.04,231.04,238.03];
    
    n = length(elements);
    aN = zeros(1,n); % atomic numbers
    aW = zeros(1,n); % atomic weights
    
    loc = zeros(size(atom));
    ind = find(atom==' ');
    loc(ind+1) = (1:length(ind));
    
    for i = 1:n
        element = [elements{i},' '];
        ind = regexp(atom, element, 'once');
        aN(i) = loc(ind);
        aW(i) = weight(loc(ind));
    end
    
    electrons = sum(stoichiometry .* aN);
    molecularWeight = sum(stoichiometry .* aW);

    if(nargin == 2)
        if(isnumeric(what))
            switch what
                case 1
                    outputValue = electrons;
                case 2
                    outputValue = molecularWeight;
            end
        else
            switch lower(what)
                case {'electron', 'electrons'}
                    outputValue = electrons;
                case {'mw', 'molecularweight'}
                    outputValue = molecularWeight;
            end
        end
    else
        outputValue = [electrons, molecularWeight];
    end
    
end
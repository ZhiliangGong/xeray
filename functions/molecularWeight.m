function mw = molecularWeight(elements, stoichiometry)
% parse a string formula first, then use this function
    
    load('atomicMassTable.mat');
    
    n = length(elements);
    mass = zeros(1, n);
    for i = 1:n
        mass(i) = atomicMass(elements{i});
    end
    
    mw = sum(stoichiometry .* mass);

end
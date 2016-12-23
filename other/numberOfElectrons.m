function nE = numberOfElectrons(elements, stoichiometry)
% calculate the number of electrons in a chemical formula

    load('electronTable.mat');
    
    n = length(elements);
    number = zeros(1, n);
    for i = 1:n
        number(i) = electron(elements{i});
    end
    
    nE = sum(stoichiometry .* number);

end
function [elements,stoichiometry] = parseFormula(formula)
% parse the formula to give the elements and stoichiometry numbers

    % check errors in formula
    if ~isempty(regexp(formula, '[^[A-Z, a-z, \., 0-9]', 'once'))
        error('Formula contains illegal characters!');
    elseif isempty(regexp(formula, '^[A-Z]', 'once'))
        error('Formula should start with a capital letter!');
    elseif ~isempty(regexp(formula, '\.[0-9]\.', 'once')) || ~isempty(regexp(formula, '\.[A-Z, a-z\', 'once'))
        error('Check decimal point position!');
    end
    
    % insert 1's when missing for stoichiometry
    upperCase = (formula <= 'Z' & formula >= 'A');
    lowerCase = (formula <= 'z' & formula >= 'a');
    marker = ((upperCase | lowerCase) & [upperCase(2:end), true]);
    location = false(1, length(marker) + sum(marker));
    location(find(marker)+(1:length(find(marker)))) = true;
    formula(~location) = formula;
    formula(location) = '1';
    
    % assign logical arrays
    if length(upperCase) < length(formula)
        upperCase = (formula <= 'Z' & formula >= 'A');
        lowerCase = (formula <= 'z' & formula >= 'a');
    end
    number = ((formula <= '9' & formula >= '0') | formula == '.');
    n = sum(upperCase);
    elements = cell(1,n);
    stoichiometry = zeros(1,n);
    
    % obtain elements
    start = find(upperCase);
    finish = find((upperCase & ~[lowerCase(2:end),false]) | (lowerCase & ~[lowerCase(2:end),false]));
    for i = 1:n
        elements{i} = formula(start(i):finish(i));
    end
    
    % obtain stoichiometry numbers
    start = find(number & ~[true, number(1:end-1)]);
    finish = find(number & ~[number(2:end), false]);
    for i = 1:n
        stoichiometry(i) = str2double(formula(start(i):finish(i)));
    end

end
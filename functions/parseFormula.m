function [elements,nAtoms] = parseFormula(formula)

    n = 0;
    elements = {};
    nAtoms = {};
    try
        for i = 1:length(formula)
            c = formula(i);
            if c <= 'Z' &&  c >= 'A'
                n = n+1;
                elements{n} = c;
                nAtoms{n} = '0';
            elseif c <= 'z' &&  c >= 'a' && ((formula(i-1) <= 'Z' && formula(i-1) >= 'A') || (formula(i-1) <= 'z'&& formula(i-1) >= 'a'))
                elements{n} = [elements{n},c];
            elseif (c <= '9' &&  c >= '0') || c == '.'
                nAtoms{n} = [nAtoms{n},c];
            else
                error('Invalid chemical formula.');
            end
        end
    catch
        error('Invalid chemical formula.');
    end
    
    for i = 1:n
        nAtoms{i} = str2double(nAtoms{i});
        if nAtoms{i} == 0
            nAtoms{i} = 1;
        end
    end
    
    nAtoms = cell2mat(nAtoms);

end
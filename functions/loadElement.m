function elementStruct = loadElement(element) %load the elementEnergies file
        
    %read the whole elementEnergy file
    fname = which('elementEnergy.txt');
    text = textread(fname, '%s', 'delimiter', '\n');

    n = length(text);
    for i = 1:n
        if ~isempty(text{i}) && strcmp(text{i}(1),'#')
            if strcmpi(text{i}(2:end),element)
                break;
            end
        end
    end

    elementStruct.name = text{i}(2:end);
    
    bounds = textscan(text{i+1},'%s %f %f');
    elementStruct.range = [bounds{2},bounds{3}];
    elementStruct.peak = str2num(text{i+2}(6:end));

    elementStruct.width = str2num(text{i+3}(15:end));

end
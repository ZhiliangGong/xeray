function index = locateStringInCellArray(string, cellArray)

    for i = 1 : length(cellArray)
        if strcmp(cellArray{i}, string)
            index = i;
            break;
        end
    end

end
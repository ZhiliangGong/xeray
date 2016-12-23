function string = catStringCellArray(cellArray)
            
    string = recursiveCat('', cellArray);

    function [string, cellArray] = recursiveCat(string, cellArray)

        if ~isempty(cellArray)
            string = strcat(string, cellArray{1});
            cellArray = cellArray(2:end);
            [string, cellArray] = recursiveCat(string, cellArray);
        end

    end

end
function string = catStringCellArrayWithComma(cellArray)
            
    string = recursiveCat('', cellArray);

    function [string, cellArray] = recursiveCat(string, cellArray)

        if ~isempty(cellArray)
            if isempty(string)
                string = cellArray{1};
            else
                string = sprintf('%s, %s', string, cellArray{1});
            end
            cellArray = cellArray(2:end);
            [string, cellArray] = recursiveCat(string, cellArray);
        end

    end

end
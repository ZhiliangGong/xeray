function [string, stringArray] = stringArrayCatwithComma(string,stringArray) %concatenate string array
    if ~isempty(stringArray)
        if isempty(string)
            string = stringArray{1};
        else
            string = sprintf('%s, %s',string,stringArray{1});
        end
        stringArray = stringArray(2:end);
        [string, stringArray] = stringArrayCatwithComma(string, stringArray);
    end
end
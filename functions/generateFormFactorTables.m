function generateFormFactorTables
% read and save form factor tables

    parentPath = getParentDir(pwd);
    files = dir('../AtomicScatteringFactor/');
    files = files(3:end);
    
    formFactor = containers.Map;
    expression = '\.nff$';
    for i = 1:length(files)
        if ~isempty(regexp(files(i).name, expression, 'once'))
            fid = fopen(fullfile(parentPath,'AtomicScatteringFactor',files(i).name));
            fgetl(fid);
            data = textscan(fid, '%f %f %f');
            fclose(fid);
            data = cell2mat(data);
            data = data(data(:,1)>=29, :);
            element = strcat(upper(files(i).name(1)), files(i).name(2:end-4));
            formFactor(element) = data;
        end
    end
    
    save('formFactor', 'formFactor');

end
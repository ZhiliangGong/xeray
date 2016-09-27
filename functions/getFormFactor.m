function [f1,f2] = getFormFactor(element,energy)
    %form factors for a single element
    
    path = getParentDir(which('XeRay.m'));
    fid = fopen(fullfile(path,'AtomicScatteringFactor',strcat(lower(element),'.nff')));
    fgetl(fid);
    data = textscan(fid,'%f %f %f');
    data = cell2mat(data);
    data = data(data(:,1)>=29,:);
    fclose(fid);
    
    f1 = interp1(data(:,1),data(:,2),energy*1000,'pchip');
    f2 = interp1(data(:,1),data(:,3),energy*1000,'pchip');

end
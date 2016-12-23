function [qz, energy, spectra, specError] = readXfluo( fname )
%read an xfluo file and spit out the qz range, energy, and spec
    
    data = importdata(fname);
    line = data.textdata{1};
    if ~strcmpi(line(1:9),'e(kev)\qz')
        error('%s %s',fname,'is not a .xlfuo file.');
    else
        energy = data.data(:,1);
        spectra = data.data(:,2:2:end);
        specError = data.data(:,3:2:end);
        qz = str2num(line(10:end));
        qz = qz(1:2:end);
        if length(qz) ~= size(spectra,2)
            error('%s %s',fname,': # of qz and # of spectra should match.');
        end
    end
end
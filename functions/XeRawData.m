classdef XeRawData < handle
    
    properties
        
        energy
        intensity
        intensityError
        angle
        
    end
    
    methods
        
        function this = XeRawData(file)
            
            this.loadData(file);
            
        end
        
        function loadData(this, file)

            rawdata = importdata(file);
            line = rawdata.textdata{1};
            if ~strcmpi(line(1:9),'e(kev)\qz')
                error('%s %s',fname,'is not a .xlfuo file.');
            else
                emissionEnergy = rawdata.data(:,1);
                spectra = rawdata.data(:,2:2:end);
                specError = rawdata.data(:,3:2:end);
                qz = str2num(line(10:end));
                qz = qz(1:2:end);
                if length(qz) ~= size(spectra,2)
                    error('%s %s',fname,': # of qz and # of spectra should match.');
                end

                this.energy = emissionEnergy;
                this.intensity = spectra;
                this.intensityError = specError;
                this.angle = asin(qz * 1.24 / 4 / pi);

            end

        end
        
    end
    
end
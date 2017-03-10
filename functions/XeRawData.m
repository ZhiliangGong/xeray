classdef XeRawData < handle

    properties

        angle
        energy
        intensity
        intensityError

    end

    methods

        function this = XeRawData(file)

            this.loadData(file);

        end

        function loadData(this, file)
            
            rawdata = importdata(file);
            line = rawdata.textdata{1};
            if ~strcmpi(line(1:12),'E(kev)\Angle')
                error('%s %s',fname,'is not a .xlfuo file.');
            else
                emissionEnergy = rawdata.data(:, 1);
                spectra = rawdata.data(:, 2:2:end);
                specError = rawdata.data(:, 3:2:end);
                angles = str2num(line(13:end));
                angles = angles(1:2:end);
                if length(angles) ~= size(spectra,2)
                    error('%s %s', fname, ': # of angle and # of spectra should match.');
                end

                this.energy = emissionEnergy;
                this.intensity = spectra;
                this.intensityError = specError;
                this.angle = angles;

            end

        end

    end

end

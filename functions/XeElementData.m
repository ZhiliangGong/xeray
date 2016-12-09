classdef XeElementData < handle

    properties

        element
        angle
        energy
        intensity
        intensityError
        netIntensity
        lineshape

        config

        ElementProfiles

    end

    methods

        function this = XeElementData(config, element, rawdata, lineshape)

            this.config = config;
            this.generateElementProfiles();
            this.updateElement(element, rawdata, lineshape);

        end

        function updateElement(this, element, rawdata, lineshape)

            if nargin == 3
                lineshape = 'Gaussian';
            end

            this.element = element;
            this.angle = rawdata.angle;
            profile = this.getElementProfile(element);

            % find the energy range
            n = closestPointIndex(profile.range, rawdata.energy);
            indexRange = (n(1):n(2));

            this.energy = rawdata.energy(indexRange);
            this.intensity = rawdata.intensity(indexRange, :);
            this.intensityError = rawdata.intensityError(indexRange, :);

            N = 500;
            this.lineshape = XeLineshape(this.energy, this.intensity, this.intensityError, lineshape, profile.peaks, profile.width, N);

            this.netIntensity = this.intensity - [this.energy, ones(size(this.energy))] * this.lineshape.parameters(end-1:end, :);

        end

        function generateElementProfiles(this)

            filename = this.config{7};
            text = textread(filename, '%s', 'delimiter', '\n');
            n = sum((catStringCellArray(text) == '#'));

            table.elements = cell(1, n);
            table.peaks = cell(1, n);
            table.ranges = cell(1, n);
            table.widths = cell(1, n);

            m = length(text);
            n = 1;
            for i = 1:m
                if ~isempty(text{i}) && strcmp(text{i}(1),'#')
                    table.elements{n} = text{i}(2:end);
                    bounds = textscan(text{i+1},'%s %f %f');
                    table.ranges{n} = [bounds{2},bounds{3}];
                    table.peaks{n} = str2num(text{i+2}(6:end));
                    table.widths{n} = str2num(text{i+3}(15:end));
                    n = n + 1;
                end
            end

            this.ElementProfiles = table;

        end

        function profile = getElementProfile(this, element)

            indicator = false;
            profiles = this.ElementProfiles;
            for n = 1 : length(profiles.elements)
                if strcmp(element, profiles.elements{n})
                    profile.element = profiles.elements{n};
                    profile.peaks = profiles.peaks{n};
                    profile.range = profiles.ranges{n};
                    profile.width = profiles.widths{n};
                    indicator = true;
                    break;
                end
            end

            if ~indicator
                error('Did not find the element in the elementEnergy.txt file!');
            end

        end
        
        function angles = fineAngleRange(this, n)
            
            angles = linspace(min(this.angle), max(this.angle), n);
            
        end

    end

end

classdef XeElementData < handle

    properties

        element
        angle
        energy
        intensity
        intensityError
        netIntensity
        lineshape

        ElementProfiles

    end

    methods

        function this = XeElementData(element, rawdata, lineshape)
            
            if nargin == 2
                lineshape = 'Gaussian';
            end

            this.ElementProfiles = loadjson(fullfile(getParentDir(which('XeRay.m')), 'support-files/element-profiles.json'));
            this.updateElement(element, rawdata, lineshape);

        end

        function updateElement(this, element, rawdata, lineshape)

            if nargin == 3
                lineshape = 'Gaussian';
            end

            this.element = element;
            this.angle = rawdata.angle;
            profile = this.ElementProfiles.(element);

            % find the energy range
            n = closestPointIndex(profile.range, rawdata.energy);
            indexRange = (n(1):n(2));

            this.energy = rawdata.energy(indexRange);
            this.intensity = rawdata.intensity(indexRange, :);
            this.intensityError = rawdata.intensityError(indexRange, :);

            N = 500;
            this.lineshape = XeLineshape(this.energy, this.intensity, this.intensityError, lineshape, profile.peak, profile.width, N);

            this.netIntensity = this.intensity - [this.energy, ones(size(this.energy))] * this.lineshape.parameters(end-1:end, :);

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

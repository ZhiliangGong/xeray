classdef XeRefraction < handle
    
    properties
        
        energy
        wavelength
        dispersion
        absorption
        
        ScatteringFactorFolder
        ScatteringFactorTable
        
    end
    
    methods
        
        function this = XeRefraction(scatteringFactorFolder, energy)
            
            this.ScatteringFactorFolder = scatteringFactorFolder;
            this.energy = energy;
            this.getWavelength();
            this.generateScatteringFactorTables();
            
        end
        
        function push(this, newEnergy, varargin)
            
            this.energy = [this.energy, newEnergy];
            this.getWavelength();
            switch length(varargin)
                case 1
                    
                case 5
            end
            
        end
        
        function pop(this, indices)
            
            if max(indices) > length(this.dispersion)
                warning('This layer #%d does not exist.', max(indices));
            else
                sel = true(1, length(this.dispersion));
                sel(indices) = false;
                this.dispersion = this.dispersion(sel);
                this.absorption = this.absorption(sel);
            end
            
        end
        
        function makeSpace(this, position)
            
            sel = true(1, length(this.dispersion) + 1);
            sel(position) = false;
            this.dispersion(sel) = this.dispersion;
            this.absorption(sel) = this.absorption;
            
        end
        
        function calculateDispersionAbsorption(this, n, density, elements, stoichiometry, molecularWeight)
            % obtain dispersion and absorption from chemical formula and density

            % units
            % energy - keV
            % density - g/cm^3

            % constants
            re = 2.81794092e-15; % classical radius of electrons
            c = 299792458; % speed of light
            h = 6.626068e-34; % planck's constant
            e = 1.60217646e-19; % elemental charge
            NA = 6.02214199e23; % Avagadro's number
            wl = (c * h / e)/( this.energy * 1000); % wavelength in m

            m = length(elements);
            f1 = zeros(1, m);
            f2 = f1;
            for i = 1:length(elements)
                [f1(i),f2(i)] = this.getScatteringFactor(elements{i});
            end

            factor = wl.^2 / (2*pi) * re * NA * density * 1e6 / molecularWeight;
            this.dispersion(n) = factor * sum(stoichiometry .* f1);
            this.absorption(n) = factor * sum(stoichiometry .* f2);

        end
        
        function calculateDispersion(this, indices, electronDensity)

            % units
            % electronDensity - /A^3, for water is 0.3344
            % incidenceEnergy - keV
            % wavelength - A
            
            re = 2.81794092e-5; % classical radius for electron in A

            this.dispersion(indices) = re * electronDensity * this.wavelength^2 / 2 / pi;
            this.absorption(indices) = 0;

        end
        
        function getWavelength(this)
        % calculate the x-ray wavelength based on the energy
        % supports vectorized calculation

            % units
            % energy - keV
            % wavelength - A

            speedOfLight = 299792458;
            planckConstant = 6.626068e-34;
            kev = 1.60218e-16; % convert kev to joule

            this.wavelength = planckConstant * speedOfLight ./ (this.energy * kev) * 1e10;

        end
        
        function generateScatteringFactorTables(this)

            folder = this.ScatteringFactorFolder;
            files = dir(folder);
            files = files(3:end);

            scatteringFactor = containers.Map;
            expression = '\.nff$';
            for i = 1:length(files)
                if ~isempty(regexp(files(i).name, expression, 'once'))
                    fid = fopen(fullfile(folder, files(i).name));
                    fgetl(fid);
                    filedata = textscan(fid, '%f %f %f');
                    fclose(fid);
                    filedata = cell2mat(filedata);
                    filedata = filedata(filedata(:,1)>=29, :);
                    element = strcat(upper(files(i).name(1)), files(i).name(2:end-4));
                    scatteringFactor(element) = filedata;
                end
            end

            this.ScatteringFactorTable = scatteringFactor;

        end
        
        function [f1, f2] = getScatteringFactor(this, element)
            
            datatable = this.ScatteringFactorTable(element);

            f1 = interp1(datatable(:,1),datatable(:,2), this.energy*1000, 'pchip');
            f2 = interp1(datatable(:,1),datatable(:,3), this.energy*1000, 'pchip');
            
        end
        
        function refractionAngle = getRefractionAngle(this, angle)
            
            m = length(angle);
            angle = reshape(angle, m, 1);
            
            n = length(this.dispersion);
            dDelta = this.dispersion(2:end) - repmat( this.dispersion(1), 1, n-1 );
            dBeta = this.absorption(2:end) - repmat( this.absorption(1), 1, n-1 );
            
            refracted = sqrt( repmat(angle, 1, n-1).^2 - 2 * repmat(dDelta, m, 1) + 2i * repmat(dBeta, m, 1) );
            
            refractionAngle = [angle, refracted];
            
        end
        
    end
    
end
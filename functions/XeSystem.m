classdef XeSystem < handle
    
    properties
        
        N
        energy
        electronDensity
        thickness
        
        chemical
        refraction
        
        slit
        foot
        
        density
        
    end
    
    methods
        
        function this = XeSystem(config, energy)
            
            this.energy = energy;
            this.chemical = ChemicalFormula();
            this.refraction = XeRefraction(config, energy);
            
        end
        
        function push(this, n, varargin)

            if isempty(this.N)
                this.N = 1;
                n = 1;
            elseif n > this.N
                this.N = this.N + 1;
                n = this.N;
            end

            
            switch length(varargin)
                
                % unkown formula, give the electron density and thickness
                case 2
                    this.electronDensity(n) = varargin{1};
                    this.thickness(n) = varargin{2};
                    this.chemical.push(n);
                    
                % known formula, give the electron density, thickness, and formula
                case 3                    
                    this.electronDensity(n) = varargin{1};
                    this.thickness(n) = varargin{2};
                    this.chemical.push(n, varargin{3});
                    
                otherwise
                    error('Arguments for update layer function not right.');
            end
            
            this.getDensity(n);
            this.getRefraction(n);

        end
        
        function pop(this, indices)
            
            if max(indices) > this.N
                warning('The layer #%d does not exist.', max(indices));
            else
                sel = true(1, this.N);
                sel(indices) = false;
                this.electronDensity = this.electronDensity(sel);
                this.thickness = this.thickness(sel);
                this.density = this.density(sel);

                this.chemical.pop(indices);
                this.refraction.pop(indices);
                this.N = this.N - length(indices);
            end

        end
        
        function updateChemical(this, n, element, newStoichiometryNumber)
            
            this.chemical.update(n, element, newStoichiometryNumber);
            this.getDensity(n);
            this.getRefraction(n);

        end
        
        function updateThickness(this, indices, newThickness)
            
            this.thickness(indices) = newThickness;
            
        end
        
        function updateElectronDensity(this, indices, newElectronDensity)
            
            this.electronDensity(indices) = newElectronDensity;
            this.getDensity(indices);
            this.getRefraction(indices);
            
        end
        
        function getDensity(this, indices)
            
            this.density(indices) = this.chemical.convertEd2Density(indices, this.electronDensity(indices));
            
        end
        
        function getRefraction(this, indices)
            
            for n = indices
                if this.density(n) == 0
                    this.refraction.calculateDispersion(n, this.electronDensity(n));
                else
                    this.refraction.calculateDispersionAbsorption(n, this.density(n), this.chemical.elements{n}, this.chemical.stoichiometry{n}, this.chemical.molecularWeight(n));
                end
            end
            
        end
        
        function layerIntensity = calculateLayerIntensity(this, angle)
            
            M = length(angle);
            angle = reshape(angle, numel(angle), 1);
            refractionAngle = sqrt(repmat(angle, 1, this.N).^2 - 2 * repmat(this.refraction.dispersion, M, 1) + 2i * repmat(this.refraction.absorption, M, 1));

            theta1 = [angle, refractionAngle(:, 1:end-1)];
            theta2 = refractionAngle;
            d1 = repmat([0, this.thickness(:, 1:end-1)], M, 1);
            d2 = repmat([this.thickness(1:end-1), 0], M, 1); % calculate the intensity at the interface for the last layer

            ratio1 = (theta1 + theta2) / 2 ./ theta1;
            ratio2 = (theta1 - theta2) / 2 ./ theta1;
            expo1 = 1i * pi / this.refraction.wavelength * (theta1 .* d1 + theta2 .* d2);
            expo2 = 1i * pi / this.refraction.wavelength * (theta1 .* d1 - theta2 .* d2);

            m = zeros(M, this.N, 4);
            m(:, :, 1) = ratio1 .* exp(-expo1);
            m(:, :, 2) = ratio2 .* exp(-expo2);
            m(:, :, 3) = ratio2 .* exp(expo2);
            m(:, :, 4) = ratio1 .* exp(expo1);

            tempmatrix = cell(M, this.N);
            matrices = cell(M, this.N);
            for i = 1 : M
                for j = this.N : -1 : 1
                    tempmatrix{i, j} = reshape(m(i, j, :), 2, 2)';
                    matrices{i, j} = eye(2);
                    for k = j : this.N
                        matrices{i, j} = matrices{i, j} * tempmatrix{i, k};
                    end
                end
            end

            tamp = zeros(M, this.N);
            ramp = zeros(M, this.N);

            ramp(:, end) = 0;
            for i = 1 : M
                tamp(i, end) = 1 / matrices{i, 1}(1, 1);
            end

            for i = 1 : M
                for j = 1 : this.N - 1
                    tamp(i, j) = matrices{i, j+1}(1, 1) * tamp(i, end);
                    ramp(i, j) = matrices{i, j+1}(2, 1) * tamp(i, end);
                end
            end


            phaseLength = cumsum([0, this.thickness(1:end-1)]) - [this.thickness(1:end-1), 0] / 2;
            phaseShift = 2 * pi / this.refraction.wavelength * refractionAngle .* repmat(phaseLength, M, 1);
            transmission = tamp .* exp( 1i * phaseShift );
            reflection = ramp .* exp( -1i * phaseShift );

            alpha = repmat(angle, 1, this.N);
            delta = repmat(this.refraction.dispersion, M, 1);
            beta = repmat(this.refraction.absorption, M, 1);
            penetration = this.refraction.wavelength / 4 / pi ./ imag( sqrt( alpha.^2 - 2 * delta + 2i * beta ) );

            % intensity below each of the interface
            z = repmat(cumsum([0, this.thickness]), M, 1);
            attenuation = exp( - z(:,1:end-1) ./ [ones(M, 1), penetration(:, 1:end-1)]);
            layerIntensity = abs((transmission + reflection).^2) .* attenuation;

            % integrated intensity for each layer
            zdiff = z(:, 2:end) - z(:, 1:end-1);
            integralFactor = penetration .* (exp(-z(:, 1:end-1) ./ penetration) - exp(-z(:, 2:end) ./ penetration));
            infIndex = (penetration == Inf);
            integralFactor(infIndex) = zdiff(infIndex);
            layerIntensity = layerIntensity .* integralFactor;
            
        end
        
        function fluoIntensity = calculateFluoIntensity(this, element, angle)

            layerIntensity = this.calculateLayerIntensity(angle);
            
            location = zeros(1, this.N); % locate which layer the element is in
            for i = 1 : length(this.chemical.elements)
                if ~isempty(this.chemical.elements{i})
                    for j = 1 : length(this.chemical.elements{i})
                        if strcmp(this.chemical.elements{i}{j}, element)
                            location(i) = 1;
                            break;
                        end
                    end
                end
            end

            fluoIntensity = sum(repmat(location, length(angle), 1) .* layerIntensity, 2)';

        end
        
    end
    
end
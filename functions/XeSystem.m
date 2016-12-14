classdef XeSystem < handle
    
    properties
        
        N
        angle
        offset
        incidence
        emission
        slit
        foot
        
        electronDensity
        thickness
        
        chemical
        
        density
        concentration
        layerIntensity
        
    end
    
    methods
        
        function this = XeSystem(incidenceEnergy, emissionEnergy, slit, foot, angle, ScatteringFactorFolder)
            
            this.slit = slit;
            this.foot = foot;
            this.angle = angle;
            this.offset = 0;
            this.incidence = XeRefraction(ScatteringFactorFolder, incidenceEnergy);
            this.emission = XeRefraction(ScatteringFactorFolder, emissionEnergy);
            this.chemical = ChemicalFormula();
            
        end
        
        function a = offsetAngle(this)
            
            a = this.angle + this.offset;
            
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
            
            this.concentration(n) = 0;
            this.getDensity(n);
            this.getRefractionProperties(n);
            this.getLayerIntegratedIntensity();

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
                this.concentration = this.concentration(sel);
                this.layerIntensity = this.layerIntensity(:, sel);

                this.chemical.pop(indices);
                this.incidence.pop(indices);
                this.emission.pop(indices);
                this.N = this.N - length(indices);
            end

        end
        
        function insert(this, position, varargin)
            
            if ~isempty(this.N) && position > this.N
                warning('The insertion position must be within the current number of layers.')
            else
                this.N = this.N + 1;
                sel = true(1, this.N);
                sel(position) = false;
                this.electronDensity(sel) = this.electronDensity;
                this.thickness(sel) = this.thickness;
                this.density(sel) = this.density;
                this.concentration(sel) = this.concentration;
                this.layerIntensity(:, sel) = this.layerIntensity;

                this.chemical.makeSpace(position);
                this.incidence.makeSpace(position);
                this.emission.makeSpace(position);
                
                this.push(position, varargin{:});
            end
            
        end
        
        function updateChemical(this, n, element, newStoichiometryNumber)
            
            this.chemical.update(n, element, newStoichiometryNumber);
            this.getDensity(n);
            this.getRefractionProperties(n);
            this.getLayerIntegratedIntensity();

        end
        
        function updateThickness(this, indices, newThickness)
            
            this.thickness(indices) = newThickness;
            this.getLayerIntegratedIntensity();
            
        end
        
        function updateElectronDensity(this, indices, newElectronDensity)
            
            this.electronDensity(indices) = newElectronDensity;
            this.getDensity(indices);
            this.getRefraction(indices);
            this.getLayerIntegratedIntensity();
            
        end
        
        function updateOffset(this, offset)
            
            this.offset = offset;
            this.getLayerIntegratedIntensity();
            
        end
        
        function getDensity(this, indices)
            
            this.density(indices) = this.chemical.convertEd2Density(indices, this.electronDensity(indices));
            
        end
        
        function getRefractionProperties(this, indices, what)
            
            if nargin == 2
                what = 'both';
            end
            
            for n = indices
                if this.density(n) == 0
                    switch what
                        case 'incidence'
                            this.incidence.calculateDispersion(n, this.electronDensity(n));
                        case 'emission'
                            this.emission.calculateDispersion(n, this.electronDensity(n));
                        case 'both'
                            this.incidence.calculateDispersion(n, this.electronDensity(n));
                            this.emission.calculateDispersion(n, this.electronDensity(n));
                    end
                else
                    switch what
                        case 'incidence'
                            this.incidence.calculateDispersionAbsorption(n, this.density(n), this.chemical.elements{n}, this.chemical.stoichiometry{n}, this.chemical.molecularWeight(n));
                        case 'emission'
                            this.emission.calculateDispersionAbsorption(n, this.density(n), this.chemical.elements{n}, this.chemical.stoichiometry{n}, this.chemical.molecularWeight(n));
                        case 'both'
                            this.incidence.calculateDispersionAbsorption(n, this.density(n), this.chemical.elements{n}, this.chemical.stoichiometry{n}, this.chemical.molecularWeight(n));
                            this.emission.calculateDispersionAbsorption(n, this.density(n), this.chemical.elements{n}, this.chemical.stoichiometry{n}, this.chemical.molecularWeight(n));
                    end
                end
            end
            
        end
        
        function intensity = calculateElementFluoIntensity(this, element, angles)
            
            if nargin == 2
                angles = this.offsetAngle;
            end
            
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

            intensity = sum(repmat(location, length(angles), 1) .* this.layerIntensity, 2)';

        end
        
        function intensity = getLayerIntegratedIntensityForAngles(this, angles)
            
            if nargin == 1
                angles = reshape(this.offsetAngle, length(this.offsetAngle), 1);
            else
                angles = reshape(angles, length(angles), 1);
            end
            
            if this.thickness(end) ~= Inf
                error('The last layer must have infinite thickness.')
            end
            
            slits = this.slit * 1e7;
            foots = this.foot * 1e7;
            
            m = length(angles);
            n = this.N;
            
            refractionAngle = this.incidence.getRefractionAngle(angles);
            
            theta1 = [angles, refractionAngle(:, 1:end-1)];
            theta2 = refractionAngle;
            d1 = repmat([0, this.thickness(1:end-1)], m, 1);
            d2 = repmat([this.thickness(1:end-1), 0], m, 1); % calculate the intensity at the interface for the last layer

            ratio1 = (theta1 + theta2) / 2 ./ theta1;
            ratio2 = (theta1 - theta2) / 2 ./ theta1;
            expo1 = 1i * pi / this.incidence.wavelength * (theta1 .* d1 + theta2 .* d2);
            expo2 = 1i * pi / this.incidence.wavelength * (theta1 .* d1 - theta2 .* d2);
            
            M = zeros(m, n, 4);
            M(:, :, 1) = ratio1 .* exp(-expo1);
            M(:, :, 2) = ratio2 .* exp(-expo2);
            M(:, :, 3) = ratio2 .* exp(expo2);
            M(:, :, 4) = ratio1 .* exp(expo1);
            
            tempmatrix = cell(m, n);
            matrices = cell(m, n);
            for i = 1 : m
                for j = n : -1 : 1
                    tempmatrix{i, j} = reshape(M(i, j, :), 2, 2)';
                    matrices{i, j} = eye(2);
                    for k = j : n
                        matrices{i, j} = matrices{i, j} * tempmatrix{i, k};
                    end
                end
            end

            tamp = zeros(m, n);
            ramp = zeros(m, n);
            
            ramp(:, end) = 0;
            for i = 1 : m
                tamp(i, end) = 1 / matrices{i, 1}(1, 1);
            end

            for i = 1 : m
                for j = 1 : n - 1
                    tamp(i, j) = matrices{i, j+1}(1, 1) * tamp(i, end);
                    ramp(i, j) = matrices{i, j+1}(2, 1) * tamp(i, end);
                end
            end
            
            phaseLength = cumsum([0, this.thickness(1:end-1)]) - [this.thickness(1:end-1), 0] / 2;
            phaseShift = 2 * pi / this.incidence.wavelength * refractionAngle .* repmat(phaseLength, m, 1);
            transmission = tamp .* exp( 1i * phaseShift );
            reflection = ramp .* exp( -1i * phaseShift );

            alpha = repmat(angles, 1, n);
            delta = repmat(this.incidence.dispersion, m, 1);
            beta = repmat(this.incidence.absorption, m, 1);
            
            alpha1 = pi/2;
            delta1 = repmat(this.emission.dispersion, m, 1);
            beta1 = repmat(this.emission.absorption, m, 1);
            
            p0 = this.incidence.wavelength / 4 / pi ./ imag( sqrt( alpha.^2 - 2 * delta + 2i * beta ) );
            p1 = this.emission.wavelength / 4 / pi ./ imag( sqrt( alpha1.^2 - 2 * delta1 + 2i * beta1 ) );
            
            location = ~(p1 == Inf);
            
            penetration = p0;
            penetration(location) = p0(location) .* p1(location) ./ (p0(location) + p1(location));
            
            % intensity below each of the interface
            z = repmat(cumsum([0, this.thickness]), m, 1);
            attenuation = exp( - z(:,1:end-1) ./ [ones(m, 1), penetration(:, 1:end-1)]);
            intensity = abs((transmission + reflection).^2) .* attenuation;
            
            % integrate for the top thin layers
            zdiff = repmat(this.thickness, m, 1);
            
            integralFactor = penetration(:, 1:end-1) .* (exp(-z(:, 1:end-2) ./ penetration(:, 1:end-1)) - exp(-z(:, 2:end-1) ./ penetration(:, 1:end-1)));
            location = (penetration == Inf);
            integralFactor(location) = zdiff(location);
            intensity(:, 1:end-1) = intensity(:, 1:end-1) .* integralFactor;
            
            larger = slits./sin(angles) > foots;
            smaller = ~larger;
            larger(end) = false;
            smaller(end) = false;
            intensity(larger, 1:end-1) = intensity(larger, 1:end-1) * foots;
            intensity(smaller, 1:end-1) = intensity(smaller, 1:end-1) * slits ./ alpha(smaller, 1:end-1);
            
            % integrate for the bottom infinite layer
            larger = slits./sin(angles) > foots;
            
            term0 = zeros(size(angles));
            term0(larger) = ones(sum(larger), 1) * foots;
            term0(~larger) = slits ./ sin(angles(~larger));
            
            L = penetration(:, end);
            term1 = L ./ tan(angles) .* exp( -(tan(angles) ./ L .* (slits / 2 ./ sin(angles) + foots / 2)) );
            term2 = L ./ tan(angles) .* exp( -(tan(angles) ./ L .* abs(slits / 2 ./ sin(angles) - foots / 2)) );
            
            intensity(:, end) = intensity(:, end) .* L .* (term0 + term1 - term2);
            
            intensity = intensity / 1e14;
            
        end
        
        function getLayerIntegratedIntensity(this)
            
            this.layerIntensity = this.getLayerIntegratedIntensityForAngles();
            
        end
        
        function intensity = calculateFluoIntensity(this, P)
            
            % P: angle offset, scale factor, background, concentration, and
            % layer index
            
            if P(1) ~= this.offset
                this.updateOffset(P(1));
            end
            
            if P(5) ~= 0
                this.concentration(P(5)) = P(4);
            end
            
            intensity = sum(repmat(this.concentration, length(this.offsetAngle()), 1) .* this.layerIntensity, 2)' * P(2) + P(3);
            
        end
        
        function intensity = calculateFluoIntensityCurve(this, P, angles)
            
            if P(1) ~= this.offset
                this.updateOffset(P(1));
            end
            
            if P(5) ~= 0
                this.concentration(P(5)) = P(4);
            end
            
            intensity = sum(repmat(this.concentration, length(angles), 1) .* this.getLayerIntegratedIntensityForAngles(angles), 2)' * P(2) + P(3);
            
        end
        
        function intensity = calculateFluoIntensityWithBounds(this, start, lower, upper)
            
            % parameters: parameters being fitted, with the last one being
            % the layer index
            fixed = (lower == upper);
            P = zeros(1, 5);
            P(fixed) = lower(fixed);
            P(~fixed) = start;
            
            intensity = this.calculateFluoIntensity(P);
            
        end
        
    end
    
end
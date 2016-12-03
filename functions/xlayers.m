classdef xlayers < handle
    % tratified layer structure for x-ray fluorescence
    % this class holds the general information of each layer
    
    properties
        
        % basic
        N % number of layers
        M % number of incidence angles
        
        % inputs
        electronDensity
        thickness
        formula
        
        % dependent on the formula
        elements
        stoichiometry
        molecularWeight
        electronNumber
        
        % dependent on the formula and electron density
        density
        
        % refraction properties
        energy
        wavelength
        dispersion
        absorption
        
        % optics
        angle % an array, m x 1, in radian
        refracAngle % refraction angle, m x n
        transmission % complex amplitude
        reflection % complex amplitude
        penetration % depth in A
        layerIntensity % relative to incoming beam intensity at the start of each layer
        
        % fitting
        chosenElement
        fluoIntensity
        
        % supporting database
        ElectronTable
        AtomicMassTable
        FormFactorTable
        
    end
    
    methods
        
        % construct an instance, and load the supporting database
        function s = xlayers
            
            s.generateSupportDatabase;
            
        end
        
        % add a layer, calculate refraction index
        function updateLayer(s, n, varargin)
            
            if isempty(s.N)
                s.N = 1;
                n = 1;
            elseif n > s.N
                s.N = s.N + 1;
                n = s.N;
            end
            
            switch length(varargin)
                case 2 % unkown formula, give the electron density and thickness
                    s.electronDensity(n) = varargin{1};
                    s.thickness(n) = varargin{2};
                case 3 % known formula, give the electron density, thickness, and formula
                    s.electronDensity(n) = varargin{1};
                    s.thickness(n) = varargin{2};
                    s.formula{n} = varargin{3};
                    s.parseFormula(n);
                    s.getDensity(n);
                otherwise
                    error('Arguments for push function not right.');
            end
            
        end
        
        % remove a layer
        function removeLayer(s, n)
            
            if n > s.N
                error('The layer #%d does not exist.', n);
            end
            
            sel = true(1, s.N);
            s.N = s.N - 1;
            sel(n) = false;
            
            s.electronDensity = s.electronDensity(sel);
            s.thickness = s.thickness(sel);
            s.formula = s.formula(sel);
            s.elements = s.elements(sel);
            s.stoichiometry = s.stoichiometry(sel);
            s.molecularWeight = s.molecularWeight(sel);
            s.electronNumber = s.electronNumber(sel);
            s.density = s.density(sel);
            
        end
        
        % update layer formula
        function updateFormula(s, n, element, newStoichiometryNumber)
            % leading to changes in parsed formula, number of electrons,
            % stoichiometry, and density
            
            for i = 1 : length(s.elements{n})
                if strcmp(s.elements{n}{i}, element)
                    s.stoichiometry{n}(i) = newStoichiometryNumber;
                    
                    newFormula = '';
                    for j = 1 : length(s.elements{n})
                        newFormula = strcat(newFormula, s.elements{n}{j}, num2str(s.stoichiometry{n}(j)));
                    end
                    s.formula{n} = newFormula;
                    s.parseFormula(n);
                    s.getDensity(n);
                    break;
                end
            end
            
        end
        
        % calculate x-ray optical properties
        function calculateRefractionIndex(s, energy, indices)
            
            s.energy = energy;
            s.getWavelength;
            
            if nargin == 2
                indices = 1 : s.N;
            end
            
            
            
            for k = indices
                if s.energy < 0.003
                    error('X-ray energy must be larger than 3 eV.');
                else
                    if s.density(k)
                        s.calculateDispersionAbsorption(k);
                    else
                        s.calculateDispersion(k);
                    end
                end
            end
            
        end
        
        % calculate the detailed optics
        function optics(s, angle)
            
            s.M = length(angle);
            s.angle = reshape(angle, numel(angle), 1);
            s.refracAngle = sqrt(repmat(s.angle, 1, s.N).^2 - 2 * repmat(s.dispersion, s.M, 1) + 2i * repmat(s.absorption, s.M, 1));
            
            % calculate the refraction matrices
            if s.thickness(end) ~= Inf
                error('The last layer must have infinite thickness.');
            end
            
            theta1 = [s.angle, s.refracAngle(:, 1:end-1)];
            theta2 = s.refracAngle;
            d1 = repmat([0, s.thickness(:, 1:end-1)], s.M, 1);
            d2 = repmat([s.thickness(1:end-1), 0], s.M, 1); % calculate the intensity at the interface for the last layer
            
            ratio1 = (theta1 + theta2) / 2 ./ theta1;
            ratio2 = (theta1 - theta2) / 2 ./ theta1;
            expo1 = 1i * pi / s.wavelength * (theta1 .* d1 + theta2 .* d2);
            expo2 = 1i * pi / s.wavelength * (theta1 .* d1 - theta2 .* d2);
            
            m = zeros(s.M, s.N, 4);
            m(:, :, 1) = ratio1 .* exp(-expo1);
            m(:, :, 2) = ratio2 .* exp(-expo2);
            m(:, :, 3) = ratio2 .* exp(expo2);
            m(:, :, 4) = ratio1 .* exp(expo1);
            
            tempmatrix = cell(s.M, s.N);
            matrices = cell(s.M, s.N);
            for i = 1 : s.M
                for j = s.N : -1 : 1
                    tempmatrix{i, j} = reshape(m(i, j, :), 2, 2)';
                    matrices{i, j} = eye(2);
                    for k = j : s.N
                        matrices{i, j} = matrices{i, j} * tempmatrix{i, k};
                    end
                end
            end
            
            tamp = zeros(s.M, s.N);
            ramp = zeros(s.M, s.N);
            
            ramp(:, end) = 0;
            for i = 1 : s.M
                tamp(i, end) = 1 / matrices{i, 1}(1, 1);
            end
            
            for i = 1 : s.M
                for j = 1 : s.N - 1
                    tamp(i, j) = matrices{i, j+1}(1, 1) * tamp(i, end);
                    ramp(i, j) = matrices{i, j+1}(2, 1) * tamp(i, end);
                end
            end
            
            
            phaseLength = cumsum([0, s.thickness(1:end-1)]) - [s.thickness(1:end-1), 0] / 2;
            phaseShift = 2 * pi / s.wavelength * s.refracAngle .* repmat(phaseLength, s.M, 1);
            s.transmission = tamp .* exp( 1i * phaseShift );
            s.reflection = ramp .* exp( -1i * phaseShift );
            
            alpha = repmat(s.angle, 1, s.N);
            delta = repmat(s.dispersion, s.M, 1);
            beta = repmat(s.absorption, s.M, 1);
            s.penetration = s.wavelength / 4 / pi ./ imag( sqrt( alpha.^2 - 2 * delta + 2i * beta ) );
            
            % intensity below each of the interface
            z = repmat(cumsum([0, s.thickness]), s.M, 1);
            attenuation = exp( - z(:,1:end-1) ./ [ones(s.M, 1), s.penetration(:, 1:end-1)]);
            s.layerIntensity = abs((s.transmission + s.reflection).^2) .* attenuation;
            
            % integrated intensity for each layer
            zdiff = z(:, 2:end) - z(:, 1:end-1);
            integralFactor = s.penetration .* (exp(-z(:, 1:end-1) ./ s.penetration) - exp(-z(:, 2:end) ./ s.penetration));
            infIndex = (s.penetration == Inf);
            integralFactor(infIndex) = zdiff(infIndex);
            s.layerIntensity = s.layerIntensity .* integralFactor;
            
        end
        
        % calculate the intensity for a given element
        function calculateFluoIntensity(s, element)
            
            s.chosenElement = element;
            
            location = zeros(1, s.N); % locate which layer the element is in
            for i = 1 : length(s.elements)
                if ~isempty(s.elements{i})
                    for j = 1 : length(s.elements{i})
                        if strcmp(s.elements{i}{j}, element)
                            location(i) = 1;
                            break;
                        end
                    end
                end
            end
            
            s.fluoIntensity = sum(repmat(location, s.M, 1) .* s.layerIntensity, 2);
            
        end
        
        % calculate dispersion and absorption
        function calculateDispersionAbsorption(s, k)
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
            wl = (c * h / e)/( s.energy * 1000); % wavelength in m

            n = length(s.elements{k});
            f1 = zeros(1, n);
            f2 = f1;
            for i = 1:length(s.elements{k})
                [f1(i),f2(i)] = getFormFactor(s.elements{k}{i}, s.energy);
            end

            factor = wl.^2 / (2*pi) * re * NA * s.density(k) * 1e6 / molecularWeight(s.elements{k},s.stoichiometry{k});
            s.dispersion(k) = factor * sum(s.stoichiometry{k} .* f1);
            s.absorption(k) = factor * sum(s.stoichiometry{k} .* f2);

        end
        
        % calculate dispersion only based on electron density
        function calculateDispersion(s, k)

            % units
            % electronDensity - /A^3, for water is 0.3344
            % energy - keV
            % wavelength - A

            re = 2.81794092e-5; % classical radius for electron in A

            s.dispersion(k) = re * s.electronDensity(k) * s.wavelength^2 / 2 / pi;

        end
        
        % generate supporting database
        function generateSupportDatabase(s)
            
            load('electronTable.mat');
            load('atomicMassTable.mat');
            load('formFactor.mat');
            
            s.ElectronTable = electron;
            s.AtomicMassTable = atomicMass;
            s.FormFactorTable = formFactor;
            
        end
        
        % parse formula, handle indices as a vector
        function parseFormula(s, indices)
            % parse the formula, calculate the molecular weight, and the
            % number of electrons in the formula
            
            for k = indices
                
                f = s.formula{k};
                if isempty(f)
                    error('The chemical formula for layer %d does not exist!', n);
                end

                % check errors in formula
                if ~isempty(regexp(f, '[^[A-Z, a-z, \., 0-9]', 'once'))
                    error('Formula contains illegal characters!');
                elseif isempty(regexp(f, '^[A-Z]', 'once'))
                    error('Formula should start with a capital letter!');
                elseif ~isempty(regexp(f, '\.[0-9]\.', 'once')) || ~isempty(regexp(f, '\.[A-Z, a-z\', 'once'))
                    error('Check decimal point position!');
                end

                % insert 1's when missing for stoichiometry
                upperCase = (f <= 'Z' & f >= 'A');
                lowerCase = (f <= 'z' & f >= 'a');
                marker = ((upperCase | lowerCase) & [upperCase(2:end), true]);
                location = false(1, length(marker) + sum(marker));
                location(find(marker)+(1:length(find(marker)))) = true;
                f(~location) = f;
                f(location) = '1';

                % assign logical arrays
                if length(upperCase) < length(f)
                    upperCase = (f <= 'Z' & f >= 'A');
                    lowerCase = (f <= 'z' & f >= 'a');
                end
                number = ((f <= '9' & f >= '0') | f == '.');
                n = sum(upperCase);
                s.elements{k} = cell(1,n);
                s.stoichiometry{k} = zeros(1,n);

                % obtain elements
                start = find(upperCase);
                finish = find((upperCase & ~[lowerCase(2:end),false]) | (lowerCase & ~[lowerCase(2:end),false]));
                for i = 1:n
                    s.elements{k}{i} = f(start(i):finish(i));
                end

                % obtain stoichiometry numbers
                start = find(number & ~[true, number(1:end-1)]);
                finish = find(number & ~[number(2:end), false]);
                for i = 1:n
                    s.stoichiometry{k}(i) = str2double(f(start(i):finish(i)));
                end
                
                % molecular weight and number of electrons
                n = length(s.elements{k});
                mass = zeros(1, n);
                number = zeros(1, n);
                for i = 1:n
                    mass(i) = s.AtomicMassTable(s.elements{k}{i});
                    number(i) = s.ElectronTable(s.elements{k}{i});
                end
                s.molecularWeight(k) = sum(s.stoichiometry{k} .* mass);
                s.electronNumber(k) = sum(s.stoichiometry{k} .* number);
                
            end
            
        end
        
        % convert energy (kev) to wavelength
        function getWavelength(s)
        % calculate the x-ray wavelength based on the energy
        % supports vectorized calculation

            % units
            % energy - keV
            % wavelength - A

            speedOfLight = 299792458;
            planckConstant = 6.626068e-34;
            kev = 1.60218e-16; % convert kev to joule

            s.wavelength = planckConstant * speedOfLight ./ (s.energy * kev) * 1e10;

        end
        
        % get the density
        function getDensity(s, indices)
            
            NA = 6.02214199e23; % Avagadro's Number
            s.density(indices) = s.electronDensity(indices) ./ s.electronNumber(indices) / NA .* s.molecularWeight(indices) * 1e24;
            
        end
        
    end
    
end
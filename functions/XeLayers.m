classdef XeLayers < handle
    % tratified layer structure for x-ray fluorescence
    % this class holds the general information of each layer
    
    properties
        
        % basic
        N % number of layers
        M % number of incidence angles
        
        % system
        composition
        refraction
        optics
        
        % fitting
        data
        fit
        
        % supporting database
        ElectronTable
        AtomicMassTable
        FormFactorTable
        
    end
    
    methods
        
        % construct an instance, and load the supporting database
        function s = XeLayers
            
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
                case 2 % unkown formula, give the electron density and depth
                    s.composition.electronDensity(n) = varargin{1};
                    s.composition.depth(n) = varargin{2};
                case 3 % known formula, give the electron density, depth, and formula
                    s.composition.electronDensity(n) = varargin{1};
                    s.composition.depth(n) = varargin{2};
                    s.composition.formula{n} = varargin{3};
                    s.parseFormula(n);
                    s.getDensity(n);
                otherwise
                    error('Arguments for push function not right.');
            end
            
        end
        
        % remove a layer
        function popLayer(s, n)
            
            if n > s.N
                error('The layer #%d does not exist.', n);
            end
            
            sel = true(1, s.N);
            s.N = s.N - 1;
            sel(n) = false;
            
            s.composition.electronDensity = s.composition.electronDensity(sel);
            s.composition.depth = s.composition.depth(sel);
            s.composition.formula = s.composition.formula(sel);
            s.composition.elements = s.composition.elements(sel);
            s.composition.stoichiometry = s.composition.stoichiometry(sel);
            s.composition.molecularWeight = s.composition.molecularWeight(sel);
            s.composition.electronNumber = s.composition.electronNumber(sel);
            s.composition.density = s.composition.density(sel);
            
        end
        
        % update layer formula
        function updateFormula(s, n, element, newStoichiometryNumber)
            % leading to changes in parsed formula, number of electrons,
            % stoichiometry, and density
            
            for i = 1 : length(s.composition.elements{n})
                if strcmp(s.composition.elements{n}{i}, element)
                    s.composition.stoichiometry{n}(i) = newStoichiometryNumber;
                    
                    newFormula = '';
                    for j = 1 : length(s.composition.elements{n})
                        newFormula = strcat(newFormula, s.composition.elements{n}{j}, num2str(s.composition.stoichiometry{n}(j)));
                    end
                    s.composition.formula{n} = newFormula;
                    s.parseFormula(n);
                    s.getDensity(n);
                    break;
                end
            end
            
        end
        
        % calculate x-ray optical properties
        function calculateRefractionIndex(s, energy, indices)
            
            s.refraction.energy = energy;
            s.getWavelength;
            
            if nargin == 2
                indices = 1 : s.N;
            end
            
            
            for k = indices
                if s.refraction.energy < 0.003
                    error('X-ray energy must be larger than 3 eV.');
                else
                    if s.composition.density(k)
                        s.calculateDispersionAbsorption(k);
                    else
                        s.calculateDispersion(k);
                    end
                end
            end
            
        end
        
        % calculate the detailed optics
        function calculateOptics(s, angle)
            
            s.M = length(angle);
            s.optics.angle = reshape(angle, numel(angle), 1);
            s.optics.refracAngle = sqrt(repmat(s.optics.angle, 1, s.N).^2 - 2 * repmat(s.refraction.dispersion, s.M, 1) + 2i * repmat(s.refraction.absorption, s.M, 1));
            
            % calculate the refraction matrices
            if s.composition.depth(end) ~= Inf
                error('The last layer must have infinite depth.');
            end
            
            theta1 = [s.optics.angle, s.optics.refracAngle(:, 1:end-1)];
            theta2 = s.optics.refracAngle;
            d1 = repmat([0, s.composition.depth(:, 1:end-1)], s.M, 1);
            d2 = repmat([s.composition.depth(1:end-1), 0], s.M, 1); % calculate the intensity at the interface for the last layer
            
            ratio1 = (theta1 + theta2) / 2 ./ theta1;
            ratio2 = (theta1 - theta2) / 2 ./ theta1;
            expo1 = 1i * pi / s.refraction.wavelength * (theta1 .* d1 + theta2 .* d2);
            expo2 = 1i * pi / s.refraction.wavelength * (theta1 .* d1 - theta2 .* d2);
            
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
            
            
            phaseLength = cumsum([0, s.composition.depth(1:end-1)]) - [s.composition.depth(1:end-1), 0] / 2;
            phaseShift = 2 * pi / s.refraction.wavelength * s.optics.refracAngle .* repmat(phaseLength, s.M, 1);
            s.optics.transmission = tamp .* exp( 1i * phaseShift );
            s.optics.reflection = ramp .* exp( -1i * phaseShift );
            
            alpha = repmat(s.optics.angle, 1, s.N);
            delta = repmat(s.refraction.dispersion, s.M, 1);
            beta = repmat(s.refraction.absorption, s.M, 1);
            s.optics.penetration = s.refraction.wavelength / 4 / pi ./ imag( sqrt( alpha.^2 - 2 * delta + 2i * beta ) );
            
            % intensity below each of the interface
            z = repmat(cumsum([0, s.composition.depth]), s.M, 1);
            attenuation = exp( - z(:,1:end-1) ./ [ones(s.M, 1), s.optics.penetration(:, 1:end-1)]);
            s.optics.layerIntensity = abs((s.optics.transmission + s.optics.reflection).^2) .* attenuation;
            
            % integrated intensity for each layer
            zdiff = z(:, 2:end) - z(:, 1:end-1);
            integralFactor = s.optics.penetration .* (exp(-z(:, 1:end-1) ./ s.optics.penetration) - exp(-z(:, 2:end) ./ s.optics.penetration));
            infIndex = (s.optics.penetration == Inf);
            integralFactor(infIndex) = zdiff(infIndex);
            s.optics.layerIntensity = s.optics.layerIntensity .* integralFactor;
            
        end
        
        % calculate the intensity for a given element
        function calculateFluoIntensity(s, element)
            
            s.fit.chosenElement = element;
            
            location = zeros(1, s.N); % locate which layer the element is in
            for i = 1 : length(s.composition.elements)
                if ~isempty(s.composition.elements{i})
                    for j = 1 : length(s.composition.elements{i})
                        if strcmp(s.composition.elements{i}{j}, element)
                            location(i) = 1;
                            break;
                        end
                    end
                end
            end
            
            s.fit.fluoIntensity = sum(repmat(location, s.M, 1) .* s.optics.layerIntensity, 2);
            
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
            wl = (c * h / e)/( s.refraction.energy * 1000); % wavelength in m

            n = length(s.composition.elements{k});
            f1 = zeros(1, n);
            f2 = f1;
            for i = 1:length(s.composition.elements{k})
                [f1(i),f2(i)] = getFormFactor(s.composition.elements{k}{i}, s.refraction.energy);
            end

            factor = wl.^2 / (2*pi) * re * NA * s.composition.density(k) * 1e6 / molecularWeight(s.composition.elements{k},s.composition.stoichiometry{k});
            s.refraction.dispersion(k) = factor * sum(s.composition.stoichiometry{k} .* f1);
            s.refraction.absorption(k) = factor * sum(s.composition.stoichiometry{k} .* f2);

        end
        
        % calculate dispersion only based on electron density
        function calculateDispersion(s, k)

            % units
            % electronDensity - /A^3, for water is 0.3344
            % energy - keV
            % wavelength - A

            re = 2.81794092e-5; % classical radius for electron in A

            s.refraction.dispersion(k) = re * s.composition.electronDensity(k) * s.refraction.wavelength^2 / 2 / pi;

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
                
                f = s.composition.formula{k};
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
                s.composition.elements{k} = cell(1,n);
                s.composition.stoichiometry{k} = zeros(1,n);

                % obtain elements
                start = find(upperCase);
                finish = find((upperCase & ~[lowerCase(2:end),false]) | (lowerCase & ~[lowerCase(2:end),false]));
                for i = 1:n
                    s.composition.elements{k}{i} = f(start(i):finish(i));
                end

                % obtain stoichiometry numbers
                start = find(number & ~[true, number(1:end-1)]);
                finish = find(number & ~[number(2:end), false]);
                for i = 1:n
                    s.composition.stoichiometry{k}(i) = str2double(f(start(i):finish(i)));
                end
                
                % molecular weight and number of electrons
                n = length(s.composition.elements{k});
                mass = zeros(1, n);
                number = zeros(1, n);
                for i = 1:n
                    mass(i) = s.AtomicMassTable(s.composition.elements{k}{i});
                    number(i) = s.ElectronTable(s.composition.elements{k}{i});
                end
                s.composition.molecularWeight(k) = sum(s.composition.stoichiometry{k} .* mass);
                s.composition.electronNumber(k) = sum(s.composition.stoichiometry{k} .* number);
                
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

            s.refraction.wavelength = planckConstant * speedOfLight ./ (s.refraction.energy * kev) * 1e10;

        end
        
        % get the density
        function getDensity(s, indices)
            
            NA = 6.02214199e23; % Avagadro's Number
            s.composition.density(indices) = s.composition.electronDensity(indices) ./ s.composition.electronNumber(indices) / NA .* s.composition.molecularWeight(indices) * 1e24;
            
        end
        
        % add data file
        function loadData(s, file)
            
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
                
                s.data.energy = emissionEnergy;
                s.data.spectra = spectra;
                s.data.specError = specError;
                s.data.angle = asin(qz * s.refraction.wavelength / 4 / pi);
                
            end
            
        end
        
    end
    
end
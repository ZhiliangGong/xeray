classdef xlayers < handle
    % tratified layer structure for x-ray fluorescence
    % this class holds the general information of each layer
    
    properties
        % basic
        N
        density
        electronDensity
        thickness
        formula
        
        % processed
        elements
        stoichiometry
        
        % refraction properties
        energy
        wavelength
        dispersion
        absorption
        
        % optics
        angle % an array, m x 1
        rangle % refraction angle, m x n
        matrices
        transmission % complex amplitude
        reflection % complex amplitude
        penetration % depth in A
        intensity % relative to incoming beam intensity
        
        % fitting
        fitElement
        fluoIntensity
        
    end
    
    methods
        
        % construct an instance
        function s = xlayers(n)
            
            s.N = n;
            s.formula = cell(1, n);
            s.density = zeros(1, n);
            s.electronDensity = zeros(1, n);
            s.thickness = zeros(1, n);
            s.elements = cell(1, n);
            s.stoichiometry = cell(1, n);
            s.dispersion = zeros(1, n);
            s.absorption = zeros(1, n);
            
        end
        
        % add a layer
        function push(s, varargin)
            switch length(varargin)
                case 3 % unkown formula, give the electron density and thickness
                    n = varargin{1};
                    s.electronDensity(n) = varargin{2};
                    s.thickness(n) = varargin{3};
                case 4 % known formula, give the density, thickness, and formula
                    n = varargin{1};
                    s.density(n) = varargin{2};
                    s.thickness(n) = varargin{3};
                    s.formula{n} = varargin{4};
                otherwise
                    error('Arguments for push function not right.');
            end            
        end
        
        % calculate x-ray optical properties
        function refractionIndex(s, energy)
            
            if find(~(s.density | s.electronDensity), 1)
                error('Either electron density or the density must be present for each layer.');
            end
            s.energy = energy;
            s.wavelength = getWavelength(energy);
            for i = 1 : s.N
                if s.density(i)
                    s.parseFormula(i);
                    s.calculateDispersionAbsorption(i);
                else
                    s.calculateDispersion(i);
                end
            end
            
        end
        
        % calculate the detailed optics
        function optics(s, angle)
            
            M = length(angle);
            s.angle = reshape(angle, numel(angle), 1);
            s.rangle = sqrt(repmat(s.angle, 1, s.N).^2 - 2 * repmat(s.dispersion, M, 1) + 2i * repmat(s.absorption, M, 1));
            
            % calculate the refraction matrices
            if s.thickness(end) ~= Inf
                error('The last layer must have infinite thickness.');
            end
            
            theta1 = [s.angle, s.rangle(:, 1:end-1)];
            theta2 = s.rangle;
            d1 = repmat([0, s.thickness(:, 1:end-1)], M, 1);
            d2 = repmat([s.thickness(1:end-1), 0], M, 1); % calculate the intensity at the interface for the last layer
            
            ratio1 = (theta1 + theta2) / 2 ./ theta1;
            ratio2 = (theta1 - theta2) / 2 ./ theta1;
            expo1 = 1i * pi / s.wavelength * (theta1 .* d1 + theta2 .* d2);
            expo2 = 1i * pi / s.wavelength * (theta1 .* d1 - theta2 .* d2);
            
            m = zeros(M, s.N, 4);
            m(:, :, 1) = ratio1 .* exp(-expo1);
            m(:, :, 2) = ratio2 .* exp(-expo2);
            m(:, :, 3) = ratio2 .* exp(expo2);
            m(:, :, 4) = ratio1 .* exp(expo1);
            
            tempmatrix = cell(M, s.N);
            s.matrices = cell(M, s.N);
            for i = 1 : M
                for j = s.N : -1 : 1
                    tempmatrix{i, j} = reshape(m(i, j, :), 2, 2)';
                    s.matrices{i, j} = eye(2);
                    for k = j : s.N
                        s.matrices{i, j} = s.matrices{i, j} * tempmatrix{i, k};
                    end
                end
            end
            
            tamp = zeros(M, s.N);
            ramp = zeros(M, s.N);
            
            ramp(:, end) = 0;
            for i = 1 : M
                tamp(i, end) = 1 / s.matrices{i, 1}(1, 1);
            end
            
            for i = 1 : M
                for j = 1 : s.N - 1
                    tamp(i, j) = s.matrices{i, j+1}(1, 1) * tamp(i, end);
                    ramp(i, j) = s.matrices{i, j+1}(2, 1) * tamp(i, end);
                end
            end
            
            
            phaseLength = cumsum([0, s.thickness(1:end-1)]) - [s.thickness(1:end-1), 0] / 2;
            phaseShift = 2 * pi / s.wavelength * s.rangle .* repmat(phaseLength, M, 1);
            s.transmission = tamp .* exp( 1i * phaseShift );
            s.reflection = ramp .* exp( -1i * phaseShift );
            
            alpha = repmat(s.angle, 1, s.N);
            delta = repmat(s.dispersion, M, 1);
            beta = repmat(s.absorption, M, 1);
            s.penetration = s.wavelength / 4 / pi ./ imag( sqrt( alpha.^2 - 2 * delta + 2i * beta ) );
            
            % intensity below each of the interface
            s.intensity = abs((s.transmission + s.reflection).^2);
            
        end
        
        % calculate the intensity for a given element
        function calculateFluoIntensity(s, element)
            
            s.fitElement = element;
            
            location = false(1, s.N); % locate which layer the element is in
            for i = 1 : length(s.elements)
                if ~isempty(s.elements{i})
                    for j = 1 : length(s.elements{i})
                        if strcmp(s.elements{i}{j}, element)
                            location(i) = true;
                            break;
                        end
                    end
                end
            end
            
            cumsum([s.thickness(1: end-1), 0])
            layerIntensity = repmat(location, length(s.angle), 1) .* s.intensity;
            s.fluoIntensity = sum(layerIntensity, 2);
            
        end
        
        % parse formula to obtain elements and stoichiometry
        function parseFormula(s, k)
            
            f = s.formula{k};

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
            elem = cell(1,n);
            stoi = zeros(1,n);

            % obtain elements
            start = find(upperCase);
            finish = find((upperCase & ~[lowerCase(2:end),false]) | (lowerCase & ~[lowerCase(2:end),false]));
            for i = 1:n
                elem{i} = f(start(i):finish(i));
            end

            % obtain stoichiometry numbers
            start = find(number & ~[true, number(1:end-1)]);
            finish = find(number & ~[number(2:end), false]);
            for i = 1:n
                stoi(i) = str2double(f(start(i):finish(i)));
            end
            
            s.elements{k} = elem;
            s.stoichiometry{k} = stoi;

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
            % calculate the dispersion part of the refractive index, the real part

            % units
            % electronDensity - /A^3, for water is 0.3344
            % energy - keV
            % wavelength - A

            re = 2.81794092e-5; % classical radius for electron in A

            s.dispersion(k) = re * s.electronDensity(k) * s.wavelength^2 / 2 / pi;

        end
        
    end
    
end
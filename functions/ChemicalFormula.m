classdef ChemicalFormula < handle
    
    properties
        
        formula
        elements
        stoichiometry
        molecularWeight
        molecularElectron
        
        ElectronTable
        AtomicMassTable
        
    end
    
    methods
        
        function this = ChemicalFormula()
            
            this.generatePeriodicTable();
            
        end
        
        function push(this, n, formula)
            
            if nargin == 2
                this.formula{n} = [];
            else
                this.formula{n} = formula;
            end
            
            this.parseFormula(n);
            this.getMWandElectron(n);
            
        end
        
        function pop(this, indices)
            
            if max(indices) > length(this.formula)
                warning('This layer #%d does not exist.', max(indices));
            else
                sel = true(1, length(this.formula));
                sel(indices) = false;
                this.formula = this.formula(sel);
                this.elements = this.elements(sel);
                this.stoichiometry = this.stoichiometry(sel);
                this.molecularWeight = this.molecularWeight(sel);
                this.molecularElectron = this.molecularElectron(sel);
            end
            
        end
        
        function update(this, n, element, newStoichiometryNumber)

            for i = 1 : length(this.elements{n})
                if strcmp(this.elements{n}{i}, element)
                    this.stoichiometry{n}(i) = newStoichiometryNumber;
                    newFormula = '';
                    for j = 1 : length(this.elements{n})
                        newFormula = strcat(newFormula, this.elements{n}{j}, num2str(this.stoichiometry{n}(j)));
                    end
                    this.formula{n} = newFormula;
                    this.stoichiometry{n}(i) = newStoichiometryNumber;
                    this.getMWandElectron(n);
                    break;
                end
            end

        end
        
        function makeSpace(this, position)
            
            sel = true(1, length(this.formula) + 1);
            sel(position) = false;
            this.formula(sel) = this.formula;
            this.elements(sel) = this.elements;
            this.stoichiometry(sel) = this.stoichiometry;
            this.molecularWeight(sel) = this.molecularWeight;
            this.molecularElectron(sel) = this.molecularElectron;
            
        end
        
        function generatePeriodicTable(this)

            symbols = 'H He Li Be B C N O F Ne Na Mg Al Si P S Cl Ar K Ca Sc Ti V Cr Mn Fe Co Ni Cu Zn Ga Ge As Se Br Kr Rb Sr Y Zr Nb Mo Tc Ru Rh Pd Ag Cd In Sn Sb Te I Xe Cs Ba La Ce Pr Nd Pm Sm Eu Gd Tb Dy Ho Er Tm Yb Lu Hf Ta W Re Os Ir Pt Au Hg Tl Pb Bi Po At Rn Fr Ra Ac Th Pa U';
            atomicNumber = (1:92);
            masses = [1.0079,4.0026,6.941,9.0122,10.81,12.011,14.007,15.999,18.998,20.18,22.99,24.305,26.982,28.085,30.974,32.066,35.453,39.948,39.098,40.078,44.956,47.867,50.941,51.996,54.938,55.845,58.933,58.693,63.546,65.39,69.723,72.61,74.922,78.96,79.904,83.8,85.468,87.62,88.906,91.224,92.906,95.94,98,101.07,102.91,106.42,107.87,112.41,114.82,118.71,121.76,127.6,126.9,131.29,132.91,137.33,138.91,140.12,140.91,144.24,145,150.36,151.96,157.25,158.93,162.5,164.93,167.26,168.93,173.04,174.97,178.49,180.95,183.84,186.21,190.23,192.22,195.08,196.97,200.59,204.38,207.2,208.98,209,210,222,223,226,227,232.04,231.04,238.03];

            symbol = regexp(symbols, ' ', 'split');
            electron = containers.Map;
            atomicMass = containers.Map;

            for i = 1:length(symbol)
                electron(symbol{i}) = atomicNumber(i);
                atomicMass(symbol{i}) = masses(i);
            end
            
            this.AtomicMassTable = atomicMass;
            this.ElectronTable = electron;

        end
        
        function parseFormula(this, indices)
            % parse the formula, calculate the molecular weight, and the
            % number of electrons in the formula
            
            for k = indices

                f = this.formula{k};
                if isempty(f)
                    this.elements{k} = [];
                    this.stoichiometry{k} = [];
                    this.molecularWeight(k) = 0;
                    this.molecularElectron(k) = 0;
                else
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
                    this.elements{k} = cell(1,n);
                    this.stoichiometry{k} = zeros(1,n);

                    % obtain elements
                    start = find(upperCase);
                    finish = find((upperCase & ~[lowerCase(2:end),false]) | (lowerCase & ~[lowerCase(2:end),false]));
                    for i = 1:n
                        this.elements{k}{i} = f(start(i):finish(i));
                    end

                    % obtain stoichiometry numbers
                    start = find(number & ~[true, number(1:end-1)]);
                    finish = find(number & ~[number(2:end), false]);
                    for i = 1:n
                        this.stoichiometry{k}(i) = str2double(f(start(i):finish(i)));
                    end

                end
            end

        end
        
        function density = convertEd2Density(this, indices, ed)
            
            if length(indices) ~= length(ed)
                disp('Indices and electron density must be the same length.');
            else
                density = zeros(1, length(indices));
                for k = 1 : length(indices)
                    if this.molecularWeight(indices(k)) > 0
                        NA = 6.02214199e23; % Avagadro's Number
                        density(k) = ed(k) / this.molecularElectron(indices(k)) / NA * this.molecularWeight(indices(k)) * 1e24;
                    end
                end
            end
            
        end
        
        function getMWandElectron(this, indices)
            
            for k = indices
                n = length(this.elements{k});
                if n == 0
                    this.molecularWeight(k) = 0;
                    this.molecularElectron(k) = 0;
                else
                    mass = zeros(1, n);
                    number = zeros(1, n);
                    for i = 1:n
                        mass(i) = this.AtomicMassTable(this.elements{k}{i});
                        number(i) = this.ElectronTable(this.elements{k}{i});
                    end
                    this.molecularWeight(k) = sum(this.stoichiometry{k} .* mass);
                    this.molecularElectron(k) = sum(this.stoichiometry{k} .* number);
                end
            end
            
        end
        
    end
    
end
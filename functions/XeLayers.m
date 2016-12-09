classdef XeLayers < handle
    % tratified layer structure for x-ray fluorescence
    % this class holds the general information of each layer

    properties

        system
        rawdata
        data
        fit

        config

    end

    methods

        % construct an instance, and load the supporting database
        function this = XeLayers(file)

            this.config = textread(which('xeray-config.txt'), '%s', 'delimiter', '\n');

            this.rawdata = XeRawData(file);
            
            %this.fit = XeFitting();

        end

        % obtain the data for a chosen element as a preparation for fitting
        function selectElement(this, element, lineshape)

            if nargin == 2
                lineshape = 'Gaussian';
            end
            this.data = XeElementData(this.config, element, this.rawdata, lineshape);
            
        end
        
        function createPhysicalSystem(this, incidenceEnergy, slit, foot)
            
            emissionEnergy = this.data.lineshape.mainPeak;
            this.system = XeSystem(incidenceEnergy, emissionEnergy, slit, foot, this.rawdata.angle, this.config);
            
        end
        
        function runFluoFit(this, concentration, varargin)
            
            if ~isempty(concentration)
                this.system.concentration = concentration;
            end
            this.fit = XeFitting(varargin{:});
            
            signal = this.data.lineshape.signal;
            signalError = this.data.lineshape.signalError;
            
            if isempty(this.fit.fitParameters)
                
                % not fitting any parameters
                P = this.fit.lower;
                
                this.fit.all.parameters = [];
                this.fit.all.P = P;
                this.fit.all.chi2 = sum(((this.system.calculateFluoIntensity(P) - signal) ./ signalError).^2);
                this.fit.all.likelihood = 1;
                
            else
                
                % global fit
                parameters = this.fit.fitParameters;
                one = FitOneResult(parameters);
                
                start = this.fit.start();
                lower = this.fit.lower();
                upper = this.fit.upper();
                lb = this.fit.lb();
                ub = this.fit.ub();
                
                options = optimoptions('lsqnonlin', 'MaxFunEvals', 1e25, 'MaxIter', 1e5, 'Display', 'off');
                
                myfun = @(p) ((this.system.calculateFluoIntensityWithBounds(p, this.fit.lower, this.fit.upper) - signal) ./ signalError);
                
                [result, chi2] = lsqnonlin(myfun, start, lb, ub, options);
                P = this.fit.fullP(result);
                
                all0.parameters = parameters;
                all0.P = P;
                all0.chi2 = chi2;
                all0.likelihood = 1;
                this.fit.all = all0;
                
                % fitting one parameter at a time
                
                m = length(parameters);
                n = this.fit.steps;
                
                para = zeros(n, m);
                chi2 = zeros(n, m);
                sys = this.system;
                location = this.fit.location;
                
                for i = 1:m
                    
                    para(:, i) = linspace(lb(i), ub(i), n)';
                    
                    if m == 1
                        parfor j = 1:n
                            par_P = P;
                            par_location = location;
                            par_para = para;
                            par_P(par_location) = par_para(j);
                            par_sys = sys;
                            chi2(j, i) = sum(((par_sys.calculateFluoIntensity(par_P) - signal) ./ signalError).^2);
                        end
                    else
                        parfor j = 1:n
                            par_location = location;
                            par_lower = lower;
                            par_upper = upper;
                            par_lower(par_location(i)) = para(j, i);
                            par_upper(par_location(i)) = para(j, i);
                            par_P = P;
                            p = par_P(par_lower ~= par_upper);
                            lbs = par_lower(par_lower ~= par_upper);
                            ubs = par_upper(par_lower ~= par_upper);
                            par_sys = sys;
                            myfun = @(p) ((par_sys.calculateFluoIntensityWithBounds(p, par_lower, par_upper) - signal) ./ signalError);
                            [~, chi2(j,i)] = lsqnonlin(myfun, p, lbs, ubs, options);
                        end
                    end
                    
                end
                
                one.chi2 = chi2;
                one.para = para;
                one.getLikelihood();
                one.fitLikelihood();
                this.fit.one = one;
                 
                if m >= 2
                    if m == 2
                        two = cell(2, 2);
                        two{1, 2} = FitTwoResult(this.fit.fitParameters);
                        two{1, 2}.para1 = para(:, 1);
                        two{1, 2}.para2 = para(:, 2);
                        chi2 = zeros(n, n);
                        for i = 1 : n
                            P(location(1)) = para(i, 1);
                            for j = 1 : n
                                P(location(2)) = para(j, 2);
                                chi2(i, j) = sum(((this.system.calculateFluoIntensity(P) - signal) ./ signalError).^2);
                            end
                        end
                        two{1,2}.chi2 = chi2;
                        two{1,2}.getLikelihood();
                    else
                        two = cell(m, m);
                        for k = 1 : m-1
                            for l = k+1 : m
                                two{k, l} = FitTwoResult(parameters(location([k,l])));
                                two{k, l}.para1 = para(:, k);
                                two{k, l}.para2 = para(:, l);
                                chi2 = zeros(n, n);
                                parfor g = 1 : n
                                    par_location = location;
                                    par_para = para;
                                    par_P = P;
                                    
                                    par_lower = lower;
                                    par_upper = upper;
                                    
                                    par_lower(par_location(k)) = par_para(g, k);
                                    par_upper(par_location(k)) = par_para(g, k);
                                    for h = 1 : n
                                        par_lower(par_location(l)) = par_par(h, l);
                                        par_upper(par_location(l)) = par_par(h, l);
                                        p = par_P(par_lower ~= par_upper);
                                        lbs = par_lower(par_lower ~= par_upper);
                                        ubs = par_upper(par_lower ~= par_upper);
                                        par_sys = sys;
                                        myfun = @(p) ((par_sys.calculateFluoIntensityWithBounds(p, par_lower, par_upper) - signal) ./ signalError);
                                        [~, chi2(g, h)] = lsqnonlin(myfun, p, lbs, ubs, options);
                                    end
                                end
                                two{k,l}.chi2 = chi2;
                                two{k,l}.getLikelihood();
                            end
                        end
                    end
                    this.fit.two = two;
                    
                end
                
            end
            
        end

        function plotSignal(this, axis)

            if nargin == 1
                axis = gca;
            end

            errorbar(axis, this.data.angle, this.data.lineshape.signal, this.data.lineshape.signalError,'o','markersize',8,'linewidth',2);
            hold(axis,'on');
            
            fineAngle = this.data.fineAngleRange(100);
            plot(axis, fineAngle, this.system.calculateFluoIntensityCurve(this.fit.all.P, fineAngle), 'r-', 'linewidth', 2);
            hold(axis,'off');
            
            xlabel(axis,'Qz');
            ylabel(axis,'Integrated Signal (a.u.)');
            legend(axis,'Data','Fit');
            title(axis,sprintf('%s %s', this.data.element, 'Fluorescence'));

        end
        
        function plotLikelihood(this, parameter, ax)
            
            if nargin == 2
                ax = gca;
            end
            
            index = this.fit.fitParaIndex(parameter);
            if index > 0
                x = this.fit.one.para(:, index);
                y = this.fit.one.likelihood(:, index);
                plot(ax, x, y, 'o', 'markersize', 8, 'linewidth', 2);
                title(ax,sprintf('%s %s','\chi^2 of', parameter));
                legend(ax,'Likelihood');
            end
            
        end
        
    end

end

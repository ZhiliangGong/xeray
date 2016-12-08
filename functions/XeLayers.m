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
        
        function plotSignal(this, axis)

            if nargin == 1
                axis = gca;
            end

            errorbar(axis, this.data.angle, this.data.lineshape.signal, this.data.lineshape.signalError,'o','markersize',8,'linewidth',2);
            hold(axis,'on');
            
            plot(axis, this.data.angle, this.fit.curve, 'r-', 'linewidth', 2);
            hold(axis,'off');
            xlabel(axis,'Qz');
            ylabel(axis,'Integrated Signal (a.u.)');
            legend(axis,'Data','Fit');
            title(axis,sprintf('%s %s', this.data.element, 'Fluorescence'));

        end
        
        function runFluoFit(this, concentration, varargin)
            
            if ~isempty(concentration)
                this.system.concentration = concentration;
            end
            this.fit = XeFitting(varargin{:});
            
            signal = this.data.lineshape.signal;
            signalError = this.data.lineshape.signalError;
            
            if isempty(this.fit.fitParameters)
                this.fit.curve = this.system.updateCalculation(this.fit.start);
            else
                %fit all parameters at once
                start = this.fit.start();
                lb = this.fit.lb();
                ub = this.fit.ub();
                
                options = optimoptions('lsqnonlin', 'MaxFunEvals', 1e25, 'MaxIter', 1e5, 'Display', 'off');
                
                myfun = @(P) ((this.system.calculateFluoIntensityWithBounds(P, this.fit.lower, this.fit.upper) - signal) ./ signalError);
                
                [result, chi2] = lsqnonlin(myfun, start, lb, ub, options);
                this.fit.curve = this.system.calculateFluoIntensity(this.fit.fullParameter(result));
                
%                 fitAll.parameters = parameters(loc);
%                 fitAll.value = start;
%                 fitAll.chi2 = chi2;
%                 fitAll.fitQRange = linspace(min(angles),max(angles),M);
%                 fitAll.fitSignal = totalFluoIntensity2(x,fitAll.fitQRange,start,lb0,ub0);
%                 x.fluoFit.fitAll = fitAll;
%                 
%                 fitting parameters one by one
%                 
%                 paraRange = zeros(N,m);
%                 chi2 = zeros(N,m);
%                 
%                 for i = 1:m
%                     
%                     paraRange(:,i) = linspace(lb0(loc(i)),ub0(loc(i)),N)';
%                     
%                     if m == 1
%                         parfor j = 1:N
%                             P = P0;
%                             locPar = loc;
%                             paraRangePar = paraRange;
%                             P(locPar) = paraRangePar(j);
%                             chi2(j,i) = sum(((totalFluoIntensity(x,angles,P)-signal)./signalError).^2);
%                         end
%                     else
%                         parfor j = 1:N
%                             locPar = loc;
%                             lb = lb0;
%                             ub = ub0;
%                             lb(locPar(i)) = paraRange(j,i);
%                             ub(locPar(i)) = paraRange(j,i);
%                             P0Par = P0;
%                             start = P0Par(lb~=ub);
%                             lb = lb(lb~=ub);
%                             ub = ub(lb~=ub);
%                             myfun = @(Ps) ((totalFluoIntensity2(x,angles,Ps,lb,ub)-signal)./signalError);
%                             [~,chi2(j,i)] = lsqnonlin(myfun,start,lb,ub,options);
%                         end
%                     end
%                     
%                 end
%                 lk = chi2;
%                 lk = exp(-(lk-repmat(min(lk),N,1))/2);
%                 lk = lk./repmat(sum(lk),N,1);
%                 
%                 %fit likelihood (lk)
%                 lkFit = zeros(M,m);
%                 lkFitRange = zeros(M,m);
%                 lkPara = cell(1,m);
%                 quality = cell(1,m);
%                 parfor i = 1:m
%                     
%                     paraRangePar = paraRange;
%                     parametersPar = parameters;
%                     
%                     [lkPara{i},flag] = fitGaussianLikelihood(paraRangePar(:,i),lk(:,i));
%                     if flag
%                         warning('%s %s',parametersPar{loc(i)},'fitting bad.');
%                         quality{i} = 'bad';
%                     else
%                         quality{i} = 'good';
%                     end
% 
%                     lkFitRange(:,i) = linspace(paraRangePar(1,i),paraRangePar(end,i),M)';
%                     lkFit(:,i) = lkPara{i}(1)*exp(-(lkFitRange(:,i)-lkPara{i}(2)).^2/2/lkPara{i}(3)^2);
%                     
%                 end
%                 lkPara = cell2mat(lkPara);
%                 x.fluoFit.parameters = parameters(loc);
%                 x.fluoFit.fit1.value = lkPara(2,:);
%                 x.fluoFit.fit1.std = lkPara(3,:);
%                 x.fluoFit.fit1.adjustedStd = (x.fluoFit.fit1.std).^(1/m);
%                 x.fluoFit.fit1.quality = quality;
%                 x.fluoFit.fit1.paraRange = paraRange;
%                 x.fluoFit.fit1.chi2 = chi2;
%                 x.fluoFit.fit1.likelihood = lk;
%                 x.fluoFit.fit1.lkFitRange = lkFitRange;
%                 x.fluoFit.fit1.lkFit = lkFit;
%                 
%                 if m >= 2
%                     if m == 2
%                         fit2 = cell(2,2);
%                         fit2{1,2}.parameters = parameters(loc);
%                         fit2{1,2}.paraRange1 = paraRange(:,1);
%                         fit2{1,2}.paraRange2 = paraRange(:,2);
%                         P = P0;
%                         chi2 = zeros(N,N);
%                         for i = 1:N
%                             P(loc(1)) = paraRange(i,1);
%                             for j = 1:N
%                                 P(loc(2)) = paraRange(j,2);
%                                 chi2(i,j) = sum(((totalFluoIntensity(x,angles,P)-signal)./signalError).^2);
%                             end
%                         end
%                         lk = chi2;
%                         lk = exp(-(lk-min(lk(:)))/2);
%                         lk = lk/sum(lk(:));
%                         fit2{1,2}.chi2 = chi2;
%                         fit2{1,2}.lk = lk;
%                     else
%                         fit2 = cell(m,m);
%                         for k = 1:m-1
%                             for l = k+1:m
%                                 fit2{k,l}.parameters = parameters(loc([k,l]));
%                                 fit2{k,l}.paraRange1 = paraRange(:,k);
%                                 fit2{k,l}.paraRange2 = paraRange(:,l);
%                                 chi2 = zeros(N,N);
%                                 parfor i = 1:N
%                                     
%                                     locPar = loc;
%                                     paraRangePar = paraRange;
%                                     P0Par = P0;
%                                     
%                                     lb = lb0;
%                                     ub = ub0;
%                                     lb(locPar(k)) = paraRangePar(i,k);
%                                     ub(locPar(k)) = paraRangePar(i,k);
%                                     for j = 1:N
%                                         lb(locPar(l)) = paraRangePar(j,l);
%                                         ub(locPar(l)) = paraRangePar(j,l);
%                                         start = P0Par(lb~=ub);
%                                         lb = lb(lb~=ub);
%                                         ub = ub(lb~=ub);
%                                         myfun = @(Ps) ((totalFluoIntensity2(x,angles,Ps,lb,ub)-signal)./signalError);
%                                         [~,chi2(i,j)] = lsqnonlin(myfun,start,lb,ub,options);
%                                     end
%                                 end
%                                 lk = chi2;
%                                 lk = exp(-(lk-min(lk(:)))/2);
%                                 lk = lk/sum(lk(:));
%                                 fit2{k,l}.chi2 = chi2;
%                                 fit2{k,l}.lk = lk;
%                             end
%                         end
%                     end
%                     x.fluoFit.fit2 = fit2;
%                     
%                 end
                
            end
            
        end

    end

end

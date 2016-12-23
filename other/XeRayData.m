classdef XeRayData < handle
    %Data for the XeRay Gui

    properties
        
        %fields when loads .xfluo file
        file %the full file name with path
        q %qz
        angle %angle in radian
        e %energy in kev
        E %incoming beam energy, keV
        density %in g/mL
        intensity %normalized raw data by monc and the scale factor
        intensityError %error of the normalized raw data
        
        element %the currently fitted element
        xe %short energy axis just for an element
        xIntensity %intensity just for an element
        xIntensityError %intensity error just for an element
        
        %fields after fitting to an element
        lineShape %Gaussian or Lorentzian
        lineShapePara %fitting parameters for the gaussian or Lorentzian
        fitE %fits
        intensityFit %netted fits for an element
        netIntensityFit %net fitted intensity
        netIntensity %net intensity with background subtracted
        
        signal %integrated intensity
        signalError %error of the integrated intensity
        peaks %energy peaks
        pickedPeak %the index of the picked peak for analysis
        
        formula %the chemical formula
        detectorLength %detector length
        slit %slit size
        xresult %refractive properties of the incidence beam
        xresult1 %refractive properties of the fluorescence signal
        
        calRange %range for calculation
        calculation %calculated signal based on current parameters
        allPara %names of all parameters
        fitted %fitted parameters
        fluoFit %info on fitted parameters and fixed ones
        
        comment
        
    end
   
    methods
        
        % import and process spectra
        
        function x = XeRayData(fname,energy)
            
            [~,name,ext] = fileparts(fname);
            file = [name,ext];
            
            x.file = file;
            [x.q,x.e,x.intensity,x.intensityError]=readXfluo(fname);
            
            if nargin == 2
                x.E = energy;
                x.angle = q2Radian(x,x.q);
            end
            
        end
        
        function xFit(x,element,varargin) %fit the fluorescence spectrum
            
            if nargin == 2
                type = 'gaussian';
            elseif nargin == 3
                type = varargin{1};
            else
                error('Check argument for xFit.');
            end
            x.lineShape = type;
            
            element = loadElement(element);
            x.element = element;
            
            %find the energy range working on
            n1 = find(abs(x.e-element.range(1)) == min(abs(x.e-element.range(1))),1);
            n2 = find(abs(x.e-element.range(2)) == min(abs(x.e-element.range(2))),1);

            x.xe = x.e(n1:n2);
            x.xIntensity = x.intensity(n1:n2,:);
            x.xIntensityError = x.intensityError(n1:n2,:);
            
            [~,n] = size(x.xIntensity);
            N = 500;
            x.fitE = linspace(x.xe(1),x.xe(end),N)';
            x.intensityFit = zeros(N,n);
            switch length(element.peak)
                case 1
                    x.lineShapePara = zeros(5,n);
                case 2
                    x.lineShapePara = zeros(8,n);
                otherwise
                    error('Curve type not found.');
            end
            for i = 1:n
                [x.lineShapePara(:,i),~,x.intensityFit(:,i)] = fluoCurveFit(x.xe,x.xIntensity(:,i),type,element.peak,element.width,N);
            end
            
            x.netIntensity = x.xIntensity - [x.xe,ones(size(x.xe))]*x.lineShapePara(end-1:end,:);
            x.netIntensityFit = x.intensityFit - [x.fitE,ones(size(x.fitE))]*x.lineShapePara(end-1:end,:);
            
            %calculate the signal and error
            x.peaks = element.peak;
            switch length(element.peak)
                case 1
                    M = 1;
                    x.pickedPeak = 1;
                    ratio = 1;
                case 2
                    ratio = sum(x.lineShapePara(1,:))/sum(x.lineShapePara(3,:));
                    if ratio > 1
                        M = 1;
                        ratio = ratio/(ratio+1);
                        x.pickedPeak = 1;
                    else
                        M = 4;
                        ratio = 1/(ratio+1);
                        x.pickedPeak = 2;
                    end
            end
            switch lower(type)
                case {'gauss','gaussian'}
                    x.signal = x.lineShapePara(M,:).*x.lineShapePara(2+M,:)*sqrt(2*pi);
                case {'lorentz','lorentzian'}
                    x.signal = x.lineShapePara(M,:).*x.lineShapePara(2+M,:)*2;
            end
            x.signalError = sqrt(sum(x.xIntensityError.^2))*range(x.xe)/length(x.xe) * ratio;
            
        end
        
        %calculate intensity
        
        function I = totalFluoIntensity(x,q,P) %total intensity
            %P: qz offset, scaleFactor, bulk, surf, and background
            
            if ~isa(P,'numeric') || length(P) ~= 5
                error('Check input for totalFluoIntensity.');
            end
            
            I = xFluoIntensity(x.xresult.dispersion,x.xresult.absorption,x.xresult.wavelength,...
                x.xresult1.dispersion,x.xresult1.absorption,x.xresult1.wavelength,...
                x.slit,x.detectorLength,q2Radian(x,q+P(1)),P(2),P(3),P(4),P(5));
            
        end
        
        function I = totalFluoIntensity2(x,q,sP,lb,ub) %intensity fitting function
            %sP, a truncated version of P, fitting sP
            
            fixed = (lb==ub);
            P = zeros(1,5);
            P(fixed) = lb(fixed);
            P(~fixed) = sP;
            
            I = totalFluoIntensity(x,q,P);
            
        end
        
        %fitting fluorescence
        
        function runFluoFit(x,varargin)
                        
            % inputs
            parameters = {'Qz-Offset','Scale-Factor','Bulk(mM)','Surf(1/nm^2)','Background'};
            x.allPara = parameters;
            
            arguments = {[0 1 1 1 0],[0 0 0 0.9 0],[0 10 100 1.1 100],100,(1:length(x.q))};
            arguments(1:length(varargin)) = varargin;
            
            %assign inputs
            P0 = arguments{1}; %the start values
            lb0 = arguments{2}; %the lower bound
            ub0 = arguments{3}; %the upper bound
            N = arguments{4}; %number of points between the lower bound and upper bound
            qIndex = arguments{5};
            
            %obtain the signal and error range being fitted
            qRange = x.q(qIndex);
            theSignal = x.signal(qIndex);
            theError = x.signalError(qIndex);
            
            x.fluoFit.data.qRange = qRange;
            x.fluoFit.data.signal = theSignal;
            x.fluoFit.data.error = theError;
            x.fluoFit.allParameters = parameters;
            x.fluoFit.start = P0;
            x.fluoFit.lowerBounds = lb0;
            x.fluoFit.upperBounds = ub0;
            
            %obtain fitting starting points, lower bound and upper bound
            fixed = lb0==ub0;
            fitting = ~fixed;
            loc = find(fitting);
            M = 100; %fitting curves, # of points
            
            x.fitted = fitting;
            
            % fitting depending on # of parameters
            
            m = sum(fitting);
            x.fluoFit.numberOfPara = m;
            
            if m == 0
                x.fluoFit.parameters = {'none'};
                x.fluoFit.fit0.para = P0;
                x.fluoFit.fit0.fitQRange = linspace(min(qRange),max(qRange),M);
                x.fluoFit.fit0.signal = totalFluoIntensity(x,x.fluoFit.fit0.fitQRange,P0);
            else
                %fit all parameters at once
                Ps = P0(~fixed);
                lbs = lb0(~fixed);
                ubs = ub0(~fixed);
                
                options = optimoptions('lsqnonlin','MaxFunEvals',1e25,'MaxIter',1e5,'Display','off');
                myfun = @(Ps) ((totalFluoIntensity2(x,qRange,Ps,lb0,ub0)-theSignal)./theError);
                [Ps,chi2] = lsqnonlin(myfun,Ps,lbs,ubs,options);
                
                fitAll.parameters = parameters(loc);
                fitAll.value = Ps;
                fitAll.chi2 = chi2;
                fitAll.fitQRange = linspace(min(qRange),max(qRange),M);
                fitAll.fitSignal = totalFluoIntensity2(x,fitAll.fitQRange,Ps,lb0,ub0);
                x.fluoFit.fitAll = fitAll;
                
                % fitting parameters one by one
                
                paraRange = zeros(N,m);
                chi2 = zeros(N,m);
                
                for i = 1:m
                    
                    paraRange(:,i) = linspace(lb0(loc(i)),ub0(loc(i)),N)';
                    
                    if m == 1
                        parfor j = 1:N
                            P = P0;
                            locPar = loc;
                            paraRangePar = paraRange;
                            P(locPar) = paraRangePar(j);
                            chi2(j,i) = sum(((totalFluoIntensity(x,qRange,P)-theSignal)./theError).^2);
                        end
                    else
                        parfor j = 1:N
                            locPar = loc;
                            lb = lb0;
                            ub = ub0;
                            lb(locPar(i)) = paraRange(j,i);
                            ub(locPar(i)) = paraRange(j,i);
                            P0Par = P0;
                            Ps = P0Par(lb~=ub);
                            lbs = lb(lb~=ub);
                            ubs = ub(lb~=ub);
                            myfun = @(Ps) ((totalFluoIntensity2(x,qRange,Ps,lb,ub)-theSignal)./theError);
                            [~,chi2(j,i)] = lsqnonlin(myfun,Ps,lbs,ubs,options);
                        end
                    end
                    
                end
                lk = chi2;
                lk = exp(-(lk-repmat(min(lk),N,1))/2);
                lk = lk./repmat(sum(lk),N,1);
                
                %fit likelihood (lk)
                lkFit = zeros(M,m);
                lkFitRange = zeros(M,m);
                lkPara = cell(1,m);
                quality = cell(1,m);
                parfor i = 1:m
                    
                    paraRangePar = paraRange;
                    parametersPar = parameters;
                    
                    [lkPara{i},flag] = fitGaussianLikelihood(paraRangePar(:,i),lk(:,i));
                    if flag
                        warning('%s %s',parametersPar{loc(i)},'fitting bad.');
                        quality{i} = 'bad';
                    else
                        quality{i} = 'good';
                    end

                    lkFitRange(:,i) = linspace(paraRangePar(1,i),paraRangePar(end,i),M)';
                    lkFit(:,i) = lkPara{i}(1)*exp(-(lkFitRange(:,i)-lkPara{i}(2)).^2/2/lkPara{i}(3)^2);
                    
                end
                lkPara = cell2mat(lkPara);
                x.fluoFit.parameters = parameters(loc);
                x.fluoFit.fit1.value = lkPara(2,:);
                x.fluoFit.fit1.std = lkPara(3,:);
                x.fluoFit.fit1.adjustedStd = (x.fluoFit.fit1.std).^(1/m);
                x.fluoFit.fit1.quality = quality;
                x.fluoFit.fit1.paraRange = paraRange;
                x.fluoFit.fit1.chi2 = chi2;
                x.fluoFit.fit1.likelihood = lk;
                x.fluoFit.fit1.lkFitRange = lkFitRange;
                x.fluoFit.fit1.lkFit = lkFit;
                
                if m >= 2
                    if m == 2
                        fit2 = cell(2,2);
                        fit2{1,2}.parameters = parameters(loc);
                        fit2{1,2}.paraRange1 = paraRange(:,1);
                        fit2{1,2}.paraRange2 = paraRange(:,2);
                        P = P0;
                        chi2 = zeros(N,N);
                        for i = 1:N
                            P(loc(1)) = paraRange(i,1);
                            for j = 1:N
                                P(loc(2)) = paraRange(j,2);
                                chi2(i,j) = sum(((totalFluoIntensity(x,qRange,P)-theSignal)./theError).^2);
                            end
                        end
                        lk = chi2;
                        lk = exp(-(lk-min(lk(:)))/2);
                        lk = lk/sum(lk(:));
                        fit2{1,2}.chi2 = chi2;
                        fit2{1,2}.lk = lk;
                    else
                        fit2 = cell(m,m);
                        for k = 1:m-1
                            for l = k+1:m
                                fit2{k,l}.parameters = parameters(loc([k,l]));
                                fit2{k,l}.paraRange1 = paraRange(:,k);
                                fit2{k,l}.paraRange2 = paraRange(:,l);
                                chi2 = zeros(N,N);
                                parfor i = 1:N
                                    
                                    locPar = loc;
                                    paraRangePar = paraRange;
                                    P0Par = P0;
                                    
                                    lb = lb0;
                                    ub = ub0;
                                    lb(locPar(k)) = paraRangePar(i,k);
                                    ub(locPar(k)) = paraRangePar(i,k);
                                    for j = 1:N
                                        lb(locPar(l)) = paraRangePar(j,l);
                                        ub(locPar(l)) = paraRangePar(j,l);
                                        Ps = P0Par(lb~=ub);
                                        lbs = lb(lb~=ub);
                                        ubs = ub(lb~=ub);
                                        myfun = @(Ps) ((totalFluoIntensity2(x,qRange,Ps,lb,ub)-theSignal)./theError);
                                        [~,chi2(i,j)] = lsqnonlin(myfun,Ps,lbs,ubs,options);
                                    end
                                end
                                lk = chi2;
                                lk = exp(-(lk-min(lk(:)))/2);
                                lk = lk/sum(lk(:));
                                fit2{k,l}.chi2 = chi2;
                                fit2{k,l}.lk = lk;
                            end
                        end
                    end
                    x.fluoFit.fit2 = fit2;
                    
                end
                
            end
            
        end
        
        function errorFit(x,confidence) %fit the error of the parameters
            
            if nargin == 1
                confidence = 0.95;
            end
            
            m = x.fluoFit.numberOfPara;
            if m > 0
                multiplier = norminv((1-confidence)/2+confidence,0,1);
                cw1 = [-multiplier*x.fluoFit.fit1.std;multiplier*x.fluoFit.fit1.std];
                cw1 = cw1+repmat(x.fluoFit.fit1.value,2,1);
                cw2 = [-multiplier*x.fluoFit.fit1.adjustedStd;multiplier*x.fluoFit.fit1.adjustedStd];
                cw2 = cw2+repmat(x.fluoFit.fit1.value,2,1);
                x.fluoFit.confidence = confidence;
                x.fluoFit.fit1.confidenceWindow = cw1;
                x.fluoFit.fit1.adjustedConfidenceWindow = cw2;
                
                if m > 1
                    for i = 1:m-1
                        for j = i+1:m
                            lk = x.fluoFit.fit2{i,j}.lk;
                            xdata = x.fluoFit.fit2{i,j}.paraRange1;
                            ydata = x.fluoFit.fit2{i,j}.paraRange2;
                            
                            lk1 = sort(lk(:));
                            lksum = cumsum(lk1);
                            lksum = abs(lksum-(1-confidence));
                            ind = find(lksum == min(lksum),1);
                            cLevel = lk1(ind);
                            
                            C = contourc(xdata,ydata,lk,[cLevel,cLevel]);
                            C = C(:,C(1,:) >= min(xdata));
                            C = C(:,C(1,:) <= max(xdata));
                            C = C(:,C(2,:) >= min(ydata));
                            C = C(:,C(2,:) <= max(ydata));
                            x.fluoFit.fit2{i,j}.contour = C;
                            
                            [ind1,ind2] = find(lk == max(lk(:)),1);
                            x.fluoFit.fit2{i,j}.center = [xdata(ind1),ydata(ind2)];
                            x.fluoFit.fit2{i,j}.confidenceWindow = [min(C(1,:)),max(C(1,:));min(C(2,:)),max(C(2,:))];
                        end
                    end
                end
                
            end
            
        end
        
        %utility
        
        function angle = q2Radian(x,qRange) %convert q to radian
            
            h = 6.62606957e-34; %Planck constatn
            c = 299792458; %speed of light
            ev2j = 1.60217657e-19; %eV to Joul conversion factor
            
            angle = asin((qRange*1e10)*h*c/(x.E*1000*ev2j)/(4*pi)); %convert q to radian
            
        end
        
        function lambda = calculateWavelength(x) %calculate the wavelength from keV
            h = 6.62606957e-34; %Planck constatn
            c = 299792458; %speed of light
            ev2j = 1.60217657e-19; %eV to Joul conversion factor
            lambda = h*c/(x.E*1000*ev2j)*1e10; %wavelength in A  
        end
        
        function reduceFormula(x) %calculate parameters depending only on formula and energy
            %to prepare for calculating the absorption and dispersion
            
            x.xresult = refracOf(x.formula,x.E,x.density);
            
        end
        
        %plot
        
        function plotFit(x,ax)
            
            if nargin == 1
                ax = gca;
            end
            errorbar(ax,x.fluoFit.data.qRange,x.fluoFit.data.signal,x.fluoFit.data.error,'o','markersize',8,'linewidth',2);
            hold(ax,'on');
            plot(ax,x.fluoFit.fitAll.fitQRange,x.fluoFit.fitAll.fitSignal,'r-','linewidth',2);
            hold(ax,'off');
            xlabel(ax,'Qz');
            ylabel(ax,'Integrated Signal (a.u.)');
            legend(ax,'Data','Fit');
            title(ax,sprintf('%s %s',x.element.name,'Fluorescence'));
            
        end
        
        function plotPara(x)
            
            m = x.fluoFit.numberOfPara;
            if m > 0
                for i = 1:m
                    fit1 = x.fluoFit.fit1;
                    figure;
                    plot(fit1.paraRange(:,i),fit1.likelihood(:,i),'o');
                    hold on;
                    plot(fit1.lkFitRange(:,i),fit1.lkFit(:,i),'r');
                    hold off;
                    xlabel(x.fluoFit.parameters{i},'fontsize',16);
                    ylabel('Normalized Likelihood','fontsize',16);
                    legend('Likelihood','Gaussian Fit');
                    set(gca,'fontsize',14);
                end
                
                if m > 1
                    for i = 1:m-1
                        for j = i+1:m
                            
                            fit2 = x.fluoFit.fit2{i,j};
                            xdata =fit2.paraRange1;
                            ydata = fit2.paraRange2;
                            C = fit2.contour;
                            lk = fit2.lk;
                            figure;
                            contourf(xdata,ydata,lk);
                            colorbar;
                            hold on;
                            plot(C(1,:),C(2,:),'r','linewidth',2);
                            hold off;
                            xlabel(x.fluoFit.parameters{i},'fontsize',16);
                            ylabel(x.fluoFit.parameters{j},'fontsize',16);
                            legend('Joint Likelihood',sprintf('%.2f %s',x.fluoFit.confidence,'Confidence Window'));
                            set(gca,'fontsize',14);
                            
                        end
                    end
                end
                
            end
            
        end
        
        function plotSinglePara(x,m,type,ax)
            %m is the parameter index within the 5 parameters, type would
            %be 1 for 'lk' or 2 'chi'
            
            switch nargin
                case 2
                    type = 1;
                    ax = gca;
                case 3
                    ax = gca;
            end
            
            m = sum(x.fitted(1:m));
            
            fit1 = x.fluoFit.fit1;
            
            switch type
                case 1
                    xdata1 = fit1.paraRange(:,m);
                    ydata1 = fit1.likelihood(:,m);                    
                    xdata2 = fit1.lkFitRange(:,m);
                    ydata2 = fit1.lkFit(:,m);
            
                    plot(ax,xdata1,ydata1,'o','markersize',8,'linewidth',2);
                    hold(ax,'on');
                    plot(ax,xdata2,ydata2,'r','linewidth',2);
                    hold(ax,'off');
                    xlabel(ax,x.fluoFit.parameters{m});
                    ylabel(ax,'Normalized Likelihood');
                    title(ax,sprintf('%s %s','Likelihood Distribution of',x.fluoFit.parameters{m}));
                    legend(ax,'Likelihood','Gaussian Fit');
                case 2
                    xdata1 = fit1.paraRange(:,m);
                    ydata1 = fit1.chi2(:,m);
                    
                    plot(ax,xdata1,ydata1,'o','markersize',8,'linewidth',2);
                    xlabel(ax,x.fluoFit.parameters{m});
                    ylabel(ax,'Raw \chi^2');
                    title(ax,sprintf('%s %s','\chi^2 of',x.fluoFit.parameters{m}));
                    legend(ax,'\chi^2');
            end
            
        end
        
        function plotDoublePara(x,m,type,ax)
            %m are the 2 parameters index within the 5 parameters
            
            switch nargin
                case 2
                    type = 1;
                    ax = gca;
                case 3
                    ax = gca;
            end
            
            m(1) = sum(x.fitted(1:m(1)));
            m(2) = sum(x.fitted(1:m(2)));
            fit2 = x.fluoFit.fit2{m(1),m(2)};
            xdata =fit2.paraRange1;
            ydata = fit2.paraRange2;
            
            switch type
                case 1
                    C = fit2.contour;
                    lk = fit2.lk;
                    contourf(ax,xdata,ydata,lk);
                    colorbar(ax);
                    hold(ax,'on');
                    plot(ax,C(1,:),C(2,:),'r','linewidth',2);
                    hold(ax,'off');
                    xlabel(ax,x.fluoFit.parameters{m(1)});
                    ylabel(ax,x.fluoFit.parameters{m(2)});
                    legend(ax,'Joint Likelihood',sprintf('%.2f %s',x.fluoFit.confidence,'Confidence Window'));
                    title(ax,sprintf('%s %s %s %s','Joint Likelihood of',x.fluoFit.parameters{m(1)},'and',x.fluoFit.parameters{m(2)}));
                case 2
                    chi2 = fit2.chi2;
                    contourf(ax,xdata,ydata,chi2);
                    colorbar(ax);
                    xlabel(ax,x.fluoFit.parameters{m(1)});
                    ylabel(ax,x.fluoFit.parameters{m(2)});
                    legend(ax,'Joint \chi^2');
                    title(ax,sprintf('%s %s %s %s','Joint \chi^2 of',x.fluoFit.parameters{m(1)},'and',x.fluoFit.parameters{m(2)}));
            end
            
        end
        
        function plot1Para(x,para)
            
            m = x.fluoFit.numberOfPara;
            if m > 0
                
                i = 1;
                while i <= m && ~strcmpi(x.fluoFit.parameters{i},para)
                    i = i+1;
                end
                
                if i > m
                    error('%s %s','Did not fit',para);
                end
                
                fit1 = x.fluoFit.fit1;
                figure;
                plot(fit1.paraRange(:,i),fit1.likelihood(:,i),'o');
                hold on;
                plot(fit1.lkFitRange(:,i),fit1.lkFit(:,i),'r');
                hold off;
                xlabel(x.fluoFit.parameters{i},'fontsize',16);
                ylabel('Normalized Likelihood','fontsize',16);
                legend('Likelihood','Gaussian Fit');
                set(gca,'fontsize',14);
            else
                error('%s %s','Did not fit',para);
            end
            
        end
        
        function plot2Para(x,para)
            
            m = x.fluoFit.numberOfPara;
            if m > 1
                
                i = 1;
                while i <= m && ~strcmpi(x.fluoFit.parameters{i},para{1})
                    i = i+1;
                end
                j = 1;
                while j <= m && ~strcmpi(x.fluoFit.parameters{j},para{2})
                    j = j+1;
                end
                
                if i > m || j > m
                    error('%s %s %s %s %s','Did not fit',para{1},'and',para{2},'together.');
                end
                
                fit2 = x.fluoFit.fit2{i,j};
                xdata =fit2.paraRange1;
                ydata = fit2.paraRange2;
                C = fit2.contour;
                lk = fit2.lk;
                figure;
                contourf(xdata,ydata,lk);
                colorbar;
                hold on;
                plot(C(1,:),C(2,:),'r','linewidth',2);
                hold off;
                xlabel(x.fluoFit.parameters{i},'fontsize',16);
                ylabel(x.fluoFit.parameters{j},'fontsize',16);
                legend('Joint Likelihood',sprintf('%.2f %s',x.fluoFit.confidence,'Confidence Window'));
                set(gca,'fontsize',14);
                
            else
                error('Did not fit two parameters.')
            end
            
        end
        
    end
    
end
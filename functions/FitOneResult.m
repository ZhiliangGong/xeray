classdef FitOneResult < handle
    
    properties
        
        parameters
        P
        para
        chi2
        likelihood
        
        value
        std
        adjustedStd
        fitQuality
        likelihoodPara
        likelihoodCurve
        
        confidence
        window
        adjWindow
        
    end
    
    methods
        
        function this = FitOneResult(parameters)
            
            if nargin == 1
                this.parameters = parameters;
            else
                this.parameters = [];
            end
            
        end
        
        function getLikelihood(this)
            
            m = size(this.chi2, 1);
            if m > 1
                lk = this.chi2;
                lk = exp(-(lk - repmat(min(lk), m, 1)) / 2);
                lk = lk ./ repmat(sum(lk), m, 1);
                this.likelihood = lk;
            end
            
        end
        
        function fitLikelihood(this)
            
            m = 100;
            n = size(this.likelihood, 2);
            
            %fit likelihood (lk)
            lkFit = zeros(m, n);
            lkFitRange = zeros(m, n);
            
            lkPara = cell(1, n);
            quality = cell(1, n);
            
            par_para0 = this.para;
            par_parameters = this.parameters;
            par_lk = this.likelihood;
            parfor i = 1:n
                par_para = par_para0;
                [lkPara{i}, flag] = fitGaussianLikelihood(par_para(:, i), par_lk(:, i));
                if flag
                    warning('%s %s', par_parameters{i}, 'fitting bad.');
                    quality{i} = 'bad';
                else
                    quality{i} = 'good';
                end
                
                lkFitRange(:,i) = linspace(par_para(1, i), par_para(end, i), m)';
                lkFit(:,i) = lkPara{i}(1) * exp(-(lkFitRange(:, i) - lkPara{i}(2)).^2 / 2 / lkPara{i}(3)^2);
                
            end
            lkPara = cell2mat(lkPara);
            this.value = lkPara(2, :);
            this.std = lkPara(3, :);
            this.confidence = (normcdf(1) - normcdf(-1))^(1/n);
            this.adjustedStd = this.std .* norminv( (1 - this.confidence) / 2 + this.confidence, 0, 1 );
            this.fitQuality = quality;
            this.likelihoodPara = lkFitRange;
            this.likelihoodCurve = lkFit;
            
            this.getConfidenceWindow();
            
        end
        
        function getConfidenceWindow(this, newConfidence)
            
            if nargin == 1
                newConfidence = 0.95;
            end
            
            if isempty(this.confidence) || newConfidence ~= this.confidence
                this.confidence = newConfidence;
                multiplier = norminv( (1 - newConfidence) / 2 + newConfidence, 0, 1 );
                this.window = [-multiplier * this.std; multiplier * this.std];
                this.window = this.window + repmat(this.value, 2, 1);
                this.adjWindow = [-multiplier * this.adjustedStd; multiplier * this.adjustedStd];
                this.adjWindow = this.adjWindow+repmat(this.value, 2, 1);
            end
            
            
            
        end
        
    end
    
end
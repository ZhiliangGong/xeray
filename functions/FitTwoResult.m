classdef FitTwoResult < handle
    
    properties
        
        parameters
        para1
        para2
        chi2
        likelihood
        
    end
    
    methods
        
        function this = FitTwoResult(parameters)
            
            this.parameters = parameters;
            
        end
        
        function getLikelihood(this)
            
            lk = exp(-(this.chi2 -min(this.chi2(:))) / 2);
            this.likelihood = lk / sum(lk(:));
            
        end
        
    end
    
end
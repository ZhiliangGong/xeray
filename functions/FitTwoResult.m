classdef FitTwoResult < handle
    
    properties
        
        parameters
        para1
        para2
        chi2
        likelihood
        
        confidence
        contour
        center
        window
        
    end
    
    methods
        
        function this = FitTwoResult(parameters)
            
            this.parameters = parameters;
            
        end
        
        function getLikelihood(this)
            
            lk = exp(-(this.chi2 -min(this.chi2(:))) / 2);
            this.likelihood = lk / sum(lk(:));
            
        end
        
        function getConfidenceWindow(this, confidence)
            
            if nargin == 1
                this.confidence = 0.95;
            else
                this.confidence = confidence;
            end
            
            sortedLK = sort( this.likelihood(:) );
            lksum = cumsum(sortedLK);
            lksum = abs(lksum - ( 1 - this.confidence));
            ind = find(lksum == min(lksum), 1);
            cLevel = sortedLK(ind);
            
            C = contourc(this.para1, this.para2, this.likelihood, [cLevel, cLevel]);
            C = C(:, C(1, :) >= min(this.para1));
            C = C(:, C(1, :) <= max(this.para1));
            C = C(:, C(2, :) >= min(this.para2));
            C = C(:, C(2, :) <= max(this.para2));
            this.contour = C;
            
            [ind1,ind2] = find(this.likelihood == max(this.likelihood(:)), 1);
            this.center = [this.para1(ind1),this.para2(ind2)];
            this.window = [min(C(1, :)) ,max(C(1, :)); min(C(2, :)), max(C(2, :))];
            
        end
        
    end
    
end
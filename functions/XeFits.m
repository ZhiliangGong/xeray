classdef XeFits < handle
    
    properties
        
        parameters
        
        lower
        upper
        steps
        
        all
        one
        two
        
    end
    
    methods
        
        function this = XeFits(lower, upper, steps)
            
            this.lower = lower;
            this.upper = upper;
            this.steps = steps;
            
            this.updateParameterNames()
            
        end
        
        function updateBounds(this, lower, upper, steps)
            
            this.lower = lower;
            this.upper = upper;
            this.steps = steps;
            
            this.updateParameterNames();
            
        end
        
        function updateParameterNames(this)
            
            n = length(this.lower);
            this.parameters = cell(1, n);
            this.parameters(1:3) = {'Angle-Offset', 'Scale-Factor', 'Background'};
            
            for i = 1 : n-3
                this.parameters{i+3} = strcat('Conc-', num2str(i));
            end
            
        end
        
        function paras = fitParameters(this)
             
            paras = this.parameters(this.varied);
            
        end
        
        function location = fixed(this)
            
            location = this.lower == this.upper;
            
        end
        
        function location = varied(this)
            
            location = this.lower ~= this.upper;
            
        end
        
        function x = lb(this)
            
            x = this.lower(this.varied);
            
        end
        
        function x = ub(this)
            
            x = this.upper(this.varied);
            
        end
        
        function st = start(this)
            
            st = (this.lower(this.varied) + this.upper(this.varied)) / 2;
            
        end
        
        function fp = fullP(this, fittingStart)
            
            fp(this.fixed) = this.lower(this.fixed);
            fp(this.varied) = fittingStart;
            
        end
        
        function loc = location(this)
            
            loc = find(this.varied);
            
        end
        
        function loc = fitParaIndex(this, parameter)
            
            index = locateStringInCellArray(parameter, this.parameters);
            loc = find(index == this.location);
            if isempty(loc)
                loc = 0;
            end
            
        end
        
    end
    
end
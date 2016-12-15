classdef XeFitting < handle
    
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
        
        function this = XeFitting(varargin)
            
            this.parameters = {'Angle-Offset', 'Scale-Factor', 'Background', 'Concentration', 'Layer'};
            
            values = { [0, 0, -100, 50, 2], [0.01, 100, 100, 50, 1], 20 };
            values(1:length(varargin)) = varargin;
            
            this.lower = values{1};
            this.upper = values{2};
            this.steps = values{3};
            
            if sum(this.upper < this.lower) > 0
                error('The lower bounds must be smaller or equal to the upper bounds.');
            end
            
        end
        
        function updateBounds(this, lower, upper, steps)
            
            this.lower = lower;
            this.upper = upper;
            this.steps = steps;
            
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
            
            fp = zeros(1, 5);
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
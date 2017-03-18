classdef DoubleLayerFits < handle
    
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
        
        function this = DoubleLayerFits(lower, upper, steps)
            
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
            
            const = 4;
            
            n = length(this.lower);
            this.parameters = cell(1, n);
            this.parameters(1:const) = {'Angle-Offset', 'Scale-Factor', 'Decay-Length', 'Background'};
            this.parameters{end} = 'Conc-bottom';
            
            for i = 1 : n - const - 1
                this.parameters{i+const} = strcat('Conc-', num2str(n - const - i));
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
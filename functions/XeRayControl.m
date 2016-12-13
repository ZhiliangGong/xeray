classdef XeRayControl
    
    properties
        
        element
        lineShapes
        lineShape
        plot
        colors
        symbols
        
    end
    
    methods
        
        function this = XeRayControl()
            
            this.element = 'none';
            this.lineShapes = {'Gaussian','Lorentzian'};
            this.lineShape = this.lineShapes{1};
            
            %initial plot control
            this.plot.element = 0;
            this.plot.para = -ones(1,5);
            this.plot.likelihood = 1;
            this.plot.error = 0;
            this.plot.background = 0;
            this.plot.calculation = 0;
            this.plot.fit = 0;
            
            this.colors = 'kbrgcmy';
            this.symbols = 'o^vsd><ph+*x.';
            
        end
        
    end
    
end
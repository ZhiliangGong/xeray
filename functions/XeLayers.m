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
        function this = XeLayers(energy, file)
            
            this.config = textread('xeray-config.txt', '%s', 'delimiter', '\n');
            
            this.system = XeSystem(this.config, energy);
            this.rawdata = XeRawData(file);
            this.data = XeElementData(this.config);
            this.fit = XeFitting();

        end
        
        % obtain the data for a chosen element as a preparation for fitting
        function selectElement(this, element, lineshape)
            
            if nargin == 2
                lineshape = 'Gaussian';
            end
            
            this.data.updateElement(element, this.rawdata, lineshape);
            
        end
        
        function plotSignal(this, axis)
            
            if nargin == 1
                axis = gca;
            end
            
            errorbar(axis, this.data.angle, this.data.lineshape.signal, this.data.lineshape.signalError,'o','markersize',8,'linewidth',2);
            hold(axis,'on');
            plot(axis, this.data.angle, this.system.calculateFluoIntensity(this.data.element, this.data.angle), 'r-', 'linewidth', 2);
            hold(axis,'off');
            xlabel(axis,'Qz');
            ylabel(axis,'Integrated Signal (a.u.)');
            legend(axis,'Data','Fit');
            title(axis,sprintf('%s %s', this.data.element, 'Fluorescence'));
            
        end

    end

end

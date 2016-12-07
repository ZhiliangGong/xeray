classdef XeLineshape < handle
    
    properties
        
        type
        energy
        intensity
        netIntensity
        parameters
        signal
        signalError
        
    end
    
    methods
        
        function this = XeLineshape(originalEnergy, originalIntensity, originalIntensityError, type, peaks, width, N)
            
            this.type = type;
            [~, n] = size(originalIntensity);
            
            this.energy = linspace(originalEnergy(1), originalEnergy(end), N)';
            this.intensity = zeros(N, n);
            
            switch length(peaks)
                case 1
                    this.parameters = zeros(5,n);
                case 2
                    this.parameters = zeros(8,n);
                otherwise
                    error('Curve type not found.');
            end
            
            % fitting to the lineshape
            for i = 1:n
                [this.parameters(:,i), ~, this.intensity(:,i)] = fluoCurveFit(originalEnergy, originalIntensity(:,i), type, peaks, width, N);
            end
            
            % integration
            this.netIntensity = this.intensity - [this.energy, ones(size(this.energy))] * this.parameters(end-1:end, :);
            
            switch length(peaks)
                case 1
                    M = 1;
                    ratio = 1;
                case 2
                    ratio = sum(this.parameters(1,:)) / sum(this.parameters(3,:));
                    if ratio > 1
                        M = 1;
                        ratio = ratio/(ratio+1);
                    else
                        M = 4;
                        ratio = 1/(ratio+1);
                    end
            end
            
            switch type
                case 'Gaussian'
                    this.signal = this.parameters(M,:) .* this.parameters(2+M, :) * sqrt(2*pi);
                case 'Lorentzian'
                    this.signal = this.parameters(M,:) .* this.parameters(2+M,:) * 2;
            end
            
            this.signalError = sqrt(sum(originalIntensityError.^2)) * range(originalEnergy) / length(originalEnergy) * ratio;
            
        end
        
    end
    
end
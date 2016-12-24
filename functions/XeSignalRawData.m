classdef XeSignalRawData < handle

    properties

        angle
        signal
        signalError

    end

    methods

        function this = XeSignalRawData(file, angleType)

            if nargin == 1
                angleType = 'radian';
            end
            
            data = importdata(file);
            
            switch angleType
                case 'radian'
                    this.angle = asin(data(:, 1) * 1.2398 / 4 / pi);
                    %this.angle = data(:, 1);
                case 'qz'
                    this.angle = asin(data(:, 1) * 1.2398 / 4 / pi);
            end
            
            this.signal = data(:, 2);
            this.signalError = data(:, 3);

        end

    end

end

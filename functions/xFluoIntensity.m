function I = xFluoIntensity(dispersion,absorption,wavelength,dispersion1,absorption1,wavelength1,slitSize,detectionLength,angle,scaleFactor,bulk,surf,background)
    %angle in radian, slit size in mm, delectionLength in mm
    
    criticalAngle = sqrt(2*dispersion);
    T = abs(2*angle./(angle+sqrt(angle.^2-criticalAngle^2))).^2; %transmission
    L = wavelength./(4*pi*imag(sqrt(angle.^2-criticalAngle^2+2*1i*absorption))) / 1e7; %penetration depth in mm
    
    criticalAngle1 = sqrt(2*dispersion1);
    L1 = wavelength1/(4*pi*imag(sqrt((pi/2)^2-criticalAngle1^2+2*1i*absorption1))) / 1e7; %penetration depth for excited wave
    
    L = L*L1./(L+L1);
    
    sel1 = slitSize./sin(angle) > detectionLength;
    
    term0 = zeros(size(angle));
    term0(sel1) = ones(1,sum(sel1)) * detectionLength;
    term0(~sel1) = slitSize./sin(angle(~sel1));
    
    term1 = L./tan(angle) .* exp(-(tan(angle)./L.*(slitSize/2./sin(angle)+detectionLength/2)));
    term2 = L./tan(angle) .* exp(-(tan(angle)./L.*abs(slitSize/2./sin(angle)-detectionLength/2)));
    
    IB = scaleFactor .* T * bulk .* L .* (term0 + term1 - term2);
    
    factor = zeros(size(angle));
    factor(sel1) = detectionLength / slitSize;
    factor(~sel1) = 1 ./ sin(angle(~sel1));
    IS = scaleFactor .* T * surf .* factor .* slitSize / 6.0221413e2;
    
    I = IB + IS + background;

end
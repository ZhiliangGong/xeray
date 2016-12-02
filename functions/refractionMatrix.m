function M = refractionMatrix(incidenceAngle, wavelength, dispersion1, absorption1, thickness1, dispersion2, absorption2, thickness2)
% calculate the refraction matrix
% dispersion1 and absorption1 are that of the top layer
% dispersion2 and absorptin2 are that of the bottom layer

% units: angle - in radian

    M = zeros(2, 2);
    k = 2 * pi / wavelength;
    angle1 = sqrt(incidenceAngle^2 - 2 * dispersion1 + 1i * 2 * absorption1);
    angle2 = sqrt(incidenceAngle^2 - 2 * dispersion2 + 1i * 2 * absorption2);
    
    M(1,1) = (angle1 + angle2)/(2 * angle1) * exp(-1i * k / 2 * (angle1 * thickness1 + angle2 * thickness2));
    M(1,2) = (angle1 - angle2)/(2 * angle1) * exp(-1i * k / 2 * (angle1 * thickness1 - angle2 * thickness2));
    M(2,1) = (angle1 - angle2)/(2 * angle1) * exp(1i * k / 2 * (angle1 * thickness1 - angle2 * thickness2));
    M(2,2) = (angle1 + angle2)/(2 * angle1) * exp(1i * k / 2 * (angle1 * thickness1 + angle2 * thickness2));

end
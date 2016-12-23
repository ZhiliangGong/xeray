function theta = refractionAngle(theta0, dispersion, absorption)
% calculate the refraction angle

    theta = sqrt(theta0.^2 - 2 * dispersion + 2i * absorption);

end
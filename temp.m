
angles = reshape(angles, length(angles), 1);

if s.thickness(end) ~= Inf
    error('The last layer must have infinite thickness.')
end

slits = s.slit * 1e7;
foots = s.foot * 1e7;

m = length(angles);
n = s.N;

refractionAngle = s.incidence.getRefractionAngle(angles);

theta1 = [angles, refractionAngle(:, 1:end-1)];
theta2 = refractionAngle;
d1 = repmat([0, s.thickness(1:end-1)], m, 1);
d2 = repmat([s.thickness(1:end-1), 0], m, 1); % calculate the intensity at the interface for the last layer

ratio1 = (theta1 + theta2) / 2 ./ theta1;
ratio2 = (theta1 - theta2) / 2 ./ theta1;
expo1 = 1i * pi / s.incidence.wavelength * (theta1 .* d1 + theta2 .* d2);
expo2 = 1i * pi / s.incidence.wavelength * (theta1 .* d1 - theta2 .* d2);

M = zeros(m, n, 4);
M(:, :, 1) = ratio1 .* exp(-expo1);
M(:, :, 2) = ratio2 .* exp(-expo2);
M(:, :, 3) = ratio2 .* exp(expo2);
M(:, :, 4) = ratio1 .* exp(expo1);

tempmatrix = cell(m, n);
matrices = cell(m, n);
for i = 1 : m
    for j = n : -1 : 1
        tempmatrix{i, j} = reshape(M(i, j, :), 2, 2)';
        matrices{i, j} = eye(2);
        for k = j : n
            matrices{i, j} = matrices{i, j} * tempmatrix{i, k};
        end
    end
end

tamp = zeros(m, n);
ramp = zeros(m, n);

ramp(:, end) = 0;
for i = 1 : m
    tamp(i, end) = 1 / matrices{i, 1}(1, 1);
end

for i = 1 : m
    for j = 1 : n - 1
        tamp(i, j) = matrices{i, j+1}(1, 1) * tamp(i, end);
        ramp(i, j) = matrices{i, j+1}(2, 1) * tamp(i, end);
    end
end

phaseLength = cumsum([0, s.thickness(1:end-1)]) - [s.thickness(1:end-1), 0] / 2;
phaseShift = 2 * pi / s.incidence.wavelength * refractionAngle .* repmat(phaseLength, m, 1);
transmission = tamp .* exp( 1i * phaseShift );
reflection = ramp .* exp( -1i * phaseShift );

alpha = repmat(angles, 1, n);
delta = repmat(s.incidence.dispersion, m, 1);
beta = repmat(s.incidence.absorption, m, 1);

alpha1 = pi/2;
delta1 = repmat(s.emission.dispersion, m, 1);
beta1 = repmat(s.emission.absorption, m, 1);

p0 = s.incidence.wavelength / 4 / pi ./ imag( sqrt( alpha.^2 - 2 * delta + 2i * beta ) );
p1 = s.emission.wavelength / 4 / pi ./ imag( sqrt( alpha1.^2 - 2 * delta1 + 2i * beta1 ) );

location = ~(p1 == Inf);

penetration = p0;
penetration(location) = p0(location) .* p1(location) ./ (p0(location) + p1(location));

% intensity below each of the interface
d = repmat([0, s.thickness(1:end-1)], m, 1);
attenuation = exp( - d ./ [ones(m, 1), penetration(:, 1:end-1)]);
attenuation = cumprod(attenuation, 2);
intensity = abs((transmission + reflection).^2) .* attenuation;

% integrate for the top thin layers
zdiff = repmat(s.thickness, m, 1);

location = (penetration == Inf);
d = zdiff(:, 1:end-1);
integralFactor = penetration(:, 1:end-1) .* ( 1 - exp(- d ./ penetration(:, 1:end-1)) );
integralFactor(location(:, 1:end-1)) = d(location(:, 1:end-1));
%integralFactor = penetration(:, 1:end-1) .* (exp(-z(:, 1:end-2) ./ penetration(:, 1:end-1)) - exp(-z(:, 2:end-1) ./ penetration(:, 1:end-1)));
%integralFactor(location) = zdiff(location);
intensity(:, 1:end-1) = intensity(:, 1:end-1) .* integralFactor;

larger = slits./sin(angles) > foots;
smaller = ~larger;
%larger(end) = false;
%smaller(end) = false;
intensity(larger, 1:end-1) = intensity(larger, 1:end-1) * foots;
intensity(smaller, 1:end-1) = intensity(smaller, 1:end-1) * slits ./ alpha(smaller, 1:end-1);

% integrate for the bottom infinite layer
larger = slits./sin(angles) > foots;

term0 = zeros(size(angles));
term0(larger) = ones(sum(larger), 1) * foots;
term0(~larger) = slits ./ sin(angles(~larger));

L = penetration(:, end);
term1 = L ./ tan(angles) .* exp( -(tan(angles) ./ L .* (slits / 2 ./ sin(angles) + foots / 2)) );
term2 = L ./ tan(angles) .* exp( -(tan(angles) ./ L .* abs(slits / 2 ./ sin(angles) - foots / 2)) );

intensity(:, end) = intensity(:, end) .* L .* (term0 + term1 - term2);

intensity = intensity / 1e14;
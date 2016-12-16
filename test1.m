%angles = this.angle';
this = c.system;
angles = linspace(0.0017, 0.0032, 100)';

slits = this.slit * 1e7; % mm to A
foots = this.foot * 1e7; % mm to A
thick = this.thickness;

m = length(angles);
n = this.N;

refractionAngle = this.incidence.getRefractionAngle(angles);

theta1 = [angles, refractionAngle(:, 1:end-1)];
theta2 = refractionAngle;
d1 = repmat([0, thick(1:end-1)], m, 1);
d2 = repmat([thick(1:end-1), 0], m, 1); % calculate the intensity at the interface for the last layer

ratio1 = (theta1 + theta2) / 2 ./ theta1;
ratio2 = (theta1 - theta2) / 2 ./ theta1;
expo1 = 1i * pi / this.incidence.wavelength * (theta1 .* d1 + theta2 .* d2);
expo2 = 1i * pi / this.incidence.wavelength * (theta1 .* d1 - theta2 .* d2);

M = zeros(m, n, 4);
M(:, :, 1) = ratio1 .* exp(-expo1);
M(:, :, 2) = ratio2 .* exp(-expo2);
M(:, :, 3) = ratio2 .* exp(expo2);
M(:, :, 4) = ratio1 .* exp(expo1);

matrices = cell(m, n);
for i = 1 : m
    matrices{i, n} = reshape(M(i, n, :), 2, 2)';
    for j = n-1 : -1 : 1
        matrices{i, j} = reshape(M(i, j, :), 2, 2)' * matrices{i, j+1};
    end
end

tamp = zeros(m, n);
ramp = zeros(m, n);

for i = 1 : m
    tamp(i, end) = 1 / matrices{i, 1}(1, 1);
end

for i = 1 : m
    for j = 1 : n - 1
        tamp(i, j) = matrices{i, j+1}(1, 1) * tamp(i, end);
        ramp(i, j) = matrices{i, j+1}(2, 1) * tamp(i, end);
    end
end

phaseLength = [thick(1:end-1), 0] / 2;
phaseShift = 2 * pi / this.incidence.wavelength * refractionAngle .* repmat(phaseLength, m, 1);
transmission = tamp .* exp( -1i * phaseShift );
reflection = ramp .* exp( 1i * phaseShift );

alpha = repmat(angles, 1, n);
delta = repmat(this.incidence.dispersion, m, 1);
beta = repmat(this.incidence.absorption, m, 1);

alpha1 = pi/2;
delta1 = repmat(this.emission.dispersion, m, 1);
beta1 = repmat(this.emission.absorption, m, 1);

p0 = this.incidence.wavelength / 4 / pi ./ imag( sqrt( alpha.^2 - 2 * delta + 2i * beta ) );
p1 = this.emission.wavelength / 4 / pi ./ imag( sqrt( alpha1.^2 - 2 * delta1 + 2i * beta1 ) );

location = ~(p1 == Inf);

penetration = p0;
penetration(location) = p0(location) .* p1(location) ./ (p0(location) + p1(location));

% intensity below each of the interface
d = repmat([0, thick(1:end-1)], m, 1);
attenuation = exp( - d ./ [ones(m, 1), penetration(:, 1:end-1)]);
attenuation = cumprod(attenuation, 2);
intensity = abs((transmission + reflection).^2) .* attenuation;
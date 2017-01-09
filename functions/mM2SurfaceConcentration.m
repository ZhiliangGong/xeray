function result = mM2SurfaceConcentration(conc, depth)

% return number per nm^2, concentration in mM, depth in A

result = depth * 1e-9 * (1e-8)^2 * conc * 1e-3 * 6.0221409e+23;

end
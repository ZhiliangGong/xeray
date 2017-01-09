c0 = 5356;
delta = 167;
c = [c0 - 2*delta, c0, c0 + 2*delta];
h = 4.6;
s = mM2SurfaceConcentration(c, h);
areaPerMoleculr = 1./s * 100; % area per molecule in A^2
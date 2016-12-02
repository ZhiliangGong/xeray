clear;
s = xlayers(1);
s.push(1, 1, Inf, 'H2OCa0.009Cl0.018');
s.refractionIndex(10);
s.optics(linspace(0.001, 0.004, 10));
s.calculateFluoIntensity('Ca');
clear;
s = xlayers(3);
s.push(1, 0.25, 12);
s.push(2, 0.4, 8);
s.push(3, 1, Inf, 'H2OCa0.009Cl0.018');
s.refractionIndex(10);
s.optics(linspace(0.001, 0.004, 10));
s.calculateFluoIntensity('Ca');
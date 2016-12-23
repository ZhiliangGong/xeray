function t = measurePerformance(f)
% measure the time needed to run a certain function for 1000 times

    n = 1000;
    t = zeros(1, n);
    for i = 1:1000
        t(i) = timeit(f);
    end
    t = sum(t);

end
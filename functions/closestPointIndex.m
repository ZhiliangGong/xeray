function index = closestPointIndex(dataPoints, dataArray)

    n = numel(dataPoints);
    index = zeros(1, n);
    for i = 1 : n
        diff = abs(dataArray - dataPoints(i));
        index(i) = find(diff == min(diff), 1);
    end

end
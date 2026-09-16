function globalRegion = loadCovidData(filename)
    load(filename, 'covid_data');

    header = covid_data(1, :);
    rawData = covid_data(2:end, :);
    dates = datetime(header(3:end), 'InputFormat', 'MM/dd/yy');

    countries = unique(rawData(:,1));
    globalRegion = CovidRegion("Global", dates, zeros(1,numel(dates)), zeros(1,numel(dates)));

    for i = 1:numel(countries)
        countryName = countries{i};
        indices = strcmp(rawData(:,1), countryName);
        countryData = rawData(indices, :);

        countryCases = zeros(1, numel(dates));
        countryDeaths = zeros(1, numel(dates));
        countryObj = CovidRegion(countryName, dates, countryCases, countryDeaths);

        for j = 1:size(countryData,1)
            stateName = countryData{j,2};
            values = countryData(j,3:end);
            values = cell2mat(values');
            stateCases = values(1:2:end);
            stateDeaths = values(2:2:end);
            regionObj = CovidRegion(stateName, dates, stateCases, stateDeaths);
            countryObj = countryObj.addChild(regionObj);

            % 加總進國家
            countryObj.CumulativeCases = countryObj.CumulativeCases + stateCases;
            countryObj.CumulativeDeaths = countryObj.CumulativeDeaths + stateDeaths;
        end

        globalRegion = globalRegion.addChild(countryObj);
        globalRegion.CumulativeCases = globalRegion.CumulativeCases + countryObj.CumulativeCases;
        globalRegion.CumulativeDeaths = globalRegion.CumulativeDeaths + countryObj.CumulativeDeaths;
    end
end

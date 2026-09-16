classdef Covid19 < matlab.apps.AppBase
    properties (Access = public)
        UIFigure                   matlab.ui.Figure
        CountryDropDownLabel       matlab.ui.control.Label
        CountryDropDown            matlab.ui.control.ListBox
        StateDropDownLabel         matlab.ui.control.Label
        StateDropDown              matlab.ui.control.ListBox
        PlotTypeButtonGroup        matlab.ui.container.ButtonGroup
        CasesButton                matlab.ui.control.RadioButton
        DeathsButton               matlab.ui.control.RadioButton
        BothButton                 matlab.ui.control.RadioButton
        DataTypeButtonGroup        matlab.ui.container.ButtonGroup
        CumulativeButton           matlab.ui.control.RadioButton
        DailyButton                matlab.ui.control.RadioButton
        DaysSliderLabel            matlab.ui.control.Label
        DaysSlider                 matlab.ui.control.Slider
        UIAxes                     matlab.ui.control.UIAxes
    end

    properties (Access = private)
        GlobalRegion
        CountryList
    end

    methods (Access = private)

        function updatePlot(app)
            try
                countryName = app.CountryDropDown.Value;
                stateName = app.StateDropDown.Value;
                days = round(app.DaysSlider.Value);
                plotType = app.PlotTypeButtonGroup.SelectedObject.Text;
                dataType = app.DataTypeButtonGroup.SelectedObject.Text;

                % 取得地區物件
                if strcmp(countryName, 'Global')
                    region = app.GlobalRegion;
                else
                    country = app.CountryList(countryName);
                    if isKey(country.StateMap, stateName) && ~strcmp(stateName, 'All')
                        region = country.StateMap(stateName);
                    else
                        region = country;
                    end
                end

                % 取得並排序日期
                dates = keys(region.Data);
                dt = datetime(dates, 'InputFormat', 'MM/dd/yy');
                [dt, idx] = sort(dt);
                dates = dates(idx);

                cases = zeros(1, length(dates));
                deaths = zeros(1, length(dates));
                for i = 1:length(dates)
                    data = region.Data(dates{i});
                    cases(i) = data(1);
                    deaths(i) = data(2);
                end

                if strcmp(dataType, 'Daily')
                    cases = [cases(1), diff(cases)];
                    deaths = [deaths(1), diff(deaths)];
                    cases(cases < 0) = 0;
                    deaths(deaths < 0) = 0;
                end

                % 只顯示最近 N 天
                N = min(days, length(dt));
                dt = dt(end-N+1:end);
                cases = cases(end-N+1:end);
                deaths = deaths(end-N+1:end);

                % 移動平均（只用於死亡數折線）
                maFilter = ones(1, N) / N;
                ma_deaths = conv(deaths, maFilter, 'same');

                % 清除舊圖
                cla(app.UIAxes);
                hold(app.UIAxes, 'off');

                if strcmp(plotType, 'Cases')
                    yyaxis(app.UIAxes, 'left');
                    bar(app.UIAxes, dt, cases, 'FaceColor', 'b', 'EdgeColor', 'b', ...
                        'FaceAlpha', 0.5, 'BarWidth', 0.8);
                    ylabel(app.UIAxes, 'Cases');
                    yyaxis(app.UIAxes, 'right');
                    ylabel(app.UIAxes, '');

                elseif strcmp(plotType, 'Deaths')
                    yyaxis(app.UIAxes, 'right');
                    plot(app.UIAxes, dt, ma_deaths, '-r', 'LineWidth', 2);
                    ylabel(app.UIAxes, 'Deaths');
                    yyaxis(app.UIAxes, 'left');
                    ylabel(app.UIAxes, '');

                elseif strcmp(plotType, 'Both')
                    yyaxis(app.UIAxes, 'left');
                    bar(app.UIAxes, dt, cases, 'FaceColor', 'b', 'EdgeColor', 'b', ...
                        'FaceAlpha', 0.5, 'BarWidth', 0.8);
                    ylabel(app.UIAxes, 'Cases');
                    hold(app.UIAxes, 'on');
                    yyaxis(app.UIAxes, 'right');
                    plot(app.UIAxes, dt, ma_deaths, '-r', 'LineWidth', 2);
                    ylabel(app.UIAxes, 'Deaths');
                end

                title(app.UIAxes, sprintf('Cases and Deaths in %s (Last %d Days)', stateName, N));
                xlabel(app.UIAxes, 'Date');
                grid(app.UIAxes, 'on');
            catch ME
                disp(['Error in updatePlot: ' ME.message]);
            end
        end

        function updateStates(app)
            countryName = app.CountryDropDown.Value;
            if strcmp(countryName, 'Global')
                app.StateDropDown.Items = {'All'};
            else
                country = app.CountryList(countryName);
                states = keys(country.StateMap);
                if isempty(states)
                    app.StateDropDown.Items = {'All'};
                else
                    app.StateDropDown.Items = ['All', states];
                end
            end
        end

        function createComponents(app)
            app.UIFigure = uifigure('Position', [100 100 800 600], 'Name', 'COVID-19 Data Visualization');
            app.CountryDropDownLabel = uilabel(app.UIFigure, 'Position', [30 560 100 22], 'Text', 'Country');
            app.CountryDropDown = uilistbox(app.UIFigure, 'Position', [30 410 150 150]);
            app.CountryDropDown.ValueChangedFcn = @(src, event) app.CountryDropDownValueChanged(event);

            app.StateDropDownLabel = uilabel(app.UIFigure, 'Position', [30 380 100 22], 'Text', 'State');
            app.StateDropDown = uilistbox(app.UIFigure, 'Position', [30 230 150 150]);
            app.StateDropDown.ValueChangedFcn = @(src, event) app.StateDropDownValueChanged(event);

            app.PlotTypeButtonGroup = uibuttongroup(app.UIFigure, 'Position', [200 500 150 100], 'Title', 'Plot Type');
            app.CasesButton = uiradiobutton(app.PlotTypeButtonGroup, 'Position', [10 60 100 22], 'Text', 'Cases');
            app.DeathsButton = uiradiobutton(app.PlotTypeButtonGroup, 'Position', [10 35 100 22], 'Text', 'Deaths');
            app.BothButton = uiradiobutton(app.PlotTypeButtonGroup, 'Position', [10 10 100 22], 'Text', 'Both');
            app.PlotTypeButtonGroup.SelectionChangedFcn = @(src, event) app.PlotTypeChanged(event);

            app.DataTypeButtonGroup = uibuttongroup(app.UIFigure, 'Position', [200 390 150 100], 'Title', 'Data Type');
            app.CumulativeButton = uiradiobutton(app.DataTypeButtonGroup, 'Position', [10 60 100 22], 'Text', 'Cumulative');
            app.DailyButton = uiradiobutton(app.DataTypeButtonGroup, 'Position', [10 35 100 22], 'Text', 'Daily');
            app.DataTypeButtonGroup.SelectionChangedFcn = @(src, event) app.DataTypeChanged(event);

            app.DaysSliderLabel = uilabel(app.UIFigure, 'Position', [200 350 150 22], 'Text', 'Days to Display');
            app.DaysSlider = uislider(app.UIFigure, 'Position', [200 330 150 3], 'Limits', [1 60], 'Value', 14);
            app.DaysSlider.ValueChangedFcn = @(src, event) app.DaysSliderValueChanged(event);

            app.UIAxes = uiaxes(app.UIFigure, 'Position', [370 50 400 500]);
        end
    end

    methods (Access = public)

        function app = Covid19
            createComponents(app);
            registerApp(app, app.UIFigure);
            runStartupFcn(app, @(app)startupFcn(app));
        end

        function delete(app)
            delete(app.UIFigure);
        end

        function startupFcn(app)
            try
                load('processed_data.mat', 'globalRegion', 'countryList');
                app.GlobalRegion = globalRegion;

                map = containers.Map;
                items = {'Global'};
                for i = 1:length(countryList)
                    c = countryList{i};
                    items{end+1} = c.Name;
                    map(c.Name) = c;
                end
                app.CountryList = map;
                app.CountryDropDown.Items = items;
                app.CountryDropDown.Value = 'Global';
                app.StateDropDown.Items = {'All'};
                app.StateDropDown.Value = 'All';
                app.BothButton.Value = true;
                app.DailyButton.Value = true;
                updatePlot(app);
            catch ME
                disp(['Error in startupFcn: ' ME.message]);
            end
        end

        function CountryDropDownValueChanged(app, event)
            updateStates(app);
            app.StateDropDown.Value = 'All';
            updatePlot(app);
        end

        function StateDropDownValueChanged(app, event)
            updatePlot(app);
        end

        function DaysSliderValueChanged(app, event)
            updatePlot(app);
        end

        function PlotTypeChanged(app, event)
            updatePlot(app);
        end

        function DataTypeChanged(app, event)
            updatePlot(app);
        end

    end
end

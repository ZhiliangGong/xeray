function XeRay2

%XeRay GUI for analyzing near total reflection x-ray fluorescence data for
%   all types of elements. Pre-constructured data reading routine is built
%   in for Sector 15 of APS, while other data formats need to be imported.
%   Add the folder to Matlab search path, and run XeRay to start.
%
%   Zhiliang Gong, Ka Yee Lee Lab, University of Chicago

%% GUI, create the GUI handle
set(0,'units','pixels');
pix = get(0,'screensize');
if pix(4)*0.85 > 800
    height = 800;
else
    height = pix(4)*0.85;
end

handles = figure('Visible','off','Name','on','NumberTitle','off','Units','pixels',...
    'Position',[190,15,1250,height],'Resize','on');

%% GUI, common shared data

info = {}; %stores all the necessary information
x = {}; %stores all the data;
initializeInfo;

%% GUI, list panel
listPanel = uipanel(handles,'Title','X-ray Fluorescence Data','Units','normalized',...
    'Position',[0.014 0.02 0.16 0.97]);

scanText = uicontrol(listPanel,'Style','text','String','Select data sets to begin','Units','normalized',...
    'Position',[0.05 0.965 0.8 0.03]);

scanList = uicontrol(listPanel,'Style','listbox','Units','normalized',...
    'Position',[0.05 0.56 0.9 0.405],'Max',2,'CallBack',@scanList_Callback);

loadButton = uicontrol(listPanel,'Style','pushbutton','String','Load','Units','normalized',...
    'Position',[0.035 0.52 0.3 0.032],'Callback',@loadButton_Callback);

deleteButton = uicontrol(listPanel,'Style','pushbutton','String','Delete','Units','normalized',...
    'Position',[0.38 0.52 0.3 0.032],'Callback',@deleteButton_Callback);

uicontrol(listPanel,'Style','text','String','Select Qz range','Units','normalized',...
    'Position',[0.05 0.49 0.8 0.03]);

qzList = uicontrol(listPanel,'Style','listbox','Units','normalized',...
    'Position',[0.05 0.015 0.9 0.48],'Max',2,'CallBack',@qzList_Callback);

%% GUI, axes
% plot region 1
showError = uicontrol(handles,'Style','checkbox','String','Show Error','Units','normalized','Visible','on',...
    'Position',[0.6 0.965 0.1 0.018],'CallBack',@showError_Callback);

likelihoodChi2 = uicontrol(handles,'Style','popupmenu','String',{'Likelihood','Chi^2'},'Visible','off',...
    'Units','normalized',...
    'Position',[0.572 0.97 0.1 0.018],'CallBack',@likelihoodChi_Callback);

showCal = uicontrol(handles,'Style','checkbox','String','Show Calc.','Units','normalized',...
    'Position',[0.6 0.437 0.08 0.018],'CallBack',@showCal_Callback);

showFit = uicontrol(handles,'Style','checkbox','String','Show Fit','Units','normalized',...
    'Position',[0.54 0.437 0.06 0.018],'CallBack',@showFit_Callback);

ax1 = axes('Parent',handles,'Units','normalized','Position',[0.215 0.52 0.45 0.44]);
ax1.XLim = [0 10];
ax1.YLim = [0 10];
ax1.XTick = [0 2 4 6 8 10];
ax1.YTick = [0 2 4 6 8 10];
ax1.XLabel.String = 'x1';
ax1.YLabel.String = 'y1';

% plot region 2
ax2 = axes('Parent',handles,'Units','normalized','Position',[0.215 0.08 0.45 0.35]);
ax2.XLim = [0 10];
ax2.YLim = [0 10];
ax2.XTick = [0 2 4 6 8 10];
ax2.YTick = [0 2 4 6 8 10];
ax2.XLabel.String = 'x2';
ax2.YLabel.String = 'y2';

%% GUI, panel on the right
rightPanel = uipanel(handles,'Units','normalized','Position',[0.68 0.02 0.31 0.97]);

elementEditPanel = uipanel(handles,'Title','Element Management','Visible','off','Units','normalized',...
    'Position',[0.685 0.57 0.3 0.375]);

%% GUI, element edit panel

uicontrol(elementEditPanel,'Style','text','String','Existing Elements','Units','normalized',...
    'HorizontalAlignment','left','Position',[0.02 0.9 0.3 0.0825]);

uicontrol(elementEditPanel,'Style','pushbutton','String','Close','Units','normalized',...
    'Position',[0.8 0.9 0.15 0.0825],'Callback',@closeElementTab_Callback);

elementListbox = uicontrol(elementEditPanel,'Style','listbox','String',info.elements,'Units','normalized',...
    'Position',[0.02 0.04 0.2 0.88],'Max',1,'CallBack',@elementListbox_Callback);

uicontrol(elementEditPanel,'Style','text','String','Element Name:','Units','normalized',...
    'HorizontalAlignment','left','Position',[0.25 0.86 0.25 0.05]);

elementNameInput = uicontrol(elementEditPanel,'Style','edit','String',info.elements{1},'Units','normalized',...
    'HorizontalAlignment','left','Position',[0.45 0.84 0.25 0.08]);

columnName = {'1','2'};
columnFormat = {'numeric','numeric'};
columnWidth = {60,60};
rowName = {'Range (keV)','Peaks (keV)','FWHM (keV)'};
elementTableData = getDataForElementTable(info.elements{1});

elementTable = uitable(elementEditPanel,'ColumnName', columnName,'Data',elementTableData,...
            'ColumnFormat', columnFormat,'ColumnEditable', [true true],'Units','normalized',...
            'ColumnWidth',columnWidth,'RowName',rowName,'RowStriping','off',...
            'Position',[0.25 0.45 0.7 0.36]);

uicontrol(elementEditPanel,'Style','text','String','Note: (1) FWHM is optinal, (2) enter both the lower and upper bounds, (3) enter 1 or 2 peaks.',...
    'Units','normalized','HorizontalAlignment','left','Position',[0.25 0.28 0.65 0.15]);

uicontrol(elementEditPanel,'Style','pushbutton','String','Add/Modify','Units','normalized',...
    'Position',[0.67 0.135 0.28 0.0825],'Callback',@modifyElementButton_Callback);

uicontrol(elementEditPanel,'Style','pushbutton','String','Remove Element','Units','normalized',...
    'Position',[0.67 0.05 0.28 0.0825],'Callback',@removeElementButton_Callback);
        
%% GUI, before the table

elementPopup = uicontrol(rightPanel,'Style','popupmenu','String',[{'Choose element...'},info.elements,{'Add or modify...'}],'Units','normalized',...
    'Position',[0.01 0.96 0.43 0.03],'CallBack',@elementPopup_Callback);

curveType = uicontrol(rightPanel,'Style','popupmenu','String',info.curveTypes,'Units','normalized',...
    'Position',[0.5 0.96 0.43 0.03],'CallBack',@curveType_Callback);

background = uicontrol(rightPanel,'Style','radiobutton','Enable','off','String','Subtract Background','Units','normalized',...
    'Position',[0.015 0.92 0.43 0.03],'CallBack',@background_Callback);

startFitting = uicontrol(rightPanel,'Style','radiobutton','Enable','off','String','Start Fitting','Units','normalized',...
    'Position',[0.5 0.92 0.43 0.03],'CallBack',@startFitting_Callback);

energyText = uicontrol(rightPanel,'Style','text','String','Beam Energy (keV)','Units','normalized',...
    'HorizontalAlignment','left','Position',[0.025 0.88 0.29 0.03]);

energyInput = uicontrol(rightPanel,'Style','edit','String','10.0','Units','normalized',...
    'HorizontalAlignment','left','Position',[0.3 0.885 0.15 0.028],'CallBack',@energyInput_Callback);

densityText = uicontrol(rightPanel,'Style','text','String','Density (g/mL)','Units','normalized',...
    'HorizontalAlignment','left','Position',[0.5 0.88 0.2 0.03]);

densityInput = uicontrol(rightPanel,'Style','edit','String','1.02','Units','normalized',...
    'HorizontalAlignment','left','Position',[0.72 0.885 0.21 0.028],'CallBack',@densityInput_Callback);

slitText = uicontrol(rightPanel,'Style','text','String','Slit Size (mm)','Units','normalized',...
    'HorizontalAlignment','left','Position',[0.5 0.845 0.2 0.03]);

slitInput = uicontrol(rightPanel,'Style','edit','String','0.02','Units','normalized',...
    'HorizontalAlignment','left','Position',[0.72 0.85 0.21 0.028],'CallBack',@slitInput_Callback);

lengthText = uicontrol(rightPanel,'Style','text','String','Detector Foot (mm)','Units','normalized',...
    'HorizontalAlignment','left','Position',[0.025 0.845 0.29 0.03]);

lengthInput = uicontrol(rightPanel,'Style','edit','String','10.76','Units','normalized',...
    'HorizontalAlignment','left','Position',[0.3 0.85 0.15 0.028],'CallBack',@lengthInput_Callback);

formulaText = uicontrol(rightPanel,'Style','text','String','Chemical Formula','Units','normalized',...
    'HorizontalAlignment','left','Position',[0.025 0.81 0.29 0.03]);

formulaInput = uicontrol(rightPanel,'Style','edit','String','H2OCa0.000018Cl0.000036','Units','normalized',...
    'HorizontalAlignment','left','Position',[0.3 0.815 0.625 0.028],'CallBack',@formulaInput_Callback);

%% GUI, table and below, before outpout and export
rowName = {'Qz Offset','Scale Factor','Bulk (mM)','Surf (1/nm^2)','Background'};
columnName = {'Min','Max','Start','Fix','Plot'};
columnFormat = {'numeric','numeric','numeric','logical','logical'};
columnWidth = {55 55 55 30 30};
tableData = {-0.001,0.001,0,false,false;1,1,1,true,false;1,1,1,true,false;0,0,0,true,false;0,0,0,true,false};

table = uitable(rightPanel,'Data', tableData,'ColumnName', columnName,...
            'ColumnFormat', columnFormat,'ColumnEditable', [true true true true true],'Units','normalized',...
            'ColumnWidth',columnWidth,'RowName',rowName,'RowStriping','off',...
            'Position',[0.025 0.64 0.935 0.17],'CellEditCallBack',@table_Callback);

loadPara = uicontrol(rightPanel,'Style','pushbutton','String','Load Para','Units','normalized',...
    'Position',[0.024 0.605 0.17 0.03],'CallBack',@loadPara_Callback);

savePara = uicontrol(rightPanel,'Style','pushbutton','String','Save Para','Units','normalized',...
    'Position',[0.19 0.605 0.17 0.03],'CallBack',@savePara_Callback);

stepInput = uicontrol(rightPanel,'Style','edit','String',20,'Units','normalized',...
    'HorizontalAlignment','left','Position',[0.62 0.605 0.1 0.03]);

stepText = uicontrol(rightPanel,'Style','text','String','Steps','Units','normalized',...
    'HorizontalAlignment','left','Position',[0.735 0.6 0.08 0.03]);

fitButton = uicontrol(rightPanel,'Style','pushbutton','String','Fit','Units','normalized',...
    'Position',[0.82 0.605 0.15 0.03],'CallBack',@fitButton_Callback);

withText = uicontrol(rightPanel,'Style','text','String','With','Units','normalized','HorizontalAlignment','left',...
    'Position',[0.025 0.570 0.07 0.03]);
confidenceInput = uicontrol(rightPanel,'Style','edit','String','95','Units','normalized',...
    'HorizontalAlignment','left','Position',[0.1 0.575 0.07 0.03],'CallBack',@confidenceInput_Callback);
confidenceText = uicontrol(rightPanel,'Style','text','String','% confidence window','Units','normalized','HorizontalAlignment','left',...
    'Position',[0.171 0.570 0.28 0.03]);
recordFitting = uicontrol(rightPanel,'Style','pushbutton','String','Record Fitting','Units','normalized',...
    'Position',[0.452 0.575 0.22 0.03],'CallBack',@recordFitting_Callback);

adjustPara = uicontrol(rightPanel,'Style','pushbutton','String','Adjust Para','Units','normalized',...
    'Position',[0.77 0.575 0.2 0.03],'CallBack',@adjustPara_Callback);

%% GUI, the output panel and save buttons

output = uicontrol(rightPanel,'Style','edit','Max',2,'HorizontalAlignment','left','Units','normalized',...
    'Position',[0.03 0.07 0.935 0.495]);

uicontrol(rightPanel,'Style','pushbutton','String','Clear','Units','normalized',...
    'Position',[0.82 0.038 0.15 0.03],'CallBack',@clearButton_Callback);

uicontrol(rightPanel,'Style','text','String','Save:','Units','normalized',...
    'HorizontalAlignment','left','Position',[0.025 0.035 0.08 0.025]);

uicontrol(rightPanel,'Style','pushbutton','String','Output Text','Units','normalized',...
    'Position',[0.024 0.007 0.2 0.03],'CallBack',@saveText_Callback);

uicontrol(rightPanel,'Style','pushbutton','String','Upper Figure','Units','normalized',...
    'Position',[0.234 0.007 0.2 0.03],'CallBack',@saveFig1_Callback);

uicontrol(rightPanel,'Style','pushbutton','String','Lower Figure','Units','normalized',...
    'Position',[0.444 0.007 0.2 0.03],'CallBack',@saveFig2_Callback);

uicontrol(rightPanel,'Style','pushbutton','String','Data Set','Units','normalized',...
    'Position',[0.654 0.007 0.15 0.03],'CallBack',@saveDataset_Callback);

uicontrol(rightPanel,'Style','pushbutton','String','Data & Fit','Units','normalized',...
    'Position',[0.814 0.007 0.17 0.03],'CallBack',@saveDataFit_Callback);

%% GUI, open

initializeXeRay;

%% callbacks, left panel

    function loadButton_Callback(source,eventdata)
        
        [fnames0,fnames1] = loadNewData; %returns old data file names as fname0, and new data file names as fnames1
        if ~isempty(fnames1)
            updateGUI('scanlist',[fnames0,fnames1]);
            
            for i = 1:length(x)
                info.dataLengths(i) = length(x{i}.q);
            end
            
            if isempty(fnames0)
                updateGUI('qz');
                updateGUI('gui','on');
                updateGUI('fitting','off');
                XeRayPlot;
            end
            
        end
        
    end

    function deleteButton_Callback(source,eventdata)
        
        if ~isempty(scanList.String)
            
            if isa(scanList.String,'char')
                n = true;
            else
                n = true(1,length(scanList.String));
            end
            m = scanList.Value;
            n(m) = false(1,length(m));
            x = x(n);
            
            if sum(n)
                updateGUI('keep',n);
                XeRayPlot;
            else
                updateGUI('delete');
                plot(ax1,1);
                plot(ax2,1);
            end
            
        end
    end

    function scanList_Callback(source,eventdata)
        
        updateGUI('qz');
        XeRayPlot;
        
    end

    function qzList_Callback(source,eventdata)
        
        if elementPopup.Value ~= 1 && elementPopup.Value ~= length(elementPopup.String) && length(scanList.Value) == 1
            getAllInputs;
            getCalculation;
        end
        
        XeRayPlot;
        
    end

%% callbacks, middle panel

    function showError_Callback(source,eventdata) %show error in plot
        
        info.plot.error = showError.Value;
        XeRayPlot(1);
        
    end

    function showCal_Callback(source,eventdata)
        
        info.plot.calculation = showCal.Value;
        XeRayPlot(2);
        
    end

    function showFit_Callback(source,eventdata)
        
        info.plot.fit = showFit.Value;
        XeRayPlot(2);
        
    end

%% callbacks, before the table and the table

    function elementPopup_Callback(source,eventdata) %fits the selected data range to the element
        
        n = elementPopup.Value;
        updateGUI('popup',n);
        
        switch n
            case 1
                startFitting.Enable = 'off';
                info.plot.element = 0;
                XeRayPlot;
            case length(elementPopup.String)
                info.plot.element = 0;
                elementEditPanel.Visible = 'on';
            otherwise
                info.plot.element = 1;
                startFitting.Enable = 'on';
                if ~strcmp(info.fittedElement,elementPopup.String{elementPopup.Value})
                    info.fittedElement = elementPopup.String{elementPopup.Value};
                    fitElement;
                end
                XeRayPlot;
        end
        
    end

    function curveType_Callback(source,eventdata) %fits the selected data range to the element
        
        fitElement;
        XeRayPlot;
        
    end

    function background_Callback(source,eventdata) %subtract the background of spectra
        
        info.plot.background = background.Value;
        XeRayPlot(1);
        
    end

    function startFitting_Callback(source,eventdata) %start fitting, change views and plotting options
        
        switch startFitting.Value
            case 0
                for i = 1:5
                    table.Data{i,5} = false;
                end
                
                info.plot.para = -ones(1,5);
                info.plot.fit = 0;
                
                switchFittingTo('off');
                showFit.Value = 0;
                loadButton.Enable = 'on';
                deleteButton.Enable = 'on';
                XeRayPlot;
            case 1
                switchFittingTo('on');
                loadButton.Enable = 'off';
                deleteButton.Enable = 'off';
                
                info.plot.calculation = showCal.Value;
                
                getAllInputs;
                getCalculation;
                XeRayPlot;
        end
        
    end

    function densityInput_Callback(source,eventdata)
        
        n = scanList.Value;
        oldDensity = x{n}.density;
        x{n}.density = getDensity;
        
        if oldDensity ~= x{n}.density
            replotForConstants;
        end
        
    end

    function formulaInput_Callback(source,eventdata)
        
        n = scanList.Value;
        oldFormula = x{n}.formula;
        x{n}.formula = getFormula;
        
        if ~strcmp(oldFormula,x{n}.formula)
            replotForConstants;
        end
        
    end

    function energyInput_Callback(source,eventdata)
        
        n = scanList.Value;
        oldEnergy = x{n}.E;
        x{n}.E = getEnergy;
        
        if oldEnergy ~= x{n}.E
            replotForConstants;
        end
        
    end

    function slitInput_Callback(source,eventdata)
        
        n = scanList.Value;
        oldSlit = x{n}.slit;
        x{n}.slit = getSlitSize;
        
        if oldSlit ~= x{n}.slit
            replotForConstants;
        end
        
    end

    function lengthInput_Callback(source,eventdata)
        
        n = scanList.Value;
        oldLength = x{n}.detectorLength;
        x{n}.detectorLength = getLength;
        
        if oldLength ~= x{n}.detectorLength
            replotForConstants;
        end
        
    end

    function table_Callback(source,eventdata) %respond to the plot column of the table
        
        y = x{scanList.Value};
        ind1 = eventdata.Indices(1);
        ind2 = eventdata.Indices(2);
        
        %dynamically change the table and plot
        switch ind2
            case 1
                if table.Data{ind1,1} > table.Data{ind1,2}
                    table.Data{ind1,2} = table.Data{ind1,1};
                    table.Data{ind1,3} = table.Data{ind1,1};
                    table.Data{ind1,4} = true;
                    replotForParameters;
                else
                    table.Data{ind1,4} = false;
                    if table.Data{ind1,1} > table.Data{ind1,3}
                        table.Data{ind1,3} = table.Data{ind1,1};
                        replotForParameters;
                    end
                end
                if table.Data{ind1,1} == table.Data{ind1,3} && table.Data{ind1,2} == table.Data{ind1,3}
                    table.Data{ind1,4} = true;
                else
                    table.Data{ind1,4} = false;
                end
            case 2
                if table.Data{ind1,1} > table.Data{ind1,2}
                    table.Data{ind1,1} = table.Data{ind1,2};
                    table.Data{ind1,3} = table.Data{ind1,2};
                    table.Data{ind1,4} = true;
                    replotForParameters;
                else
                    table.Data{ind1,4} = false;
                    if table.Data{ind1,2} < table.Data{ind1,3}
                        table.Data{ind1,3} = table.Data{ind1,2};
                        replotForParameters;
                    end
                end
                if table.Data{ind1,1} == table.Data{ind1,3} && table.Data{ind1,2} == table.Data{ind1,3}
                    table.Data{ind1,4} = true;
                else
                    table.Data{ind1,4} = false;
                end
            case 3
                if table.Data{ind1,3} > table.Data{ind1,2}
                    table.Data{ind1,2} = table.Data{ind1,3};
                end
                if table.Data{ind1,3} < table.Data{ind1,1}
                    table.Data{ind1,1} = table.Data{ind1,3};
                end
                if table.Data{ind1,1} == table.Data{ind1,3} && table.Data{ind1,2} == table.Data{ind1,3}
                    table.Data{ind1,4} = true;
                else
                    table.Data{ind1,4} = false;
                end
                replotForParameters;
            case 4
                if ~eventdata.EditData
                    if table.Data{ind1,1} == table.Data{ind1,3} && table.Data{ind1,2} == table.Data{ind1,3}
                        if ind1 == 1
                            if table.Data{ind1,3} == 0
                                table.Data{ind1,1} = -0.0001;
                                table.Data{ind1,2} = 0.0001;
                            else
                                table.Data{ind1,1} = -abs(table.Data{ind1,3});
                                table.Data{ind1,2} = abs(table.Data{ind1,3});
                            end
                        else
                            if table.Data{ind1,3} == 0
                                table.Data{ind1,1} = 0;
                                table.Data{ind1,2} = 1;
                            else
                                table.Data{ind1,1} = table.Data{ind1,3} - 0.2*abs(table.Data{ind1,3});
                                table.Data{ind1,2} = table.Data{ind1,3} + 0.2*abs(table.Data{ind1,3});
                            end
                        end
                    end
                else
                end
            case 5
                if ~isempty(y.fitted) && sum(y.fitted) > 0 && sum(info.plot.para) >= 0
                    
                    if y.fitted(ind1) < eventdata.EditData
                        table.Data{ind1,ind2} = 0;
                        beep;
                    else
                        info.plot.para(ind1) = eventdata.EditData;
                        if sum(info.plot.para) > 2
                            info.plot.para(ind1) = 0;
                            table.Data{ind1,ind2} = 0;
                            beep;
                        elseif sum(info.plot.para) >= 1
                            table.Data{ind1,ind2} = eventdata.EditData;
                            showError.Visible = 'off';
                            likelihoodChi2.Visible = 'on';
                            XeRayPlot(1);
                        else
                            showError.Visible = 'on';
                            likelihoodChi2.Visible = 'off';
                            XeRayPlot(1);
                        end
                    end

                else
                    table.Data{ind1,ind2} = 0;
                    beep;
                end
        end
        
    end

%% callbacks, after the table

    function fitButton_Callback(source,eventdata) %check the inputed parameters
        
        fitting = zeros(1,5);
        for i = 1:5
            if ~table.Data{i,4}
                fitting(i) = 1;
            end
        end
        
        if ~parameterTableDataGood
            h = warndlg('Cannot fit. Min, max, and start have to be numeric!');
            pause(5);
            try
                close(h);
            catch
            end
        elseif length(qzList.Value) > sum(fitting) && sum(fitting) > 0
            if doFluoFit
                n = scanList.Value;
                errorFit(x{n});
                recordFit2Output;

                if sum(info.plot.para) < 0
                    info.plot.para = zeros(1,5);
                else
                    for i = 1:5
                        if table.Data{i,4}
                            table.Data{i,5} = false;
                            info.plot.para(i) = 0;
                        else
                            if table.Data{i,5}
                                info.plot.para(i) = 1;
                            end
                        end
                    end
                end
                
                showFit.Enable = 'on';
                showFit.Value = 1;
                info.plot.fit = 1;
                XeRayPlot;
            end
        elseif sum(fitting) > 0
            h = warndlg('Cannot fit because # of data points < # of fitting parameters.');
            pause(5);
            try
                close(h);
            catch
            end
        else
            h = warndlg('Should not fix all parameters for fitting.');
            pause(5);
            try
                close(h);
            catch
            end
        end
        
        
    end

    function confidenceInput_Callback(source,eventdata)
        
        confidence = str2double(confidenceInput.String)/100;
        if confidence > 0 && confidence < 1
            if sum(info.plot.para) == 2
                try
                    if confidence ~= x{scanList.Value}.fluoFit.confidence
                        errorFit(x{scanList.Value},confidence);
                    end
                    XeRayPlot(1);
                catch
                end
            end
        end
        
    end

    function recordFitting_Callback(source,eventdata) %record the fitting results to the output box
        
        confidence = str2double(confidenceInput.String)/100;
        try
            if confidence ~= x{scanList.Value}.fluoFit.confidence
                errorFit(x{scanList.Value},confidence);
            end
            XeRayPlot(1);
        catch
        end
        recordFit2Output(confidence);
        
    end

    function savePara_Callback(source,eventdata) %save the fitting parameters
        
        tableData = cell(size(table.Data)+[1 1]);
        tableData{1,1} = '';
        tableData(1,2:end) = {'min','max','start','fix','plot'};
        tableData(2:end,1) = {'Qz-Offset','Scale-Factor','Bulk(mM)','Surf(1/nm^2)','Background'};
        tableData(2:end,2:end) = table.Data;
        
        y = x{scanList.Value};
        string1 = sprintf('%s%s',y.file(1:end-6),'.xfluopara');
        string2 = sprintf('%s %s %s','Save fitting parameters of',y.file,'as');
        [fileName,path] = uiputfile(string1,string2);
        
        if ~isnumeric(fileName)
            paraFile = fullfile(path,fileName);

            fid = fopen(paraFile,'w');

            fprintf(fid,'%17s %-8f\n','Beam-energy(keV)',str2double(energyInput.String));
            fprintf(fid,'%17s %-8f\n','Density(g/mL)',str2double(densityInput.String));
            fprintf(fid,'%17s %-8f\n','Detector-foot(mm)',str2double(lengthInput.String));
            fprintf(fid,'%17s %-8f\n','Slit-size(mm)',str2double(slitInput.String));
            fprintf(fid,'%17s %-s\n','Chemical-formula',formulaInput.String);
            fprintf(fid,'\n');

            formatSpec1 = '%-13s  %-9s %-9s %-9s %-4s %-4s\n';
            fprintf(fid,formatSpec1,tableData{1,:});

            formatSpec2 = '%12s  %- 8f %- 8f %- 8f %- 4d %- 4d\n';
            for i = 2:size(tableData)
                fprintf(fid,formatSpec2,tableData{i,:});
            end
            fclose(fid);
        end
        
    end

    function loadPara_Callback(source,eventdata) %center the starting points
        
        [file,path] = uigetfile('.xfluopara','Load the .xfluopara file');
        file = fullfile(path,file);
        fid = fopen(file);
        
        if fid > 0
            line = textscan(fgetl(fid),'%s %s');
            energyInput.String = line{2};

            line = textscan(fgetl(fid),'%s %s');
            densityInput.String = line{2};

            line = textscan(fgetl(fid),'%s %s');
            lengthInput.String = line{2};

            line = textscan(fgetl(fid),'%s %s');
            slitInput.String = line{2};

            line = textscan(fgetl(fid),'%s %s');
            formulaInput.String = line{2}{1};

            fgetl(fid);
            fgetl(fid);

            tableData = textscan(fid,'%s %f %f %f %f %f');
            fclose(fid);
            tableData = tableData(:,2:end);
            tableData = num2cell(cell2mat(tableData));
            for i = 1:5
                tableData{i,4} = logical(tableData{i,4});
                tableData{i,5} = false;
            end
            table.Data = tableData;

            getAllInputs;
            getCalculation;
            XeRayPlot;
        end
        
    end

    function adjustPara_Callback(source,eventdata)
        
        try
            n = scanList.Value;
            j = 1;
            for i = 1:size(table.Data)
                if x{n}.fitted(i)
                    table.Data{i,3} = x{n}.fluoFit.fitAll.value(j);
                    j = j+1;
                end
            end
            getTableInputs;
            getCalculation;
            XeRayPlot(2);
        catch EM
            h = errordlg(EM,'Winwdow closing in 8 s.');
            try
                close(h);
            catch
            end
        end
        
    end

    function likelihoodChi_Callback(source,eventdata)
        
        info.plot.likelihood = likelihoodChi2.Value;
        XeRayPlot(1);
        
    end

    function clearButton_Callback(source,eventdata) %clear the output
        
        output.String = {};
        
    end

    function saveDataset_Callback(source,eventdata) %save the current data to workspace
        
        fileName = 'XeRayDataSet';
        XeRayDataSet = x;
        save(fileName,'XeRayDataSet');
        clear XeRayDataSet;
        
    end

    function saveFig1_Callback(source,eventdata) %save figure one
        
        fileName = x{scanList.Value}.file;
        theFigure = figure;
        copyobj(ax1,theFigure);
        ax = gca;
        ax.Units = 'normalized';
        ax.Position = [.13 .11 .775 .815];
        hgsave(theFigure,fileName);
        
    end

    function saveFig2_Callback(source,eventdata) %save figure one
        
        fileName = x{scanList.Value}.file;
        theFigure = figure;
        copyobj(ax2,theFigure);
        ax = gca;
        ax.Units = 'normalized';
        ax.Position = [.13 .11 .775 .815];
        hgsave(theFigure,fileName);
        
    end

    function saveText_Callback(source,eventdata) %save text output
        
        y = x{scanList.Value};
        string1 = sprintf('%s%s',y.file(1:end-6),'.xerayoutput');
        string2 = sprintf('%s %s %s','Save output text',y.file,'as');
        [fileName,path] = uiputfile(string1,string2);
        file = fullfile(path,fileName);
        text = output.String;
        
        fid = fopen(file,'w');
        fprintf(fid,strcat(datestr(datetime),'\n'));
        for i = 1:length(text)
            fprintf(fid, strcat(text{i},'\n'));
        end
        fclose(fid);
        
    end

    function saveDataFit_Callback(source,eventdata)
        
        y = x{scanList.Value};
        string1 = sprintf('%s%s',y.file(1:end-6),'.xerayfitting');
        string2 = sprintf('%s %s %s','Save fluorescence data and fit of',y.file,'as');
        
        [fileName,path] = uiputfile(string1,string2);
        file = fullfile(path,fileName);
        
        fid = fopen(file,'w');
        data = num2str(y.fluoFit.data.qRange);
        fprintf(fid,'%12s %s\n','Data Qz',data);
        
        data = num2str(y.fluoFit.data.signal);
        fprintf(fid,'%12s %s\n','Data Signal',data);
        
        data = num2str(y.fluoFit.data.error);
        fprintf(fid,'%12s %s\n','Data Error',data);
        
        data = num2str(y.fluoFit.fitAll.fitQRange);
        fprintf(fid,'%12s %s\n','Fit Qz',data);
        
        data = num2str(y.fluoFit.fitAll.fitSignal);
        fprintf(fid,'%12s %s\n','Fit Signal',data);
        
        fclose(fid);
        
    end

%% callbacks, element list panel
    
    function elementListbox_Callback(source,eventdata)
        
        elementName = elementListbox.String{elementListbox.Value};
        elementTable.Data = getDataForElementTable(elementName);
        
        elementNameInput.String = elementName;
        
    end

    function modifyElementButton_Callback(source,eventdata)
        
        newOne = 1;
        elementName = elementNameInput.String;
        for i = 1:length(elementListbox.String)
            if strcmpi(elementName,elementListbox.String{i})
                newOne = 0;
                break;
            end
        end
        
        if elementTableDataGood
            if newOne == 0
                answer = questdlg('You are changing an existing element! Are you sure?');
                if strcmpi(answer,'yes')
                   [info.elements,info.elementsProperty] = dealElementEnergyFile('modify',elementName);
                end
            else
                [info.elements,info.elementsProperty] = dealElementEnergyFile('add',elementName);
            end
            elementListbox.String = info.elements;
            elementPopup.String = [{'Choose element...'},info.elements,{'Add or modify...'}];
            elementPopup.Value = 1;
            info.plot.element = 0;
        end
        
        
    end

    function removeElementButton_Callback(source,eventdata)
        
        info.plot.element = 0;
        
        n = elementListbox.Value;
        elementName = elementListbox.String{n};
        
        
        if n == length(elementListbox.String)
            n = 1;
        end
        
        [info.elements,info.elementsProperty] = dealElementEnergyFile('remove',elementName);
        
        elementPopup.Value = 1;
        elementPopup.String = [{'Choose element...'},info.elements,{'Add or modify...'}];
        
        if ~isempty(info.elements)
            elementListbox.Value = 1;
            elementListbox.String = info.elements;
            elementTable.Data = getDataForElementTable(elementListbox.String{n});
            elementNameInput.String = elementListbox.String{1};
        else
            elementListbox.Value = 0;
            elementListbox.String = {};
            elementTable.Data = cell(3,2);
        end
        
    end

    function closeElementTab_Callback(source,eventdata)
        
        elementEditPanel.Visible = 'off';
        elementPopup.Value = 1;
        XeRayPlot;
        
    end

%% functions, initialize

    function initializeXeRay %initialize specfile and mca files
        
        handles.Name = 'XeRay';
        movegui(handles,'center')
        handles.Visible = 'on';
        
        updateGUI('gui','off');
        
    end

    function initializeInfo %initialize parameters
        
        info.fittedElement = 'none';
        info.dataLengths = [];
        info.curveTypes = {'Gaussian','Lorentzian'};
        info.curveType = info.curveTypes{1};
        
        %initial plot control
        info.plot.element = 0;
        info.plot.para = -ones(1,5);
        info.plot.likelihood = 1;
        info.plot.error = 0;
        info.plot.background = 0;
        info.plot.calculation = 0;
        info.plot.fit = 0;
        
        info.legend1 = {};
        info.legend2 = {};
        info.symbolColor1 = {};
        info.symbolColor2 = {};
        
        % x is all the data
        x = {}; %all the data
        info.colors = 'kbrgcmy';
        info.symbols = 'o^vsd><ph+*x.';
        
        [info.elements, info.elementsProperty] = dealElementEnergyFile('read');
        
    end

%% functions, load data

    function [fnames0,fnames1] = loadNewData
        
        [fnames1,path] = uigetfile('*.xfluo','Select fluorescence data files','MultiSelect','on');
        
        if ~isa(fnames1,'numeric') %got files
            
            %convert to cell array
            if isa(fnames1,'char')
                fnames1 = {fnames1};
            end
            
            fnames0 = scanList.String;
            
            %remove files aleady loaded
            if ~isempty(fnames0)
                if isa(fnames0,'char') %if only one file before loading, convert to cell array
                    fnames0 = {fnames0};
                end
                
                sel = ones(size(fnames1));
                for i = 1:length(fnames1)
                    for j = 1:length(fnames0)
                        if strcmp(fnames0{j},fnames1{i})
                            sel(i) = 0;
                        end
                    end
                end
                sel = logical(sel);
                fnames1 = fnames1(sel);
            end
            
            %if new files found, load them
            n = length(fnames1);
            if n > 0
                
                %import data
                x1 = cell(1,n);
                for i = 1:n
                    x1{i} = XeRayData(fullfile(path,fnames1{i}));
                end
                x = [x,x1];
                
                if info.plot.element
                    n = length(x);
                    m = length(x1);
                    range = n-m+1:n;
                    fitElement(range);
                end
                
            end
            
        end
        
    end

%% functions, plot

    function XeRayPlot(n) %the master plot function for this XeRay GUI
        
        getLineSpecAndLegend;
        
        if nargin == 0
            upperPlot;
            lowerPlot;
        elseif n == 1
            upperPlot;
        elseif n == 2
            lowerPlot;
        end
        
    end

    function upperPlot %upper figure
        
        switch sum(info.plot.para)
            case {1,2}
                plotLikelihoodChi2(ax1,info.plot.para,info.plot.likelihood);
            otherwise
                plotSpectra(ax1,info.plot.element,info.plot.error,info.plot.background);
        end
        
        normalizeXLim;
        
    end

    function lowerPlot %lower figure
        
        switch info.plot.element
            case 1
                plotSignal(ax2,info.plot.calculation,info.plot.fit);
        end
        
        normalizeXLim;
        
    end

    function plotSpectra(ax,elementSpec,withError,background) %plot spectra
        
        [n,m,~,~] = getSelectionIndex;
        
        switch elementSpec
            case 0
                switch withError
                    case 0
                        for i = 1:length(qzList.Value)
                            plot(ax,x{n(i)}.e,x{n(i)}.intensity(:,m(i)),info.symbolColor1{i});
                            hold(ax,'on')
                        end
                    case 1
                        for i = 1:length(qzList.Value)
                            errorbar(ax,x{n(i)}.e,x{n(i)}.intensity(:,m(i)),x{n(i)}.intensityError(:,m(i)),info.symbolColor1{i});
                            hold(ax,'on')
                        end
                end
            case 1
                switch withError
                    case 0
                        switch background
                            case 0
                                for i = 1:length(qzList.Value)
                                    plot(ax,x{n(i)}.xe,x{n(i)}.xIntensity(:,m(i)),info.symbolColor1{i});
                                    hold(ax,'on')
                                end
                            case 1
                                for i = 1:length(qzList.Value)
                                    plot(ax,x{n(i)}.xe,x{n(i)}.netIntensity(:,m(i)),info.symbolColor1{i});
                                    hold(ax,'on')
                                end
                        end
                    case 1
                        switch background
                            case 0
                                for i = 1:length(qzList.Value)
                                    errorbar(ax,x{n(i)}.xe,x{n(i)}.xIntensity(:,m(i)),x{n(i)}.xIntensityError(:,m(i)),info.symbolColor1{i});
                                    hold(ax,'on')
                                end
                            case 1
                                for i = 1:length(qzList.Value)
                                    errorbar(ax,x{n(i)}.xe,x{n(i)}.netIntensity(:,m(i)),x{n(i)}.xIntensityError(:,m(i)),info.symbolColor1{i});
                                    hold(ax,'on')
                                end
                        end
                end
        end
        
        legend(ax,info.legend1);
        xlabel(ax, 'Energy (keV)');
        ylabel(ax, 'Signal');
        
        %plot fits and add title
        switch elementSpec
            case 0
                set(ax, 'xlim',[min(x{scanList.Value(1)}.e) max(x{scanList.Value(1)}.e)]);
                titleText = 'Whole Spectra';
            case 1
                titleText = sprintf('%s %s',info.fittedElement,'Spectra');
                switch background
                    case 0
                        for i = 1:length(qzList.Value)
                            plot(ax,x{n(i)}.fitE,x{n(i)}.intensityFit(:,m(i)),info.symbolColor1{i}(2));
                        end
                    case 1
                        for i = 1:length(qzList.Value)
                            plot(ax,x{n(i)}.fitE,x{n(i)}.netIntensityFit(:,m(i)),info.symbolColor1{i}(2));
                        end
                end
        end
        title(ax,titleText);
        
        hold(ax,'off');

    end

    function plotSignal(ax,withCalculation,withFit) %plot the integrated signal for a given element
        
        [n,m,~,~] = getSelectionIndex;
        [n,m] = getVectors(n,m);
        
        sel = true(size(n));
        
        for i = 1:length(n)
            if isempty(m{i})
                sel(i) = false;
            end
            errorbar(ax,x{n(i)}.q(m{i}),x{n(i)}.signal(m{i}),x{n(i)}.signalError(m{i}),info.symbolColor2{i},'markersize',8,'linewidth',2);
            hold(ax,'on');
        end
        
        theLegend = info.legend2(sel);
        
        if withCalculation
            n = scanList.Value(1);
            if isempty(x{n}.calculation)
                getAllInputs;
                getCalculation;
            end
            plot(ax,x{n}.calRange,x{n}.calculation,'g-','linewidth',2);
            hold(ax,'on');
            theLegend = [theLegend,{'Calculation'}];
        end
        
        if withFit
            n = scanList.Value(1);
            plot(ax,x{n}.fluoFit.fitAll.fitQRange,x{n}.fluoFit.fitAll.fitSignal,'r-','linewidth',2);
            hold(ax,'on');
            theLegend = [theLegend,{'Fit'}];
        end
        
        xlabel(ax,'Qz');
        ylabel(ax,'Fluorescence Intensity (a.u.)');
        titleText = sprintf('%s %s',info.fittedElement,'Fluorescence');
        title(ax,titleText);
        legend(ax,theLegend);
        hold(ax,'off');
        
    end

    function plotLikelihoodChi2(ax,plotPara,plotLikelihood) %plot the likelihood from fitting the signal
        
        n = scanList.Value(1);
        y = x{n};
        m = find(plotPara);
        
        switch length(m)
            case 1
                m = sum(y.fitted(1:m));
                fit1 = y.fluoFit.fit1;
                switch plotLikelihood
                    case 0
                        xdata1 = fit1.paraRange(:,m);
                        ydata1 = fit1.chi2(:,m);

                        plot(ax,xdata1,ydata1,'o','markersize',8,'linewidth',2);
                        xlabel(ax,y.fluoFit.parameters{m});
                        ylabel(ax,'Raw \chi^2');
                        title(ax,sprintf('%s %s','\chi^2 of',y.fluoFit.parameters{m}));
                        legend(ax,'\chi^2');
                    case 1
                        xdata1 = fit1.paraRange(:,m);
                        ydata1 = fit1.likelihood(:,m);                    
                        xdata2 = fit1.lkFitRange(:,m);
                        ydata2 = fit1.lkFit(:,m);

                        plot(ax,xdata1,ydata1,'o','markersize',8,'linewidth',2);
                        hold(ax,'on');
                        plot(ax,xdata2,ydata2,'r','linewidth',2);
                        hold(ax,'off');
                        xlabel(ax,y.fluoFit.parameters{m});
                        ylabel(ax,'Normalized Likelihood');
                        title(ax,sprintf('%s %s','Likelihood Distribution of',y.fluoFit.parameters{m}));
                        legend(ax,'Likelihood','Gaussian Fit');
                end
            case 2
                m(1) = sum(y.fitted(1:m(1)));
                m(2) = sum(y.fitted(1:m(2)));
                fit2 = y.fluoFit.fit2{m(1),m(2)};
                switch plotLikelihood
                    case 0
                        xdata =fit2.paraRange1;
                        ydata = fit2.paraRange2;
                        chi2 = fit2.chi2;
                        contourf(ax,xdata,ydata,chi2);
                        colorbar(ax);
                        xlabel(ax,y.fluoFit.parameters{m(1)});
                        ylabel(ax,y.fluoFit.parameters{m(2)});
                        legend(ax,'Joint \chi^2');
                        title(ax,sprintf('%s %s %s %s','Joint \chi^2 of',y.fluoFit.parameters{m(1)},'and',y.fluoFit.parameters{m(2)}));
                    case 1
                        xdata =fit2.paraRange1;
                        ydata = fit2.paraRange2;
                        
                        C = fit2.contour;
                        
                        
                        lk = fit2.lk;
                        contourf(ax,xdata,ydata,lk);
                        colorbar(ax);
                        hold(ax,'on');
                        plot(ax,C(1,:),C(2,:),'r','linewidth',2);
                        hold(ax,'off');
                        xlabel(ax,y.fluoFit.parameters{m(1)});
                        ylabel(ax,y.fluoFit.parameters{m(2)});
                        legend(ax,'Joint Likelihood',sprintf('%.2f %s',y.fluoFit.confidence,'Confidence Window'));
                        title(ax,sprintf('%s %s %s %s','Joint Likelihood of',y.fluoFit.parameters{m(1)},'and',y.fluoFit.parameters{m(2)}));
                end
        end        
        
    end

    function replotForConstants
        
        getConstantInputs;
        
        n = scanList.Value;
        x{n}.xresult = refracOf(x{n}.formula,x{n}.E,x{n}.density);
        x{n}.xresult1 = refracOf(x{n}.formula,x{n}.peaks(x{n}.pickedPeak),x{n}.density);
        
        getCalculation;

        for i = 1:5
            table.Data{i,5} = false;
        end
        info.plot.para = -ones(1,5);
        info.plot.fit = 0;
        
        showFit.Value = 0;
        showFit.Enable = 'off';
        
        XeRayPlot;
        
    end

    function replotForParameters
        
        getTableInputs;
        getCalculation;
        
        XeRayPlot(2);
        
    end

%% functinons, handling inputs from GUI

    function energy = getEnergy
        
        energy = str2double(energyInput.String);
        if energy < 0.03 || energy > 30
            energy = 0;
            h = errordlg('Energy cannot be smaller than 0.03 keV, or bigger than 30 keV.');
            pause(5);
            try
                close(h);
            catch
            end
        end
        
    end

    function density = getDensity
        
        density = str2double(densityInput.String);
        if density < 0
            density = 0;
            h = errordlg('Density cannot be zero or negative.');
            pause(5);
            try
                close(h);
            catch
            end
        end
        
    end

    function detectorLength = getLength
        
        detectorLength = str2double(lengthInput.String);
        if detectorLength < 0
            detectorLength = 0;
            h = errordlg('Detector length must be positive.');
            pause(5);
            try
                close(h);
            catch
            end
        end
        
    end

    function slitSize = getSlitSize
        
        slitSize = str2double(slitInput.String);
        if slitSize < 0
            slitSize = 0;
            h = errordlg('Slit size must be positive.');
            pause(5);
            try
                close(h);
            catch
            end
        end
        
    end

    function formula = getFormula
        
        formula = formulaInput.String;
        try
            parseFormula(formula);
        catch
            formula = 0;
            h = errordlg('Cannot parse formula.');
            pause(5);
            try
                close(h);
            catch
            end
        end
        
    end

    function getTableInputs
        
        starts = cell2mat(table.Data(:,1:3));
        for i = 1:size(starts)
            if table.Data{i,3} < table.Data{i,1}
                table.Data{i,1} = table.Data{i,3};
            end
            if table.Data{i,3} > table.Data{i,2}
                table.Data{i,2} = table.Data{i,3};
            end
            if table.Data{i,2} == table.Data{i,3} && table.Data{i,1} == table.Data{i,3}
                table.Data{i,4} = true;
            end
            if table.Data{i,4}
                starts(i,1) = starts(i,3);
                starts(i,2) = starts(i,3);
            end
        end
        
        lb = starts(:,1)';
        ub = starts(:,2)';
        P = starts(:,3)';
        
        n = scanList.Value;
        x{n}.fluoFit.start = P;
        x{n}.fluoFit.lowerBounds = lb;
        x{n}.fluoFit.upperBounds = ub;
        
        for i = 1:5
            info.plot.plotPara = table.Data{i,5};
        end
        
        
    end

    function getConstantInputs
        
        n = scanList.Value;
        x{n}.formula = getFormula;
        x{n}.E = getEnergy;
        x{n}.density = getDensity;
        x{n}.detectorLength = getLength;
        x{n}.slit = getSlitSize;
        x{n}.xresult = refracOf(x{n}.formula,x{n}.E,x{n}.density);
        
    end

    function getAllInputs
        
        getTableInputs;
        getConstantInputs;
        
    end

%% functions, element table

    function flag = elementTableDataGood
        
        flag = 0;
        
        if isnan(elementTable.Data{1,1}) || isnan(elementTable.Data{1,2}) || isnan(elementTable.Data{2,1})
                errordlg('Two energy bounds and at least one peak should be present.');
        else
            if elementTable.Data{1,1} >= elementTable.Data{1,2}
                errordlg('The energy range must increase from 1 to 2.');
            elseif elementTable.Data{1,1} < 0.03 || elementTable.Data{1,2} < 0.03 || elementTable.Data{1,1} > 30 || elementTable.Data{1,2} > 30
                errordlg('Energy range must be within 0.03 keV to 30 keV.');
            elseif elementTable.Data{2,1} < elementTable.Data{1,1} || elementTable.Data{1,1} > elementTable.Data{1,2}
                errordlg('Peaks must be within bounds.');
            elseif ~isnan(elementTable.Data{2,2}) && (elementTable.Data{2,1} < elementTable.Data{1,1} || elementTable.Data{1,1} > elementTable.Data{1,2})
                errordlg('Peaks must be within bounds.');
            else
                flag = 1;
            end
        end
        
    end

    function [line1,line2,line3] = elementTableDataAsString(data)
        
        line1 = sprintf('%s %f %f','energyBound',data{1,1},data{1,2});
        
        if isnan(data{2,2})
            line2 = sprintf('%s %f','peak',data{2,1});
        else
            line2 = sprintf('%s %f %f','peak',data{2,1},data{2,2});
        end
        
        if ~isnan(data{3,1})
            if ~isnan(data{3,2})
                line3 = sprintf('%s %f %f','peakHalfWidth',data{3,1},data{3,2});
            else
                line3 = sprintf('%s %f','peakHalfWidth',data{3,1});
            end
        else
            line3 = 'peakHalfWidth';
        end
        
    end

    function data = getDataForElementTable(elementName)
        
        for i = 1:length(info.elements)
            if strcmp(elementName,info.elements{i})
                break;
            end
        end
        
        data = cell(3,2);
        property = info.elementsProperty{i};
        data{1,1} = property.range(1);
        data{1,2} = property.range(2);
        data{2,1} = property.peak(1);
        
        if length(property.peak) > 1
            data{2,2} = property.peak(2);
        else
            data{2,2} = NaN;
        end
        if ~isempty(property.width)
            data{3,1} = property.width(1);
            if length(property.width) > 1
                data{3,2} = property.width(2);
            else
                data{3,2} = NaN;
            end
        else
            data{3,1} = NaN;
            data{3,2} = NaN;
        end
        
    end

%% functions, elementEnergy.txt file

    function flag = parameterTableDataGood
        
        flag = 1;
        data = table.Data;
        for i = 1:5
            for j = 1:3
                if isnan(data{i,j})
                    flag = 0;
                    break;
                end
            end
        end
        
    end

    function [elements,elementsProperty] = dealElementEnergyFile(action,element) %read the elements
        
        fid = fopen(which('elementEnergy.txt'));
        if fid > 0
            fclose(fid);
            switch(action)
                case 'read'
                    [elements,elementsProperty] = readElementEnergyFile;
                case {'add','modify','remove'}
                    updateElementEnergyFile(action,element);
                    [elements,elementsProperty] = readElementEnergyFile;
            end
        else
            errordlg('Cannot find elementEnergy.txt.');
        end
        
    end

    function updateElementEnergyFile(action,element)
        
        switch action
            case 'add'
                newtext = cell(4,1);
                newtext{1} = ['#',element];
                newtext{2} = sprintf('%s %f %f','energyBound',elementTable.Data{1,1},elementTable.Data{1,2});
                newtext{3} = sprintf('%s %f %f','peak',elementTable.Data{2,1},elementTable.Data{2,2});
                newtext{4} = sprintf('%s %f %f','peakHalfWidth',elementTable.Data{3,1},elementTable.Data{3,2});
                
                fid = fopen(which('elementEnergy.txt'),'a');
                fprintf(fid,'\n');
                for i = 1:4
                    fprintf(fid,'%s\n',newtext{i});
                end
                fclose(fid);
            case {'modify','remove'}
                text = textread(which('elementEnergy.txt'),'%s','delimiter','\n');
                for i = 1:length(text)
                    if ~isempty(text{i}) && strcmpi(text{i}(1),'#') && strcmpi(text{i}(2:end),element)
                        break;
                    end
                end
                switch action
                    case 'modify'
                        [line1,line2,line3] = elementTableDataAsString(elementTable.data);
                        text{i+1} = line1;
                        text{i+2} = line2;
                        text{i+3} = line3;
                    case 'remove'
                        text = [text(1:i-1); text(i+5:end)];
                end
                
                fid = fopen(which('elementEnergy.txt'),'w');
                for i = 1:length(text)
                    fprintf(fid,'%s\n',text{i});
                end
                fclose(fid);
        end
        
        
    end

    function [elements,elementsProperty] = readElementEnergyFile
        
        text = textread(which('elementEnergy.txt'),'%s','delimiter','\n');
        string = catStringCellArray(text);
        n = sum(string=='#');
        elements = cell(1,n);
        elementsProperty = cell(1,n);

        j = 1;
        i = 1;
        while i < length(text)
            if ~isempty(text{i}) && strcmp(text{i}(1),'#')
                elements{j} = text{i}(2:end);
                bounds = textscan(text{i+1},'%s %f %f');
                elementsProperty{j}.range = [bounds{2},bounds{3}];
                elementsProperty{j}.peak = str2num(text{i+2}(6:end));
                elementsProperty{j}.width = str2num(text{i+3}(15:end));
                j = j+1;
                i = i+3;
            end
            i = i+1;
        end
        
    end

%% functions, GUI elements control

    function updateGUI(feature,parameter)
        
        switch feature
            case 'gui'
                switchGuiTo(parameter);
            case 'scanlist'
                scanList.String = parameter;
            case 'qz'
                displayQz;
            case 'keep'
                n = parameter;
                scanList.String = scanList.String(n);
                scanList.Value = 1;
                qzList.Value = 1;
                displayQz;
            case 'delete'
                scanList.Value = 1;
                scanList.String = {};
                qzList.String = {};
                switchGuiTo('off');
            case 'fitting'
                switchFittingTo(parameter);
        end
        
    end

    function displayQz %displays Qz in the qz list
        
        %collect the length of qz vectors
        n = zeros(size(scanList.Value));
        for i = 1:length(scanList.Value)
            n(i) = length(x{scanList.Value(i)}.q);
        end
        
        qString = cell(1,sum(n));
        k = 0;
        for i = 1:length(n)
            for j = 1:n(i)
                k = k+1;
                qString{k} = sprintf('%s %s %f',scanList.String{scanList.Value(i)}(1:end-6),'Qz: ',x{scanList.Value(i)}.q(j));
            end
        end
        if max(qzList.Value) > length(qString)
            qzList.Value = 1;
        end
        qzList.String = qString;
        
    end

    function switchFittingTo(status) %switch on fitting
        
        energyText.Enable = status;
        energyInput.Enable = status;
        lengthText.Enable = status;
        lengthInput.Enable = status;
        slitText.Enable = status;
        slitInput.Enable = status;
        densityText.Enable = status;
        densityInput.Enable = status;
        formulaText.Enable = status;
        formulaInput.Enable = status;
        table.Enable = status;
        savePara.Enable = status;
        loadPara.Enable = status;
        stepInput.Enable = status;
        stepText.Enable = status;
        fitButton.Enable = status;
        withText.Enable = status;
        confidenceInput.Enable = status;
        confidenceText.Enable = status;
        recordFitting.Enable = status;
        showCal.Enable = status;
        adjustPara.Enable = status;
        
        switch lower(status)
            case 'on'
                scanList.Value = scanList.Value(1);
                displayQz;
                scanList.Enable = 'off';
                elementPopup.Enable = 'off';
                curveType.Enable = 'off';
            case 'off'
                scanList.Enable = 'on';
                elementPopup.Enable = 'on';
                curveType.Enable = 'on';
                showFit.Enable = 'off';
        end
        
    end

    function normalizeXLim %function to ensure the two x-axis conform to each other
        
        if strcmpi(ax1.XLabel.String,ax2.XLabel.String)
            newxlim = [min(ax1.XLim(1),ax2.XLim(1)),max(ax1.XLim(2),ax2.XLim(2))];
            set(ax1,'xlim',newxlim);
            set(ax2,'xlim',newxlim);            
        end
        
    end

    function switchGuiTo(status) %gray out the GUI or not
       
        set(findall(rightPanel,'-property','Enable'),'Enable',status);
        set(findall(listPanel,'-property','Enable'),'Enable',status);
        showError.Enable = status;
        showCal.Enable = status;
        showFit.Enable = status;
        likelihoodChi2.Enable = status;
        
        loadButton.Enable = 'on';
        scanText.Enable = 'on';
        
        if elementPopup.Value == 1
            startFitting.Enable = 'off';
        else
            startFitting.Enable = 'on';
        end
        
    end

    function recordFit2Output(confidence)
        
        if nargin == 0
            confidence = 0;
        end
        
        oldtext = output.String;
        
        n = scanList.Value;
        fits = x{n}.fluoFit;
        try
            m = fits.numberOfPara;
        catch
            m = -3;
        end
        text = cell(7+m,1);
        
        text{1} = '--------------------------------------------------------------------';
        text{2} = sprintf('%s %s','#Time stamp:',datestr(datetime));
        text{3} = sprintf('%s%s%s','#Fitted parameters: (',stringArrayCatwithComma('',fits.parameters),')');
        text{4} = '';
        
        if m
            text{5} = '#Fitting report';
            text{6} = sprintf('%s %f','#Best chi^2:',fits.fitAll.chi2);
            if confidence
                text{7} = sprintf('%8s%15s%20s%10s%5.3f%s','','TRR','Brute Force','Error(',confidence,')');
                multiplier = norminv((1-confidence)/2+confidence,0,1);
            else
                text{7} = sprintf('%8s%15s%20s%15s','','TRR','Brute Force','Adjusted Std');
                multiplier = 1;
            end
            for i = 8:7+m
                text{i} = sprintf('%-13s%10f %10f %10f',fits.parameters{i-7},fits.fitAll.value(i-7),fits.fit1.value(i-7),multiplier*fits.fit1.adjustedStd(i-7));
            end
        end

        if ~isempty(oldtext)
            text = [text;oldtext];
        end

        output.String = text;
    end

%% functions, utility

    function getLineSpecAndLegend %obtain line spec and legends for both plots
        
        %obtain line spec for plotting, and legends
        info.symbolColor1 = cell(size(qzList.Value));
        info.legend1 = info.symbolColor1;
        
        [~,~,rankn,rankm] = getSelectionIndex;
        rankn = mod(rankn,length(info.symbols));
        rankn(rankn==0) = length(info.symbols);
        rankm = mod(rankm,length(info.colors));
        rankm(rankm==0) = length(info.colors);
        for i = 1:length(qzList.Value);
            info.symbolColor1{i} = strcat(info.symbols(rankn(i)),info.colors(rankm(i)));
            info.legend1{i} = qzList.String{qzList.Value(i)};
        end
        
        uniqueN = unique(rankn,'stable');
        info.symbolColor2 = cell(size(uniqueN));
        info.legend2 = info.symbolColor2;
        for i = 1:length(uniqueN)
            info.symbolColor2{i} = info.symbols(uniqueN(i));
            info.legend2{i} = scanList.String{scanList.Value(uniqueN(i))};
        end       
        
    end

    function [n,m,rankn,rankm] = getSelectionIndex %4 indices for each selected spectrum
        %n is the position within the x{} data set, m is the position for
        %the q, rankn is the position of n within selected n, and rankm is
        %the position of m within selected m for that specific n
        
        n = zeros(size(qzList.Value));
        m = n;
        rankn = n;
        rankm = n;
        
        cn = cumsum(info.dataLengths(scanList.Value));
        for i = 1:length(qzList.Value)
            rankn(i) = find(cn>=qzList.Value(i),1);
            n(i) = scanList.Value(rankn(i));
            if rankn(i) > 1
                m(i) = qzList.Value(i) - cn(rankn(i)-1);
            else
                m(i) = qzList.Value(i);
            end
            if i == 1 || rankn(i) > rankn(i-1)
                rankm(i) = 1;
            else
                rankm(i) = rankm(i-1)+1;
            end
        end
        
    end

    function [nv,mv] = getVectors(n,m) %the indices

        n1 = n;
        n1(2:end) = n1(2:end)-n1(1:end-1);
        ind = find(n1~=0);

        nv = zeros(size(ind));
        mv = cell(size(ind));

        for i = 1:length(ind)-1
            nv(i) = n(ind(i));
            mv{i} = m(ind(i):ind(i+1)-1);
        end
        nv(end) = n(ind(end));
        mv{end} = m(ind(end):end);

    end

    function fitElement(n) %fit the chosen element
    
        if nargin == 0
            n = 1:length(x);
        end
        
        for i = n
            xFit(x{i},info.fittedElement,curveType.String{curveType.Value});
        end
        
    end

    function getCalculation
        
        n = scanList.Value;
        x{n}.xresult = refracOf(x{n}.formula,x{n}.E,x{n}.density);
        x{n}.xresult1 = refracOf(x{n}.formula,x{n}.peaks(x{n}.pickedPeak),x{n}.density);
        N = 100;
        x{n}.calRange = linspace(min(x{n}.q(qzList.Value)),max(x{n}.q(qzList.Value)),N);
        x{n}.calculation = totalFluoIntensity(x{n},x{n}.calRange,x{n}.fluoFit.start);
        
    end

    function flag = doFluoFit %fit data, return 1 if success, 0 if not
        
        flag = 0;
        
        N = str2double(stepInput.String);
        
        if N < 5
            N = 5;
            stepInput.String = '5';
            h = warndlg('At least 5 steps for the parameters being fitted. Corrected.');
            try
                close(h);
            catch
            end
        end
        
        n = scanList.Value;
        try
            getAllInputs;
            x{n}.xresult = refracOf(x{n}.formula,x{n}.E,x{n}.density);
            x{n}.xresult1 = refracOf(x{n}.formula,x{n}.peaks(x{n}.pickedPeak),x{n}.density);
            h = msgbox({'Fitting in process...','Do not close this window.'});
            runFluoFit(x{n},x{n}.fluoFit.start,x{n}.fluoFit.lowerBounds,x{n}.fluoFit.upperBounds,N,qzList.Value);
            
            flag =1;
            
            try
                close(h);
            catch
            end
        catch EM
            try
                close(h);
            catch
            end
            h = errordlg(EM,'Window closing in 5 s.');
            try
                close(h);
            catch
            end
        end
        
    end

end
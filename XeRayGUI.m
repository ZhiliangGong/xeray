classdef XeRayGUI < handle
    
    properties
        
        data
        gui
        control
        
        handles
        
        config
        ElementProfiles
        
    end
    
    methods
        
        % create the GUI
        
        function this = XeRayGUI(filenames)
            
            this.processGuiConfig();
            this.ElementProfiles = loadjson(fullfile(getParentDir(which('XeRay.m')), 'support-files/element-profiles.json'));

            set(0, 'units', this.config.units);
            pix = get(0, 'screensize');
            if pix(4) * 0.85 <= this.config.window(4)
                this.config.window(4) = pix(4)*0.85;
            end
            
            this.handles = figure('Visible','on','Name','XeRay','NumberTitle','off','Units','pixels',...
                'Position', this.config.window, 'Resize', 'on');
            
            this.control = XeRayControl();
            this.createGUIElements();
            this.dynamicOnOffControl();
            
            if nargin == 1
                this.loadCellArrayDataFiles(filenames);
            end
            
        end
        
        function createGUIElements(this)
            
            handle0 = this.handles;
            
            createListPanel(this);
            createAxes(this);
            createRightPanel(this);
            createElementEditPanel(this);
            createDataControl(this);
            createBasicInfoTalbe(this);
            createParametersTable(this);
            createLayersTable(this);
            createFittingControls(this);
            createOutputandSaveButtons(this);
            
            function createListPanel(this)
            
                listPanel = uipanel(handle0,'Title','X-ray Fluorescence Data','Units','normalized',...
                    'Position',[0.014 0.02 0.16 0.97]);
                
                this.gui.scanText = uicontrol(listPanel,'Style','text','String','Select data sets to begin','Units','normalized',...
                    'Position',[0.05 0.965 0.8 0.03]);
                
                this.gui.fileList = uicontrol(listPanel,'Style','listbox','Units','normalized',...
                    'Position',[0.05 0.56 0.9 0.405],'Max',2,'CallBack',@this.fileList_Callback);
                
                this.gui.loadButton = uicontrol(listPanel,'Style','pushbutton','String','Load','Units','normalized',...
                    'Position',[0.035 0.52 0.3 0.032],'Callback',@this.loadButton_Callback);
                
                this.gui.deleteButton = uicontrol(listPanel,'Style','pushbutton','String','Delete','Units','normalized',...
                    'Position',[0.38 0.52 0.3 0.032],'Callback',@this.deleteButton_Callback);
                
                uicontrol(listPanel,'Style','text','String','Select angle range','Units','normalized',...
                    'Position',[0.05 0.49 0.8 0.03]);
                
                this.gui.angleList = uicontrol(listPanel,'Style','listbox','Units','normalized',...
                    'Position',[0.05 0.015 0.9 0.48],'Max',2,'CallBack',@this.angleList_Callback);
                
            end
            
            function createAxes(this)
                
                this.gui.showError = uicontrol(handle0,'Style','checkbox','String','Show Error','Units','normalized','Visible','on',...
                    'Position',[0.6 0.965 0.1 0.018],'CallBack',@this.showError_Callback);
                
                this.gui.likelihoodChi2 = uicontrol(handle0,'Style','popupmenu','String',{'Likelihood','Chi^2'},'Visible','off',...
                    'Units','normalized',...
                    'Position',[0.572 0.97 0.1 0.018],'CallBack',@this.likelihoodChi_Callback);
                
                this.gui.showCal = uicontrol(handle0,'Style','checkbox','String','Show Calc.','Units','normalized',...
                    'Position',[0.6 0.437 0.08 0.018],'CallBack',@this.showCal_Callback);
                
                this.gui.showFit = uicontrol(handle0,'Style','checkbox','String','Show Fit','Units','normalized',...
                    'Position',[0.54 0.437 0.06 0.018],'CallBack',@this.showFit_Callback);
                
                ax1 = axes('Parent',handle0,'Units','normalized','Position',[0.215 0.52 0.45 0.44]);
                ax1.XLim = [0 10];
                ax1.YLim = [0 10];
                ax1.XTick = [0 2 4 6 8 10];
                ax1.YTick = [0 2 4 6 8 10];
                ax1.XLabel.String = 'x1';
                ax1.YLabel.String = 'y1';
                
                this.gui.ax1 = ax1;
                
                % plot region 2
                ax2 = axes('Parent',handle0,'Units','normalized','Position',[0.215 0.08 0.45 0.35]);
                ax2.XLim = [0 10];
                ax2.YLim = [0 10];
                ax2.XTick = [0 2 4 6 8 10];
                ax2.YTick = [0 2 4 6 8 10];
                ax2.XLabel.String = 'x2';
                ax2.YLabel.String = 'y2';
                
                this.gui.ax2 = ax2;
                
            end
            
            function createRightPanel(this)
                
                this.gui.rightPanel = uipanel(handle0,'Units','normalized','Position',[0.68 0.02 0.31 0.97]);
                
                this.gui.elementEditPanel = uipanel(handle0,'Title','Element Management','Visible','off','Units','normalized',...
                    'Position',[0.685 0.57 0.3 0.375]);
            end
            
            function createElementEditPanel(this)
                
                elementEditPanel = this.gui.elementEditPanel;
                elementNames = fieldnames(this.ElementProfiles);
                
                uicontrol(elementEditPanel,'Style','text','String','Existing Elements','Units','normalized',...
                    'HorizontalAlignment','left','Position',[0.02 0.9 0.3 0.0825]);
                
                uicontrol(elementEditPanel,'Style','pushbutton','String','Close','Units','normalized',...
                    'Position',[0.8 0.9 0.15 0.0825],'Callback',@this.closeElementTab_Callback);
                
                this.gui.elementListbox = uicontrol(elementEditPanel,'Style','listbox','String', elementNames, 'Units','normalized',...
                    'Position',[0.02 0.04 0.2 0.88],'Max',1,'CallBack',@this.elementListbox_Callback);
                
                uicontrol(elementEditPanel,'Style','text','String','Element Name:','Units','normalized',...
                    'HorizontalAlignment','left','Position',[0.25 0.86 0.25 0.05]);
                
                this.gui.elementNameInput = uicontrol(elementEditPanel,'Style','edit','String',elementNames{1},'Units','normalized',...
                    'HorizontalAlignment','left','Position',[0.45 0.84 0.25 0.08]);
                
                columnName = {'1','2'};
                columnFormat = {'numeric','numeric'};
                columnWidth = {60,60};
                rowName = {'Range (keV)','Peaks (keV)','FWHM (keV)'};
                elementTableData = this.getDataForElementTable(elementNames{1});
                
                this.gui.elementTable = uitable(elementEditPanel,'ColumnName', columnName,'Data',elementTableData,...
                    'ColumnFormat', columnFormat,'ColumnEditable', [true true],'Units','normalized',...
                    'ColumnWidth',columnWidth,'RowName',rowName,'RowStriping','off',...
                    'Position',[0.25 0.45 0.7 0.36]);
                
                uicontrol(elementEditPanel,'Style','text','String','Note: (1) FWHM is optinal, (2) enter both the lower and upper bounds, (3) enter 1 or 2 peaks.',...
                    'Units','normalized','HorizontalAlignment','left','Position',[0.25 0.28 0.65 0.15]);
                
                uicontrol(elementEditPanel,'Style','pushbutton','String','Add/Modify','Units','normalized',...
                    'Position',[0.67 0.135 0.28 0.0825],'Callback',@this.modifyElementButton_Callback);
                
                uicontrol(elementEditPanel,'Style','pushbutton','String','Remove Element','Units','normalized',...
                    'Position',[0.67 0.05 0.28 0.0825],'Callback',@this.removeElementButton_Callback);
                
            end
            
            function createDataControl(this)
                
                elementNames = fieldnames(this.ElementProfiles);
                rightPanel = this.gui.rightPanel;
                
                this.gui.elementPopup = uicontrol(rightPanel,'Style','popupmenu','String',[{'Choose element...'}, elementNames', {'Add or modify...'}],'Units','normalized',...
                    'Position',[0.01 0.96 0.43 0.03], 'TooltipString', 'Choose or add new element.', ...
                    'CallBack', @this.element_Callback);
                
                this.gui.lineShape = uicontrol(rightPanel,'Style','popupmenu','String',this.control.lineShapes,'Units','normalized',...
                    'Position',[0.5 0.96 0.43 0.03], 'TooltipString', 'Lineshape to fit peaks.', ...
                    'CallBack',@this.lineShape_Callback);
                
                this.gui.removeBackground = uicontrol(rightPanel,'Style','radiobutton','String','Subtract Background','Units','normalized',...
                    'Position',[0.015 0.925 0.43 0.03],'CallBack',@this.removeBackground_Callback);
                
                this.gui.startFitting = uicontrol(rightPanel,'Style','radiobutton','String','Start Fitting','Units','normalized',...
                    'Position',[0.5 0.925 0.43 0.03],'CallBack',@this.startFitting_Callback);
                
            end
            
            function createBasicInfoTalbe(this)
                
                rightPanel = this.gui.rightPanel;
                
                rowName = {'Beam Energy (keV)', 'Slit Size (mm)', 'Detector Footprint (mm)'};
                colName = {};
                columnFormat = {'numeric'};
                columnWidth = {120};
                tableData = {10; 10.76; 0.024};
                
                this.gui.basicInfoTable = uitable(rightPanel, 'Data', tableData, 'ColumnName', colName, ...
                    'ColumnFormat', columnFormat, 'ColumnEditable', true, 'Units','normalized', ...
                    'ColumnWidth',columnWidth,'RowName',rowName, 'RowStriping','off',...
                    'Position', [0.025 0.84 0.935 0.08], 'TooltipString', 'Press enter to update value.', ...
                    'CellEditCallBack', @this.basicInfo_Callback);
                
            end
            
            function createLayersTable(this)
                
                rightPanel = this.gui.rightPanel;
                
                rowName = {'1'};
                colName = {'Formula', 'ED', 'Depth', 'Conc', 'Fit', 'Del'};
                colFormat = {'char', 'numeric', 'numeric', 'numeric', 'logical', 'logical'};
                colWidth = {140, 40, 40, 40, 30, 30};
                tableData = {'H2O', 0.334, Inf, 0, false, false};
                
                this.gui.layerTableTitle = uicontrol(rightPanel,'Style','text','String','Layer Structure:','Units','normalized','HorizontalAlignment','left',...
                    'Position',[0.025 0.81 0.8 0.025]);
                
                this.gui.layerTable = uitable(rightPanel,'Data', tableData,'ColumnName', colName,...
                    'ColumnFormat', colFormat,'ColumnEditable', true(1, 6), 'Units', 'normalized',...
                    'ColumnWidth',colWidth,'RowName',rowName,'RowStriping','off',...
                    'Position', [0.025 0.66 0.935 0.15], 'CellEditCallBack',@this.layerTable_Callback);
                
                this.gui.addLayer = uicontrol(rightPanel,'Style','pushbutton','String', 'Add', 'Units','normalized',...
                    'Position', [0.725 0.63 0.11 0.03], 'CallBack', @this.addLayer_Callback);
                
                this.gui.deleteLayer = uicontrol(rightPanel,'Style','pushbutton','String', 'Delete','Units','normalized',...
                    'Position', [0.84 0.63 0.12 0.03], 'CallBack', @this.deleteLayers_Callback);
                
            end
            
            function createParametersTable(this)
                
                rightPanel = this.gui.rightPanel;
                
                rowName = {'Angle Offset','Scale Factor','Background'};
                colName = {'Min','Max','Start','Fix','Plot'};
                colFormat = {'numeric','numeric','numeric','logical','logical'};
                colWidth = {55 55 55 30 30};
                tableData = {-0.001,0.001,0,false,false; 1,1,1,true,false; 1,1,1,true,false;};
                
                this.gui.parametersTableTitle = uicontrol(rightPanel,'Style','text','String','Fitting Parameters:','Units','normalized','HorizontalAlignment','left',...
                    'Position', [0.025 0.625 0.8 0.025]);
                
                this.gui.parametersTable = uitable(rightPanel,'Data', tableData,'ColumnName', colName,...
                    'ColumnFormat', colFormat,'ColumnEditable', [true true true true true],'Units','normalized',...
                    'ColumnWidth',colWidth,'RowName',rowName,'RowStriping','off',...
                    'Position', [0.025 0.495 0.935 0.13], 'CellEditCallBack', @this.parametersTable_Callback);
                
            end
            
            function createFittingControls(this)
                
                rightPanel = this.gui.rightPanel;
                
                this.gui.layerTableTitle = uicontrol(rightPanel,'Style','text','String', 'Fitting Control:','Units','normalized','HorizontalAlignment','left',...
                    'Position',[0.025 0.46 0.8 0.025]);
                
                this.gui.loadPara = uicontrol(rightPanel,'Style','pushbutton','String','Load Para','Units','normalized',...
                    'Position',[0.024 0.43 0.17 0.03],'CallBack',@this.loadPara_Callback);
                
                this.gui.savePara = uicontrol(rightPanel,'Style','pushbutton','String','Save Para','Units','normalized',...
                    'Position',[0.19 0.43 0.17 0.03],'CallBack',@this.savePara_Callback);
                
                this.gui.stepInput = uicontrol(rightPanel,'Style','edit','String',20,'Units','normalized',...
                    'HorizontalAlignment','left','Position',[0.62 0.43 0.1 0.03]);
                
                this.gui.stepText = uicontrol(rightPanel,'Style','text','String','Steps','Units','normalized',...
                    'HorizontalAlignment','left','Position',[0.735 0.425 0.08 0.03]);
                
                this.gui.fitButton = uicontrol(rightPanel,'Style','pushbutton','String','Fit','Units','normalized',...
                    'Position',[0.82 0.43 0.15 0.03],'CallBack',@this.fitButton_Callback);
                
                this.gui.withText = uicontrol(rightPanel,'Style','text','String','With','Units','normalized','HorizontalAlignment','left',...
                    'Position',[0.025 0.395 0.07 0.03]);
                this.gui.confidenceInput = uicontrol(rightPanel,'Style','edit','String','95','Units','normalized',...
                    'HorizontalAlignment','left','Position',[0.1 0.4 0.07 0.03],'CallBack',@this.confidenceInput_Callback);
                this.gui.confidenceText = uicontrol(rightPanel,'Style','text','String','% confidence window','Units','normalized','HorizontalAlignment','left',...
                    'Position',[0.171 0.395 0.28 0.03]);
                this.gui.recordFitting = uicontrol(rightPanel,'Style','pushbutton','String','Record Fitting','Units','normalized',...
                    'Position',[0.452 0.4 0.22 0.03],'CallBack',@this.recordFitting_Callback);
                
                this.gui.adjustPara = uicontrol(rightPanel,'Style','pushbutton','String','Adjust Para','Units','normalized',...
                    'Position',[0.77 0.4 0.2 0.03],'CallBack',@this.adjustPara_Callback);
                
            end
            
            function createOutputandSaveButtons(this)
                
                rightPanel = this.gui.rightPanel;
                
                this.gui.output = uicontrol(rightPanel,'Style','edit','Max',2,'HorizontalAlignment','left','Units','normalized',...
                    'Position',[0.03 0.07 0.935 0.32]);
                
                uicontrol(rightPanel,'Style','pushbutton','String','Clear','Units','normalized',...
                    'Position',[0.82 0.038 0.15 0.03],'CallBack',@this.clearButton_Callback);
                
                uicontrol(rightPanel,'Style','text','String','Save:','Units','normalized',...
                    'HorizontalAlignment','left','Position',[0.025 0.035 0.08 0.025]);
                
                uicontrol(rightPanel,'Style','pushbutton','String','Output Text','Units','normalized',...
                    'Position',[0.024 0.007 0.2 0.03],'CallBack',@this.saveText_Callback);
                
                uicontrol(rightPanel,'Style','pushbutton','String','Upper Figure','Units','normalized',...
                    'Position',[0.234 0.007 0.2 0.03],'CallBack',@this.saveFig1_Callback);
                
                uicontrol(rightPanel,'Style','pushbutton','String','Lower Figure','Units','normalized',...
                    'Position',[0.444 0.007 0.2 0.03],'CallBack',@this.saveFig2_Callback);
                
                uicontrol(rightPanel,'Style','pushbutton','String','Data Set','Units','normalized',...
                    'Position',[0.654 0.007 0.15 0.03],'CallBack',@this.saveDataset_Callback);
                
                uicontrol(rightPanel,'Style','pushbutton','String','Data & Fit','Units','normalized',...
                    'Position',[0.814 0.007 0.17 0.03],'CallBack',@this.saveDataFit_Callback);
                
            end
            
        end
        
        % call back functions
        
        function loadButton_Callback(this, source, eventdata)

            [oldFiles, newFiles] = this.loadNewData();
            
            if ~isempty(newFiles)
                
                this.gui.fileList.String = [oldFiles, newFiles];
                
                if isempty(oldFiles)
                    this.updateView('file');
                end
                
            end
            
        end
        
        function deleteButton_Callback(this, source, eventdata)

            fileList = this.gui.fileList;
            
            if ~isempty(fileList.String)
                
                if isa(fileList.String, 'char')
                    n = true;
                else
                    n = true(1, length(fileList.String));
                end
                m = fileList.Value;
                n(m) = false(1, length(m));
                this.data = this.data(n);
                
                this.updateView('delete', n);
                
            end
            
        end
        
        function fileList_Callback(this, source, eventdata)

            this.updateView('file');
            
        end
        
        function angleList_Callback(this, source, eventdata)
            
%             if elementPopup.Value ~= 1 && elementPopup.Value ~= length(elementPopup.String) && length(scanList.Value) == 1
%                 getAllInputs;
%                 getCalculation;
%             end
            this.updateView('angle');
            
        end
        
        function showError_Callback(this, source, eventdata)
            
            this.updateView('error');
            
        end
        
        function element_Callback(this, source, eventdata)
            
            n = length(this.gui.elementPopup.String);
            m = this.gui.elementPopup.Value;
            switch m
                case 1
                    this.control.element = 'none';
                case n
                    this.control.element = 'new';
                otherwise
                    this.control.element = this.gui.elementPopup.String{this.gui.elementPopup.Value};
                    this.fitSpectraToElement();
            end
            
            this.updateView('element');
            
        end
        
        function lineShape_Callback(this, source, eventdata)
            
            this.control.lineShape = this.gui.lineShape.String{this.gui.lineShape.Value};
            this.fitSpectraToElement();
            this.updateView('lineshape');
            
        end
        
        function removeBackground_Callback(this, source, eventdata)
            
            this.updateView('background');
            
        end
        
        function startFitting_Callback(this, source, eventdata)
            
            this.gui.fileList.Value = min(this.gui.fileList.Value);
            this.updateView('start-fitting');
            
        end
        
        function basicInfo_Callback(this, source, eventdata)
            
            table = this.gui.basicInfoTable;
            
            ind = eventdata.Indices;
            olddata = eventdata.PreviousData;
            
            if isnan(table.Data{ind(1), ind(2)})
                table.Data{ind(1), ind(2)} = olddata;
            end
            
        end
        
        function showCal_Callback(this, source, eventdata)
            
            this.updateView('calculated');
            
        end
        
        function layerTable_Callback(this, source, eventdata)
            
            ind = eventdata.Indices;
            olddata = eventdata.PreviousData;
            newdata = eventdata.EditData;
            
            table = this.gui.layerTable;
            n = size(table.Data, 1);
            
            switch ind(2)
                case 1
                    if ~isempty(newdata)
                        try
                            parseFormula(newdata);
                        catch EM
                            table.Data{ind(1), ind(2)} = olddata;
                            this.raiseErrorDialog(EM.message);
                        end
                    end
                case 2
                    if str2double(newdata) <= 0
                        table.Data{ind(1), ind(2)} = olddata;
                        this.raiseErrorDialog('Electron density must be larger than 0.');
                    end
                case 3
                    switch ind(1)
                        case n
                            table.Data{ind(1), ind(2)} = olddata;
                        otherwise
                            if str2double(newdata) <= 0
                                table.Data{ind(1), ind(2)} = olddata;
                                this.raiseErrorDialog('Depth must be larger than 0.');
                            end
                    end
                case 4
                    if str2double(newdata) < 0
                        table.Data{ind(1), ind(2)} = olddata;
                        this.raiseErrorDialog('Concentration must not be smaller than 0');
                    else
                        this.matchLayerToParameter();
                    end
                case 5
                    if sum(this.chosenFitConcentration()) > 1
                        this.resetFitConcentration();
                        table.Data{ind(1), ind(2)} = newdata;
                    end
                    this.matchLayerToParameter();
                case 6
                    if ind(1) == n
                        table.Data{ind(1), ind(2)} = false;
                    end
            end
            
        end
        
        function addLayer_Callback(this, source, eventdata)
            
            layerData = this.gui.layerTable.Data;
            [n, m] = size(layerData);
            
            newData = cell(n+1, m);
            newData(2:n+1, :) = layerData;
            newData(1, :) = {'H2O', 0.334, 1, 0, false, false};
            
            rowName = cell(1, n+1);
            for i = 1 : n+1
                rowName{i} = num2str(i);
            end
            
            this.gui.layerTable.Data = newData;
            this.gui.layerTable.RowName = rowName;
            
        end
        
        function deleteLayers_Callback(this, source, eventdata)
            
            this.updateView('delete-layers');
        
        end
        
        function parametersTable_Callback(this, source, eventdata)
            
            ind = eventdata.Indices;
            olddata = eventdata.PreviousData;
            newdata = eventdata.EditData;
            
            table = this.gui.parametersTable;
            numeric = ~isnan(table.Data{ind(1), ind(2)});
            
            switch ind(2)
                case 1
                    if numeric
                        if this.angleOffsetWithinLimit()
                            this.adjustParameterTableBounds('min');
                        else
                            table.Data{ind(1), ind(2)} = olddata;
                            this.raiseErrorDialog('Offset cannot be smaller than the smallest angle.');
                        end
                    else
                        table.Data{ind(1), ind(2)} = olddata;
                    end
                case 2
                    if numeric
                        this.adjustParameterTableBounds('max');
                    else
                        table.Data{ind(1), ind(2)} = olddata;
                    end
                case 3
                    if numeric
                        this.adjustParameterTableBounds('start');
                    else
                        table.Data{ind(1), ind(2)} = olddata;
                    end
                case 4
                    if ind(1) == 4
                        if newdata
                            this.matchParameterToLayer();
                        end
                    else
                        table.Data{ind(1), ind(2)} = olddata;
                    end
                case 5
            end
            
            if ind(1) == 4
                this.matchParameterToLayer();
            end
            
        end
        
        % data processing
        
        function processGuiConfig(this)
            
            parent = getParentDir(which('XeRay.m'));
            this.config = loadjson(fullfile(parent, 'support-files/xeray-config.json'));
            this.config.ScatteringFactorFolder = fullfile(parent, this.config.ScatteringFactorFolder);
            %this.config.elementProfilesFolder = fullfile(parent, this.config.elementProfilesFolder);
            
        end
        
        function data = getDataForElementTable(this, elementName)
            
            data = cell(3,2);
            profile = this.ElementProfiles.(elementName);
            data{1,1} = profile.range(1);
            data{1,2} = profile.range(2);
            data{2,1} = profile.peak(1);
            
            if length(profile.peak) > 1
                data{2,2} = profile.peak(2);
            else
                data{2,2} = NaN;
            end
            if ~isempty(profile.width)
                data{3,1} = profile.width(1);
                if length(profile.width) > 1
                    data{3,2} = profile.width(2);
                else
                    data{3,2} = NaN;
                end
            else
                data{3,1} = NaN;
                data{3,2} = NaN;
            end
            
        end
        
        function [oldFiles, newFiles] = loadNewData(this, filenames)

            if nargin == 2
                n = length(filenames);
                newFiles = cell(1, n);
                path = fileparts(filenames{1});
                for i = 1 : n
                    [~, name, extension] = fileparts(filenames{i});
                    newFiles{i} = [name, extension];
                end
            else
                [newFiles, path] = uigetfile('*.xfluo','Select fluorescence data files', 'MultiSelect', 'on');
            end
            
            if ~isa(newFiles,'numeric') %got files
                
                %convert to cell array
                if isa(newFiles,'char')
                    newFiles = {newFiles};
                end
                
                oldFiles = this.gui.fileList.String;
                
                %remove files aleady loaded
                if ~isempty(oldFiles)
                    if isa(oldFiles,'char') %if only one file before loading, convert to cell array
                        oldFiles = {oldFiles};
                    end
                    
                    sel = ones(size(newFiles));
                    for i = 1:length(newFiles)
                        for j = 1:length(oldFiles)
                            if strcmp(oldFiles{j},newFiles{i})
                                sel(i) = 0;
                            end
                        end
                    end
                    sel = logical(sel);
                    newFiles = newFiles(sel);
                end
                
                %if new files found, load them
                n = length(newFiles);
                if n > 0
                    
                    %import data
                    newData = cell(1,n);
                    for i = 1:n
                        newData{i} = XeLayers(fullfile(path, newFiles{i}), this.config.ScatteringFactorFolder);
                    end
                    this.data = [this.data, newData];
                    
                end
                
            end
            
        end
        
        function indices = activeDataSets(this)
            
            indices = this.gui.fileList.Value;
            
        end
        
        function [n, m, rankn, rankm] = getSelectionIndex(this)
            % 4 indices for each selected spectrum
            % n is the position within the x{} data set, m is the position for
            % the angle, rankn is the position of n within selected n, and rankm is
            % the position of m within selected m for that specific n
            
            fileList = this.gui.fileList;
            angleList = this.gui.angleList;
            
            n = zeros(size(angleList.Value));
            m = n;
            rankn = n;
            rankm = n;
            
            cn = cumsum(this.dataLengths(fileList.Value));
            
            for i = 1:length(angleList.Value)
                rankn(i) = find(cn >= angleList.Value(i),1);
                n(i) = fileList.Value(rankn(i));
                if rankn(i) > 1
                    m(i) = angleList.Value(i) - cn(rankn(i)-1);
                else
                    m(i) = angleList.Value(i);
                end
                if i == 1 || rankn(i) > rankn(i-1)
                    rankm(i) = 1;
                else
                    rankm(i) = rankm(i-1)+1;
                end
            end
            
        end
        
        function [fileIndex, angleIndices] = getSelectedSignalIndices(this)
            
            [n, m, ~, ~] = this.getSelectionIndex();
            
            n1 = n;
            n1(2:end) = n1(2:end)-n1(1:end-1);
            ind = find(n1~=0);
            
            fileIndex = zeros(size(ind));
            angleIndices = cell(size(ind));
            
            for i = 1:length(ind)-1
                fileIndex(i) = n(ind(i));
                angleIndices{i} = m(ind(i):ind(i+1)-1);
            end
            fileIndex(end) = n(ind(end));
            angleIndices{end} = m(ind(end):end);
            
        end
        
        function [styles1, legends1, styles2, legends2] = getSpectraStylesAndLegends(this)

            
            angleList = this.gui.angleList;
            fileList = this.gui.fileList;
            
            %obtain line spec for plotting, and legends
            styles1 = cell(size(angleList.Value));
            legends1 = styles1;
            
            [~,~,rankn,rankm] = this.getSelectionIndex();
            rankn = mod(rankn,length(this.control.symbols));
            rankn(rankn==0) = length(this.control.symbols);
            rankm = mod(rankm,length(this.control.colors));
            rankm(rankm==0) = length(this.control.colors);
            
            for i = 1:length(angleList.Value)
                styles1{i} = strcat(this.control.symbols(rankn(i)),this.control.colors(rankm(i)));
                legends1{i} = angleList.String{angleList.Value(i)};
            end
            
            uniqueN = unique(rankn,'stable');
            styles2 = cell(size(uniqueN));
            legends2 = styles2;
            for i = 1:length(uniqueN)
                styles2{i} = this.control.symbols(uniqueN(i));
                legends2{i} = fileList.String{fileList.Value(uniqueN(i))};
            end
            
        end
        
        function fitSpectraToElement(this)
            
            element = this.gui.elementPopup.String{this.gui.elementPopup.Value};
            lineShape = this.gui.lineShape.String{this.gui.lineShape.Value};
            
            for i = 1 : length(this.data)
                
                this.data{i}.selectElement(element, lineShape);
                
            end
            
        end
        
        function lengths = dataLengths(this, indices)
            
            if ~isempty(this.data)
                if nargin == 1
                    indices = 1 : length(this.data);
                elseif max(indices) > length(this.data)
                    warning('Indices cannot be larger than the number of datasets.');
                end
                n = length(indices);
                lengths = zeros(1, n);
                for i = 1 : n
                    lengths(i) = length(this.data{indices(1)}.rawdata.angle);
                end
            else
                lengths = 0;
                disp('No data.');
            end
            
        end
        
        function loadCellArrayDataFiles(this, filenames)
            
            flag = 1;
            if ischar(filenames)
                filenames = {filenames};
            end
            for i = 1 : length(filenames)
                if ~exist(filenames{i}, 'file')
                    Warning('Cannot find this file: %s', filenames{i});
                    flag = 0;
                    break;
                end
            end
            
            if flag == 1
                [oldFiles, newFiles] = this.loadNewData(filenames);
                if ~isempty(newFiles)
                    
                    this.gui.fileList.String = [oldFiles, newFiles];
                    
                    if isempty(oldFiles)
                        this.updateView('file');
                    end
                    
                end
            end
            
            
            
        end
        
        function createLayerSystem(this)
            
            tabledata = this.gui.basicInfoTable.Data;
            energy = tabledata{1};
            slit = tabledata{2};
            foot = tabledata{3};
            
            for i = 1 : length(this.data)
                this.data{i}.createPhysicalSystem(energy, slit, foot);
            end
            
        end
        
        function processGuiInputs(this)
            
            % create the physical system
            
            basicInfo = this.gui.basicInfoTable.Data;
            energy = basicInfo{1};
            slit = basicInfo{2};
            foot = basicInfo{3};
            n = this.gui.fileList.Value;
            
            this.data{n}.createPhysicalSystem(energy, slit, foot);
            
            % create layers - layers table
            layerData = this.gui.layerTable.Data;
            n = size(layerData, 1);
            
            dataset = this.data{this.gui.fileList.Value};
            concentration = zeros(1, n);
            
            for i = n : -1 : 1
                concentration(i) = layerData{i, 4};
                if isempty(layerData{i, 1})
                    parameters = layerData(i, [2, 3]);
                else
                    parameters = layerData(i, [2, 3, 1]);
                end
                dataset.system.insert(1, parameters{:});
            end
            
            dataset.system.concentration = concentration;
            
            % construct fitting parameters
            table = this.gui.parametersTable;
            n = size(table.Data, 1);
            mat = cell2mat(table.Data(:, 1:3));
            switch n
                case 3
                    lower = [mat(:, 1)', 0, 0];
                    upper = [mat(:, 2)', 0, 0];
                case 4
                    index = find(this.chosenFitConcentration());
                    lower = [mat(:, 1)', index];
                    upper = [mat(:, 2)', index];
            end
            
            steps = str2double(this.gui.stepInput.String);
            
            dataset.fit = XeFitting(lower, upper, steps);
            
        end
        
        function starts = obtainStarts(this)
            
            table = this.gui.parametersTable;
            n = size(table.Data, 1);
            mat = cell2mat(table.Data(:, 1:3));
            switch n
                case 3
                    starts = [mat(:, 3)', 0, 0];
                case 4
                    starts = [mat(:, 3)', 0];
            end
            
        end
        
        % view controller
        
        function updateView(this, trigger, varargin)
            
            switch trigger
                case 'file'
                    this.displayAngles();
                    this.replot();
                case 'angle'
                    this.replot();
                case 'delete'
                    indices = varargin{1};
                    fileList = this.gui.fileList;
                    angleList = this.gui.angleList;
                    if sum(indices)
                        fileList.String = fileList.String(indices);
                        fileList.Value = 1;
                        angleList.Value = 1;
                        this.displayAngles();
                    else
                        fileList.Value = 1;
                        fileList.String = {};
                        angleList.String = {};
                        this.emptyFigures();
                    end
                case 'error'
                    this.replot();
                case 'element'
                    element = this.control.element;
                    this.dynamicOnOffControl();
                    switch element
                        case 'none'
                            this.replot();
                        case 'new'
                            
                        otherwise
                            this.replot();
                    end
                case 'lineshape'
                    this.replot();
                case 'background'
                    this.replot();
                case 'start-fitting'
                    this.displayAngles();
                    this.dynamicOnOffControl();
                    this.replot();
                case 'delete-layers'
                    this.deleteLayers();
                    this.matchLayerToParameter();
                case 'calculated'
                    this.replot();
            end
            
        end
        
        function replot(this)
            
            switch this.control.element
                case 'none'
                    this.emptyFigures(2);
                    switch this.gui.showError.Value
                        case 0
                            this.plotWholeSpectraWithoutError();
                        case 1
                            this.plotWholeSpectraWithError();
                    end
                case 'new'
                    % do nothing
                otherwise
                    switch this.gui.showError.Value
                        case 0
                            this.plotElementSpectraWithoutError();
                        case 1
                            this.plotElementSpectraWithError();
                    end
                    switch this.gui.showCal.Value
                        case 0
                            this.plotSignal();
                        case 1
                            this.plotSignal();
                            this.plotCalculation();
                    end
            end
            
        end
        
        % plot functions
        
        function plotWholeSpectraWithoutError(this)
            
            ax = this.gui.ax1;
            
            [n, m, ~, ~] = this.getSelectionIndex();
            [styles, legends, ~, ~] = this.getSpectraStylesAndLegends();
            
            hold(ax, 'off');
            
            for i = 1 : length(this.gui.angleList.Value)
                xdata = this.data{n(i)}.rawdata.energy;
                ydata = this.data{n(i)}.rawdata.intensity(:, m(i));
                plot(ax, xdata, ydata, styles{i});
                if i == 1
                    hold(ax, 'on');
                end
            end
            
            set(ax, 'xlim', [min(this.data{this.gui.fileList.Value(1)}.rawdata.energy), max(this.data{this.gui.fileList.Value(1)}.rawdata.energy)]);
            
            legend(ax, legends);
            title(ax, 'Whole Spectra');
            xlabel(ax, 'Energy (keV)');
            ylabel(ax, 'Signal');
            
            hold(ax, 'off');
            
        end
        
        function plotWholeSpectraWithError(this)
            
            ax = this.gui.ax1;
            
            [n, m, ~, ~] = this.getSelectionIndex();
            [styles, legends, ~, ~] = this.getSpectraStylesAndLegends();
            
            hold(ax, 'off');
            
            for i = 1 : length(this.gui.angleList.Value)
                xdata = this.data{n(i)}.rawdata.energy;
                ydata = this.data{n(i)}.rawdata.intensity(:, m(i));
                yerror = this.data{n(i)}.rawdata.intensityError(:, m(i));
                errorbar(ax, xdata, ydata, yerror, styles{i});
                if i == 1
                    hold(ax, 'on');
                end
            end
            
            set(ax, 'xlim', [min(this.data{this.gui.fileList.Value(1)}.rawdata.energy), max(this.data{this.gui.fileList.Value(1)}.rawdata.energy)]);
            
            legend(ax, legends);
            title(ax, 'Whole Spectra');
            xlabel(ax, 'Energy (keV)');
            ylabel(ax, 'Signal');
            
            hold(ax, 'off');
            
        end
        
        function plotElementSpectraWithoutError(this)
            
            ax = this.gui.ax1;
            
            [n, m, ~, ~] = this.getSelectionIndex();
            [styles, legends, ~, ~] = this.getSpectraStylesAndLegends();
            
            hold(ax, 'off');
            
            switch this.gui.removeBackground.Value
                case 0
                    marker = 'intensity';
                case 1
                    marker = 'netIntensity';
            end
            
            for i = 1 : length(this.gui.angleList.Value)
                xdata = this.data{n(i)}.data.energy;
                ydata = this.data{n(i)}.data.(marker)(:, m(i));
                plot(ax, xdata, ydata, styles{i});
                if i == 1
                    hold(ax, 'on');
                end
            end
            
            legend(ax, legends);
            title(ax, sprintf('%s %s', this.control.element, 'Spectra'));
            xlabel(ax, 'Energy (keV)');
            ylabel(ax, 'Signal');
            
            for i = length(this.gui.angleList.Value)
                xdata = this.data{n(i)}.data.lineshape.energy;
                ydata = this.data{n(i)}.data.lineshape.(marker)(:, m(i));
                plot(ax, xdata, ydata, styles{i}(2));
            end
            
            hold(ax, 'off');
            
        end
        
        function plotElementSpectraWithError(this)
            
            ax = this.gui.ax1;
            
            [n, m, ~, ~] = this.getSelectionIndex();
            [styles, legends, ~, ~] = this.getSpectraStylesAndLegends();
            
            hold(ax, 'off');
            
            switch this.gui.removeBackground.Value
                case 0
                    marker = 'intensity';
                case 1
                    marker = 'netIntensity';
            end
            
            for i = 1 : length(this.gui.angleList.Value)
                xdata = this.data{n(i)}.data.energy;
                ydata = this.data{n(i)}.data.(marker)(:, m(i));
                yerror = this.data{n(i)}.data.intensityError(:, m(i));
                errorbar(ax, xdata, ydata, yerror, styles{i});
                if i == 1
                    hold(ax, 'on');
                end
            end
                    
            legend(ax, legends);
            title(ax, sprintf('%s %s', this.control.element, 'Spectra'));
            xlabel(ax, 'Energy (keV)');
            ylabel(ax, 'Signal');
            
            for i = length(this.gui.angleList.Value)
                xdata = this.data{n(i)}.data.lineshape.energy;
                ydata = this.data{n(i)}.data.lineshape.(marker)(:, m(i));
                plot(ax, xdata, ydata, styles{i}(2));
            end
            
            hold(ax, 'off');
            
        end
        
        function plotSignal(this)
            
            [~, ~, styles, legends] = this.getSpectraStylesAndLegends();
            [n, m] = this.getSelectedSignalIndices();
            
            sel = true(size(n));
            
            hold(this.gui.ax2, 'off');
            
            for i = 1:length(n)
                if isempty(m{i})
                    sel(i) = false;
                end
                xdata = this.data{n(i)}.data.angle(m{i});
                ydata = this.data{n(i)}.data.lineshape.signal(m{i});
                yerror = this.data{n(i)}.data.lineshape.signalError(m{i});
                errorbar(this.gui.ax2, xdata, ydata, yerror, styles{i}, 'markersize', 8, 'linewidth', 2);
                if i == 1
                   hold(this.gui.ax2, 'on'); 
                end
            end
            
            selectedLegends = legends(sel);
            
%             if withCalculation
%                 n = scanList.Value(1);
%                 if isempty(x{n}.calculation)
%                     getAllInputs;
%                     getCalculation;
%                 end
%                 plot(ax,x{n}.calRange,x{n}.calculation,'g-','linewidth',2);
%                 hold(ax,'on');
%                 theLegend = [theLegend,{'Calculation'}];
%             end
%             
%             if withFit
%                 n = scanList.Value(1);
%                 plot(ax,x{n}.fluoFit.fitAll.fitQRange,x{n}.fluoFit.fitAll.fitSignal,'r-','linewidth',2);
%                 hold(ax,'on');
%                 theLegend = [theLegend,{'Fit'}];
%             end
            
            xlabel(this.gui.ax2, 'Angle (radians)');
            ylabel(this.gui.ax2, 'Fluorescence Intensity (a.u.)');
            title(this.gui.ax2, sprintf('%s %s', this.control.element, 'Fluorescence'));
            legend(this.gui.ax2, selectedLegends);
            hold(this.gui.ax2, 'off');
            
        end
        
        function plotCalculation(this)
            
            dataset = this.data{this.gui.fileList.Value};
            starts = this.obtainStarts();
            
            angles = dataset.rawdata.angle(this.gui.angleList.Value);
            
            ax = this.gui.ax2;
            hold(ax, 'on');
            
            if length(angles) == 1
                fineAngleRange = linspace(angles * 0.99, angles * 1.01, 2);
            else
                fineAngleRange = linspace(min(angles), max(angles), 100);
            end
            
            calculated = dataset.system.calculateFluoIntensityCurve(starts, fineAngleRange);
            
            if length(angles) == 1
                plot(ax, fineAngleRange, calculated, 'r-', 'linewidth', 2);
            else
                plot(ax, fineAngleRange, calculated, 'r-', 'linewidth', 2);
            end
            
        end
        
        % view control functions
        
        function displayAngles(this)
            
            fileList = this.gui.fileList;
            angleList = this.gui.angleList;
            
            n = zeros(size(fileList.Value));
            for i = 1:length(fileList.Value)
                n(i) = length(this.data{fileList.Value(i)}.rawdata.angle);
            end
            
            angleStrings = cell(1, sum(n));
            k = 0;
            for i = 1:length(n)
                for j = 1 : n(i)
                    k = k + 1;
                    angleStrings{k} = sprintf('%s %s %f',fileList.String{fileList.Value(i)}(1:end-6), '@angle: ',this.data{fileList.Value(i)}.rawdata.angle(j));
                end
            end
            
            if max(angleList.Value) > length(angleStrings)
                angleList.Value = 1;
            end
            angleList.String = angleStrings;
            
        end
        
        function emptyFigures(this, index)
            
            switch nargin
                case 1
                    plot(this.gui.ax1, 1);
                    plot(this.gui.ax2, 1);
                case 2
                    switch index
                        case 1
                            plot(this.gui.ax1, 1);
                        case 2
                            plot(this.gui.ax2, 1);
                    end
            end
            
        end
        
        function dynamicOnOffControl(this)
            
            n = length(this.gui.elementPopup.String);
            m = this.gui.elementPopup.Value;
            switch m
                case 1
                    set(findall(this.gui.rightPanel, '-property', 'Enable'), 'Enable', 'off');
                    this.gui.elementPopup.Enable = 'on';
                    this.gui.fileList.Enable = 'on';
                    this.gui.showFit.Enable = 'off';
                    this.gui.showCal.Enable = 'off';
                case n
                otherwise
                    switch this.gui.startFitting.Value
                        case 0
                            set(findall(this.gui.rightPanel, '-property', 'Enable'), 'Enable', 'off');
                            this.gui.lineShape.Enable = 'on';
                            this.gui.startFitting.Enable = 'on';
                            this.gui.removeBackground.Enable = 'on';
                            this.gui.elementPopup.Enable = 'on';
                            this.gui.fileList.Enable = 'on';
                        case 1
                            set(findall(this.gui.rightPanel, '-property', 'Enable'), 'Enable', 'on');
                            this.gui.fileList.Enable = 'off';
                            this.gui.elementPopup.Enable = 'off';
                            this.gui.lineShape.Enable = 'off';
                            this.gui.removeBackground.Enable = 'off';
                            this.gui.showCal.Enable = 'on';
                            switch isempty(this.data{this.gui.fileList.Value(1)}.fit)
                                case false
                                    this.gui.showFit.Enable = 'on';
                                case true
                                    this.gui.showFit.Enable = 'off';
                            end
                    end
            end
            
        end
        
        function matchLayerToParameter(this)
            
            n = find(this.chosenFitConcentration());
            ltable = this.gui.layerTable;
            ptable = this.gui.parametersTable;
            
            if ~isempty(n)
                ptable.RowName = {'Angle Offset', 'Scale Factor', 'Background', 'Conc.'};
                tableData = cell(4, 5);
                tableData(1:3, :) = ptable.Data(1:3, :);
                
                start = ltable.Data{n, 4};
                if start == 0
                    ub = 1;
                else
                    ub = start * 2;
                end
                lb = start * 0.5;
                
                tableData(4, :) = {lb, ub, start, false, false};
                ptable.Data = tableData;
            else
                ptable.RowName = {'Angle Offset','Scale Factor','Background'};
                ptable.Data = ptable.Data(1:3, :);
            end
            
        end
        
        function matchParameterToLayer(this)
            
            ptable = this.gui.parametersTable;
            n = size(ptable.Data, 1);
            
            if n == 4 && ptable.Data{4, 4}
                index = this.chosenFitConcentration();
                this.gui.layerTable.Data{find(index), 5} = false;
                
                this.gui.parametersTable.RowName = {'Angle Offset','Scale Factor','Background'};
                this.gui.parametersTable.Data = this.gui.parametersTable.Data(1:3, :);
            end
            
        end
        
        function indices = chosenFitConcentration(this)
            
            layerData = this.gui.layerTable.Data;
            n = size(layerData, 1);
            indices = zeros(1, n);
            
            for i = 1 : n
                if layerData{i, 5}
                    indices(i) = 1;
                end
            end
            
        end
        
        function raiseErrorDialog(this, message)
            
            h = errordlg({message, 'Closing in 5s...'});
            pause(5);
            try
                close(h);
            catch
            end
            
        end
        
        function resetFitConcentration(this)
            
            table = this.gui.layerTable;
            n = size(table.Data, 1);
            
            for i =  1 : n
                table.Data{i, 5} = false;
            end
            
        end
        
        function deleteLayers(this)
            
            table = this.gui.layerTable;
            n = size(table.Data, 1);
            
            sel = true(1, n);
            for i = 1 : n
                if table.Data{i, end}
                    sel(i) = false;
                end
            end
            
            table.Data = table.Data(sel, :);
            table.RowName = table.RowName(1:sum(sel));
            
        end
        
        function flag = angleOffsetWithinLimit(this)
            
            flag = 1;
            table = this.gui.parametersTable;
            minOffset = - min(this.data{this.gui.fileList.Value}.rawdata.angle);
            for i = 1 : 3
                if table.Data{1, i} < minOffset
                    flag = false;
                    break;
                end
            end
            
        end
        
        function adjustParameterTableBounds(this, what)
            
            table = this.gui.parametersTable;
            
            matrix = cell2mat(table.Data(:, 1:3));
            mins = matrix(:, 1);
            maxs = matrix(:, 2);
            starts = matrix(:, 3);
            
            switch what
                case 'min'
                    ind = find(mins > maxs);
                    if ~isempty(ind)
                        for i = ind
                            table.Data{i, 2} = table.Data{i, 1};
                            table.Data{i, 3} = table.Data{i, 1};
                        end
                    else
                        ind = find(mins > starts);
                        if ~isempty(ind)
                            for i = ind
                                table.Data{i, 3} = table.Data{i, 1};
                            end
                        end
                    end
                case 'max'
                    ind = find(mins > maxs);
                    if ~isempty(ind)
                        for i = ind
                            table.Data{i, 1} = table.Data{i, 2};
                            table.Data{i, 3} = table.Data{i, 2};
                        end
                    else
                        ind = find(maxs < starts);
                        if ~isempty(ind)
                            for i = ind
                                table.Data{i, 3} = table.Data{i, 2};
                            end
                        end
                    end
                case 'start'
                    ind = find(starts > maxs);
                    if ~isempty(ind)
                        for i = ind
                            table.Data{i, 2} = table.Data{i, 3};
                        end
                    else
                        ind = find(starts < mins);
                        if ~isempty(ind)
                            for i = ind
                                table.Data{i, 1} = table.Data{i, 3};
                            end
                        end
                    end
            end
            
            this.fixCheckboxes();
            
        end
        
        function fixed = fixCheckboxes(this)
            
            table = this.gui.parametersTable;
            n = size(table.Data, 1);
            
            matrix = cell2mat(table.Data(:, 1:3));
            mins = matrix(:, 1);
            maxs = matrix(:, 2);
            
            fixed = mins == maxs;
            
            for i = 1 : n
                table.Data{i, 4} = fixed(i);
            end
            
            fixed = find(fixed);
            
        end
        
    end
    
end
classdef XeRayGUI2 < handle
    
    properties
        
        data
        gui
        const
        
        handles
        call
        
        config
        ElementProfiles
        
    end
    
    methods
        
        function this = XeRayGUI2(filenames)
            
            initializeGui();
            
            if nargin == 1
                this.control('load-file', filenames);
            end
            
            function initializeGui()
                
                parent = getParentDir(which('XeRayGUI.m'));
                this.config = loadjson(fullfile(parent, 'support-files/xeray-config.json'));
                this.config.ScatteringFactorFolder = fullfile(parent, this.config.ScatteringFactorFolder);
                this.ElementProfiles = loadjson(fullfile(getParentDir(which('XeRayGUI.m')), 'support-files/element-profiles.json'));
                
                set(0, 'units', this.config.units);
                pix = get(0, 'screensize');
                if pix(4) * 0.85 <= this.config.window(4)
                    this.config.window(4) = pix(4)*0.85;
                end
                
                this.handles = figure('Visible','on','Name','XeRay','NumberTitle','off','Units','pixels', 'Position', this.config.window, 'Resize', 'on');
                
                this.const = XeRayControl();
                
                createController();
                createView();
                connectViewAndController();
                
                this.control('initialize');
                
            end
            
            function createController()
                
                %% callbacks - left panel
                this.call.file = @FileList_Callback;
                this.call.angle = @AngleList_Callback;
                this.call.delete = @DeleteButton_Callback;
                this.call.load = @LoadButton_Callback;
                
                function FileList_Callback(varargin)
                    
                    this.control('file');
                    
                end
                
                function AngleList_Callback(varargin)
                    
                    this.control('angle');
                    
                end
                
                function DeleteButton_Callback(varargin)
                    
                    this.control('delete-file');
                    
                end
                
                function LoadButton_Callback(varargin)
                    
                    this.control('load-file');
                    
                end
                
                %% callbacks - right panel
                
                this.call.showCal = @ShowCal_Callback;
                this.call.basicInfo = @BasicInfo_Callback;
                this.call.likelihoodChi2 = @LikelihoodChi2_Callback;
                this.call.showFit = @ShowFit_Callback;
                this.call.confidence = @ConfidenceInput_Callback;
                
                function ShowCal_Callback(varargin)
                    
                    this.control('show-cal');
                    
                end
                
                function BasicInfo_Callback(~, eventdata)
                    
                    this.control('basic-info', eventdata);
                    
                end
                
                function LikelihoodChi2_Callback(varargin)
                    
                    this.view('likelihood-chi2');
                    
                end
                
                function ShowFit_Callback(varargin)
                    
                    this.control('show-fit');
                    
                end
                
                function ConfidenceInput_Callback(varargin)
                    
                    this.control('confidence-input');
                    
                end
                
                %% callbacks - table related
                
                this.call.layer = @LayerTable_Callback;
                this.call.addLayer = @AddLayer_Callback;
                this.call.deleteLayers = @DeleteLayers_Callback;
                this.call.parametersTable = @ParametersTable_Callback;
                
                function LayerTable_Callback(~, eventdata)
                    
                    this.control('layer-table', eventdata);
                    
                end
                
                function AddLayer_Callback(varargin)
                    
                    this.control('add-layer');
                    
                end
                
                function DeleteLayers_Callback(varargin)
                    
                    % delete the layer from layer table
                    
                    this.control('delete-layers');
                    
                end
                
                function ParametersTable_Callback(~, eventdata)
                    
                    this.control('parameter-table', eventdata);
                    
                end
                
                %% callbacks - fitting related
                
                this.call.startFitting = @StartFitting_Callback;
                this.call.loadParameters = @LoadParameters_Callback;
                this.call.saveParameters = @SaveParameters_Callback;
                this.call.stepInput = @StepInput_Callback;
                this.call.fit = @FitButton_Callback;
                this.call.updateStarts = @UpdateStartButton_Callback;
                
                function StartFitting_Callback(varargin)
                    
                    this.control('start-fitting');
                    
                end
                
                function LoadParameters_Callback(varargin)
                    
                    this.control('load-parameters');
                    
                end
                
                function SaveParameters_Callback(varargin)
                    
                    this.control('save-parameters');
                    
                end
                
                function StepInput_Callback(varargin)
                    
                    this.control('step-input');
                    
                end
                
                function FitButton_Callback(varargin)
                    
                    this.control('fit');
                    
                end
                
                function UpdateStartButton_Callback(varargin)
                    
                    this.control('update-start');
                    
                end
                
                %% callbacks - saving functions
                
                this.call.saveOutput = @SaveOutputTextButton_Callback;
                this.call.saveUpperFigure = @SaveUpperFigureButton_Callback;
                this.call.saveLowerFigure = @SaveLowerFigureButton_Callback;
                this.call.saveDataAndFit = @SaveDataAndFitButton_Callback;
                this.call.clear = @ClearButton_Callback;
                this.call.record = @RecordFittingButton_Callback;
                
                function SaveOutputTextButton_Callback(varargin) %save text output
                    
                    this.control('save-output');
                    
                end
                
                function SaveUpperFigureButton_Callback(varargin) %save figure one
                    
                    this.control('save-upper-figure');
                    
                end
                
                function SaveLowerFigureButton_Callback(varargin) %save figure one
                    
                    this.control('save-lower-figure');
                    
                end
                
                function SaveDataAndFitButton_Callback(varargin)
                    
                    this.control('save-data');
                    
                end
                
                function ClearButton_Callback(varargin)
                    
                    this.control('clear-output');
                    
                end
                
                function RecordFittingButton_Callback(varargin)
                    
                    this.control('record-results');
                    
                end
                
            end
            
            function createView()
                
                handle0 = this.handles;
                
                createListPanel();
                createAxes();
                createRightPanel();
                createBasicInfoTalbe();
                createParametersTable();
                createLayersTable();
                createFittingControls();
                createOutputandSaveButtons();
                
                function createListPanel()
                    
                    listPanel = uipanel(handle0,'Title','X-ray Fluorescence Data','Units','normalized',...
                        'Position',[0.014 0.02 0.16 0.97]);
                    
                    this.gui.scanText = uicontrol(listPanel,'Style','text','String','Select data sets to begin','Units','normalized',...
                        'Position',[0.05 0.965 0.8 0.03]);
                    
                    this.gui.fileList = uicontrol(listPanel,'Style','listbox','Units','normalized',...
                        'Position',[0.05 0.56 0.9 0.405],'Max',2);
                    
                    this.gui.loadButton = uicontrol(listPanel,'Style','pushbutton','String','Load','Units','normalized',...
                        'Position',[0.035 0.52 0.3 0.032]);
                    
                    this.gui.deleteButton = uicontrol(listPanel,'Style','pushbutton','String','Delete','Units','normalized',...
                        'Position',[0.38 0.52 0.3 0.032]);
                    
                    uicontrol(listPanel,'Style','text','String','Select angle range','Units','normalized',...
                        'Position',[0.05 0.49 0.8 0.03]);
                    
                    this.gui.angleList = uicontrol(listPanel,'Style','listbox','Units','normalized',...
                        'Position',[0.05 0.015 0.9 0.48],'Max',2);
                    
                end
                
                function createAxes()
                    
                    this.gui.startFitting = uicontrol(handle0,'Style','checkbox','String','Start Fitting','Units','normalized','Visible','on',...
                        'Position',[0.6 0.965 0.1 0.018]);
                    
                    this.gui.likelihoodChi2 = uicontrol(handle0,'Style','popupmenu','String',{'Likelihood','Chi^2'},'Visible','off',...
                        'Units','normalized',...
                        'Position',[0.572 0.97 0.1 0.018]);
                    
                    this.gui.showCal = uicontrol(handle0,'Style','checkbox','String','Show Calc.','Units','normalized',...
                        'Position',[0.6 0.437 0.08 0.018]);
                    
                    this.gui.showFit = uicontrol(handle0,'Style','checkbox','String','Show Fit','Units','normalized',...
                        'Position',[0.54 0.437 0.06 0.018]);
                    
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
                
                function createRightPanel()
                    
                    this.gui.rightPanel = uipanel(handle0,'Units','normalized','Position',[0.68 0.02 0.31 0.97]);
                    
                    this.gui.elementEditPanel = uipanel(handle0,'Title', 'Element Management', 'Visible', 'off', 'Units', 'normalized', 'Position',[0.685 0.03 0.3 0.95]);
                    
                end
                
                function createBasicInfoTalbe()
                    
                    rightPanel = this.gui.rightPanel;
                    
                    rowName = {'Beam Energy (keV)', 'Emission Energy (kev)', 'Slit Size (mm)', 'Detector Footprint (mm)'};
                    colName = {};
                    columnFormat = {'numeric'};
                    columnWidth = {120};
                    tableData = {10; 7.8; 0.024; 10.76};
                    
                    this.gui.basicInfoTable = uitable(rightPanel, 'Data', tableData, 'ColumnName', colName, ...
                        'ColumnFormat', columnFormat, 'ColumnEditable', true, 'Units','normalized', ...
                        'ColumnWidth',columnWidth,'RowName',rowName, 'RowStriping','off',...
                        'Position', [0.025 0.88 0.935 0.1], 'TooltipString', 'Press enter to update value.');
                    
                end
                
                function createLayersTable()
                    
                    rightPanel = this.gui.rightPanel;
                    
                    rowName = {'top', 'bottom'};
                    colName = {'Formula', 'ED', 'Depth (A)', 'Delete'};
                    colFormat = {'char', 'numeric', 'numeric', 'logical'};
                    colWidth = {130, 40, 60, 50};
                    heliumEd = 101325 / 8.314 / 298 / 1e3 * 6.02e23 * 1e-27 * 2;
                    tableData = {'He', heliumEd, Inf, false; 'H2O', 0.334, Inf, false};
                    
                    base = 0.85;
                    
                    uicontrol(rightPanel,'Style','text','String','Layer Structure:','Units','normalized','HorizontalAlignment','left', 'Position',[0.025 base 0.8 0.025]);
                    
                    this.gui.layerTable = uitable(rightPanel,'Data', tableData,'ColumnName', colName,...
                        'ColumnFormat', colFormat,'ColumnEditable', true(1, 6), 'Units', 'normalized',...
                        'ColumnWidth',colWidth,'RowName',rowName,'RowStriping','off',...
                        'Position', [0.025 base-0.15 0.935 0.15]);
                    
                    this.gui.addLayer = uicontrol(rightPanel,'Style','pushbutton','String', 'Add', 'Units','normalized', 'Position', [0.725 base-0.18 0.11 0.03]);
                    
                    this.gui.deleteLayer = uicontrol(rightPanel,'Style','pushbutton','String', 'Delete','Units','normalized', 'Position', [0.84 base-0.18 0.12 0.03]);
                    
                end
                
                function createParametersTable()
                    
                    rightPanel = this.gui.rightPanel;
                    
                    rowName = {'Angle-Offset','Scale-Factor','Background', 'Conc-bottom'};
                    colName = {'Min','Max','Start','Fix','Plot'};
                    colFormat = {'numeric','numeric','numeric','logical','logical'};
                    colWidth = {55 55 55 30 30};
                    tableData = {-0.0001, 0.0001, 0, false, false; 1, 1, 1, true, false; 1, 1, 1, true, false; 0, 0, 0, true, false};
                    
                    base = 0.665;
                    
                    this.gui.parametersTableTitle = uicontrol(rightPanel,'Style','text','String','Fitting Parameters:','Units','normalized','HorizontalAlignment','left', 'Position', [0.025 base 0.8 0.025]);
                    
                    this.gui.parametersTable = uitable(rightPanel,'Data', tableData,'ColumnName', colName,...
                        'ColumnFormat', colFormat,'ColumnEditable', [true true true true true],'Units','normalized',...
                        'ColumnWidth',colWidth,'RowName',rowName,'RowStriping','off', 'Position', [0.025 base-0.2 0.935 0.2]);
                    
                end
                
                function createFittingControls()
                    
                    rightPanel = this.gui.rightPanel;
                    
                    base = 0.43;
                    
                    this.gui.layerTableTitle = uicontrol(rightPanel,'Style','text','String', 'Fitting Control:','Units','normalized','HorizontalAlignment','left',...
                        'Position',[0.025 base 0.8 0.025]);
                    
                    this.gui.loadPara = uicontrol(rightPanel,'Style','pushbutton','String','Load Para','Units','normalized',...
                        'Position',[0.024 base-0.03 0.17 0.03]);
                    
                    this.gui.savePara = uicontrol(rightPanel,'Style','pushbutton','String','Save Para','Units','normalized',...
                        'Position',[0.19 base-0.03 0.17 0.03]);
                    
                    this.gui.stepInput = uicontrol(rightPanel,'Style','edit','String',20,'Units','normalized',...
                        'HorizontalAlignment','left','Position',[0.62 base-0.03 0.1 0.03]);
                    
                    this.gui.stepText = uicontrol(rightPanel,'Style','text','String','Steps','Units','normalized',...
                        'HorizontalAlignment','left','Position', [0.735 base-0.035 0.08 0.03]);
                    
                    this.gui.fitButton = uicontrol(rightPanel,'Style','pushbutton','String','Fit','Units','normalized',...
                        'Position',[0.82 base-0.03 0.15 0.03]);
                    
                    this.gui.withText = uicontrol(rightPanel,'Style','text','String','With','Units','normalized','HorizontalAlignment','left',...
                        'Position',[0.025 base-0.065 0.07 0.03]);
                    
                    this.gui.confidenceInput = uicontrol(rightPanel,'Style','edit','String','95','Units','normalized',...
                        'HorizontalAlignment','left','Position',[0.1 base-0.06 0.07 0.03]);
                    
                    this.gui.confidenceText = uicontrol(rightPanel,'Style','text','String','% confidence window','Units','normalized','HorizontalAlignment','left',...
                        'Position',[0.171 base-0.065 0.28 0.03]);
                    
                    this.gui.recordFitting = uicontrol(rightPanel,'Style','pushbutton','String','Record Fitting','Units','normalized',...
                        'Position',[0.452 base-0.06 0.22 0.03]);
                    
                    this.gui.updateStartButton = uicontrol(rightPanel,'Style','pushbutton','String','Update Starts','Units','normalized',...
                        'Position',[0.75 base-0.06 0.22 0.03]);
                    
                end
                
                function createOutputandSaveButtons()
                    
                    rightPanel = this.gui.rightPanel;
                    
                    this.gui.output = uicontrol(rightPanel,'Style','edit','Max',2,'HorizontalAlignment','left','Units','normalized',...
                        'Position',[0.03 0.07 0.935 0.29]);
                    
                    this.gui.clearOutput = uicontrol(rightPanel,'Style','pushbutton','String','Clear','Units','normalized',...
                        'Position',[0.82 0.038 0.15 0.03]);
                    
                    uicontrol(rightPanel,'Style','text','String','Save:','Units','normalized',...
                        'HorizontalAlignment','left','Position',[0.025 0.035 0.08 0.025]);
                    
                    this.gui.saveOutput = uicontrol(rightPanel,'Style','pushbutton','String','Output Text','Units','normalized',...
                        'Position',[0.024 0.007 0.2 0.03]);
                    
                    this.gui.saveUpperFigure = uicontrol(rightPanel,'Style','pushbutton','String','Upper Figure','Units','normalized',...
                        'Position',[0.234 0.007 0.2 0.03]);
                    
                    this.gui.saveLowerFigure = uicontrol(rightPanel,'Style','pushbutton','String','Lower Figure','Units','normalized',...
                        'Position',[0.444 0.007 0.2 0.03]);
                    
                    this.gui.saveData = uicontrol(rightPanel,'Style','pushbutton','String','Data & Fit','Units','normalized',...
                        'Position',[0.66 0.007 0.17 0.03]);
                    
                end
                
            end
            
            function connectViewAndController()
                
                % left panel
                this.gui.fileList.Callback = this.call.file;
                this.gui.loadButton.Callback = this.call.load;
                this.gui.deleteButton.Callback = this.call.delete;
                this.gui.angleList.Callback = this.call.angle;
                
                % middle panel
                this.gui.likelihoodChi2.Callback = this.call.likelihoodChi2;
                this.gui.showFit.Callback = this.call.showFit;
                this.gui.showCal.Callback = this.call.showCal;
                this.gui.startFitting.Callback = this.call.startFitting;
                
                % table callbacks
                this.gui.basicInfoTable.CellEditCallback = this.call.basicInfo;
                
                this.gui.layerTable.CellEditCallback = this.call.layer;
                this.gui.addLayer.Callback = this.call.addLayer;
                this.gui.deleteLayer.Callback = this.call.deleteLayers;
                
                this.gui.parametersTable.CellEditCallback = this.call.parametersTable;
                
                % fitting controls
                this.gui.loadPara.Callback = this.call.loadParameters;
                this.gui.savePara.Callback = this.call.saveParameters;
                this.gui.recordFitting.Callback = this.call.record;
                this.gui.fitButton.Callback = this.call.fit;
                this.gui.stepInput.Callback = this.call.stepInput;
                this.gui.confidenceInput.Callback = this.call.confidence;
                this.gui.updateStartButton.Callback = this.call.updateStarts;
                
                % output and save
                this.gui.saveData.Callback = this.call.saveDataAndFit;
                this.gui.saveUpperFigure.Callback = this.call.saveUpperFigure;
                this.gui.saveLowerFigure.Callback = this.call.saveLowerFigure;
                this.gui.saveOutput.Callback = this.call.saveOutput;
                this.gui.clearOutput.Callback = this.call.clear;
                
            end
            
        end
        
        function feedback = model(this, state, trigger, varargin)
            
            switch state
                case 'empty'
                    switch trigger
                        case 'load-file'
                            files = varargin{1};
                            paths = varargin{2};
                            loadNewData(files, paths);
                    end
                case 'explore'
                    switch trigger
                        case 'delete-file'
                            deleteSelectedFiles();
                        case 'load-file'
                            files = varargin{1};
                            path = varargin{2};
                            loadNewData(files, path);
                        case 'delete-layers'
                            this.processInputs('layer');
                        case 'inputs'
                            what = varargin{1};
                            this.processInputs(what);
                        case 'switch-element'
                            newElement = varargin{1};
                            switch newElement
                                case 'none'
                                    % do nothing
                                case 'new'
                                    
                                otherwise
                                    if ~strcmp(newElement, this.const.element)
                                        this.const.element = newElement;
                                        fitSpectraToElement();
                                    end
                            end
                    end
                case 'fitting'
                    switch trigger
                        case 'start-fitting'
                            
                    end
            end
            
            % model functions
            
            function deleteSelectedFiles()
                
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
                    
                    feedback = n;
                    
                end
                
            end
            
            function loadNewData(files, paths)
                
                if ~isempty(files)
                    
                    % convert to cell array
                    if isa(files, 'char')
                        files = {files};
                        paths = {paths};
                    else
                        if isa(paths, 'char')
                            paths = repmat({paths}, 1, length(files));
                        end
                    end
                    
                    % load data
                    n = length(files);
                    
                    newData = cell(1, n);
                    for i = 1:n
                        newData{i} = XeSignal(fullfile(paths{i}, files{i}), this.config.ScatteringFactorFolder);
                    end
                    
                    this.data = [this.data, newData];
                    
                end
                
            end
            
            function fitSpectraToElement()
            
                element = this.const.element;
                lineshape = this.const.lineShape;
                
                for i = 1 : length(this.data)
                    
                    this.data{i}.selectElement(element, lineshape);
                    
                end
                
            end
            
        end
        
        function view(this, state, trigger, varargin)
            
            switch state
                case 'empty'
                    switch trigger
                        case 'initialize'
                            switchToExplore();
                        case 'load-file'
                            olds = varargin{1};
                            news = varargin{2};
                            this.gui.fileList.String = [olds; news];
                            displayAngles();
                            replot('both');
                            this.gui.startFitting.Enable = 'on';
                    end
                case 'explore'
                    switch trigger
                        case 'file'
                            displayAngles();
                            replot('lower');
                        case 'angle'
                            replot('lower');
                        case 'delete-file'
                            indices = varargin{1};
                            deleteSelectedFiles(indices);
                            replot('lower');
                        case 'load-file'
                            olds = varargin{1};
                            news = varargin{2};
                            this.gui.fileList.String = [olds; news];
                        case 'start-fitting'
                            switchElementFitting('off');
                            replot('lower');
                        otherwise
                            warning('Case not fonund for XeRayGUI.view() - whole-spectra state.');
                    end
                case 'fitting'
                    switch trigger
                        case 'angle'
                            replot('both');
                        case 'start-fitting'
                            switchElementFitting('on');
                        case 'show-cal'
                            replot('lower');
                        case 'layer-table'
                            replot('lower');
                        case 'basic-info'
                            replot('lower');
                        case 'parameter-table'
                            what = varargin{1};
                            replot(what);
                        case 'add-layer'
                            addLayer();
                        case 'add-layer-update'
                            replot('lower');
                        case 'delete-layers'
                            deleteLayers();
                        case 'delete-layers-update'
                            replot('lower');
                        case 'load-parameters'
                            loadParameters();
                        case 'load-parameters-update'
                            replot('lower');
                        case 'fit'
                            this.gui.showFit.Enable = 'on';
                            this.gui.showFit.Value = 1;
                            replot('lower');
                            replot('upper');
                            recordFittingResults(0);
                        case 'show-fit'
                            replot('lower');
                        case 'update-start'
                            replot('lower');
                        case 'clear-output'
                            this.gui.output.String = {};
                        case 'record-results'
                            confidence = str2double(this.gui.confidenceInput.String) / 100;
                            recordFittingResults(confidence);
                        case 'confidence-input'
                            confidence = str2double(this.gui.confidenceInput.String) / 100;
                            recordFittingResults(confidence);
                    end
            end
            
            % view functions
            
            function deleteSelectedFiles(indices)
                
                fileList = this.gui.fileList;
                angleList = this.gui.angleList;
                if sum(indices)
                    fileList.String = fileList.String(indices);
                    fileList.Value = 1;
                    angleList.Value = 1;
                    displayAngles();
                else
                    fileList.Value = 1;
                    fileList.String = {};
                    angleList.String = {};
                end
                
            end
            
            function switchToExplore()
                
                set(findall(this.gui.rightPanel, '-property', 'Enable'), 'Enable', 'off');
                this.gui.fileList.Enable = 'on';
                this.gui.showFit.Enable = 'off';
                this.gui.showCal.Enable = 'off';
                this.gui.startFitting.Enable = 'off';
                this.gui.startFitting.Value = 0;
                
            end
            
            function switchElementFitting(status)
                
                if strcmp(status, 'on')
                    antiStatus = 'off';
                else
                    antiStatus = 'on';
                    this.gui.showFit.Enable = 'off';
                    this.gui.showFit.Value = 0;
                    this.gui.showCal.Value = 0;
                end
                
                set(findall(this.gui.rightPanel, '-property', 'Enable'), 'Enable', status);
                this.gui.showCal.Enable = status;
                this.gui.startFitting.Enable = 'on';
                
                this.gui.fileList.Enable = antiStatus;
                this.gui.elementPopup.Enable = antiStatus;
                this.gui.lineShape.Enable = antiStatus;
                this.gui.removeBackground.Enable = antiStatus;
                this.gui.loadButton.Enable = antiStatus;
                this.gui.deleteButton.Enable = antiStatus;
                
            end
            
            function loadParameters()
                
                [filename, pathname] = uigetfile('*.xeraypara', 'Load a saved parameter file.');
                            
                if ~isnumeric(filename)
                    file = fullfile(pathname, filename);
                    
                    para = loadjson(file);
                    
                    
                    % load the basic info table
                    this.gui.basicInfoTable.Data = num2cell(para.basic);
                    
                    % load the layer table
                    dat = para.layer;
                    if ~ischar(dat{1})
                        n = length(dat);
                        m = length(dat{1});
                        newdata = cell(n, m);
                        for i = 1 : n
                            newdata(i, :) = dat{i};
                        end
                        dat = newdata;
                    end
                    
                    for i = 1 : size(dat, 1)
                        dat{i, end} = logical(dat{i, end});
                    end
                    
                    this.gui.layerTable.Data = dat;
                    assignLayerTableRowName();
                    
                    % load the parameters table
                    dat = num2cell(para.parameter);
                    n = size(dat, 1);
                    
                    for i = 1 : n
                        dat{i, 4} = logical(dat{i, 4});
                        dat{i, 5} = logical(dat{i, 5});
                    end
                    
                    this.gui.parametersTable.Data = dat;
                    assignParameterTableRowName();
                end
            end
            
            function displayAngles()
            
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
            
            function assignLayerTableRowName()
                
                table = this.gui.layerTable;
                n = size(table.Data, 1);
                
                rowNames = cell(1, n);
                for i = 1 : n
                    rowNames{i} = num2str(i);
                end
                
                table.RowName = rowNames;
                
            end
        
            function assignParameterTableRowName()
                
                table = this.gui.parametersTable;
                n = size(table.Data, 1);
                rowNames = cell(n, 1);
                rowNames(1:3) = {'Angle-Offset', 'Scale-Factor', 'Background'};
                
                for i = 4 : n
                    rowNames{i} = strcat('Conc-', num2str(i-3));
                end
                
                table.RowName = rowNames;
                
            end
            
            function n = chosenPlotPara()
                
                n = sum(cell2mat(this.gui.parametersTable.Data(:, end)));
                
            end
            
            function indices = indicesInFit()
                
                dat = cell2mat(this.gui.parametersTable.Data(:, 4:5));
                fixed = ~dat(:, 1);
                plotting = dat(:, 2);
                
                if sum(plotting)
                    indices = zeros(1, sum(plotting));
                    plotting = find(plotting);
                    for i = 1 : length(plotting)
                        indices(i) = sum(fixed(1 : plotting(i)));
                    end
                end
                
            end
            
            function [n, m, rankn, rankm] = getSelectionIndex()
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
                
                cn = cumsum(dataLengths(fileList.Value));
                
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
            
            function [fileIndex, angleIndices] = getSelectedSignalIndices()
                
                [n, m, ~, ~] = getSelectionIndex();
                
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
        
            function [styles1, legends1, styles2, legends2] = getSpectraStylesAndLegends()
                
                
                angleList = this.gui.angleList;
                fileList = this.gui.fileList;
                
                %obtain line spec for plotting, and legends
                styles1 = cell(size(angleList.Value));
                legends1 = styles1;
                
                [~,~,rankn,rankm] = getSelectionIndex();
                rankn = mod(rankn,length(this.const.symbols));
                rankn(rankn==0) = length(this.const.symbols);
                rankm = mod(rankm,length(this.const.colors));
                rankm(rankm==0) = length(this.const.colors);
                
                for i = 1:length(angleList.Value)
                    styles1{i} = strcat(this.const.symbols(rankn(i)),this.const.colors(rankm(i)));
                    legends1{i} = angleList.String{angleList.Value(i)};
                end
                
                uniqueN = unique(rankn,'stable');
                styles2 = cell(size(uniqueN));
                legends2 = styles2;
                for i = 1:length(uniqueN)
                    styles2{i} = this.const.symbols(uniqueN(i));
                    legends2{i} = fileList.String{fileList.Value(uniqueN(i))};
                end
                
            end
        
            function lengths = dataLengths(indices)
                
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
        
            function starts = obtainStarts()
                
                mat = cell2mat(this.gui.parametersTable.Data(:, 1:3));
                starts = mat(:, 3)';
                
            end
            
            function addLayer()
                
                this.gui.showFit.Value = false;
                this.gui.showFit.Enable = 'off';
                
                % update layers table
                table = this.gui.layerTable;
                table.Data = [table.Data(1, :); {'H2O', 0.334, 1, false}; table.Data(2:end, :)];
                n = size(table.Data, 1) -2;
                layerName = strcat('layer-', num2str(n));
                table.RowName = [table.RowName(1); layerName; table.RowName(2:end)];
                
                % update parameters table
                table = this.gui.parametersTable;
                table.Data = [table.Data(1:3, :); {0, 0, 0, true, false}; table.Data(4:end, :)];
                table.RowName = [table.RowName(1:3); strcat('Conc-', num2str(n)); table.RowName(4:end)];
                
            end
            
            function deleteLayers()
                
                table = this.gui.layerTable;
                
                sel = cell2mat(table.Data(:, end));
                n = sum(sel);
                if n
                    sel = ~sel;
                    table.Data = table.Data(sel, :);
                    table.RowName = table.RowName(~sel);
                    
                    % delete the layers from parameters table
                    table = this.gui.parametersTable;
                    location = find(~sel) + 3;
                    sel = true(size(table.Data, 1), 1);
                    sel(location) = false;
                    table.Data = table.Data(sel, :);
                    table.RowName = table.RowName(sel);
                    
                end
                
            end
            
            function recordFittingResults(confidence)
                
                if nargin == 1
                    confidence = 0;
                end
                
                oldtext = this.gui.output.String;
                
                n = this.gui.fileList.Value;
                fits = this.data{n}.fit;
                
                try
                    m = length(fits.one.parameters);
                    if m == 0
                        m = -3;
                    end
                catch
                    m = -3;
                end
                
                text = cell(7+m, 1);
                
                text{1} = '--------------------------------------------------------------------';
                text{2} = sprintf('%s %s', '#Time stamp:', datestr(datetime));
                text{3} = sprintf('%s%s%s', '#Fitted parameters: (', catStringCellArrayWithComma(fits.one.parameters), ')');
                text{4} = '';
                
                if m
                    text{5} = '#Fitting report';
                    text{6} = sprintf('%s %f', '#Best chi^2:', fits.all.chi2);
                    if confidence
                        text{7} = sprintf('%8s%15s%20s%10s%5.3f%s', '', 'TRR', 'Brute Force', 'Error(', confidence, ')');
                        multiplier = norminv((1-confidence)/2+confidence, 0, 1);
                    else
                        text{7} = sprintf('%8s%15s%20s%15s', '', 'TRR', 'Brute Force', 'Adjusted Std');
                        multiplier = 1;
                    end
                    for i = 8 : 7+m
                        index = i - 7;
                        paraLocation = fits.location();
                        paraIndex = paraLocation(index);
                        text{i} = sprintf('%-13s%10f %10f %10f',fits.one.parameters{index}, fits.all.P(paraIndex), fits.one.value(index), multiplier*fits.one.adjustedStd(index));
                    end
                end
                
                if ~isempty(oldtext)
                    text = [text;oldtext];
                end
                
                this.gui.output.String = text;
                
            end
            
            % plot functions
        
            function replot(what)
                
                if nargin == 0
                    what = 'both';
                end
                
                switch what
                    case 'upper'
                        upperPlot();
                    case 'lower'
                        lowerPlot();
                    case 'both'
                        upperPlot();
                        lowerPlot();
                    otherwise
                        warning('Case not found for XeRayGui.replot()');
                end
                
                function upperPlot()
                    
                    if isempty(this.gui.fileList.String)
                        emptyFigures(1);
                    else
                        switch chosenPlotPara()
                            case 0
                                emptyFigures(1);
                            case 1
                                switch this.gui.likelihoodChi2.Value
                                    case 1
                                        plotOneLikelihood();
                                    case 2
                                        plotOneChi2();
                                end
                            case 2
                                switch this.gui.likelihoodChi2.Value
                                    case 1
                                        plotTwoLikelihood();
                                    case 2
                                        plotTwoChi2();
                                end
                        end
                    end
                    
                end
                
                function lowerPlot()
                    
                    ax = this.gui.ax2;
                    
                    if isempty(this.data)
                        emptyFigures(2);
                    else
                        switch this.gui.showCal.Value
                            case 0
                                switch this.gui.showFit.Value
                                    case 0
                                        plotSignal();
                                    case 1
                                        plotSignal();
                                        hold(ax, 'on');
                                        plotFit();
                                        legends = [ax.Legend.String, {'Fit'}];
                                        legend(ax, legends);
                                        hold(ax, 'off');
                                end
                            case 1
                                switch this.gui.showFit.Value
                                    case 0
                                        plotSignal();
                                        hold(ax, 'on');
                                        plotCalculation();
                                        legends = [ax.Legend.String, {'Calculation'}];
                                        legend(ax, legends);
                                        hold(ax, 'off');
                                    case 1
                                        plotSignal();
                                        hold(ax, 'on');
                                        plotCalculation();
                                        plotFit();
                                        legends = [ax.Legend.String, {'Calculation', 'Fit'}];
                                        legend(ax, legends);
                                        hold(ax, 'off');
                                end
                        end
                    end
                    
                end
                
                function emptyFigures(index)
                    
                    switch nargin
                        case 0
                            plot(this.gui.ax1, 1);
                            plot(this.gui.ax2, 1);
                        case 1
                            switch index
                                case 1
                                    plot(this.gui.ax1, 1);
                                case 2
                                    plot(this.gui.ax2, 1);
                            end
                    end
                    
                end
            
                function plotSignal()
                    
                    ax = this.gui.ax2;
                    
                    [~, ~, styles, legends] = getSpectraStylesAndLegends();
                    [n, m] = getSelectedSignalIndices();
                    
                    sel = true(size(n));
                    
                    hold(ax, 'off');
                    
                    for i = 1:length(n)
                        if isempty(m{i})
                            sel(i) = false;
                        end
                        xdata = this.data{n(i)}.rawdata.angle(m{i});
                        ydata = this.data{n(i)}.rawdata.signal(m{i});
                        yerror = this.data{n(i)}.rawdata.signalError(m{i});
                        errorbar(ax, xdata, ydata, yerror, styles{i}, 'markersize', 8, 'linewidth', 2);
                        if i == 1
                            hold(ax, 'on');
                        end
                    end
                    
                    selectedLegends = legends(sel);
                    
                    xlabel(ax, 'Angle (radians)');
                    ylabel(ax, 'Fluorescence Intensity (a.u.)');
                    title(ax, sprintf('%s %s', this.const.element, 'Fluorescence'));
                    legend(ax, selectedLegends);
                    hold(ax, 'off');
                    
                end
                
                function plotCalculation()
                    
                    ax = this.gui.ax2;
                    
                    dataset = this.data{this.gui.fileList.Value(1)};
                    starts = obtainStarts();
                    
                    angles = dataset.rawdata.angle(this.gui.angleList.Value);
                    
                    if length(angles) == 1
                        fineAngleRange = linspace(angles * 0.99, angles * 1.01, 2);
                    else
                        fineAngleRange = linspace(min(angles), max(angles), 50);
                    end
                    
                    calculated = dataset.system.calculateSignalCurve(starts, fineAngleRange);
                    plot(ax, fineAngleRange, calculated, '-', 'linewidth', 2);
                    
                end
            
                function plotOneLikelihood()
                    
                    n = indicesInFit();
                    dataset = this.data{this.gui.fileList.Value(1)};
                    ax = this.gui.ax1;
                    
                    xdata = dataset.fit.one.para(:, n);
                    ydata = dataset.fit.one.likelihood(:, n);
                    plot(ax, xdata, ydata, 'o', 'linewidth', 2);
                    
                    hold(ax, 'on');
                    
                    xdata = dataset.fit.one.likelihoodPara(:, n);
                    ydata = dataset.fit.one.likelihoodCurve(:, n);
                    plot(ax, xdata, ydata, '-', 'linewidth', 2)
                    
                    hold(ax, 'off');
                    
                    legend(ax, {'Likelihood', 'Gaussian Fit'});
                    xlabel(ax, dataset.fit.one.parameters{n});
                    ylabel(ax, 'Likelihood');
                    title(ax, 'Gaussian Likelihood Fit');
                    
                end
                
                function plotTwoLikelihood()
                    
                    n = indicesInFit();
                    fits = this.data{this.gui.fileList.Value(1)}.fit.two{n(1), n(2)};
                    
                    xdata = fits.para1;
                    ydata = fits.para2;
                    zdata = fits.likelihood;
                    contourData = fits.contour;
                    
                    ax = this.gui.ax1;
                    
                    contourf(ax, xdata, ydata, zdata);
                    colorbar(ax);
                    
                    hold(ax, 'on');
                    plot(ax, contourData(1, :), contourData(2, :), 'r-', 'linewidth', 2);
                    hold(ax, 'off');
                    
                    xlabel(ax, fits.parameters{1});
                    ylabel(ax, fits.parameters{2});
                    legend(ax, 'Joint Likelihood', sprintf('%.2f %s', fits.confidence, 'Confidence Window'));
                    title(ax, sprintf('%s %s %s %s','Joint Likelihood of', fits.parameters{1}, 'and', fits.parameters{2}));
                    
                end
                
                function plotOneChi2()
                    
                    n = indicesInFit();
                    dataset = this.data{this.gui.fileList.Value(1)};
                    ax = this.gui.ax1;
                    
                    xdata = dataset.fit.one.para(:, n);
                    ydata = dataset.fit.one.chi2(:, n);
                    plot(ax, xdata, ydata, 'o-', 'linewidth', 2);
                    
                    legend(ax, '\chi^2');
                    xlabel(ax, dataset.fit.one.parameters{n});
                    ylabel(ax, '\chi^2');
                    title(ax, '\chi^2');
                    
                end
                
                function plotTwoChi2()
                    
                    n = indicesInFit();
                    fits = this.data{this.gui.fileList.Value(1)}.fit.two{n(1), n(2)};
                    
                    xdata = fits.para1;
                    ydata = fits.para2;
                    zdata = fits.chi2;
                    
                    ax = this.gui.ax1;
                    
                    contourf(ax, xdata, ydata, zdata);
                    colorbar(ax);
                    
                    xlabel(ax, fits.parameters{1});
                    ylabel(ax, fits.parameters{2});
                    legend(ax, 'Joint \chi^2');
                    title(ax, sprintf('%s %s %s %s','Joint \chi^2 of', fits.parameters{1}, 'and', fits.parameters{2}));
                    
                end
                
                function plotFit()
                    
                    ax = this.gui.ax2;
                    
                    dataset = this.data{this.gui.fileList.Value(1)};
                    angles = dataset.rawdata.angle(this.gui.angleList.Value);
                    
                    xdata = linspace(min(angles), max(angles), 100);
                    ydata = dataset.system.calculateSignalCurve(dataset.fit.all.P, xdata);
                    
                    plot(ax, xdata, ydata, 'b-', 'linewidth', 2);
                    
                end
                
            end
            
        end
        
        function control(this, trigger, varargin)
            
            state = getGuiState();
            
            switch state
                case 'empty'
                    switch trigger
                        case 'load-file'
                            if nargin >= 3
                                files = varargin{1};
                                [olds, news, paths] = obtainNewFilesViaArgs(files);
                                this.model(state, trigger, news, paths);
                                this.view(state, trigger, olds, news);
                            else
                                [olds, news, path] = obtainNewFilesViaUI();
                                if ~isempty(news)
                                    this.model(state, trigger, news, path);
                                    this.view(state, trigger, olds, news);
                                end
                            end
                        case 'initialize'
                            this.view(state, trigger);
                    end
                case 'explore'
                    switch trigger
                        case 'file'
                            this.view(state, trigger);
                        case 'angle'
                            this.view(state, trigger);
                        case 'delete-file'
                            indices = this.model(state, trigger);
                            this.view(state, trigger, indices);
                        case 'load-file'
                            [olds, news, path] = obtainNewFilesViaUI();
                            if ~isempty(news)
                                this.model(state, trigger, news, path);
                                this.view(state, trigger, olds, news);
                            end
                        case 'start-fitting'
                            this.view(state, trigger);
                    end
                case 'fitting'
                    switch trigger
                        case 'angle'
                            this.view(state, trigger);
                        case 'start-fitting'
                            processInputs();
                            this.view(state, trigger);
                        case 'show-cal'
                            this.view(state, trigger);
                        case 'basic-info'
                            eventdata = varargin{1};
                            if editBasicInfo(eventdata)
                                this.view(state, trigger);
                            end
                        case 'layer-table'
                            eventdata = varargin{1};
                            if layerTableInputsAreGood(eventdata)
                                processInputs();
                                this.view(state, trigger);
                            end
                        case 'parameter-table'
                            eventdata = varargin{1};
                            flag = parameterTableInputIndicator(eventdata);
                            switch flag
                                case 1
                                    processInputs();
                                    this.view(state, trigger, 'lower');
                                case 2
                                    this.view(state, trigger, 'upper');
                            end
                        case 'add-layer'
                            this.view(state, trigger);
                            processInputs();
                            %this.view(state, 'add-layer-update');
                        case 'delete-layers'
                            this.view(state, trigger);
                            processInputs();
                            this.view(state, 'delete-layers-update');
                        case 'load-parameters'
                            this.view(state, 'load-parameters');
                            processInputs();
                            this.view(state, 'load-parameters-update');
                        case 'save-parameters'
                            saveParameters();
                        case 'step-input'
                            editStepInput();
                        case 'fit'
                            if runFitting()
                                this.view(state, 'fit');
                            end
                        case 'show-fit'
                            this.view(state, 'show-fit');
                        case 'update-start'
                            updateStarts();
                            this.view(state, trigger);
                        case 'save-output'
                            saveOutput();
                        case 'save-upper-figure'
                            saveUpperFigure();
                        case 'save-lower-figure'
                            saveLowerFigure();
                        case 'save-data'
                            saveDataAndFit();
                        case 'clear-output'
                            this.view(state, trigger);
                        case 'record-results'
                            try
                                this.view(state, 'record-results');
                            catch
                                beep;
                            end
                        case 'confidence-input'
                            this.view(state, 'confidence-input');
                    end
            end
            
            % define states of the GUI
            
            function state = getGuiState()
                
                if isempty(this.gui.fileList.String)
                    state = 'empty';
                else
                    if this.gui.startFitting.Value
                        state = 'fitting';
                    else
                        state = 'explore';
                    end
                end
                
            end
            
            function [olds, news, path] = obtainNewFilesViaUI()
                
                [news, path] = uigetfile('*', 'Select fluorescence data files', 'MultiSelect', 'on');
                olds = this.gui.fileList.String;
                
                if isnumeric(news)
                    news = [];
                    path = [];
                else
                    if isa(news, 'char')
                        news = {news};
                    end
                    %remove files aleady loaded
                    if ~isempty(olds)
                        if isa(olds, 'char') %if only one file before loading, convert to cell array
                            olds = {olds};
                        end
                        
                        sel = ones(size(news));
                        for i = 1:length(news)
                            for j = 1:length(olds)
                                if strcmp(olds{j}, news{i})
                                    sel(i) = 0;
                                end
                            end
                        end
                        sel = logical(sel);
                        news = news(sel);
                    end
                end
                
            end
            
            function [olds, news, paths] = obtainNewFilesViaArgs(files)
                
                if isa(files, 'char')
                    files = {files};
                end
                
                news = cell(1, length(files));
                paths = news;
                for i = 1 : length(files)
                    [temppath, name, extension] = fileparts(files{i});
                    news{i} = [name, extension];
                    paths{i} = temppath;
                end
                
                olds = this.gui.fileList.String;
                
                if ~isempty(olds)
                    if isa(olds, 'char') %if only one file before loading, convert to cell array
                        olds = {olds};
                    end
                    
                    sel = ones(size(news));
                    for i = 1:length(news)
                        for j = 1:length(olds)
                            if strcmp(olds{j}, news{i})
                                sel(i) = 0;
                            end
                        end
                    end
                    sel = logical(sel);
                    news = news(sel);
                end
                
            end
        
            function processInputs(what)
                
                dataset = this.data{this.gui.fileList.Value};
                
                if nargin == 0
                    what = 'all';
                end
                
                switch what
                    case 'basic-info'
                        processBasicInfo();
                    case 'layer'
                        processLayerStructure();
                        processFittingParameters();
                    case {'parameter', 'step'}
                        processFittingParameters();
                    case 'confidence'
                    case 'all'
                        processBasicInfo();
                        processLayerStructure();
                        processFittingParameters();
                end
                
                function processBasicInfo()
                    
                    basicInfo = this.gui.basicInfoTable.Data;
                    incidenceEnergy = basicInfo{1};
                    emissionEnergy = basicInfo{2};
                    slit = basicInfo{3};
                    foot = basicInfo{4};
                    
                    dataset.createPhysicalSystem(incidenceEnergy, emissionEnergy, slit, foot);
                    
                end
                
                function processLayerStructure()
                    
                    dataset.system.pop();
                    
                    dat = this.gui.layerTable.Data;
                    n = size(dat, 1);
                    
                    for i = n : -1 : 1
                        if isempty(dat{i, 1})
                            parameters = dat(i, [2, 3]);
                        else
                            parameters = dat(i, [2, 3, 1]);
                        end
                        dataset.system.insert(1, parameters{:});
                    end
                    
                end
                
                function processFittingParameters()
                    
                    table = this.gui.parametersTable;
                    mat = cell2mat(table.Data(:, 1:3));
                    
                    lower = mat(:, 1)';
                    upper = mat(:, 2)';
                    
                    steps = str2double(this.gui.stepInput.String);
                    
                    if isempty(dataset.fit)
                        dataset.fit = XeFits(lower, upper, steps);
                    else
                        dataset.fit.updateBounds(lower, upper, steps);
                    end
                    
                end
                
            end
                
            function flag = layerTableInputsAreGood(eventdata)
                
                flag = true;
                
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
                                flag = false;
                                table.Data{ind(1), ind(2)} = olddata;
                                raiseErrorDialog(EM.message);
                            end
                        end
                    case 2
                        if str2double(newdata) <= 0
                            flag = false;
                            table.Data{ind(1), ind(2)} = olddata;
                            raiseErrorDialog('Electron density must be larger than 0.');
                        end
                    case 3
                        switch ind(1)
                            case n
                                flag = false;
                                table.Data{ind(1), ind(2)} = olddata;
                            otherwise
                                if str2double(newdata) <= 0
                                    flag = false;
                                    table.Data{ind(1), ind(2)} = olddata;
                                    raiseErrorDialog('Depth must be larger than 0.');
                                end
                        end
                    case 4
                        if ind(1) == n
                            flag = false;
                            table.Data{ind(1), ind(2)} = false;
                            raiseErrorDialog('Last layer cannot be deleted.');
                        end
                end
                
            end
                
            function flag = parameterTableInputIndicator(eventdata)
                
                % flag: 0 - inputs are bad; 1 - should update lower figure;
                % 2 - should update upper figure
                
                flag = 0;
                
                ind = eventdata.Indices;
                olddata = eventdata.PreviousData;
                newdata = eventdata.EditData;
                
                table = this.gui.parametersTable;
                numeric = ~isnan(table.Data{ind(1), ind(2)});
                
                switch ind(2)
                    case 1
                        if numeric
                            if angleOffsetWithinLimit()
                                flag = 1;
                                adjustBounds('min');
                            else
                                flag = 0;
                                table.Data{ind(1), ind(2)} = olddata;
                                raiseErrorDialog('Offset cannot be smaller than the smallest angle.');
                            end
                        else
                            flag = 0;
                            table.Data{ind(1), ind(2)} = olddata;
                        end
                    case 2
                        if numeric
                            if angleOffsetWithinLimit()
                                flag = 1;
                                adjustBounds('max');
                            else
                                flag = 0;
                                table.Data{ind(1), ind(2)} = olddata;
                                raiseErrorDialog('Offset cannot be smaller than the smallest angle.');
                            end
                        else
                            flag = 0;
                            table.Data{ind(1), ind(2)} = olddata;
                        end
                    case 3
                        if numeric
                            if angleOffsetWithinLimit()
                                flag = 1;
                                adjustBounds('start');
                            else
                                flag = 0;
                                table.Data{ind(1), ind(2)} = olddata;
                                raiseErrorDialog('Offset cannot be smaller than the smallest angle.');
                            end
                        else
                            flag = 0;
                            table.Data{ind(1), ind(2)} = olddata;
                        end
                    case 4
                        if newdata
                            table.Data{ind(1), 1} = table.Data{ind(1), 3};
                            table.Data{ind(1), 2} = table.Data{ind(1), 3};
                            table.Data{ind(1), end} = false;
                            flag = 2;
                        else
                            flag = 0;
                            switch ind(1)
                                case 1
                                    table.Data{ind(1), 1} = table.Data{ind(1), 3} - 1e-4;
                                    table.Data{ind(1), 2} = table.Data{ind(1), 3} + 1e-4;
                                case 2
                                    table.Data{ind(1), 1} = table.Data{ind(1), 3} * 0.9;
                                    table.Data{ind(1), 2} = table.Data{ind(1), 3} * 1.1;
                                case 3
                                    table.Data{ind(1), 1} = table.Data{ind(1), 3} - 1;
                                    table.Data{ind(1), 2} = table.Data{ind(1), 3} + 1;
                                otherwise
                                    if table.Data{ind(1), ind(2)} == 0
                                        table.Data{ind(1), 1} = 0;
                                        table.Data{ind(1), 2} = 1;
                                    else
                                        table.Data{ind(1), 1} = table.Data{ind(1), ind(2)} * 0.5;
                                        table.Data{ind(1), 2} = table.Data{ind(1), ind(2)} * 1.5;
                                    end
                            end
                        end
                    case 5
                        if ~isParameterFitted(ind(1))
                            flag = 0;
                            table.Data{ind(1), ind(2)} = false;
                        else
                            flag = 2;
                            checked = cell2mat(table.Data(:, end));
                            if sum(checked) > 2
                                checked(ind(1)) = 0;
                                location = find(checked, 1);
                                checked(location) = 0;
                                checked(ind(1)) = 1;
                                checkedCell = cell(size(checked));
                                for i = 1 : length(checked)
                                    checkedCell{i} = logical(checked(i));
                                end
                                table.Data(:, end) = checkedCell;
                            end
                        end
                end
                
                function adjustBounds(what)
                    
                    matrix = cell2mat(table.Data(:, 1:3));
                    mins = matrix(:, 1);
                    maxs = matrix(:, 2);
                    starts = matrix(:, 3);
                    
                    % adjust bounds
                    
                    switch what
                        case 'min'
                            loc = find(mins > maxs);
                            if ~isempty(loc)
                                for j = loc
                                    table.Data{j, 2} = table.Data{j, 1};
                                    table.Data{j, 3} = table.Data{j, 1};
                                end
                            else
                                loc = find(mins > starts);
                                if ~isempty(loc)
                                    for j = loc
                                        table.Data{j, 3} = table.Data{j, 1};
                                    end
                                end
                            end
                        case 'max'
                            loc = find(mins > maxs);
                            if ~isempty(loc)
                                for j = loc
                                    table.Data{j, 1} = table.Data{j, 2};
                                    table.Data{j, 3} = table.Data{j, 2};
                                end
                            else
                                loc = find(maxs < starts);
                                if ~isempty(loc)
                                    for j = loc
                                        table.Data{j, 3} = table.Data{j, 2};
                                    end
                                end
                            end
                        case 'start'
                            loc = find(starts > maxs);
                            if ~isempty(loc)
                                for j = loc
                                    table.Data{j, 2} = table.Data{j, 3};
                                end
                            else
                                loc = find(starts < mins);
                                if ~isempty(loc)
                                    for j = loc
                                        table.Data{j, 1} = table.Data{j, 3};
                                    end
                                end
                            end
                    end
                    
                    % check the fixed parameters
                    
                    n = size(table.Data, 1);
                    
                    matrix = cell2mat(table.Data(:, 1:3));
                    mins = matrix(:, 1);
                    maxs = matrix(:, 2);
                    
                    fixed = mins == maxs;
                    
                    for j = 1 : n
                        table.Data{j, 4} = fixed(j);
                    end
                    
                end
                
            end
            
            function saveParameters()
                
                jsondata.basic = this.gui.basicInfoTable.Data;
                jsondata.layer = this.gui.layerTable.Data;
                jsondata.parameter = this.gui.parametersTable.Data;
                
                currentFile = this.gui.fileList.String{this.gui.fileList.Value(1)};
                [~, name, ~] = fileparts(currentFile);
                
                filename = [name, '.xeraypara'];
                
                %savejson('', jsondata, name);
                text = savejson('', jsondata);
                
                msg = sprintf('%s %s %s','Save fitting parameters of', name, 'as');
                [filename, pathname] = uiputfile(filename, msg);
                if ~isnumeric(filename)
                    file = fullfile(pathname, filename);
                    fid = fopen(file, 'w');
                    fprintf(fid, text);
                    fclose(fid);
                end
                
            end
            
            function flag = runFitting()
                
                flag = false;
                
                n = this.gui.angleList.Value;
                dataset = this.data{this.gui.fileList.Value(1)};
                m = sum(dataset.fit.lower ~= dataset.fit.upper);
                if n < m + 1
                    h = errordlg('Select at least one more data point than the number of parameters being fitted.', 'Closing in 5 s...');
                    pause(5);
                    try
                        close(h);
                    catch
                    end
                else
                    processInputs();
                    
                    h = msgbox({'Fitting in process...', 'Do not close this window.'});
                    
                    dataset.runFluoFitting();
                    
                    flag = true;
                    
                    try
                        close(h);
                    catch
                    end
                end
                
                
            end
        
            function flag = angleOffsetWithinLimit()
                
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
        
            function flag = isParameterFitted(n)
                
                flag = false;
                
                parameters = this.gui.parametersTable.RowName;
                parameter = parameters{n};
                
                dataset = this.data{this.gui.fileList.Value(1)};
                if ~isempty(dataset.fit.one) && any(strcmp(dataset.fit.one.parameters, parameter))
                    flag = true;
                end
                
            end
            
            function raiseErrorDialog(message)
                
                h = errordlg({message, 'Closing in 5s...'});
                pause(5);
                try
                    close(h);
                catch
                end
                
            end
            
            function flag = editBasicInfo(eventdata)
                
                table = this.gui.basicInfoTable;
                ind = eventdata.Indices;
                olddata = eventdata.PreviousData;
                
                if isnan(table.Data{ind(1), ind(2)})
                    table.Data{ind(1), ind(2)} = olddata;
                    flag = false;
                else
                    processInputs();
                    flag = true;
                end
                
            end
            
            function editStepInput()
                
                n = str2double(this.gui.stepInput.String);
                
                if n < 5
                    this.gui.stepInput.String = 20;
                    h = warndlg('At least 5 steps for the parameters being fitted.');
                    try
                        close(h);
                    catch
                    end
                else
                    this.data{this.gui.fileList.Value(1)}.fit.steps = n;
                end
                
            end
            
            function updateStarts()
                
                table = this.gui.parametersTable;
                try
                    dat = this.data{this.gui.fileList.Value(1)}.fit.all.P;
                    table.Data(:, 3) = num2cell(dat');
                catch EM
                    warning(EM.message);
                end
                
            end
            
            function saveOutput()
                
                file = this.gui.fileList.String{this.gui.fileList.Value(1)};
                
                [~, string1, ~] = fileparts(file);
                string1 = sprintf('%s%s', string1, '.xerayoutput');
                string2 = 'Save output text as: ';
                
                [fileName, targetPath] = uiputfile(string1, string2);
                
                if ~isnumeric(fileName)
                    file = fullfile(targetPath, fileName);
                    text = this.gui.output.String;
                    
                    fid = fopen(file,'w');
                    fprintf(fid, strcat(datestr(datetime), '\n'));
                    for i = 1:length(text)
                        fprintf(fid, strcat(text{i}, '\n'));
                    end
                    fclose(fid);
                end
                
            end
            
            function saveUpperFigure()
                
                fileName = this.gui.fileList.String{this.gui.fileList.Value};
                
                [~, fileName, ~] = fileparts(fileName);
                
                theFigure = figure;
                copyobj(this.gui.ax1, theFigure);
                ax = gca;
                ax.Units = 'normalized';
                ax.Position = [.13 .11 .775 .815];
                hgsave(theFigure, fileName);
                
            end
            
            function saveLowerFigure()
                fileName = this.gui.fileList.String{this.gui.fileList.Value};
                theFigure = figure;
                copyobj(this.gui.ax2, theFigure);
                ax = gca;
                ax.Units = 'normalized';
                ax.Position = [.13 .11 .775 .815];
                hgsave(theFigure, fileName);
            end
            
            function saveDataAndFit()
                
                dataset = this.data{this.gui.fileList.Value(1)};
                
                if ~isempty(dataset.fit.all)
                    
                    file = this.gui.fileList.String{this.gui.fileList.Value(1)};
                    [~, file, ~] = fileparts(file);
                    
                    filename = sprintf('%s%s', file, '.xerayfit');
                    [fileName, targetPath] = uiputfile(filename, 'Save data and fit as: ');
                    
                    if ~isnumeric(fileName)
                        
                        jsondata.angle = num2str(dataset.data.angle);
                        jsondata.signal = num2str(dataset.data.lineshape.signal);
                        jsondata.error = num2str(dataset.data.lineshape.signalError);
                        jsondata.fit = num2str(dataset.system.calculateSignal(dataset.fit.all.P));
                        
                        text = savejson('', jsondata);
                        
                        file = fullfile(targetPath, fileName);
                        
                        fid = fopen(file, 'w');
                        
                        if fid
                            fprintf(fid, text);
                            fclose(fid);
                        end
                        
                    end
                    
                else
                    
                    raiseErrorDialog('No fitting results yet.');
                    
                end
            end
            
        end
        
    end
    
end
classdef XeRayGUI < handle
    
    properties
        
        data
        gui
        control
        
        elementProfiles
        handles
        
    end
    
    methods
        
        % create the GUI
        
        function this = XeRayGUI()
            
            config = loadjson(fullfile(getParentDir(which('XeRay.m')), 'support-files/gui-config.json'));
            this.elementProfiles = loadjson(fullfile(getParentDir(which('XeRay.m')), 'support-files/element-profiles.json'));

            set(0, 'units', config.units);
            pix = get(0, 'screensize');
            if pix(4) * 0.85 <= config.window(4)
                config.window(4) = pix(4)*0.85;
            end
            
            this.handles = figure('Visible','on','Name','XeRay','NumberTitle','off','Units','pixels',...
                'Position', config.window, 'Resize', 'on');
            
            this.control = XeRayControl();
            this.createGUIElements();
            
        end
        
        function createGUIElements(this)
            
            handle0 = this.handles;
            
            createListPanel(this);
            createAxes(this);
            createRightPanel(this);
            createElementEditPanel(this);
            createUIBeforeTable(this);
            createTableEtc(this);
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
                    'Position',[0.6 0.965 0.1 0.018],'CallBack',@showError_Callback);
                
                this.gui.likelihoodChi2 = uicontrol(handle0,'Style','popupmenu','String',{'Likelihood','Chi^2'},'Visible','off',...
                    'Units','normalized',...
                    'Position',[0.572 0.97 0.1 0.018],'CallBack',@likelihoodChi_Callback);
                
                this.gui.showCal = uicontrol(handle0,'Style','checkbox','String','Show Calc.','Units','normalized',...
                    'Position',[0.6 0.437 0.08 0.018],'CallBack',@showCal_Callback);
                
                this.gui.showFit = uicontrol(handle0,'Style','checkbox','String','Show Fit','Units','normalized',...
                    'Position',[0.54 0.437 0.06 0.018],'CallBack',@showFit_Callback);
                
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
                elementNames = fieldnames(this.elementProfiles);
                
                uicontrol(elementEditPanel,'Style','text','String','Existing Elements','Units','normalized',...
                    'HorizontalAlignment','left','Position',[0.02 0.9 0.3 0.0825]);
                
                uicontrol(elementEditPanel,'Style','pushbutton','String','Close','Units','normalized',...
                    'Position',[0.8 0.9 0.15 0.0825],'Callback',@closeElementTab_Callback);
                
                this.gui.elementListbox = uicontrol(elementEditPanel,'Style','listbox','String', elementNames, 'Units','normalized',...
                    'Position',[0.02 0.04 0.2 0.88],'Max',1,'CallBack',@elementListbox_Callback);
                
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
                    'Position',[0.67 0.135 0.28 0.0825],'Callback',@modifyElementButton_Callback);
                
                uicontrol(elementEditPanel,'Style','pushbutton','String','Remove Element','Units','normalized',...
                    'Position',[0.67 0.05 0.28 0.0825],'Callback',@removeElementButton_Callback);
                
            end
            
            function createUIBeforeTable(this)
                
                elementNames = fieldnames(this.elementProfiles);
                rightPanel = this.gui.rightPanel;
                
                this.gui.elementPopup = uicontrol(rightPanel,'Style','popupmenu','String',[{'Choose element...'}, elementNames', {'Add or modify...'}],'Units','normalized',...
                    'Position',[0.01 0.96 0.43 0.03],'CallBack',@elementPopup_Callback);
                
                this.gui.curveType = uicontrol(rightPanel,'Style','popupmenu','String',this.control.curveTypes,'Units','normalized',...
                    'Position',[0.5 0.96 0.43 0.03],'CallBack',@curveType_Callback);
                
                this.gui.background = uicontrol(rightPanel,'Style','radiobutton','Enable','off','String','Subtract Background','Units','normalized',...
                    'Position',[0.015 0.92 0.43 0.03],'CallBack',@background_Callback);
                
                this.gui.startFitting = uicontrol(rightPanel,'Style','radiobutton','Enable','off','String','Start Fitting','Units','normalized',...
                    'Position',[0.5 0.92 0.43 0.03],'CallBack',@startFitting_Callback);
                
                this.gui.energyText = uicontrol(rightPanel,'Style','text','String','Beam Energy (keV)','Units','normalized',...
                    'HorizontalAlignment','left','Position',[0.025 0.88 0.29 0.03]);
                
                this.gui.energyInput = uicontrol(rightPanel,'Style','edit','String','10.0','Units','normalized',...
                    'HorizontalAlignment','left','Position',[0.3 0.885 0.15 0.028],'CallBack',@energyInput_Callback);
                
                this.gui.densityText = uicontrol(rightPanel,'Style','text','String','Density (g/mL)','Units','normalized',...
                    'HorizontalAlignment','left','Position',[0.5 0.88 0.2 0.03]);
                
                this.gui.densityInput = uicontrol(rightPanel,'Style','edit','String','1.02','Units','normalized',...
                    'HorizontalAlignment','left','Position',[0.72 0.885 0.21 0.028],'CallBack',@densityInput_Callback);
                
                this.gui.slitText = uicontrol(rightPanel,'Style','text','String','Slit Size (mm)','Units','normalized',...
                    'HorizontalAlignment','left','Position',[0.5 0.845 0.2 0.03]);
                
                this.gui.slitInput = uicontrol(rightPanel,'Style','edit','String','0.02','Units','normalized',...
                    'HorizontalAlignment','left','Position',[0.72 0.85 0.21 0.028],'CallBack',@slitInput_Callback);
                
                this.gui.lengthText = uicontrol(rightPanel,'Style','text','String','Detector Foot (mm)','Units','normalized',...
                    'HorizontalAlignment','left','Position',[0.025 0.845 0.29 0.03]);
                
                this.gui.lengthInput = uicontrol(rightPanel,'Style','edit','String','10.76','Units','normalized',...
                    'HorizontalAlignment','left','Position',[0.3 0.85 0.15 0.028],'CallBack',@lengthInput_Callback);
                
                this.gui.formulaText = uicontrol(rightPanel,'Style','text','String','Chemical Formula','Units','normalized',...
                    'HorizontalAlignment','left','Position',[0.025 0.81 0.29 0.03]);
                
                this.gui.formulaInput = uicontrol(rightPanel,'Style','edit','String','H2OCa0.000018Cl0.000036','Units','normalized',...
                    'HorizontalAlignment','left','Position',[0.3 0.815 0.625 0.028],'CallBack',@formulaInput_Callback);
                
            end
            
            function createTableEtc(this)
                
                rightPanel = this.gui.rightPanel;
                
                rowName = {'Qz Offset','Scale Factor','Bulk (mM)','Surf (1/nm^2)','Background'};
                columnName = {'Min','Max','Start','Fix','Plot'};
                columnFormat = {'numeric','numeric','numeric','logical','logical'};
                columnWidth = {55 55 55 30 30};
                tableData = {-0.001,0.001,0,false,false;1,1,1,true,false;1,1,1,true,false;0,0,0,true,false;0,0,0,true,false};
                
                this.gui.table = uitable(rightPanel,'Data', tableData,'ColumnName', columnName,...
                    'ColumnFormat', columnFormat,'ColumnEditable', [true true true true true],'Units','normalized',...
                    'ColumnWidth',columnWidth,'RowName',rowName,'RowStriping','off',...
                    'Position',[0.025 0.64 0.935 0.17],'CellEditCallBack',@table_Callback);
                
                this.gui.loadPara = uicontrol(rightPanel,'Style','pushbutton','String','Load Para','Units','normalized',...
                    'Position',[0.024 0.605 0.17 0.03],'CallBack',@loadPara_Callback);
                
                this.gui.savePara = uicontrol(rightPanel,'Style','pushbutton','String','Save Para','Units','normalized',...
                    'Position',[0.19 0.605 0.17 0.03],'CallBack',@savePara_Callback);
                
                this.gui.stepInput = uicontrol(rightPanel,'Style','edit','String',20,'Units','normalized',...
                    'HorizontalAlignment','left','Position',[0.62 0.605 0.1 0.03]);
                
                this.gui.stepText = uicontrol(rightPanel,'Style','text','String','Steps','Units','normalized',...
                    'HorizontalAlignment','left','Position',[0.735 0.6 0.08 0.03]);
                
                this.gui.fitButton = uicontrol(rightPanel,'Style','pushbutton','String','Fit','Units','normalized',...
                    'Position',[0.82 0.605 0.15 0.03],'CallBack',@fitButton_Callback);
                
                this.gui.withText = uicontrol(rightPanel,'Style','text','String','With','Units','normalized','HorizontalAlignment','left',...
                    'Position',[0.025 0.570 0.07 0.03]);
                this.gui.confidenceInput = uicontrol(rightPanel,'Style','edit','String','95','Units','normalized',...
                    'HorizontalAlignment','left','Position',[0.1 0.575 0.07 0.03],'CallBack',@confidenceInput_Callback);
                this.gui.confidenceText = uicontrol(rightPanel,'Style','text','String','% confidence window','Units','normalized','HorizontalAlignment','left',...
                    'Position',[0.171 0.570 0.28 0.03]);
                this.gui.recordFitting = uicontrol(rightPanel,'Style','pushbutton','String','Record Fitting','Units','normalized',...
                    'Position',[0.452 0.575 0.22 0.03],'CallBack',@recordFitting_Callback);
                
                this.gui.adjustPara = uicontrol(rightPanel,'Style','pushbutton','String','Adjust Para','Units','normalized',...
                    'Position',[0.77 0.575 0.2 0.03],'CallBack',@adjustPara_Callback);
                
            end
            
            function createOutputandSaveButtons(this)
                
                rightPanel = this.gui.rightPanel;
                
                this.gui.output = uicontrol(rightPanel,'Style','edit','Max',2,'HorizontalAlignment','left','Units','normalized',...
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
                
            end
            
        end
        
        % utility functions
        
        function data = getDataForElementTable(this, elementName)
            
            data = cell(3,2);
            profile = this.elementProfiles.(elementName);
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
        
        function [oldFiles, newFiles] = loadNewData(this)

            [newFiles, path] = uigetfile('*.xfluo','Select fluorescence data files','MultiSelect','on');
            
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
                        newData{i} = XeLayers(fullfile(path, newFiles{i}));
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
        
        % plot functions
        
        function plotWholeSpectraWithoutError(this)
            
            [n, m, ~, ~] = this.getSelectionIndex();
            [styles1, legends1, ~, ~] = this.getSpectraStylesAndLegends();
            
            for i = 1 : length(this.gui.angleList.Value)
                plot(this.gui.ax1, this.data{n(i)}.rawdata.energy, this.data{i}.rawdata.intensity(:, m(i)), styles1{i});
                hold('on');
            end
            
            legend(this.gui.ax1, legends1);
            xlabel(this.gui.ax1, 'Energy (keV)');
            ylabel(this.gui.ax1, 'Signal');
            
            hold('off');
            
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
        
        function emptyFigures(this)
            
            plot(this.gui.ax1, 1);
            plot(this.gui.ax2, 1);
            
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
        
        % view controller
        
        function updateView(this, trigger, varargin)
            
            switch trigger
                case 'file'
                    this.displayAngles();
                    switch this.control.element
                        case 'none'
                            this.plotWholeSpectraWithoutError();
                    end
                case 'angle'
                    switch this.control.element
                        case 'none'
                            this.plotWholeSpectraWithoutError();
                    end
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
            end
            
        end
        
    end
    
end
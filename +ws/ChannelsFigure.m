classdef ChannelsFigure < ws.MCOSFigure & ws.EventSubscriber
    properties  % protected by gentleman's agreement
        %Model  % an Wavesurfer object
        %Controller  % a ChannelsController
        %FigureGH  % the figure graphics handle
        AIsPanel
        AIChannelColTitleText
        AIScaleColTitleText
        AIIsActiveColTitleText        
        AILabelTexts
        AIUnitsEdits
        AIScaleEdits
        AIUnitsTexts
        AIIsActiveCheckboxes
        
        AOsPanel
        AOChannelColTitleText
        AOScaleColTitleText
        %AOMultiplierColTitleText
        AOLabelTexts
        AOUnitsEdits
        AOScaleEdits
        AOUnitsTexts
        %AOMultiplierEdits
    end  % properties
    
    methods
        function self=ChannelsFigure(model,controller)
            self = self@ws.MCOSFigure(model,controller);
            
            % Set the relevant properties of the figure itself
            set(self.FigureGH,'Tag','ChannelsFigure', ...
                              'Units','pixels', ...
                              'Color',get(0,'defaultUIControlBackgroundColor'), ...
                              'Resize','off', ...
                              'Name','Channels...', ...
                              'NumberTitle','off', ...
                              'Menubar','none', ...
                              'Visible','off');
            
            % Create all the "static" controls, set them up, but don't position them
            self.createFixedControls();

            % Set up the tags of the HG objects to match the property names
            self.updateHGObjectTags_();
           
            % Initialize the guidata
            self.updateGuidata_();

            % sync up self to model
            self.update();         
            
            % Subscribe to model events
            model=self.Model;
            if ~isempty(model) ,
                model.subscribeMe(self,'Update','','update');                
                model.subscribeMe(self,'DidSetState','','updateControlProperties');            
                acquisition=model.Acquisition;
                if ~isempty(acquisition) ,
                    acquisition.subscribeMe(self,'DidSetAnalogChannelUnitsOrScales','','updateControlProperties');
                    acquisition.subscribeMe(self,'DidSetIsChannelActive','','updateControlProperties');
                end
                stimulation=model.Stimulation;
                if ~isempty(stimulation) ,
                    stimulation.subscribeMe(self,'DidSetAnalogChannelUnitsOrScales','','updateControlProperties');                    
                end
            end
            
            % make the figure visible
            set(self.FigureGH,'Visible','on');                        
        end

        function self=createFixedControls(self)
            nAIs=self.Model.Acquisition.NChannels;
            nAOs=self.Model.Stimulation.NChannels;
            
            %
            % Make the AIs panel
            %
            self.AIsPanel= ...
                uipanel('Parent',self.FigureGH, ...
                        'Tag','AIsPanel', ...
                        'Units','pixels', ...
                        'FontName','Tahoma', ...
                        'FontSize',8, ...
                        'Title','AI Channels');
            
            % make the title row
            self.AIChannelColTitleText= ...
                uicontrol('Parent',self.AIsPanel, ...
                          'Style','text', ...
                          'Units','pixels', ...
                          'FontName','Tahoma', ...
                          'FontSize',8, ...
                          'HorizontalAlignment','left', ...
                          'String','');
            self.AIScaleColTitleText= ...
                uicontrol('Parent',self.AIsPanel, ...
                          'Style','text', ...
                          'Units','pixels', ...
                          'FontName','Tahoma', ...
                          'FontSize',8, ...
                          'HorizontalAlignment','center', ...
                          'String','Scale');
            self.AIIsActiveColTitleText= ...
                uicontrol('Parent',self.AIsPanel, ...
                          'Style','text', ...
                          'Units','pixels', ...
                          'FontName','Tahoma', ...
                          'FontSize',8, ...
                          'HorizontalAlignment','center', ...
                          'String','Active?');
                    
            % Populate the AI channel rows        
            for i=1:nAIs ,
                self.AILabelTexts(i)=...
                    uicontrol('Parent',self.AIsPanel, ...
                              'Style','text', ...
                              'Tag',sprintf('AILabelTexts%d',i), ...
                              'Units','pixels', ...
                              'FontName','Tahoma', ...
                              'FontSize',8, ...
                              'HorizontalAlignment','left');  % shim to make look nice
                self.AIScaleEdits(i)= ...
                    uicontrol('Parent',self.AIsPanel, ...
                              'Style','edit', ...
                              'Tag',sprintf('AIScaleEdits%d',i), ...
                              'Units','pixels', ...
                              'FontName','Tahoma', ...
                              'FontSize',8, ...
                              'BackgroundColor','w', ...
                              'HorizontalAlignment','right', ...
                              'Callback',@(src,evt)(self.controlActuated('AIScaleEdits',src,evt)) );
                self.AIUnitsTexts(i)= ...
                    uicontrol('Parent',self.AIsPanel, ...
                              'Style','text', ...
                              'Tag',sprintf('AIUnitsTexts%d',i), ...
                              'Units','pixels', ...
                              'FontName','Tahoma', ...
                              'FontSize',8, ...
                              'String','V/', ...
                              'HorizontalAlignment','left');
                self.AIUnitsEdits(i)= ...
                    uicontrol('Parent',self.AIsPanel, ...
                              'Style','edit', ...
                              'Tag',sprintf('AIUnitsEdits%d',i), ...
                              'Units','pixels', ...
                              'FontName','Tahoma', ...
                              'FontSize',8, ...
                              'BackgroundColor','w', ...
                              'HorizontalAlignment','left', ...
                              'Callback',@(src,evt)(self.controlActuated('AIUnitsEdits',src,evt)) );
                self.AIIsActiveCheckboxes(i)= ...
                    uicontrol('Parent',self.AIsPanel, ...
                              'Style','checkbox', ...
                              'Units','pixels', ...
                              'FontSize',8, ...
                              'FontName','Tahoma', ...
                              'Value',0, ...
                              'String','', ...
                              'Callback',@(src,evt)(self.controlActuated('AIIsActiveCheckboxes',src,evt)));                          
            end
            
            %
            % Make the AOs panel
            %
            self.AOsPanel= ...
                uipanel('Parent',self.FigureGH, ...
                        'Tag','AOsPanel', ...
                        'Units','pixels', ...
                        'FontName','Tahoma', ...
                        'FontSize',8, ...
                        'Title','AO Channels');
            
            % make the title row
            self.AOChannelColTitleText= ...
                uicontrol('Parent',self.AOsPanel, ...
                          'Style','text', ...
                          'Units','pixels', ...
                          'FontName','Tahoma', ...
                          'FontSize',8, ...
                          'HorizontalAlignment','left', ...
                          'String','');
            self.AOScaleColTitleText= ...
                uicontrol('Parent',self.AOsPanel, ...
                          'Style','text', ...
                          'Units','pixels', ...
                          'FontName','Tahoma', ...
                          'FontSize',8, ...
                          'HorizontalAlignment','left', ...
                          'String','Scale');
%             self.AOMultiplierColTitleText= ...
%                 uicontrol('Parent',self.AOsPanel, ...
%                           'Style','text', ...
%                           'Units','pixels', ...
%                           'FontName','Tahoma', ...
%                           'FontSize',8, ...
%                           'HorizontalAlignment','center', ...
%                           'String','Multiplier');

            % populate the AO rows
            for i=1:nAOs ,
                self.AOLabelTexts(i)=...
                    uicontrol('Parent',self.AOsPanel, ...
                              'Style','text', ...
                              'Tag',sprintf('AOLabelTexts%d',i), ...
                              'Units','pixels', ...
                              'FontName','Tahoma', ...
                              'FontSize',8, ...
                              'HorizontalAlignment','left');
                self.AOScaleEdits(i)= ...
                    uicontrol('Parent',self.AOsPanel, ...
                              'Style','edit', ...
                              'Tag',sprintf('AOScaleEdits%d',i), ...
                              'Units','pixels', ...
                              'FontName','Tahoma', ...
                              'FontSize',8, ...
                              'BackgroundColor','w', ...
                              'HorizontalAlignment','right', ...
                              'Callback',@(src,evt)(self.controlActuated('AOScaleEdits',src,evt)) );
                self.AOUnitsEdits(i)= ...
                    uicontrol('Parent',self.AOsPanel, ...
                              'Style','edit', ...
                              'Tag',sprintf('AOUnitsEdits%d',i), ...
                              'Units','pixels', ...
                              'FontName','Tahoma', ...
                              'FontSize',8, ...
                              'BackgroundColor','w', ...
                              'HorizontalAlignment','right', ...
                              'Callback',@(src,evt)(self.controlActuated('AOUnitsEdits',src,evt)) );
                self.AOUnitsTexts(i)= ...
                    uicontrol('Parent',self.AOsPanel, ...
                              'Style','text', ...
                              'Tag',sprintf('AOUnitsTexts%d',i), ...
                              'Units','pixels', ...
                              'FontName','Tahoma', ...
                              'FontSize',8, ...
                              'String','/V', ...
                              'HorizontalAlignment','left');
%                 self.AOMultiplierEdits(i)= ...
%                     uicontrol('Parent',self.AOsPanel, ...
%                               'Style','edit', ...
%                               'Tag',sprintf('AOMultiplierEdits%d',i), ...
%                               'Units','pixels', ...
%                               'FontName','Tahoma', ...
%                               'FontSize',8, ...
%                               'BackgroundColor','w', ...
%                               'HorizontalAlignment','right', ...
%                               'Callback',@(src,evt)(self.controlActuated(src,evt)) );
            end
        end  % method
        
        function value=maximumAIScaleLabelWidth(self)
            n=length(self.AIScaleEdits);
            value=-inf;
            for i=1:n ,
                thisExtent=get(self.AILabelTexts(i),'Extent');
                thisWidth=thisExtent(3);
                value=max(value,thisWidth);
            end            
        end
        
        function value=maximumAOScaleLabelWidth(self)
            n=length(self.AOScaleEdits);            
            value=-inf;
            for i=1:n ,
                thisExtent=get(self.AOLabelTexts(i),'Extent');
                thisWidth=thisExtent(3);
                value=max(value,thisWidth);
            end            
        end
        
        function self=layout(self)
            import ws.utility.*

            % Layout parameters
            panelBorderSize=6;
            interPanelSpaceWidth=10;
            panelToTitleRowSpaceHeight=20;  % need to accomodate the panel title
            bottomRowToFrameSpaceHeight=12;
            titleRowHeight=10;
            rowHeight=16;
            interRowHeight=10;
            rowToRowHeight=rowHeight+interRowHeight;
            panelToLabelSpaceWidth=5;
            aiScaleLabelWidth=max(30,self.maximumAIScaleLabelWidth());
            editShimHeight=5;
            editHeight=rowHeight+editShimHeight;  % shim makes it look nicer
            gainEditWidth=42;
            aiUnitsNumeratorTextWidth=12;
            aiUnitsEditWidth=25;
            labelHeight=rowHeight;
            aiPanelRightPadWidth=2;
            gainLabelSpaceWidth=3;
            gainUnitSpaceWidth=4;
            interUnitsSpaceWidth=0;
            aoScaleLabelWidth=max(30,self.maximumAOScaleLabelWidth());
            aoUnitsDenominatorTextWidth=12;
            spaceBeforeIsActiveColWidth=1;
            aiIsActiveColWidth=50;
            spaceBelowTitleRowHeight=2;
            spaceBeforeAOMultiplierColWidth=0;
            aoMultiplierEditWidth=0;
            
            % Derived layout parameters
            nAIs=length(self.AIScaleEdits);
            nAOs=length(self.AOScaleEdits);            
            nRows=max(nAIs,nAOs);            
            aoUnitsEditWidth=aiUnitsEditWidth;
            aoPanelRightPadWidth=8;
            aiPanelWidth=panelToLabelSpaceWidth+...
                         aiScaleLabelWidth+ ...
                         gainLabelSpaceWidth+ ...
                         gainEditWidth+ ...
                         gainUnitSpaceWidth+ ...
                         aiUnitsNumeratorTextWidth+ ...
                         interUnitsSpaceWidth+ ...
                         aiUnitsEditWidth+ ...
                         spaceBeforeIsActiveColWidth + ...
                         aiIsActiveColWidth+ ...
                         aiPanelRightPadWidth;
            aoPanelWidth=panelToLabelSpaceWidth+...
                         aoScaleLabelWidth+ ...
                         gainLabelSpaceWidth+ ...
                         gainEditWidth+ ...
                         gainUnitSpaceWidth+ ...
                         aoUnitsEditWidth+ ...
                         interUnitsSpaceWidth+ ...                         
                         aoUnitsDenominatorTextWidth+ ...
                         spaceBeforeAOMultiplierColWidth+ ...
                         aoMultiplierEditWidth+ ...
                         aoPanelRightPadWidth;
            panelHeight=panelToTitleRowSpaceHeight+titleRowHeight+spaceBelowTitleRowHeight+(nRows-1)*interRowHeight+nRows*rowHeight+bottomRowToFrameSpaceHeight;
            figureHeight=panelHeight+2*panelBorderSize;
            figureWidth=panelBorderSize+aiPanelWidth+interPanelSpaceWidth+aoPanelWidth+panelBorderSize;
            
            % Position the figure, keeping upper left corner fixed
            currentPosition=get(self.FigureGH,'Position');
            currentOffset=currentPosition(1:2);
            currentSize=currentPosition(3:4);
            currentUpperY=currentOffset(2)+currentSize(2);
            figurePosition=[currentOffset(1) currentUpperY-figureHeight figureWidth figureHeight];
            set(self.FigureGH,'Position',figurePosition);
            
            % Position the AIs panel
            set(self.AIsPanel,'Position',[panelBorderSize panelBorderSize aiPanelWidth panelHeight]);
            
            %  Layout the row of column titles in AI panel
            titleRowBottomY=panelHeight-panelToTitleRowSpaceHeight-titleRowHeight;
            channelLabelColLeftX = panelToLabelSpaceWidth;
            alignTextInRectangleBang(self.AIChannelColTitleText,[channelLabelColLeftX titleRowBottomY aiScaleLabelWidth titleRowHeight],'lm');
            gainColLeftX = channelLabelColLeftX+aiScaleLabelWidth+gainLabelSpaceWidth;
            alignTextInRectangleBang(self.AIScaleColTitleText,[gainColLeftX titleRowBottomY gainEditWidth titleRowHeight],'cm');
            isActiveColLeftX=gainColLeftX+gainEditWidth+gainUnitSpaceWidth+ ...
                             aiUnitsNumeratorTextWidth+ ...
                             interUnitsSpaceWidth+ ...
                             aiUnitsEditWidth+spaceBeforeIsActiveColWidth;
            alignTextInRectangleBang(self.AIIsActiveColTitleText,[isActiveColLeftX titleRowBottomY aiIsActiveColWidth titleRowHeight],'cm');
            
            % Position the stuff in the AI rows            
            aiYRowBottom=titleRowBottomY-spaceBelowTitleRowHeight-rowHeight;   
            for i=1:nAIs ,
                xColLeft=panelToLabelSpaceWidth;
                set(self.AILabelTexts(i), ...
                    'Position',[xColLeft aiYRowBottom-4 aiScaleLabelWidth labelHeight]);  % shim to make look nice
                xColLeft=xColLeft+aiScaleLabelWidth+gainLabelSpaceWidth;
                set(self.AIScaleEdits(i), ...
                    'Position',[xColLeft aiYRowBottom-editShimHeight gainEditWidth editHeight]);
                xColLeft=xColLeft+gainEditWidth+gainUnitSpaceWidth;
                set(self.AIUnitsTexts(i), ...
                    'Position',[xColLeft aiYRowBottom-4 aiUnitsNumeratorTextWidth labelHeight]);
                xColLeft=xColLeft+aiUnitsNumeratorTextWidth+interUnitsSpaceWidth;
                set(self.AIUnitsEdits(i), ...
                    'Position',[xColLeft aiYRowBottom-editShimHeight aiUnitsEditWidth editHeight] );
                xColLeft=xColLeft+aiUnitsEditWidth+spaceBeforeIsActiveColWidth;
                centerCheckboxBang(self.AIIsActiveCheckboxes(i),[xColLeft+aiIsActiveColWidth/2 aiYRowBottom+rowHeight/2]);
                aiYRowBottom=aiYRowBottom-rowToRowHeight;
            end
            
            % Position the AOs panel
            set(self.AOsPanel, ...
                'Position',[panelBorderSize+aiPanelWidth+interPanelSpaceWidth panelBorderSize aoPanelWidth panelHeight] );

            %  Layout the row of column titles in AO panel
            channelLabelColLeftX = panelToLabelSpaceWidth;
            alignTextInRectangleBang(self.AOChannelColTitleText,[channelLabelColLeftX titleRowBottomY aoScaleLabelWidth titleRowHeight],'lm');
            gainColLeftX = channelLabelColLeftX+aoScaleLabelWidth+gainLabelSpaceWidth;
            alignTextInRectangleBang(self.AOScaleColTitleText,[gainColLeftX titleRowBottomY gainEditWidth titleRowHeight],'cm');
%             multiplierColLeftX=gainColLeftX+ ...
%                                gainEditWidth+ ...
%                                gainUnitSpaceWidth+ ...
%                                aoUnitsEditWidth+ ...
%                                interUnitsSpaceWidth+ ...
%                                aoUnitsDenominatorTextWidth+ ...
%                                spaceBeforeAOMultiplierColWidth;
%             alignTextInRectangleBang(self.AOMultiplierColTitleText,[multiplierColLeftX titleRowBottomY aoMultiplierEditWidth titleRowHeight],'cm');            

            % Position the stuff in the AO rows                        
            aoYRowBottom=titleRowBottomY-spaceBelowTitleRowHeight-rowHeight;   
            for i=1:nAOs ,
                xColLeft=panelToLabelSpaceWidth;
                set(self.AOLabelTexts(i), ...
                    'Position',[xColLeft aoYRowBottom-4 aoScaleLabelWidth labelHeight] );
                xColLeft=xColLeft+aoScaleLabelWidth+gainLabelSpaceWidth;
                set(self.AOScaleEdits(i), ...
                    'Position',[xColLeft aoYRowBottom-editShimHeight gainEditWidth editHeight] );
                xColLeft=xColLeft+gainEditWidth+gainUnitSpaceWidth;
                set(self.AOUnitsEdits(i), ...
                    'Position',[xColLeft aoYRowBottom-editShimHeight aoUnitsEditWidth editHeight] );
                xColLeft=xColLeft+aoUnitsEditWidth+interUnitsSpaceWidth;
                set(self.AOUnitsTexts(i), ...
                    'Position',[xColLeft aoYRowBottom-4 aoUnitsDenominatorTextWidth labelHeight] );
%                 xColLeft=xColLeft+aoUnitsDenominatorTextWidth+spaceBeforeAOMultiplierColWidth;
%                 set(self.AOMultiplierEdits(i), ...
%                     'Position',[xColLeft aoYRowBottom-editShimHeight aoMultiplierEditWidth editHeight] );                
                aoYRowBottom=aoYRowBottom-rowToRowHeight;
            end
        end  % method
  
    end  % methods
    
    methods (Access=protected)
        function updateImplementation_(self,varargin)
            % Syncs self with model, making no prior assumptions about what
            % might have changed or not changed in the model.
            %self.updateControlsInExistance();
            self.updateControlProperties();
            self.layout();
        end        

        function updateControlPropertiesImplementation_(self,varargin)
            import ws.utility.*
            model=self.Model;
            if isempty(model) || ~isvalid(model) ,
                return
            end
            
            nAIs=length(self.AIScaleEdits);
            nAOs=length(self.AOScaleEdits);
            isWavesurferIdle=(model.State==ws.ApplicationState.Idle);
            
            % update the AIs
            normalBackgroundColor=[1 1 1];
            warningBackgroundColor=[1 0.8 0.8];
            deviceNames=model.Acquisition.DeviceNames;  % cell array of strings
            channelIDs=model.Acquisition.ChannelIDs;  % zero-based NI channel index
            channelNames=model.Acquisition.ChannelNames;
            channelScales=model.Acquisition.ChannelScales;
            channelUnits=model.Acquisition.ChannelUnits;
            nElectrodesClaimingChannel=model.Acquisition.getNumberOfElectrodesClaimingChannel();
            isChannelScaleEnslaved=(nElectrodesClaimingChannel==1);
            isChannelOvercommited=(nElectrodesClaimingChannel>1);
            for i=1:nAIs ,
                set(self.AILabelTexts(i),'String',sprintf('%s/ai%d (%s):',deviceNames{i},channelIDs(i),channelNames{i}));                
                set(self.AIScaleEdits(i),'String',sprintf('%g',channelScales(i)), ...
                                         'BackgroundColor',fif(isChannelOvercommited(i),warningBackgroundColor,normalBackgroundColor), ...
                                         'Enable',onIff(isWavesurferIdle&&~isChannelScaleEnslaved(i)));
                set(self.AIUnitsEdits(i),'String',toString(channelUnits(i)), ...
                                         'BackgroundColor',fif(isChannelOvercommited(i),warningBackgroundColor,normalBackgroundColor), ...
                                         'Enable',onIff(isWavesurferIdle&&~isChannelScaleEnslaved(i)));
                set(self.AIIsActiveCheckboxes(i),'Value',self.Model.Acquisition.IsChannelActive(i), ...
                                                 'Enable',onIff(isWavesurferIdle));                                     
            end
            
            % update the AOs
            deviceNames=model.Stimulation.DeviceNamePerAnalogChannel;  % cell array of strings
            channelIDs=model.Stimulation.ChannelIDs;  % zero-based NI channel index
            channelNames=model.Stimulation.ChannelNames;
            channelScales=model.Stimulation.ChannelScales;
            channelUnits=model.Stimulation.ChannelUnits;
            nElectrodesClaimingChannel=model.Stimulation.getNumberOfElectrodesClaimingChannel();
            isChannelScaleEnslaved=(nElectrodesClaimingChannel==1);
            isChannelOvercommited=(nElectrodesClaimingChannel>1);
            for i=1:nAOs ,
                set(self.AOLabelTexts(i),'String',sprintf('%s/ao%d (%s):',deviceNames{i},channelIDs(i),channelNames{i}));                
                set(self.AOScaleEdits(i),'String',sprintf('%g',channelScales(i)), ...
                                         'BackgroundColor',fif(isChannelOvercommited(i),warningBackgroundColor,normalBackgroundColor), ...
                                         'Enable',onIff(isWavesurferIdle&&~isChannelScaleEnslaved(i)));
                set(self.AOUnitsEdits(i),'String',toString(channelUnits(i)), ...
                                         'BackgroundColor',fif(isChannelOvercommited(i),warningBackgroundColor,normalBackgroundColor), ...
                                         'Enable',onIff(isWavesurferIdle&&~isChannelScaleEnslaved(i)));
            end
        end  % function        
        
    end
    
    methods (Access=protected)
%         function initializeGuidata(self)
%             % Set up the figure guidata the way it would be if this were a
%             % GUIDE UI, or close enough to fool a ws.most.Controller.
%             childControls=get(self.FigureGH,'Children');
%             nChildren=length(childControls);
%             handles=struct();
%             for i=1:nChildren
%                 childControl=childControls(i);
%                 tag=get(childControl,'Tag');
%                 handles.(tag)=childControl;
%             end
%             % Add the figure itself
%             fig=self.FigureGH;  % the figure GH
%             tag=get(fig,'Tag');
%             handles.(tag)=fig;
%             % commit to the guidata
%             guidata(self.FigureGH,handles);
%         end
        
%         function controlActuated(self,source,event) %#ok<INUSD>
%             % This makes it so that we don't have all these implicit
%             % references to the controller in the closures attached to HG
%             % object callbacks.  It also means we can just do nothing if
%             % the Controller is invalid, instead of erroring.
%             if isempty(self.Controller) || ~isvalid(self.Controller) ,
%                 return
%             end
%             self.Controller.controlActuated(source);
%         end  % function
    end  % methods

    methods (Access = protected)
        function updateHGObjectTags_(self)
            % For each object property, if it's an HG object, set the tag
            % based on the property name
            mc=metaclass(self);
            propertyNames={mc.PropertyList.Name};
            for i=1:length(propertyNames) ,
                propertyName=propertyNames{i};
                propertyThing=self.(propertyName);
                if ~isempty(propertyThing) && all(ishghandle(propertyThing)) && ~(isscalar(propertyThing) && isequal(get(propertyThing,'Type'),'figure')) ,
                    % Set Tag
                    set(propertyThing,'Tag',propertyName);
                end
            end
        end  % function        
    end  % protected methods block
    
end  % classdef

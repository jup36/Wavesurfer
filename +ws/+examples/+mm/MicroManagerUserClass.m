classdef MicroManagerUserClass < ws.UserClass

    properties (Access=private, Transient=true)
        doesInterfaceExist_
        interface_
        isIInFrontend_ 
    end
    
    methods
        function self = MicroManagerUserClass(wsModel)
            fprintf('Creating the Micro-Manager user object\n') ;
            self.isIInFrontend_ = ( isa(wsModel,'ws.WavesurferModel') && wsModel.IsITheOneTrueWavesurferModel ) ;
            self.doesInterfaceExist_ = false ;
        end
        
        function delete(self)  %#ok<INUSD>
            fprintf('Deleting the Micro-Manager user object\n') ;
%             if self.areCameraInterfacesInitialized_ ,
%                 for i=1:self.cameraCount_ ,
%                     try
%                         %self.biasCameraInterfaces_{i}.disconnect();
%                     catch me  %#ok<NASGU>
%                         % ignore
%                     end
%                     delete(self.biasCameraInterfaces_{i});
%                     self.biasCameraInterfaces_{i} = [] ;  % set the cell to empty, but don't change length of cell array
%                 end
%                 self.biasCameraInterfaces_ = cell(1,0) ;  % set to zero-length cell array
%                 self.areCameraInterfacesInitialized_ = false ;
%             end
        end
        
        function startingRun(self,~,~)
            fprintf('Starting a run.\n');
            if self.isIInFrontend_ ,
                if ~self.doesInterfaceExist_ ,
                    self.interface_ = ws.examples.mm.MicroManagerInterface() ;
                    self.doesInterfaceExist_ = true ;
                    
                    % Make sure the server is there
                    fprintf('About to check if the server is alive...\n') ;
                    self.interface_.isBusy() ;
                    % We ignore the response, and only check that we get a response at all.
                end
            end
        end
        
        function startingSweep(self ,~, ~)
            % Called just before each sweep
            fprintf('Starting a sweep.\n');
            if self.isIInFrontend_ ,
                self.interface_.runWithoutBlocking() ;   % Tell MM to start acquiring (should be setup to wait for TTL trigger)
            end
        end
        
        function completingSweep(self, ~, ~)
            fprintf('Completing a sweep.\n');
                % Wait for MM to be done acquiring
                checkInterval = 0.1 ;  % s
                while true,
                    isMMAcquiring = self.interface_.isAcquiring() ;
                    if isMMAcquiring
                        pause(checkInterval) ;    % wait a bit before checking again
                    else
                        break ;
                    end
                end                
        end
        
        function abortingSweep(self,~,~) %#ok<INUSD>
            fprintf('Oh noes!  A sweep aborted.\n');
        end
        
        function stoppingSweep(self,~,~) %#ok<INUSD>
            fprintf('A sweep was stopped.\n');
        end
        
        function completingRun(self,~,~) %#ok<INUSD>
            % Called just after each set of trials (a.k.a. each
            % "experiment")
            fprintf('Completing a run.\n');
        end
        
        function abortingRun(self,~,~) %#ok<INUSD>
            % Called if a trial set goes wrong, after the call to
            % trialDidAbort()
            fprintf('Oh noes!  A run aborted.\n');
        end
        
        function stoppingRun(self,~,~) %#ok<INUSD>
            fprintf('A run was stopped.\n');
        end
        
        function dataAvailable(~,~,~)
        end

        % These methods are called in the refiller process
        function startingEpisode(~,~,~)
        end
        
        function completingEpisode(~,~,~)
        end
        
        function abortingEpisode(~,~,~)
        end
        
        function stoppingEpisode(~,~,~)
        end
        
        % These methods are called in the looper process
        function samplesAcquired(self,looper,eventName,analogData,digitalData)  %#ok<INUSD>
            % Called each time a "chunk" of data (typically a few ms worth) 
            % is read from the DAQ board.
            %nScans = size(analogData,1);
            %fprintf('%s  Just acquired %d scans of data.\n',self.Greeting,nScans);                                    
        end        
    end  % public methods
end  % classdef


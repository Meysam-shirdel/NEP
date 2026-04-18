classdef Bradshaw_ECGData
    properties
        participantnumber
        age
        filename
        filedirectory
        edffilename
        ecg
        samplerate
        edfstarttime
        ecg_icwt
        ecg_icwt_30_45
    end


    methods
        function obj = filterecg(obj, band1)
            %ECG bandpass filtering.
           
            % Default bands
            if nargin < 2 || isempty(band1), band1 = [10 45]; end
            %if nargin < 2 || isempty(band1), band2 = [30 45]; end
            band2 = [30 45];
            order = 4;

            if isempty(obj.ecg)
                 error('Bradshaw_ECGData:filterecg:NoECG', ...
                       'obj.ecg is empty. Load ECG before filtering.');
            end

            fs = double(obj.samplerate);
            x = double(obj.ecg(:));

            nyq = fs / 2;

            % Butterworth bandpass filter
            [b1, a1] = butter(order, band1 / nyq, 'bandpass');
            [b2, a2] = butter(order, band2 / nyq, 'bandpass');

            % Zero-phase filtering 
            y1 = filtfilt(b1, a1, x);
            y2 = filtfilt(b2, a2, x);

            % Store results with original shape
            if isrow(obj.ecg)
                obj.ecg_icwt       = y1.';
                obj.ecg_icwt_30_45 = y2.';
            else
                obj.ecg_icwt       = y1;
                obj.ecg_icwt_30_45 = y2;
            end
        end
    end
end


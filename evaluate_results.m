function evaluate_results(record_name, detected_indices, Fs, Fs_orig, N, t, ecg, mwi)
    %evaluates detection accuracy against the MIT-BIH ATR file.
    
    % 1. Load Reference Annotations
    [ann_samples, ann_types] = read_atr_file([record_name '.atr']);
    
    %filter valid beat types (Normal + Arrhythmias)
    valid_beats = ismember(ann_types, ['N';'L';'R';'B';'A';'a';'J';'S';'V';'r';'e';'j';'n']);
    reference_peaks = round(ann_samples(valid_beats) * (Fs / Fs_orig));
    
    %sanity check for indices
    reference_peaks(reference_peaks > N) = []; 
    reference_peaks(reference_peaks < 1) = [];
    
    % 2. Correct Filter Delay
    delay_correction = 23; %the digital filters introduce a delay 
    corrected_detections = detected_indices - delay_correction;
    
    %remove invalid indices after shift
    corrected_detections = corrected_detections(corrected_detections > 0);
    corrected_detections(corrected_detections > N) = [];
    
    % 3. Calculate Statistics (TP, FP, FN)
    TP = 0; FN = 0;
    tolerance_window = 0.150 * Fs; % 150 ms tolerance
    
    %check every reference beat
    for k = 1:length(reference_peaks)
        ref_idx = reference_peaks(k);
        if isempty(corrected_detections), break; end
        
        [min_dist, ~] = min(abs(corrected_detections - ref_idx));
        
        if min_dist <= tolerance_window
            TP = TP + 1;
        else
            FN = FN + 1;
        end
    end
    FP = length(corrected_detections) - TP;
    
    Sensitivity = (TP / (TP + FN)) * 100;
    PositivePredictivity = (TP / (TP + FP)) * 100;
    
    fprintf('\n=========================================\n');
    fprintf(' PERFORMANCE EVALUATION (Record: %s)\n', record_name);
    fprintf('=========================================\n');
    fprintf(' Total Reference Beats:   %d\n', length(reference_peaks));
    fprintf(' Total Detected Beats:    %d\n', length(corrected_detections));
    fprintf('-----------------------------------------\n');
    fprintf(' True Positives (TP):     %d\n', TP);
    fprintf(' False Positives (FP):    %d\n', FP);
    fprintf(' False Negatives (FN):    %d\n', FN);
    fprintf('-----------------------------------------\n');
    fprintf(' SENSITIVITY:             %.2f%%\n', Sensitivity);
    fprintf(' POSITIVE PREDICTIVITY:   %.2f%%\n', PositivePredictivity);
    fprintf('=========================================\n');
   
    figure('Name', 'Detection Results vs Reference', 'NumberTitle', 'off');
    
    % Subplot 1: ECG Signal with Annotations
    ax(1) = subplot(2,1,1);
  
    plot(t, ecg, 'Color', [0 0.447 0.741], 'LineWidth', 1); hold on;
    plot(t(reference_peaks), ecg(reference_peaks), 'o', ...
         'MarkerEdgeColor', [0 0.6 0], 'MarkerSize', 8, 'LineWidth', 1.5);
    plot(t(corrected_detections), ecg(corrected_detections), 'ro', ...  %detection
         'MarkerFaceColor', 'r', 'MarkerSize', 5);
    title(['ECG Signal with Detections (Record ' record_name ')'], 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Amplitude [mV]', 'FontSize', 10);
    legend('ECG Signal', 'Reference (True)', 'Algorithm Detection', 'Location', 'Best');
    grid on; box on;
    
    % Subplot 2: MWI Signal
    ax(2) = subplot(2,1,2);
    plot(t, mwi, 'Color','b', 'LineWidth', 1.2); hold on;
    plot(t(corrected_detections), mwi(corrected_detections), 'rx', 'MarkerSize', 8, 'LineWidth', 1.5);
    
    title('Moving Window Integration (MWI) Output', 'FontSize', 12, 'FontWeight', 'bold');
    xlabel('Time [s]', 'FontSize', 11, 'FontWeight', 'bold');
    ylabel('Integrated Energy', 'FontSize', 10);
    legend('MWI Signal', 'Detection Points', 'Location', 'Best');
    grid on; box on;
    
    linkaxes(ax, 'x');
end

%read atr
function [pos, type] = read_atr_file(fname)
    fid = fopen(fname, 'r');
    if fid == -1, error(['Cannot open file: ' fname]); end
    A = fread(fid, [2, inf], 'uint8')';
    fclose(fid);
    
    pos = []; type = [];
    current_idx = 0;
    
    for i = 1:size(A,1)
        if A(i,2) == 0, continue; end
        val = A(i,2)*256 + A(i,1);
        code = bitshift(A(i,2), -2);
        data = bitand(val, 1023);
        
        current_idx = current_idx + data;
        
        type_char = 'Q';
        switch code
            case 1, type_char = 'N'; case 2, type_char = 'L'; case 3, type_char = 'R';
            case 4, type_char = 'a'; case 5, type_char = 'V'; case 6, type_char = 'F';
            case 7, type_char = 'J'; case 8, type_char = 'A'; case 9, type_char = 'S';
            case 10, type_char = 'E'; case 11, type_char = 'j'; case 28, type_char = '+';
        end
        pos = [pos; current_idx];
        type = [type; type_char];
    end
end
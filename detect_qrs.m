function qrs_indices = detect_qrs(mwi_signal, filtered_signal, Fs)
    %detects QRS complexes
  
    N = length(mwi_signal);
   
    %learning phase 1: Initialize Detection Thresholds
    
    training_period_samples = 2 * Fs; % 2 seconds window
    initial_window = mwi_signal(1:training_period_samples);
    
    %find peaks in this training window to estimate signal strength
    init_peaks = initial_window(initial_window > mean(initial_window));
    
    if isempty(init_peaks)
        max_signal_est = max(initial_window);
    else
        %avg the highest peaks to avoid using a single noise artifact
        sorted_peaks = sort(init_peaks, 'descend');
        max_signal_est = mean(sorted_peaks(1:min(length(sorted_peaks), 5)));
    end
    
    %init thresholds for the Integrated Signal (MWI)
    SPKI = max_signal_est * 0.5; %Signal Peak Estimate
    NPKI = SPKI * 0.5; %Noise Peak Estimate
    Threshold_I1 = NPKI + 0.25 * (SPKI - NPKI);
    Threshold_I2 = 0.5 * Threshold_I1;
    
    %initthresholds for the Filtered Signal (Bandpass)
    max_filt_est = max(filtered_signal(1:training_period_samples));
    SPKF = max_filt_est * 0.5;
    NPKF = SPKF * 0.5;
    Threshold_F1 = NPKF + 0.25 * (SPKF - NPKF);
   
    qrs_indices = [];       %beat location
    last_qrs_index = 0;     %last detected beat
    searchback_buffer = []; %store potential peaks for re-evaluation
    
    %RR Interval values (Heart Rate)
    RR_avg2 = Fs;           
    RR_low = 0.92 * RR_avg2;
    RR_high = 1.16 * RR_avg2;
    RR_miss = 1.66 * RR_avg2;
    
    refractory_period = 0.2 * Fs; %200 ms blind period after a beat
    
    fprintf('detecting.. ');
    
    for i = (training_period_samples + 2) : N
        
        %check if current point is a local peak
        current_val = mwi_signal(i);
        prev_val = mwi_signal(i-1);
        prev2_val = mwi_signal(i-2);
        
        is_peak = (prev_val > prev2_val) && (prev_val >= current_val);
        
        if is_peak
            peak_idx = i-1;
            peak_val_I = mwi_signal(peak_idx);
            
            %find exatc location on filtered signal for precision
            window_width = round(0.15 * Fs);
            start_search = max(1, peak_idx - window_width);
            end_search = min(N, peak_idx + window_width);
            
            [peak_val_F, rel_loc] = max(filtered_signal(start_search : end_search));
            peak_idx_F = start_search + rel_loc - 1;
            
            %check refractory period (cannot have two beats within 200ms)
            if (peak_idx - last_qrs_index) > refractory_period
                
                %decision rule: is it a valid qrs?
                if (peak_val_I > Threshold_I1) && (peak_val_F > Threshold_F1)
                    
                    % beat detected
                    qrs_indices = [qrs_indices, peak_idx_F];
                    last_qrs_index = peak_idx;
                    
                    %Update Signal Estimates (Learning)
                    SPKI = 0.125 * peak_val_I + 0.875 * SPKI;
                    SPKF = 0.125 * peak_val_F + 0.875 * SPKF;
                    
                    searchback_buffer = []; % Clear search-back buffer
                    
                    %learning phase 2: init/update RR intervals
                    if length(qrs_indices) > 1
                        rr_interval = qrs_indices(end) - qrs_indices(end-1);
                        
                        %check if the rhythm is regular
                        if (rr_interval > RR_low) && (rr_interval < RR_high)
                            RR_avg2 = 0.125 * rr_interval + 0.875 * RR_avg2;
                            
                            %update limits based on new average
                            RR_low = 0.92 * RR_avg2;
                            RR_high = 1.16 * RR_avg2;
                            RR_miss = 1.66 * RR_avg2;
                        end
                    end
                    
                else
                    %noise detected -> update Noise Estimates
                    NPKI = 0.125 * peak_val_I + 0.875 * NPKI;
                    NPKF = 0.125 * peak_val_F + 0.875 * NPKF;
                    
                    %save to buffer for ->  possible search-back later
                    searchback_buffer = [searchback_buffer; peak_idx, peak_val_I, peak_val_F];
                end
            end
            
            %update thresholds (Adaptive)
            Threshold_I1 = NPKI + 0.25 * (SPKI - NPKI);
            Threshold_I2 = 0.5 * Threshold_I1;
            Threshold_F1 = NPKF + 0.25 * (SPKF - NPKF);
        end
        
        %search back 
        % If we haven't found a beat for a long time (RR_miss limit)
        time_since_last_beat = i - last_qrs_index;
        
        if (time_since_last_beat > RR_miss) && ~isempty(searchback_buffer)
            
            %find the strongest peak in the noise buffer
            [max_buf_val, buf_idx] = max(searchback_buffer(:, 2)); 
            
            candidate_val_I = max_buf_val;
            candidate_val_F = searchback_buffer(buf_idx, 3);
            candidate_idx = searchback_buffer(buf_idx, 1);
            
            %check against lower threshold (Threshold 2)
            if (candidate_val_I > Threshold_I2)
                %recovered a missed beat
                
                %find location
                window_width = round(0.15 * Fs);
                start_search = max(1, candidate_idx - window_width);
                end_search = min(N, candidate_idx + window_width);
                [~, rel_loc] = max(filtered_signal(start_search : end_search));
                real_pos = start_search + rel_loc - 1;
                
                qrs_indices = [qrs_indices, real_pos];
                qrs_indices = sort(qrs_indices);
                last_qrs_index = candidate_idx;
                
                %update estimates (Special weighting for search-back)
                SPKI = 0.25 * candidate_val_I + 0.75 * SPKI;
                SPKF = 0.25 * candidate_val_F + 0.75 * SPKF;
                
                searchback_buffer = [];
                
                %recalculate treshold
                Threshold_I1 = NPKI + 0.25 * (SPKI - NPKI);
                Threshold_I2 = 0.5 * Threshold_I1;
                Threshold_F1 = NPKF + 0.25 * (SPKF - NPKF);
            end
        end
    end
    
    fprintf('done\n');
end
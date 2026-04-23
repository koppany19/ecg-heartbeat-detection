function [ecg_out, Fs_new, t_out] = preprocess_signal(signal_in, Fs_in)
    % resampling: 360hz -> 200hz
    Fs_new = 200;
    ecg_out = resample(signal_in, Fs_new, Fs_in);
    ecg_out = ecg_out - mean(ecg_out);
    
    N = length(ecg_out);
    t_out = (0:N-1) / Fs_new;
end
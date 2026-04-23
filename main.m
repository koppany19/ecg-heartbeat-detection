record_name = '100';

% 1. loading the data
[raw_signal, Fs_original] = load_ecg_data(record_name);

% 2. preprocessing, resample, removing DC comp
[ecg_signal, Fs, time_vector] = preprocess_signal(raw_signal, Fs_original);

% 3. Signalprocessing
[filtered_signal, integrated_signal] = apply_filters(ecg_signal);

% 4. detecting the QRS peaks
detected_indices = detect_qrs(integrated_signal, filtered_signal, Fs);

% 5. results and vizualization
evaluate_results(record_name, detected_indices, Fs, Fs_original, length(ecg_signal), time_vector, ecg_signal, integrated_signal);
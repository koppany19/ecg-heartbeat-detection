function [filtered, integrated] = apply_filters(ecg)
    N = length(ecg);
    
    % 1. Low-Pass Filter
    lp = zeros(1, N);
    for i = 13:N
        lp(i) = 2*lp(i-1) - lp(i-2) + ecg(i) - 2*ecg(i-6) + ecg(i-12);
    end
    lp = lp / 36;
    
    % 2. High-Pass Filter 
    hp = zeros(1, N);
    lp_sum = zeros(1, N);
    for i = 33:N
        lp_sum(i) = lp_sum(i-1) + lp(i) - lp(i-32);
        hp(i) = 32*lp(i-16) - lp_sum(i);
    end
    filtered = hp / 32; % filtered signal
    
    % 3. Deriative
    deriv = zeros(1, N);
    for i = 5:N
        deriv(i) = (1/8) * (-filtered(i-4) - 2*filtered(i-3) + 2*filtered(i-1) + filtered(i));
    end
    
    % 4. Squaring
    squared = deriv .^ 2;
    
    % 5. Moving window integration
    integrated = zeros(1, N);
    win_size = 30; % 150 ms
    for i = win_size:N
        integrated(i) = sum(squared(i-win_size+1:i)) / win_size;
    end
    
    % removing peaks at the start
    integrated(1:100) = 0;
    filtered(1:100) = 0;
    
    figure('Name', 'Signalprocessing step (Fig. 1)');
    t_idx = 1:min(800, N);
    subplot(5,1,1); plot(ecg(t_idx)); title('Signal raw'); axis tight;
    subplot(5,1,2); plot(filtered(t_idx)); title('Bandpass filter'); axis tight;
    subplot(5,1,3); plot(deriv(t_idx)); title('Derivative'); axis tight;
    subplot(5,1,4); plot(squared(t_idx)); title('Squaring'); axis tight;
    subplot(5,1,5); plot(integrated(t_idx), 'k', 'LineWidth', 1.5); title('Moving window integration'); axis tight;
end
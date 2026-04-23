function [signal, Fs] = load_ecg_data(record_name)
    fid = fopen([record_name '.hea'], 'r');
    if fid == -1
        error('error when opening .hea file!'); 
    end
    line = fgetl(fid);
    fclose(fid);
    
    parts = textscan(line, '%s %d %d %d');
    Fs = double(parts{3});
   
    fid = fopen([record_name '.dat'], 'r');
    if fid == -1
        error('error when opening .dat file!'); 
    end
    raw_bytes = fread(fid, inf, 'uint8');
    fclose(fid);
    
    % decoding format 212
    M = length(raw_bytes);
    num_samples = floor(M / 3);
    b1 = double(raw_bytes(1:3:3*num_samples));
    b2 = double(raw_bytes(2:3:3*num_samples));
    
    % MLII csatorna
    signal = b1 + bitand(b2, 15) * 256;
    signal(signal > 2047) = signal(signal > 2047) - 4096;
    
    disp(['Loaded successfully: ' record_name]);
end
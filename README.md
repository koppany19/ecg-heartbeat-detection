# ECG Heartbeat (QRS) Detection 🫀

This repository contains a MATLAB implementation of a QRS (R-peak) detection algorithm to identify heartbeats in Electrocardiogram (ECG) signals. The solution is based on the classic Pan-Tompkins algorithm and is evaluated using the MIT-BIH Arrhythmia Database.

This was created as a university university project focusing on digital signal processing and algorithm evaluation.

## 🎯 Project Objectives
* Implement a robust QRS detection algorithm.
* Preprocess ECG signals (filtering, derivative, squaring, moving window integration).
* Evaluate the algorithm's accuracy against expert annotations.
* Provide an efficient, close-to-real-time solution.

## 📁 Project Structure
The project is modularized into several MATLAB scripts for clarity and maintainability:

* `main.m`: The entry point of the application. It orchestrates the loading, processing, detection, and evaluation steps.
* `load_ecg_data.m`: Handles reading the raw ECG signal and annotation files.
* `preprocess_signal.m` & `apply_filters.m`: Applies the necessary signal processing steps (Bandpass filtering, differentiation, etc.) to isolate the QRS complex and reduce noise.
* `detect_qrs.m`: Contains the core peak detection logic with adaptive thresholds to identify the R-peaks accurately.
* `evaluate_results.m`: Compares the detected peaks against the ground truth annotations to calculate the accuracy of the detector.

## 📊 Dataset
The algorithm is tested on the **MIT-BIH Arrhythmia Database** provided by PhysioNet. 
* Sample data (`100.dat`, `100.hea`, `100.atr`) is included in this repository for quick testing.

## 🚀 How to Run
1. Clone the repository.
2. Open MATLAB and navigate to the project folder.
3. Open and run the `main.m` script.
4. The script will process the included sample record (`100`), plot the ECG signal with the detected R-peaks, and output the accuracy metrics to the console.

## 📚 References
* [Pan, Tompkins: A Real-Time QRS Detection Algorithm, IEEE Transactions on Biomedical Engineering (1985)](https://ieeexplore.ieee.org/document/4122029)
* [MIT-BIH Arrhythmia Database (PhysioNet)](https://physionet.org/content/mitdb/1.0.0/)
* [Electrocardiography (Wikipedia)](https://en.wikipedia.org/wiki/Electrocardiography)

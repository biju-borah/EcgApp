import numpy as np
import matplotlib.pyplot as plt
import scipy.signal as signal

def bandpass_filter(data, lowcut, highcut, fs, order=1):
    nyquist = 0.5 * fs
    low = lowcut / nyquist
    high = highcut / nyquist
    b, a = signal.butter(order, [low, high], btype='band')
    y = signal.lfilter(b, a, data)
    return y

def pan_tompkins_detector(ecg, fs):
    # Bandpass Filter
    # filtered_ecg = bandpass_filter(ecg, 0.5, 45, fs, order=1)
    
    # Derivative filter
    derivative_ecg = np.diff(ecg)
    
    # Squaring
    squared_ecg = derivative_ecg ** 2

    # Moving window integration
    # window_size = int(0.150 * fs)
    window_size = 4
    integrated_ecg = np.convolve(squared_ecg, np.ones(window_size)/window_size, mode='same')
    
    # Thresholding
    # threshold = np.mean(integrated_ecg) * 1.2
    # r_peaks = np.where(integrated_ecg > threshold)[0]
    
    threshold = 1.2 * np.mean(integrated_ecg)
    r_peaks = []

    for i in range(1, len(integrated_ecg) - 1):
        if integrated_ecg[i] > integrated_ecg[i-1] and integrated_ecg[i] > integrated_ecg[i+1] and integrated_ecg[i] > threshold:
            r_peaks.append(i)

    # Remove false positives (peaks too close to each other)
    i = 0
    while i < len(r_peaks) - 1:
        if r_peaks[i+1] - r_peaks[i] < 0.25 * fs:
            if ecg[r_peaks[i]] > ecg[r_peaks[i+1]]:
                r_peaks.pop(i+1)
            else:
                r_peaks.pop(i)
        else:
            i += 1

    return r_peaks, derivative_ecg, squared_ecg, integrated_ecg

def detect_pqrst(ecg, r_peaks, fs):
    pqrst_complexes = []
    prev_mid = 0
    curr_mid = 0
    print(r_peaks)
    for r_peak in r_peaks:
        # find mid between rr interval
        # if r_peak == r_peaks[0]:
        #     curr_mid = (r_peaks[1] + r_peaks[0]) // 2
        #     prev_mid = 0
        # elif r_peak == r_peaks[-1]:
        #     prev_mid = (r_peaks[-1] + r_peaks[-2]) // 2
        #     curr_mid = len(ecg) - 1
        # else:
        #     prev_mid = curr_mid
        #     curr_mid = (r_peaks[r_peaks.index(r_peak) + 1] + r_peaks[r_peaks.index(r_peak) - 1]) // 2

        # Q-wave detection (before R peak)
        q_wave = np.argmin(ecg[r_peak - int(0.05 * fs): r_peak]) + (r_peak - int(0.05 * fs))

        # P-wave detection (before R peak)
        p_start = 0 if r_peak - int(0.25 * fs) < 0 else r_peak - int(0.25 * fs)
        p_wave = np.argmax(ecg[p_start: q_wave]) + p_start
        
        # S-wave detection (after R peak)
        s_wave = np.argmin(ecg[r_peak : r_peak + int(0.05 * fs):]) + r_peak
         
        # T-wave detection (after R peak)
        t_wave = np.argmax(ecg[s_wave: r_peak + int(0.25 * fs)]) + s_wave

        pqrst_complexes.append({
            'P': p_wave,
            'Q': q_wave,
            'R': r_peak,
            'S': s_wave,
            'T': t_wave
        })
        print(pqrst_complexes)

    return pqrst_complexes

def plot_ecg_with_pqrst(ecg, pqrst_complexes):
    plt.figure(figsize=(15, 6))
    plt.plot(ecg, label='ECG Signal')
    
    for pqrst in pqrst_complexes:
        plt.plot(pqrst['P'], ecg[pqrst['P']], 'go', label='P wave' if pqrst == pqrst_complexes[0] else "")
        plt.plot(pqrst['Q'], ecg[pqrst['Q']], 'bo', label='Q wave' if pqrst == pqrst_complexes[0] else "")
        plt.plot(pqrst['R'], ecg[pqrst['R']], 'ro', label='R wave' if pqrst == pqrst_complexes[0] else "")
        plt.plot(pqrst['S'], ecg[pqrst['S']], 'mo', label='S wave' if pqrst == pqrst_complexes[0] else "")
        plt.plot(pqrst['T'], ecg[pqrst['T']], 'co', label='T wave' if pqrst == pqrst_complexes[0] else "")
    
    plt.xlabel('Sample')
    plt.ylabel('Amplitude')
    plt.legend()
    plt.title('ECG Signal with Detected PQRST Points')
    plt.show()

# Example usage
ecg_signal = np.loadtxt('lead2.txt')  # Load your ECG data here
fs = 125  # Sampling frequency in Hz

# Detect R peaks
r_peaks, derivative_ecg, squared_ecg, integrated_ecg  = pan_tompkins_detector(ecg_signal, fs)

# Detect PQRST complexes
pqrst_complexes = detect_pqrst(ecg_signal, r_peaks, fs)

# Print results
for i, pqrst in enumerate(pqrst_complexes):
    print(f"Beat {i+1}: P={pqrst['P']}, Q={pqrst['Q']}, R={pqrst['R']}, S={pqrst['S']}, T={pqrst['T']}")

# Plot ECG with PQRST points
plot_ecg_with_pqrst(ecg_signal, pqrst_complexes)
# plot_ecg_with_pqrst(derivative_ecg, pqrst_complexes)
# plot_ecg_with_pqrst(squared_ecg, pqrst_complexes)
# plot_ecg_with_pqrst(integrated_ecg, pqrst_complexes)

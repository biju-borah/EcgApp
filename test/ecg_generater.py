import numpy as np
import matplotlib.pyplot as plt

def generate_ecg_waveform(duration, fs):
    # Parameters
    heart_rate = 60  # Beats per minute
    num_beats = duration * (heart_rate / 60)
    t = np.linspace(0, duration, int(duration * fs))
    ecg_signal = np.zeros_like(t)

    # Generate synthetic ECG waveform
    for beat in range(int(num_beats)):
        t_beat = t - (beat * 60 / heart_rate)
        ecg_signal += np.piecewise(t_beat,
                                   [t_beat < 0.2, (t_beat >= 0.2) & (t_beat < 0.25), 
                                    (t_beat >= 0.25) & (t_beat < 0.3), (t_beat >= 0.3) & (t_beat < 0.35), 
                                    (t_beat >= 0.35) & (t_beat < 0.4)],
                                   [lambda t: 0.5 * np.sin(2 * np.pi * 5 * t),
                                    lambda t: 0.1 * np.sin(2 * np.pi * 30 * t),
                                    lambda t: -0.5,
                                    lambda t: -0.2,
                                    lambda t: 0.5 * np.sin(2 * np.pi * 10 * t)])

    # Normalize the signal
    ecg_signal /= np.max(np.abs(ecg_signal))
    
    return t, ecg_signal

# Parameters
duration = 10  # seconds
fs = 360  # sampling frequency in Hz

# Generate ECG signal
t, ecg_signal = generate_ecg_waveform(duration, fs)

# Save to file
np.savetxt('ecg_data.txt', ecg_signal)

# Plot the signal
plt.plot(t, ecg_signal)
plt.title('Synthetic ECG Signal')
plt.xlabel('Time (s)')
plt.ylabel('Amplitude')
plt.show()

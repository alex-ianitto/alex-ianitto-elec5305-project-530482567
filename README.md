# alex-ianitto-elec5305-project-530482567

This project is an interactive music-processing suite built in MATLAB that takes a recorded vocal or instrumental input and automatically:

Corrects pitch (autotune) — detecting pitch frame-by-frame using both a classical algorithm (YIN/autocorrelation) and a deep learning model (CREPE), then correcting it to the nearest note in a target scale using PSOLA/phase vocoder resynthesis.
Generates a matching accompaniment — detecting the key/chord progression of the recording and automatically selecting and transposing a pre-composed backing pattern (strings, drums) to accompany it.

The result is an end-to-end pipeline — record, denoise, correct, accompany, export — that demonstrates both classical DSP techniques and applied deep learning in a musically motivated, real-time-feasible system.

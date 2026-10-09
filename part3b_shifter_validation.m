%% part3b_shifter_validation.m
% Tests the pitch-shifting stage ON ITS OWN, with known target shifts, so the
% result does not depend on any pitch estimator. A steady 440 Hz tone is shifted
% by known amounts with shiftPitch and the output frequency is measured with a
% zero-padded, parabolic-interpolated FFT peak (resolution well under 1 cent).
clear; clc; close all;

fs = 48000;  f0 = 440;
t = (0:fs-1)'/fs;
x = zeros(size(t));
for h = 1:5, x = x + sin(2*pi*h*f0*t)/h; end
x = 0.9*x/max(abs(x));

shiftsCents = [-50 -30 -20 -10 10 20 30 50];
measuredCents = zeros(size(shiftsCents));
for k = 1:numel(shiftsCents)
    y = shiftPitch(x, shiftsCents(k)/100);          % semitones = cents/100
    y = y(round(0.2*fs):round(0.8*fs));              % drop edge artefacts
    measuredCents(k) = 1200*log2(fftPeakHz(y, fs, [300 600]) / f0);
end
err = measuredCents - shiftsCents;

fprintf('requested (cents)  measured (cents)  error (cents)\n');
fprintf('%14d  %16.1f  %13.1f\n', [shiftsCents; measuredCents; err]);
fprintf('Max |error| = %.1f cents\n', max(abs(err)));

figure('Color','w');
plot(shiftsCents, shiftsCents, 'k--'); hold on;
plot(shiftsCents, measuredCents, 'bo-');
xlabel('Requested shift (cents)'); ylabel('Measured shift (cents)'); grid on;
legend('Ideal', 'shiftPitch output', 'Location', 'best');
title('Pitch-shifter validation with known shifts');

function f = fftPeakHz(x, fs, range)
% Frequency of the strongest spectral peak in range (Hz), parabolic interpolation.
x = x(:);  n = numel(x);
x = x .* (0.5 - 0.5*cos(2*pi*(0:n-1)'/(n-1)));       % Hann window (no toolbox needed)
nfft = 2^nextpow2(8*n);
X = abs(fft(x, nfft));
fr = (0:nfft-1)' * fs/nfft;
idx = find(fr >= range(1) & fr <= range(2));
[~, kk] = max(X(idx));  k = idx(kk);
a = log(X(k-1));  b = log(X(k));  c = log(X(k+1));
p = 0.5*(a - c)/(a - 2*b + c);
f = (k - 1 + p) * fs/nfft;
end

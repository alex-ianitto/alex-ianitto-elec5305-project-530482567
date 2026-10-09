function [audioIn, fs, t, trueF0, intendedMidi, tChange] = makeTestSignal(vibDepthCents, detuneCents)
% MAKETESTSIGNAL  Synthetic "sung" test case: A4 with vibrato -> slide -> A#4 with vibrato.
%   vibDepthCents : vibrato depth (cents), default 70
%   detuneCents   : constant detune applied to the whole signal (cents), default 0
%   intendedMidi  : the INTENDED note N(t) per sample (69 then 70) - NOT the rounded F0
%   tChange       : time (s) of the genuine intended-note change (midpoint of the slide)
if nargin < 1, vibDepthCents = 70; end
if nargin < 2, detuneCents = 0; end

% 48 kHz on purpose: autocorrelation-type estimators have integer-lag
% resolution (~f0^2/fs Hz), which is ~50 cents at 16 kHz near 450 Hz.
fs = 48000;
vibRate = 5;                       % Hz
noteA4  = 440;  noteAs4 = 440*2^(1/12);
n1 = round(1.0*fs);  nT = round(0.15*fs);  n2 = n1;

t1 = (0:n1-1)'/fs;  t2 = (0:n2-1)'/fs;
f0_1 = noteA4  * 2.^(vibDepthCents*sin(2*pi*vibRate*t1)/1200);
f0_T = linspace(noteA4, noteAs4, nT)';
f0_2 = noteAs4 * 2.^(vibDepthCents*sin(2*pi*vibRate*t2)/1200);
trueF0 = [f0_1; f0_T; f0_2] * 2^(detuneCents/1200);

N = numel(trueF0);
t = (0:N-1)'/fs;                   % strictly increasing, unique
phase = 2*pi*cumsum(trueF0)/fs;    % one continuous phase -> no clicks at joins
audioIn = zeros(N,1);
for h = 1:5
    audioIn = audioIn + sin(h*phase)/h;
end
audioIn = 0.9*audioIn/max(abs(audioIn));

changeIdx = n1 + round(nT/2);
intendedMidi = 69*ones(N,1);
intendedMidi(changeIdx:end) = 70;
tChange = (changeIdx-1)/fs;
end

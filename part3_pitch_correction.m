%% part3_pitch_correction.m
% Pitch-correction stage driven by the STABILISED target notes, tested on a
% signal with a KNOWN detune so the correct answer is known.
%   For each run of constant stabilised note:
%       offset = target note - mean(estimated pitch in that run, ends trimmed)   (semitones)
%       the run is shifted by lambda*offset with shiftPitch (Audio Toolbox),
%       with cross-fades between runs.
% lambda = 0: no correction, 1: full correction of each note's tuning offset.
% Because the shift is constant per note, vibrato is preserved by design; a
% per-frame correction p_out = p + lambda*(p_T - p) is the extension.
clear; clc; close all;

detuneCents   = -30;      % singer is 30 cents flat throughout
vibDepthCents = 50;
lambda        = 1.0;
winSec = 0.20;  hystSemi = 0.1;  hopSec = 0.01;   % stabiliser operating point
xfade  = 0.02;            % cross-fade margin (s)
minSegSec = 0.25;         % runs shorter than this are left unshifted

[audioIn, fs, t, ~, intendedMidi, tChange] = makeTestSignal(vibDepthCents, detuneCents);
N = numel(audioIn);

%% 1. Estimate pitch, stabilise notes
[f0, tF0] = estimateF0(audioIn, fs, 'classical', hopSec);
midiEst  = hz2midi(f0);
notes    = stabiliseSmoothHyst(midiEst, max(1, round(winSec/hopSec)), hystSemi);
intended = interp1(t, intendedMidi, tF0, 'nearest', 'extrap');

%% 2. Correct each stabilised run
runStart = [1; find(diff(notes) ~= 0) + 1];
runEnd   = [runStart(2:end) - 1; numel(notes)];
audioOut = zeros(N,1);  wsum = zeros(N,1);
xf = round(xfade*fs);

for r = 1:numel(runStart)
    idx = runStart(r):runEnd(r);
    % Trim 0.1 s from each end of the run (transients / stabiliser delay), then use
    % the MEAN: with a staircase estimator and vibrato, the median proved unreliable.
    trim = round(0.1/hopSec);
    idxT = idx;  if numel(idx) > 2*trim + 5, idxT = idx(trim+1:end-trim); end
    offsetSemi = notes(idx(1)) - mean(midiEst(idxT), 'omitnan');
    shiftSemi  = lambda * offsetSemi;

    s1 = 1;  if r > 1,            s1 = round(tF0(runStart(r))*fs); end
    s2 = N;  if r < numel(runStart), s2 = round(tF0(runEnd(r))*fs);  end
    a1 = max(1, s1 - xf);  a2 = min(N, s2 + xf);
    seg = audioIn(a1:a2);

    segOut = seg;
    if numel(seg) >= round(minSegSec*fs) && abs(shiftSemi) > 1e-3
        try
            segOut = shiftPitch(seg, shiftSemi);
            segOut = segOut(:);
            if numel(segOut) >= numel(seg), segOut = segOut(1:numel(seg));
            else, segOut(end+1:numel(seg)) = 0; end
        catch ME
            warning('shiftPitch failed on run %d (%s) - left unshifted.', r, ME.message);
            segOut = seg;
        end
    end
    fprintf('Run %d: note %d, shift %+.1f cents\n', r, notes(idx(1)), 100*shiftSemi);

    w = ones(numel(seg),1);
    if a1 > 1, w(1:min(end,2*xf))         = linspace(0,1,min(numel(w),2*xf))'; end
    if a2 < N, w(max(1,end-2*xf+1):end)   = linspace(1,0,min(numel(w),2*xf))'; end
    audioOut(a1:a2) = audioOut(a1:a2) + w.*segOut;
    wsum(a1:a2)     = wsum(a1:a2) + w;
end
audioOut = audioOut ./ max(wsum, eps);
audioOut = 0.9*audioOut/max(abs(audioOut));

%% 3. Evaluate: re-estimate pitch of corrected audio against the intended note
[f0o, tFo] = estimateF0(audioOut, fs, 'classical', hopSec);
errBefore = 100*(midiEst        - intended);               % cents vs intended note
errAfter  = 100*(hz2midi(f0o)   - interp1(t, intendedMidi, tFo, 'nearest', 'extrap'));
fprintf('\nTuning error vs intended note (cents):\n');
fprintf('  before: median %+6.1f | MAE %5.1f | spread (std) %5.1f\n', median(errBefore,'omitnan'), mean(abs(errBefore),'omitnan'), std(errBefore,'omitnan'));
fprintf('  after : median %+6.1f | MAE %5.1f | spread (std) %5.1f\n', median(errAfter,'omitnan'),  mean(abs(errAfter),'omitnan'),  std(errAfter,'omitnan'));
fprintf('(median ~ tuning bias; std ~ vibrato + estimator noise, expected to stay similar.)\n');

% Per-run before/after (mean error, ends trimmed) - clearer than one global median
if numel(errAfter) == numel(errBefore)
    fprintf('\nPer stabilised run (mean error vs intended note, cents):\n');
    for r = 1:numel(runStart)
        idx = runStart(r):runEnd(r);
        idxT = idx;  if numel(idx) > 2*trim + 5, idxT = idx(trim+1:end-trim); end
        fprintf('  run %d (note %d): before %+6.1f -> after %+6.1f\n', r, notes(idx(1)), ...
            mean(errBefore(idxT),'omitnan'), mean(errAfter(idxT),'omitnan'));
    end
end

audiowrite('test_before.wav', audioIn, fs);
audiowrite('test_corrected.wav', audioOut, fs);

figure('Color','w','Name','Part 3 - correction');
plot(tF0, errBefore, 'r.-'); hold on; plot(tFo, errAfter, 'b.-');
yline(0, 'k--');
xlabel('Time (s)'); ylabel('Pitch error vs intended note (cents)'); grid on;
legend('Before', 'After correction', 'Location', 'best');
title(sprintf('Pitch correction, detune %d cents, lambda = %.1f', detuneCents, lambda));

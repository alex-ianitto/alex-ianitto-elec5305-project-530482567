%% part1_framewise_vs_stabilised.m
% Framewise vs stabilised intended-note decisions on the synthetic test case,
% for each pitch estimator. (Replaces pitch_note_stability_demo.m.)
clear; clc; close all;

vibDepthCents = 70;       % deep enough that vibrato crosses semitone boundaries
hopSec = 0.01;
[audioIn, fs, t, trueF0, intendedMidi, tChange] = makeTestSignal(vibDepthCents, 0);

estimators = {'classical', 'crepe'};
for k = 1:numel(estimators)
    try
        [f0, tF0] = estimateF0(audioIn, fs, estimators{k}, hopSec);
    catch ME
        warning('Skipping %s: %s', estimators{k}, ME.message);
        continue;
    end
    midiEst  = hz2midi(f0);
    intended = interp1(t, intendedMidi, tF0, 'nearest', 'extrap');

    framewise = round(midiEst);
    minHold   = stabiliseMinHold(midiEst, 6);                  % 60 ms
    smoothH   = stabiliseSmoothHyst(midiEst, 20, 0.2);         % 200 ms window, 0.2 semitone hysteresis

    fprintf('\n=== %s estimator (vibrato depth %d cents) ===\n', estimators{k}, vibDepthCents);
    names = {'Framewise', 'MinHold 60 ms', 'Smooth 200 ms + hyst 0.2'};
    outs  = {framewise, minHold, smoothH};
    for j = 1:3
        m = noteMetrics(outs{j}, tF0, intended, tChange, 70);
        fprintf('%-26s switches %3d | false %3d | delay %6.0f ms | accuracy %.2f\n', ...
            names{j}, m.switches, m.falseSwitches, 1000*m.delay, m.accuracy);
    end

    figure('Color','w','Name',['Part 1 - ' estimators{k}]);
    subplot(2,1,1);
    plot(t, trueF0, 'k', 'LineWidth', 1.5); hold on;
    plot(tF0, f0, 'b.-');
    ylabel('Frequency (Hz)'); grid on; legend('Reference F0', estimators{k}, 'Location', 'best');
    title(sprintf('F0 estimate (%s)', estimators{k}));
    subplot(2,1,2);
    stairs(tF0, framewise, 'Color', [.6 .6 1]); hold on;
    stairs(tF0, minHold, 'g', 'LineWidth', 1.2);
    stairs(tF0, smoothH, 'b', 'LineWidth', 1.8);
    stairs(tF0, intended, 'k--', 'LineWidth', 1.5);
    ylabel('MIDI note'); xlabel('Time (s)'); grid on;
    legend('Framewise', 'MinHold 60 ms', 'Smooth + hysteresis', 'Intended note', 'Location', 'best');
    title('Target-note decisions vs intended note N(t)');
end

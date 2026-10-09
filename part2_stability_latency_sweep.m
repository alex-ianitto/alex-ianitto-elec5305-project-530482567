%% part2_stability_latency_sweep.m
% Core experiment: sweep stabilisation strength and measure
%   false target-note switches   vs   delay to recognise the genuine note change.
% Three methods: MinHold, and causal Smoothing + hysteresis (3 hysteresis values).
% Results are saved to sweep_results_<estimator>.csv for the report/GitHub.
clear; clc; close all;

vibDepthCents = 70;
hopSec   = 0.01;
holdSec  = 0:0.02:0.30;                 % MinHold durations (0 = framewise)
winSec   = [0 0.05 0.10 0.15 0.20 0.25 0.30];   % smoothing windows (0 = none)
hystVals = [0 0.1 0.2];                 % hysteresis (semitones)

[audioIn, fs, t, ~, intendedMidi, tChange] = makeTestSignal(vibDepthCents, 0);
estimators = {'classical', 'crepe'};

for k = 1:numel(estimators)
    est = estimators{k};
    try
        [f0, tF0] = estimateF0(audioIn, fs, est, hopSec);
    catch ME
        warning('Skipping %s: %s', est, ME.message);
        continue;
    end
    midiEst  = hz2midi(f0);
    intended = interp1(t, intendedMidi, tF0, 'nearest', 'extrap');

    rows = struct('method',{},'paramMs',{},'hyst',{},'switches',{}, ...
                  'falseSwitches',{},'delayMs',{},'accuracy',{});

    for hs = holdSec
        notes = stabiliseMinHold(midiEst, max(1, round(hs/hopSec)));
        m = noteMetrics(notes, tF0, intended, tChange, 70);
        rows(end+1) = struct('method',"MinHold",'paramMs',1000*hs,'hyst',NaN, ...
            'switches',m.switches,'falseSwitches',m.falseSwitches, ...
            'delayMs',1000*m.delay,'accuracy',m.accuracy); %#ok<SAGROW>
    end
    for h = hystVals
        for ws = winSec
            notes = stabiliseSmoothHyst(midiEst, max(1, round(ws/hopSec)), h);
            m = noteMetrics(notes, tF0, intended, tChange, 70);
            rows(end+1) = struct('method',string(sprintf('SmoothHyst h=%.1f',h)), ...
                'paramMs',1000*ws,'hyst',h,'switches',m.switches, ...
                'falseSwitches',m.falseSwitches,'delayMs',1000*m.delay, ...
                'accuracy',m.accuracy); %#ok<SAGROW>
        end
    end
    T = struct2table(rows);
    writetable(T, sprintf('sweep_results_%s.csv', est));

    fprintf('\n=== %s estimator ===\n', est);
    disp(T);
    fprintf('%d of %d settings MISSED the genuine transition (delay = NaN).\n', ...
        sum(isnan(T.delayMs)), height(T));
    ok = T.falseSwitches == 0 & ~isnan(T.delayMs);
    if any(ok)
        Tok = T(ok,:);
        [~, b] = min(Tok.delayMs);
        fprintf('Lowest-latency setting with zero false switches: %s, param %.0f ms -> delay %.0f ms\n', ...
            Tok.method(b), Tok.paramMs(b), Tok.delayMs(b));
    else
        fprintf('No setting achieved zero false switches while catching the transition.\n');
    end

    figure('Color','w','Name',['Part 2 - ' est]);
    methods = unique(T.method, 'stable');
    subplot(1,2,1); hold on;
    for j = 1:numel(methods)
        sub = T(T.method == methods(j), :);
        plot(sub.delayMs, sub.falseSwitches, '-o', 'DisplayName', char(methods(j)));
    end
    xlabel('Delay to recognise genuine note change (ms)'); ylabel('False note switches');
    title(sprintf('Stability vs latency (%s)', est)); grid on; legend('Location','northeast');
    subplot(1,2,2); hold on;
    for j = 1:numel(methods)
        sub = T(T.method == methods(j), :);
        plot(sub.delayMs, sub.accuracy, '-o', 'DisplayName', char(methods(j)));
    end
    xlabel('Delay (ms)'); ylabel('Frame-level note accuracy');
    title('Accuracy vs latency'); grid on;
end

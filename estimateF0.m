function [f0, tF0] = estimateF0(audioIn, fs, method, hopSec)
% ESTIMATEF0  Frame-wise F0 using existing MATLAB implementations.
%   method : 'classical' -> pitch(...,'Method','NCF')   (autocorrelation family, YIN-like)
%            'crepe'     -> pitchnn(...)                (pretrained CREPE; model must be downloaded)
if nargin < 4, hopSec = 0.01; end
switch lower(method)
    case 'classical'
        frameLen = round(0.04*fs);
        hopLen   = round(hopSec*fs);
        % Default range is ~50-400 Hz, which excludes A4 and causes octave errors.
        [f0, loc] = pitch(audioIn, fs, 'Method','NCF', 'Range',[80 1000], ...
            'WindowLength',frameLen, 'OverlapLength',frameLen-hopLen);
        tF0 = loc(:)/fs;
    case 'crepe'
        % CREPE uses fixed 1024-sample frames at 16 kHz (64 ms), so only the
        % overlap can be set. Overlap chosen to give roughly hopSec spacing.
        overlapPct = 100*(1 - hopSec/0.064);
        [f0, loc] = pitchnn(audioIn, fs, 'ModelCapacity','full', ...
            'ConfidenceThreshold',0.5, 'OverlapPercentage',overlapPct);
        % loc units differ between releases (samples vs seconds) - detect which.
        if max(loc) > 2*numel(audioIn)/fs, tF0 = loc(:)/fs; else, tF0 = loc(:); end
    otherwise
        error('Unknown method "%s" (use ''classical'' or ''crepe'').', method);
end
f0 = f0(:);
end

function notes = stabiliseSmoothHyst(midiTrack, winFrames, hystSemi)
% STABILISESMOOTHHYST  Causal trailing-median smoothing of the pitch track
% (window = winFrames), then nearest-note quantisation with hysteresis: the
% note only changes once the smoothed pitch is more than (0.5 + hystSemi)
% semitones from the current note. A window of about one vibrato period
% recovers the vibrato's centre pitch, which is what defines the intended note.
N = numel(midiTrack);
notes = nan(N,1);
if winFrames > 1
    s = movmedian(midiTrack, [winFrames-1 0], 'omitnan');   % causal (no look-ahead)
else
    s = midiTrack;
end
first = find(~isnan(s), 1);
if isempty(first), return; end
current = round(s(first));
notes(1:first) = current;
for i = first:N
    if ~isnan(s(i)) && abs(s(i) - current) > 0.5 + hystSemi
        current = round(s(i));
    end
    notes(i) = current;
end
end

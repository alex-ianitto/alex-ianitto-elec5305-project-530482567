function notes = stabiliseMinHold(midiTrack, holdFrames)
% STABILISEMINHOLD  A candidate note must be the nearest note for holdFrames
% CONSECUTIVE frames before the target note changes. holdFrames = 1 is framewise.
N = numel(midiTrack);
notes = nan(N,1);
first = find(~isnan(midiTrack), 1);
if isempty(first), return; end
current = round(midiTrack(first));  candidate = current;  holdCount = 0;
notes(1:first) = current;
for i = first:N
    if isnan(midiTrack(i)), notes(i) = current; continue; end
    c = round(midiTrack(i));
    if c == current
        holdCount = 0;
    else
        if c == candidate, holdCount = holdCount + 1;
        else,              candidate = c;  holdCount = 1;
        end
        if holdCount >= holdFrames
            current = candidate;  holdCount = 0;
        end
    end
    notes(i) = current;
end
end

function m = noteMetrics(notes, tF0, intendedAtFrames, tChange, newNote)
% NOTEMETRICS  Note-level metrics for one stabilisation setting.
%   switches      : total target-note changes
%   falseSwitches : switches beyond the single genuine change
%   delay         : time (s) from the genuine change until the output first
%                   equals the new note (NaN = transition missed). NB: an
%                   unstable output can "reach" the new note early just by
%                   fluttering through it, so read delay together with falseSwitches.
%   accuracy      : fraction of frames equal to the intended note
valid = ~isnan(notes);
m.switches      = sum(diff(notes(valid)) ~= 0);
m.falseSwitches = max(m.switches - 1, 0);
idx = find(tF0 >= tChange & notes == newNote, 1, 'first');
if isempty(idx), m.delay = NaN; else, m.delay = tF0(idx) - tChange; end
m.accuracy = mean(notes(valid) == intendedAtFrames(valid));
end

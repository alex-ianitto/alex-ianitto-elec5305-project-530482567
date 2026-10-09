function m = hz2midi(f0)
% HZ2MIDI  Hz -> fractional MIDI note number. Unvoiced/NaN/zero frames -> NaN.
m = nan(size(f0));
v = f0 > 0;
m(v) = 69 + 12*log2(f0(v)/440);
end

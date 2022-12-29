function [spectgram]=trace2specgram(signal)
 
t = signal(:,1);
s = signal(:,2);
dt = t(2)- t(1);
Fs=1/dt;

dB_lower_limit=-100;
number_of_step = 200;
step = round(length(t)/number_of_step);
window = 8*step;
nfft = 2^nextpow2(8*window);
noverlap= window-step;

[S, f, t] = specgram(s, nfft, Fs, window, noverlap);

S = 2*abs(S);

S = S/max(S(:));

S=20*log10(S);

S(S<dB_lower_limit)=dB_lower_limit;

[T F] = meshgrid(t,f);
spectgram=[T(:),F(:),S(:)];

endfunction

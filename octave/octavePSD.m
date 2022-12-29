function octavePSD = octavePSD(s,octaveFreq)

t = s(:,1);
s = s(:,2:end);

dt= t(2)-t(1);
Fs = 1/dt;

[nt nstation] = size(s);

nfft = 2^nextpow2(nt);
f = transpose(Fs*(0:(nfft/2))/nfft);
S = fft(s,nfft);

psd = 2*abs(S(1:nfft/2+1,:)/nfft).^2;
psd = 10*log10(psd);

[octaveFreqLower, octaveFreqUpper] = octaveBand(octaveFreq,1/3);
[octaveFreqLower octaveFreqLowerIndex]=findNearest(f,octaveFreqLower);
[octaveFreqUpper octaveFreqUpperIndex]=findNearest(f,octaveFreqUpper);

octavePSD=zeros(length(octaveFreq),nstation);

for iOctaveFreq=1:length(octaveFreq)
  octavePSD(iOctaveFreq,:) = mean(psd([octaveFreqLowerIndex(iOctaveFreq):octaveFreqUpperIndex(iOctaveFreq)],:));
end

end

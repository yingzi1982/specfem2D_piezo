function [spectrum]=trace2spectrum(signal)

t = signal(:,1);
t = t-t(1);
dt = t(2)- t(1);
Fs=1/dt;

s = signal(:,2:end);

nfft = 2^nextpow2(10*length(t));
f = transpose(Fs*(0:(nfft/2))/nfft);
spectrum = fft(s,nfft);
%PSD = 2*abs(spectrum(1:nfft/2+1)/nfft).^2;
%PSD = 10*log10(PSD);
%sourceFrequencySpetrum =[f,PSD];
%spectrum = 2*abs(spectrum(1:nfft/2+1)/nfft);
spectrum = 2*spectrum(1:nfft/2+1,:)/nfft;

%spectrum = spectrum/max(spectrum);

spectrum =[f,spectrum];
endfunction

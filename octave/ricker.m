function [t, r] = ricker(fc, dt)

t = transpose([-1/fc:dt:1/fc]);
r = (1-2*pi^2*fc^2*t.^2).*exp(-pi^2*fc^2*t.^2);

%L = length(t);
%fs = 1/dt;
%NFFT =8*2^nextpow2(L);
%R = fft(r,NFFT)/L;
%f = fs/2*linspace(0,1,NFFT/2+1);
%R = 2*R(1:NFFT/2+1);

%df = 
%f= [0:df:3*fc];
%R = 2/sqrt(pi)*f.^2/fc^3.*exp(-f.^2/fc^2);
end

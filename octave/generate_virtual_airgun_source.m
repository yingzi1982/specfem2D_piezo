#!/usr/bin/env octave

%clear all
%close all
%clc

s_cut = load('../backup/SeiSx_23_azimuths.txt');
t_cut = s_cut(:,1);
colNumber=11; % 92 deg, K column
s_cut = s_cut(:,colNumber);
s_cut = s_cut - mean(s_cut);
dt = mean(diff(t_cut));

sourceTimeFunction= [t_cut s_cut];
save("-ascii",['../backup/virtualAirgunSourceTimeFunction'],'sourceTimeFunction')

nfft = 2^nextpow2(length(t_cut));
S_cut = fft(s_cut,nfft);

Fs=1/dt;
f = transpose(Fs*(0:(nfft/2))/nfft);
P_cut = abs(S_cut/nfft);
sourceFrequencySpetrum =[f,2*P_cut(1:nfft/2+1)];
save("-ascii",['../backup/virtualAirgunSourceFrequencySpetrum'],'sourceFrequencySpetrum')

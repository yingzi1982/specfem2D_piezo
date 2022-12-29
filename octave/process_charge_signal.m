#!/usr/bin/env octave

clear all
close all
clc

%charge9 = dlmread('../backup/charge_forceModel/charge_9_pairs','');
%charge49 = dlmread('../backup/charge_forceModel/charge_49_pairs','');
%charge99 = dlmread('../backup/charge_forceModel/charge_99_pairs','');
%charge= [charge9 charge49(:,2) charge99(:,2)];

%charge9 = dlmread('../backup/charge_crossFieldModel/charge_9_pairs','');
%charge49 = dlmread('../backup/charge_crossFieldModel/charge_49_pairs','');
%charge99 = dlmread('../backup/charge_crossFieldModel/charge_99_pairs','');
%charge= [charge9 charge49(:,2) charge99(:,2)];

%charge0 = dlmread('../backup/charge_crossFieldModel/charge_0nm','');
%charge200 = dlmread('../backup/charge_crossFieldModel/charge_200nm','');
%charge400 = dlmread('../backup/charge_crossFieldModel/charge_400nm','');
%charge= [charge0 charge200(:,2) charge400(:,2)];

%window_length = 1001;
%window = hanning(window_length);
%window = window([ceil(window_length/2):end]);
%window_length = length(window);
%charge(end-window_length+1:end,[2:end]) = charge(end-window_length+1:end,[2:end]).*window;

charge = dlmread('../backup/charge','');
current = dlmread('../backup/current','');
voltage = dlmread(['../backup/sourceTimeFunction'],'');

if rows(charge) != rows(voltage)
  error('the charge and voltage are not equal length!')
end
t = voltage(:,1);

voltage_spectrum = trace2spectrum(voltage);
charge_spectrum = trace2spectrum(charge);
current_spectrum = trace2spectrum(current);
f = voltage_spectrum(:,1);
admittance = i*2*pi*f.*charge_spectrum(:,2:end)./voltage_spectrum(:,2:end);
%admittance = current_spectrum(:,2:end)./voltage_spectrum(:,2:end);
freqIndex = find(f>0.5e9&f<1.5e9);
f = f(freqIndex);
admittance = admittance(freqIndex,:);
conductance = real(admittance);
susceptance = imag(admittance);

%conductance = conductance./max(abs(conductance));
%susceptance = susceptance./max(abs(susceptance));
max(abs(conductance))
max(abs(susceptance))
%[M,I] = max(conductance(:,3));
%conductance_peak_frequency = f(I)
%[M1,I1] = max(susceptance(:,3));
%[M2,I2] = min(susceptance(:,3));
%susceptance_peak_frequency = f([I1 I2])

conductance = [f conductance];
susceptance = [f susceptance];

dlmwrite('../backup/conductance',conductance,' ');
dlmwrite('../backup/susceptance',susceptance,' ');

%admittance_angle = [f rad2deg(angle(admittance))];

%admittance_abs = [f 20*log10(abs(admittance)./max(abs(admittance)))];
%min(admittance_abs(:,2:end))
%max(admittance_abs(:,2:end))
%dlmwrite('../backup/admittance_abs',admittance_abs,' ');
%dlmwrite('../backup/admittance_angle',admittance_angle,' ');

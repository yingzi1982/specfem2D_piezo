#!/usr/bin/env octave

clear all
close all
clc

arg_list = argv ();
if length(arg_list) > 0
  signal_name=arg_list{1};
else
  signal_name = input('Please input signal name: ','s');
end

signal_file=['../backup/' signal_name];
disp(['Filter signal: ' signal_file])

s = load(signal_file);

t = s(:,1);
s = s(:,2);
dt= t(2)-t(1);
Fs = 1/dt;

filter_parameters=load("-ascii",['../backup/filter_parameters']);
fcuts = filter_parameters(1,:);
mags = round(filter_parameters(2,:));
devs = filter_parameters(3,:);
[n,Wn,beta,ftype] = kaiserord(fcuts,mags,devs,Fs);
hh = fir1(n,Wn,ftype,kaiser(n+1,beta),'noscale');
s = filtfilt(hh,1,s);

s = [t s];

save("-ascii",['../backup/' signal_name '_filtered'],'s')


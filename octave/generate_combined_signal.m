#!/usr/bin/env octave

clear all
close all
clc

data_folder=['../backup/'];

pressure_signal=load([data_folder 'ARRAY.S1.PRE.semp']);
t = pressure_signal(:,1);
t = t - min(t);
pressure_signal = pressure_signal(:,2)*7.5337e+07;

%velocity_signal_x=load([data_folder 'ARRAY.S1.BXX.semv']);
%velocity_signal_z=load([data_folder 'ARRAY.S1.BXZ.semv']);
%velocity_signal = [velocity_signal_x(:,2) velocity_signal_z(:,2)]*2.2395e+04;

signal = [t pressure_signal];
%signal = [signal velocity_signal];
dlmwrite('../backup/ts.txt',signal,' ');


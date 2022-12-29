#!/usr/bin/env octave

clear all
close all
clc

arg_list = argv ();

if length(arg_list) > 0
  filter_dimension = arg_list{1};
else
  error("Please input filter dimension.")
end

%I: model_number 1 rho Vp Vs 0 0 QKappa Qmu 0 0 0 0 0 0
%II: model_number 2 rho c11 c13 c15 c33 c35 c55 c12 c23 c25 0 0 0

[piezo]=generate_piezomaterial_parameters(filter_dimension);
c   = piezo.elastic_constant;
rho = piezo.density;
Vp = piezo.Vp;
Vs = piezo.Vs;
QKappa = piezo.QKappa;
QMu = piezo.QMu;

switch filter_dimension
case '2D'
istropic_piezo_material = [1 rho Vp Vs 0 0  QKappa QMu  0 0 0 0 0 0];
piezo_material = [2 rho c(1,1) c(1,3) c(1,5) c(3,3) c(3,5) c(5,5) c(1,2) c(2,3) c(2,5) 0 0 0];
finger_material = [1 2700 6375 3130   0 0  9999 9999  0 0 0 0 0 0];

materials = [istropic_piezo_material; piezo_material; finger_material];
nbmodels = rows(materials);
models = [[1:nbmodels]' materials];

fileID = fopen(['../backup/nbmodels'],'w');
fprintf(fileID, '\n')
fprintf(fileID, '#------------------------------------------------------------\n')
fprintf(fileID, 'nbmodels                        = %i\n',nbmodels)
fprintf(fileID, '#------------------------------------------------------------\n')
fprintf(fileID, '\n')
fclose(fileID);
%-------------------------------------------------------------------------------------

fileID = fopen(['../backup/models'],'w');
for nmodel = [1:nbmodels]
  fprintf(fileID, '%i %i %g %g %g %g %g %g %g %g %g %g %i %i %i \n', ...
  models(nmodel,1),  models(nmodel,2),  models(nmodel,3),  models(nmodel,4),  models(nmodel,5),...
  models(nmodel,6),  models(nmodel,7),  models(nmodel,8),  models(nmodel,9),  models(nmodel,10),...
  models(nmodel,11), models(nmodel,12), models(nmodel,13), models(nmodel,14), models(nmodel,15))
end
fprintf(fileID, '\n')
fclose(fileID);
case '3D'
otherwise
error('Wrong flter dimension!')
end

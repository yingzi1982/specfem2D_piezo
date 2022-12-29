#!/usr/bin/env octave

clear all
close all
clc

arg_list = argv ();
if length(arg_list) > 0
  filter_type  = arg_list{1};
  filter_dimension = arg_list{2};
else
  error('Please input filter type and dimension.');
end

[piezo]=generate_piezomaterial_parameters(filter_dimension);

dx = piezo.dx;
dy = piezo.dy;
dz = piezo.dz;

xmin = piezo.xmin;
ymin = piezo.ymin;
zmin = piezo.zmin;

xmax = piezo.xmax;
ymax = piezo.ymax;
zmax = piezo.zmax;

piezo_range_selection = '.false.';
if strcmp(piezo_range_selection,'.true.')
  finger_x_range = dlmread('../backup/finger_x_range','');
  finger_width = dlmread('../backup/finger_width','');
  offset = finger_width/10;
  xmin = finger_x_range(1) - offset; 
  xmax = finger_x_range(2) + offset;
  zmin = zmax - offset;
  zmax = zmax;


  nx = round((xmax-xmin)/dx+1); 
  ny = round((ymax-ymin)/dy+1);
  nz = round((zmax-zmin)/dz+1);

  x = linspace(xmin,xmax,nx);
  y = linspace(ymin,ymax,ny);
  z = linspace(zmin,zmax,nz);
else
  x = piezo.x;
  y = piezo.y;
  z = piezo.z;
end

fileID = fopen(['../backup/range_selection'],'w');
fprintf(fileID, 'xmin = %g\n', xmin);
fprintf(fileID, 'ymin = %g\n', ymin);
fprintf(fileID, 'zmin = %g\n', zmin);
fprintf(fileID, '\n');

fprintf(fileID, 'xmax = %g\n', xmax);
fprintf(fileID, 'ymax = %g\n', ymax);
fprintf(fileID, 'zmax = %g\n', zmax);
fclose(fileID);

%---------------------------------
positive_finger_V = 1;
negative_finger_V = 0;
%---------------------------------
%positive_finger_grid = dlmread('../backup/positive_finger_grid',' ');
%negative_finger_grid = dlmread('../backup/negative_finger_grid',' ');

positive_finger_contact_interface = dlmread('../backup/positive_finger_contact_interface',' ');
negative_finger_contact_interface = dlmread('../backup/negative_finger_contact_interface',' ');

positive_finger_source = positive_finger_contact_interface;
negative_finger_source = negative_finger_contact_interface;
%positive_finger_source = positive_finger_grid;
%negative_finger_source = negative_finger_grid;

switch filter_dimension
case '2D'

[X Z] = meshgrid (x,z);
%V = relaxationMethod(x,y,z,positive_finger_source,negative_finger_source,positive_finger_V,negative_finger_V,filter_dimension);
V = summationMethod(x,y,z,positive_finger_source,negative_finger_source,positive_finger_V,negative_finger_V,filter_dimension);

[E_x E_z] = gradient(V,dx,dz);
E_x = -E_x;
E_z = -E_z;

E_x_negative_finger_contact_interface = interp2(X,Z,E_x,negative_finger_contact_interface(:,1),negative_finger_contact_interface(:,2),'linear');
E_z_negative_finger_contact_interface = interp2(X,Z,E_z,negative_finger_contact_interface(:,1),negative_finger_contact_interface(:,2),'linear');
E_x_positive_finger_contact_interface = interp2(X,Z,E_x,positive_finger_contact_interface(:,1),positive_finger_contact_interface(:,2),'linear');
E_z_positive_finger_contact_interface = interp2(X,Z,E_z,positive_finger_contact_interface(:,1),positive_finger_contact_interface(:,2),'linear');

dlmwrite('../backup/electric_NF_contact_interface',[negative_finger_contact_interface E_x_negative_finger_contact_interface E_z_negative_finger_contact_interface],' ');
dlmwrite('../backup/electric_PF_contact_interface',[positive_finger_contact_interface E_x_positive_finger_contact_interface E_z_positive_finger_contact_interface],' ');

[E_theta,E_rho] = cart2pol(E_x,E_z);

electric=[reshape(X,[],1) reshape(Z,[],1) reshape(E_rho,[],1) reshape(E_theta,[],1) [reshape(E_x,[],1) reshape(E_z,[],1)]];
potential=[reshape(X,[],1) reshape(Z,[],1) [reshape(V,[],1)]];
case '3D'
otherwise
error('Wrong filter dimension!')
end

dlmwrite('../backup/electric',electric,' ');
dlmwrite('../backup/potential',potential,' ');

#!/usr/bin/env octave

clear all
close all
clc

arg_list = argv ();
if length(arg_list) > 0
  filter_dimension = arg_list{1};
else
  error('Please input filter dimension');
end

[piezo]=generate_piezomaterial_parameters(filter_dimension);
dx = piezo.dx;                
dy = piezo.dy;                
dz = piezo.dz;                

[xmin_status xmin] = system('grep xmin ../backup/range_selection | cut -d = -f 2');
xmin = str2num(xmin);
[xmax_status xmax] = system('grep xmax ../backup/range_selection | cut -d = -f 2');
xmax = str2num(xmax);

[ymin_status ymin] = system('grep ymin ../backup/range_selection | cut -d = -f 2');
ymin = str2num(ymin);
[ymax_status ymax] = system('grep ymax ../backup/range_selection | cut -d = -f 2');
ymax = str2num(ymax);

[zmin_status zmin] = system('grep zmin ../backup/range_selection | cut -d = -f 2');
zmin = str2num(zmin);
[zmax_status zmax] = system('grep zmax ../backup/range_selection | cut -d = -f 2');
zmax = str2num(zmax);

nx = round((xmax-xmin)/dx+1);
ny = round((ymax-ymin)/dy+1);
nz = round((zmax-zmin)/dz+1);

x = linspace(xmin,xmax,nx);
y = linspace(ymin,ymax,ny);
z = linspace(zmin,zmax,nz);

piezoelectric_constant = piezo.piezoelectric_constant;

switch filter_dimension
case '2D'
  [X Z] = meshgrid(x,z);
  electric=dlmread('../backup/electric');
  Ex = electric(:,[5]);
  Ez = electric(:,[6]);
  E = [Ex Ez];
  E = transpose(E);
  piezoelectric_constant = piezoelectric_constant([1 3],[1 3 5]);

  stress = -transpose(piezoelectric_constant)*E;

  stress1 = reshape(stress(1,:),nz,nx);
  stress2 = reshape(stress(2,:),nz,nx);
  stress3 = reshape(stress(3,:),nz,nx);

  [stress1partialx, stress1partialz] = gradient(stress1,dx,dz);
  [stress2partialx, stress2partialz] = gradient(stress2,dx,dz);
  [stress3partialx, stress3partialz] = gradient(stress3,dx,dz);

  bodyforce_x = (stress1partialx + stress3partialz);
  bodyforce_z = (stress2partialz + stress3partialx);

  %onlySourceAtEdge='.true.'
  %if strcmp ('.true.', strtrim(onlySourceAtEdge))
    %positive_finger_edge=dlmread('../backup/positive_finger_edge','');
    %negative_finger_edge=dlmread('../backup/negative_finger_edge','');
    %finger_edge = [positive_finger_edge;negative_finger_edge];
    %[finger_edge_x finger_edge_xIndex] = findNearest(x,finger_edge(:,1));
    %bodyforce_x = bodyforce_x(end,finger_edge_xIndex);
    %bodyforce_z = bodyforce_z(end,finger_edge_xIndex);
    %X = X(end,finger_edge_xIndex);
    %Z = Z(end,finger_edge_xIndex);
  %end
  
  [bodyforce_theta,bodyforce_rho] = cart2pol(bodyforce_x,bodyforce_z);

  bodyforce=[reshape(X,[],1) reshape(Z,[],1) reshape(bodyforce_rho,[],1) reshape(bodyforce_theta,[],1) reshape(bodyforce_x,[],1) reshape(bodyforce_z,[],1)];
  polygon_piezo = piezo.polygon;
  [in,on] = inpolygon (bodyforce(:,1), bodyforce(:,2), polygon_piezo(:,1), polygon_piezo(:,2));
  mask_piezo = in | on;
  bodyforce = bodyforce(mask_piezo,:);

  force_x = bodyforce_x*dx*dz;
  force_z = bodyforce_z*dx*dz;

  [force_theta,force_rho] = cart2pol(force_x,force_z);

  force=[reshape(X,[],1) reshape(Z,[],1) reshape(force_rho,[],1) reshape(force_theta,[],1) reshape(force_x,[],1) reshape(force_z,[],1)];
  polygon_piezo = piezo.polygon;
  [in,on] = inpolygon (force(:,1), force(:,2), polygon_piezo(:,1), polygon_piezo(:,2));
  mask_piezo = in | on;
  force = force(mask_piezo,:);
case '3D'
  %[X Y Z] = meshgrid(x,y,z);
  %electric=dlmread('../backup/electric');
  %Ex = electric(:,[6]);
  %Ey = zeros(size(Ex));
  %Ez = electric(:,[7]);
  %E = [Ex Ey Ez];
  %E = transpose(E);
 
  %stress = -transpose(piezoelectric_constant)*E;
 
  %stress1 = reshape(stress(1,:),ny,nx,nz);
  %stress2 = reshape(stress(2,:),ny,nx,nz);
  %stress3 = reshape(stress(3,:),ny,nx,nz);
  %stress4 = reshape(stress(4,:),ny,nx,nz);
  %stress5 = reshape(stress(5,:),ny,nx,nz);
  %stress6 = reshape(stress(6,:),ny,nx,nz);
 
  %[stress1partialx, stress1partialy, stress1partialz] = gradient(stress1,dx,dy,dz);
  %[stress2partialx, stress2partialy, stress2partialz] = gradient(stress2,dx,dy,dz);
  %[stress3partialx, stress3partialy, stress3partialz] = gradient(stress3,dx,dy,dz);
  %[stress4partialx, stress4partialy, stress4partialz] = gradient(stress4,dx,dy,dz);
  %[stress5partialx, stress5partialy, stress5partialz] = gradient(stress5,dx,dy,dz);
  %[stress6partialx, stress6partialy, stress6partialz] = gradient(stress6,dx,dy,dz);
 
  %bodyforce_x = (stress1partialx + stress5partialz + stress6partialy);
  %bodyforce_y = (stress2partialy + stress4partialz + stress6partialx);
  %bodyforce_z = (stress3partialz + stress4partialy + stress5partialx);
 
 
  %%[bodyforce_azimuth,bodyforce_elevation, bodyforce_rho] = cart2sph(bodyforce_x,bodyforce_y,bodyforce_z);
  %%bodyforce=[reshape(X,[],1) reshape(Z,[],1) reshape(bodyforce_azimuth,[],1) reshape(bodyforce_elevation,[],1)  reshape(bodyforce_rho,[],1)reshape(bodyforce_x,[],1) reshape(bodyforce_y,[],1) reshape(bodyforce_z,[],1)];
otherwise
error('Wrong filter dimension!')
end
dlmwrite('../backup/bodyforce',bodyforce,' ');
dlmwrite('../backup/force',force,' ');

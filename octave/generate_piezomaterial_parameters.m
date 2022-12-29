function [piezo]=generate_piezomaterial_parameters(filter_dimension)
meshInformation_file ='../backup/meshInformation';

[xmin_status xmin] = system(['grep xmin ' meshInformation_file ' | cut -d = -f 2']);
xmin = str2num(xmin);
[xmax_status xmax] = system(['grep xmax ' meshInformation_file ' | cut -d = -f 2']);
xmax = str2num(xmax);

[ymin_status ymin] = system(['grep ymin ' meshInformation_file ' | cut -d = -f 2']);
ymin = str2num(ymin);
[ymax_status ymax] = system(['grep ymax ' meshInformation_file ' | cut -d = -f 2']);
ymax = str2num(ymax);

[zmin_status zmin] = system(['grep zmin ' meshInformation_file ' | cut -d = -f 2']);
zmin = str2num(zmin);
[zmax_status zmax] = system(['grep zmax ' meshInformation_file ' | cut -d = -f 2']);
zmax = str2num(zmax);

%total_finger_interfaces = dlmread('../backup/total_finger_interfaces','');
%total_finger_interfaces = transpose(total_finger_interfaces);
%zmax = min(total_finger_interfaces(2,:));

[dx_status dx] = system(['grep dx ' meshInformation_file ' | cut -d = -f 2']);
dx = str2num(dx);

[dy_status dy] = system(['grep dy ' meshInformation_file ' | cut -d = -f 2']);
dy = str2num(dy);

[dz_status dz] = system(['grep dz ' meshInformation_file ' | cut -d = -f 2']);
dz = str2num(dz);

%dx=dx/2;
%dy=dy/2;
%dz=dz/2;

nx = round((xmax-xmin)/dx+1);
ny = round((ymax-ymin)/dy+1);
nz = round((zmax-zmin)/dz+1);

x = linspace(xmin,xmax,nx);
y = linspace(ymin,ymax,ny);
z = linspace(zmin,zmax,nz);

dielectric_constant=...
[85.2    0    0;...
    0 85.2    0;...
    0    0 28.7]*(8.55e-12);

piezoelectric_constant=...
[    0    0   0    0 3.83 -2.37;...
 -2.37 2.37   0 3.83    0     0;...
  0.23 0.23 1.3    0    0     0];

elastic_constant=...
[2.030  0.573 0.752  0.085     0     0;...
 0.573  2.030 0.752 -0.085     0     0;...
 0.752  0.752 2.424      0     0     0;...
 0.085 -0.085     0  0.595     0     0;...
     0      0     0      0 0.595 0.085;...
     0      0     0      0 0.085 0.728]*(1.0e11); 
%elastic_constant=...
%[2.030  0.573 0.752      0     0     0;...
 %0.573  2.030 0.752      0     0     0;...
 %0.752  0.752 2.424      0     0     0;...
     %0      0     0  0.595     0     0;...
     %0      0     0      0 0.595     0;...
     %0      0     0      0     0 0.728]*(1.0e11); 

% P-wave velocities
% C11 = rho*v11^2; ***
% C22 = rho*v22^2;
% C33 = rho*v33^2;
% S-wave velocities
% C44 = rho*v23^2 = rho*v32^2;
% C55 = rho*v31^2 = rho*v13^2; ***
% C66 = rho*v12^2 = rho*v21^2; 

density = 4650;

%Vp = 7000;
%Vs = 4500;
Vp = sqrt(elastic_constant(1,1)/density);
Vs = sqrt(elastic_constant(5,5)/density);
QKappa = 9999;
QMu    = 9999;

if ~issymmetric(elastic_constant)
  error(['The elastic contant matrix is not symmetric!'])
end

switch filter_dimension
case '2D'
z_top_interface = zmax*ones(size(x));
z_bottom_interface = zmin*ones(size(x));

x_left_interface = xmin*ones(size(z));
x_right_interface = xmax*ones(size(z));

%top_interface    = [transpose(x) transpose(z_top_interface)];
%right_interface  = [transpose(x_right_interface) transpose(z)];
%bottom_interface = [transpose(x) transpose(z_bottom_interface)];
%left_interface   = [transpose(x_left_interface) transpose(z)];
%polygon = [top_interface;flipud(right_interface);flipud(bottom_interface);left_interface];

polygon = [xmin zmax; xmax zmax; xmax zmin; xmin zmin];
dlmwrite('../backup/polygon_piezo',polygon,' ');
case '3D'
otherwise
error('Wrong filter dimension!')
end

%xmin ymin zmin xmax ymax zmax dx dy dz dielectric_constant piezoelectric_constant elastic_constant density
piezo.xmin = xmin;
piezo.ymin = ymin;
piezo.zmin = zmin;

piezo.xmax = xmax;
piezo.ymax = ymax;
piezo.zmax = zmax;

piezo.dx = dx;
piezo.dy = dy;
piezo.dz = dz;

piezo.nx = nx;
piezo.ny = ny;
piezo.nz = nz;

piezo.x = x;
piezo.y = y;
piezo.z = z;

piezo.dielectric_constant = dielectric_constant;
piezo.piezoelectric_constant = piezoelectric_constant;
piezo.elastic_constant = elastic_constant;
piezo.density = density;

piezo.Vp = Vp;
piezo.Vs = Vs;
piezo.QKappa = QKappa;
piezo.QMu = QMu;

piezo.polygon = polygon;

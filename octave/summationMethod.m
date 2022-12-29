function [V] = summationMethod(x,y,z,positive_finger,negative_finger,positive_finger_V,negative_finger_V,filter_dimension)

dx=x(2)-x(1);
step=dx;
smallShift = step/5;

switch filter_dimension
case '2D'

[X Z] = meshgrid (x,z);
grid_x = reshape(X,[],1);
grid_z = reshape(Z,[],1);

[negative_finger_x negative_finger_x_index]=findNearest(x,negative_finger(:,1));
[positive_finger_x positive_finger_x_index]=findNearest(x,positive_finger(:,1));

[negative_finger_z negative_finger_z_index]=findNearest(z,negative_finger(:,2));
[positive_finger_z positive_finger_z_index]=findNearest(z,positive_finger(:,2));

negative_finger_V = negative_finger_V * ones(size(negative_finger_x));
positive_finger_V = positive_finger_V * ones(size(positive_finger_x));

finger_x = [negative_finger_x positive_finger_x];
finger_z = [negative_finger_z positive_finger_z];
finger_V = [negative_finger_V positive_finger_V];

source_x = [finger_x+smallShift finger_x-smallShift finger_x finger_x];
source_z = [finger_z finger_z finger_z+smallShift finger_z-smallShift];

[SOURCE_X FINGER_X] = meshgrid(source_x,finger_x);
[SOURCE_Z FINGER_Z] = meshgrid(source_z,finger_z);

M_SOURCE_FINGER = log(sqrt((SOURCE_X-FINGER_X).^2 + (SOURCE_Z-FINGER_Z).^2));
%Q_SOURCE = M_SOURCE_FINGER\finger_V';
Q_SOURCE = linsolve(M_SOURCE_FINGER,finger_V');

CHARGES = [reshape(source_x,[],1) reshape(source_z,[],1) reshape(Q_SOURCE,[],1)];
dlmwrite('../backup/CHARGES',CHARGES,' ');

[SOURCE_X GRID_X] = meshgrid(source_x,grid_x);
[SOURCE_Z GRID_Z] = meshgrid(source_z,grid_z);
M_SOURCE_GRID = log(sqrt((SOURCE_X-GRID_X).^2 + (SOURCE_Z-GRID_Z).^2));
V = M_SOURCE_GRID*Q_SOURCE;
V = reshape(V,length(z),length(x));

case '3D'
otherwise
error('Wrong filter dimension!')
end
endfunction

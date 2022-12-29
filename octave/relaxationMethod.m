function [V] = relaxationMethod(x,y,z,positive_finger,negative_finger,positive_finger_V,negative_finger_V,filter_dimension)

%iterationNumber=2000;
iterationNumber=200000;

norm_residual = 0.000001;

norm_V = 0;


switch filter_dimension
case '2D'

[X Z] = ndgrid (x,z);
V = zeros(size(X));

[negative_finger_x negative_finger_x_index]=findNearest(x,negative_finger(:,1));
[positive_finger_x positive_finger_x_index]=findNearest(x,positive_finger(:,1));

[negative_finger_z negative_finger_z_index]=findNearest(z,negative_finger(:,2));
[positive_finger_z positive_finger_z_index]=findNearest(z,positive_finger(:,2));

for i = 1:iterationNumber
%fixed potential
  V(positive_finger_x_index,positive_finger_z_index) = positive_finger_V;
  V(negative_finger_x_index,negative_finger_z_index) = negative_finger_V;

% update potential
  V(2:end-1,2:end-1) = (V(1:end-2,2:end-1) + V(3:end,2:end-1) + V(2:end-1,1:end-2) + V(2:end-1,3:end))/4; % inner domain

  V(1,2:end-1) = (V(1,3:end) + V(1,1:end-2) + V(2,2:end-1))/3; % left edge
  V(end,2:end-1) = (V(end,3:end) + V(end,1:end-2) + V(end-1,2:end-1))/3; % right edge
  V(2:end-1,1) = (V(1:end-2,1) + V(3:end,1) + V(2:end-1,2))/3; % bottom edge
  V(2:end-1,end) = (V(1:end-2,end) + V(3:end,end) + V(2:end-1,end-1))/3; % top edge

  V(1,1) = (V(1,2) + V(2,1))/2; % left bottom corner
  V(1,end) = (V(2,end) + V(1,end-1))/2; % left top corner
  V(end,1) = (V(end-1,1) + V(end,2))/2; % right bottom corner
  V(end,end) = (V(end-1,end) + V(end,end-1))/2; % right top corner

  norm_V_new = norm(V);
  if (norm_V_new - norm_V)/norm_V_new < norm_residual
    break;
  else
    norm_V = norm_V_new;
  end

end
disp([ "Iteration Number = " int2str(i)]);
%length(find(V>0.5))
X = permute(X,[2 1]); 
Z = permute(Z,[2 1]);  
V = permute(V,[2 1]);  

case '3D'
otherwise
error('Wrong filter dimension!')
end
endfunction

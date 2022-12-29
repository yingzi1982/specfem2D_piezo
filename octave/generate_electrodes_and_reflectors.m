#!/usr/bin/env octave

clear all
close all
clc

arg_list = argv ();
if length(arg_list) > 0
  filter_type = arg_list{1};
  filter_dimension = arg_list{2};
else
  error('Please input filter type and dimension.');
end

[xminStatus xmin] = system('grep xmin ../backup/Par_file.part | cut -d = -f 2');
xmin = str2num(xmin);

[xmaxStatus xmax] = system('grep xmax ../backup/Par_file.part | cut -d = -f 2');
xmax = str2num(xmax);

[nxStatus nx] = system('grep nx ../backup/Par_file.part | cut -d = -f 2');
nx = str2num(nx);

dx = (xmax - xmin)/nx;

xNumber = nx + 1;

x=linspace(xmin,xmax,xNumber);
%---------------------------------

unit_length = 1.0E-6;

right_finger_grating_gap = 0.5*unit_length;
left_finger_grating_gap = 0.5*unit_length;

%finger_pair_number = 99;
%finger_pair_number = 49;
finger_pair_number = 9;
grating_pair_number = 1;
switch filter_type
case 'SAW'

  switch filter_dimension
  case '2D'

  dlmwrite('../backup/finger_pair_number',finger_pair_number,' ');
  finger_z_min = 0.0*unit_length;
  %finger_z_max = 0.2*unit_length;
  finger_z_max = 0.0*unit_length;
  finger_width = 1*unit_length;
  dlmwrite('../backup/finger_width',finger_width,' ');
  finger_gap = 1*unit_length;
  finger_period_width = (finger_width + finger_gap)*2; % positive+gap+negative+gap

  single_positive_finger_x = [0:dx:finger_width-dx];
  single_negative_finger_x = single_positive_finger_x - finger_period_width/2;
  single_positive_finger_length = length(single_positive_finger_x);
  single_negative_finger_length = length(single_negative_finger_x);

  single_positive_finger_x_edge = [0 finger_width];
  single_negative_finger_x_edge = single_positive_finger_x_edge - finger_period_width/2;

  single_positive_gap_center = finger_width + finger_width/2;
  single_negative_gap_center = -finger_width + finger_width/2;

  %finger_element_shape = transpose(hanning(single_positive_finger_length)/max(hanning(single_positive_finger_length)));
  finger_element_shape = zeros(1,single_positive_finger_length);
  %finger_element_shape = ones(1,single_positive_finger_length);
  %finger_element_shape([1 end]) = 0.5;

  positive_finger_x = [];
  negative_finger_x = [];

  positive_finger_x_edge = [];
  negative_finger_x_edge = [];

  positive_gap_center = [];
  negative_gap_center = [];

  positive_finger_shape = [];
  negative_finger_shape = [];

  positive_finger_contact_interface = [];
  negative_finger_contact_interface = [];

  for i = -floor((finger_pair_number-1)/2):floor((finger_pair_number-1)/2)
    positive_finger_x = [positive_finger_x single_positive_finger_x+i*finger_period_width];
    negative_finger_x = [negative_finger_x single_negative_finger_x+i*finger_period_width];

    positive_finger_shape = [positive_finger_shape finger_z_max*finger_element_shape];
    negative_finger_shape = [negative_finger_shape finger_z_max*finger_element_shape];

    positive_finger_contact_interface = [positive_finger_contact_interface finger_z_min*ones(1,single_positive_finger_length)];
    negative_finger_contact_interface = [negative_finger_contact_interface finger_z_min*ones(1,single_negative_finger_length)];
    
    positive_finger_x_edge =  [positive_finger_x_edge single_positive_finger_x_edge + i*finger_period_width];
    negative_finger_x_edge =  [negative_finger_x_edge single_negative_finger_x_edge + i*finger_period_width];

    positive_gap_center = [positive_gap_center single_positive_gap_center + i*finger_period_width];
    negative_gap_center = [negative_gap_center single_negative_gap_center + i*finger_period_width];
  end

   positive_finger_edge = [transpose(positive_finger_x_edge) transpose(zeros(size(positive_finger_x_edge)))];
   negative_finger_edge = [transpose(negative_finger_x_edge) transpose(zeros(size(negative_finger_x_edge)))];
   dlmwrite('../backup/positive_finger_edge',positive_finger_edge,' ');
   dlmwrite('../backup/negative_finger_edge',negative_finger_edge,' ');

   positive_gap_center = [transpose(positive_gap_center) transpose(zeros(size(positive_gap_center)))];
   negative_gap_center = [transpose(negative_gap_center) transpose(zeros(size(negative_gap_center)))];
   dlmwrite('../backup/positive_gap_center',positive_gap_center,' ');
   dlmwrite('../backup/negative_gap_center',negative_gap_center,' ');

   positive_finger_shape = [transpose(positive_finger_x) transpose(positive_finger_shape)];
   negative_finger_shape = [transpose(negative_finger_x) transpose(negative_finger_shape)];

   positive_finger_contact_interface = [transpose(positive_finger_x) transpose(positive_finger_contact_interface)];
   negative_finger_contact_interface = [transpose(negative_finger_x) transpose(negative_finger_contact_interface)];
  
  %[positive_finger_grid_x positive_finger_grid_z] = meshgrid(positive_finger_x,finger_z);
  %[negative_finger_grid_x negative_finger_grid_z] = meshgrid(negative_finger_x,finger_z);
%
  %positive_finger_grid = [reshape(positive_finger_grid_x,[],1) reshape(positive_finger_grid_z,[],1)];
  %negative_finger_grid = [reshape(negative_finger_grid_x,[],1) reshape(negative_finger_grid_z,[],1)];

  [positive_finger_x positive_finger_x_index]=findNearest(x,positive_finger_x);
  [negative_finger_x negative_finger_x_index]=findNearest(x,negative_finger_x);

  total_finger_top_interface = zeros(size(x));

  total_finger_top_interface(positive_finger_x_index) = positive_finger_shape(:,2);
  total_finger_top_interface(negative_finger_x_index) = negative_finger_shape(:,2);

  total_finger_bottom_interface = zeros(size(x));

  total_finger_bottom_interface(positive_finger_x_index) = positive_finger_contact_interface(:,2);
  total_finger_bottom_interface(negative_finger_x_index) = negative_finger_contact_interface(:,2);

  total_finger_interfaces = [x' total_finger_bottom_interface' total_finger_top_interface'];
  finger_x_min = min([positive_finger_x negative_finger_x]);
  finger_x_max = max([positive_finger_x negative_finger_x]);
  finger_x_range = [finger_x_min finger_x_max];
  dlmwrite('../backup/finger_x_range',finger_x_range,' ');
 if ( max(finger_x_max)>xmax || min(finger_x_min)<xmin )
   error('the finger is over xrange limit!')
 end
%-----------------------------------------------------
  dlmwrite('../backup/grating_pair_number',grating_pair_number,' ');
  grating_z_min = finger_z_min;
  grating_z_max = finger_z_max;
  grating_width = finger_width;
  grating_gap = finger_gap;
  grating_period_width = (grating_width + grating_gap);

  single_grating_x = [0:dx:grating_width-dx];
  single_right_grating_length = length(single_grating_x);
  single_left_grating_length = length(single_grating_x);

  %grating_element_shape = transpose(hanning(single_right_grating_length)/max(hanning(single_right_grating_length)));
  grating_element_shape = zeros(1,single_right_grating_length);
  %grating_element_shape = ones(1,single_right_grating_length);

  grating_x = [];
  right_grating_x = [];
  left_grating_x = [];

  right_grating_shape = [];
  left_grating_shape = [];

  right_grating_contact_interface = [];
  left_grating_contact_interface = [];

  for i = 0:grating_pair_number-1
    grating_x = [grating_x single_grating_x+i*grating_period_width];

    right_grating_shape = [right_grating_shape grating_z_max*grating_element_shape];
    left_grating_shape = [left_grating_shape grating_z_max*grating_element_shape];

    right_grating_contact_interface = [right_grating_contact_interface grating_z_min*ones(1,single_right_grating_length)];
    left_grating_contact_interface = [left_grating_contact_interface grating_z_min*ones(1,single_left_grating_length)];
  end

  right_grating_x = finger_x_max + grating_x + right_finger_grating_gap;
  left_grating_x = finger_x_min - fliplr(grating_x) - left_finger_grating_gap;

  [right_grating_x right_grating_x_index]=findNearest(x,right_grating_x);
  [left_grating_x left_grating_x_index]=findNearest(x,left_grating_x);

  total_finger_and_grating_top_interface = total_finger_top_interface;
  total_finger_and_grating_bottom_interface = total_finger_bottom_interface;

  total_finger_and_grating_top_interface(right_grating_x_index) = right_grating_shape(:,2);
  total_finger_and_grating_top_interface(left_grating_x_index) = left_grating_shape(:,2);

  total_finger_and_grating_bottom_interface(right_grating_x_index) = right_grating_contact_interface(:,2);
  total_finger_and_grating_bottom_interface(left_grating_x_index) = left_grating_contact_interface(:,2);

  total_finger_and_grating_interfaces = [x' total_finger_and_grating_bottom_interface' total_finger_and_grating_top_interface'];
 if ( max(right_grating_x)>xmax || min(left_grating_x)<xmin )
   error('the grating is over xrange limit!')
 end
  case '3D'
  otherwise
  error('Wrong filter dimension!')
  end
case 'BAW'
  switch dimension
  case '2D'
  case '3D'
  otherwise
  error('Wrong filter dimension!')
  end
otherwise
error('Wrong filter type!')
end

dlmwrite('../backup/positive_finger_contact_interface',positive_finger_contact_interface,' ');
dlmwrite('../backup/negative_finger_contact_interface',negative_finger_contact_interface,' ');

dlmwrite('../backup/total_finger_interfaces',total_finger_interfaces,' ');
dlmwrite('../backup/total_finger_and_grating_interfaces',total_finger_and_grating_interfaces,' ');

%dlmwrite('../backup/positive_finger_grid',positive_finger_grid,' ');
%dlmwrite('../backup/negative_finger_grid',negative_finger_grid,' ');

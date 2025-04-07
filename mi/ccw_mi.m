clear; clc; close all;
addpath('~/cna/CNA/src/');
us = ["u", "v", "w"];
for ii=1:3
    load(sprintf('mi_bins_MIT_%s_vel_mat.mat', us(ii)));
    mi(mi < 0) = 0;
    mi_max = max(mi(:));
    mi_thres = 0.6;
    mi = mi./mi_max;
    mi(mi < mi_thres) = 0;

    ccw = sum(mi, 1);
    ccw = ccw./max(ccw(:));
    sorted = sort(ccw(:));
    ccw(ccw < sorted(end-100)) = 0;

%     addpath('~/cna/CNA/src/');
%     ccw = get_ccw(mi);
    
    load('/work/home/vivek/MIT_Data/LowSwirl_No_CB/PIV_CC_LS_No_CB_data.mat');
    
    addpath('~/cna');
    [nt, nx, nz] = size(u_vel_mat);
    ccw2d = zeros(nx, nz);
    for i  = 1:nx
        for j = 1:nz
           ccw2d(i,j) = ccw((i-1)*nz + j);
        end
    end
    d = 1.0;
    plot_field(ii, R_MAT./d, Z_MAT./d, ccw2d, zeros(nx,nz), '');
		saveas(gcf, sprintf('%s.png',us(ii));
end

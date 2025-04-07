clear; clc; close all;
% tic;
% load('/work/home/vivek/MIT_Data/LowSwirl_No_CB/LES_non_uniform_coords.mat');
% toc;

tic;
vels = ["u"];
%for ii = 1:3
ii = 1;
    vel_comp = sprintf("%s",vels(ii));
    sample_rank = 0;
    sample_entr = ["hx", "hxy"];
    %mi_bins_MIT_CC_NOZ_v_225_hx_new.mat
    file_suffix = 'mi_bins';
    sample_hx_file = sprintf("%s_%s_%d_%s_new.mat", file_suffix, vel_comp, sample_rank, sample_entr(1));
    sample_hxy_file = sprintf("%s_%s_%d_%s_new.mat", file_suffix, vel_comp, sample_rank, sample_entr(2));
    
    load(sample_hx_file);
    load(sample_hxy_file);
    [nx_hx, ny_hx] = size(hx);
    [nx_hxy, ny_hxy] = size(hxy);
    
    HX = zeros(nx_hx, ny_hx);
    HXY = zeros(nx_hxy, ny_hxy);
    mi = zeros(nx_hxy, ny_hxy);
    
    %Get the number of files:
    NUM_PROCS = 0;
    while exist(sprintf("%s_%s_%d_%s_new.mat", file_suffix, vel_comp, NUM_PROCS, sample_entr(1)), 'file')
        NUM_PROCS = NUM_PROCS + 1;
    end
    
    for rnk = 0:NUM_PROCS-1
        rnk
        load(sprintf("%s_%s_%d_%s_new.mat", file_suffix, vel_comp, rnk, sample_entr(1)));
        load(sprintf("%s_%s_%d_%s_new.mat", file_suffix, vel_comp, rnk, sample_entr(2)));
        if nx_hx == 1
            HX(nx_hx, :) = HX(nx_hx, :) + hx;
        else
            HX(:,ny_hy) = HX(:,ny_hy) + hx;
        end
        HXY(:,:) = HXY(:,:) + hxy(:,:);
    end
    
    for i = 1:nx_hxy
        for j = i + 1:ny_hxy
            if nx_hx == 1
                mi(i,j) = HX(nx_hx,i) + HX(nx_hx,j) - HXY(i,j);
            else
                mi(i,j) = HX(i,nx_hy) + HX(j,nx_hy) - HXY(i,j);
            end
            mi(j,i) = mi(i,j);
        end
    end
    toc;
    
    mi(isnan(mi)) = 0;
    mi(isinf(mi)) = 0;
    mi(mi < 0) = 0;

    save('mi.mat','mi');
%     
%     mi_max = max(mi(:));
%     mi_thres = 0.0;
%     mi = mi./mi_max;
%     mi(mi < mi_thres) = 0;
%     % 
%     % mi_sum = sum(mi,1);
%     % mi_sum_max = max(mi_sum(:));
%     % mi_sum = mi_sum./mi_sum_max;
%     % mi_thres = 0.0;
%     % mi_sum(mi_sum < mi_thres) = 0;
%     % save(sprintf('../data/mi_sum_%s_%0.2f.mat',vel_comp, mi_thres), 'mi_sum');
%     
%     addpath('~/cna/CNA/src/');
%     ccw = get_ccw(mi);
%     save(sprintf('../data/ccw_CC_NOZ_%s_%0.2f.mat',vel_comp, mi_thres), 'ccw');
%end
toc;
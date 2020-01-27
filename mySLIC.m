function mySLIC(ImgPath_arg, K_arg, M_arg, Threshold, handles)
    % Parameters
    global I_rgb;
    global cluster_centers;
    global label;
    global res;
    global E;
    global ImgPath;
    global K;
    global M;
    global times;
    ImgPath = ImgPath_arg;
    K = K_arg;
    M = M_arg;
    % main loop
    ReadData();
    FilterImg();
    InitParameters();
    InitClusters();
    E = Inf;
    times = 0;
    axes(handles.axes2);
    while E > Threshold
        Assignment();
        UpdateClusters();
        calE();

        mask = boundarymask(label);
        imshow(labeloverlay(I_rgb,mask,'Transparency',0));
        hold on;
        plot(gca, cluster_centers(:,2),cluster_centers(:,1),'r*');
        hold off;
        pause(0.01);
        times = times + 1;
        times_str = strcat('SLIC¹ý³Ì£ºTimes= ',int2str(times));
        set(handles.text11,'string',times_str);
    end
    GetRes();
    ReadData();
    
    axes(handles.axes3);
    imshow(res,[]);

%     axes(handles.axes2);
%     label = superpixels(I_rgb,K);
%     mask = boundarymask(label);
%     imshow(labeloverlay(I_rgb,mask,'Transparency',0));
end
% Read Data
function ReadData
    global ImgPath;
    global I_rgb;
    I_rgb = im2double(imread(ImgPath));
end
% Filter Img
function FilterImg
    global I_rgb;
    global I_lab;
    I_rgb = imfilter(I_rgb,fspecial('average'));
    I_lab = rgb2lab(I_rgb);
end
% Init Parameters
function InitParameters
    global R;
    global C;
    global N;
    global S;
    global cluster_centers;
    global label;
    global dis;
    global I_lab;
    global K;
    [R, C, ~] = size(I_lab);
    N = R*C;
    S = floor(sqrt(N/K));
    cluster_centers = zeros(K,2);
    label = zeros(R,C);
    dis = inf(R,C);
end
% Init Clusters
function InitClusters
    global cluster_centers;
    global S;
    global R;
    global C;
    global K;
    cluster_index = 1;
    h = floor(S/2);
    w = floor(S/2);
    while h < R
        while w < C
            cluster_centers(cluster_index,:) = [h,w];
            cluster_index = cluster_index + 1;
            w = w + S;
        end
        w = floor(S/2);
        h = h + S;
    end
    K = cluster_index - 1;
    cluster_centers = cluster_centers(1:K,:);
end
% Assignment
function Assignment
    global K;
    global cluster_centers;
    global I_lab;
    global label;
    global dis;
    global S;
    global R;
    global C;
    global M;
    for cluster_index = 1:K
        cluster_h = cluster_centers(cluster_index,1);
        cluster_w = cluster_centers(cluster_index,2);
        for h = cluster_h-S:cluster_h+S
            if h < 1 || h > R
                continue;
            end
            for w = cluster_w-S:cluster_w+S
                if w < 1 || w > C
                    continue;
                end
                cluster_l = I_lab(cluster_h,cluster_w,1);
                cluster_a = I_lab(cluster_h,cluster_w,2);
                cluster_b = I_lab(cluster_h,cluster_w,3);
                cur_l = I_lab(h,w,1);
                cur_a = I_lab(h,w,2);
                cur_b = I_lab(h,w,3);
                d_c = sqrt((cluster_l-cur_l)^2 + (cluster_a-cur_a)^2 + (cluster_b-cur_b)^2);
                d_s = sqrt((cluster_h-h)^2 + (cluster_w-w)^2);
                d = sqrt((d_c)^2 + (d_s/S*M)^2);
                if d < dis(h,w)
                    label(h,w) = cluster_index;
                    dis(h,w) = d;
                end
            end
        end
    end
end
% Update Clusters
function UpdateClusters
    global K;
    global label;
    global cluster_centers;
    global R;
    global cluster_centers_pre;
    cluster_centers_pre = cluster_centers;
    for cluster_index = 1:K
        sum_h = 0;
        sum_w = 0;
        indexs = find(label == cluster_index);
        for idx = 1:length(indexs)
            sum_w = sum_w + floor(indexs(idx)/R) + 1;
            sum_h = sum_h + indexs(idx) - floor(indexs(idx)/R)*R;
        end
        new_h = floor(sum_h / length(indexs));
        new_w = floor(sum_w / length(indexs));
        cluster_centers(cluster_index,:) = [new_h,new_w];
    end
end
function GetRes
    global label;
    global cluster_centers;
    global I_lab;
    global R;
    global C;
    global res;
    res_lab = I_lab;
    for h = 1:R
        for w = 1:C
            cluster_index = label(h,w);
            cluster_h = cluster_centers(cluster_index,1);
            cluster_w = cluster_centers(cluster_index,2);
            res_lab(h,w,:) = I_lab(cluster_h,cluster_w,:);
        end
    end
    res = lab2rgb(res_lab);
end

function calE
    global E;
    global cluster_centers;
    global cluster_centers_pre;
    dif = cluster_centers - cluster_centers_pre;
    E = sum(sum(dif .^ 2));
end

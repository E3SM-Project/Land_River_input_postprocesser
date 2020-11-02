%%
% this one only add values to number 17 vegetation to the original landuse
%%%%%%%%%%%%%%%%%%%%%

clc; clear;

originfile = '/compyfs/inputdata/lnd/clm2/surfdata_map/landuse.timeseries_0.5x0.5_HIST_simyr1850-2015_c200924.nc';
targetfile = '/compyfs/zhou014/datasets/landuse.timeseries_0.5x0.5_HIST_simyr1850-2015_c201008_17pft.nc';
hyde = load('HYDE-1850-2010-irr-rainfed-km2.mat');

%o = ncinfo(originfile); t = ncinfo(targetfile);

temp = ncread(originfile,'PCT_NAT_PFT');
new_pct_nat = temp;

hyde.irr(isnan(hyde.irr)) = 0;
hyde.rain(isnan(hyde.rain)) = 0;

irr_ratio = hyde.irr(:,:,:)./(hyde.irr(:,:,:)+hyde.rain(:,:,:)); %ratio 
irr_ratio(isnan(irr_ratio)) = 0;

for y = 1:17
    yid = (y-1)*10+1:y*10;
    if y == 17
        yid = 161:166;
    end
    
    ratio_y = flipud(irr_ratio(:,:,y))';
    
    new_pct_nat(:,:,17,yid) = temp(:,:,16,yid).* repmat(ratio_y,1,1,1,length(yid));
    new_pct_nat(:,:,16,yid) = temp(:,:,16,yid).* repmat((1-ratio_y),1,1,1,length(yid));
end

%%%%%%%% remove nan in the data if there's any
k = isnan(new_pct_nat);
[o, p, q, r] = ind2sub(size(k),find(k==1));

for i = 1: length(o)
    
    new_pct_nat(o(i),p(i),1,r(i)) = 100;
    new_pct_nat(o(i),p(i),2:end,r(i)) = 0;
end
%%%%%%%%%%%%%%%%%%%%

ncwrite(targetfile,'PCT_NAT_PFT',new_pct_nat); %fraction of nat pfts, sum = 100
ncwrite(targetfile,'PCT_CROP',new_pct_crop); %fraction of nat pfts, sum = 100

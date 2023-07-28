%% update time series file for transient runs
%% compatible with surface data
% 1 new dimension added (cft)
% 1 new variable (PCT_CFT)
% 1 dimension size changed (natpft, from 17 to 15)

% Note that two user defined threshold values are applied to 
% remove some tiny fractions in PCT_CFT and PCT_CROP

clc; clear;

originfile = '/compyfs/inputdata/lnd/clm2/surfdata_map/landuse.timeseries_0.5x0.5_HIST_simyr1850-2015_c200924.nc';
targetfile = '/compyfs/zhou014/datasets/E3SM_inputs/landuse.timeseries_0.5x0.5_HIST_simyr1850-2015_c230726.nc';
surfacefile = '/compyfs/inputdata/lnd/clm2/surfdata_map/surfdata_0.5x0.5_simyr1850_c211019.nc';
load('HYDE3.2-1850-2015-irr-rainfed-km2-annual.mat');

%%%%%%%%%%%%%%%%
% Step 1
%%%%%%%%%%%%%%%%

% first step will be completed in NCO to 
% 1) reduce natpft dimension from 17 to 15
system(['ncks -d natpft,0,14 ' originfile ' temp.nc']); 
% 2) remove the original PCT_CROP becasue it doesn't have time dimension
system(['ncks -x -v PCT_CROP temp.nc ' targetfile]); 
%o = ncinfo(originfile); t = ncinfo(targetfile);

%%%%%%%%%%%%%%%%
% Step 2 create new variables for crops, including the new PCT_CROP that
% has time dimension
%%%%%%%%%%%%%%%%

newv = {'cft', 'PCT_CFT', 'PCT_CROP'};
newfields = struct;

% 1) create cft 
var = char(newv(1)); %cft
newfields.(var) = [15;16]; %only two cfts, rainfed and irrigated

% 2) create PCT_CFT
var = char(newv(2)); %PCT_CFT
temp = ncread(originfile,'PCT_NAT_PFT'); % fraction time series for all 17 PFTs
pct_natveg = ncread(originfile,'PCT_NATVEG'); % fixed natveg fraction in all landunits

hyde32_interp.irr(isnan(hyde32_interp.irr)) = 0;
hyde32_interp.rain(isnan(hyde32_interp.rain)) = 0;

irr_ratio_all = hyde32_interp.irr(:,:,:)./(hyde32_interp.irr(:,:,:)+hyde32_interp.rain(:,:,:)); %ratio
irr_ratio_all(isnan(irr_ratio_all)) = 0;

%%%%%%% remove tiny ratio values to reduce tiny CFT fractions
threshold = 1e-3;
irr_ratio_all(irr_ratio_all<threshold) = 0;
irr_ratio_all(irr_ratio_all>(1-threshold) & irr_ratio_all<1) = 1;
% sum(irr_ratioall>0 & irr_ratio_all<1e-3,'all')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

pct_crop_new = zeros(size(pct_natveg)); % this is for the next step, PCT_CROP

for y = 1:166
    S_nat = sum(temp(:,:,1:15,y),3); % total fraction of natural veg
    S_crp = sum(temp(:,:,16:17,y),3); % total fraction of crop, 1st is rainfed, 2nd is irrigated

    crp_ratio = S_crp./(S_crp+S_nat);
    pct_crop_new(:,:,y) = pct_natveg.*crp_ratio;

    % if there's no crop, then no irrigation, even hyde data says there's irrigation
    irr_ratio = irr_ratio_all(:,:,y);
    irr_ratio = (flipud(irr_ratio))';
    irr_ratio(S_crp==0)=0;
	
    newfields.(var)(:,:,1,y) = 100-irr_ratio*100;
    newfields.(var)(:,:,2,y) = irr_ratio*100;
    
end

% 3) create new PCT_CROP
var = char(newv(3)); %PCT_CROP

%%%%%%% remove tiny ratio values to reduce tiny CROP fractions
threshold = 1e-4;
pct_crop_new(pct_crop_new<threshold) = 0;
pct_crop_new(pct_crop_new>(100-threshold) & pct_crop_new<100) = 100;
% sum(pct_crop_new>0 & pct_crop_new<threshold,'all')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

newfields.(var) = pct_crop_new; % calculated in the loop in 2) above

%%%%%%%%%%%%%%%%
% Step 3 modify target file
%%%%%%%%%%%%%%%%

ncid = netcdf.open(targetfile,'NC_WRITE');
% Put file in define mode.
netcdf.reDef(ncid);

% exisiting dimensions
dimidnatpft = netcdf.inqDimID(ncid,'natpft');
dimidcol = netcdf.inqDimID(ncid,'lsmlat');
dimidrow = netcdf.inqDimID(ncid,'lsmlon');
dimidtime = netcdf.inqDimID(ncid,'time');

% new dimensions
dimidcft = netcdf.defDim(ncid,'cft',2);
%
varid_cft = netcdf.defVar(ncid,'cft','NC_INT',[dimidcft]);
varid_pctcft = netcdf.defVar(ncid,'PCT_CFT','double',[dimidrow dimidcol dimidcft dimidtime]);
varid_pct_crop = netcdf.defVar(ncid,'PCT_CROP','double',[dimidrow dimidcol,dimidtime]);

netcdf.putAtt(ncid,varid_cft,'standard_name','cft');
netcdf.putAtt(ncid,varid_cft,'units','unitless');

netcdf.putAtt(ncid,varid_pctcft,'standard_name','PCT_CFT');
netcdf.putAtt(ncid,varid_pctcft,'units','unitless');

netcdf.putAtt(ncid,varid_pct_crop,'standard_name','PCT_CROP');
netcdf.putAtt(ncid,varid_pct_crop,'units','unitless');

netcdf.endDef(ncid);

% put values in to the nc file
netcdf.putVar(ncid,varid_cft,newfields.(char(newv(1))));
netcdf.putVar(ncid,varid_pctcft,newfields.(char(newv(2))));
netcdf.putVar(ncid,varid_pct_crop,newfields.(char(newv(3))));
netcdf.close(ncid);

%%%%%%%%%%%%%%%%
% Step 4 modify exsisting variable, PCT_NAT_PFT in the target file
% No need to modify PCT_NATVEG as modified for surface data
% because it will be rescaled in the model based on the PCT_CROP each year
%%%%%%%%%%%%%%%%

pct_nat = ncread(targetfile,'PCT_NAT_PFT');
pct_nat_new = pct_nat;

for tstep = 1:166
    disp(tstep);
    
    S_nat = sum(pct_nat(:,:,:,tstep),3);

    for i = 1:15
        pct_nat_new(:,:,i,tstep) = 100*pct_nat(:,:,i,tstep)./S_nat;
    end

end

%%%%%%%% remove nan in the pct_nat_new if there's any, nan mostly in 
%%%%%%%% all crop cells, which makes S_nat zero

k = isnan(pct_nat_new);
[o, p, q, r] = ind2sub(size(k),find(k==1));

for i = 1: length(o) 
    pct_nat_new(o(i),p(i),1,r(i)) = 100;
    pct_nat_new(o(i),p(i),2:15,r(i)) = 0;
end

% sum(pct_nat_new>0 & pct_nat_new<threshold,'all')
%%%%%%%%%%%%%%%%%%%%
ncwrite(targetfile,'PCT_NAT_PFT',pct_nat_new); %fraction of nat pfts, sum = 100

%%%%%%%%%%%%%%%%
% Step 5 optional step to make the first year of landuse file identical to the surface data
%%%%%%%%%%%%%%%%

pct_nat = ncread(targetfile,'PCT_NAT_PFT');
pct_cft = ncread(targetfile,'PCT_CFT');
pct_crop = ncread(targetfile,'PCT_CROP');

pct_nat1 = ncread(surfacefile,'PCT_NAT_PFT');
pct_cft1 = ncread(surfacefile,'PCT_CFT');
pct_crop1 = ncread(surfacefile,'PCT_CROP');

pct_nat(:,:,:,1) = pct_nat1;
pct_cft(:,:,:,1) = pct_cft1;
pct_crop(:,:,1) = pct_crop1;
    
ncwrite(targetfile,'PCT_CROP',pct_crop); %total fraction of cfts
ncwrite(targetfile,'PCT_NAT_PFT',pct_nat); %fraction of nat pfts, sum = 100
ncwrite(targetfile,'PCT_CFT',pct_cft); %fraction of cfts, sum = 100

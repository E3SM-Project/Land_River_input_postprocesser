%% update time series file for transient runs
%% compatible with surface data

clc; clear;

originfile = '/compyfs/inputdata/lnd/clm2/surfdata_map/landuse.timeseries_0.5x0.5_HIST_simyr1850-2015_c200924.nc';
targetfile = '/compyfs/zhou014/datasets/landuse.timeseries_0.5x0.5_HIST_simyr1850-2015_c201008.nc';
hyde = load('HYDE-1850-2010-irr-rainfed-km2.mat');

% Step 1
% first step will be completed in NCO to reduce natpft dimension from
% 17 to 15 using 'ncks -d natpft,0,14 in.nc out.nc'

system(['ncks -d natpft,0,14 ' originfile ' temp.nc']);
system(['ncks -x -v PCT_CROP temp.nc ' targetfile]);

%o = ncinfo(originfile); t = ncinfo(targetfile);

% get the variables from original file and trim them to the right format
newv = {'cft', 'PCT_CFT', 'PCT_CROP'};
newfields = struct;

var = char(newv(1)); %cft
newfields.(var) = [15;16]; %only two cfts, rainfed and irrigated

var = char(newv(2)); %PCT_CFT
temp = ncread(originfile,'PCT_NAT_PFT');

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
    
    newfields.(var)(:,:,2,yid) = temp(:,:,16,yid).* repmat(ratio_y,1,1,1,length(yid));
    newfields.(var)(:,:,1,yid) = temp(:,:,16,yid).* repmat((1-ratio_y),1,1,1,length(yid));
end

var = char(newv(3)); 
pc = ncread(originfile,'PCT_CROP');
newfields.(var) = repmat(pc,1,1,166);

% Start modifying target file
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

%%%%%%%%%%%% additional changes

pct_nat = ncread(targetfile,'PCT_NAT_PFT');
pct_cft = ncread(targetfile,'PCT_CFT');
pct_crop = ncread(targetfile,'PCT_CROP');
pct_natveg = ncread(targetfile,'PCT_NATVEG');

pct_nat_new = pct_nat;
pct_cft_new = pct_cft;
pct_crop_new = pct_crop;

for tstep = 1:166
    disp(tstep);
    
    S_nat = sum(pct_nat(:,:,:,tstep),3);
    S_crp = sum(pct_cft(:,:,:,tstep),3);
    

    for i = 1:15
        pct_nat_new(:,:,i,tstep) = 100*pct_nat(:,:,i,tstep)./S_nat;
    end
    
    for i = 1:2
        pct_cft_new(:,:,i,tstep) = 100*pct_cft(:,:,i,tstep)./S_crp;
    end
    
    for i = 1:720
        for j = 1:360
            if S_crp(i,j) == 0
                pct_cft_new(i,j,1,tstep) = 100;
            end
            
            if isnan(pct_cft_new(i,j,2,tstep))
                pct_cft_new(i,j,2,tstep) = 0;
            end
        end
    end
    
    crp_ratio = S_crp./(S_crp+S_nat);
    crop = pct_natveg.*crp_ratio;
    pct_crop_new(:,:,tstep) = crop;
end

%%%%%%%% remove nan in the data if there's any
k = isnan(pct_nat_new);
[o, p, q, r] = ind2sub(size(k),find(k==1));

for i = 1: length(o)
    
    pct_nat_new(o(i),p(i),1,r(i)) = 100;
    pct_nat_new(o(i),p(i),2:15,r(i)) = 0;
end
%%%%%%%%%%%%%%%%%%%%


ncwrite(targetfile,'PCT_CROP',pct_crop_new); %total fraction of cfts
ncwrite(targetfile,'PCT_NAT_PFT',pct_nat_new); %fraction of nat pfts, sum = 100
ncwrite(targetfile,'PCT_CFT',pct_cft_new); %fraction of cfts, sum = 100
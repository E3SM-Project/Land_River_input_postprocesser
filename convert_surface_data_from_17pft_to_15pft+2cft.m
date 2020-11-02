%% adding crop related variables to non crop surface data (17 pfts)
% 5 new variables will be added (cft, FIRRIG, FSURF, FGRD, PCT_CFT)
% 2 variable dimensions will be modified (natpft, PCT_NAT_PFT)
% 1 dimension will be added (cft)
% 1 dimension will be modified (natpft)

%%%%%%%%%%%%%%%%%%%%%
clc; clear;
originfile = '/compyfs/inputdata/lnd/clm2/surfdata_map/surfdata_0.5x0.5_simyr1850_c200924.nc';
targetfile = '/compyfs/zhou014/datasets/surfdata_0.5x0.5_simyr1850_c201008.nc';
irrigfile = '/compyfs/zhou014/datasets/surfdata_0.5x0.5_simyr2000_c190418_firrig_updated.nc'; % a surface dataset that includes Firrig, Fsurf, and Fgrd
hyde = load('HYDE-1850-2010-irr-rainfed-km2.mat');

% Step 1
% first step will be completed in NCO to reduce natpft dimension from
% 17 to 15 using 'ncks -d natpft,0,14 in.nc out.nc'

system(['ncks -d natpft,0,14 ' originfile ' ' targetfile]);

%o = ncinfo(originfile); t = ncinfo(targetfile);

% Step 2
% get the variables from original file and trim them to the right format
newv = {'cft', 'FIRRIG', 'FSURF', 'FGRD', 'PCT_CFT'};
newfields = struct;

var = char(newv(1)); %cft
newfields.(var) = [15;16]; %only two cfts, rainfed and irrigated

for i = 2:4
    var = char(newv(i));
    disp(var);
    temp = ncread(irrigfile,var);
    newfields.(var) = temp;
end

var = char(newv(5)); %PCT_CFT
temp = ncread(originfile,'PCT_NAT_PFT');


hyde.irr(isnan(hyde.irr)) = 0;
hyde.rain(isnan(hyde.rain)) = 0;

irr_ratio = (flipud(hyde.irr(:,:,1)./(hyde.irr(:,:,1)+hyde.rain(:,:,1))))'; %ratio for 1850
irr_ratio(isnan(irr_ratio)) = 0;

newfields.(var)(:,:,2) = temp(:,:,16).*irr_ratio;
newfields.(var)(:,:,1) = temp(:,:,16).*(1-irr_ratio);
%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
%dimidlsmpft = netcdf.defDim(ncid,'lsmpft',25);

%
varid_cft = netcdf.defVar(ncid,'cft','NC_INT',[dimidcft]);
varid_firrig = netcdf.defVar(ncid,'FIRRIG','double',[dimidrow dimidcol]);
varid_fsurf = netcdf.defVar(ncid,'FSURF','double',[dimidrow dimidcol]);
varid_fgrd = netcdf.defVar(ncid,'FGRD','double',[dimidrow dimidcol]);
varid_pctcft = netcdf.defVar(ncid,'PCT_CFT','double',[dimidrow dimidcol dimidcft]);


netcdf.putAtt(ncid,varid_cft,'standard_name','cft');
netcdf.putAtt(ncid,varid_cft,'units','unitless');

netcdf.putAtt(ncid,varid_firrig,'standard_name','FIRRIG');
netcdf.putAtt(ncid,varid_firrig,'units','unitless');

netcdf.putAtt(ncid,varid_fsurf,'standard_name','FSURF');
netcdf.putAtt(ncid,varid_fsurf,'units','unitless');

netcdf.putAtt(ncid,varid_fgrd,'standard_name','FGRD');
netcdf.putAtt(ncid,varid_fgrd,'units','unitless');

netcdf.putAtt(ncid,varid_pctcft,'standard_name','PCT_CFT');
netcdf.putAtt(ncid,varid_pctcft,'units','unitless');

netcdf.endDef(ncid);

newv = {'cft', 'FIRRIG', 'FSURF', 'FGRD', 'PCT_CFT'};
% put values in to the nc file
netcdf.putVar(ncid,varid_cft,newfields.cft);
netcdf.putVar(ncid,varid_firrig,newfields.(char(newv(2))));
netcdf.putVar(ncid,varid_fsurf,newfields.(char(newv(3))));
netcdf.putVar(ncid,varid_fgrd,newfields.(char(newv(4))));
netcdf.putVar(ncid,varid_pctcft,newfields.(char(newv(5))));

netcdf.close(ncid);

%%%%%%%%%%%% additional changes
temp = ncread(originfile,'PCT_NAT_PFT');
S_nat = sum(temp(:,:,1:15),3);
S_crp = sum(temp(:,:,16:17),3);

pct_nat = ncread(targetfile,'PCT_NAT_PFT');
pct_cft = ncread(targetfile,'PCT_CFT');

for i = 1:15
    pct_nat(:,:,i) = 100*pct_nat(:,:,i)./S_nat;
end

for i = 1:2
    pct_cft(:,:,i) = 100*pct_cft(:,:,i)./S_crp;
end

for i = 1:720
    for j = 1:360
        if S_crp(i,j) == 0
           pct_cft(i,j,1) = 100;
        end
        
        if isnan(pct_cft(i,j,2))
            pct_cft(i,j,2) = 0;
        end
    end
end

natveg = ncread(targetfile,'PCT_NATVEG');

crp_ratio = S_crp./(S_crp+S_nat);
crop = natveg.*crp_ratio;
natveg_new = natveg-crop; 

ncwrite(targetfile,'PCT_CROP',crop); %total fraction of cfts
ncwrite(targetfile,'PCT_NATVEG',natveg_new); %total fraction of nat pfts
ncwrite(targetfile,'PCT_NAT_PFT',pct_nat); %fraction of nat pfts, sum = 100
ncwrite(targetfile,'PCT_CFT',pct_cft); %fraction of cfts, sum = 100

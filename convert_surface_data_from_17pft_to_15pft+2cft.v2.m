%% convert 17-PFT-only surface data to 15PFT+2CFT surface data 

% 1 new dimension added (cft)
% 4 new variables (FIRRIG, FSURF, FGRD, PCT_CFT)
% 1 dimension size changed (natpft, from 17 to 15)

% Note that two user defined threshold values are applied to 
% remove some tiny fractions in PCT_CFT and PCT_CROP

%%%%%%%%%%%%%%%%%%%%%
clc; clear;
originfile = '/compyfs/inputdata/lnd/clm2/surfdata_map/surfdata_0.5x0.5_simyr1850_c200924.nc';
targetfile = '/compyfs/zhou014/datasets/E3SM_inputs/surfdata_0.5x0.5_simyr1850_c230726.nc';
irrigfile = '/compyfs/zhou014/datasets/E3SM_inputs/surfdata_0.5x0.5_simyr2000_c190418_firrig_updated.nc'; % a surface dataset that includes Firrig, Fsurf, and Fgrd
load('HYDE3.2-1850-2015-irr-rainfed-km2-annual.mat');

%%%%%%%%%%%%%%%%
% Step 1 using NCO to reduce natpft dimension from 17 to 15
%%%%%%%%%%%%%%%%
system(['ncks -d natpft,0,14 ' originfile ' ' targetfile]);
%o = ncinfo(originfile); t = ncinfo(targetfile);

%%%%%%%%%%%%%%%%
% Step 2 create five new variables about crops and irrigation
% FIRRIG, FSURF, and FGRD are extracted from an exisiting data
%%%%%%%%%%%%%%%%

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
S_nat = sum(temp(:,:,1:15),3); % total fraction of natural veg
S_crp = sum(temp(:,:,16:17),3); % total fraction of crop

hyde32_interp.irr(isnan(hyde32_interp.irr)) = 0;
hyde32_interp.rain(isnan(hyde32_interp.rain)) = 0;

irr_ratio = hyde32_interp.irr(:,:,1)./(hyde32_interp.irr(:,:,1)+hyde32_interp.rain(:,:,1)); %ratio for 1850
irr_ratio(isnan(irr_ratio)) = 0;

%%%%%%% remove tiny ratio values to reduce tiny PCT_CFT fractions
threshold = 1e-3;
irr_ratio(irr_ratio<threshold) = 0;
irr_ratio(irr_ratio>(1-threshold) & irr_ratio<1) = 1;
% sum(irr_ratioall>0 & irr_ratio_all<1e-3,'all')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% in original data all crops are rainfed, meaning zero irrigation (#17 pft)
% so we get the irrigation and rainfed cft fractions only from #16 pft
% these two fractions should add to 100, 

% flip the irr_ratio from hyde to match the surface data structure
irr_ratio = (flipud(irr_ratio))';

% if there's no crop, then no irrigation, even hyde data says there's irrigation
irr_ratio(S_crp==0)=0; 

newfields.(var)(:,:,1) = 100-irr_ratio*100; % 1st is rainfed, 2nd is irrigated
newfields.(var)(:,:,2) = irr_ratio*100; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

%%%%%%%%%%%% modify the natural PFT part
%%%%%%%%%%%%%%%%
% Step 4 modify exsisting variable, PCT_NAT_PFT and PCT_NATVEG in the target file
%%%%%%%%%%%%%%%%

pct_nat = ncread(targetfile,'PCT_NAT_PFT');
S_nat = sum(pct_nat,3);

for i = 1:15
    pct_nat(:,:,i) = 100*pct_nat(:,:,i)./S_nat;
end

% here we don't check and remove tiny values in PCT_NAT_PFT to keep consistency with the original 17 PFT data

pct_natveg = ncread(targetfile,'PCT_NATVEG');

crp_ratio = S_crp./(S_crp+S_nat);
pct_crop_new = pct_natveg.*crp_ratio;

%%%%%%% remove tiny ratio values to reduce tiny PCT_CROP fractions
threshold = 1e-4;
pct_crop_new(pct_crop_new<threshold) = 0;
pct_crop_new(pct_crop_new>(100-threshold) & pct_crop_new<100) = 100;
% sum(pct_crop_new>0 & pct_crop_new<threshold,'all')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

pct_natveg_new = pct_natveg-pct_crop_new; 

ncwrite(targetfile,'PCT_CROP',pct_crop_new); %total fraction of cfts
ncwrite(targetfile,'PCT_NATVEG',pct_natveg_new); %total fraction of nat pfts
ncwrite(targetfile,'PCT_NAT_PFT',pct_nat); %fraction of nat pfts, sum = 100

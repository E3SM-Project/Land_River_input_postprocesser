% this script adds values to number 17 vegetation (irrigated) and add irrigation
% related variables
% 
%%%%%%%%%%%%%%%%%%%%%
clc; clear;
originfile = '/compyfs/inputdata/lnd/clm2/surfdata_map/surfdata_0.5x0.5_simyr1850_c200924.nc';
targetfile = '/compyfs/zhou014/datasets/surfdata_0.5x0.5_simyr1850_c201008_17pft.nc';
irrigfile = '/compyfs/zhou014/datasets/surfdata_0.5x0.5_simyr2000_c190418_firrig_updated.nc'; % a surface dataset that includes Firrig, Fsurf, and Fgrd
hyde = load('HYDE-1850-2010-irr-rainfed-km2.mat');

% Step 2
% get the variables from original file and trim them to the right format
newv = {'FIRRIG', 'FSURF', 'FGRD'};
newfields = struct;

for i = 1:3
    var = char(newv(i));
    disp(var);
    temp = ncread(irrigfile,var);
    newfields.(var) = temp;
end

old_pct_nat = ncread(originfile,'PCT_NAT_PFT');
new_pct_nat = old_pct_nat;

hyde.irr(isnan(hyde.irr)) = 0;
hyde.rain(isnan(hyde.rain)) = 0;

irr_ratio = (flipud(hyde.irr(:,:,1)./(hyde.irr(:,:,1)+hyde.rain(:,:,1))))'; %ratio for 1850
irr_ratio(isnan(irr_ratio)) = 0;

new_pct_nat(:,:,17) = old_pct_nat(:,:,16).*irr_ratio;
new_pct_nat(:,:,16) = old_pct_nat(:,:,16).*(1-irr_ratio);

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


varid_firrig = netcdf.defVar(ncid,'FIRRIG','double',[dimidrow dimidcol]);
varid_fsurf = netcdf.defVar(ncid,'FSURF','double',[dimidrow dimidcol]);
varid_fgrd = netcdf.defVar(ncid,'FGRD','double',[dimidrow dimidcol]);



netcdf.putAtt(ncid,varid_firrig,'standard_name','FIRRIG');
netcdf.putAtt(ncid,varid_firrig,'units','unitless');

netcdf.putAtt(ncid,varid_fsurf,'standard_name','FSURF');
netcdf.putAtt(ncid,varid_fsurf,'units','unitless');

netcdf.putAtt(ncid,varid_fgrd,'standard_name','FGRD');
netcdf.putAtt(ncid,varid_fgrd,'units','unitless');

netcdf.endDef(ncid);

newv = {'FIRRIG', 'FSURF', 'FGRD'};
% put values in to the nc file
netcdf.putVar(ncid,varid_firrig,newfields.(char(newv(1))));
netcdf.putVar(ncid,varid_fsurf,newfields.(char(newv(2))));
netcdf.putVar(ncid,varid_fgrd,newfields.(char(newv(3))));

netcdf.close(ncid);

ncwrite(targetfile,'PCT_NAT_PFT',new_pct_nat); %fraction of nat pfts, sum = 100

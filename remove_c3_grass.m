%% Script to remove the C3 grass (number 14) for one gridcell
clc; clear;

ncfile = '/compyfs/zhou014/datasets/E3SM_inputs/landuse.timeseries_0.5x0.5_HIST_simyr1850-2015_c230722_noC3grass_2cells.nc';

info = ncinfo(ncfile);
lat = ncread(ncfile,'LATIXY');
lon = ncread(ncfile,'LONGXY');

latitude = -14.25; longitude = 34.75; add_back_to = 15; remove_from_year = 116;
% latitude = 28.25; longitude = 57.75; add_back_to = 1; remove_from_year = 6;

% latitude, longitude, add back to which pft, and remove the c3 from which
% year til the end

x = find(lon(:,1) == longitude); ...
    y = find(lat(1,:) == latitude);

% read constant fractions
pglacier = ncread(ncfile,'PCT_GLACIER');
purban = ncread(ncfile,'PCT_URBAN'); purban = sum(purban,3);
plake = ncread(ncfile,'PCT_LAKE');
pnatveg = ncread(ncfile,'PCT_NATVEG');
pwetland = ncread(ncfile,'PCT_WETLAND');

% imagesc(pglacier+purban+plake+pnatveg+pwetland)

% read transient fractions
pct_crop = ncread(ncfile,'PCT_CROP');
pct_cft = ncread(ncfile,'PCT_CFT');
pct_pft = ncread(ncfile,'PCT_NAT_PFT');

pcrop = squeeze(pct_crop(x,y,:));
pcft = squeeze(pct_cft(x,y,:,:));
ppft = squeeze(pct_pft(x,y,:,:));

ppft_temp = ppft;
ppft_temp(14,remove_from_year:end) = 0;
ppft_temp(add_back_to,remove_from_year:end) = ppft(add_back_to,remove_from_year:end) + ppft(14,remove_from_year:end);
ppft = ppft_temp;

pct_pft(x,y,:,:) = ppft;
ncwrite(ncfile,'PCT_NAT_PFT',pct_pft);
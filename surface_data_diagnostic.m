clc; clear;
%% This following script produces three plots for one single gridcell:
% 1. landunit fraction for this gridcell
% 2. fractions of natural PFTs
% 3. fractions of CFTs; if there's no crop in the dataset (i.e. only PFT
% available), this plot will be replaced by a new landunit fraction that
% assumes the last two PFTs in the original dataset is converted to CFTs

ncfile = '\\compy01/compyfs/zhou014/datasets/E3SM_inputs/landuse.timeseries_0.5x0.5_HIST_simyr1850-2015_c230722_noC3grass_2cells.nc';
figuredir = 'E:\OneDrive - PNNL\Publication\under_development\BGC\new\';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this is the gridcell you want to check
latitude = -30.25; longitude = -58.75; %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

info = ncinfo(ncfile);
lat = ncread(ncfile,'LATIXY');
lon = ncread(ncfile,'LONGXY');

x = find(lon(:,1) == longitude); ...
    y = find(lat(1,:) == latitude);

% read constant fractions
pglacier = ncread(ncfile,'PCT_GLACIER');
purban = ncread(ncfile,'PCT_URBAN'); purban = sum(purban,3);
plake = ncread(ncfile,'PCT_LAKE');
pnatveg = ncread(ncfile,'PCT_NATVEG');
pwetland = ncread(ncfile,'PCT_WETLAND');

% Find the index of natpft dimension in the Dimensions array
dimIndex = find(strcmp({info.Dimensions.Name}, 'cft'));

% Check if the dimension exists
if isempty(dimIndex)
    cft = 0;
    disp('No CFT');
else
    cft = 1;
    % Has CFT and PFT
end

% read transient fractions
if cft
    pcrop = squeeze(ncread(ncfile,'PCT_CROP',[x y 1], [1 1 inf]));
    pcft = squeeze(ncread(ncfile,'PCT_CFT',[x y 1 1], [1 1 inf inf]));
else
    pcrop = ncread(ncfile,'PCT_CROP');
end

ppft = squeeze(ncread(ncfile,'PCT_NAT_PFT',[x y 1 1], [1 1 inf inf]));

%%%%%%%%%%% define PFT names
pftnames = {'not vegetated',...
'nleaf eve tem',...
'nleaf eve bor',...
'nleaf dec bor',...
'bleaf eve tro',...
'bleaf eve tem',...
'bleaf dec tro',...
'bleaf dec tem',...
'bleaf dec bor',...
'eve shrub',...
'dec tem shrub',...
'dec bor shrub',...
'c3 arctic',...
'c3 non-arctic',...
'c4 ',...
'c3 crop',...
'c3 irri'};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if cft
    frac_all = [pglacier(x,y); purban(x,y); plake(x,y); pwetland(x,y); pnatveg(x,y)];
    frac_all = repmat(frac_all,1,166);
    frac_all(6,:) = pcrop';
    frac_all(5,:)  = frac_all(5,:) -frac_all(6,:);
else
    frac_all = [pglacier(x,y); purban(x,y); plake(x,y); pwetland(x,y); pnatveg(x,y); pcrop(x,y)];
    frac_all = repmat(frac_all,1,166);
    frac_all_update = frac_all; % assume moving natpft 16 and 17 to crop fraction to landunit
    frac_all_update(6,:) =  ((ppft(16,:)+ppft(17,:))/100).*frac_all(5,:);
    frac_all_update(5,:) = frac_all(5,:) - frac_all_update(6,:);
end

% making figures
fg = figure;
set(fg, 'Position', [50 80 600 700]);

subplot(3,1,1)
area(1850:2015,frac_all')
legend('glacier','urban','lake','wetland','natural','crop','location','southoutside','Orientation','horizontal');
axis tight
xlabel('year'); ylabel('percentage');
title (['landunit ' num2str(latitude) ', ' num2str(longitude)]);

subplot(3,1,2)
temp = sum(ppft,2);
ids = find (temp>0);
area(1850:2015,ppft(ids,:)')
legend(pftnames(ids),'Location','east','Orientation','vertical');
%legend(num2str(ids),'Location','southoutside','Orientation','horizontal')
axis tight
xlabel('year'); ylabel('percentage');
title (['natpft ' num2str(latitude) ', ' num2str(longitude)]);

if cft
    subplot(3,1,3)
    area(1850:2015,pcft')
    legend('non irrigated','irrigated','Location','southoutside','Orientation','horizontal')
    axis tight
    xlabel('year'); ylabel('percentage');
    title (['cft ' num2str(latitude) ', ' num2str(longitude)]);
else
    subplot(3,1,3)
    area(1850:2015,frac_all_update')
    legend('glacier','urban','lake','wetland','natural','crop','location','southoutside','Orientation','horizontal');
    axis tight
    xlabel('year'); ylabel('percentage');
    title (['updated landunit ' num2str(latitude) ', ' num2str(longitude)]);
end

filename = [num2str(latitude) '_' num2str(longitude) '.png'];
set(gcf,'PaperPositionMode','auto')
print(fg,'-dpng', [figuredir filename],'-r400');
close (fg)
%% check consistency between surface data and first year of transient data
clc; clear;

% surface dataset
sfile = '\\compy01/compyfs/inputdata/lnd/clm2/surfdata_map/surfdata_0.5x0.5_simyr1850_c211019.nc';
% transient landuse dataset
tfile = '/compyfs/zhou014/datasets/E3SM_inputs/landuse.timeseries_0.5x0.5_HIST_simyr1850-2015_c230602_noC3grass_2cells.nc';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this is the gridcell you want to check
latitude = -14.25; longitude = 34.75; %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tinfo = ncinfo(tfile);
sinfo = ncinfo(sfile);
lat = ncread(tfile,'LATIXY');
lon = ncread(tfile,'LONGXY');

x = find(lon(:,1) == longitude); ...
    y = find(lat(1,:) == latitude);

% read constant fractions from time series
pglacier = ncread(tfile,'PCT_GLACIER');
purban = ncread(tfile,'PCT_URBAN'); purban = sum(purban,3);
plake = ncread(tfile,'PCT_LAKE');
pnatveg = ncread(tfile,'PCT_NATVEG');
pwetland = ncread(tfile,'PCT_WETLAND');

pcrop = ncread(tfile,'PCT_CROP',[1 1 1], [inf inf 1]);
ppft = ncread(tfile,'PCT_NAT_PFT',[1 1 1 1], [inf inf inf 1]);
pcft = ncread(tfile,'PCT_CFT',[1 1 1 1], [inf inf inf 1]);

pcrop = squeeze(pcrop(x,y,1));
pcft = squeeze(pcft(x,y,:,1));
ppft = squeeze(ppft(x,y,:,1));

frac_all_t = [pglacier(x,y); purban(x,y); plake(x,y); pwetland(x,y); pcrop;pcft;ppft];

% read constant fractions from surface data
pglacier = ncread(sfile,'PCT_GLACIER');
purban = ncread(sfile,'PCT_URBAN'); purban = sum(purban,3);
plake = ncread(sfile,'PCT_LAKE');
pnatveg = ncread(sfile,'PCT_NATVEG');
pwetland = ncread(sfile,'PCT_WETLAND');
pcrop = ncread(sfile,'PCT_CROP');

ppft = ncread(sfile,'PCT_NAT_PFT');
pcft = ncread(sfile,'PCT_CFT');

pcft = squeeze(pcft(x,y,:));
ppft = squeeze(ppft(x,y,:));

frac_all_s = [pglacier(x,y); purban(x,y); plake(x,y); pwetland(x,y); pcrop(x,y);pcft;ppft];

scatter(frac_all_t,frac_all_s)

%% check if there's any tiny values in PCT_CFT, PCT_CROP, and PCT_NAT_PFT
clc;clear;
ncfile = '/compyfs/zhou014/datasets/E3SM_inputs/landuse.timeseries_0.5x0.5_HIST_simyr1850-2015_c230722.nc'; %0, 0, 0

thre = 1e-10;

temp = ncread(ncfile,'PCT_CFT');
temp = temp(:,:,:,2:end);
sum(temp>0&temp<thre,'all')

temp= ncread(ncfile,'PCT_CROP');
temp = temp(:,:,2:end);
sum(temp>0&temp<thre,'all')

temp= ncread(ncfile,'PCT_NAT_PFT');
temp = temp(:,:,:,2:end);
sum(temp>0&temp<thre,'all')

%% check if everything adds to 100 for CFT and PFT
clc;clear;
ncfile = '/compyfs/zhou014/datasets/E3SM_inputs/landuse.timeseries_0.5x0.5_HIST_simyr1850-2015_c230722.nc'; %0, 0, 0

pct_nat = ncread(ncfile,'PCT_NAT_PFT');
pct_cft = ncread(ncfile,'PCT_CFT');

for y = 1:166

    cft_x = pct_cft(:,:,:,y);
    tot_cft = sum(100 - sum(cft_x,3),'all');
    dif_cft = max(abs(100 - sum(cft_x,3)),[],'all');

    pft_x = pct_nat(:,:,:,y);
    tot_pft = sum(100 - sum(pft_x,3),'all');
    dif_pft = max(abs(100 - sum(pft_x,3)),[],'all');
    disp(['year ' num2str(y) ' has max difference in PFT: ' num2str(dif_pft) ', in CFT: ' num2str(dif_cft)]);

end

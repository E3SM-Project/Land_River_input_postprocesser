%%
% Convert hyde 3.2 database to irrigation and rainfed data 
% from 1850 to 2015 at half degree
clc; clear;
hyde_dir = '/compyfs/zhou014/datasets/HYDE3.2/baseline/zip/';

hyde32 = struct;
k=1;

for i = [1850:10:2000 2001:2015]
    disp(i);
    irrifile = [hyde_dir num2str(i) 'AD_lu/tot_irri' num2str(i) 'AD.asc'];
    rainfile = [hyde_dir num2str(i) 'AD_lu/tot_rainfed' num2str(i) 'AD.asc'];

    irr = zeros(360,720);
    fid = fopen (irrifile);
    header = textscan (fid, '%s %f', 6);
    fclose (fid);
    A = header{1};
    B = header{2};

    data = dlmread(irrifile, ' ', 6,0);
    [p,q] = size (data);
    col = B(1);
    row = B(2);
    xll = B(3);
    yll = B(4);
    cellsize = B(5);
    nodata = B(6);

    if (q ~= col || p ~=row)
        error ('ERROR: colum or row number do not match with file header');
    end

    data(data==-9999) = 0;

    for ii = 1:360
        for jj = 1:720
            irr(ii,jj) = sum(data((ii-1)*6+1:ii*6,(jj-1)*6+1:jj*6),'all');
        end
    end

    rain = zeros(360,720);
    fid = fopen (rainfile);
    header = textscan (fid, '%s %f', 6);
    fclose (fid);
    A = header{1};
    B = header{2};

    data = dlmread(rainfile, ' ', 6,0);
    [p,q] = size (data);
    col = B(1);
    row = B(2);
    xll = B(3);
    yll = B(4);
    cellsize = B(5);
    nodata = B(6);

    if (q ~= col || p ~=row)
        error ('ERROR: colum or row number do not match with file header');
    end

    data(data==-9999) = 0;

    for ii = 1:360
        for jj = 1:720
            rain(ii,jj) = sum(data((ii-1)*6+1:ii*6,(jj-1)*6+1:jj*6),'all');
        end
    end

    hyde32.irr(:,:,k) = irr;
    hyde32.rain(:,:,k) = rain;
    k=k+1;
end

save("HYDE3.2-1850-2015-irr-rainfed-km2.mat","hyde32",'-mat');

%% interpolate the 1850-2015 decadal hyde data to annual data 1850-2015
clc; clear;
load ('HYDE3.2-1850-2015-irr-rainfed-km2.mat');

hyde32_interp = struct;
[Xi, Yi, Zi] = meshgrid(1:720,1:360,[1850:10:2000 2001:2015]);
[Xq, Yq, Zq] = meshgrid(1:720,1:360,1850:1:2015);

Vi = hyde32.irr;
hyde32_interp.irr = interp3(Xi,Yi,Zi,Vi,Xq,Yq,Zq,'linear');
Vi = hyde32.rain;
hyde32_interp.rain = interp3(Xi,Yi,Zi,Vi,Xq,Yq,Zq,'linear');

save("HYDE3.2-1850-2015-irr-rainfed-km2-annual.mat","hyde32_interp",'-mat');

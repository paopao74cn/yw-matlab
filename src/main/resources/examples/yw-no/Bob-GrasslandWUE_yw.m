function Bob-GrasslandWUE_yw
%Function takes "Alice's output" and perfroms correlation analysis wrt
%water use efficiency (WUE).

% @BEGIN Bob_GrasslandWUE_yw

% @IN BIOME_BGC_BG1_Monthly_GPP_data @URI BIOME-BGC_BG1_Monthly_GPP.nc4
% @IN BIOME_BGC_BG1_Monthly_Evap_data @URI BIOME-BGC_BG1_Monthly_Evaps.nc4
% @PARAM To_Be_Communicated_Member(Alice)_Node_pid

% @OUT water_use_efficiency_image @URI water-use-efficiency.png
% @OUT tenancy_4_WUE_image @URI tenancy-4-WUE.png

%% fetch WUE
%Output available @ http://nacp.ornl.gov/mstmipdata/mstmip_simulation_results_global_v1.jsp
%MsTMIP Model: BIOME-BGC; Simulation: BG1; Variables: GPP and Evap; time resolution: Monthly
%Code assumes netcdf files are local
%pth='C:\Users\cs2239\Downloads'; %change as needed

% @BEGIN fetch_WUE
% @IN BIOME_BGC_BG1_Monthly_GPP_data @URI BIOME-BGC_BG1_Monthly_GPP.nc4
% @IN BIOME_BGC_BG1_Monthly_Evap_data @URI BIOME-BGC_BG1_Monthly_Evaps.nc4

% @OUT WUEh @AS gross_C_uptake_data 
% @OUT lath @AS half_degree_lat_data 
% @OUT lonh @AS half_degree_lon_data 



pth='/Users/zqian1/Documents/yw-no/'; %change as needed

GPP=ncread([pth filesep 'BIOME-BGC_BG1_Monthly_GPP.nc4'],'GPP'); %units: kg C m-2 s-1
Evap=ncread([pth filesep 'BIOME-BGC_BG1_Monthly_Evap.nc4'],'Evap'); %units: kg H2O m-2 s-1
%Note: WUE is gross C uptake (GPP) per unit H2O loss (Evap). Higher values
%are more efficient, plants "create" more GPP per unit water.
[GPP Evap]=deal(GPP(:,:,end-335:end),Evap(:,:,end-335:end)); %1901-2010 to 1982-2010
%Note: Use only last 28 years. This corresponds to satellite-era when 
%simulated values are thought to be higher quality.
WUEh=nanmean(GPP,3)./nanmean(Evap,3);
lath=ncread([pth filesep 'BIOME-BGC_BG1_Monthly_Evap.nc4'],'lat'); %half-degree lat --needed for interp2
lonh=ncread([pth filesep 'BIOME-BGC_BG1_Monthly_Evap.nc4'],'lon'); %half-degree lon --needed for interp2

% @END fetch_WUE


% Get a Member Node to talk to
% @BEGIN fetch_remote_member(Alice)_file_path
% @PARAM To_Be_Communicated_Member(Alice)_Node_pid

% @OUT C3_fraction_path @AS synmap_c3grass_path
% @OUT C4_fraction_path @AS synmap_c4grass_path
% @OUT Grass_fraction_path @AS synmap_presentveg_grass_path

import org.dataone.client.v2.DataONEClient;
mn = DataONEClient.getMN('urn:node:mnDemo2');


% Get SYNMAP_PRESENTVEG_C3Grass_RelaFrac_NA_v2.0.nc dataset
synmap_c3grass_pid = '22e72484-07f6-4167-911c-6950dc1f6412';
data = mn.get([], synmap_c3grass_pid);
% Save the data locally
system_metadata_synmap_c3grass = mn.getSystemMetadata([], synmap_c3grass_pid);
synmap_c3grass_path = [pth filesep system_metadata_synmap_c3grass.fileName];
fid = fopen(synmap_c3grass_path, 'w');
fwrite(fid, data, 'int8');
fclose(fid);

% Get SYNMAP_PRESENTVEG_C4Grass_RelaFrac_NA_v2.0.nc
synmap_c4grass_pid =  '89bb3f7f-b881-48c3-b40f-86de8a8f4fc0';
data = mn.get([], synmap_c4grass_pid);
% Save the data locally
system_metadata_synmap_c4grass = mn.getSystemMetadata([], synmap_c4grass_pid);
synmap_c4grass_path = [pth filesep system_metadata_synmap_c4grass.fileName];
fid = fopen(synmap_c4grass_path, 'w');
fwrite(fid, data, 'int8');
fclose(fid);

% Get SYNMAP_PRESENTVEG_Grass_Fraction_NA_v2.0.nc
synmap_presentveg_grass_pid = '15a312cb-83b9-44b6-b157-15a168507c38';
data = mn.get([], synmap_presentveg_grass_pid);
% Save the data locally
system_metadata_synmap_presentveg_grass = mn.getSystemMetadata([], synmap_presentveg_grass_pid);
synmap_presentveg_grass_path = [pth filesep system_metadata_synmap_presentveg_grass.fileName];
fid = fopen(synmap_presentveg_grass_path, 'w');
fwrite(fid, data, 'int8');
fclose(fid);

% @END fetch_remote_member(Alice)_file_path

% fetch Alice's output

% @BEGIN fetch_Alice's_output_data_file

% @IN C3_fraction_path @AS synmap_c3grass_path
% @IN C4_fraction_path @AS synmap_c4grass_path
% @IN Grass_fraction_path @AS synmap_presentveg_grass_path


% @OUT C3_fraction_data @AS C3Frac_data
% @OUT C4_fraction_data @AS C4Frac_data
% @OUT Grass_fraction_data @AS GrassFrac_data
% @OUT latq @AS quarter_degree_lat_data 
% @OUT lonq @AS quarter_degree_lon_data

C3Frac=ncread(synmap_c3grass_path,'C3_frac'); %units: relative fraction
C4Frac=ncread(synmap_c4grass_path,'C4_frac'); %units: relative fraction
GrassFrac=ncread(synmap_presentveg_grass_path,'grass'); %units: relative fraction
latq=ncread(synmap_c3grass_path,'lat'); %quarter-degree lat --needed for interp2
lonq=ncread(synmap_c3grass_path,'lon'); %quarter-degree lon --needed for interp2

% @END fetch_Alice's_output_data_file


%% snap to common grid
% @BEGIN interpolate_gross_C_uptake_data
% @IN latq @AS quarter_degree_lat_data 
% @IN lonq @AS quarter_degree_lon_data
% @IN WUEh @AS gross_C_uptake_data 
% @IN lath @AS half_degree_lat_data 
% @IN lonh @AS half_degree_lon_data

% @OUT WUEq @AS interpolated_gross_C_uptake_data
%Regrettably Alice is quarter-degree for North American and Bob is
%half-degree global.
[lathm lonhm]=meshgrid(lath,lonh);
[latqm lonqm]=meshgrid(latq,lonq);
WUEq=interp2(lathm,lonhm,WUEh,latqm,lonqm);

% @END interpolate_gross_C_uptake_data
%% viz
% @BEGIN viz
% @IN WUEq @AS interpolated_gross_C_uptake_data
% @IN C3_fraction_data @AS C3Frac_data
% @IN C4_fraction_data @AS C4Frac_data
% @IN Grass_fraction_data @AS GrassFrac_data
% @OUT water_use_efficiency_image @URI water-use-efficiency.png

mask=~isnan(WUEq) & GrassFrac>0; %good pixels only
[WUEq C3Frac C4Frac GrassFrac]=deal(zscore(WUEq(mask)),C3Frac(mask),C4Frac(mask),GrassFrac(mask));
%Note: C4Frac is left in but not currently used.
[fitobject1 gof1]=fit([C3Frac,GrassFrac],WUEq,'poly11'); %linear polynomial surface fit
fig1 = figure(1);
plot(fitobject1,[C3Frac,GrassFrac],WUEq)
xlabel 'C3 grass relative fraction [dim]'
ylabel 'Grasslands fraction [dim]'
zlabel 'Water use efficiency [\sigma]'
disp(gof1)
disp(fitobject1)
print(fig1, 'water-use-efficiency', '-dpng');
%We find that WUE increases with both the relative fraction of C3 grasses
%and overall grass fraction.

% @END viz

%% viz 
% @BEGIN viz2
% @IN Grass_fraction_data @AS GrassFrac_data
% @IN WUEq @AS interpolated_gross_C_uptake_data
% @OUT tenancy_4_WUE_image @URI tenancy-4-WUE.png

[fitobject2 gof2]=fit(GrassFrac,WUEq,'poly1'); %linear fit
fig2 = figure(2);
h=plot(fitobject2,GrassFrac,WUEq);
set(h,'linewidth',4); %bold trend line
xlabel 'Grasslands fraction [dim]'
ylabel 'Water use efficiency [\sigma]'
disp(gof2)
disp(fitobject2)
print(fig2, 'tenancy-4-WUE', '-dpng');
% @END viz2

%% @END Bob_GrasslandWUE_yw

%We find a weak tendency for WUE to decline as overall grass fraction 
%increases.


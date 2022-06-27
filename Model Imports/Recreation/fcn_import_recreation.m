function NEVO_ORVal_chgsite_data = fcn_import_recreation(uk_baseline, ...
                                                         parameters, ...
                                                         conn, ...
                                                         hash)
    
    %% fcn_import_recreation.m
    %  =======================
    %  Authors: Mattia Mancini, Rebecca Collins
    %  Created: 08-Jun-2022
    %  Last modified: 08-Jun-2022
    %  ----------------------------------------
    %
    %  DESCRIPTION
    %  Load data and prepare the matlab structures required to run the
    %  recreation model for the BNG and Agile-SPRINT work.
    %  AAA: FOR THE TIME BEING, THIS ONLY PRODUCES THE TABLES REQUIRED TO
    %       RUN THE REC MODEL WITH THE 'path_chg' SITE OPTION!!!
    %       
    %  The following tables are created within this script:
    %   1 - max_ev0
	%	2 - max_expv1cari_base
	%	3 - max_expv1wlki_base
	%	4 - max_Index
	%	5 - max_lsoapop
	%	6 - max_spid
	%	7 - max_Sumexpv1car_base
	%	8 - max_Sumexpv1wlk_base
	%	9 - max_v1carxlc
	%	10 - max_v1wlkxlc
	%	11 - NEVO_base_lcs_pcts
	%	12 - NEVO_base_rec_areas
	%	13 - NEVO_base_sumlcs
	%	14 - ORVal_paths_cells
	%	15 - ORVal_site
	%	16 - Visval
    %  ===============================================================
    
    %% (1) LAND COVER AND SITE LC DATA
    %      - 1.1. NEVO_base_lcs and NEVO_base_sumlcs
    %      - 1.2. NEVO_base_lcs_pcts
    %      - 1.3. ORVal_paths_cells
    %      - 1.4. ORVal_parks_cells
    %      - 1.5. ORVal_beaches_cells
    %      - 1.6. ORVal_site
    %      - 1.7. NEVO_base_rec_areas
    % ===============================================
    
    % 1.1. NEVO_base_sumlcs
    % ----------------------
    NEVO_base_lcs = uk_baseline;
    
    NEVO_base_lcs.ngrass_ha_20 = NEVO_base_lcs.sngrass_ha + NEVO_base_lcs.rgraz_ha_20;
    NEVO_base_lcs.ngrass_ha_30 = NEVO_base_lcs.sngrass_ha + NEVO_base_lcs.rgraz_ha_30;
    NEVO_base_lcs.ngrass_ha_40 = NEVO_base_lcs.sngrass_ha + NEVO_base_lcs.rgraz_ha_40;
    NEVO_base_lcs.ngrass_ha_50 = NEVO_base_lcs.sngrass_ha + NEVO_base_lcs.rgraz_ha_50;
    NEVO_base_lcs.mgrass_ha_20 = NEVO_base_lcs.pgrass_ha_20 + NEVO_base_lcs.tgrass_ha_20;
    NEVO_base_lcs.mgrass_ha_30 = NEVO_base_lcs.pgrass_ha_30 + NEVO_base_lcs.tgrass_ha_30;
    NEVO_base_lcs.mgrass_ha_40 = NEVO_base_lcs.pgrass_ha_40 + NEVO_base_lcs.tgrass_ha_40;
    NEVO_base_lcs.mgrass_ha_50 = NEVO_base_lcs.pgrass_ha_50 + NEVO_base_lcs.tgrass_ha_50;
    NEVO_base_lcs.agric_ha_20 = NEVO_base_lcs.arable_ha_20;
    NEVO_base_lcs.agric_ha_30 = NEVO_base_lcs.arable_ha_30;
    NEVO_base_lcs.agric_ha_40 = NEVO_base_lcs.arable_ha_40;
    NEVO_base_lcs.agric_ha_50 = NEVO_base_lcs.arable_ha_50;
       
    
    NEVO_base_new2kids = NEVO_base_lcs.new2kid;

    NEVO_base_lcs_20    = [NEVO_base_lcs.wood_ha NEVO_base_lcs.agric_ha_20 NEVO_base_lcs.mgrass_ha_20  NEVO_base_lcs.ngrass_ha_20];
    NEVO_base_sumlcs_20 = sum(NEVO_base_lcs_20,2);
    NEVO_base_sumlcs_20(NEVO_base_sumlcs_20==0) = 1; % In case all water & urban 

    NEVO_base_lcs_30    = [NEVO_base_lcs.wood_ha NEVO_base_lcs.agric_ha_30 NEVO_base_lcs.mgrass_ha_30  NEVO_base_lcs.ngrass_ha_30];
    NEVO_base_sumlcs_30 = sum(NEVO_base_lcs_30,2);
    NEVO_base_sumlcs_30(NEVO_base_sumlcs_30==0) = 1; % In case all water & urban 

    NEVO_base_lcs_40    = [NEVO_base_lcs.wood_ha NEVO_base_lcs.agric_ha_40 NEVO_base_lcs.mgrass_ha_40  NEVO_base_lcs.ngrass_ha_40];
    NEVO_base_sumlcs_40 = sum(NEVO_base_lcs_40,2);
    NEVO_base_sumlcs_40(NEVO_base_sumlcs_40==0) = 1; % In case all water & urban 

    NEVO_base_lcs_50    = [NEVO_base_lcs.wood_ha NEVO_base_lcs.agric_ha_50 NEVO_base_lcs.mgrass_ha_50  NEVO_base_lcs.ngrass_ha_50];
    NEVO_base_sumlcs_50 = sum(NEVO_base_lcs_50,2);
    NEVO_base_sumlcs_50(NEVO_base_sumlcs_50==0) = 1; % In case all water & urban 

    NEVO_base_sumlcs = [NEVO_base_new2kids NEVO_base_sumlcs_20 NEVO_base_sumlcs_30 NEVO_base_sumlcs_40 NEVO_base_sumlcs_50];        

    
    NEVO_base_lcs = [NEVO_base_new2kids ... 
                     NEVO_base_lcs_20  ... 
                     NEVO_base_lcs_30  ...
                     NEVO_base_lcs_40  ...
                     NEVO_base_lcs_50]; 
                 
    % 1.2. NEVO_base_lcs_pcts
    % -----------------------
    NEVO_base_lcs_pcts = [NEVO_base_new2kids ... 
                          NEVO_base_lcs_20./NEVO_base_sumlcs(:,2)  ... 
                          NEVO_base_lcs_30./NEVO_base_sumlcs(:,3)  ...
                          NEVO_base_lcs_40./NEVO_base_sumlcs(:,4)  ...
                          NEVO_base_lcs_50./NEVO_base_sumlcs(:,5)];
     
    % 1.3. ORVAL_path_cells
    % ---------------------
    sqlquery = 'SELECT new2kid, spid, path_pct, patharea, cellarea_lc FROM nevo.paths_cells ORDER BY new2kid';
    curs = exec(conn,sqlquery);
    setdbprefs('DataReturnFormat','table')
    curs = fetch(curs);
    ORVal_paths_cells = table2array(curs.Data);
    close(curs);
    
    % 1.4. ORVAL_park_cells
    % ---------------------
    sqlquery = 'SELECT new2kid, spid, park_pct FROM nevo.parks_cells ORDER BY new2kid';
    curs = exec(conn,sqlquery);
    setdbprefs('DataReturnFormat','table')
    curs = fetch(curs);
    ORVal_parks_cells = table2array(curs.Data);
    close(curs);
    
    % 1.5. ORVAL_beaches_cells
    % ---------------------
    sqlquery = 'SELECT new2kid, spid, beach_pct FROM nevo.beaches_cells ORDER BY new2kid';
    curs = exec(conn,sqlquery);
    setdbprefs('DataReturnFormat','table')
    curs = fetch(curs);
    ORVal_beaches_cells = table2array(curs.Data);
    close(curs);
    
    % 1.6. ORVAL_site
    % ---------------
    sqlquery = 'SELECT spid, pid, easting, northing, v1xlc, divxlc, div_pct, fw_pct, sw_pct, path, cpk FROM nevo.v1_mnl3 ORDER BY spid';
    curs = exec(conn,sqlquery);
    setdbprefs('DataReturnFormat','table')
    curs = fetch(curs);
    ORVal_site = curs.Data;
    close(curs);
    
    % 1.7. NEVO_base_rec_areas
    % ------------------------
    sqlquery = 'SELECT * FROM nevo.sites_cells ORDER BY new2kid';
    curs = exec(conn,sqlquery);
    setdbprefs('DataReturnFormat','table')
    curs = fetch(curs);
    NEVO_base_rec_areas = curs.Data;
    close(curs);
   
    %% (2) REC. MODEL DATA
    %  
    %  ===================
    
    % (e) ORVal v0 data: 
    % ------------------
    % ORVAl paths_cells table
    sqlquery = 'SELECT * FROM nevo.v0_mnl3 ORDER BY lsoanum';
    curs = exec(conn,sqlquery);
    setdbprefs('DataReturnFormat','table')
    curs = fetch(curs);
    ORVal_v0 = curs.Data;
    close(curs);

    expv0      = exp([ORVal_v0.v0ab ORVal_v0.v0c1 ORVal_v0.v0c2 ORVal_v0.v0de]);
    lsoa_pop   = [ORVal_v0.nab ORVal_v0.nc1 ORVal_v0.nc2 ORVal_v0.nde];
    lsoa_loc   = [ORVal_v0.easting ORVal_v0.northing];
    lsoa_nocar = ORVal_v0.nocar;
    
    % a. Construct Working Matrices for Vis & Val in Baseline and for NEVO alter
    % --------------------------------------------------------------------------
    dovisvalloop   = 1;
    doSumexpv1loop = 1;

    % dotestinput    = 0;

    % b. Model
    % --------    
    model.type = 'mnl3';       % mnl, nmnl, xmnl
    
    % c. Site type
    % ------------
    sitetype = 'path_chg';

    % c. Data files 
    % -------------
%     data_folder = 'E:\MyData\Research\Projects (Land Use)\NEVO\Recreation\Matlab\';
    % For Baseline & constuction of NEVO working matrices
%     NEVO_ORVal_build_data_mat     = strcat(data_folder, 'NEVO_ORVal_build_data.mat');
%     NEVO_ORVal_sumexpv1_data_mat  = strcat(data_folder, 'NEVO_ORVal_sumexpv1_data.mat');
%     % For NEVO:
%     NEVO_ORVal_data_mat           = strcat(data_folder, 'NEVO_ORVal_data.mat');
%     NEVO_ORVal_max_data_mat       = strcat(data_folder, 'NEVO_ORVal_max_data.mat');
%     NEVO_ORVal_visval_data_mat    = strcat(data_folder, 'NEVO_ORVal_visval_data.mat');


    % e. NEVO mats from NEVORec1
    % --------------------------
%     tic;
%         NEVO_ORVal_build_data = load(NEVO_ORVal_build_data_mat);
%         NEVO_ORVal_data       = load(NEVO_ORVal_data_mat);
%     toc  


    %% (2) TRANSLATE NEVO INPUT CELL LANDCOVERS TO ORVAL PATH LANDCOVERS
    % ==================================================================
    % Calculation of Rec Model Categories from NEVO Categories:
    %    Wood          = Woodland
    %    Agriculture   = Crops
    %    Managed Grass = Permanent Grassland + Temporary Grassland
    %    Natural Grass = Rough Grazing + Semi-Natural Grassland    

    tic;    

    % (a) NEVO Input data: Area in cell under Wood, Agric, Managed Grass, Semi-Natural Grass
    % --------------------------------------------------------------------------------------
    % NEVO_input Columns:
    %    1  new2kid    - cell ids of changed cells
    %   2020s:
    %    2   %cell_wd  - ha in wood
    %    3   %cell_ag  - ha in agriculture
    %    4   %cell_mg  - ha in managed grass
    %    5   %cell_ng  - ha in natural grass
    %   2030s
    %    6 - 9
    %   2040s
    %    10 - 13
    %   2050s
    %    14 - 17

    % For Baseline Visit & Values are stored in NEVO_ORVal_build_data
    NEVO_input = NEVO_base_lcs;
    ncells = length(NEVO_input);

    % if (dotestinput == 1)
    %     nchange = 1000;
    %     NEVO_input = NEVO_input(randperm(ncells,nchange),:);
    %     NEVO_input(:,2:17) = NEVO_input(:,2:17)/2;
    %     ncells = nchange;
    % end


    % (b) NEVO cell areas to percentages
    % ----------------------------------
    % Index of cell ids in input data in NEVO_base_sumlcs (sum of green lcs in that cell in the baseline)
    [~,newcell_idx] = ismember(NEVO_input(:,1), NEVO_base_sumlcs(:,1));

    % New landcovers to percentage of base green land area. If urban has
    % expanded then percentages no longer sum to 1 
    NEVO_new_lcs_pcts = [NEVO_input(:,1) ... 
                         NEVO_input(:,2:5)./NEVO_base_sumlcs(newcell_idx,2)  ... 
                         NEVO_input(:,6:9)./NEVO_base_sumlcs(newcell_idx,3)  ...
                         NEVO_input(:,10:13)./NEVO_base_sumlcs(newcell_idx,4)  ...
                         NEVO_input(:,14:17)./NEVO_base_sumlcs(newcell_idx,5)];


    % (c) Construct table of base lcs in cells crossed by paths in changed cells
    % --------------------------------------------------------------------------

    % i. Find Spids of paths in changed land cells
    % --------------------------------------------
    % Find cells in ORVal_paths_cells that are in NEVO_input, select out path 
    % spids within these cells then reduce to unique spids
    %  ORVal_paths_cells columns:
    %    1     new2kid      cell id
    %    2     spid         path id
    %    3     patharea     total area of path across all cells
    %    4     cellarea_lc  area under wd, ag, ng, mg within cell (urban and water not included)
    %    5     path_pct     percentage of total path area within cell
    new_paths_spids = unique(ORVal_paths_cells(ismember(ORVal_paths_cells(:,1), NEVO_input(:,1)), 2));


    % ii. Select all cells containing these spids
    % -------------------------------------------
    % Since path can go beyond changed cells, select out cells that contain
    % path that cross changed changed cells
    new_paths_cells  = ORVal_paths_cells(ismember(ORVal_paths_cells(:,2), new_paths_spids), :);

    % iii. Join NEVO base landcovers pcts to the data on these cells
    % --------------------------------------------------------------
    % Find index of cells in matrix holding base lc pcts and add pcts cols to
    % new_path_cells table
    %  NEVO_base_lcs_pcts columns:
    %    1      new2kid    cell id
    %    2-5    pct_lc 20  percentage in each green landcover in 20s
    %    6-9    pct_lc 30  percentage in each green landcover in 30s
    %    10-13  pct_lc 40  percentage in each green landcover in 40s
    %    14-17  pct_lc 50  percentage in each green landcover in 50s
    [~, cells_idx]   = ismember(new_paths_cells(:,1), NEVO_base_lcs_pcts(:,1));
    new_paths_cells = [new_paths_cells NEVO_base_lcs_pcts(cells_idx,2:17)];
    %  joined table - new_paths_cells columns:
    %    1     new2kid       cell id
    %    2     spid          path id
    %    3     path_pct      percentage of total path area within cell
    %    4     patharea      total area of path across all cells
    %    5     cellarea_lc   area under wd, ag, ng, mg within cell (urban and water not included) in baseline
    %    6-9   pct_lc 20     percentage in each green landcover in 20s
    %    10-13 pct_lc 30     percentage in each green landcover in 30s
    %    14-17 pct_lc 40     percentage in each green landcover in 40s
    %    18-21 pct_lc 50     percentage in each green landcover in 50s


    % (d) Update base landcover pct to NEVO input landcover pcts
    % ----------------------------------------------------------
    [new_cells, new_cells_idx]      = ismember(new_paths_cells(:,1), NEVO_new_lcs_pcts(:,1));
    new_paths_cells(new_cells,6:21) = NEVO_new_lcs_pcts(new_cells_idx(new_cells),2:17);


    % (e) Calculate has of each landcover along each Path Segment under new NEVO landcovers (pcts * cellarea_lc)
    % ---------------------------------------------------------------------------------------------------------
    paths_cells_new_lc_has = new_paths_cells(:,6:21).*new_paths_cells(:,5); 


    % (f) Accumulate lcs from each path-segment in different cells to give path lc totals
    % -----------------------------------------------------------------------------------    
    [new_paths_spids,idxa,idxb] = unique(new_paths_cells(:,2));

    for jj = size(paths_cells_new_lc_has,2):-1:1 % Count backwards for dynamic preallocation
        new_paths_lcs_has(:,jj) = accumarray(idxb, paths_cells_new_lc_has(:,jj));
    end

    new_paths_patharea = new_paths_cells(idxa,4);
    new_paths_lcs_pct  = new_paths_lcs_has./new_paths_patharea; % Percent of whole path area under 4 green landcovers

    toc;



    %% (3) CALCULATE v1 FOR EACH ORVAL PATH WITH NEW LANDCOVERS
    % =========================================================
    tic;
    nlsoa  = size(expv0,1);
    nsites = size(ORVal_site.spid,1);
    npaths = sum(ORVal_site.path);
    ndecades  = 4;
    nsegs     = 4;
    nlsoasave = 50;

    % (a) ORVal LC Parameters
    % -----------------------
    [model, params] = fcn_nevo_include_read_params(model); 

    % (b) Calculate new expv1 with new landcovers
    % -------------------------------------------
    % Index of path_spids in full list of ORVal spids
    [~, path_idx] = ismember(new_paths_spids,ORVal_site.spid);

    v1lc(:,1) = nevo_function_calculate_v1_lc(sitetype, new_paths_lcs_pct(:,1:4),  new_paths_patharea, ORVal_site.divxlc(path_idx), ORVal_site.div_pct(path_idx), [ORVal_site.fw_pct(path_idx) ORVal_site.sw_pct(path_idx)], params);
    v1lc(:,2) = nevo_function_calculate_v1_lc(sitetype, new_paths_lcs_pct(:,5:8),  new_paths_patharea, ORVal_site.divxlc(path_idx), ORVal_site.div_pct(path_idx), [ORVal_site.fw_pct(path_idx) ORVal_site.sw_pct(path_idx)], params);
    v1lc(:,3) = nevo_function_calculate_v1_lc(sitetype, new_paths_lcs_pct(:,9:12), new_paths_patharea, ORVal_site.divxlc(path_idx), ORVal_site.div_pct(path_idx), [ORVal_site.fw_pct(path_idx) ORVal_site.sw_pct(path_idx)], params);
    v1lc(:,4) = nevo_function_calculate_v1_lc(sitetype, new_paths_lcs_pct(:,13:16),new_paths_patharea, ORVal_site.divxlc(path_idx), ORVal_site.div_pct(path_idx), [ORVal_site.fw_pct(path_idx) ORVal_site.sw_pct(path_idx)], params);

    ORVal_site.v1xlc = repmat(ORVal_site.v1xlc,1,ndecades); %No change parks & beaches
    v1    = ORVal_site.v1xlc; %No change parks & beaches
    v1(path_idx,:) = v1(path_idx,:) + v1lc;

    toc;

    %% (4) CALCULATE NEVO BASELINE LC VISITS AND VALUE & NEVO ALTER LC WORKING MATRICES
    % =================================================================================
    tic;   

    % (a) Travel Cost Parameters
    % --------------------------
    bTCcar   = cell2mat(params(strcmp(params(:,1),'TCCAR'), 2));
    bTCwlk   = cell2mat(params(find(strcmp(params(:,1),'TCWALK')),2));
    bnocar   = cell2mat(params(strcmp(params(:,1),'CNOCAR'),2));
    bwlk     = cell2mat(params(strcmp(params(:,1),'CWALK'), 2));
    bPcarcpk = cell2mat(params(strcmp(params(:,1),'PCARCPK'), 2));

    % (b) Loop through sites for Sumexp terms for each LSOA under baseline
    % --------------------------------------------------------------------
    % NOTE: 1 hr run time
    % -------------------
    if (doSumexpv1loop == 1)

        Sumexpv1car = zeros(nlsoa,1);
        Sumexpv1wlk = zeros(nlsoa,1);

        count = 0; count1 = 0;
        for i = 1:nsites

            % Calculate travel costs from Site to all LSOAs
            % ---------------------------------------------        
            [v1car, v1wlk] = nevo_function_calculate_v1_tc(lsoa_loc, lsoa_nocar, [ORVal_site.easting(i,:) ORVal_site.northing(i,:)] , ORVal_site.cpk(i), bTCcar, bnocar, bPcarcpk, bTCwlk, bwlk);

            % e(v) = e(v1)*e(vtc) for walk & drive options for this site
            % -----------------------------------------------------------
            Sumexpv1car = Sumexpv1car + exp(v1(i,:) + v1car);
            Sumexpv1wlk = Sumexpv1wlk + exp(v1(i,:) + v1wlk);

            if sum(isnan(Sumexpv1car(:,1))) > 0
                disp('Problemo!');
            end

            count  = count  + 1; count1 = count1 + 1;
            if count1 == 1000
                disp(count);
                count1 = 0;
            end

        end

        toc;
    end


    % (c) Loop through sites calculating vis & val and working matrix for NEVO landcover alter
    % ----------------------------------------------------------------------------------------
    % NOTE: 2 hr run time
    % -------------------
    if (dovisvalloop == 1)
      
        % Sumexpv for each Socioeconomic Seg
        Sumexpvxv0 = Sumexpv1car + Sumexpv1wlk;    
        Sumexpv(:,:,1) = expv0 + Sumexpvxv0(:,1);
        Sumexpv(:,:,2) = expv0 + Sumexpvxv0(:,2);
        Sumexpv(:,:,3) = expv0 + Sumexpvxv0(:,3);
        Sumexpv(:,:,4) = expv0 + Sumexpvxv0(:,4);   

        % Val & Vis estimates for baseline landcovers:
        val    = zeros(nsites,nsegs,ndecades);
        vis    = zeros(nsites,nsegs,ndecades);
        carvis = zeros(nsites,ndecades);
        wlkvis = zeros(nsites,ndecades);

        % max lsoa elements for NEVO new landcovers:
        max_spid             = zeros(npaths,1);
        max_Index            = zeros(npaths, nlsoasave);
        max_Sumexpv1car_base = zeros(nlsoasave, ndecades, npaths);
        max_Sumexpv1wlk_base = zeros(nlsoasave, ndecades, npaths);
        max_expv1cari_base   = zeros(nlsoasave, ndecades, npaths);
        max_expv1wlki_base   = zeros(nlsoasave, ndecades, npaths);
        max_v1carxlc         = zeros(nlsoasave, ndecades, npaths);
        max_v1wlkxlc         = zeros(nlsoasave, ndecades, npaths);
        max_ev0              = zeros(nlsoasave, nsegs, npaths);
        max_lsoapop          = zeros(nlsoasave, nsegs, npaths);

        tic;
        count = 0; count1 = 0; pathcount = 1;
        for i = 1:nsites
            % Calculate travel costs from Site to all LSOAs
            % ---------------------------------------------
            [v1car, v1wlk] = nevo_function_calculate_v1_tc(lsoa_loc, lsoa_nocar, [ORVal_site.easting(i,:) ORVal_site.northing(i,:)], ORVal_site.cpk(i), bTCcar, bnocar, bPcarcpk, bTCwlk, bwlk);

            expv1cari = exp(v1(i,:) + v1car);
            expv1wlki = exp(v1(i,:) + v1wlk);

            % Sum visits to this site across all lsoa populations
            % --------------------------------------------------- 
            for k = 1:ndecades
                carvisi  = sum((expv1cari./Sumexpv(:,:,k)) .* lsoa_pop * 365, 1);    
                wlkvisi  = sum((expv1wlki./Sumexpv(:,:,k)) .* lsoa_pop * 365, 1); 

                carvis(i,k)  = sum(carvisi);    
                wlkvis(i,k)  = sum(wlkvisi);    
                vis(i,:,k)   = carvisi + wlkvisi;            
                val(i,:,k)   = (1/-bTCcar)*sum((log(Sumexpv(:,:,k)) - log(Sumexpv(:,:,k) - expv1cari - expv1wlki)) .* lsoa_pop * 365);            
            end

            % Save Working Matrices for NEVO landcover alter impacts on path recreation
            % -------------------------------------------------------------------------       
            if ORVal_site.path(i) == 1

                pathcount = pathcount + 1;

                % LSOAs generating most value from site i
                % ---------------------------------------
                vali  = sum((log(Sumexpv(:,:,1)) - log(Sumexpv(:,:,1) - expv1cari - expv1wlki)) .* lsoa_pop, 2);
                [~, sortIndexi] = sort(vali, 'descend');  % Sort the values in descending order
                maxIndexi = sortIndexi(1:nlsoasave);

                % Create Matrices for NEVO lc change calculations
                % -----------------------------------------------
                max_spid(pathcount)    = ORVal_site.spid(i);
                max_Index(pathcount,:) = maxIndexi'; % index to max lsoas

                % For max lsoas: Baseline sum across expv1 for sites and expv1 for this site
                max_Sumexpv1car_base(:,:,pathcount) = Sumexpv1car(maxIndexi,:);
                max_Sumexpv1wlk_base(:,:,pathcount) = Sumexpv1wlk(maxIndexi,:);
                max_expv1cari_base(:,:,pathcount)   = expv1cari(maxIndexi,:);
                max_expv1wlki_base(:,:,pathcount)   = expv1wlki(maxIndexi,:);

                % For max lsoas: v1 without landcovers for this site
                max_v1carxlc(:,:,pathcount) = ORVal_site.v1xlc(i,:) + v1car(maxIndexi);
                max_v1wlkxlc(:,:,pathcount) = ORVal_site.v1xlc(i,:) + v1wlk(maxIndexi);

                % For max lsoas: v0 and lsoa population data
                max_ev0(:,:,pathcount)     = expv0(maxIndexi,:);
                max_lsoapop(:,:,pathcount) = lsoa_pop(maxIndexi,:);

            end

            count  = count  + 1; count1 = count1 + 1;
            if count1 == 500
                t = toc; tic;
                fprintf('count: %d   time: %.4f \n', count, t);
                count1 = 0;
            end


        end 
    end
    
    spid = ORVal_site.spid;
    NEVO_ORVal_visval_data = struct('spid', spid, 'carvis', carvis, 'wlkvis', wlkvis, 'vis', vis, 'val', val);

%     if (dosavemats == 1)
%         save(NEVO_ORVal_max_data_mat, 'max_spid','max_Index','max_Sumexpv1car_base','max_Sumexpv1wlk_base','max_expv1cari_base','max_expv1wlki_base',...
%                                       'max_v1carxlc','max_v1wlkxlc','max_ev0','max_lsoapop',...
%                                       '-mat', '-v6');      
%         
%         save(NEVO_ORVal_visval_data_mat, 'spid','carvis','wlkvis','vis','val', '-mat', '-v6');      
%     end


    %% (5) TRANSLATE FROM VALUES TO CELLS
    % ==================================

    % a. Make Path, Park & Beach VisVal tables
    % ----------------------------------------
    tic;

        % i. Paths
        % --------
        [~,spid_idx] = ismember(ORVal_paths_cells(:,2), NEVO_ORVal_visval_data.spid(:,1));
        visval_paths_paths_cells = [ORVal_paths_cells(:, 1) ...
                                    [NEVO_ORVal_visval_data.carvis(spid_idx,:)   ...
                                     NEVO_ORVal_visval_data.wlkvis(spid_idx,:)   ...
                                     NEVO_ORVal_visval_data.vis(spid_idx,:,1)   ...
                                     NEVO_ORVal_visval_data.vis(spid_idx,:,2)   ...
                                     NEVO_ORVal_visval_data.vis(spid_idx,:,3)   ...
                                     NEVO_ORVal_visval_data.vis(spid_idx,:,4)   ...
                                     NEVO_ORVal_visval_data.val(spid_idx,:,1)   ...
                                     NEVO_ORVal_visval_data.val(spid_idx,:,2)   ...
                                     NEVO_ORVal_visval_data.val(spid_idx,:,3)   ...
                                     NEVO_ORVal_visval_data.val(spid_idx,:,4) ].*ORVal_paths_cells(:,3)];

        [cellids,~,cell_idx] = unique(visval_paths_paths_cells(:,1));

        visval_paths_cells = [cellids zeros(size(cellids,1),size(visval_paths_paths_cells,2)-1)];

        for jj = 2:size(visval_paths_cells,2)
            visval_paths_cells(:,jj) = accumarray(cell_idx, visval_paths_paths_cells(:,jj));
        end

        visval_paths = array2table( [ visval_paths_cells(:,1) ...
                                      visval_paths_cells(:,2:5)+visval_paths_cells(:,6:9) ...
                                      visval_paths_cells(:,2:5)  ...
                                      visval_paths_cells(:,6:9)  ...
                                      visval_paths_cells(:,10:13) ...
                                      visval_paths_cells(:,14:17) ...
                                      visval_paths_cells(:,18:21) ...
                                      visval_paths_cells(:,22:25) ...
                                      sum(visval_paths_cells(:,26:29),2) sum(visval_paths_cells(:,30:33),2) sum(visval_paths_cells(:,34:37),2) sum(visval_paths_cells(:,38:41),2) ...
                                      visval_paths_cells(:,26:29) ...
                                      visval_paths_cells(:,30:33) ...
                                      visval_paths_cells(:,34:37) ...
                                      visval_paths_cells(:,38:41) ], ...
                                    'VariableNames',{'new2kid', ...
                                                     'pth_vis_20',   'pth_vis_30',   'pth_vis_40',   'pth_vis_50', ...
                                                     'pth_viscar_20','pth_viscar_30','pth_viscar_40','pth_viscar_50', ...
                                                     'pth_viswlk_20','pth_viswlk_30','pth_viswlk_40','pth_viswlk_50', ...
                                                     'pth_visab_20', 'pth_visc1_20', 'pth_visc2_20', 'pth_visde_20', ...
                                                     'pth_visab_30', 'pth_visc1_30', 'pth_visc2_30', 'pth_visde_30', ...
                                                     'pth_visab_40', 'pth_visc1_40', 'pth_visc2_40', 'pth_visde_40', ...
                                                     'pth_visab_50', 'pth_visc1_50', 'pth_visc2_50', 'pth_visde_50', ...
                                                     'pth_val_20',   'pth_val_30',   'pth_val_40',   'pth_val_50',   ...
                                                     'pth_valab_20', 'pth_valc1_20', 'pth_valc2_20', 'pth_valde_20', ...
                                                     'pth_valab_30', 'pth_valc1_30', 'pth_valc2_30', 'pth_valde_30', ...
                                                     'pth_valab_40', 'pth_valc1_40', 'pth_valc2_40', 'pth_valde_40', ...
                                                     'pth_valab_50', 'pth_valc1_50', 'pth_valc2_50', 'pth_valde_50'});

        % ii. Parks
        % ---------
        [~,spid_idx] = ismember(ORVal_parks_cells(:,2), NEVO_ORVal_visval_data.spid(:,1));
        visval_parks_paths_cells = [ORVal_parks_cells(:, 1) ...
                                    [NEVO_ORVal_visval_data.carvis(spid_idx,:)   ...
                                     NEVO_ORVal_visval_data.wlkvis(spid_idx,:)  ...
                                     NEVO_ORVal_visval_data.vis(spid_idx,:,1)   ...
                                     NEVO_ORVal_visval_data.vis(spid_idx,:,2)   ...
                                     NEVO_ORVal_visval_data.vis(spid_idx,:,3)   ...
                                     NEVO_ORVal_visval_data.vis(spid_idx,:,4)   ...
                                     NEVO_ORVal_visval_data.val(spid_idx,:,1)   ...
                                     NEVO_ORVal_visval_data.val(spid_idx,:,2)   ...
                                     NEVO_ORVal_visval_data.val(spid_idx,:,3)   ...
                                     NEVO_ORVal_visval_data.val(spid_idx,:,4)].*ORVal_parks_cells(:,3)];

        [cellids,~,cell_idx] = unique(visval_parks_paths_cells(:,1));

        visval_parks_cells = [cellids zeros(size(cellids,1),size(visval_parks_paths_cells,2)-1)];

        for jj = 2:size(visval_parks_cells,2)
            visval_parks_cells(:,jj) = accumarray(cell_idx, visval_parks_paths_cells(:,jj));
        end

        visval_parks = array2table( [ visval_parks_cells(:,1) ...
                                      visval_parks_cells(:,2:5)+visval_parks_cells(:,6:9) ...
                                      visval_parks_cells(:,2:5)  ...
                                      visval_parks_cells(:,6:9)  ...
                                      visval_parks_cells(:,10:13) ...
                                      visval_parks_cells(:,14:17) ...
                                      visval_parks_cells(:,18:21) ...
                                      visval_parks_cells(:,22:25) ...
                                      sum(visval_parks_cells(:,26:29),2) sum(visval_parks_cells(:,30:33),2) sum(visval_parks_cells(:,34:37),2) sum(visval_parks_cells(:,38:41),2) ...
                                      visval_parks_cells(:,26:29) ...
                                      visval_parks_cells(:,30:33) ...
                                      visval_parks_cells(:,34:37) ...
                                      visval_parks_cells(:,38:41) ], ...
                                    'VariableNames',{'new2kid', ...
                                                     'prk_vis_20',   'prk_vis_30',   'prk_vis_40',   'prk_vis_50', ...
                                                     'prk_viscar_20','prk_viscar_30','prk_viscar_40','prk_viscar_50', ...
                                                     'prk_viswlk_20','prk_viswlk_30','prk_viswlk_40','prk_viswlk_50', ...
                                                     'prk_visab_20', 'prk_visc1_20', 'prk_visc2_20', 'prk_visde_20', ...
                                                     'prk_visab_30', 'prk_visc1_30', 'prk_visc2_30', 'prk_visde_30', ...
                                                     'prk_visab_40', 'prk_visc1_40', 'prk_visc2_40', 'prk_visde_40', ...
                                                     'prk_visab_50', 'prk_visc1_50', 'prk_visc2_50', 'prk_visde_50', ...
                                                     'prk_val_20',   'prk_val_30',   'prk_val_40',   'prk_val_50',   ...
                                                     'prk_valab_20', 'prk_valc1_20', 'prk_valc2_20', 'prk_valde_20', ...
                                                     'prk_valab_30', 'prk_valc1_30', 'prk_valc2_30', 'prk_valde_30', ...
                                                     'prk_valab_40', 'prk_valc1_40', 'prk_valc2_40', 'prk_valde_40', ...
                                                     'prk_valab_50', 'prk_valc1_50', 'prk_valc2_50', 'prk_valde_50'});

        % iii. Beaches
        % ------------
        [~,spid_idx] = ismember(ORVal_beaches_cells(:,2), NEVO_ORVal_visval_data.spid(:,1));
        visval_beaches_paths_cells = [ORVal_beaches_cells(:, 1) ...
                                    [NEVO_ORVal_visval_data.carvis(spid_idx,:)   ...
                                     NEVO_ORVal_visval_data.wlkvis(spid_idx,:)  ...
                                     NEVO_ORVal_visval_data.vis(spid_idx,:,1)   ...
                                     NEVO_ORVal_visval_data.vis(spid_idx,:,2)   ...
                                     NEVO_ORVal_visval_data.vis(spid_idx,:,3)   ...
                                     NEVO_ORVal_visval_data.vis(spid_idx,:,4)   ...
                                     NEVO_ORVal_visval_data.val(spid_idx,:,1)   ...
                                     NEVO_ORVal_visval_data.val(spid_idx,:,2)   ...
                                     NEVO_ORVal_visval_data.val(spid_idx,:,3)   ...
                                     NEVO_ORVal_visval_data.val(spid_idx,:,4)].*ORVal_beaches_cells(:,3)];

        [cellids,~,cell_idx] = unique(visval_beaches_paths_cells(:,1));

        visval_beaches_cells = [cellids zeros(size(cellids,1),size(visval_beaches_paths_cells,2)-1)];

        for jj = 2:size(visval_beaches_cells,2)
            visval_beaches_cells(:,jj) = accumarray(cell_idx, visval_beaches_paths_cells(:,jj));
        end


        visval_beaches = array2table( [ visval_beaches_cells(:,1) ...
                                        visval_beaches_cells(:,2:5)+visval_beaches_cells(:,6:9) ...
                                        visval_beaches_cells(:,2:5)  ...
                                        visval_beaches_cells(:,6:9)  ...
                                        visval_beaches_cells(:,10:13) ...
                                        visval_beaches_cells(:,14:17) ...
                                        visval_beaches_cells(:,18:21) ...
                                        visval_beaches_cells(:,22:25) ...
                                        sum(visval_beaches_cells(:,26:29),2) sum(visval_beaches_cells(:,30:33),2) sum(visval_beaches_cells(:,34:37),2) sum(visval_beaches_cells(:,38:41),2) ...
                                        visval_beaches_cells(:,26:29) ...
                                        visval_beaches_cells(:,30:33) ...
                                        visval_beaches_cells(:,34:37) ...
                                        visval_beaches_cells(:,38:41) ], ...
                                      'VariableNames',{'new2kid', ...
                                                       'bch_vis_20',   'bch_vis_30',   'bch_vis_40',   'bch_vis_50', ...
                                                       'bch_viscar_20','bch_viscar_30','bch_viscar_40','bch_viscar_50', ...
                                                       'bch_viswlk_20','bch_viswlk_30','bch_viswlk_40','bch_viswlk_50', ...
                                                       'bch_visab_20', 'bch_visc1_20', 'bch_visc2_20', 'bch_visde_20', ...
                                                       'bch_visab_30', 'bch_visc1_30', 'bch_visc2_30', 'bch_visde_30', ...
                                                       'bch_visab_40', 'bch_visc1_40', 'bch_visc2_40', 'bch_visde_40', ...
                                                       'bch_visab_50', 'bch_visc1_50', 'bch_visc2_50', 'bch_visde_50', ...
                                                       'bch_val_20',   'bch_val_30',   'bch_val_40',   'bch_val_50',   ...
                                                       'bch_valab_20', 'bch_valc1_20', 'bch_valc2_20', 'bch_valde_20', ...
                                                       'bch_valab_30', 'bch_valc1_30', 'bch_valc2_30', 'bch_valde_30', ...
                                                       'bch_valab_40', 'bch_valc1_40', 'bch_valc2_40', 'bch_valde_40', ...
                                                       'bch_valab_50', 'bch_valc1_50', 'bch_valc2_50', 'bch_valde_50'});


    % b. Join Paths, Parks & Beaches Tables
    % -------------------------------------
    visval = outerjoin(NEVO_base_rec_areas, visval_parks,'MergeKeys',true);
    visval = outerjoin(visval, visval_paths,'MergeKeys',true);          
    visval = outerjoin(visval, visval_beaches,'MergeKeys',true);
    
    NEVO_ORVal_chgsite_data = struct('max_ev0', max_ev0, ...
        'max_expv1cari_base', max_expv1cari_base, ...
        'max_expv1wlki_base', max_expv1wlki_base, ...
        'max_Index', max_Index, ...
        'max_lsoapop', max_lsoapop, ...
        'max_spid', max_spid, ...
        'max_Sumexpv1car_base', max_Sumexpv1car_base, ...
        'max_Sumexpv1wlk_base', max_Sumexpv1wlk_base, ...
        'max_v1carxlc', max_v1carxlc, ...
        'max_v1wlkxlc', max_v1wlkxlc, ...
        'NEVO_base_lcs_pcts', NEVO_base_lcs_pcts, ...
        'NEVO_base_rec_areas', NEVO_base_rec_areas, ...
        'NEVO_base_sumlcs', NEVO_base_sumlcs, ...
        'ORVal_paths_cells', ORVal_paths_cells, ...
        'ORVal_site', ORVal_site, ...
        'visval', visval);
    
end
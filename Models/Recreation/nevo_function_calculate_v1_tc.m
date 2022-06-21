% Calculates lsoa to each site travel costs
% -----------------------------------------

function [v1car, v1wlk] = nevo_function_calculate_v1_tc(lsoa_loc, lsoa_nocar, site_loci, cpki, bTCcar, bnocar, bPcarcpk, bTCwlk, bwlk)

    % Calculate travel costs from Site to all LSOAs
    % ---------------------------------------------
    disti = sqrt((lsoa_loc(:,1) - site_loci(1)).^2 + (lsoa_loc(:,2) - site_loci(2)).^2);

    % a. straightline vs. travel distance
    % -----------------------------------
    %  I(x/10^1)  I(x^2/10^7) I(x^3/10^12) I(x^4/10^17) I(x^5/10^22) I(x^6/10^28) I(x^7/10^34) 
    % 13.8250357   -0.8971193   -8.2906304    6.2314109   -1.9587947    2.7958513   -1.4747125
    tdistcar = (1/1000)*(13.8250357*disti/10 + -0.8971193*(disti.^2)/10^7 + -8.2906304*(disti.^3)/10^12 + 6.2314109*(disti.^4)/10^17 + -1.9587947*(disti.^5)/10^22 + 2.7958513*(disti.^6)/10^28 + -1.4747125*(disti.^7)/10^34); % Distance in km

    % b. straightline vs. car ttime
    % -----------------------------
    % I(x/10^2)  I(x^2/10^7) I(x^3/10^12) I(x^4/10^17) I(x^5/10^23) I(x^6/10^29) I(x^7/10^35) 
    % 7.598699    -4.626649     3.339851    -1.372186     3.111653    -3.624561     1.698963 
    ttimecar = (1/3600)*(7.598699*disti/10^2 + -4.626649*disti.^2/10^7 + 3.339851*disti.^3/10^12 + -1.372186*disti.^4/10^17 + 3.111653*disti.^5/10^23 + -3.624561*disti.^6/10^29 + 1.698963*disti.^7/10^35); % Time in hours

    % c. straightline vs. car fuel
    % ----------------------------
    % I(x/10^4) I(x^2/10^11) I(x^3/10^16) I(x^4/10^22) I(x^5/10^28) I(x^6/10^34) I(x^7/10^40) 
    % 0.8894736   -6.0871324    2.3648788   -4.9365203    5.4302182   -6.8220266    7.8306890 
    tfuelcar = 0.8894736*disti/10^4 + -6.0871324*disti.^2/10^11 + 2.3648788*disti.^3/10^16 + -4.9365203*disti.^4/10^22 + 5.4302182*disti.^5/10^28 + -6.8220266*disti.^6/10^34 + 7.8306890*disti.^7/10^40; % in £s

    % d. straightline vs. wlk ttime
    % -----------------------------
    % I(x/10^1)  I(x^2/10^6) I(x^3/10^11) I(x^4/10^17) I(x^5/10^22) I(x^6/10^28) I(x^7/10^34) 
    % 9.256409    -1.333951     1.048595    -5.246848     1.477974    -2.089121     1.154619 
    ttwlk = (1/3600)*(9.256409*disti/10 + -1.333951*disti.^2/10^6 + 1.048595*disti.^3/10^11 + -5.246848*disti.^4/10^17 + 1.477974*disti.^5/10^22 + -2.089121*disti.^6/10^28 + 1.154619*disti.^7/10^34); % Time in hours

    ttime = 2*ttimecar;
    tdist = 2*tdistcar;	
    tccar = 2*tfuelcar;
    ttwlk = 2*ttwlk;

    tccar = tccar + (2.30.*ttime)                      .*(tdist<=8) ... 
                  + (2.30.*ttime).*(8./tdist)          .*(tdist>8)  ... 
                  + (3.47.*ttime).*((tdist-8)./tdist)  .*(tdist>8).*(tdist<=32) ...
                  + (3.47.*ttime).*((32-8)./tdist)     .*(tdist>32) ...
                  + (6.14.*ttime).*((tdist-32)./tdist) .*(tdist>32).*(tdist<=160) ...
                  + (6.14.*ttime).*((160-32)./tdist)   .*(tdist>160) ...
                  + (9.25.*ttime).*((tdist-160)./tdist).*(tdist>160); 
    tccar(tdist==0) = 0; % In case get site on same 

    tcwlk = (exp(ttwlk)-1)*4.58;
    tcwlk(tcwlk>675 + isnan(tcwlk)) = 675;

    % Calculate walk & drive travel costs from Site to all LSOAs
    % ----------------------------------------------------------
    v1car = bTCcar*tccar + bnocar*lsoa_nocar + bPcarcpk*cpki;
    v1wlk = bTCwlk*tcwlk + bwlk;

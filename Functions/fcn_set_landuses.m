function landuse_table = fcn_set_landuses(columns_passed)
    
    required_vars = {'new2kid', 'urban_ha', 'sngrass_ha', 'wood_ha', ...
    'farm_ha', 'coast_ha', 'marine_ha', 'fwater_ha', 'ocean_ha'};

    missing_vars = setdiff(required_vars, columns_passed);

end
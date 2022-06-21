# Parse function arguments
# Get 'random_string'
args = commandArgs(trailingOnly = TRUE)
random_string = args[1]

# Load mgcv package
suppressPackageStartupMessages(require(mgcv))

# Set paths where .csv files are saved
# Passed between MATLAB and R
path_to_temp_save = "C:/Temp/"

# Load data needed to run model
# Prepared in MATLAB
lu_mod_data = read.csv(paste(path_to_temp_save, "lu_mod_data", random_string, ".csv", sep = ""), header = TRUE)

# Load landuse water quality models from .RData file
load("C:/Users/neo204/OneDrive - University of Exeter/NEV/Models/Water Transfer/orgn_lu_mod.RData")
load("C:/Users/neo204/OneDrive - University of Exeter/NEV/Models/Water Transfer/orgp_lu_mod.RData")
load("C:/Users/neo204/OneDrive - University of Exeter/NEV/Models/Water Transfer/no3_lu_mod.RData")
# No land use component for no2
# No land use component for nh4
load("C:/Users/neo204/OneDrive - University of Exeter/NEV/Models/Water Transfer/minp_lu_mod.RData")
load("C:/Users/neo204/OneDrive - University of Exeter/NEV/Models/Water Transfer/disox_lu_mod.RData")

# Predict from the models
# -----------------------
# Remember exp() transform
# Set NA values to 9999

# orgn
porgn_lu_mod = as.numeric(predict(orgn_lu_mod, 
                                  newdata = lu_mod_data, 
                                  type = "response"))
porgn_lu_mod = exp(porgn_lu_mod)
porgn_lu_mod[is.na(porgn_lu_mod)] = 9999

# orgp
porgp_lu_mod = as.numeric(predict(orgp_lu_mod, 
                                  newdata = lu_mod_data, 
                                  type = "response"))
porgp_lu_mod = exp(porgp_lu_mod)
porgp_lu_mod[is.na(porgp_lu_mod)] = 9999

# no3
pno3_lu_mod = as.numeric(predict(no3_lu_mod, 
                                 newdata = lu_mod_data, 
                                 type = "response"))
pno3_lu_mod = exp(pno3_lu_mod)
pno3_lu_mod[is.na(pno3_lu_mod)] = 9999

# minp
pminp_lu_mod = as.numeric(predict(minp_lu_mod, 
                                  newdata = lu_mod_data, 
                                  type = "response"))
pminp_lu_mod = exp(pminp_lu_mod)
pminp_lu_mod[is.na(pminp_lu_mod)] = 9999

# disox
pdisox_lu_mod = as.numeric(predict(disox_lu_mod, 
                                   newdata = lu_mod_data, 
                                   type = "response"))
pdisox_lu_mod = exp(pdisox_lu_mod)
pdisox_lu_mod[is.na(pdisox_lu_mod)] = 9999

# Save predictions to CSV
# -----------------------
# orgn
write.csv(porgn_lu_mod,
          paste(path_to_temp_save, "orgn_lu_mod_pred", random_string, ".csv", sep = ""),
          row.names = FALSE)

# orgp
write.csv(porgp_lu_mod,
          paste(path_to_temp_save, "orgp_lu_mod_pred", random_string, ".csv", sep = ""),
          row.names = FALSE)
# no3
write.csv(pno3_lu_mod,
          paste(path_to_temp_save, "no3_lu_mod_pred", random_string, ".csv", sep = ""),
          row.names = FALSE)
# minp
write.csv(pminp_lu_mod,
          paste(path_to_temp_save, "minp_lu_mod_pred", random_string, ".csv", sep = ""),
          row.names = FALSE)
# disox
write.csv(pdisox_lu_mod,
          paste(path_to_temp_save, "disox_lu_mod_pred", random_string, ".csv", sep = ""),
          row.names = FALSE)

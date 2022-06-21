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

# Load landuse flow model from .RData file
load("C:/Users/neo204/OneDrive - University of Exeter/NEV/Models/Water Transfer/flow_lu_mod.RData")

# Predict from the model
# Remember exp() transform
# Set NA values to 9999
pflow_lu_mod = as.numeric(predict(flow_lu_mod, 
                          newdata = lu_mod_data, 
                          type = "response"))
pflow_lu_mod = exp(pflow_lu_mod)
pflow_lu_mod[is.na(pflow_lu_mod)] = 9999

# Save predictions to CSV
write.csv(pflow_lu_mod,
          paste(path_to_temp_save, "flow_lu_mod_pred", random_string, ".csv", sep = ""),
          row.names = FALSE)

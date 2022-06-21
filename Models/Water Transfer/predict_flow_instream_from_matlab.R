path_to_temp_save = "C:/Temp/"

flow_instream_mod_data = read.csv(paste(path_to_temp_save, "flow_instream_mod_data.csv", sep = ""),
                                  header = TRUE)

load("C:/Users/neo204/OneDrive - University of Exeter/NEV/Models/Water Transfer/flow_instream_mod.RData")

pflow_instream_mod = as.numeric(predict(flow_instream_mod, 
                                  newdata = flow_instream_mod_data, 
                                  type = "response"))

pflow_instream_mod = exp(pflow_instream_mod) - 1
pflow_instream_mod[is.na(pflow_instream_mod)] = 9999

write.csv(pflow_instream_mod,
          paste(path_to_temp_save, "flow_instream_mod_pred.csv", sep = ""),
          row.names = FALSE)
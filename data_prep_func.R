####################################
# Data preparation wrapper function
####################################
library(dplyr)
library(anytime)
library(tidyverse)

prepData <- function(demo.path = "demo_train.csv", 
                     med.path = "medication_train.csv", 
                     proc.path = "procedure_train.csv", 
                     keep.los = F, # whether to keep LOS variable in the data
                     keep.id = F # whether to keep patient_sk in the data
                     ) {
  ## Read in data
  demo_df <- read.csv(demo.path, header = T)
  med_df <- read.csv(med.path, header = T)
  proc_df <- read.csv(proc.path, header = T)
  
  ## Convert factor time variable to date-time format
  demo_df <- demo_df %>% 
    mutate(New_admitted_dt_tm = anytime(New_admitted_dt_tm), ## anytime() Parse POSIXct or Date objects from input data
           New_discharge_dt_tm = anytime(New_discharge_dt_tm))
  
  med_df$med_started_dt_tm <- anytime(med_df$med_started_dt_tm)

  proc_df$procedure_dt_tm <- anytime(proc_df$procedure_dt_tm)
  
  ## Renaming
  demo_df <- demo_df %>% 
    rename(
      age = age_in_years,
      admission_date = New_admitted_dt_tm,
      discharge_date = New_discharge_dt_tm
    )
  
  med_df <- med_df %>% 
    rename(
      medication_date = med_started_dt_tm
    )
  
  proc_df <- proc_df %>% 
    rename(
      procedure_date = procedure_dt_tm
    )
  
  ## Merge medication and procedure data to demographics
  med_df <- demo_df %>% 
    dplyr::select(patient_sk, admission_date) %>% 
    right_join(med_df, by = "patient_sk")
  proc_df <- demo_df %>% 
    dplyr::select(patient_sk, admission_date) %>% 
    right_join(proc_df, by = "patient_sk")
  
  ## Calculate date differences
  demo_df <- demo_df %>% 
    mutate(
      los = as.numeric(difftime(discharge_date, admission_date, units ="days"))
    )
  
  med_df <- med_df %>% 
    mutate(
      days_med_adm = as.numeric(difftime(medication_date, admission_date, units ="days"))
    )
  
  proc_df <- proc_df %>% 
    mutate(
      days_pro_adm = as.numeric(difftime(procedure_date, admission_date, units ="days"))
    )
  
  ## Modify levels in race and remove any observations with LOS < 3 days
  ## Treat "Unknown" in race and gender as missing values 
  demo_df_new <- demo_df %>% filter(gender != "Unknown", 
                                    race != "Unknown") %>%
    mutate(race = fct_recode(race, 
                             `Others` = 'Asian', 
                             `Others` = 'Pacific Islander', 
                             `Others` = 'Asian/Pacific Islander', 
                             `Others` = 'Biracial', 
                             `Others` = 'Hispanic', 
                             `Others` = 'Mid Eastern Indian', 
                             `Others` = 'Native American', 
                             `Others` = 'Other')) %>%
    filter(los >= 3)
  
  ## Create new variables for medications and procedures
  med.tmp <- med_df %>% group_by(patient_sk) %>%
    summarise(n_med = n(),
              min_days_med_adm = min(days_med_adm),
              max_days_med_adm = max(days_med_adm),
              any_vaso = any(generic_name %in% c("dopamine", "phenylephrine",  "norepinephrine")),
              n_vaso = sum(generic_name %in% c("dopamine", "phenylephrine",  "norepinephrine")))
  
  
  proc.tmp <- proc_df %>% group_by(patient_sk) %>% 
    summarise(n_proc = n(), 
              min_days_pro_adm = min(days_pro_adm),
              max_days_pro_adm = max(days_pro_adm)) 
  
  #### Combining all dataframes into one by id and admission date (WHEN THE SMALLER DATASETS ARE CLEANED)
  joined_df <- demo_df_new %>%
    left_join(med.tmp, by = c('patient_sk')) %>%
    left_join(proc.tmp, by = c('patient_sk'))
  
  ## pivot med and proc dfs and merge with joined_df 
  ## to get individual meds/procedures as features
  # create meds and procs frequency table
  med_freq <- med_df %>% group_by(generic_name) %>%
    summarise(n = n()) %>%
    arrange(desc(n)) 
  
  proc_freq <- proc_df %>% group_by(procedure_id) %>%
    summarise(n = n(), 
              procedure_description = first(procedure_description)) %>%
    arrange(desc(n)) 
  # filter to only medications with 50 or more patients
  med_freq_filter = filter(med_freq, n>50) 
  #remove cols from med df so we get one row per patient after pivoting
  med_df = subset(med_df, select=-c(admission_date, medication_date))
  # pivot med df to get one row per patient
  med_df_pivot = med_df %>%
    group_by(patient_sk, generic_name) %>%
    filter(row_number() == 1) %>%
    mutate(n = 1) %>%
    pivot_wider(id_cols = patient_sk, 
                names_from = generic_name, 
                values_from = n, 
                values_fill = list(n = 0))
  #select subset of med pivot df with only medications given to 50 or more patients
  med_df_pivot_filter = subset(med_df_pivot,
                                  select= c('patient_sk',
                                            med_freq_filter$generic_name))
  # replace any uncommon characters (e.g. space, slash,...) in medication variable names to underscore "_"
  orig.names <- names(med_df_pivot_filter)
  new.names <- gsub(" ", "_", orig.names)
  new.names <- gsub("-", "_", new.names)
  new.names <- gsub("/", "_", new.names)
  new.names <- gsub(",_", "_", new.names)
  
  names(med_df_pivot_filter) <- new.names
  
  ## Pivot procedure variables
  proc_freq_filter = filter(proc_freq, n>50) 
  proc_df = subset(proc_df, select=-c(procedure_description,admission_date, procedure_date))
  proc_df_pivot = proc_df %>% 
    group_by(patient_sk, procedure_id) %>%
    filter(row_number() == 1) %>%
    mutate(n = 1) %>%
    pivot_wider(id_cols = patient_sk, 
                names_from = procedure_id, 
                values_from = n, 
                values_fill = list(n = 0))
  proc_df_pivot_filter = subset(proc_df_pivot,
                                   select= c('patient_sk',
                                             proc_freq_filter$procedure_id))
  # add a prefix "P" to procedure IDs 
  names(proc_df_pivot_filter) <- 
    c('patient_sk', paste0("P", names(proc_df_pivot_filter[,-1])))

  ## Merge data
  merged_df = joined_df %>%
    left_join(med_df_pivot_filter, by = c('patient_sk')) %>% 
    left_join(proc_df_pivot_filter, by = c('patient_sk'))
  
  final_df = subset(merged_df,
                       select= -c(admission_date,discharge_date))
  
  #convert categorical variables to factors
  final_df$gender = as.factor(final_df$gender)

  #convert response variable to binary
  if ("death" %in% names(final_df)) {
  final_df$death = as.integer(as.logical(final_df$death))
  }

  if (keep.los == F) {
    final_df <- final_df %>% dplyr::select(-los)
  }
  
  if (keep.id == F) {
    final_df <- final_df %>% dplyr::select(-patient_sk)
  }

  return(final_df)
}

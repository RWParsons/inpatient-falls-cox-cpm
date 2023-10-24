TABLES_UNPROCESSED_DIR <- "U:/Research/Projects/ihbi/aushsi/aushsi_students/inpatient_falls_RP/data/Falls"

TIME_HOURS_SPLIT <- 12

HOURS_MAX_STAY <- 14 * 24

MODEL_FORMULA <- Surv(tstart, tstop, fall) ~
  female + rms::rcs(age, 4) + rms::rcs(years_since_2018, 4) + admit_src +
  med_service + rms::rcs(tstart, 3) + prev_falls

FOLD_COLOURS <- c("#1b9e77", "#d95f02", "#7570b3", "#e7298a", "#66a61e")

DAYS_TROC <- 1:7

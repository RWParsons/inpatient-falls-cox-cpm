read_encounters <- function(file) {
  arrow::read_parquet(file = file) |>
    select(
      pt_id = Enc_Person_ID, enc_id = Enc_Encntr_ID, enc_mrn = Enc_MRN, visit_reason = REASON_FOR_VISIT,
      sex = SEX, age = Age, admit_type = ADMIT_TYPE, admit_src = ADMIT_SRC,
      med_service = MED_SERVICE, facility = FACILITY,
      disch_dest = DISCH_DISPOSITION,
      admit_dt = REG_DT_TM, disch_dt = DISCH_DT_TM, deceased_dt = DECEASED_DT_TM
    ) |>
    mutate(across(where(is.POSIXct), convert_to_AEST)) |>
    filter(admit_dt < disch_dt) |>
    mutate(
      status_deceased = as.integer((disch_dest == "Died in Hospital") & (as.Date(deceased_dt) <= as.Date(disch_dt))),
      time_deceased = ifelse(status_deceased == 1, deceased_dt, NA_POSIXct_),
      time_deceased = as.POSIXct.numeric(time_deceased, origin = "1970-01-01"),
      end_dt = ifelse(
        !is.na(time_deceased) & are_posixct_same_date(time_deceased, disch_dt),
        time_deceased,
        disch_dt
      ),
      end_dt = as.POSIXct.numeric(end_dt, origin = "1970-01-01"),
      time_start = 0,
      time_end = as.numeric(difftime(disch_dt, admit_dt, units = "hours"))
    ) |>
    select(-all_of(c("deceased_dt", "disch_dt", "time_deceased")))
}


read_riskman <- function(file) {
  arrow::read_parquet(file = file) |>
    janitor::clean_names() |>
    select(enc_id = enc_encntr_id, incident_dt, incident_tm) |>
    filter(!is.na(enc_id)) |>
    mutate(
      incident_tm = str_extract(incident_tm, "(?<= ).*"),
      across(where(is.POSIXct), convert_to_AEST),
      incident_dt = incident_dt + as.difftime(incident_tm, tz = "Australia/Queensland")
    ) |>
    select(-incident_tm)
}

convert_to_AEST <- function(x) {
  x <- as.character(x)
  as.POSIXct(x, tz = "Australia/Queensland")
}

are_posixct_same_date <- function(x1, x2) {
  as.POSIXct(as.character(x1), format = "%Y-%m-%d") == as.POSIXct(as.character(x2), format = "%Y-%m-%d")
}

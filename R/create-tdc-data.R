create_tdc_data <- function(encounters,
                            riskman,
                            time_hours_split,
                            hours_max_stay) {
  d_falls <- filter(riskman, enc_id %in% encounters$enc_id)

  fold_lookup <- encounters |>
    group_by(facility) |>
    summarize(n = n()) |>
    arrange(desc(n)) |>
    mutate(fold = row_number()) |>
    select(-n)

  encs <- encounters |>
    select(-all_of(c("pt_id", "enc_mrn", "disch_dest", "status_deceased", "end_dt", "time_start"))) |>
    distinct() |>
    mutate(
      female = ifelse(sex == "FEMALE", 1, 0),
      med_service = str_replace(med_service, "Transplantation", "tsplnt"),
      med_service = str_replace(med_service, "General Medical", "GenMed"),
      visit_reason = str_replace(visit_reason, "Suspected FB", "sus FB"),
      visit_reason = str_replace(visit_reason, "MBC/quadbike", "MBC"),
      across(where(is.character), \(x) {
        ifelse(x == "", "missing", x)
      }),
      across(where(is.character), as.factor),
      years_since_2018 = as.numeric(
        difftime(
          admit_dt,
          as.POSIXct(strptime("2018-01-01 00:00:00", "%Y-%m-%d %H:%M:%S")),
          units = "days"
        ) / 365.25
      )
    ) |>
    left_join(fold_lookup, by = "facility")


  d_fall_times <- d_falls |>
    left_join(select(encounters, enc_id, admit_dt)) |>
    mutate(time_fall = as.numeric(difftime(incident_dt, admit_dt, units = "hours"))) |>
    select(-incident_dt, -admit_dt) |>
    group_by(enc_id) |>
    arrange(time_fall) |>
    distinct() |>
    mutate(event_n = row_number())

  d_prev_falls <- d_fall_times |>
    mutate(prev_falls = event_n) |>
    select(-event_n)

  tmerge_falls <- function(data, fall_events) {
    for (n in 1:max(fall_events$event_n)) {
      data <- tmerge(data, filter(fall_events, event_n == n), id = enc_id, fall = event(time_fall))
    }
    data
  }

  tdc_data <- tmerge(encs, encs, id = enc_id, tstop = time_end) |>
    tmerge_falls(fall_events = d_fall_times) |> # add falls events
    # add predictor for count of previous falls
    left_join(d_prev_falls, by = c("enc_id", "tstart" = "time_fall")) |>
    mutate(
      prev_falls = ifelse(is.na(prev_falls), 0, prev_falls),
      admit_src = ifelse(admit_src %in% admit_src_cats, as.character(admit_src), "other"),
      med_service = fx_med_service(med_service),
      visit_reason = fx_visit_reason(visit_reason)
    )

  cut_hours <- seq(
    from = time_hours_split,
    to = floor(max(tdc_data$time_end) / time_hours_split) * time_hours_split,
    by = time_hours_split
  )

  survSplit(
    Surv(tstart, tstop, fall) ~ ., tdc_data,
    cut = cut_hours
  ) |>
    filter(tstop <= hours_max_stay)
}

fx_med_service <- function(x) {
  case_when(
    # keepers
    x %in% c(
      "Spinal", "GenMed", "Rehabilitation", "Palliative medicine",
      "Psychogeriatric", "Geriatrics", "Neurosurgery", "Orthopaedics"
    ) ~ x,
    x %in% c("Psychiatric Adult Residential", "Psychiatry") ~ "psych",
    .default = "other"
  )
}


fx_visit_reason <- function(x) {
  case_when(
    # keepers
    x == "missing" ~ x,

    # groupings
    x %in% c("Pedestrian vs", "Fall") ~ "fall and pedestrian vs",
    x %in% c("Weakness", "Gait disturbance", "Altered sensation") ~ "weakness/gait/altered sensation",
    x %in% c("Aggression", "Anxiety/agitation") ~ "aggression/anxiety/agitation",
    .default = "other"
  )
}


admit_src_cats <- c(
  "Residential Aged Care Service",
  "Community Service",
  "Admitted Pt Transferred from Other Hosp",
  "Emergency Department - this hospital",
  "Private Medical Practitioner (not Psych)",
  "Outpatient Department - this hospital",
  "Routine Readmission No Referral Required"
)

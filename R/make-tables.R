make_model_parm_table <- function(data, final_model) {
  cbind(final_model$coefficients, confint(final_model)) |>
    cbind(
      exp(cbind(final_model$coefficients, confint(final_model)))
    ) |>
    as.data.frame() |>
    (\(x) {
      names(x) <- c(
        "Estimate", "ci_95_ll", "ci_95_ul",
        "Hazard ratio", "ci_hr_95_ll", "ci_hr_95_ul"
      )
      x
    })() |>
    rownames_to_column(var = "Parameter") |>
    mutate(
      Parameter = str_remove(Parameter, ".*\\)(?=[a-z])"),
      Parameter = str_replace_all(Parameter, "'", "")
    ) |>
    mutate(
      across(!Parameter, function(v) format(round(v, 4), nsmall = 4)),
      `95% Confidence Interval` = glue("({ci_95_ll}, {ci_95_ul})"),
      `95% Confidence Interval ` = glue("({ci_hr_95_ll}, {ci_hr_95_ul})"),
      Parameter = clean_term(Parameter),
      Parameter = str_replace(Parameter, "Admission source", "Admission source ["),
      Parameter = str_replace(Parameter, "Medical service", "Medical service ["),
      Parameter = ifelse(str_detect(Parameter, "\\["), paste0(Parameter, "]"), Parameter)
    ) |>
    select(-starts_with("ci")) |>
    relocate("Hazard ratio", .before = last_col()) |>
    flextable()|>
    footnote(
      i = c(
        2,3,3,4,4,4, # age
        5,6,6,7,7,7, # time since 2018
        24,25,25 # tstart
      ), 
      j = 1,
      ref_symbols = "*",
      value = as_paragraph("Indicates the levels for the spline terms – see supplementary appendix 2 for table of knot locations for each term."),
      part = "body"
    ) |> 
    save_as_docx(path = file.path(OUT_DIR, "tbl-model-coefs.docx"))

  rcs_terms <- final_model$coefficients |>
    names() |>
    (\(x) x[str_detect(x, "rcs\\(")])() |>
    str_extract("^.*\\)") |>
    unique()


  lapply(
    rcs_terms,
    \(term) {
      eval(parse(text = glue("with(data, {term})")))
    }
  ) |>
    lapply(\(x) {
      format(round(attr(x, "parms"), 2), nsmall = 2) |>
        as.data.frame() |>
        t() |>
        as.data.frame()
    }) |>
    bind_rows() |>
    mutate(Term = str_extract(rcs_terms, "(?<=\\().*(?=,)")) |>
    remove_rownames() |>
    select(Term, everything()) |>
    pivot_longer(!Term, names_to = "Knot Number", values_to = "Knot Location") |>
    na.omit() |>
    mutate(
      `Knot Number` = str_replace(`Knot Number`, "V", ""),
      Term = clean_term(Term)
    ) |>
    group_by(Term) |>
    mutate(is_last_val_in_group = row_number() == max(row_number())) |>
    flextable(col_keys = c(
      "Term", "Knot Number", "Knot Location"
    )) |>
    merge_v(j = ~Term) |>
    hline(i = ~ is_last_val_in_group == TRUE, border = fp_border_default()) |>
    save_as_docx(path = file.path(OUT_DIR, "tbl-knot-locations.docx"))

  file.path(OUT_DIR, c("tbl-knot-locations.docx", "tbl-model-coefs.docx"))
}

clean_term <- function(x) {
  x |>
    str_replace("female", "Female") |>
    str_replace("age", "Age (years)") |>
    str_replace("years_since_2018", "Time since 2018 (years)") |>
    str_replace("tstart", "Time since admission (hours)") |>
    str_replace("admit_src", "Admission source") |>
    str_replace("med_service", "Medical service") |>
    str_replace("prev_falls", "Previous falls (n)") |>
    str_replace("[p,P]sych(?=[), \\]])", "Psychiatry") |>
    str_replace("psych$", "Psychiatry") |>
    str_replace("other$", "Other")
}


get_supp_power_by_fold_table <- function(data, all_models) {
  model_params <- all_models |>
    lapply(\(model_set){
      length(model_set$model$coefficients)
    }) |>
    unlist()

  final_model_params <- max(model_params)

  data |>
    mutate(max_time = ifelse(time_end > HOURS_MAX_STAY, HOURS_MAX_STAY, time_end)) |>
    group_by(fold) |>
    summarize(
      patients = n(),
      patient_days = round(sum((max_time - tstart) / 24)),
      falls_n = sum(falls_n)
    ) |>
    column_to_rownames(var = "fold") |>
    t() |>
    as.data.frame() |>
    mutate(across(!All, \(x) All - x)) |>
    t() |>
    as.data.frame() |>
    rownames_to_column(var = "fold") |>
    add_column(model_params = c(model_params, final_model_params)) |>
    mutate(
      `Events per parameter` = round(falls_n / model_params),
      Model = ifelse(fold == "All", "Final", paste0("Fold: ", fold))
    ) |>
    relocate(Model, .before = everything()) |>
    rename(
      `Inpatient admissions` = patients,
      `Patient days (truncated at 14 days)` = patient_days,
      `Falls (n)` = falls_n,
      `Model parameters (n)` = model_params
    ) |>
    select(-fold) |>
    flextable() |>
    footnote(
      i = 1, j = 1,
      ref_symbols = "*",
      value = as_paragraph("Model represents the cross-validation fold models and the final model fit with all patient data. The fold models are those fit during internal-external cross-validation and incorporate all patient data except for the associated hospital of the same number. For example, the 'Fold: 1' model was fit using patient data from hospitals 2 to 5, with hospital 1 being the validation set."),
      part = "header"
    ) |>
    save_as_docx(path = file.path(OUT_DIR, "tbl-power-by-fold.docx"))

  file.path(OUT_DIR, "tbl-power-by-fold.docx")
}

get_summary_table <- function(data) {
  demographics_data <-
    data |>
    group_by(fold) %>%
    summarize(
      grp_pat_count = n(),
      grp_pat_days = format_count(round(sum(time_end - tstart) / 24)),
      grp_pat_days_truncated = format_count(
        round(sum(
          ifelse(time_end > HOURS_MAX_STAY, HOURS_MAX_STAY, time_end) - tstart
        ) / 24)
      ),
      grp_female_count_perc = glue("{format_count(round(mean(female) * n()))} ({scales::percent(mean(female))})"),
      grp_falls_n = format_count(sum(falls_n)),
      grp_falls_fallers = (\(x) {
        f <- unique(fold)
        x |>
          filter(
            fold == f,
            falls_n > 0
          ) |>
          pull(enc_id) |>
          unique() |>
          length()
      })(.),
      grp_age_medn_iqr = format_median_iqr(age, dps = 0),
      grp_los_medn_iqr = format_median_iqr((time_end - tstart) / 24, dps = 1),
    ) |>
    mutate(
      grp_falls_fallers = glue("{format_count(grp_falls_fallers)} ({scales::percent(grp_falls_fallers/grp_pat_count, accuracy = 0.01)})"),
      grp_pat_count = format_count(grp_pat_count)
    ) |>
    mutate(across(everything(), as.character)) |>
    pivot_longer(!fold) |>
    as.data.frame() |>
    mutate(
      varname = str_extract(name, "(?<=^grp_)[a-z]*(?=_)"),
      measure = str_remove(name, glue(".*{varname}_"))
    ) |>
    select(fold, varname, measure, value)

  demographics_data |>
    bind_rows(
      f_cat_counts(data, "med_service"),
      f_cat_counts(data, "admit_src")
    ) |>
    mutate(
      varname = case_when(
        varname == "med_service" ~ "Medical service",
        varname == "admit_src" ~ "Admission source",
        varname == "pat" ~ "Inpatient admissions",
        varname == "female" ~ "Female",
        varname == "falls" ~ glue("Falls (truncated at {HOURS_MAX_STAY/24} days)"),
        varname == "age" ~ "Age",
        varname == "los" ~ "Length of stay",
        .default = varname
      ),
      measure = case_when(
        measure == "count" ~ "Count",
        measure == "days" ~ "Days",
        measure == "days_truncated" ~ glue("Days (truncated at {HOURS_MAX_STAY/24} days)"),
        measure == "count_perc" ~ "Count (%)",
        measure == "medn_iqr" ~ "Median (IQR)",
        measure == "n" ~ "Count",
        measure == "fallers" ~ "Fallers",
        measure == "falls" ~ "Falls",
        .default = measure
      ),
      fold = ifelse(fold != "All", paste0("Hospital_", fold), fold)
    ) |>
    pivot_wider(names_from = "fold", values_from = "value") |>
    rename(Measure = measure, Variable = varname) |>
    group_by(Variable) |>
    mutate(is_last_val_in_group = row_number() == max(row_number())) |>
    flextable(col_keys = c(
      "Variable", "Measure",
      paste0("Hospital_", 1:5),
      "All"
    )) |>
    merge_v(j = ~Variable) |>
    hline(i = ~ is_last_val_in_group == TRUE, border = fp_border_default()) |>
    separate_header() |>
    save_as_docx(path = file.path(OUT_DIR, "tbl-summary.docx"))

  file.path(OUT_DIR, "tbl-summary.docx")
}

format_count <- function(x) {
  prettyNum(x, big.mark = ",")
}

format_mean_sd <- function(x, dps) {
  f <- function(v) format(round(v, dps), nsmall = dps)
  glue(
    "{f(mean(x))} ({f(sd(x))})"
  )
}

format_median_iqr <- function(x, dps) {
  f <- function(v) format(round(v, dps), nsmall = dps)
  glue(
    "{f(median(x))} ({paste0(f(quantile(x, c(0.25, 0.75))), collapse = ' - ')})"
  )
}

make_short_data <- function(data) {
  data |>
    filter(tstop <= HOURS_MAX_STAY) |>
    group_by(enc_id) |>
    mutate(falls_n = sum(fall)) |>
    slice(1) |>
    ungroup() |>
    (\(df) rbind(
      df,
      mutate(df, fold = "All")
    ))()
}

f_cat_counts <- function(.data, col, val_min = 100) {
  .data |>
    group_by(fold, !!rlang::sym(col)) |>
    summarize(n = n()) |>
    ungroup() |>
    (\(d) {
      d_all <- filter(d, fold == "All") |>
        arrange(desc(n))

      levels <- c(d_all[[2]][d_all[[2]] != "other"], "other")
      d[[2]] <- factor(d[[2]], levels = levels)
      d
    })() |>
    arrange(!!rlang::sym(col)) |>
    pivot_wider(names_from = all_of(col), values_from = "n") |>
    mutate(across(
      !all_of("fold"),
      \(x) as.character(ifelse(is.na(x) | x < val_min, glue("< {val_min}"), format_count(x)))
    )) |>
    pivot_longer(!fold) |>
    add_column(varname = col) |>
    mutate(
      measure = glue("{name} (count)"),
      measure = str_to_sentence(measure),
      measure = str_replace(measure, "[p,P]sych(?=[), ])", "Psychiatry")
    ) |>
    select(-name)
}

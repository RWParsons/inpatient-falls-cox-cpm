make_model_parm_table <- function(data, final_model) {
  cbind(final_model$coefficients, confint(final_model)) |>
    as.data.frame() |>
    (\(x) {
      names(x) <- c("Estimate", "ci_95_ll", "ci_95_ul")
      x
    })() |>
    rownames_to_column(var = "Parameter") |>
    mutate(
      Parameter = str_remove(Parameter, ".*\\)(?=[a-z])"),
      Parameter = str_replace_all(Parameter, "'", "\\*")
    ) |>
    mutate(
      across(!Parameter, function(v) format(round(v, 4), nsmall = 4)),
      `95% Confidence Interval` = glue("({ci_95_ll}, {ci_95_ul})"),
      Parameter = str_replace(Parameter, "admit_src", "admit_src ["),
      Parameter = str_replace(Parameter, "med_service", "med_service ["),
      Parameter = ifelse(str_detect(Parameter, "\\["), paste0(Parameter, "]"), Parameter)
    ) |>
    select(-starts_with("ci")) |>
    flextable() |>
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
    mutate(across(everything(), \(x) ifelse(is.na(x), "", x))) |>
    (\(df) {
      names(df)[2:ncol(df)] <- paste("Knot", 1:(ncol(df) - 1))
      df
    })() |>
    flextable() |>
    save_as_docx(path = file.path(OUT_DIR, "tbl-knot-locations.docx"))

  file.path(OUT_DIR, c("tbl-knot-locations.docx", "tbl-model-coefs.docx"))
}


get_supp_power_by_fold_table <- function(data, all_models) {
  model_params <- all_models |>
    lapply(\(model_set){
      length(model_set$model$coefficients)
    }) |>
    unlist()

  final_model_params <- max(model_params)

  data |>
    group_by(fold) |>
    summarize(
      patients = n(),
      patient_days = round(sum(time_end - tstop) / 24),
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
      events_per_param = round(falls_n / model_params),
      fold = ifelse(fold == "All", "Full Model", fold)
    ) |>
    flextable() |>
    save_as_docx(path = file.path(OUT_DIR, "tbl-power-by-fold.docx"))

  file.path(OUT_DIR, "tbl-power-by-fold.docx")
}

get_summary_table <- function(data) {
  demographics_data <-
    data |>
    group_by(fold) %>%
    summarize(
      grp_pat_count = n(),
      grp_pat_days = format_count(round(sum(time_end - tstop) / 24)),
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
    pivot_wider(names_from = "fold", values_from = "value") |>
    flextable() |>
    merge_v(j = ~varname) |>
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
    pivot_wider(names_from = all_of(col), values_from = "n") |>
    mutate(across(
      !all_of("fold"),
      \(x) as.character(ifelse(is.na(x) | x < val_min, glue("< {val_min}"), format_count(x)))
    )) |>
    pivot_longer(!fold) |>
    add_column(varname = col) |>
    mutate(measure = glue("{name} (count)")) |>
    select(-name)
}

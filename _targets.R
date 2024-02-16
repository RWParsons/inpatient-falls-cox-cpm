# Created by use_targets().
# Follow the comments below to fill in this target script.
# Then follow the manual to check and run the pipeline:
#   https://books.ropensci.org/targets/walkthrough.html#inspect-the-pipeline

# Load packages required to define the pipeline:
library(targets)

# Set target options:
tar_option_set(
  packages = c("tidyverse", "survival", "data.table", "flextable"),
  format = "qs", # Optionally set the default storage format. qs is fast.
  garbage_collection = TRUE
)

# Run the R scripts in the R/ folder with your custom functions:
tar_source()

# Replace the target list below with your own:
list(
  # input files
  tar_target(
    encounters_file,
    file.path(TABLES_UNPROCESSED_DIR, "Encounters_Data.parquet"),
    format = "file"
  ),
  tar_target(
    riskman_file,
    file.path(TABLES_UNPROCESSED_DIR, "RISKMAN_Falls.parquet")
  ),


  # data
  tar_target(
    d_encounters,
    read_encounters(encounters_file)
  ),
  tar_target(
    d_riskman,
    read_riskman(riskman_file)
  ),
  tar_target(
    d_model,
    create_tdc_data(
      encounters = d_encounters,
      riskman = d_riskman,
      time_hours_split = TIME_HOURS_SPLIT,
      hours_max_stay = HOURS_MAX_STAY
    )
  ),

  # models
  tar_target(
    model1,
    fit_fold_model(
      d_model,
      formula = MODEL_FORMULA,
      valid_fold = 1
    )
  ),
  tar_target(
    model2,
    fit_fold_model(
      d_model,
      formula = MODEL_FORMULA,
      valid_fold = 2
    )
  ),
  tar_target(
    model3,
    fit_fold_model(
      d_model,
      formula = MODEL_FORMULA,
      valid_fold = 3
    )
  ),
  tar_target(
    model4,
    fit_fold_model(
      d_model,
      formula = MODEL_FORMULA,
      valid_fold = 4
    )
  ),
  tar_target(
    model5,
    fit_fold_model(
      d_model,
      formula = MODEL_FORMULA,
      valid_fold = 5
    )
  ),
  tar_target(
    all_models,
    list(model1, model2, model3, model4, model5)
  ),
  tar_target(
    final_model,
    coxph(MODEL_FORMULA, d_model)
  ),

  # time-dependent ROCs
  ## cued as never because they take ages to create and I spent time cleaning up
  ## code for preceding targets
  tar_target(
    d1_troc,
    make_troc(
      model_list = all_models,
      day = 1
    ),
    cue = tar_cue(mode = "never")
  ),
  tar_target(
    d2_troc,
    make_troc(
      model_list = all_models,
      day = 2
    ),
    cue = tar_cue(mode = "never")
  ),
  tar_target(
    d3_troc,
    make_troc(
      model_list = all_models,
      day = 3
    ),
    cue = tar_cue(mode = "never")
  ),
  tar_target(
    d4_troc,
    make_troc(
      model_list = all_models,
      day = 4
    ),
    cue = tar_cue(mode = "never")
  ),
  tar_target(
    d5_troc,
    make_troc(
      model_list = all_models,
      day = 5
    ),
    cue = tar_cue(mode = "never")
  ),
  tar_target(
    d6_troc,
    make_troc(
      model_list = all_models,
      day = 6
    ),
    cue = tar_cue(mode = "never")
  ),
  tar_target(
    d7_troc,
    make_troc(
      model_list = all_models,
      day = 7
    ),
    cue = tar_cue(mode = "never")
  ),
  tar_target(
    troc_fig,
    ggplotGrob(
      make_model_discrimination_fig(
        trocs = list(
          d1_troc,
          d2_troc,
          d3_troc,
          d4_troc,
          d5_troc,
          d6_troc,
          d7_troc
        )
      )
    )
  ),
  tar_target(
    calibration_fig,
    ggplotGrob(
      make_model_calibration_fig(
        model_list = all_models
      )
    )
  ),
  
  # save figures
  tar_target(
    troc_fig_out,
    draw_fig(
      troc_fig, 
      file.path(OUT_DIR, "fig_discrimination.jpeg"),
      height = 8, width = 20, dpi = 600
    ),
    format = "file"
  ),
  tar_target(
    calibration_fig_out,
    draw_fig(
      calibration_fig, 
      file.path(OUT_DIR, "fig_calibration.jpeg"),
      height = 7.5, width = 7.5, dpi = 600
    ),
    format = "file"
  ),

  # make tables
  tar_target(
    d_short,
    make_short_data(data = d_model)
  ),
  tar_target(
    supp_power_by_fold_table,
    get_supp_power_by_fold_table(
      data = d_short,
      all_models = all_models
    ),
    format = "file"
  ),
  tar_target(
    summary_table,
    get_summary_table(
      data = d_short
    ),
    format = "file"
  ),
  tar_target(
    model_parm_table,
    make_model_parm_table(
      data = d_model,
      final_model = final_model
    ),
    format = "file"
  ),
  tar_target(
    required_sample_size,
    calculate_req_sample_size(d_short),
    format = "file"
  )
)

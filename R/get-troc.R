make_troc <- function(model_list, day) {
  valid_df_list <- lapply(model_list, "[[", "valid")
  valid_dfs_combined <- na.omit(do.call("rbind", valid_df_list))

  with(valid_dfs_combined, ci.cvAUC(
    predictions = pred_neg_risk, # should be predicted risk (see `marker` in `survivalROC::survivalROC()`)
    tstop = tstop, # time of right-censoring/event
    predict.time = day * 24, # time point of the ROC curve
    labels = as.factor(fall),
    folds = fold
  ))
}

make_model_discrimination_fig <- function(trocs) {
  p_time_series <- make_plot_troc_series(trocs)

  troc_plots_by_day <- lapply(
    DAYS_TROC,
    \(day) make_plot_troc_day(troc = trocs[[day]], predict_day = day)
  )

  top_grid <- plot_grid(
    plotlist = c(list(p_time_series), troc_plots_by_day[1:3]),
    nrow = 1,
    labels = LETTERS[1:4]
  )

  bottom_grid <- plot_grid(
    plotlist = troc_plots_by_day[4:7],
    nrow = 1,
    labels = LETTERS[5:8]
  )

  fig <- plot_grid(top_grid, bottom_grid, nrow = 2) +
    theme(panel.background = element_rect(fill = "white", colour = "white"))
  
  fig
}

make_plot_troc_day <- function(troc, predict_day) {
  roc_data <- map(
    1:length(troc$roc_objects),
    \(x) {
      troc$roc_objects[[x]] |>
        (\(obj) data.frame(TP = obj$TP, FP = obj$FP, fold = x))() |>
        vertically_average() |>
        add_column(fold = x)
    }
  ) |>
    (\(x) do.call("rbind", x))() |>
    mutate(fold = as.factor(fold))

  roc_data_agg <-
    roc_data |>
    group_by(FP) |>
    summarize(TP = mean(TP), fold = "Combined")

  aucs <- map(
    1:length(troc$roc_objects),
    \(x) {
      data.frame(AUC = troc$roc_objects[[x]]$AUC, fold = x)
    }
  ) |>
    (\(x)do.call("rbind", x))() |>
    rbind(data.frame(AUC = troc$cvAUC, fold = "Combined")) |>
    mutate(fold_label = glue("{fold} ({format(round(AUC, 3), nsmall = 3)})"))

  roc_data_plot <-
    roc_data |>
    rbind(roc_data_agg) |>
    left_join(aucs, by = "fold")

  roc_data_plot |>
    ggplot() +
    geom_line(
      aes(FP, TP, col = fold_label, linetype = fold_label),
      linewidth = 1.2
    ) +
    scale_color_manual(
      values = c(FOLD_COLOURS, "black"),
      labels = aucs
    ) +
    scale_linetype_manual(
      values = c(rep("solid", 5), "dashed"),
      labels = aucs
    ) +
    geom_abline(linetype = "dotted") +
    theme_bw() +
    theme(panel.grid.minor = element_blank()) +
    labs(
      col = "Fold (AUC)",
      linetype = "Fold (AUC)",
      title = glue("Time-dependent ROC (Day {predict_day})"),
      x = "1 - Specificity",
      y = "Sensitivity",
      caption = glue(
        "(Internally-externally validated) AUC: {format(round(troc$cvAUC, 3), nsmall = 3)}\n",
        "(95% CI: {paste0(format(round(troc$ci, 3), nsmall = 3), collapse = ' - ')})"
      )
    ) +
    coord_equal()
}

make_plot_troc_series <- function(trocs) {
  troc_df <- lapply(
    trocs,
    (\(obj) {
      cv_roc <- data.frame(
        group = "Combined",
        auc = obj$cvAUC,
        ll = obj$ci[[1]],
        ul = obj$ci[[2]],
        predict.time = obj$roc_objects[[1]]$predict.time / 24
      )

      individual_rocs <- lapply(
        1:length(obj$roc_objects),
        \(i) {
          roc <- obj$roc_objects[[i]]
          data.frame(
            group = as.character(i),
            auc = roc$AUC,
            ll = NA_integer_,
            ul = NA_integer_,
            predict.time = roc$predict.time / 24
          )
        }
      ) |>
        (\(x) do.call("rbind", x))()

      rbind(cv_roc, individual_rocs)
    })
  ) |>
    (\(x) do.call("rbind", x))() |>
    mutate(group = factor(group, levels = c(1:5, "Combined")))

  legend_lab <- "Fold"

  troc_df |>
    ggplot(
      aes(
        x = as.factor(predict.time),
        y = auc,
        group = group,
        linetype = group,
        col = group,
        ymin = ll,
        ymax = ul
      )
    ) +
    geom_line(linewidth = 1) +
    geom_ribbon(
      data = filter(troc_df, group == "Combined"),
      alpha = 0.3,
      fill = "grey",
      col = NA,
      show.legend = FALSE
    ) +
    theme_bw() +
    scale_y_continuous(limits = c(0.4, 1), breaks = seq(0.4, 1, 0.1)) +
    labs(
      x = "Prediction time (days since admission)",
      y = "Area under the time-dependent ROC",
      group = legend_lab,
      col = legend_lab,
      linetype = legend_lab
    ) +
    scale_linetype_manual(
      values = c(rep("solid", 5), "dashed"),
      labels = levels(troc_df$group)
    ) +
    scale_color_manual(
      values = c(FOLD_COLOURS, "black"),
      labels = levels(troc_df$group)
    ) +
    scale_alpha_manual(values = c(0.4, 1)) +
    theme(
      panel.grid.minor = element_blank(),
      aspect.ratio = 1
    )
}

vertically_average <- function(dat, fp_seq = seq(0, 1, 0.001)) {
  res_df <- data.frame()
  for (fp in fp_seq) {
    res_df <- rbind(
      res_df,
      data.frame(
        FP = fp,
        TP = dat$TP[which.min(abs(dat$FP - fp))]
      )
    )
  }
  res_df
}

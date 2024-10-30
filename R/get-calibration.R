make_model_calibration_fig <- function(model_list) {
  data_list <- lapply(model_list, "[[", "valid")

  combined_data <- data.frame()

  for (dat in data_list) {
    dat$p <- log(dat$pred_exp)
    dat$logbase <- dat$p - dat$pred_lp

    calfit <- glm(
      fall ~ rms::rcs(pred_lp, 3) + offset(p),
      family = poisson,
      data = filter(dat, p != -Inf)
    )

    dat$pois <- predict(calfit, newdata = dat, type = "response")

    combined_data <- rbind(
      combined_data,
      data.frame(
        x_var = dat$pred_exp,
        y_var = dat$pois,
        fold = dat$fold
      )
    )
  }

  zoom_ecdf <- list(x = c(0, 0.015), y = c(0, 1))
  x_max <- 4
  
  p_data <- mutate(combined_data, fold = as.factor(fold)) 
  
  ecdf_ylab <- "\nEmpirical cumulative distribution function"
  
  message("making ecdf plot")
  p_ecdf <-
    p_data |>
    ggplot(aes(x_var, col = fold, group = fold)) +
    stat_ecdf(geom = "step") +
    add_labs() +
    ylab(ecdf_ylab) +
    annotate(
      "rect",
      xmin = zoom_ecdf$x[1], xmax = zoom_ecdf$x[2],
      ymin = zoom_ecdf$y[1], ymax = zoom_ecdf$y[2],
      alpha = .5, colour = "grey75", fill = "grey75"
    ) +
    scale_x_continuous(limits = c(0, x_max)) +
    scale_color_manual(
      values = FOLD_COLOURS,
      labels = 1:5
    ) +
    theme(legend.position = "bottom")

  legend <- get_legend(p_ecdf)

  p_ecdf <- p_ecdf + add_common_aesthetics()

  add_summary_rows <- function(.data, ...) {
    group_modify(.data, function(x, y) bind_rows(x, summarise(x, ...)))
  }
  p_ecdf_zoom <-
    ggplot_build(p_ecdf)$data[[1]] |>
    group_by(group) |>
    filter(x < zoom_ecdf$x[2]) |>
    add_summary_rows(y = max(y), x = zoom_ecdf$x[2]) |>
    ungroup() |>
    ggplot(
      aes(x = x, y = y, group = as.factor(group), colour = as.factor(group))
    ) +
    geom_line() +
    scale_x_continuous(limits = zoom_ecdf$x) +
    add_labs() +
    ylab(ecdf_ylab) +
    add_common_aesthetics()

  grid_ecdf <- plot_grid(p_ecdf, p_ecdf_zoom, labels = c("A", "C"), ncol = 1)

  message("making calibration plot")
  p_calibration <-
    p_data |>
    ggplot(aes(x_var, y_var, col = fold, group = fold)) +
    geom_smooth(se = FALSE) +
    geom_abline(linetype = "dashed") +
    theme_bw() +
    coord_equal() +
    add_labs() +
    add_common_aesthetics() +
    scale_x_continuous(limits = c(0, x_max)) +
    scale_y_continuous(limits = c(0, x_max))

  p_calibration_zoom <-
    p_data |>
    ggplot(aes(x_var, y_var, col = fold, group = fold)) +
    geom_smooth(se = FALSE) +
    geom_abline(linetype = "dashed") +
    theme_bw() +
    coord_equal() +
    add_labs() +
    scale_x_continuous(limits = zoom_ecdf$x) +
    scale_y_continuous(limits = zoom_ecdf$x) +
    add_common_aesthetics()

  message("combining plots")
  grid_calib <- plot_grid(
    p_calibration, p_calibration_zoom,
    labels = c("B", "D"), ncol = 1
  )

  combined_grid <- plot_grid(grid_ecdf, grid_calib, ncol = 2)

  calibration_plot <- plot_grid(
    combined_grid, legend,
    ncol = 1, rel_heights = c(1, 0.05)
  ) +
    theme(plot.background = element_rect(fill = "white", colour = NA))

  
  calibration_plot
}

add_labs <- function() {
  list(
    labs(
      x = "Cumulative hazard: Cox regression\n(predicted)",
      y = "\nCumulative hazard: Poisson regression\n(observed)",
      col = "Fold",
      group = "Fold"
    )
  )
}

add_common_aesthetics <- function() {
  list(
    theme_bw(),
    theme(
      panel.grid.minor = element_blank(),
      legend.position = "none"
    ),
    scale_color_manual(
      values = FOLD_COLOURS,
      labels = 1:5
    )
  )
}

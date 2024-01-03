get_D_from_c <- function(c) {
  # Equation (6) from DOI <10.1186/s12874-015-0078-y>
  5.5 * (c - 0.5) + 10.26 * (c - 0.5)^3
}

get_r2_from_D <- function(D,
                          sigma2 = (pi^2) / 3,
                          k = sqrt(8 / pi)) {
  # Equation (A2) from DOI <10.1002/sim.1621>
  (D^2 / k^2) / (sigma2 + (D^2) / (k^2))
}

get_r2_from_c <- function(c, ...) {
  get_r2_from_D(D = get_D_from_c(c = c), ...)
}


calculate_req_sample_size <- function(d_short) {
  d_short <- filter(d_short, fold == "All")
  falls_rate <- sum(d_short$falls_n) / nrow(d_short)
  capture.output(
    {
      x <- capture.output(pmsampsize::pmsampsize(
        type = "s",
        csrsquared = get_r2_from_c(c = 0.7),
        parameters = 28,
        rate = falls_rate,
        timepoint = 24, # primary end point as prediction at 1 day post admission
        meanfup = mean(d_short$truncated_time_end) # meanfup = mean los for data used in model (truncated)
      ))
      glue(
        "{paste0(x, collapse = '\n')}",
        "\n",
        "Mean LOS in hours (truncated): {mean(d_short$truncated_time_end)}",
        "\n",
        "Falls rate (falls per admission): {falls_rate}",
        "\n"
      )
    },
    file = file.path(OUT_DIR, "sample-size.txt")
  )
  file.path(OUT_DIR, "sample-size.txt")
}

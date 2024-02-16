draw_fig <- function(grob, filepath, ...) {
  p <- ggplotify::as.ggplot(grob)
  ggsave(plot = p, filename = filepath, ...)
  
  filepath
}

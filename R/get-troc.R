make_troc <- function(model_list, day) {
  valid_df_list <- lapply(model_list, "[[", "valid")
  
  valid_dfs_combined <- na.omit(do.call("rbind", valid_df_list))
  auc_res <- with(valid_dfs_combined, ci.cvAUC(
    predictions = pred_neg_risk, # should be predicted risk (see `marker` in `survivalROC::survivalROC()`)
    tstop = tstop, # time of right-censoring/event
    predict.time = day * 24, # time point of the ROC curve
    labels = as.factor(fall),
    folds = fold
  ))

  auc_res
}

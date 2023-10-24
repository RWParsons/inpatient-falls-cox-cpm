fit_fold_model <- function(data, formula, valid_fold) {
  train <- filter(data, fold != valid_fold)
  valid <- filter(data, fold == valid_fold)
  model <- coxph(formula, train)

  for (x_var in names(model$xlevels)) {
    # if the validation dataset has any levels of a categorical predictor that
    # weren't in the original model, reclass to "other"
    if (!all(valid[[x_var]] %in% model$xlevels[[x_var]])) {
      valid[[x_var]][!valid[[x_var]] %in% model$xlevels[[x_var]]] <- "other"
    }
  }

  withr::with_environment(env = environment(), {
    preds <- get_preds(model, valid)
  })

  list(
    model = model,
    train = train,
    valid = cbind(valid, preds)
  )
}

get_preds <- function(coxph_mod, valid_df) {
  cbind(
    pred_neg_risk = -predict(coxph_mod, type = "risk", newdata = valid_df),
    pred_lp = predict(coxph_mod, type = "lp", newdata = valid_df),
    pred_exp = predict(coxph_mod, type = "expected", newdata = valid_df)
  )
}

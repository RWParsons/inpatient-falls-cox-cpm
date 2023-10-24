ci.cvAUC <- function(predictions, # should be predicted risk (see `marker` in `survivalROC::survivalROC()`)
                     tstop, # time of right-censoring/event
                     predict.time, # time point of the ROC curve
                     labels, # labelled outcome (0/1 falls)
                     label.ordering = NULL,
                     folds = NULL,
                     confidence = 0.95,
                     use_survivalROC.C = TRUE) {
  if (use_survivalROC.C) {
    survivalROCfx <- survivalROC::survivalROC.C
  } else {
    survivalROCfx <- survivalROC::survivalROC
  }


  # Pre-process the input
  clean <- .process_input(
    predictions = predictions, labels = labels,
    tstop = tstop,
    label.ordering = label.ordering, folds = folds,
    ids = NULL, confidence = confidence
  )

  predictions <- clean$predictions # Length-V list of predicted values
  labels <- clean$labels # Length-V list of true labels
  tstop <- clean$tstop # Length-V list of true labels
  pos <- levels(labels[[1]])[[2]] # Positive class label
  neg <- levels(labels[[1]])[[1]] # Negative class label
  n_obs <- length(unlist(labels)) # Number of observations

  # Inverse probability weights across entire data set
  w1 <- 1 / (sum(unlist(labels) == pos) / n_obs) # Inverse weights for positive class
  w0 <- 1 / (sum(unlist(labels) == neg) / n_obs) # Inverse weights for negative class

  # This is required to cleanly get past R CMD CHECK
  # https://stackoverflow.com/questions/8096313/no-visible-binding-for-global-variable-note-in-r-cmd-check
  pred <- label <- NULL
  fracNegLabelsWithSmallerPreds <- fracPosLabelsWithLargerPreds <- icVal <- NULL

  .IC <- function(fold_preds, fold_labels, fold_Stime, predict.time, pos, neg, w1, w0) {
    # Applied to a single fold's (preds, labels)
    n_rows <- length(fold_labels)
    n_pos <- sum(fold_labels == pos)
    n_neg <- n_rows - n_pos

    roc_obj <- survivalROCfx(
      Stime = fold_Stime,
      status = fold_labels,
      marker = fold_preds,
      predict.time = predict.time,
      span = 0.0001 * length(fold_Stime)^(-0.20)
    )

    auc <- roc_obj$AUC

    DT <- data.table(pred = fold_preds, label = fold_labels)
    DT <- DT[order(pred, -xtfrm(label))] # Sort by asc(pred), desc(label)
    DT[, fracNegLabelsWithSmallerPreds := cumsum(label == neg) / n_neg]
    DT <- DT[order(-pred, label)]
    DT[, fracPosLabelsWithLargerPreds := cumsum(label == pos) / n_pos]
    DT[, icVal := ifelse(label == pos, w1 * (fracNegLabelsWithSmallerPreds - auc),
      w0 * (fracPosLabelsWithLargerPreds - auc)
    )]

    return(list(s = mean(DT$icVal^2), roc_obj = roc_obj))
  }

  roc_outputs <- mapply(
    FUN = .IC,
    fold_preds = predictions,
    fold_labels = labels,
    fold_Stime = tstop,
    predict.time = predict.time,
    MoreArgs = list(pos = pos, neg = neg, w1 = w1, w0 = w0)
  )

  # Estimated variance
  sighat2 <- mean(unlist(roc_outputs[1, ]))
  se <- sqrt(sighat2 / n_obs)


  n_objs <- length(roc_outputs[2, ])

  cvauc <-
    1:n_objs |>
    map(\(x) roc_outputs[2, x]$roc_obj$AUC) |>
    unlist() |>
    mean()

  z <- qnorm(confidence + (1 - confidence) / 2)
  ci_cvauc <- c(cvauc - (z * se), cvauc + (z * se))
  ci_cvauc[1] <- ifelse(ci_cvauc[1] < 0, 0, ci_cvauc[1]) # Truncate CI at [0,1]
  ci_cvauc[2] <- ifelse(ci_cvauc[2] > 1, 1, ci_cvauc[2])

  return(list(cvAUC = cvauc, se = se, ci = ci_cvauc, confidence = confidence, roc_objects = roc_outputs[2, ]))
}

.process_input <- function(predictions,
                           labels,
                           tstop,
                           label.ordering = NULL,
                           folds = NULL,
                           ids = NULL,
                           confidence = NULL) {
  .vec_to_list <- function(idxs, vec) {
    return(vec[idxs])
  }
  if (!is.null(folds)) {
    if (class(predictions) == "list" | class(labels) == "list") {
      stop("If folds is specified, then predictions and labels must both be vectors.")
    }
    if (length(predictions) != length(labels)) {
      stop("predictions and labels must be equal length")
    }
    if (is.vector(folds) && !is.list(folds)) {
      if (length(folds) != length(labels)) {
        stop("folds vector must be the same length as the predictions/labels vectors.")
      } else {
        fids <- as.list(unique(folds))
        folds <- lapply(fids, function(fid, folds) {
          which(folds == fid)
        }, folds)
      }
    } else if (!is.list(folds)) {
      stop("If specifying the folds argument, folds must be a list\n of vectors of indices that correspond to each CV fold or a vector of fold numbers\n the same size as the predictions/labels vectors.")
    } else if (length(unlist(folds)) != length(labels)) {
      stop("Number of observations in the folds argument does not equal number of predictions/labels.")
    }
    predictions <- sapply(folds, .vec_to_list, vec = predictions)
    labels <- sapply(folds, .vec_to_list, vec = labels)
    tstop <- sapply(folds, .vec_to_list, vec = tstop)
    if (length(labels) > length(unlist(labels))) {
      stop("Number of folds cannot exceed the number of observations.")
    }
  }
  if (!is.null(ids)) {
    if (is.list(ids)) {
      if (length(unlist(ids)) != length(unlist(labels))) {
        stop("ids must contain same number of observations as predictions/labels.")
      }
    } else if (is.vector(ids)) {
      if (is.null(folds)) {
        ids <- list(ids)
      } else {
        ids <- sapply(folds, .vec_to_list, vec = ids)
      }
    } else if (is.matrix(ids) | is.data.frame(ids)) {
      ids <- as.list(data.frame(ids))
    } else {
      stop("Format of ids is invalid.")
    }
    if (length(ids) > 1) {
      n_ids <- sum(sapply(ids, function(i) {
        length(unique(i))
      }))
      if (length(unique(unlist(ids))) != n_ids) {
        warning("Observations with the same id are currently spread across multiple folds.\nAll observations with the same id must be in the same fold to avoid bias.")
      }
    }
  }
  if (!is.null(confidence)) {
    if (is.numeric(confidence) && length(confidence) == 1) {
      if (confidence <= 0 | confidence >= 1) {
        stop("confidence value must fall within (0,1)")
      }
    }
  }
  return(list(
    predictions = predictions,
    labels = labels,
    tstop = tstop,
    folds = folds,
    ids = ids
  ))
}

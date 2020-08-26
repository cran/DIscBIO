#' @title Evaluating the performance of the J48 decision tree.
#' @description This function evaluates the performance of the generated trees
#'   for error estimation by ten-fold cross validation assessment.
#' @export
#' @param data The resulted data from running the function J48DT.
#' @param num.folds A numeric value of the number of folds for the cross
#'   validation assessment. Default is 10.
#' @param First A string vector showing the first target cluster.  Default is
#'   "CL1"
#' @param Second A string vector showing the second target cluster.  Default is
#'   "CL2"
#' @param quiet If `TRUE`, suppresses intermediary output
#' @importFrom stats predict
#' @return Statistics about the J48 model
J48DTeval <- function(
        data, num.folds = 10, First = "CL1", Second = "CL2", quiet = FALSE
    )
    {
        exp.imput.df <- as.data.frame(t(data))
        num.instances <- nrow(exp.imput.df)
        indices <- 1:num.instances
        classVector <- factor(colnames(data))

        cross.val <-
            function(exp.df, class.vec, segments, performance, class.algo) {
                #Start cross validation loop
                class1 <- levels(class.vec)[1]
                for (fold in 1:length(segments)) {
                    if (!quiet) message("Fold ", fold, " of ", length(segments))
                    #Define training and test set
                    test.ind <- segments[[fold]]
                    training.set <- exp.df[-test.ind, ]
                    training.class <- class.vec[-test.ind]
                    test.set <- exp.df[test.ind, , drop = FALSE]
                    test.class <- class.vec[test.ind]
                    #Train J48 on training set
                    if (class.algo == "J48") {
                        cv.model <- J48(training.class ~ ., training.set)
                        pred.class <- predict(cv.model, test.set)
                    } else if (class.algo == "rpart") {
                        cv.model <- rpart(
                            training.class ~ ., training.set, method = "class"
                        )
                        pred.class <-
                            predict(cv.model, test.set, type = "class")
                    } else{
                        stop("Unknown classification algorithm")
                    }
                    #Evaluate model on test set
                    performance <- eval.pred(
                        pred.class, test.class, class1, performance
                    )
                }
                return(performance)
            }

        cv.segments <- split(
            sample(indices), rep(1:num.folds, length = num.instances)
        )
        j48.performance <- c(
            "TP" = 0,
            "FN" = 0,
            "FP" = 0,
            "TN" = 0
        )
        j48.performance <- cross.val(
            exp.imput.df, classVector, cv.segments, j48.performance, "J48"
        )
        if (!quiet) print(j48.performance)

        j48.confusion.matrix <- matrix(j48.performance, nrow = 2)
        rownames(j48.confusion.matrix) <- c(
            paste0("Predicted", First), paste0("Predicted", Second)
        )
        colnames(j48.confusion.matrix) <- c(First, Second)
        if (!quiet) print(j48.confusion.matrix)
        j48.sn <- SN(j48.confusion.matrix)
        j48.sp <- SP(j48.confusion.matrix)
        j48.acc <- ACC(j48.confusion.matrix)
        j48.mcc <- MCC(j48.confusion.matrix)

        if (!quiet) {
            message(
                "J48 SN: ", j48.sn, "\n",
                "J48 SP: ", j48.sp, "\n",
                "J48 ACC: ", j48.acc, "\n",
                "J48 MCC: ", j48.mcc, "\n",
            )
        }
        return(j48.performance)
    }
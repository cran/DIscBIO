#' @title Generating a class vector to be used for the decision tree analysis.
#' @description This function generates a class vector for the input dataset so
#'   the decision tree analysis can be implemented afterwards.
#' @param object \code{DISCBIO} class object.
#' @param Clustering Clustering has to be one of the following: ["K-means",
#'   "MB"]. Default is "K-means"
#' @param K A numeric value of the number of clusters.
#' @param First A string vector showing the first target cluster.  Default is
#'   "CL1"
#' @param Second A string vector showing the second target cluster.  Default is
#'   "CL2"
#' @param sigDEG A data frame of the differentially expressed genes (DEGs)
#'   generated by running "DEGanalysis()" or "DEGanalysisM()".
#' @param quiet If `TRUE`, suppresses intermediary output
#' @return A data frame.
setGeneric(
  "ClassVectoringDT",
  function(object, Clustering = "K-means", K, First = "CL1", Second = "CL2",
           sigDEG, quiet = FALSE) {
    standardGeneric("ClassVectoringDT")
  }
)

#' @rdname ClassVectoringDT
#' @export
setMethod(
  "ClassVectoringDT",
  signature = "DISCBIO",
  definition = function(
    object, Clustering = "K-means", K, First = "CL1", Second = "CL2", sigDEG,
    quiet = FALSE
  ) {
    if (!(Clustering %in% c("K-means", "MB"))) {
      stop("Clustering has to be either K-means or MB")
    }
    if (length(sigDEG[, 1]) < 1) {
      stop(
        "run DEGanalysis or DEGanalysis2clust ",
        "before running ClassVectoringDT"
      )
    }

    if (Clustering == "K-means") {
      Cluster_ID <- object@cpart
    }

    if (Clustering == "MB") {
      Cluster_ID <- object@MBclusters$clusterid
    }
    Obj <- object@expdata
    SC <- DISCBIO(Obj)
    SC <- Normalizedata(SC)
    DatasetForDT <- SC@fdata
    Nam <- colnames(DatasetForDT)
    num <- 1:K
    num1 <- paste("CL", num, sep = "")
    for (n in num) {
      Nam <- ifelse((Cluster_ID == n), num1[n], Nam)
    }
    colnames(DatasetForDT) <- Nam
    chosenColumns <- which(
      colnames(DatasetForDT) == First |
        colnames(DatasetForDT) == Second
    )
    sg1 <- DatasetForDT[, chosenColumns]
    dim(sg1)
    # Creating a dataset that includes only the DEGs
    gene_list <- sigDEG[, 1]
    gene_names <- rownames(DatasetForDT)
    idx_genes <- is.element(gene_names, gene_list)
    gene_names2 <- gene_names[idx_genes]
    DEGsfilteredDataset <- sg1[gene_names2, ]
    if (!quiet) {
      message(
        "The DEGs filtered normalized dataset contains:\n",
        "Genes: ", length(DEGsfilteredDataset[, 1]), "\n",
        "cells: ", length(DEGsfilteredDataset[1, ])
      )
    }
    G_list <- sigDEG
    genes <- rownames(DEGsfilteredDataset)
    DATAforDT <- cbind(genes, DEGsfilteredDataset)

    DATAforDT <- merge(DATAforDT, G_list, by.x = "genes", by.y = "DEGsE")
    DATAforDT
    DATAforDT[, 1] <- DATAforDT[, length(DATAforDT[1, ])]
    DATAforDT <- DATAforDT[!duplicated(DATAforDT[, 1]), ]

    rownames(DATAforDT) <- DATAforDT[, 1]
    DATAforDT <- DATAforDT[, c(-1, -length(DATAforDT[1, ]))]
    sg <- factor(gsub(
      paste0("(", First, "|", Second, ").*"),
      "\\1",
      colnames(DATAforDT)
    ), levels = c(paste0(First), paste0(Second)))
    sg <- sg[!is.na(sg)]
    colnames(DATAforDT) <- sg
    return(DATAforDT)
  }
)

% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/DIscBIO-classes.R
\docType{class}
\name{DISCBIO}
\alias{DISCBIO}
\alias{DISCBIO-class,}
\alias{DISCBIO-class}
\title{The DISCBIO Class}
\arguments{
\item{object}{An DISCBIO object.}
}
\description{
The DISCBIO class is the central object storing all information
  generated throughout the pipeline.
}
\details{
DISCBIO
}
\section{Slots}{

\describe{
\item{\code{SingleCellExperiment}}{Representation of the single cell input data,
including both cells from regular and ERCC spike-in samples. Data are
stored in a SingleCellExperiment object.}

\item{\code{expdata}}{The raw expression data matrix with cells as columns and
genes as rows in sparse matrix format. It does not contain ERCC spike-ins.}

\item{\code{expdataAll}}{The raw expression data matrix with cells as columns
and genes as rows in sparse matrix format. It can contain ERCC spike-ins.}

\item{\code{ndata}}{Data with expression normalized to one for each cell.}

\item{\code{fdata}}{Filtered data with expression normalized to one for each
cell.}

\item{\code{distances}}{A distance matrix.}

\item{\code{tsne}}{A data.frame with coordinates of two-dimensional tsne layout
for the K-means clustering.}

\item{\code{background}}{A list storing the polynomial fit for the background
model of gene expression variability. It is used for outlier
identification.}

\item{\code{out}}{A list storing information on outlier cells used for the
prediction of rare cell types.}

\item{\code{cpart}}{A vector containing the final clustering partition computed
by K-means.}

\item{\code{fcol}}{A vector contaning the colour scheme for the clusters.}

\item{\code{filterpar}}{A list containing the parameters used for cell and gene
filtering based on expression.}

\item{\code{clusterpar}}{A list containing the parameters used for the K-means
clustering.}

\item{\code{outlierpar}}{A list containing the parameters used for outlier
identification.}

\item{\code{kmeans}}{A list containing the results of running the Clustexp()
function.}

\item{\code{MBclusters}}{A vector containing the final clustering partition
computed by Model-based clustering.}

\item{\code{kordering}}{A vector containing the Pseudo-time ordering based on
k-means clusters.}

\item{\code{MBordering}}{A vector containing the Pseudo-time ordering based on
Model-based clusters.}

\item{\code{MBtsne}}{A data.frame with coordinates of two-dimensional tsne
layout for the Model-based clustering.}

\item{\code{noiseF}}{A vector containing the gene list resulted from running the
noise filtering.}

\item{\code{FinalGeneList}}{A vector containing the final gene list resulted
from running the noise filtering or/and the expression filtering.}
}}

\examples{
class(valuesG1msTest)
G1_reclassified <- DISCBIO(valuesG1msTest)
class(G1_reclassified)
str(G1_reclassified, max.level = 2)
identical(G1_reclassified@expdataAll, valuesG1msTest)
}

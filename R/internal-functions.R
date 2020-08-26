#' @importFrom fpc clusterboot cluster.stats calinhara dudahart2
clustfun <- function(
	x,
	clustnr   = 20,
	bootnr    = 50,
	metric    = "pearson",
	do.gap    = TRUE,
	SE.method = "Tibs2001SEmax",
	SE.factor = .25,
	B.gap     = 50,
	cln       = 0,
	rseed     = rseed,
	quiet     = FALSE
) {
	if (clustnr < 2) stop("Choose clustnr > 1")
	di <- dist.gen(t(x), method = metric)
	if (do.gap | cln > 0) {
		gpr <- NULL
		if (do.gap) {
			set.seed(rseed)
			gpr <- clusGap(
				as.matrix(di),
				FUNcluster = kmeans,
				K.max = clustnr,
				B = B.gap,
				verbose = !quiet
			)
			if (cln == 0) {
				cln <- maxSE(
					gpr$Tab[, 3],
					gpr$Tab[, 4],
					method = SE.method,
					SE.factor
				)
			}
		}
		if (cln <= 1) {
			clb <- list(
				result   = list(partition = rep(1, dim(x)[2])),
				bootmean = 1
			)
			names(clb$result$partition) <- names(x)
			return(list(x = x, clb = clb, gpr = gpr, di = di))
		}
		clb <- clusterboot(
			di,
			B             = bootnr,
			distances     = FALSE,
			bootmethod    = "boot",
			clustermethod = KmeansCBI,
			krange        = cln,
			scaling       = FALSE,
			multipleboot  = FALSE,
			bscompare     = TRUE,
			seed          = rseed,
			count         = !quiet
		)
		return(list(x = x, clb = clb,gpr = gpr, di = di))
	}
}

Kmeansruns <- function (
	data,
	krange    = 2: 10,
	criterion = "ch",
	iter.max  = 100,
	runs      = 100,
	scaledata = FALSE,
	alpha     = 0.001,
	critout   = FALSE,
	plot      = FALSE,
	method    = "euclidean",
	...
) {
	data <- as.matrix(data)
	if (criterion == "asw") sdata <- dist(data)
	if (scaledata) data <- scale(data)
	cluster1 <- 1 %in% krange
	crit <- numeric(max(krange))
	km <- list()
	for (k in krange) {
		if (k > 1) {
			minSS <- Inf
			kmopt <- NULL
			for (i in 1:runs) {
				opar <- options(show.error.messages = FALSE)
				on.exit(options(opar))
				repeat {
					kmm <- try(kmeans(data, k))
					if (!is(kmm, "try-error")) break
				}
				opar <- options(show.error.messages = TRUE)
				on.exit(options(opar))
				swss <- sum(kmm$withinss)
				if (swss < minSS) {
					kmopt <- kmm
					minSS <- swss
				}
				if (plot) {
					opar <- par(ask = TRUE)
					on.exit(par(opar))
					pairs(data, col = kmm$cluster, main = swss)
				}
			}
			km[[k]] <- kmopt
			crit[k] <- switch(
				criterion,
				asw = cluster.stats(sdata, km[[k]]$cluster)$avg.silwidth,
				ch  = calinhara(data, km[[k]]$cluster)
			)
			if (critout) {
				message(k, " clusters ", crit[k], "\n")
			}
		}
	}
	if (cluster1) {
		cluster1 <- dudahart2( data, km[[2]]$cluster, alpha = alpha)$cluster1
	}
	k.best <- which.max(crit)
	if (cluster1) k.best <- 1
	km[[k.best]]$crit <- crit
	km[[k.best]]$bestk <- k.best
	out <- km[[k.best]]
	return(out)
}

KmeansCBI <- function (data,
	krange,
	k = NULL,
	scaling = FALSE,
	runs = 1,
	criterion = "ch",
	method = "euclidean",
	...
) {
	if (!is.null(k)) krange <- k
	if (!identical(scaling, FALSE)) {
		sdata <- scale(data, center = TRUE, scale = scaling)
	} else {
		sdata <- data
	}
	c1 <- Kmeansruns(
		sdata,
		krange,
		runs = runs,
		criterion = criterion,
		method = method,
		...
	)
	partition <- c1$cluster
	cl <- list()
	nc <- krange
	for (i in 1:nc) cl[[i]] <- partition == i
	out <- list(
		result = c1,
		nc = nc,
		clusterlist = cl,
		partition = partition,
		clustermethod = "kmeans"
	)
	return(out)
}

dist.gen <- function(x, method = "euclidean") {
	if (method %in% c("spearman", "pearson", "kendall")) {
		as.dist(1 - cor(t(x), method = method))
	} else {
		dist(x, method = method)
	}
}

binompval <- function(p, N, n) {
	pval   <- pbinom(n, round(N, 0), p, lower.tail = TRUE)
	filter <- !is.na(pval) & pval > 0.5
	pval[filter] <- 1 - pval[filter]
	return(pval)
}

add_legend <- function(...) {
	opar <- par(
		fig = c(0, 1, 0, 1),
		oma = c(0, 0, 0, 0),
		mar = c(0, 0, 0, 0),
		new = TRUE
	)
	on.exit(par(opar))
	plot(
		x    = 0,
		y    = 0,
		type = 'n',
		bty  = 'n',
		xaxt = 'n',
		yaxt =  'n'
	)
	legend(...)
}

downsample <- function(x, n, dsn) {
	x <- round(x[, apply(x, 2, sum, na.rm = TRUE) >= n], 0)
	nn <- min(apply(x, 2, sum))
	for (j in 1:dsn) {
		z  <- data.frame(GENEID = rownames(x))
		rownames(z) <- rownames(x)
		initv <- rep(0, nrow(z))
		for (i in 1:dim(x)[2]) {
			y <- aggregate(
				rep(1, nn), list(sample(
					rep(rownames(x), x[, i]), nn
				)),
				sum
			)
			na <- names(x)[i]
			names(y) <- c("GENEID", na)
			rownames(y) <- y$GENEID
			z[, na] <- initv
			k <- intersect(rownames(z), y$GENEID)
			z[k, na] <- y[k, na]
			z[is.na(z[, na]), na] <- 0
		}
		rownames(z) <- as.vector(z$GENEID)
		ds <- if (j == 1) z[, -1] else ds + z[, -1]
	}
	ds <- ds / dsn + .1
	return(ds)
}

eval.pred <- function(pred.class, true.class, class1, performance) {
	for (index in 1:length(pred.class)) {
		pred <- pred.class[index]
		true <- true.class[index]
		if (pred == true && true == class1) {
			performance["TP"] <- performance["TP"] + 1
		} else if (pred != true && true == class1) {
			performance["FN"] <- performance["FN"] + 1
		} else if (pred != true && true != class1) {
			performance["FP"] <- performance["FP"] + 1
		} else if (pred == true && true != class1) {
			performance["TN"] <- performance["TN"] + 1
		}
	}
	return(performance)
}

SN <- function(con.mat) {
	TP <- con.mat[1, 1]
	FN <- con.mat[2, 1]
	return(TP / (TP + FN))
}

SP <- function(con.mat) {
	TN <- con.mat[2, 2]
	FP <- con.mat[1, 2]
	return(TN / (TN + FP))
}

ACC <- function(con.mat) {
	TP <- con.mat[1, 1]
	FN <- con.mat[2, 1]
	TN <- con.mat[2, 2]
	FP <- con.mat[1, 2]
	return((TP + TN) / (TP + FN + TN + FP))
}

MCC <- function(con.mat) {
	TP <- con.mat[1, 1]
	FN <- con.mat[2, 1]
	TN <- con.mat[2, 2]
	FP <- con.mat[1, 2]
	denom <- sqrt((TP + FP) * (TP + FN) * (TN + FP) * (TN + FN))
	denom <- ifelse(denom == 0, NA, denom)
	return((TP * TN - FP * FN) / denom)
}
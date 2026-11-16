# Shared pieces of the status x achievement models (steps 17 and 19), so that both use the same groups, sample and estimator.
# Groups (PISA 2025 definition): national status quarter (sesq) x national achievement quarter, the achievement quarter re-derived
# per plausible value and replicate with the boundary rule of every step: bottom = y <= 25th percentile, top = y >= 75th, middle split
# at the median. S4A4 (advantaged top achievers) is the omitted cell.
CELLS <- as.vector(outer(paste0("S", 1:4), paste0("A", 1:4), paste0)); EST <- setdiff(CELLS, "S4A4")
CORNERS <- c("S1A4", "S1A1", "S4A1", "S4A4")
DEMO <- c("female", "AGE", "g_m1", "g_p1")
SKMI <- c(paste0(SE6, "_z"), "growth", "EFFSCIE_z", "JOYSCIE_z")      # six skills, growth mindset, science self-efficacy and enjoyment
REL  <- paste0(CTX, "_z")                                             # belonging, bullying, family support, feeling safe
CON  <- c(`R-AT` = "S1A4", `R-PL` = "S1A1", `R-AL` = "S4A1")          # contrast -> cell subtracted from S1A4 (R-AT: nothing)
NA_EST <- setNames(rep(NA_real_, length(EST)), EST)

# cell of every student for achievement y and weight w
mx_cell <- function(s, y, w) {
  q <- wquant(y, w, c(.25, .5, .75))
  aq <- fifelse(y <= q[1], 1L, fifelse(y >= q[3], 4L, fifelse(y <= q[2], 2L, 3L)))
  fifelse(is.na(s$sesq) | is.na(aq), NA_character_, paste0("S", s$sesq, "A", aq))
}
mx_dummies <- function(cell) { D <- sapply(EST, function(k) as.integer(cell %in% k)); colnames(D) <- EST; D }
# the common sample of the models: cell, life satisfaction, school ID and every control the system fielded observed
mx_controls <- function(s) list(demo = avail(s, DEMO), skmi = avail(s, SKMI), rel = avail(s, REL))
mx_keep <- function(s, cell, ct) !is.na(cell) & !is.na(s$LS) & !is.na(s$CNTSCHID) & complete.cases(s[, c(ct$demo, ct$skmi, ct$rel), with = FALSE])

# weighted least squares on the rows in keep; Y may be a matrix (one column per outcome); returns coefficients (rows = columns of X)
wls <- function(Y, X, w, keep, g = NULL) {
  Y <- as.matrix(Y)[keep, , drop = FALSE]; X <- as.matrix(X)[keep, , drop = FALSE]; w <- w[keep]
  ok <- w > 0 & !is.na(w); Y <- Y[ok, , drop = FALSE]; X <- X[ok, , drop = FALSE]; w <- w[ok]
  if (!is.null(g)) { Z <- demean(cbind(Y, X), g[keep][ok], w); Y <- Z[, seq_len(ncol(Y)), drop = FALSE]; X <- Z[, -seq_len(ncol(Y)), drop = FALSE] }
  else X <- cbind(`(Intercept)` = 1, X)
  X <- X[, apply(X, 2, function(v) var(v) > 1e-12) | colnames(X) == "(Intercept)", drop = FALSE]
  b <- lm.wfit(X, Y, w)$coefficients; as.matrix(b)
}
pick <- function(b, rows, col = 1) { out <- setNames(rep(NA_real_, length(rows)), rows); i <- intersect(rows, rownames(b)); out[i] <- b[i, col]; out }
# the three contrasts of resilient students from a vector of cell coefficients
mx_contrasts <- function(b) c(`R-AT` = b[["S1A4"]], `R-PL` = b[["S1A4"]] - b[["S1A1"]], `R-AL` = b[["S1A4"]] - b[["S4A1"]])

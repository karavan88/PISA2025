# School Inputs & the Grade Gain -- what does the strongest input carry? Gelbach (2016) decomposition on the causal-forest scores.
# Outcome: the doubly robust score of the grade gain, Gamma_i (its conditional mean is gamma(x); 04_forest.R), same-school systems.
#   base : Gamma = a_s + b_base * T                         (T = TOP, default s_SAFE; a_s = system fixed effects)
#   full : Gamma = a_s + b_full * T + sum_k beta_k X_k      (X_k = every other school input; missing -> 0 with flags)
#   aux  : X_k   = c_s + delta_k * T                        (how each input co-moves with T)
#   b_base - b_full = sum_k delta_k * beta_k  : the part of T's moderation that runs through (or is confounded by) each input; grouped by
#   input family (resources, teachers, organisation, other climate, peers, missing-data flags). What remains (b_full) is the part no other
#   observed input accounts for. Inference: school-cluster bootstrap within each PV, Rubin across PVs. Env: TOP, B (200).
# Output: 03_outputs/schoolgain/decomp.csv (by input and by group), decomp_delta.csv (what predicts T)
suppressPackageStartupMessages({ library(data.table) })
source("02_scripts/schoolgain/00_helpers.R")
TOP <- Sys.getenv("TOP", "s_SAFE"); B <- as.integer(Sys.getenv("B", "200"))
fs <- readRDS(og("forest_scores.rds"))
inp <- fs$inputs; ok <- !is.na(inp[, TOP])
Tv <- inp[ok, TOP]; Xo <- inp[ok, setdiff(colnames(inp), TOP), drop = FALSE]
mis <- is.na(Xo); Xo[mis] <- 0; fl <- mis[, colMeans(mis) > 0.02, drop = FALSE]; colnames(fl) <- paste0("mis_", colnames(fl))
Xk <- cbind(Xo, fl); grp <- c(in_grp(colnames(Xo)), rep("Missing-data flags", ncol(fl))); grp[colnames(Xk) %in% c("s_DISC", "s_TSUP", "s_COGA", "s_BULL", "s_SAFE", "NEGSCLIM")] <- "Other climate"
FE <- model.matrix(~ factor(fs$CNT[ok]))
w <- fs$w[ok]; cl <- fs$school[ok]; S <- fs$scores[ok, , drop = FALSE]
gelbach <- function(idx, y) {
  W <- w[idx]; F <- FE[idx, , drop = FALSE]; t <- Tv[idx]; X <- Xk[idx, , drop = FALSE]; yy <- y[idx]
  bb <- lm.wfit(cbind(F, t), yy, W)$coefficients; b_base <- unname(bb[length(bb)])
  bf <- lm.wfit(cbind(F, t, X), yy, W)$coefficients; bf[is.na(bf)] <- 0; b_full <- unname(bf[ncol(F) + 1]); beta <- bf[(ncol(F) + 2):length(bf)]
  dl <- lm.wfit(cbind(F, t), X, W)$coefficients; delta <- dl[nrow(dl), ]; delta[is.na(delta)] <- 0
  c(b_base = b_base, b_full = b_full, setNames(delta * beta, paste0("c:", colnames(Xk))), setNames(delta, paste0("d:", colnames(Xk))))
}
res <- list()
cls <- unique(cl); rows_by_cl <- split(seq_along(cl), cl)
for (k in seq_len(ncol(S))) {
  y <- S[, k]; set.seed(3000 + k)
  pt <- gelbach(seq_along(y), y)
  bs <- t(replicate(B, { s <- sample(cls, replace = TRUE); gelbach(unlist(rows_by_cl[as.character(s)], use.names = FALSE), y) }))
  res[[k]] <- data.table(pv = k, term = names(pt), est = pt, se = apply(bs, 2, sd))
  log_step("PV", k, "done")
}
res <- rubin(rbindlist(res), "term")
# group totals (bootstrap SE of a sum approximated from the per-PV draws would need the draws; report the sum and the root-sum-square bound)
ct <- res[term %like% "^c:"][, var := sub("^c:", "", term)][, group := grp[match(var, colnames(Xk))]]
gt <- ct[, .(est = sum(est), se_upper = sqrt(sum(se^2))), by = group]
out <- rbind(res[term %in% c("b_base", "b_full"), .(level = "total", term, group = NA_character_, est, se)],
             ct[, .(level = "input", term = var, group, est, se)], gt[, .(level = "group", term = group, group, est, se = se_upper)], fill = TRUE)
out[, top := TOP]
fwrite(out, og("decomp.csv"))
fwrite(res[term %like% "^d:"][, .(input = sub("^d:", "", term), delta = est, se)][, top := TOP], og("decomp_delta.csv"))
print(out[level != "input"]); print(out[level == "input"][order(-abs(est))][1:10])

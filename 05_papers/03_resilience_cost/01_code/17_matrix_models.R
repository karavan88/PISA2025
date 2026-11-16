# The Cost of Resilience -- step 17: nested models on the status x achievement matrix (author's design, 15 November 2026, revised
# the same evening: school fixed effects from M2 on, and M6 = M5 without them).
# Groups as in step 16 (PISA 2025 definition): national status quarter (sesq) x national achievement quarter (reading by default;
# PAPER_ACH=SCIE for the robustness check), re-derived per plausible value and replicate. One regression per model on all students
# with 15 cell indicators; the omitted cell is S4A4, advantaged top achievers.
# Six models, all on the same students (observed on every control the system fielded) and the same systems (those with school IDs):
#   M1  cells only (weighted least squares)
#   M2  M1 + school fixed effects
#   M3  M2 + sex, age, grade (below / above the modal grade)
#   M4  M3 + six socio-emotional skills, growth mindset, science self-efficacy, enjoyment of science
#   M5  M4 + belonging, bullying, family support, feeling safe
#   M6  M5 without school fixed effects (the between-school part once every control is held fixed)
# A control a system did not field (< 50% observed) is left out in that system only (avail()).
# Terms, for the outcome in within-system SD (z) and in 0-10 points (pt):
#   mm:<y>:M#:S#A#   coefficient of each cell against S4A4 (S1A4 = resilient minus advantaged top achievers)
#   mm:<y>:M#:R-PL   S1A4 - S1A1, resilient minus disadvantaged low achievers
#   mm:<y>:M#:R-AL   S1A4 - S4A1, resilient minus advantaged low achievers
#   mm:<y>:M#:DiD    (S1A4 - S1A1) - (S4A4 - S4A1): how much larger the achievement gap is among disadvantaged than advantaged students
#   mm:<y>:M#:R-PO   resilient minus the other disadvantaged students (S1A1, S1A2, S1A3), i.e. S1A4 minus the average of the three
#                    coefficients weighted by each cell's share of those students in the model sample (added 15 November 2026, night)
#   mm:<y>:M#:DiD2   (R - other disadvantaged) - (S4A4 - other advantaged, S4A1-S4A3 weighted the same way): the achievement gap
#                    over all achievement levels, disadvantaged minus advantaged (the broad version of the RQ3 test)
# Gelbach (2016) decomposition of the change from M3 to M5 (within school, outcome in SD), for the contrasts R-AT (= S1A4), R-PL, R-AL, R-PO:
#   gel:<contrast>:<variable>   contribution of each skill, mindset and relationship variable (Gamma_k * beta_k)
#   gel:<contrast>:SKMI / REL / total   block sums; total equals M3 minus M5 for the contrast exactly. For a negative gap, a negative
#                                       contribution means the variable accounts for part of it, a positive one that it masks part of it.
#   n:S#A#           unweighted students per cell in the model sample (mean over plausible values)
# Every difference and contribution is computed inside each plausible value and replicate, so its standard error accounts for the
# shared reference cell. Systems without school IDs, or with fewer than MIN_CELL students in a corner cell, are dropped (logged).
# Output: mxmod_sys.csv, mxmod_pool.csv
source("05_papers/03_resilience_cost/01_code/00_helpers.R")
d <- load_rw()
d[, `:=`(g_m1 = as.integer(GRADE < 0), g_p1 = as.integer(GRADE > 0))]
source("05_papers/03_resilience_cost/01_code/matrix_helpers.R")   # CELLS, EST, CORNERS, DEMO, SKMI, REL, CON, wls(), pick(), ...

stat_mm <- function(s, y, w) {
  cell <- mx_cell(s, y, w); D <- mx_dummies(cell)
  ct <- mx_controls(s); demo <- ct$demo; skmi <- ct$skmi; rel <- ct$rel; K <- c(skmi, rel)
  C3 <- as.matrix(s[, ..demo]); CK <- as.matrix(s[, ..K])
  keep <- mx_keep(s, cell, ct)                                               # the common sample of the six models
  g <- s$CNTSCHID
  fit <- function(Y, X, fe) tryCatch(wls(Y, X, w, keep, if (fe) g else NULL), error = function(e) NULL)
  out <- c()
  # weights of the other disadvantaged / other advantaged cells: shares in the model sample with the weight in use
  sh <- function(ks) { v <- vapply(ks, function(k) sum(w[keep & cell %in% k]), 0); v / sum(v) }
  wPO <- sh(c("S1A1", "S1A2", "S1A3")); wAO <- sh(c("S4A1", "S4A2", "S4A3"))
  csum <- function(v, b) { i <- v != 0; sum(v[i] * b[names(v)[i]]) }       # contrast from coefficients; cells with weight 0 are ignored
  cv <- function(...) { v <- setNames(rep(0, length(EST)), EST); a <- c(...); v[names(a)] <- a; v }   # contrast = sum(cv * coefficients)
  CV <- list(`R-AT` = cv(S1A4 = 1), `R-PL` = cv(S1A4 = 1, S1A1 = -1), `R-AL` = cv(S1A4 = 1, S4A1 = -1),
             `R-PO` = cv(S1A4 = 1, setNames(-wPO, c("S1A1", "S1A2", "S1A3"))),
             DiD2 = cv(S1A4 = 1, setNames(-wPO, c("S1A1", "S1A2", "S1A3")), setNames(wAO, c("S4A1", "S4A2", "S4A3"))))
  for (yn in c("z", "pt")) {
    yv <- if (yn == "z") s$LS_z else s$LS
    f5 <- fit(yv, cbind(D, C3, CK), TRUE); f3 <- fit(yv, cbind(D, C3), TRUE)
    M <- list(M1 = fit(yv, D, FALSE), M2 = fit(yv, D, TRUE), M3 = f3,
              M4 = fit(yv, cbind(D, C3, as.matrix(s[, ..skmi])), TRUE), M5 = f5, M6 = fit(yv, cbind(D, C3, CK), FALSE))
    for (m in names(M)) {
      b <- if (is.null(M[[m]])) NA_EST else pick(M[[m]], EST)
      out[paste0("mm:", yn, ":", m, ":", EST)] <- b
      out[paste0("mm:", yn, ":", m, ":R-PL")] <- b[["S1A4"]] - b[["S1A1"]]
      out[paste0("mm:", yn, ":", m, ":R-AL")] <- b[["S1A4"]] - b[["S4A1"]]
      out[paste0("mm:", yn, ":", m, ":DiD")]  <- b[["S1A4"]] - b[["S1A1"]] + b[["S4A1"]]
      out[paste0("mm:", yn, ":", m, ":R-PO")] <- csum(CV[["R-PO"]], b)
      out[paste0("mm:", yn, ":", m, ":DiD2")] <- csum(CV[["DiD2"]], b)
    }
    if (yn == "z") {                                                          # Gelbach: M3 -> M5, within school
      bk <- if (is.null(f5)) setNames(rep(NA_real_, length(K)), K) else pick(f5, K)
      G <- fit(CK, cbind(D, C3), TRUE)                                        # each control on the cells and demographics
      for (cn in c(names(CON), "R-PO")) {
        gam <- if (is.null(G)) setNames(rep(NA_real_, length(K)), K) else
          sapply(seq_along(K), function(j) csum(CV[[cn]], pick(G, EST, j)))
        ctb <- setNames(gam * bk, K); ctb[is.na(bk) & !is.na(gam)] <- 0        # a control dropped for lack of variance contributes nothing
        out[paste0("gel:", cn, ":", c(SKMI, REL))] <- ctb[c(SKMI, REL)]
        out[paste0("gel:", cn, ":SKMI")]  <- sum(ctb[skmi])
        out[paste0("gel:", cn, ":REL")]   <- sum(ctb[rel])
        out[paste0("gel:", cn, ":total")] <- sum(ctb)
      }
    }
  }
  for (k in CELLS) out[paste0("n:", k)] <- sum(keep & cell %in% k)
  out
}

SYS <- unique(d$CNT); if (nzchar(Sys.getenv("PAPER_TEST_SYSTEMS"))) SYS <- intersect(SYS, strsplit(Sys.getenv("PAPER_TEST_SYSTEMS"), " ")[[1]])   # testing only
noid <- d[CNT %in% SYS, .(ok = mean(!is.na(CNTSCHID)) > .5), by = CNT][ok == FALSE, CNT]
log_step("systems without school IDs (dropped):", paste(noid, collapse = " "))
SYS <- setdiff(SYS, noid)
log_step("matrix models (", ACH_DOMAIN, ") on", length(SYS), "systems")
res <- run_systems(d, stat_mm, systems = SYS)
small <- res[term %in% paste0("n:", CORNERS) & est < MIN_CELL, unique(CNT)]
log_step("systems below", MIN_CELL, "students in a corner cell:", paste(small, collapse = " "))
res <- res[!CNT %in% small]
fwrite(res, orr("mxmod_sys.csv"))
pl <- pool_by(res[!grepl("^n:", term) & !is.na(est) & !is.na(se) & se > 0], "term")
fwrite(pl, orr("mxmod_pool.csv"))
log_step("done:", uniqueN(res$CNT), "systems")
print(pl[grepl("^mm:z:M[1-6]:(S1A4|S1A1|S4A1|R-PL|R-AL|R-PO|DiD|DiD2)$|^gel:R-(AT|PL|PO):(SKMI|REL|total)$", term), .(term, n_sys, re = round(re_mean, 3), se = round(re_se, 3), n_neg, sig_neg, sig_pos)])

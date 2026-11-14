# sestransmit -- per-system estimation of how much of the socio-economic gradient in achievement runs through socio-emotional skills.
#
# For system c, exposure T (ESCS percentile rank / 10), mediators M_1..M_K, controls X, outcome Y (plausible value m):
#   total gradient        Y = a + beta_tot T + X'g + e
#   SES gap in skill k    M_k = a + pi_k T + X'g + u_k
#   single-mediator model Y = a + beta T + b_k M_k + X'g + v       ACME_k = pi_k * b_k  (Imai-Keele-Tingley, linear SEM: exact)
#   joint model           Y = a + beta_dir T + sum gamma_k M_k + X'g    joint = beta_tot - beta_dir = sum pi_k gamma_k (Gelbach)
#   sensitivity           rho*_k = corr(u_k, e): the error correlation at which ACME_k = 0 (Imai, Keele & Yamamoto 2010, LSEM)
# All quantities come from the weighted cross-product matrix of [1, X, T, M, PV1..PV10] via Frisch-Waugh-Lovell, so every statistic is
# computed for the final weight and each of the 80 Fay BRR replicate weights on all ten plausible values.
# Variance: sampling = mean over PVs of sum_r (theta_mr - theta_m)^2 / 20; imputation = (1 + 1/10) var_m(theta_m); SE = sqrt(sum).
# Usage: Rscript 02_scripts/sestransmit/03_estimate.R        (writes 03_outputs/sestransmit/tables/estimates_long.csv)
source("02_scripts/sestransmit/00_helpers.R")
a <- readRDS("01_data/derived/sestransmit_analytic.rds"); med_list <- attr(a, "med_list")
NCORES <- as.integer(Sys.getenv("ST_CORES", "6"))

est_unit <- function(dt, meds, tvar, ctrl, dom, wmult = NULL) {
  pvs <- paste0("PV", 1:10, dom); K <- length(meds)
  X <- cbind(1, as.matrix(dt[, ..ctrl]))
  X <- X[, c(TRUE, apply(X[, -1, drop = FALSE], 2, function(z) var(z) > 0)), drop = FALSE]
  q <- qr(X); X <- X[, sort(q$pivot[seq_len(q$rank)]), drop = FALSE]
  A <- cbind(X, dt[[tvar]]); nA <- ncol(A)
  Z <- cbind(A, as.matrix(dt[, ..meds]), as.matrix(dt[, ..pvs]))
  W <- cbind(dt$W_FSTUWT, as.matrix(dt[, ..RW])); if (!is.null(wmult)) W <- W * wmult
  iM <- seq_len(K); iY <- K + 1:10
  one_w <- function(w) {
    G <- crossprod(Z, Z * w); GAA <- G[1:nA, 1:nA]; GAB <- G[1:nA, -(1:nA), drop = FALSE]
    C <- solve(GAA, GAB); S <- G[-(1:nA), -(1:nA), drop = FALSE] - crossprod(GAB, C)
    pi <- C[nA, iM]; btot <- C[nA, iY]
    SMM <- S[iM, iM, drop = FALSE]; SMY <- S[iM, iY, drop = FALSE]
    gam <- solve(SMM, SMY); delta <- pi * gam; joint <- colSums(delta)
    b <- SMY / diag(SMM); acme <- pi * b
    rho <- SMY / sqrt(outer(diag(SMM), diag(S)[iY]))
    rbind(beta_tot = btot, beta_dir = btot - joint, joint = joint, joint_share = joint / btot,
          `rownames<-`(matrix(pi, K, 10), paste0("pi_", meds)), `rownames<-`(gam, paste0("gamma_", meds)),
          `rownames<-`(delta, paste0("delta_", meds)), `rownames<-`(sweep(delta, 2, btot, "/"), paste0("dshare_", meds)),
          `rownames<-`(b, paste0("b_", meds)), `rownames<-`(acme, paste0("acme_", meds)),
          `rownames<-`(sweep(acme, 2, btot, "/"), paste0("ashare_", meds)), `rownames<-`(rho, paste0("rho_", meds)))
  }
  th0 <- one_w(W[, 1])
  vs <- Reduce(`+`, lapply(2:81, function(r) (one_w(W[, r]) - th0)^2)) / 20
  data.table(stat = rownames(th0), est = rowMeans(th0), se_samp = sqrt(rowMeans(vs)), se_imp = sqrt(1.1 * apply(th0, 1, var)))[
    , se := sqrt(se_samp^2 + se_imp^2)][]
}

ctrl_for <- function(spec) {
  base <- c(stu_ctrl, paste0(stu_ctrl, "_mis"))
  if (spec == "school") c(base, sch_ctrl, "sch_pct_loo_mis", "private_mis", "urban_mis") else base
}

run_one <- function(c, run, dom, spec, tvar = "ESCS_pct10", meds = NULL, ipw = FALSE) {
  dt <- a[CNT == c]; if (is.na(dt[[paste0("PV1", dom)]][1])) return(NULL)
  if (spec == "school" && !all(dt$has_school)) return(NULL)
  meds <- if (is.null(meds)) med_list[[c]] else meds
  if (!all(meds %in% med_list[[c]]) || !length(meds)) return(NULL)
  wm <- NULL
  if (ipw) { s <- readRDS("01_data/derived/sestransmit_selection.rds")[CNT == c]
    f <- as.formula(paste("complete ~ ESCS_pct10 + PV1SCIE +", paste(c(stu_ctrl, paste0(stu_ctrl, "_mis")), collapse = "+")))
    s <- s[!is.na(ESCS_pct10)]; p <- suppressWarnings(fitted(glm(f, data = s, family = quasibinomial(), weights = W_FSTUWT / mean(W_FSTUWT))))
    s[, p := pmax(p, 0.05)]; wm <- 1 / s[match(dt$CNTSTUID, CNTSTUID), p] }
  r <- tryCatch(est_unit(dt, meds, tvar, ctrl_for(spec), dom, wm), error = function(e) { message(c, " ", run, " ", conditionMessage(e)); NULL })
  if (is.null(r)) return(NULL)
  r[, `:=`(CNT = c, economy = dt$economy[1], OECD = dt$OECD[1], run = run, domain = dom, spec = spec, N = nrow(dt), n_med = length(meds))]
}

jobs <- rbind(
  CJ(run = "main", dom = c("SCIE", "READ", "MATH"), spec = c("student", "school"), CNT = sort(unique(a$CNT))),
  CJ(run = "escs_index", dom = "SCIE", spec = c("student", "school"), CNT = sort(unique(a$CNT))),
  CJ(run = "core5", dom = "SCIE", spec = c("student", "school"), CNT = sort(unique(a$CNT))),
  CJ(run = "ipw", dom = "SCIE", spec = c("student", "school"), CNT = sort(unique(a$CNT))))
t0 <- Sys.time()
res <- parallel::mclapply(seq_len(nrow(jobs)), function(i) { j <- jobs[i]
  run_one(j$CNT, j$run, j$dom, j$spec,
          tvar = if (j$run == "escs_index") "ESCS" else "ESCS_pct10",
          meds = if (j$run == "core5") c("CURIO", "ENPROBS", "COGABIL", "GOALSET", "SELFREG") else NULL,
          ipw = j$run == "ipw") }, mc.cores = NCORES, mc.preschedule = TRUE)
R <- rbindlist(res)
R[, mediator := fifelse(grepl("_", stat), sub("^[a-z]+_", "", stat), NA_character_)]
R[stat %in% c("beta_tot", "beta_dir", "joint", "joint_share"), mediator := NA]
R[, quantity := fifelse(is.na(mediator), stat, sub("_.*$", "", stat))]
fwrite(R, tp("estimates_long.csv"))
cat("rows:", nrow(R), " units:", uniqueN(R[, .(CNT, run, domain, spec)]), " minutes:", round(as.numeric(Sys.time() - t0, units = "mins"), 1), "\n")

# sestransmit -- manuscript tables (CSV, read by the Quarto file). Reads estimates_long.csv and audit files.
source("02_scripts/sestransmit/00_helpers.R")
R <- apply_tmin(fread(tp("estimates_long.csv"), encoding = "UTF-8")); cov <- fread(ap("sample_coverage.csv"), encoding = "UTF-8")
R[, grp := ifelse(OECD == 1, "OECD", "Partner")]
q <- function(x, p) quantile(x, p, na.rm = TRUE)
summ <- function(x) sprintf("%.1f [%.1f, %.1f]", median(x, na.rm = TRUE), q(x, .25), q(x, .75))

# Table 1 (appendix): sample
t1 <- cov[order(-OECD, economy), .(System = economy, Group = ifelse(OECD == 1, "OECD", "Partner"), `N (PUF)` = N_all, `N analytic` = N_analytic,
                                      `Share` = round(share, 2), `Scales` = n_med, `Mean science, all` = round(sci_all), `Mean science, analytic` = round(sci_analytic))]
fwrite(t1, tp("t1_sample.csv"))

# Table 2: headline by domain and specification; medians and IQR across systems
w <- dcast(R[run == "main" & stat %in% c("beta_tot", "beta_dir", "joint", "joint_share")], CNT + economy + grp + domain + spec + N ~ stat, value.var = c("est", "se"))
t2 <- w[, .(Systems = .N, `Gradient without skills` = summ(est_beta_tot), `Gradient with skills` = summ(est_beta_dir),
            `Difference (joint indirect)` = summ(est_joint), `Share (%)` = summ(100 * est_joint_share),
            `Share > 10%` = sprintf("%d of %d", sum(est_joint_share > .10, na.rm = TRUE), sum(!is.na(est_joint_share))), `Significant at 5%` = sprintf("%d of %d", sum(abs(est_joint / se_joint) > 1.96), .N)),
        by = .(Domain = factor(domain, c("SCIE", "READ", "MATH"), c("Science", "Reading", "Mathematics")), Specification = factor(spec, c("student", "school"), c("Total", "Within-school")))][order(Domain, Specification)]
fwrite(t2, tp("t2_headline.csv"))

# Table 3: mediator by mediator (science, total)
m <- R[run == "main" & domain == "SCIE" & spec == "student" & mediator != ""]
m3 <- dcast(m, CNT + mediator ~ quantity, value.var = c("est", "se"))
t3 <- m3[, .(Systems = .N, `SES gap, P10-P90 (SD)` = summ(P10P90 * est_pi), `Return (points/SD)` = summ(est_b), `ACME, P10-P90 (points)` = summ(P10P90 * est_acme),
             `Share, single (%)` = summ(100 * est_ashare), `Share, conditional (%)` = summ(100 * est_dshare), `rho*` = sprintf("%.2f [%.2f, %.2f]", median(est_rho), q(est_rho, .25), q(est_rho, .75)),
             `ACME significant` = sprintf("%d", sum(abs(est_acme / se_acme) > 1.96))), by = .(Skill = factor(skill_lab[mediator], skill_lab))][order(Skill)]
fwrite(t3, tp("t3_mediators.csv"))

# Table 4 (appendix): every system, science
s <- w[domain == "SCIE"]
t4 <- dcast(s, economy + grp ~ spec, value.var = c("N", "est_beta_tot", "se_beta_tot", "est_joint", "se_joint", "est_joint_share"))
t4 <- merge(t4, cov[, .(economy, n_med)], by = "economy")[order(-est_joint_share_student)]
t4o <- t4[, .(System = economy, Group = grp, N = N_student, Scales = n_med,
              `Gradient (total)` = sprintf("%.1f (%.2f)", est_beta_tot_student, se_beta_tot_student), `Indirect (total)` = sprintf("%.2f (%.2f)", est_joint_student, se_joint_student),
              `Share (total), %` = sprintf("%.1f", 100 * est_joint_share_student),
              `Gradient (within)` = ifelse(is.na(est_beta_tot_school), "", sprintf("%.1f (%.2f)", est_beta_tot_school, se_beta_tot_school)),
              `Indirect (within)` = ifelse(is.na(est_joint_school), "", sprintf("%.2f (%.2f)", est_joint_school, se_joint_school)),
              `Share (within), %` = ifelse(is.na(est_joint_share_school), ifelse(is.na(est_beta_tot_school), "", "n.r."), sprintf("%.1f", 100 * est_joint_share_school)))]
fwrite(t4o, tp("t4_systems_science.csv"))

# Table 5: robustness summary
base <- R[run == "main" & domain == "SCIE" & stat == "joint_share", .(CNT, spec, main = est)]
alt <- R[run != "main" & domain == "SCIE" & stat == "joint_share", .(CNT, spec, run, alt = est)]
rb <- merge(base, alt, by = c("CNT", "spec"))[!is.na(main) & !is.na(alt)]
t5 <- rb[, .(Systems = .N, `Main share (%)` = summ(100 * main), `Alternative share (%)` = summ(100 * alt), `Correlation` = sprintf("%.2f", cor(main, alt)),
             `Median absolute difference (pp)` = sprintf("%.1f", median(abs(100 * (alt - main))))),
         by = .(Check = factor(run, c("ipw", "escs_index", "core5"), c("Inverse-probability weights", "ESCS in index units", "Five common scales")), Specification = factor(spec, c("student", "school"), c("Total", "Within-school")))][order(Check, Specification)]
fwrite(t5, tp("t5_robustness.csv"))

# Table 6: cross-system correlates of the share (science, total)
cs <- merge(w[domain == "SCIE" & spec == "student", .(CNT, grp, share = 100 * est_joint_share, beta = est_beta_tot, OECD = as.integer(grp == "OECD"))], cov[, .(CNT, sci_all, n_med, icc_sci)], by = "CNT")
f <- lm(share ~ OECD + I(sci_all / 100) + beta + I(100 * icc_sci) + n_med, cs)
se <- sqrt(diag(sandwich::vcovHC(f, "HC1"))); o <- c(2:length(coef(f)), 1)   # slopes first, constant last
t6 <- data.table(Variable = c("OECD member", "Mean science (per 100 points)", "Gradient (points per 10 pct. points)", "Between-school share of science variance (%)", "Number of scales fielded", "Constant"),
                 Coefficient = sprintf("%.2f", coef(f)[o]), `Robust SE` = sprintf("%.2f", se[o]), `Bivariate r` = c(sprintf("%.2f", c(cor(cs$share, cs$OECD), cor(cs$share, cs$sci_all), cor(cs$share, cs$beta), cor(cs$share, cs$icc_sci, use = "complete.obs"), cor(cs$share, cs$n_med))), ""))
fwrite(t6, tp("t6_correlates.csv")); fwrite(data.table(n = nrow(cs), r2 = summary(f)$r.squared), tp("t6_fit.csv"))

# headline numbers for the text
hl <- list(
  systems = uniqueN(R[run == "main" & domain == "SCIE", CNT]), students = R[run == "main" & domain == "SCIE" & spec == "student" & stat == "joint", sum(N)],
  share_med = 100 * median(s[spec == "student", est_joint_share]), share_q25 = 100 * q(s[spec == "student", est_joint_share], .25), share_q75 = 100 * q(s[spec == "student", est_joint_share], .75),
  share_min = 100 * min(s[spec == "student", est_joint_share], na.rm = TRUE), share_max = 100 * max(s[spec == "student", est_joint_share], na.rm = TRUE),
  share_sch_med = 100 * median(s[spec == "school", est_joint_share], na.rm = TRUE), share_sch_q25 = 100 * q(s[spec == "school", est_joint_share], .25), share_sch_q75 = 100 * q(s[spec == "school", est_joint_share], .75), n_school_share = s[spec == "school", sum(!is.na(est_joint_share))],
  beta_med = median(s[spec == "student", est_beta_tot]), beta_p10p90 = P10P90 * median(s[spec == "student", est_beta_tot]),
  joint_med = median(s[spec == "student", est_joint]), joint_p10p90 = P10P90 * median(s[spec == "student", est_joint]),
  sig_student = s[spec == "student", sum(abs(est_joint / se_joint) > 1.96)], n_student = s[spec == "student", .N],
  sig_school = s[spec == "school", sum(abs(est_joint / se_joint) > 1.96)], n_school = s[spec == "school", .N],
  gt10_student = s[spec == "student", sum(est_joint_share > .1)], gt10_school = s[spec == "school", sum(est_joint_share > .1, na.rm = TRUE)],
  curio_share_med = 100 * median(m3[mediator == "CURIO", est_ashare]), curio_rho_med = median(m3[mediator == "CURIO", est_rho]),
  curio_gap_med = P10P90 * median(m3[mediator == "CURIO", est_pi]), curio_b_med = median(m3[mediator == "CURIO", est_b]),
  growth_share_med = 100 * median(m3[mediator == "GROWTH", est_ashare]), growth_b_med = median(m3[mediator == "GROWTH", est_b]), growth_gap_med = 100 * P10P90 * median(m3[mediator == "GROWTH", est_pi]),
  cor_share_sci = cor(cs$share, cs$sci_all), cor_share_icc = cor(cs$share, cs$icc_sci, use = "complete.obs"), icc_coef = coef(f)["I(100 * icc_sci)"], icc_se = se["I(100 * icc_sci)"], cor_share_beta = cor(cs$share, cs$beta), cor_ipw = rb[run == "ipw" & spec == "student", cor(main, alt)],
  share_oecd_med = 100 * median(s[spec == "student" & grp == "OECD", est_joint_share]), share_partner_med = 100 * median(s[spec == "student" & grp == "Partner", est_joint_share]))
fwrite(as.data.table(hl), tp("headline.csv"))
options(width = 200); print(t2); print(t3); print(t5); print(t6); print(t(as.data.table(hl)))

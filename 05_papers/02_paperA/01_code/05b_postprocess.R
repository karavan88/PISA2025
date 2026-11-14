# Paper A -- rebuild summary tables from long model outputs (interaction columns are named "<factor level>:<skill>")
source("02_scripts/paperA/00_helpers.R")
econ <- fread("01_data/derived/paperA_economies.csv"); blocs <- c("East Asia", "Post-Soviet", "Post-communist Europe"); ord <- c(econ$economy, blocs, ALL_LAB)
skl <- function(t) { m <- regexpr(paste(skills, collapse = "|"), t); out <- rep(NA_character_, length(t)); out[m > 0] <- skill_lab[regmatches(t, m)]; out }
H2  <- fread(tp("h2a_skill_x_escsgrp_long.csv")); H2b <- fread(tp("h2b_skill_x_escsgrp_refB40_long.csv"))
sl <- rbind(H2[term %in% skills, .(unit, bloc, skill = skill_lab[term], group = "Top 10%", est, se)],
            H2b[term %in% skills, .(unit, bloc, skill = skill_lab[term], group = "Bottom 10%", est, se)],
            H2[grepl("escs_grpBottom 10%:", term), .(unit, bloc, skill = skl(term), group = "Difference (B10 - T10)", est, se)],
            H2[grepl("escs_grp10-40%:", term), .(unit, bloc, skill = skl(term), group = "Difference (10-40 - T10)", est, se)],
            H2[grepl("escs_grp40-90%:", term), .(unit, bloc, skill = skl(term), group = "Difference (40-90 - T10)", est, se)])
sl[, unit := factor(unit, levels = ord)]; setorder(sl, unit, skill, group); fwrite(sl, tp("h2_skill_returns_by_group.csv"))
options(width = 230)
print(dcast(sl[unit %in% c(blocs, ALL_LAB) & group %in% c("Bottom 10%", "Top 10%", "Difference (B10 - T10)")], unit + skill ~ group, value.var = c("est", "se"))[, lapply(.SD, function(x) if (is.numeric(x)) round(x, 2) else x)])
d <- sl[group == "Difference (B10 - T10)" & !unit %in% c(blocs, ALL_LAB)]; d[, sig := abs(est) > 1.96 * se]
print(d[, .(n_pos_sig = sum(est > 0 & sig), n_neg_sig = sum(est < 0 & sig), n = .N), by = skill])

if (file.exists(tp("h2d_skill_x_escs_continuous_long.csv"))) {
  H2d <- fread(tp("h2d_skill_x_escs_continuous_long.csv"))
  ci <- H2d[grepl("ESCS_zw:", term), .(unit, bloc, skill = skl(term), est = round(est, 2), se = round(se, 2))]
  ci[, unit := factor(unit, levels = ord)]; setorder(ci, unit, skill); fwrite(ci, tp("h2d_skill_x_escs_continuous.csv"))
  cat("\nSkill x ESCS (continuous, within-economy SD) interactions:\n"); print(ci[unit %in% c(blocs, ALL_LAB)])
}
if (file.exists(tp("h3_skill_x_grade_long.csv"))) {
  H3 <- fread(tp("h3_skill_x_grade_long.csv"))
  h3 <- H3[term == "grade_rel" | grepl("grade_rel:", term), .(unit, bloc, term, est = round(est, 2), se = round(se, 2))]
  h3[, term := ifelse(term == "grade_rel", "Grade (learning gain)", paste0("Grade x ", skl(term)))]
  h3[, unit := factor(unit, levels = ord)]; setorder(h3, unit); fwrite(h3, tp("h3_skill_x_grade.csv"))
  print(h3[unit %in% c(blocs, ALL_LAB)])
}
if (file.exists(tp("h3b_skill_x_grade_restricted_long.csv"))) {
  H3 <- fread(tp("h3b_skill_x_grade_restricted_long.csv"))
  h3 <- H3[term == "grade_rel" | grepl("grade_rel:", term), .(unit, bloc, term, est = round(est, 2), se = round(se, 2))]
  h3[, term := ifelse(term == "grade_rel", "Grade (learning gain)", paste0("Grade x ", skl(term)))]
  h3[, unit := factor(unit, levels = ord)]; setorder(h3, unit); fwrite(h3, tp("h3b_skill_x_grade_restricted.csv"))
  print(h3)
}
cat("postprocess done\n")

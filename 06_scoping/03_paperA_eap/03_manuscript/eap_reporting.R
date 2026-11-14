# Paper A -- helpers used by the Quarto manuscript (04_manuscripts/paperA/paperA.qmd) and by 11_figures_paper.R.
# All estimation is country-level (one mediation model per education system). The paper reports the system-level estimates
# and summarises them by the MEDIAN across systems with the interquartile range [p25, p75]; no bloc or pooled statistics.
# Blocs (East Asia / post-Soviet / post-communist Europe) remain only as a descriptive label for ordering and colouring systems.
# No estimation happens here. Paths are relative to the repo root (or the analysis folder); the layout is detected.
suppressPackageStartupMessages({library(data.table); library(knitr)})
skills    <- c("PERSEV", "SELFREG", "GOALSET", "CURIO", "ENPROBS", "COGABIL", "GROWTH")
skill_lab <- c(PERSEV = "Perseverance", SELFREG = "Self-regulated learning", GOALSET = "Goal setting", CURIO = "Curiosity",
               ENPROBS = "Problem-solving enjoyment", COGABIL = "Cognitive adaptability", GROWTH = "Growth mindset")
skill_order <- c(skill_lab, "All skills (joint)")
n_skills <- length(skills)
skill_short <- c(PERSEV = "Persev.", SELFREG = "Self-reg.", GOALSET = "Goal set.", CURIO = "Curiosity", ENPROBS = "Prob.-solv.", COGABIL = "Cogn. adapt.", GROWTH = "Growth")   # narrow tables
blocs <- c("East Asia", "Post-Soviet", "Post-communist Europe")
bloc_abbr <- c("East Asia" = "EA", "Post-Soviet" = "PS", "Post-communist Europe" = "PCE")
dom_lab <- c(READ = "Reading", MATH = "Mathematics", SCIE = "Science")
REPO <- file.exists("03_outputs/paperA/audit/requested_countries.json")
econ <- fread(if (REPO) "01_data/derived/paperA_economies.csv" else "eap_data/paperA_economies.csv")
tp <- function(dom, f) if (REPO) paste0("03_outputs/paperA/", dom, "/tables/", f) else paste0("eap_data/", dom, "/tables/", f)
FIG <- if (REPO) "03_outputs/paperA/figures_paper/" else "eap_data/figures/"
fmt <- function(x, d = 1) ifelse(is.na(x), "", formatC(x, format = "f", digits = d, big.mark = ","))
es  <- function(e, s, d = 1) ifelse(is.na(e), "", paste0(fmt(e, d), ifelse(is.na(s), "", paste0(" (", fmt(s, d), ")"))))   # estimate (SE)
eq  <- function(e, lo, hi, d = 1) ifelse(is.na(e), "", paste0(fmt(e, d), ifelse(is.na(lo), "", paste0(" [", fmt(lo, d), ", ", fmt(hi, d), "]"))))   # median [p25, p75]
pct <- function(x, d = 1) fmt(100 * x, d)
q25 <- function(x) unname(quantile(x, 0.25, na.rm = TRUE)); q75 <- function(x) unname(quantile(x, 0.75, na.rm = TRUE))
# symbols as Unicode in every output (the PDF main font, Linux Libertine, carries Greek; Quarto re-parses table headers, so LaTeX math there is not safe)
RHO  <- function() "ρ*"; R2T <- function() "R̃² threshold"; ARR <- function() "→"
# treatment (exposure) of a results file: "pct" = ESCS percentile rank / 10 (headline), "escs" = ESCS index units (check), "dep" = deprivation count
TSUF <- c(pct = "_pct", escs = "", dep = "_dep")
treat_unit <- c(pct = "10 percentile points of ESCS", escs = "ESCS unit", dep = "deprivation item")
contrast_lab <- c(pct = "Decile medians", escs = "Decile medians", dep = "+1 item")
n_econ_dom <- function(dom) fread(tp(dom, "n_economies.txt"))$n
all_lab <- function(dom) "Median across systems"

# ---- loaders (country-level rows only; pooled/bloc rows written by older runs are dropped) ----
is_pooled_row <- function(u) u %in% blocs | grepl("^All ", u)
med_raw <- function(dom, spec = "within", treat = "pct") { f <- paste0("h1_mediation_pkg", TSUF[treat], if (spec == "within") "" else "_total", ".csv")
  d <- fread(tp(dom, f)); d <- d[!is_pooled_row(unit)]; d[, mediator := factor(mediator, levels = skill_order)]
  # Joint rows use matching ten-PV point estimates and BRR/PV standard errors.
  # Single-mediator rows retain the original five/two-PV simulations.
  g <- gel_raw(dom, spec, treat); cc <- jr_raw(dom, spec, treat)
  termmap <- c(acme="explained",ade="beta_full",total="beta_base",prop="share_explained")
  idx <- which(as.character(d$mediator)=="All skills (joint)")
  for(v in names(termmap)) {
    z <- g[term==termmap[[v]]]; j <- match(d$unit[idx],z$unit)
    set(d,idx,v,z$est[j]); set(d,idx,paste0(v,"_se"),z$se[j])
  }
  set(d,idx,"acme_B10_T10",d$acme[idx]*d$contrast[idx])
  set(d,idx,"rho_star",cc$rho_star[match(d$unit[idx],cc$unit)])
  set(d,idx,"pv_used",paste0("PV",1:10,dom,collapse=";"))
  for(v in c("simulation_draws","sensitivity_draws","rho_grid"))set(d,idx,v,NA_real_)
  set(d,idx,"uncertainty","80 Fay BRR weights on PV1 plus ten-PV variance")
  set(d,idx,"implementation","ten-PV weighted coefficient decomposition; fitted-index sensitivity")
  d
}

gel_raw <- function(dom, spec = "within", treat = "pct") { g <- fread(tp(dom, paste0("h1_gelbach_long", TSUF[treat], if (spec == "within") "" else "_total", ".csv"))); g[!is_pooled_row(unit)] }
jr_raw  <- function(dom, spec = "within", treat = "pct") { f <- tp(dom, paste0("h1_joint_rho", TSUF[treat], if (spec == "within") "" else "_total", ".csv"))
  if (!file.exists(f)) return(data.table(unit = character(), rho_star = numeric()))
  fread(f)[, .(unit, rho_star)] }

# country rows (n_sys = 1) + one summary row per mediator: median across systems, with p25/p75 in *_lo / *_hi
med <- function(dom, spec = "within", treat = "pct") {
  d <- med_raw(dom, spec, treat); AL <- all_lab(dom)
  d[, bloc := econ$bloc[match(unit, econ$economy)]]
  vars <- c("acme", "ade", "total", "prop", "acme_B10_T10", "rho_star", "R2star_thresh", "R2tilde_thresh", "contrast")
  agg <- d[, c(list(unit = AL, N = sum(N), n_sys = sum(!is.na(acme)), bloc = "Median"),
               setNames(lapply(vars, function(v) as.numeric(median(get(v), na.rm = TRUE))), vars),
               setNames(lapply(vars, function(v) q25(get(v))), paste0(vars, "_lo")),
               setNames(lapply(vars, function(v) q75(get(v))), paste0(vars, "_hi"))), by = mediator]
  d[, n_sys := 1L]
  out <- rbind(d, agg, fill = TRUE)
  out[, unit := factor(unit, levels = c(econ$economy, AL))]; setorder(out, unit, mediator); out
}

# ---- Table: sample ----
tbl_sample <- function() {
  rd <- function(dom) { x <- fread(tp(dom, "t1_sample.csv")); if ("Science mean" %in% names(x)) setnames(x, c("Science mean", "Science SD"), c("Outcome mean", "Outcome SD")); x }
  t1 <- rd("READ"); tm <- rd("MATH")[, .(CNT, `Maths mean` = `Outcome mean`)]; ts <- rd("SCIE")[, .(CNT, `Science mean` = `Outcome mean`)]
  t1 <- merge(merge(t1, tm, by = "CNT", all.x = TRUE), ts, by = "CNT", all.x = TRUE)
  t1[, Bloc := factor(Bloc, levels = blocs)]; setorder(t1, Bloc, Economy)
  t1[, Schools := ifelse(Economy == "Macao", "—", as.character(Schools))]
  t1[, .(Bloc = bloc_abbr[as.character(Bloc)], Economy, N = formatC(N, big.mark = ","), Schools, `% female` = Female, `Modal grade` = `Modal grade`,
         `% below modal` = `Share below modal grade`, `% repeated` = `Repeated grade`, `% immigrant` = `Immigrant background`, `ESCS mean` = fmt(`ESCS mean`, 2),
         `% deprived` = `Deprived (any of 4 items)`, Reading = `Outcome mean`, Maths = `Maths mean`, Science = `Science mean`)]
}

# ---- Table: correlation matrix of the mediators (pooled, within-system standardised) ----
tbl_corr <- function(dom = "READ") {
  cm <- fread(tp(dom, "t_skill_intercorr.csv")); setnames(cm, "skill", "Variable")
  short <- c(Perseverance = "Persev.", `Self-regulated learning` = "Self-reg.", `Goal setting` = "Goal set.", Curiosity = "Curiosity", `Problem-solving enjoyment` = "Prob.-solv.",
             `Cognitive adaptability` = "Cogn. adapt.", `Growth mindset` = "Growth", ESCS = "ESCS", Reading = "Reading", Mathematics = "Maths", Science = "Science")
  ord <- intersect(names(short), cm$Variable); cm <- cm[match(ord, Variable), c("Variable", ord), with = FALSE]
  for (c in ord) cm[, (c) := fmt(get(c), 2)]
  setnames(cm, ord, unname(short[ord])); cm
}

# ---- Table: skill gradients (mediator-model coefficient on ESCS): median across systems, IQR, lowest and highest system ----
tbl_gradients <- function(dom = "READ", spec = "total", treat = "pct") {
  g <- gel_raw(dom, spec, treat)
  one <- function(term_k, label, d) { y <- g[term == term_k]
    data.table(Variable = label, Systems = nrow(y), `Median [IQR]` = eq(median(y$est), q25(y$est), q75(y$est), d),
               Lowest = paste0(fmt(min(y$est), d), " (", y$unit[which.min(y$est)], ")"), Highest = paste0(fmt(max(y$est), d), " (", y$unit[which.max(y$est)], ")")) }
  rbind(rbindlist(lapply(skills, function(k) one(paste0("pi_", k), skill_lab[k], 3))), one("beta_base", paste0(dom_lab[dom], " (points)"), 1))
}

# ---- Table: main mediation results: median across systems [IQR], both specifications ----
tbl_mediation <- function(dom = "READ", specs = c("within", "total"), treat = "pct") {
  rbindlist(lapply(specs, function(sp) { m <- med(dom, sp, treat)[unit == all_lab(dom)]
    m <- m[, .(Specification = if (sp == "within") "School-adjusted" else "Student-adjusted", Mediator = as.character(mediator), Systems = n_sys,
               `ACME [IQR]` = eq(acme, acme_lo, acme_hi, 2), `ADE [IQR]` = eq(ade, ade_lo, ade_hi, 1), `Total [IQR]` = eq(total, total_lo, total_hi, 1),
               `Share, % [IQR]` = eq(100 * prop, 100 * prop_lo, 100 * prop_hi, 1), `ACME, B10→T10` = fmt(acme_B10_T10, 1), `ρ*` = fmt(rho_star, 2), `R̃² threshold` = fmt(R2tilde_thresh, 3))]
    setnames(m, c("ACME, B10→T10", "ρ*", "R̃² threshold"), c(paste0("ACME, ", contrast_lab[treat]), RHO(), R2T())); m }))
}

# ---- Table: by system (joint and curiosity), with the median row ----
tbl_mediation_econ <- function(dom = "READ", spec = "within", treat = "pct") {
  m <- med(dom, spec, treat)
  j <- m[mediator == "All skills (joint)"]; c <- m[mediator == "Curiosity"]
  out <- merge(j[, .(unit, N, n_sys, total, total_se, acme_j = acme, prop_j = prop, prop_se_j = prop_se, acmeB_j = acme_B10_T10, rho_j = rho_star)],
               c[, .(unit, acme_c = acme, acme_se_c = acme_se, prop_c = prop, rho_c = rho_star)], by = "unit")
  out[, bloc := econ$bloc[match(as.character(unit), econ$economy)]]; out[, unit := factor(unit, levels = c(econ$economy, all_lab(dom)))]; setorder(out, unit)
  out <- out[, .(Bloc = ifelse(is.na(bloc), "", bloc_abbr[bloc]), System = as.character(unit), N = ifelse(n_sys == 1, formatC(N, big.mark = ","), ""),
                 `Total ESCS effect (SE)` = ifelse(n_sys == 1, es(total, total_se, 1), fmt(total, 1)),
                 `ACME, all skills` = fmt(acme_j, 2), `Joint share, % (SE)` = ifelse(n_sys == 1, es(100 * prop_j, 100 * prop_se_j, 1), pct(prop_j)), `ACME, B10→T10` = fmt(acmeB_j, 1), `ρ* joint` = fmt(rho_j, 2),
                 `ACME curiosity (SE)` = ifelse(n_sys == 1, es(acme_c, acme_se_c, 2), fmt(acme_c, 2)), `% via curiosity` = pct(prop_c), `ρ* curiosity` = fmt(rho_c, 2))]
  setnames(out, c("ACME, B10→T10", "ρ* joint", "ρ* curiosity"), c(paste0("ACME, ", contrast_lab[treat]), paste(RHO(), "joint"), paste(RHO(), "curiosity")))
  out
}

# ---- Table: by system for the deprivation exposure (items fielded, total penalty per item, joint and curiosity) ----
tbl_mediation_econ_dep <- function(dom = "READ", spec = "within") {
  m <- med(dom, spec, "dep")
  items <- fread(rp("deprivation_profile.csv"))
  j <- m[mediator == "All skills (joint)"]; c <- m[mediator == "Curiosity"]
  out <- merge(j[, .(unit = as.character(unit), N, n_sys, total, total_se, acme_j = acme, prop_j = prop, prop_se_j = prop_se)], c[, .(unit = as.character(unit), acme_c = acme, acme_se_c = acme_se, prop_c = prop)], by = "unit")
  out <- merge(out, items, by = "unit", all.x = TRUE); out[, bloc := econ$bloc[match(unit, econ$economy)]]
  out[, unit := factor(unit, levels = c(econ$economy, all_lab(dom)))]; setorder(out, unit)
  out[, .(Bloc = ifelse(is.na(bloc), "", bloc_abbr[bloc]), System = as.character(unit), N = ifelse(n_sys == 1, formatC(N, big.mark = ","), ""), Items = ifelse(n_sys == 1, as.character(Items), ""),
          `% lacking any item` = ifelse(n_sys == 1, pct(dep_any, 0), ""), `Penalty per item (SE)` = ifelse(n_sys == 1, es(total, total_se, 1), fmt(total, 1)),
          `ACME, all dispositions` = fmt(acme_j, 2), `Joint share, % (SE)` = ifelse(n_sys == 1, es(100 * prop_j, 100 * prop_se_j, 1), pct(prop_j)),
          `ACME curiosity (SE)` = ifelse(n_sys == 1, es(acme_c, acme_se_c, 2), fmt(acme_c, 2)), `% via curiosity` = pct(prop_c))]
}

# ---- Pathway shares: single-mediator (mediate) vs conditional on the other skills (Gelbach); medians across systems ----
# Gelbach contribution of skill k = gamma_k (return conditional on the other five skills) x pi_k (ESCS gradient of skill k); the six sum to the joint block.
gelbach_shares <- function(dom = "READ", spec = "within", treat = "pct") {   # system rows + median row, shares of the system's own total effect
  g <- gel_raw(dom, spec, treat)
  d <- merge(g[grepl("^delta_", term), .(unit, mediator = skill_lab[sub("delta_", "", term)], pts = est)], g[term == "beta_base", .(unit, base = est)], by = "unit")
  d <- rbind(d, d[, .(mediator = "All skills (joint)", pts = sum(pts), base = base[1]), by = unit], fill = TRUE)
  shares <- g[grepl("^share_",term) & term!="share_explained",.(unit,mediator=skill_lab[sub("^share_","",term)],share=est)]
  shares <- rbind(shares,g[term=="share_explained",.(unit,mediator="All skills (joint)",share=est)])
  d <- merge(d,shares,by=c("unit","mediator"),all.x=TRUE);d[,n_sys:=1L]
  agg <- d[, .(unit = all_lab(dom), pts = median(pts), base = median(base), share = median(share), share_lo = q25(share), share_hi = q75(share), n_sys = .N), by = mediator]
  out <- rbind(d, agg, fill = TRUE); out[, mediator := factor(mediator, levels = skill_order)]; out
}
tbl_pathways <- function(dom = "READ", spec = "within", treat = "pct") {
  AL <- all_lab(dom)
  m <- med(dom, spec, treat)[unit == AL, .(Mediator = as.character(mediator), `Single mediator: median [IQR]` = eq(100 * prop, 100 * prop_lo, 100 * prop_hi, 1))]
  gb <- gelbach_shares(dom, spec, treat)[unit == AL, .(Mediator = as.character(mediator), `Conditional (Gelbach): median [IQR]` = eq(100 * share, 100 * share_lo, 100 * share_hi, 1))]
  x <- merge(m, gb, by = "Mediator"); x[, Mediator := factor(Mediator, levels = skill_order)]; setorder(x, Mediator); x[, Mediator := as.character(Mediator)]; x
}

# ---- Table: domains x specs, joint proportion mediated: median across systems [IQR] ----
tbl_domains <- function(treat = "pct") {
  rows <- list()
  for (dom in c("READ", "MATH", "SCIE")) for (spec in c("within", "total")) {
    m <- med(dom, spec, treat)[mediator == "All skills (joint)" & unit == all_lab(dom)]
    sp_lab <- if (spec == "within") "School-adjusted" else "Student-adjusted"; dm_lab <- unname(dom_lab[dom])   # (m has a `spec` column: do not resolve the loop variable inside m[])
    rows[[paste(dom, spec)]] <- m[, .(Domain = dm_lab, Specification = sp_lab, Systems = n_sys, `Total ESCS effect [IQR]` = eq(total, total_lo, total_hi, 1),
                                      `ACME, all skills [IQR]` = eq(acme, acme_lo, acme_hi, 2), `Share, % [IQR]` = eq(100 * prop, 100 * prop_lo, 100 * prop_hi, 1), `ρ* joint` = fmt(rho_star, 2))]
  }
  R <- rbindlist(rows); setnames(R, "ρ* joint", paste(RHO(), "joint")); R
}

# ---- Table: per-skill ACME across domains (median across systems) ----
tbl_skills_domains <- function(spec = "within", treat = "pct") {
  rows <- lapply(c("READ", "MATH", "SCIE"), function(dom) { m <- med(dom, spec, treat)[unit == all_lab(dom)]; dm_lab <- unname(dom_lab[dom])
    m[, .(Domain = dm_lab, Mediator = as.character(mediator), acme = fmt(acme, 2), prop = eq(100 * prop, 100 * prop_lo, 100 * prop_hi, 1), rho = fmt(rho_star, 2))] })
  R <- rbindlist(rows); R[, Mediator := factor(Mediator, levels = skill_order)]; R[, Domain := factor(Domain, levels = unname(dom_lab))]
  W <- dcast(R, Mediator ~ Domain, value.var = c("acme", "prop", "rho"))
  cols <- as.vector(outer(c("acme_", "prop_", "rho_"), unname(dom_lab), paste0)); setcolorder(W, c("Mediator", cols))
  setnames(W, cols, as.vector(outer(c("ACME", "% mediated [IQR]", RHO()), unname(dom_lab), function(a, b) paste0(b, ": ", a))))
  W[, Mediator := as.character(Mediator)]; W
}

# ---- Table: the three exposures side by side (reading): joint block and curiosity, medians across systems ----
tbl_exposures <- function(dom = "READ") {
  rows <- list()
  for (tr in c("pct", "escs", "dep")) for (sp in c("within", "total")) {
    f <- tp(dom, paste0("h1_mediation_pkg", TSUF[tr], if (sp == "within") "" else "_total", ".csv")); if (!file.exists(f)) next
    m <- med(dom, sp, tr)[unit == all_lab(dom) & mediator %in% c("All skills (joint)", "Curiosity", "Growth mindset", "Perseverance")]
    lab <- c(pct = "ESCS percentile rank (per 10 points)", escs = "ESCS index (per unit)", dep = "Deprivation count (per item, at given ESCS)")[tr]
    rows[[paste(tr, sp)]] <- m[, .(Exposure = lab, Specification = if (sp == "within") "School-adjusted" else "Student-adjusted", Systems = n_sys, Mediator = as.character(mediator),
                                   `Total effect [IQR]` = eq(total, total_lo, total_hi, 1), `ACME [IQR]` = eq(acme, acme_lo, acme_hi, 2), `Share, % [IQR]` = eq(100 * prop, 100 * prop_lo, 100 * prop_hi, 1))]
  }
  R <- rbindlist(rows); R[, Mediator := factor(Mediator, levels = c("All skills (joint)", "Curiosity", "Perseverance", "Growth mindset"))]
  R[order(match(Exposure, c("ESCS percentile rank (per 10 points)", "ESCS index (per unit)", "Deprivation count (per item, at given ESCS)")), match(Specification, c("School-adjusted", "Student-adjusted")), Mediator)][, Mediator := as.character(Mediator)][]
}

# ---- Table: robustness (reading): median across systems of the Gelbach joint share under each sample check ----
tbl_robustness <- function(dom = "READ", spec = "within", treat = "pct") {
  rb <- fread(tp(dom, paste0("rob_gelbach_table", TSUF[treat], if (spec == "within") "" else "_total", ".csv")))
  rb[, check := sub("^Main: .*", "Main specification", check)]
  rb[, .(Check = check, Systems = systems, `ESCS effect, no skills [IQR]` = eq(beta_base, beta_base_lo, beta_base_hi, 1),
         `Mediated, points [IQR]` = eq(explained, explained_lo, explained_hi, 2), `Share, % [IQR]` = eq(share_explained, share_explained_lo, share_explained_hi, 1),
         `% via curiosity (conditional)` = fmt(share_CURIO, 1))]
}

kb <- function(df, caption = NULL, digits = NULL, font = NULL, landscape = FALSE, group = NULL, ...) {
  # Markdown (pipe) tables for every output. Quarto re-parses any LaTeX table that carries a cross-reference label, so kableExtra
  # styling (scale_down, font size, landscape) does not survive; page orientation is set with a `::: {.landscape}` div in the
  # .qmd and the table font with an etoolbox hook in the PDF header. `font`, `landscape` and `group` are kept for call compatibility.
  if("Bloc" %in% names(df)) df[, Bloc := NULL]
  kable(df, caption = caption, format = "pipe", align = c("l", rep("r", ncol(df) - 1)))
}

# EAP manuscript reporting helpers; all inputs are completed estimations.
rp <- function(f) file.path(if(REPO) "03_outputs/paperA/reporting" else "eap_data/reporting",f)
ap <- function(f) file.path(if(REPO) "03_outputs/paperA/audit" else "eap_data/audit",f)
J <- function(unit=NULL,dom="READ",sp="within",tr="pct") {
  z <- med(dom,sp,tr)[mediator=="All skills (joint)"]
  selected_unit<-unit
  if(is.null(selected_unit)) z[n_sys==1] else z[as.character(z$unit)==selected_unit]
}
V <- function(unit,what="prop",dom="READ",sp="within",tr="pct",digits=1) {
  z<-J(unit,dom,sp,tr)[[what]][1]
  fmt(if(what=="prop")100*z else z,digits)
}
SM <- function(mediator="All skills (joint)",what="prop",dom="READ",sp="within",tr="pct",digits=1) {
  z<-med(dom,sp,tr);selected_mediator<-mediator;z<-z[as.character(z$mediator)==selected_mediator & n_sys>1][[what]][1]
  fmt(if(what=="prop")100*z else z,digits)
}
SP <- function(unit,mediator,what="prop",dom="READ",sp="within",tr="pct",digits=1) {
  z<-med(dom,sp,tr);selected_mediator<-mediator;selected_unit<-unit;z<-z[as.character(z$mediator)==selected_mediator & as.character(z$unit)==selected_unit][[what]][1]
  fmt(if(what=="prop")100*z else z,digits)
}
ordered <- function(z,col="System") z[order(match(z[[col]],econ$economy))]
tbl_sample_compact <- function() {
  d<-tbl_sample();d<-d[,.(System=Economy,N,Schools,`Female, %`=`% female`,Reading,Maths,Science)]
  ordered(d)
}
tbl_controls <- function() {
  d<-tbl_sample();d<-d[,.(System=Economy,`Modal grade`,`Below modal, %`=`% below modal`,`Repeated, %`=`% repeated`,
                         `Immigrant, %`=`% immigrant`,`Mean ESCS`=`ESCS mean`,`Core deprivation, %`=`% deprived`)]
  d[,`:=`(`Repeated, %`=as.character(`Repeated, %`),`Core deprivation, %`=as.character(`Core deprivation, %`))]
  d[System=="Japan",`:=`(`Repeated, %`="n/a",`Core deprivation, %`="n/a")];ordered(d)
}
tbl_country_joint <- function(dom="READ",tr="pct") {
  d<-rbindlist(lapply(c('total','within'),function(sp) {
    z<-J(dom=dom,sp=sp,tr=tr)
    z[,.(System=as.character(unit),Specification=if(sp=='within')'School' else 'Student',
          `Baseline (SE)`=es(total,total_se,2),`After skills (SE)`=es(ade,ade_se,2),
          `Change (SE)`=es(acme,acme_se,2),`Share, % (SE)`=es(100*prop,100*prop_se,1))]
  }))
  d[order(match(System,econ$economy),match(Specification,c('Student','School')))]
}
tbl_country_paths <- function(dom="READ",sp="within",tr="pct",conditional=FALSE) {
  if(conditional) {
    z<-gelbach_shares(dom,sp,tr)[n_sys==1,.(System=as.character(unit),mediator=as.character(mediator),share)]
  } else z<-med(dom,sp,tr)[n_sys==1,.(System=as.character(unit),mediator=as.character(mediator),share=prop)]
  z[,value:=fmt(100*share,1)]
  d<-dcast(z,System~mediator,value.var='value',fill='—')
  labs<-c(unname(skill_lab),"All skills (joint)");labs<-intersect(labs,names(d));setcolorder(d,c('System',labs))
  shorts<-c(unname(skill_short),"Joint");setnames(d,labs,shorts[match(labs,c(unname(skill_lab),"All skills (joint)"))]);ordered(d)
}
tbl_country_domains <- function() {
  z<-rbindlist(lapply(names(dom_lab),function(dm)rbindlist(lapply(c('within','total'),function(sp) {
    d<-J(dom=dm,sp=sp);d[,.(System=as.character(unit),Column=paste(dom_lab[dm],if(sp=='within')'School' else 'Student'),value=es(100*prop,100*prop_se,1))]
  }))))
  ordered(dcast(z,System~Column,value.var='value'))
}
tbl_country_robustness <- function(tr='pct',sp='within') {
  z<-fread(tp('READ',paste0('rob_gelbach_long',TSUF[tr],if(sp=='within')'' else '_total','.csv')))
  z<-dcast(z,unit+check~term,value.var='est');z[,Share:=fmt(100*explained/beta_base,1)]
  z[,Check:=fcase(grepl('^Main',check),'Main',grepl('^Modal',check),'Modal grade',default='Nonresponse weights')]
  z[,System:=unit];ordered(dcast(z,System~Check,value.var='Share'))
}
tbl_availability <- function() {
  a<-fread(ap('requested_sample_availability.csv'));e<-fread(ap('model_eligibility.csv'))
  z<-merge(a[,.(CNT,System=economy,Requested=N_all)],e[,.(CNT,Analytic=N,Deprivation=N_dep,Skills=skills)],by='CNT',all.x=TRUE)
  z[is.na(Analytic),`:=`(Analytic=0L,Deprivation=0L,Skills=0L)]
  z[,Note:=fcase(CNT=='KHM','Six continuous skill scales unavailable',CNT=='JPN','No repetition control; no deprivation module',CNT=='IDN','Perseverance unavailable',CNT=='MAC','School identifiers and controls unavailable',default='Full specification')]
  z<-z[match(a$CNT,CNT)];z[,CNT:=NULL];z
}

tbl_random_slopes <- function() {
  z<-fread(tp('READ','h2rs_slope_sd_by_economy.csv'))
  stopifnot(setequal(z$economy,econ$economy),nrow(z)==90L,all(is.finite(z$slope_sd)),all(z$slope_sd>=0))
  z[,`:=`(System=economy,Skill=unname(skill_short[skill]),Value=fmt(slope_sd,1))]
  ordered(dcast(z,System~Skill,value.var='Value',fill='—'))
}

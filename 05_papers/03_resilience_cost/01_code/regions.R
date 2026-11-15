# World regions of the systems in this paper, for the pooled estimates by region (step 15). A definition, not data: geographic groups
# chosen on 15 November 2026. Every system in the per-system files must appear here; 15_regions.R stops otherwise.
REGIONS <- list(
  `Western and Northern Europe` = c("AUT", "BEL", "CHE", "DEU", "DNK", "ESP", "FIN", "FRA", "GBR", "GRC", "IRL", "ISL", "ITA", "LUX", "MLT", "NLD", "PRT"),
  `Central and Eastern Europe` = c("ALB", "BGR", "CZE", "EST", "HRV", "HUN", "KSV", "LTU", "LVA", "MDA", "MKD", "MNE", "POL", "ROU", "SRB", "SVK", "SVN"),
  `Latin America` = c("ARG", "BRA", "CHL", "COL", "DOM", "ECU", "GTM", "MEX", "PER", "PRY", "URY"),
  `East and South-East Asia` = c("BRN", "HKG", "IDN", "JPN", "KOR", "MAC", "MNG", "MYS", "PHL", "QCI", "TAP", "THA", "VNM"),
  `Middle East and North Africa` = c("ARE", "ISR", "JOR", "LBN", "MAR", "PSE", "QAT", "SAU"),
  `Caucasus and Central Asia` = c("ARM", "AZE", "GEO", "KAZ", "KGZ"),
  `New Zealand and Kenya` = c("NZL", "KEN"))
REGION_OF <- data.table::rbindlist(lapply(names(REGIONS), function(n) data.table::data.table(region = n, CNT = REGIONS[[n]])))

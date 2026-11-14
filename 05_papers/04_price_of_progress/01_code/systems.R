# The 20 systems of the legacy cutoff design: whether both grades of the cohort share schools ("Same-school") or the upper grade
# is a different school ("Transition"), and display names. Definitions, not data: copied on 2026-11-14 from the legacy skillsgain
# output (structure.csv) and the grade-gain system list. Replaced when the design moves to the central 36-system preparation.
SYSTEMS_TABLE <- data.table::data.table(
  CNT = c("ARE", "BRA", "BRN", "CRI", "CZE", "DEU", "ECU", "EST", "FIN", "HKG", "HRV", "KEN", "KHM", "MUS", "PER", "PHL", "PRY", "QCI", "SVK", "TAP"),
  structure = c("Same-school", "Same-school", "Same-school", "Same-school", "Transition", "Same-school", "Same-school", "Same-school", "Same-school", "Same-school", "Same-school", "Transition", "Same-school", "Same-school", "Same-school", "Same-school", "Transition", "Transition", "Transition", "Transition"),
  name = c("United Arab Emirates", "Brazil", "Brunei", "Costa Rica", "Czechia", "Germany", "Ecuador", "Estonia", "Finland", "Hong Kong", "Croatia", "Kenya", "Cambodia", "Mauritius", "Peru", "Philippines", "Paraguay", "B-S-J-Z (China)", "Slovak Republic", "Chinese Taipei"))

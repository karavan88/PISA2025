# Local source data (ignored by Git)

Central build inputs: `CY09_MS_STU_PUF.sav` and `CY09_MS_SCH_PUF.sav`.
Other locally held PISA files may remain here but are not read by the current
shared harmonizer. The build reads student data once and school data once,
joins school weights, and prepares all current shared variables. Set PISA_DATA
to an alternative source directory. Obtain source files under the provider's
applicable access conditions; this repository does not redistribute them.

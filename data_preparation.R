#!/usr/bin/env Rscript
# ============================================================
# DATA PREPARATION PIPELINE
# Thesis: International Student Presence and Dutch Graduate
#         Labor Market Outcomes
# Author: Redon Ismailaga (9770879)
# ============================================================
#
# This script reads raw data from the thesis data directory,
# tidies it, and writes pre-processed CSV files to data_tidy/.
# The tidied datasets are then loaded by thesis_complete.Rmd for analysis.
#
# USAGE (from Positron or R terminal):
#   source("data_preparation.R")
#   prepare_all_data()
#
# Or from command line:
#   Rscript data_preparation.R "/path/to/Thesis work/DATA" "data_tidy"
#
# The script does NOT alter any raw data files -- all processing
# happens in memory.

# Auto-install required packages
for (pkg in c("data.table", "readxl")) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
}

suppressPackageStartupMessages({
  library(data.table)
  library(readxl)
})

# ============================================================
# CONFIGURATION
# ============================================================

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0 || is.na(x) || !nzchar(x)) y else x

# Auto-detect data directory
default_data_dir <- function() {
  candidates <- c(
    "C:/Users/redon/Desktop/Thesis work/DATA",
    "C:/Users/redon/Desktop/Thesis work/Data",
    "C:/Users/redon/Desktop/Hermes/data_raw",
    "/desktop/Thesis work/Data",
    "/desktop/Thesis work/DATA",
    "data_raw"
  )
  message("Looking for raw data in:")
  for (c in candidates) {
    exists <- dir.exists(c)
    message(sprintf("  %-55s [%s]", c, if(exists) "FOUND" else "missing"))
  }
  hit <- candidates[dir.exists(candidates)]
  if (length(hit)) {
    message(sprintf("\nUsing: %s", hit[[1]]))
    return(hit[[1]])
  }
  stop(sprintf(
    "No data directory found. Tried:\n  %s\n\nPlace your raw data in one of these locations, or call:\n  prepare_all_data('C:/path/to/your/DATA', 'data_tidy')",
    paste(candidates, collapse="\n  ")
  ))
}

# ============================================================
# UTILITY FUNCTIONS
# ============================================================

clean_column_names <- function(x) {
  x <- trimws(tolower(as.character(x)))
  x <- iconv(x, from = "", to = "ASCII//TRANSLIT", sub = "")
  x <- gsub("%", " percent ", x, fixed = TRUE)
  x <- gsub("[^a-z0-9]+", "_", x)
  x <- gsub("_+", "_", x)
  x <- gsub("^_|_$", "", x)
  x[nchar(x) == 0] <- "column"
  make.unique(x, sep = "_")
}

parse_wave <- function(path) {
  base <- basename(path)
  wave <- sub("^([a-z]{2}[0-9]{2}[a-z]).*$", "\\1", base)
  if (identical(wave, base)) NA_character_ else wave
}

wave_year <- function(wave) {
  as.integer(paste0("20", sub("^[a-z]{2}([0-9]{2})[a-z]$", "\\1", wave)))
}

detect_delimiter <- function(path) {
  first <- readLines(path, n = 1, warn = FALSE, encoding = "UTF-8")
  counts <- c(
    ";" = lengths(regmatches(first, gregexpr(";", first, fixed = TRUE))),
    "," = lengths(regmatches(first, gregexpr(",", first, fixed = TRUE))),
    "\t"= lengths(regmatches(first, gregexpr("\t", first, fixed = TRUE)))
  )
  names(which.max(counts))
}

read_delimited <- function(path, sep = NULL) {
  sep <- sep %||% detect_delimiter(path)
  fread(
    path, sep = sep, encoding = "UTF-8",
    na.strings = c("", "NA", "N/A", "NaN", "nan", "null", "NULL"),
    quote = "\"", integer64 = "character",
    fill = TRUE, showProgress = FALSE, data.table = TRUE
  )
}

# ============================================================
# 1. LISS WORK AND SCHOOLING DATA
# ============================================================

#' Read and standardize LISS Work and Schooling module
read_liss_work <- function(data_dir) {
  files <- list.files(
    file.path(data_dir, "LISS Work and Schooling", "Extracted"),
    pattern = "^cw[0-9]{2}[a-z]_EN_.*\\.csv$",
    full.names = TRUE
  )
  if (!length(files)) stop("No LISS Work and Schooling CSV files found")
  
  # LISS field-of-study crosswalk
  field_crosswalk <- data.table(
    liss_code = sprintf("%03d", 11:27),
    liss_field = c(
      "General or no specific field",
      "Teacher training or education",
      "Art", "Humanities",
      "Social and behavioral studies",
      "Economics, management, business administration, accountancy",
      "Law, public administration",
      "Mathematics, physics, IT",
      "Technology",
      "Agriculture, forestry, environment",
      "Medical, health services, nursing",
      "Personal care services",
      "Catering, recreation",
      "Transport, logistics",
      "Telecommunication",
      "Public order and safety",
      "Other area"
    ),
    duo_field = c(
      NA, "onderwijs", "taal en cultuur", "taal en cultuur",
      "gedrag en maatschappij", "economie", "recht",
      "natuur", "techniek", "landbouw en natuurlijke omgeving",
      "gezondheidszorg", "gedrag en maatschappij",
      "gedrag en maatschappij", "techniek", "techniek",
      "recht", "sectoroverstijgend"
    ),
    broad_field = c(
      NA, "education", "social_sciences_humanities_arts",
      "social_sciences_humanities_arts", "social_sciences_humanities_arts",
      "economics_law_business", "economics_law_business",
      "stem", "stem", "stem", "health",
      "services_other", "services_other", "stem", "stem",
      "economics_law_business", "services_other"
    ),
    # Education level mapping from LISS codes
    edu_level = c(
      NA, "hbo", "hbo", "wo",  # General, Teacher, Art, Humanities
      "wo", "hbo", "wo",       # Social, Economics, Law
      "wo", "hbo", "hbo",       # Math/IT, Technology, Agriculture
      "hbo", "hbo", "hbo",      # Medical, Personal care, Catering
      "hbo", "hbo", "hbo"       # Transport, Telecom, Public order
    )
  )
  
  all_waves <- lapply(files, function(path) {
    wave <- parse_wave(path)
    dt <- read_delimited(path)
    
    # Standardize person identifier
    old_names <- names(dt)
    key_idx <- match("Number of household member encrypted", old_names)
    if (!is.na(key_idx)) setnames(dt, old_names[key_idx], "nomem_encr")
    dt[, nomem_encr := as.character(nomem_encr)]
    dt[, wave := wave]
    dt[, survey_year := wave_year(wave)]
    
    # Extract age: "Respondent's age" (waves 20-21) or cwXX003 (waves 22-24)
    age_col <- grep("Respondent.*age|^age$", old_names, value = TRUE, ignore.case = TRUE)[1]
    age_coded <- grep(paste0("^", wave, "003$"), names(dt), value = TRUE)[1]
    if (!is.na(age_col)) {
      age_vals <- as.numeric(dt[[age_col]])
    } else if (!is.na(age_coded)) {
      age_vals <- as.numeric(dt[[age_coded]])
    } else {
      age_vals <- rep(NA_real_, nrow(dt))
    }
    
    # Extract gender: "geslacht" or gender column
    gender_col <- grep("geslacht|gender|sex", old_names, value = TRUE, ignore.case = TRUE)[1]
    if (!is.na(gender_col)) {
      gender_vals <- tolower(as.character(dt[[gender_col]]))
    } else {
      gender_vals <- rep(NA_character_, nrow(dt))
    }
    
    # Extract field of study
    # LISS stores field as binary indicators (e.g., cw20m011, cw20m012, ...)
    coded_cols <- grep(paste0("^", wave, "[0-9]{3}$"), names(dt), value = TRUE)
    
    if (length(coded_cols)) {
      id_cols <- intersect(c("nomem_encr", "wave", "survey_year"), names(dt))
      
      long <- melt(
        dt[, c(id_cols, coded_cols), with = FALSE],
        id.vars = id_cols,
        measure.vars = coded_cols,
        variable.name = "source_variable",
        value.name = "selected_raw"
      )
      long[, liss_code := sub(paste0("^", wave), "", source_variable)]
      long[, selected := as.integer(selected_raw) %in% c(1, 2)]
      
      # Merge field labels
      long <- merge(long, field_crosswalk, by = "liss_code", all.x = TRUE)
      
      # Keep only selected fields per person
      person_fields <- long[selected == TRUE, .(
        liss_field_list = paste(na.omit(unique(liss_field)), collapse = " | "),
        duo_field_list  = paste(na.omit(unique(duo_field)), collapse = " | "),
        broad_field_list = paste(na.omit(unique(broad_field)), collapse = " | "),
        stem_field      = as.integer(any(broad_field == "stem", na.rm = TRUE)),
        age             = age_vals[1],
        female          = as.integer(grepl("vrouw|female|2", gender_vals[1]))
      ), by = .(nomem_encr, wave, survey_year)]
      
      return(person_fields)
    }
    return(NULL)
  })
  
  rbindlist(all_waves, fill = TRUE)
}

# ============================================================
# 2. LISS INCOME DATA
# ============================================================

read_liss_income <- function(data_dir) {
  files <- list.files(
    file.path(data_dir, "LISS Economic Situation, Income", "Extracted"),
    pattern = "^ci[0-9]{2}[a-z]_EN_.*\\.csv$",
    full.names = TRUE
  )
  if (!length(files)) stop("No LISS Economic Situation, Income CSV files found")
  
  income_waves <- lapply(files, function(path) {
    wave <- parse_wave(path)
    dt <- read_delimited(path)
    
    # Get person ID: first try "nomem_encr", then "Number of household member encrypted"
    nms <- names(dt)
    id_col <- if ("nomem_encr" %in% nms) "nomem_encr" else {
      idx <- grep("Number of household member encrypted", nms, fixed = TRUE)
      if (length(idx)) nms[idx[1]] else nms[1]
    }
    
    # Find income column
    income_val <- NULL
    
    # Coded waves: ciXX372
    coded <- grep(paste0("^", wave, "372$"), nms, value = TRUE)
    if (length(coded)) income_val <- as.numeric(dt[[coded[1]]])
    
    # Named waves: "gross wages in total"
    if (is.null(income_val) || all(is.na(income_val))) {
      gw <- grep("gross wages in total", nms, value = TRUE, ignore.case = TRUE)
      if (length(gw)) income_val <- as.numeric(dt[[gw[1]]])
    }
    
    # Fallback: any column with "gross" in name
    if (is.null(income_val) || all(is.na(income_val))) {
      gr <- grep("gross", nms, value = TRUE, ignore.case = TRUE)
      if (length(gr)) income_val <- as.numeric(dt[[gr[1]]])
    }
    
    if (is.null(income_val)) income_val <- rep(NA_real_, nrow(dt))
    
    data.table(
      nomem_encr = as.character(dt[[id_col]]),
      personal_gross_annual_income = income_val,
      wave = wave,
      survey_year = wave_year(wave),
      income_reference_year = wave_year(wave) - 1L
    )
  })
  
  rbindlist(income_waves, fill = TRUE)
}

# ============================================================
# 3. DUO GRADUATES DATA (WO + HBO)
# ============================================================

read_duo_graduates <- function(data_dir) {
  duo_dir <- file.path(data_dir,
    "DUO Graduates by Gender, Institution, Field of  Study, University and Professional level")
  
  wo_path <- file.path(duo_dir,
    "Graduates by Gender, Institution, Field of study, University level.csv")
  hbo_path <- file.path(duo_dir,
    "Graduates by Gender, Institution, Field of study, Professional level.csv")
  
  read_one <- function(path, niveau_label) {
    if (!file.exists(path)) {
      warning("DUO file not found: ", path)
      return(data.table())
    }
    dt <- read_delimited(path)
    setnames(dt, clean_column_names(names(dt)))
    
    # Reshape from wide (year columns) to long
    year_cols <- intersect(as.character(2020:2024), names(dt))
    if (!length(year_cols)) {
      year_cols <- grep("^20[0-9]{2}$", names(dt), value = TRUE)
    }
    if (!length(year_cols)) stop("No year columns found in DUO data: ", path)
    
    long <- melt(
      dt,
      id.vars = setdiff(names(dt), year_cols),
      measure.vars = year_cols,
      variable.name = "year",
      value.name = "graduates_raw"
    )
    long[, year := as.integer(as.character(year))]
    long[, niveau := niveau_label]
    
    # Handle suppressed values "<5"
    long[, graduates_suppressed := grepl("<", as.character(graduates_raw), fixed = TRUE)]
    long[, graduates := suppressWarnings(
      as.numeric(gsub("[^0-9-]", "", as.character(graduates_raw)))
    )]
    long[graduates_suppressed == TRUE, graduates := NA_integer_]
    
    # Standardize field names
    long[, duo_field := trimws(tolower(onderdeel))]
    
    # Classify programs as international (English name)
    long[, is_international := sapply(tolower(opleidingsnaam_actueel), function(nm) {
      words <- strsplit(nm, "[^a-zA-Z]+")[[1]]
      words <- words[nchar(words) > 1]
      if (length(words) == 0) return(NA)
      english_markers <- c("studies", "science", "engineering", "management",
        "economics", "business", "international", "global", "european",
        "research", "development", "technology", "policy", "law", "health",
        "sustainability", "innovation", "governance", "leadership",
        "psychology", "sociology", "anthropology", "communication",
        "and", "the", "in", "of", "for")
      dutch_markers <- c("wetenschappen", "kunde", "onderwijs", "bestuur",
        "gedrag", "maatschappij", "geneeskunde", "tandheelkunde", "rechten",
        "economie", "bedrijfskunde", "gezondheid", "zorg", "techniek",
        "voltijd", "deeltijd", "duaal")
      english_count <- sum(tolower(words) %in% english_markers)
      dutch_count   <- sum(tolower(words) %in% dutch_markers)
      english_count > dutch_count && english_count >= 1
    })]
    
    return(long)
  }
  
  wo  <- read_one(wo_path, "WO")
  hbo <- read_one(hbo_path, "HBO")
  
  rbindlist(list(wo, hbo), fill = TRUE)
}

# ============================================================
# 4. IND VISA ACCEPTANCE DATA
# ============================================================

read_ind_visa <- function(data_dir) {
  files <- list.files(
    file.path(data_dir, "IND Short-Term Schengen Visa Acceptance Rates"),
    pattern = "\\.xlsx$", full.names = TRUE
  )
  if (!length(files)) return(data.table())
  
  all_visa <- lapply(files, function(path) {
    year <- as.integer(regmatches(basename(path), regexpr("20[0-9]{2}", basename(path))))
    dt <- as.data.table(suppressMessages(read_excel(path, sheet = "Data for consulates")))
    setnames(dt, clean_column_names(names(dt)))
    dt[, year := year]
    dt[, source_file := basename(path)]
    
    # Identify key columns
    schengen_col <- grep("schengen_state|schengen", names(dt), value = TRUE, ignore.case = TRUE)[1]
    country_col  <- grep("country.*consulate|country.*located|applicant.*country",
                         names(dt), value = TRUE, ignore.case = TRUE)[1]
    if (is.na(country_col)) {
      country_col <- grep("country", names(dt), value = TRUE, ignore.case = TRUE)[1]
    }
    applied_col  <- grep("uniform.*visa.*applied|applied.*uniform",
                         names(dt), value = TRUE, ignore.case = TRUE)[1]
    issued_col   <- grep("uniform.*visa.*issued|issued.*uniform",
                         names(dt), value = TRUE, ignore.case = TRUE)[1]
    not_issued_col <- grep("not.*issued.*rate|rejection.*rate|refusal.*rate",
                           names(dt), value = TRUE, ignore.case = TRUE)[1]
    
    # Keep Netherlands records only
    if (!is.na(schengen_col)) {
      dt <- dt[grepl("Netherlands|Nederland", get(schengen_col), ignore.case = TRUE)]
    }
    
    if (is.na(country_col) || nrow(dt) == 0) return(NULL)
    
    out <- dt[, .(
      country     = as.character(get(country_col)),
      applications = as.numeric(get(applied_col %||% country_col)),
      issued       = as.numeric(get(issued_col %||% country_col)),
      not_issued_rate = as.numeric(get(not_issued_col %||% country_col)),
      year         = year
    )]
    
    # Clean country names for matching
    out[, country_clean := tolower(trimws(country))]
    out[, country_clean := gsub("\\s*\\(.*\\)", "", country_clean)]
    
    return(out)
  })
  
  rbindlist(all_visa, fill = TRUE)
}

# ============================================================
# 5. LOAD INSTRUMENT DATA (from build_instrument.py output)
# ============================================================

#' Load the field-level instrument and merge crosswalks
#' @param work_dir Working directory where instrument CSV files live
load_instrument <- function(work_dir = ".") {
  inst_path <- file.path(work_dir, "instrument_values.csv")
  
  if (!file.exists(inst_path)) {
    warning("Instrument file not found at ", inst_path,
            ". Using fallback aggregate instrument from IND visa data.")
    return(NULL)
  }
  
  inst <- fread(inst_path)
  setnames(inst, trimws(names(inst)))
  
  # ISCED-F field name to DUO field crosswalk
  # The instrument CSV uses ISCED-F 2013 field names. Map to DUO field names.
  # Key design decisions:
  #   - ISCED-F 04 (Recht/administratie/handel) covers BOTH law AND economics in DUO.
  #     We duplicate the row so both "recht" and "economie" get the same instrument value.
  #   - ISCED-F 06 (Informatica) maps to "techniek" because CS programs in Dutch
  #     universities are predominantly housed in engineering/technical faculties.
  #   - "Onderwijsrichting onbekend" (unknown field) is excluded — it is a catch-all
  #     with a flat 50/50 herkomst split unrepresentative of any actual field.
  isced_to_duo <- function(isf) {
    isf <- as.character(isf)
    # Match on the leading ISCED-F number (01-10)
    prefix <- substr(trimws(isf), 1, 2)
    switch(prefix,
      "01" = "onderwijs",
      "02" = "taal en cultuur",
      "03" = "gedrag en maatschappij",
      "04" = c("economie", "recht"),       # ISCED-F 04 covers both — duplicate row
      "05" = "natuur",
      "06" = "techniek",                    # Informatica → engineering/technical
      "07" = "techniek",
      "08" = "landbouw en natuurlijke omgeving",
      "09" = "gezondheidszorg",
      "10" = "sectoroverstijgend",
      NA_character_                         # "Onderwijsrichting onbekend" excluded
    )
  }
  
  # Map fields — may return multiple DUO fields per ISCED-F field (e.g. field 04)
  inst[, duo_field := sapply(field, isced_to_duo, simplify = FALSE)]
  # Unnest: if a row maps to c("economie", "recht"), duplicate it
  inst <- inst[, .(duo_field = unlist(duo_field)), by = setdiff(names(inst), "duo_field")]
  # Drop rows with NA duo_field (unknown field excluded)
  inst <- inst[!is.na(duo_field)]
  inst[, year := as.integer(year)]
  
  # Warn about multi-mapped fields (informational)
  dup_check <- inst[, .N, by = .(field, duo_field)]
  if (any(duplicated(dup_check$field))) {
    message("  Note: Some ISCED-F fields map to multiple DUO fields (e.g., field 04 Recht/administratie -> both 'economie' and 'recht')")
  }
  
  # Return with columns: duo_field, year, Z_field, Z_agg
  return(inst[, .(duo_field, year, Z_field, Z_agg)])
}

# ============================================================
# 6. MERGE LISS WORK + INCOME + DUO + INSTRUMENT
# ============================================================

merge_all <- function(liss_work, liss_income, duo, visa, instrument = NULL) {
  # Merge LISS work and income at person-wave level
  liss <- merge(liss_work, liss_income,
                by = c("nomem_encr", "wave", "survey_year"),
                all.x = TRUE)
  
  # Take the first listed DUO field for each person
  liss[, duo_field := gsub(" \\|.*$", "", duo_field_list)]
  
  # Filter: keep only persons with valid duo_field
  liss <- liss[!is.na(duo_field) & nchar(duo_field) > 0]
  
  # Compute field-level international share from DUO (pooling WO+HBO)
  field_share <- duo[!is.na(is_international) & !is.na(graduates), .(
    total_grads     = sum(graduates, na.rm = TRUE),
    intl_grads      = sum(fifelse(is_international, graduates, 0), na.rm = TRUE),
    n_programs      = uniqueN(opleidingscode_actueel),
    n_intl_programs = uniqueN(opleidingscode_actueel[is_international == TRUE])
  ), by = .(duo_field, year)]
  
  field_share[, share_int := intl_grads / total_grads]
  field_share[, share_int_programs := n_intl_programs / n_programs]
  
  # Merge field shares to LISS
  liss <- merge(liss, field_share,
                by.x = c("duo_field", "survey_year"),
                by.y = c("duo_field", "year"),
                all.x = TRUE)
  
  # Merge field-level instrument
  if (!is.null(instrument) && nrow(instrument) > 0) {
    liss <- merge(liss, instrument,
                  by.x = c("duo_field", "survey_year"),
                  by.y = c("duo_field", "year"),
                  all.x = TRUE)
  }
  
  # Fallback: compute aggregate instrument from IND visa data
  if (!"Z_field" %in% names(liss) || all(is.na(liss$Z_field))) {
    visa_agg <- visa[, .(
      avg_acceptance_rate = 1 - mean(not_issued_rate, na.rm = TRUE)
    ), by = .(year)]
    
    liss <- merge(liss, visa_agg,
                  by.x = "survey_year", by.y = "year", all.x = TRUE)
    liss[, Z_field := avg_acceptance_rate]
    liss[, Z_agg := avg_acceptance_rate]
    message("Using fallback aggregate instrument (same for all fields)")
  }
  
  # Also add Z as alias for Z_field for backward compatibility
  liss[, Z := Z_field]
  
  # Prepare analysis variables
  # log_income: natural log of personal gross ANNUAL income
  # LISS Economic Situation module reports total gross wages in the reference year (annual)
  liss[personal_gross_annual_income > 0 & !is.na(personal_gross_annual_income), 
       log_income := log(personal_gross_annual_income)]
  liss[is.na(log_income), log_income := NA_real_]
  
  # Education level dummies (derived from field + typical education for that field)
  # LISS doesn't always have explicit education level; use broad_field pattern
  liss[, edu_hbo := as.integer(grepl("hbo|HBO", broad_field_list) |
         broad_field_list %in% c("services_other"))]
  liss[, edu_wo := as.integer(grepl("stem|economics|health|education",
         broad_field_list))]
  liss[is.na(edu_hbo), edu_hbo := 0]
  liss[is.na(edu_wo), edu_wo := 0]
  
  # Add age-squared
  liss[, age_sq := age^2]
  
  return(liss)
}

# ============================================================
# 7. CBS NATIONALITY SHARES (from EthnicalMakeup)
# ============================================================

prepare_cbs_nationality_shares <- function(data_dir) {
  cbs_path <- file.path(data_dir, "cbs_85124NED_2024_top15.csv")
  if (file.exists(cbs_path)) {
    return(fread(cbs_path))
  }
  
  # Use EthnicalMakeup data to compute shares
  eth_path <- file.path(data_dir, "CBS Incoming Student Ethnical Makeup",
    "Verblijfsvergunningen_voor_bepaalde_tijd_19052026_175309.csv")
  
  if (file.exists(eth_path)) {
    eth <- fread(eth_path, sep = ";")
    setnames(eth, trimws(names(eth)))
    # Standardize: Nationaliteit has trailing spaces
    eth[, Nationaliteit := trimws(Nationaliteit)]
    eth[, Perioden := gsub("\\*$", "", Perioden)]
    
    # Get most recent year's shares
    recent <- eth[Perioden == "2023", .(
      nationality = Nationaliteit,
      students = as.numeric(gsub("[^0-9]", "",
        `Verblijfsvergunning regulier naar motief/Studie (aantal)`))
    )]
    recent <- recent[!is.na(students) & students > 0]
    recent[, share_of_total := students / sum(students)]
    recent[, year := 2024]
    return(recent)
  }
  
  # Fallback: Nuffic 2024/25 top-15
  data.table(
    nationality = c("German", "Italian", "Romanian", "Spanish", "Chinese",
                     "Polish", "Bulgarian", "Belgian", "French", "Greek",
                     "Indian", "Turkish", "Hungarian", "Portuguese", "Lithuanian"),
    students   = c(19960, 8560, 7760, 6510, 6120,
                    5980, 5450, 4970, 4940, 4670,
                    3550, 3400, 3330, 2890, 2110),
    year       = 2024
  )[, share_of_total := students / sum(students)]
}

# ============================================================
# 8. MAIN PIPELINE
# ============================================================

#' Run the complete data preparation pipeline
#'
#' @param data_dir Path to raw data directory
#' @param output_dir Path to output directory for tidied data
#' @return Invisibly returns a list of all prepared datasets
prepare_all_data <- function(data_dir = default_data_dir(),
                             output_dir = "data_tidy") {
  
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  
  message("=== DATA PREPARATION PIPELINE ===")
  message("Data directory: ", data_dir)
  message("Output directory: ", output_dir)
  
  # 1. LISS Work and Schooling
  message("\n[1/6] Reading LISS Work and Schooling...")
  liss_work <- tryCatch(read_liss_work(data_dir),
    error = function(e) { warning("LISS work data: ", e$message); data.table() })
  message("  Rows: ", nrow(liss_work))
  
  # 2. LISS Income
  message("\n[2/6] Reading LISS Economic Situation/Income...")
  liss_income <- tryCatch(read_liss_income(data_dir),
    error = function(e) { warning("LISS income data: ", e$message); data.table() })
  message("  Rows: ", nrow(liss_income))
  
  # 3. DUO Graduates (WO + HBO)
  message("\n[3/6] Reading DUO Graduates (WO + HBO)...")
  duo <- tryCatch(read_duo_graduates(data_dir),
    error = function(e) { warning("DUO data: ", e$message); data.table() })
  message("  Rows: ", nrow(duo))
  
  # 4. IND Visa
  message("\n[4/6] Reading IND Visa Acceptance Rates...")
  visa <- tryCatch(read_ind_visa(data_dir),
    error = function(e) { warning("IND visa data: ", e$message); data.table() })
  message("  Rows: ", nrow(visa))
  
  # 5. Load instrument
  message("\n[5/6] Loading field-level instrument...")
  instrument <- tryCatch(load_instrument("."),
    error = function(e) { warning("Instrument load failed: ", e$message); NULL })
  if (!is.null(instrument)) {
    message("  Instrument rows: ", nrow(instrument))
    message("  Fields: ", paste(unique(instrument$duo_field), collapse=", "))
  } else {
    message("  No instrument file found, will use aggregate fallback")
  }
  
  # 6. CBS Nationality Shares
  message("\n[6/6] Preparing CBS nationality shares...")
  cbs_shares <- prepare_cbs_nationality_shares(data_dir)
  message("  Nationalities: ", nrow(cbs_shares))
  
  # Merge
  message("\n=== MERGING DATASETS ===")
  merged <- merge_all(liss_work, liss_income, duo, visa, instrument)
  message("  Merged rows: ", nrow(merged))
  message("  Unique persons: ", uniqueN(merged$nomem_encr))
  
  # Diagnostic: show instrument variation
  if ("Z_field" %in% names(merged)) {
    message("\n--- Instrument Diagnostics ---")
    message("  Z_field range: ", sprintf("%.4f - %.4f",
      min(merged$Z_field, na.rm=TRUE), max(merged$Z_field, na.rm=TRUE)))
    message("  Z_field mean:  ", sprintf("%.4f", mean(merged$Z_field, na.rm=TRUE)))
    message("  Z_field SD:    ", sprintf("%.4f", sd(merged$Z_field, na.rm=TRUE)))
    message("  Unique Z_field values across fields: ",
      uniqueN(merged[, .(duo_field, survey_year, Z_field)]))
  }
  
  # Write outputs
  message("\n=== WRITING OUTPUTS ===")
  
  files_written <- c()
  
  if (nrow(liss_work) > 0) {
    fwrite(liss_work, file.path(output_dir, "liss_work_tidy.csv"))
    files_written <- c(files_written, "liss_work_tidy.csv")
  }
  
  if (nrow(liss_income) > 0) {
    fwrite(liss_income, file.path(output_dir, "liss_income_tidy.csv"))
    files_written <- c(files_written, "liss_income_tidy.csv")
  }
  
  if (nrow(merged) > 0) {
    fwrite(merged, file.path(output_dir, "liss_work_income_merged.csv"))
    files_written <- c(files_written, "liss_work_income_merged.csv")
  }
  
  if (nrow(duo) > 0) {
    fwrite(duo, file.path(output_dir, "duo_graduates_tidy.csv"))
    files_written <- c(files_written, "duo_graduates_tidy.csv")
  }
  
  if (nrow(visa) > 0) {
    fwrite(visa, file.path(output_dir, "ind_visa_consulates_tidy.csv"))
    files_written <- c(files_written, "ind_visa_consulates_tidy.csv")
  }
  
  if (nrow(cbs_shares) > 0) {
    fwrite(cbs_shares, file.path(output_dir, "cbs_85124NED_2024_top15.csv"))
    files_written <- c(files_written, "cbs_85124NED_2024_top15.csv")
  }
  
  # Also copy instrument files to output_dir for thesis.Rmd
  for (f in c("instrument_values.csv", "cbs_field_shares.csv",
              "herkomst_visa_rates.csv", "country_crosswalk.csv")) {
    if (file.exists(f)) {
      file.copy(f, file.path(output_dir, f), overwrite = TRUE)
      files_written <- c(files_written, f)
    }
  }
  
  message("Written to ", normalizePath(output_dir), ":")
  for (f in files_written) message("  - ", f)
  
  # Quality report
  quality <- data.table(
    dataset = c("liss_work", "liss_income", "merged", "duo", "visa", "cbs_shares"),
    rows    = c(nrow(liss_work), nrow(liss_income), nrow(merged),
                nrow(duo), nrow(visa), nrow(cbs_shares))
  )
  fwrite(quality, file.path(output_dir, "quality_report.csv"))
  message("  - quality_report.csv")
  
  message("\n=== DONE ===")
  
  invisible(list(
    liss_work  = liss_work,
    liss_income = liss_income,
    merged      = merged,
    duo         = duo,
    visa        = visa,
    cbs_shares  = cbs_shares,
    instrument  = instrument
  ))
}

# ============================================================
# COMMAND-LINE ENTRY POINT
# ============================================================

if (sys.nframe() == 0 && !interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  data_dir  <- if (length(args) >= 1) args[[1]] else default_data_dir()
  output_dir <- if (length(args) >= 2) args[[2]] else "data_tidy"
  prepare_all_data(data_dir, output_dir)
}

# =============================================================================
# KURIKULUM GENERATOR - R PACKAGE REQUIREMENTS
# =============================================================================

# Core Shiny
required_packages <- c(
  # Shiny Framework
  "shiny",
  "shinydashboard",
  "shinyWidgets",
  "shinyjs",
  
  # Database
  "DBI",
  "RSQLite",
  "pool",
  
  # Data Manipulation
  "dplyr",
  "tidyr",
  "purrr",
  "stringr",
  "lubridate",
  
  # AI & API
  "httr",
  "jsonlite",
  "curl",
  
  # Export & Reports
  "rmarkdown",
  "knitr",
  "pagedown",
  "officer",      # DOCX
  "flextable",    # Tables in DOCX
  "writexl",      # Excel
  
  # UI Components
  "DT",
  "plotly",
  "htmltools",
  "htmlwidgets",
  
  # Configuration
  "config",
  "dotenv",
  "logger",
  
  # Utilities
  "glue",
  "here"
)

# Installation function
install_if_missing <- function(packages) {
  new_packages <- packages[!(packages %in% installed.packages()[,"Package"])]
  
  if(length(new_packages) > 0) {
    cat("\n📦 Installing missing packages:\n")
    print(new_packages)
    install.packages(new_packages, dependencies = TRUE)
    cat("\n✅ Installation complete!\n")
  } else {
    cat("\n✅ All packages already installed!\n")
  }
}

# Load all packages
load_packages <- function(packages) {
  cat("\n📚 Loading packages...\n")
  
  loaded <- sapply(packages, function(pkg) {
    result <- suppressPackageStartupMessages(
      suppressWarnings(library(pkg, character.only = TRUE, quietly = TRUE))
    )
    return(TRUE)
  })
  
  cat("\n✅ All packages loaded successfully!\n")
  return(invisible(loaded))
}

# Main execution
cat("\n" , rep("=", 60), "\n", sep = "")
cat("   KURIKULUM GENERATOR - Package Setup\n")
cat(rep("=", 60), "\n\n", sep = "")

cat("Total packages required:", length(required_packages), "\n\n")

# Check and install
install_if_missing(required_packages)

# Load all
load_packages(required_packages)

cat("\n", rep("=", 60), "\n", sep = "")
cat("   Setup Complete! Ready to develop.\n")
cat(rep("=", 60), "\n\n", sep = "")

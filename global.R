# =============================================================================
# KURIKULUM GENERATOR - GLOBAL CONFIGURATION
# =============================================================================

# Load packages
suppressPackageStartupMessages({
  library(shiny)
  library(shinydashboard)
  library(shinyWidgets)
  library(shinyjs)
  library(DBI)
  library(RSQLite)
  library(pool)
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(glue)
  library(httr)
  library(jsonlite)
  library(DT)
  library(plotly)
})

# Load environment variables
if (file.exists(".env")) {
  readRenviron(".env")
}

# Configuration
CONFIG <- list(
  # Database
  db_path = Sys.getenv("DB_PATH", "database/kurikulum.db"),
  
  # API Keys
  anthropic_key = Sys.getenv("ANTHROPIC_API_KEY", ""),
  openai_key = Sys.getenv("OPENAI_API_KEY", ""),
  
  # AI Models
  claude_model = Sys.getenv("AI_MODEL_CLAUDE", "claude-sonnet-4-20250514"),
  gpt_model = Sys.getenv("AI_MODEL_GPT", "gpt-4"),
  max_tokens = as.integer(Sys.getenv("AI_MAX_TOKENS", "8000")),
  temperature = as.numeric(Sys.getenv("AI_TEMPERATURE", "0.7")),
  
  # Paths
  export_path = Sys.getenv("EXPORT_PATH", "exports/"),
  template_path = Sys.getenv("TEMPLATE_PATH", "templates/"),
  
  # App
  debug = as.logical(Sys.getenv("DEBUG_MODE", "TRUE"))
)

# Load helper functions
source("R/database.R", local = TRUE)
source("R/ai_agents.R", local = TRUE)
source("R/export.R", local = TRUE) 

# Load data
SUBJECTS <- read.csv("data/subjects.csv", stringsAsFactors = FALSE, encoding = "UTF-8")
GRADES <- read.csv("data/grades.csv", stringsAsFactors = FALSE, encoding = "UTF-8")
COUNTRIES <- read.csv("data/countries.csv", stringsAsFactors = FALSE, encoding = "UTF-8")

# Initialize database
initialize_database()

# Startup message
if (CONFIG$debug) {
  cat("\n", rep("=", 60), "\n", sep = "")
  cat("   KURIKULUM GENERATOR - Started\n")
  cat(rep("=", 60), "\n\n", sep = "")
  cat("📊 Loaded:", nrow(SUBJECTS), "subjects,", nrow(GRADES), "grades,", nrow(COUNTRIES), "countries\n")
  cat("🗄️  Database:", CONFIG$db_path, "\n")
  cat("🤖 Claude Model:", CONFIG$claude_model, "\n")
  cat(rep("=", 60), "\n\n", sep = "")
}


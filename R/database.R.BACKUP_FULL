
# =============================================================================
# DATABASE HELPER FUNCTIONS - FINAL CLEAN
# =============================================================================

# Initialize database and create tables
initialize_database <- function() {
  db_path <- CONFIG$db_path
  
  db_dir <- dirname(db_path)
  if (!dir.exists(db_dir)) {
    dir.create(db_dir, recursive = TRUE)
  }
  
  con <- dbConnect(RSQLite::SQLite(), db_path)
  on.exit(dbDisconnect(con), add = TRUE)
  
  # Create curricula table
  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS curricula (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      subject_id INTEGER NOT NULL,
      subject_name TEXT NOT NULL,
      grade INTEGER NOT NULL,
      academic_year TEXT,
      hours_per_week INTEGER,
      weeks_per_year INTEGER,
      total_hours INTEGER,
      description TEXT,
      philosophy TEXT,
      learning_outcomes TEXT,
      content_structure TEXT,
      methodology TEXT,
      assessment TEXT,
      resources TEXT,
      azerbaijan_standards TEXT,
      international_standards TEXT,
      reference_countries TEXT,
      generated_by TEXT DEFAULT 'AI',
      ai_model TEXT,
      creation_method TEXT,
      status TEXT DEFAULT 'draft',
      pdf_path TEXT,
      docx_path TEXT,
      html_path TEXT,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      created_by TEXT
    )
  ")
  
  # Create generation_logs table
  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS generation_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      curriculum_id INTEGER,
      ai_model TEXT,
      prompt TEXT,
      response TEXT,
      tokens_used INTEGER,
      duration_seconds REAL,
      status TEXT,
      error_message TEXT,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (curriculum_id) REFERENCES curricula(id)
    )
  ")
  
  # Create user_preferences table
  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS user_preferences (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      preference_key TEXT UNIQUE NOT NULL,
      preference_value TEXT,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  ")
  
  if (CONFIG$debug) {
    cat("✅ Database initialized:", db_path, "\n")
  }
  
  return(invisible(TRUE))
}

# Get database connection
get_db_connection <- function() {
  con <- dbConnect(RSQLite::SQLite(), CONFIG$db_path)
  return(con)
}

# Save curriculum to database
save_curriculum <- function(curriculum_data) {
  con <- get_db_connection()
  on.exit(dbDisconnect(con), add = TRUE)
  
  # NULL checks with defaults
  params <- list(
    ifelse(is.null(curriculum_data$name), "Untitled", curriculum_data$name),
    ifelse(is.null(curriculum_data$subject_id), 1, curriculum_data$subject_id),
    ifelse(is.null(curriculum_data$subject_name), "Unknown", curriculum_data$subject_name),
    ifelse(is.null(curriculum_data$grade), 1, curriculum_data$grade),
    ifelse(is.null(curriculum_data$academic_year), "2024-2025", curriculum_data$academic_year),
    ifelse(is.null(curriculum_data$hours_per_week), 4, curriculum_data$hours_per_week),
    ifelse(is.null(curriculum_data$weeks_per_year), 36, curriculum_data$weeks_per_year),
    ifelse(is.null(curriculum_data$total_hours), 144, curriculum_data$total_hours),
    ifelse(is.null(curriculum_data$description), "", curriculum_data$description),
    ifelse(is.null(curriculum_data$philosophy), "", curriculum_data$philosophy),
    ifelse(is.null(curriculum_data$learning_outcomes), "", curriculum_data$learning_outcomes),
    ifelse(is.null(curriculum_data$content_structure), "", curriculum_data$content_structure),
    ifelse(is.null(curriculum_data$methodology), "", curriculum_data$methodology),
    ifelse(is.null(curriculum_data$assessment), "", curriculum_data$assessment),
    ifelse(is.null(curriculum_data$resources), "", curriculum_data$resources),
    ifelse(is.null(curriculum_data$azerbaijan_standards), "", curriculum_data$azerbaijan_standards),
    ifelse(is.null(curriculum_data$international_standards), "", curriculum_data$international_standards),
    ifelse(is.null(curriculum_data$reference_countries), "", curriculum_data$reference_countries),
    ifelse(is.null(curriculum_data$generated_by), "AI", curriculum_data$generated_by),
    ifelse(is.null(curriculum_data$ai_model), "Unknown", curriculum_data$ai_model),
    ifelse(is.null(curriculum_data$creation_method), "AI", curriculum_data$creation_method),
    ifelse(is.null(curriculum_data$status), "draft", curriculum_data$status),
    ifelse(is.null(curriculum_data$created_by), "system", curriculum_data$created_by)
  )
  
  query <- "
    INSERT INTO curricula (
      name, subject_id, subject_name, grade, academic_year,
      hours_per_week, weeks_per_year, total_hours,
      description, philosophy, learning_outcomes, content_structure,
      methodology, assessment, resources,
      azerbaijan_standards, international_standards, reference_countries,
      generated_by, ai_model, creation_method, status, created_by
    ) VALUES (
      ?, ?, ?, ?, ?,
      ?, ?, ?,
      ?, ?, ?, ?,
      ?, ?, ?,
      ?, ?, ?,
      ?, ?, ?, ?, ?
    )
  "
  
  dbExecute(con, query, params = params)
  
  curriculum_id <- dbGetQuery(con, "SELECT last_insert_rowid() as id")$id
  
  return(curriculum_id)
}

# Get all curricula
get_all_curricula <- function() {
  con <- get_db_connection()
  on.exit(dbDisconnect(con), add = TRUE)
  
  query <- "
    SELECT 
      id, name, subject_name, grade, academic_year,
      hours_per_week, total_hours, status,
      created_at, ai_model
    FROM curricula
    ORDER BY created_at DESC
  "
  
  curricula <- dbGetQuery(con, query)
  return(curricula)
}

# Get curriculum by ID
get_curriculum_by_id <- function(curriculum_id) {
  con <- get_db_connection()
  on.exit(dbDisconnect(con), add = TRUE)
  
  query <- "SELECT * FROM curricula WHERE id = ?"
  curriculum <- dbGetQuery(con, query, params = list(curriculum_id))
  
  return(curriculum)
}

# Update curriculum
update_curriculum <- function(curriculum_id, updates) {
  con <- get_db_connection()
  on.exit(dbDisconnect(con), add = TRUE)
  
  set_clause <- paste(names(updates), "= ?", collapse = ", ")
  
  query <- glue("
    UPDATE curricula 
    SET {set_clause}, updated_at = CURRENT_TIMESTAMP
    WHERE id = ?
  ")
  
  params <- c(unname(updates), curriculum_id)
  
  dbExecute(con, query, params = params)
  
  return(invisible(TRUE))
}

# Delete curriculum
delete_curriculum <- function(curriculum_id) {
  con <- get_db_connection()
  on.exit(dbDisconnect(con), add = TRUE)
  
  dbExecute(con, "DELETE FROM curricula WHERE id = ?", params = list(curriculum_id))
  
  return(invisible(TRUE))
}

# Log AI generation
log_ai_generation <- function(curriculum_id, ai_model, prompt, response, 
                               tokens_used, duration, status, error_msg = NULL) {
  con <- get_db_connection()
  on.exit(dbDisconnect(con), add = TRUE)
  
  query <- "
    INSERT INTO generation_logs (
      curriculum_id, ai_model, prompt, response,
      tokens_used, duration_seconds, status, error_message
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
  "
  
  dbExecute(con, query, params = list(
    curriculum_id, ai_model, prompt, response,
    tokens_used, duration, status, error_msg
  ))
  
  return(invisible(TRUE))
}

# Get statistics
get_curriculum_statistics <- function() {
  con <- get_db_connection()
  on.exit(dbDisconnect(con), add = TRUE)
  
  stats <- list()
  
  stats$total <- dbGetQuery(con, "SELECT COUNT(*) as count FROM curricula")$count
  
  stats$by_status <- dbGetQuery(con, "
    SELECT status, COUNT(*) as count 
    FROM curricula 
    GROUP BY status
  ")
  
  stats$by_subject <- dbGetQuery(con, "
    SELECT subject_name, COUNT(*) as count 
    FROM curricula 
    GROUP BY subject_name
    ORDER BY count DESC
  ")
  
  stats$by_grade <- dbGetQuery(con, "
    SELECT grade, COUNT(*) as count 
    FROM curricula 
    GROUP BY grade
    ORDER BY grade
  ")
  
  stats$recent <- dbGetQuery(con, "
    SELECT COUNT(*) as count 
    FROM curricula 
    WHERE created_at >= datetime('now', '-7 days')
  ")$count
  
  return(stats)
}

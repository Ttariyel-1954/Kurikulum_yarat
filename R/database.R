# =============================================================================
# DATABASE FUNCTIONS - SQLite
# =============================================================================

library(DBI)
library(RSQLite)
library(glue)

# =============================================================================
# DATABASE INITIALIZATION
# =============================================================================

initialize_database <- function() {
  
  db_dir <- dirname(CONFIG$db_path)
  if (!dir.exists(db_dir)) {
    dir.create(db_dir, recursive = TRUE)
  }
  
  conn <- get_db_connection()
  on.exit(dbDisconnect(conn))
  
  # Create curricula table
  dbExecute(conn, "
    CREATE TABLE IF NOT EXISTS curricula (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      subject_id INTEGER,
      subject_name TEXT,
      grade INTEGER,
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
      generated_by TEXT,
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
  dbExecute(conn, "
    CREATE TABLE IF NOT EXISTS generation_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      curriculum_id INTEGER,
      ai_model TEXT,
      prompt TEXT,
      response TEXT,
      tokens_used INTEGER,
      duration REAL,
      status TEXT,
      error_message TEXT,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (curriculum_id) REFERENCES curricula(id)
    )
  ")
  
  # Create user_preferences table
  dbExecute(conn, "
    CREATE TABLE IF NOT EXISTS user_preferences (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      preference_key TEXT UNIQUE,
      preference_value TEXT,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  ")
  
  cat("✅ Database initialized successfully\n")
  return(TRUE)
}

# =============================================================================
# CONNECTION
# =============================================================================

get_db_connection <- function() {
  conn <- dbConnect(RSQLite::SQLite(), CONFIG$db_path)
  dbExecute(conn, "PRAGMA foreign_keys = ON")
  return(conn)
}

# =============================================================================
# CURRICULUM CRUD OPERATIONS
# =============================================================================

save_curriculum <- function(curriculum_data) {
  conn <- get_db_connection()
  on.exit(dbDisconnect(conn))
  
  # Prepare data with NULL-safe defaults
  name <- ifelse(is.null(curriculum_data$name), "", curriculum_data$name)
  subject_id <- ifelse(is.null(curriculum_data$subject_id), NA, curriculum_data$subject_id)
  subject_name <- ifelse(is.null(curriculum_data$subject_name), "", curriculum_data$subject_name)
  grade <- ifelse(is.null(curriculum_data$grade), NA, curriculum_data$grade)
  academic_year <- ifelse(is.null(curriculum_data$academic_year), "", curriculum_data$academic_year)
  hours_per_week <- ifelse(is.null(curriculum_data$hours_per_week), NA, curriculum_data$hours_per_week)
  weeks_per_year <- ifelse(is.null(curriculum_data$weeks_per_year), NA, curriculum_data$weeks_per_year)
  total_hours <- ifelse(is.null(curriculum_data$total_hours), NA, curriculum_data$total_hours)
  description <- ifelse(is.null(curriculum_data$description), "", curriculum_data$description)
  philosophy <- ifelse(is.null(curriculum_data$philosophy), "", curriculum_data$philosophy)
  learning_outcomes <- ifelse(is.null(curriculum_data$learning_outcomes), "", curriculum_data$learning_outcomes)
  content_structure <- ifelse(is.null(curriculum_data$content_structure), "", curriculum_data$content_structure)
  methodology <- ifelse(is.null(curriculum_data$methodology), "", curriculum_data$methodology)
  assessment <- ifelse(is.null(curriculum_data$assessment), "", curriculum_data$assessment)
  resources <- ifelse(is.null(curriculum_data$resources), "", curriculum_data$resources)
  azerbaijan_standards <- ifelse(is.null(curriculum_data$azerbaijan_standards), "", curriculum_data$azerbaijan_standards)
  international_standards <- ifelse(is.null(curriculum_data$international_standards), "", curriculum_data$international_standards)
  reference_countries <- ifelse(is.null(curriculum_data$reference_countries), "", curriculum_data$reference_countries)
  generated_by <- ifelse(is.null(curriculum_data$generated_by), "AI", curriculum_data$generated_by)
  ai_model <- ifelse(is.null(curriculum_data$ai_model), "Unknown", curriculum_data$ai_model)
  creation_method <- ifelse(is.null(curriculum_data$creation_method), "Unknown", curriculum_data$creation_method)
  status <- ifelse(is.null(curriculum_data$status), "draft", curriculum_data$status)
  created_by <- ifelse(is.null(curriculum_data$created_by), "system", curriculum_data$created_by)
  
  tryCatch({
    result <- dbExecute(conn, "
      INSERT INTO curricula (
        name, subject_id, subject_name, grade, academic_year,
        hours_per_week, weeks_per_year, total_hours,
        description, philosophy, learning_outcomes, content_structure,
        methodology, assessment, resources,
        azerbaijan_standards, international_standards, reference_countries,
        generated_by, ai_model, creation_method, status, created_by
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ", params = list(
      name, subject_id, subject_name, grade, academic_year,
      hours_per_week, weeks_per_year, total_hours,
      description, philosophy, learning_outcomes, content_structure,
      methodology, assessment, resources,
      azerbaijan_standards, international_standards, reference_countries,
      generated_by, ai_model, creation_method, status, created_by
    ))
    
    curriculum_id <- dbGetQuery(conn, "SELECT last_insert_rowid() as id")$id
    return(curriculum_id)
    
  }, error = function(e) {
    warning(glue("Save curriculum error: {e$message}"))
    return(NULL)
  })
}

get_all_curricula <- function() {
  conn <- get_db_connection()
  on.exit(dbDisconnect(conn))
  
  curricula <- dbGetQuery(conn, "
    SELECT * FROM curricula 
    ORDER BY created_at DESC
  ")
  
  return(curricula)
}

get_curriculum_by_id <- function(curriculum_id) {
  conn <- get_db_connection()
  on.exit(dbDisconnect(conn))
  
  curriculum <- dbGetQuery(conn, "
    SELECT * FROM curricula WHERE id = ?
  ", params = list(curriculum_id))
  
  if (nrow(curriculum) == 0) {
    return(NULL)
  }
  
  return(as.list(curriculum[1, ]))
}

update_curriculum <- function(curriculum_id, updates) {
  conn <- get_db_connection()
  on.exit(dbDisconnect(conn))
  
  set_clause <- paste(
    names(updates),
    "= ?",
    collapse = ", "
  )
  
  query <- glue("
    UPDATE curricula 
    SET {set_clause}, updated_at = CURRENT_TIMESTAMP
    WHERE id = ?
  ")
  
  params <- c(as.list(updates), list(curriculum_id))
  
  tryCatch({
    result <- dbExecute(conn, query, params = params)
    return(result > 0)
  }, error = function(e) {
    warning(glue("Update curriculum error: {e$message}"))
    return(FALSE)
  })
}

delete_curriculum <- function(curriculum_id) {
  conn <- get_db_connection()
  on.exit(dbDisconnect(conn))
  
  tryCatch({
    # Delete logs first
    dbExecute(conn, "DELETE FROM generation_logs WHERE curriculum_id = ?", 
              params = list(curriculum_id))
    
    # Delete curriculum
    result <- dbExecute(conn, "DELETE FROM curricula WHERE id = ?", 
                        params = list(curriculum_id))
    
    return(result > 0)
    
  }, error = function(e) {
    warning(glue("Delete curriculum error: {e$message}"))
    return(FALSE)
  })
}

# =============================================================================
# LOGGING
# =============================================================================

log_ai_generation <- function(curriculum_id, ai_model, prompt, response, 
                               tokens_used, duration, status, error_message = NULL) {
  conn <- get_db_connection()
  on.exit(dbDisconnect(conn))
  
  tryCatch({
    dbExecute(conn, "
      INSERT INTO generation_logs (
        curriculum_id, ai_model, prompt, response,
        tokens_used, duration, status, error_message
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ", params = list(
      curriculum_id, ai_model, prompt, response,
      tokens_used, duration, status, error_message
    ))
    
    return(TRUE)
    
  }, error = function(e) {
    warning(glue("Log generation error: {e$message}"))
    return(FALSE)
  })
}

# =============================================================================
# STATISTICS - FIXED
# =============================================================================

get_curriculum_statistics <- function() {
  conn <- get_db_connection()
  on.exit(dbDisconnect(conn))
  
  stats <- list()
  
  # Total count
  stats$total <- dbGetQuery(conn, "SELECT COUNT(*) as count FROM curricula")$count
  
  # By status
  by_status <- dbGetQuery(conn, "
    SELECT status, COUNT(*) as count 
    FROM curricula 
    GROUP BY status
  ")
  
  if (nrow(by_status) > 0) {
    stats$by_status <- setNames(by_status$count, by_status$status)
  } else {
    stats$by_status <- integer(0)
  }
  
  # By subject - FIXED: return numeric vector
  by_subject <- dbGetQuery(conn, "
    SELECT subject_name, COUNT(*) as count 
    FROM curricula 
    WHERE subject_name IS NOT NULL AND subject_name != ''
    GROUP BY subject_name
    ORDER BY count DESC
  ")
  
  if (nrow(by_subject) > 0) {
    stats$by_subject <- setNames(as.numeric(by_subject$count), by_subject$subject_name)
  } else {
    stats$by_subject <- numeric(0)
  }
  
  # By grade - FIXED: return numeric vector
  by_grade <- dbGetQuery(conn, "
    SELECT grade, COUNT(*) as count 
    FROM curricula 
    WHERE grade IS NOT NULL
    GROUP BY grade 
    ORDER BY grade
  ")
  
  if (nrow(by_grade) > 0) {
    stats$by_grade <- setNames(as.numeric(by_grade$count), as.character(by_grade$grade))
  } else {
    stats$by_grade <- numeric(0)
  }
  
  # Recent (last 10)
  stats$recent <- dbGetQuery(conn, "
    SELECT id, name, subject_name, grade, created_at 
    FROM curricula 
    ORDER BY created_at DESC 
    LIMIT 10
  ")
  
  return(stats)
}

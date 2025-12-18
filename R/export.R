# =============================================================================
# PROFESSIONAL EXPORT FUNCTIONS
# =============================================================================

library(rmarkdown)
library(glue)

# Export to beautiful HTML
export_curriculum_html <- function(curriculum_data, curriculum_content, 
                                   generation_info) {
  
  # Create exports directory
  if (!dir.exists("exports")) {
    dir.create("exports", recursive = TRUE)
  }
  
  # Generate filename
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  safe_subject <- gsub("[^A-Za-z0-9_-]", "", curriculum_data$subject_name)
  filename <- glue("{safe_subject}_{curriculum_data$grade}sinif_{timestamp}.html")
  output_path <- file.path("exports", filename)
  
  # Prepare parameters
  params_list <- list(
    curriculum_name = curriculum_data$name,
    subject = curriculum_data$subject_name,
    grade = curriculum_data$grade,
    hours_per_week = curriculum_data$hours_per_week,
    weeks_per_year = curriculum_data$weeks_per_year,
    total_hours = curriculum_data$total_hours,
    academic_year = curriculum_data$academic_year,
    reference_countries = curriculum_data$reference_countries,
    content = curriculum_content,
    ai_model = generation_info$method,
    generation_date = Sys.time(),
    tokens_used = generation_info$claude_tokens + generation_info$gpt_tokens + generation_info$synthesis_tokens,
    duration = generation_info$total_duration
  )
  
  # Render
  tryCatch({
    rmarkdown::render(
      input = "templates/curriculum_template.Rmd",
      output_file = basename(output_path),
      output_dir = dirname(output_path),
      params = params_list,
      quiet = TRUE,
      envir = new.env()
    )
    
    return(list(
      success = TRUE,
      path = output_path,
      filename = filename,
      size = file.size(output_path)
    ))
    
  }, error = function(e) {
    return(list(
      success = FALSE,
      error = as.character(e)
    ))
  })
}

# Export comparison HTML
export_comparison_html <- function(curriculum_data, claude_content, gpt_content,
                                    claude_tokens, gpt_tokens, 
                                    claude_duration, gpt_duration) {
  
  if (!dir.exists("exports")) {
    dir.create("exports", recursive = TRUE)
  }
  
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  safe_subject <- gsub("[^A-Za-z0-9_-]", "", curriculum_data$subject_name)
  filename <- glue("{safe_subject}_{curriculum_data$grade}sinif_COMPARISON_{timestamp}.html")
  output_path <- file.path("exports", filename)
  
  params_list <- list(
    curriculum_name = curriculum_data$name,
    subject = curriculum_data$subject_name,
    grade = curriculum_data$grade,
    hours_per_week = curriculum_data$hours_per_week,
    weeks_per_year = curriculum_data$weeks_per_year,
    total_hours = curriculum_data$total_hours,
    academic_year = curriculum_data$academic_year,
    reference_countries = curriculum_data$reference_countries,
    claude_content = claude_content,
    gpt_content = gpt_content,
    claude_tokens = claude_tokens,
    gpt_tokens = gpt_tokens,
    claude_duration = claude_duration,
    gpt_duration = gpt_duration,
    generation_date = Sys.time()
  )
  
  tryCatch({
    rmarkdown::render(
      input = "templates/comparison_template.Rmd",
      output_file = basename(output_path),
      output_dir = dirname(output_path),
      params = params_list,
      quiet = TRUE,
      envir = new.env()
    )
    
    return(list(
      success = TRUE,
      path = output_path,
      filename = filename,
      size = file.size(output_path)
    ))
    
  }, error = function(e) {
    return(list(
      success = FALSE,
      error = as.character(e)
    ))
  })
}

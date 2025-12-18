# =============================================================================
# DUAL AI AGENTS - COMPARISON MODE
# =============================================================================

# Call Claude Sonnet 4.5
call_claude_api <- function(prompt, system_prompt = NULL, temperature = NULL, max_tokens = NULL) {
  
  if (CONFIG$anthropic_key == "" || CONFIG$anthropic_key == "your_claude_api_key_here") {
    stop("❌ Claude API key konfiqurasiya edilməyib!")
  }
  
  start_time <- Sys.time()
  
  temp <- ifelse(is.null(temperature), CONFIG$temperature, temperature)
  tokens <- ifelse(is.null(max_tokens), CONFIG$max_tokens, max_tokens)
  
  body <- list(
    model = CONFIG$claude_model,
    max_tokens = tokens,
    temperature = temp,
    messages = list(list(role = "user", content = prompt))
  )
  
  if (!is.null(system_prompt)) {
    body$system <- system_prompt
  }
  
  tryCatch({
    response <- POST(
      url = "https://api.anthropic.com/v1/messages",
      add_headers(
        "x-api-key" = CONFIG$anthropic_key,
        "anthropic-version" = "2023-06-01",
        "content-type" = "application/json"
      ),
      body = toJSON(body, auto_unbox = TRUE),
      encode = "json"
    )
    
    if (status_code(response) != 200) {
      error_content <- content(response, "text", encoding = "UTF-8")
      stop(glue("Claude API xətası [{status_code(response)}]: {error_content}"))
    }
    
    result <- content(response, "parsed", encoding = "UTF-8")
    text_content <- result$content[[1]]$text
    duration <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
    
    return(list(
      success = TRUE,
      text = text_content,
      model = CONFIG$claude_model,
      tokens_used = result$usage$input_tokens + result$usage$output_tokens,
      duration = duration,
      error = NULL
    ))
    
  }, error = function(e) {
    duration <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
    return(list(
      success = FALSE,
      text = NULL,
      model = CONFIG$claude_model,
      tokens_used = 0,
      duration = duration,
      error = as.character(e)
    ))
  })
}

# Call GPT-4o
call_gpt_api <- function(prompt, system_prompt = NULL, temperature = NULL, max_tokens = NULL) {
  
  if (CONFIG$openai_key == "" || CONFIG$openai_key == "your_openai_api_key_here") {
    stop("❌ OpenAI API key konfiqurasiya edilməyib!")
  }
  
  start_time <- Sys.time()
  
  temp <- ifelse(is.null(temperature), CONFIG$temperature, temperature)
  tokens <- ifelse(is.null(max_tokens), CONFIG$max_tokens, max_tokens)
  
  messages <- list()
  
  if (!is.null(system_prompt)) {
    messages <- append(messages, list(list(role = "system", content = system_prompt)))
  }
  
  messages <- append(messages, list(list(role = "user", content = prompt)))
  
  body <- list(
    model = CONFIG$gpt_model,
    messages = messages,
    max_tokens = tokens,
    temperature = temp
  )
  
  tryCatch({
    response <- POST(
      url = "https://api.openai.com/v1/chat/completions",
      add_headers(
        "Authorization" = paste("Bearer", CONFIG$openai_key),
        "Content-Type" = "application/json"
      ),
      body = toJSON(body, auto_unbox = TRUE),
      encode = "json"
    )
    
    if (status_code(response) != 200) {
      error_content <- content(response, "text", encoding = "UTF-8")
      stop(glue("GPT API xətası [{status_code(response)}]: {error_content}"))
    }
    
    result <- content(response, "parsed", encoding = "UTF-8")
    text_content <- result$choices[[1]]$message$content
    duration <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
    
    return(list(
      success = TRUE,
      text = text_content,
      model = CONFIG$gpt_model,
      tokens_used = result$usage$total_tokens,
      duration = duration,
      error = NULL
    ))
    
  }, error = function(e) {
    duration <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
    return(list(
      success = FALSE,
      text = NULL,
      model = CONFIG$gpt_model,
      tokens_used = 0,
      duration = duration,
      error = as.character(e)
    ))
  })
}

# Generate curriculum - DUAL AI WITH COMPARISON
generate_curriculum_dual_ai <- function(subject, grade, hours_per_week, weeks_per_year, 
                                        reference_countries = NULL, special_focus = NULL) {
  
  # Build prompt
  prompt <- build_curriculum_prompt(subject, grade, hours_per_week, weeks_per_year, 
                                     reference_countries, special_focus)
  
  system_prompt <- "Siz professional təhsil ekspertisiniz. Azərbaycan və beynəlxalq təhsil standartlarına əsasən ətraflı və tətbiq edilə bilən kurikulum hazırlayırsınız. Azərbaycan dilində, düzgün terminologiya ilə yazın."
  
  # Check API keys
  claude_available <- !(CONFIG$anthropic_key == "" || CONFIG$anthropic_key == "your_claude_api_key_here")
  gpt_available <- !(CONFIG$openai_key == "" || CONFIG$openai_key == "your_openai_api_key_here")
  
  results <- list(
    claude = NULL,
    gpt = NULL,
    final = NULL
  )
  
  # Call Claude
  if (claude_available) {
    cat("🤖 Claude Sonnet 4.5 yaradır...\n")
    results$claude <- call_claude_api(prompt, system_prompt)
    
    if (results$claude$success) {
      cat("✅ Claude tamamladı: ", results$claude$tokens_used, " token, ", 
          round(results$claude$duration, 1), " saniyə\n")
    } else {
      cat("❌ Claude xəta verdi:", results$claude$error, "\n")
    }
  } else {
    cat("⚠️ Claude API key yoxdur\n")
  }
  
  # Call GPT
  if (gpt_available) {
    cat("🤖 GPT-4o yaradır...\n")
    results$gpt <- call_gpt_api(prompt, system_prompt)
    
    if (results$gpt$success) {
      cat("✅ GPT tamamladı: ", results$gpt$tokens_used, " token, ", 
          round(results$gpt$duration, 1), " saniyə\n")
    } else {
      cat("❌ GPT xəta verdi:", results$gpt$error, "\n")
    }
  } else {
    cat("⚠️ GPT API key yoxdur\n")
  }
  
  # Determine final output
  if (!is.null(results$claude) && results$claude$success && 
      !is.null(results$gpt) && results$gpt$success) {
    
    # BOTH SUCCESS - return comparison
    cat("🔄 Hər iki model uğurla tamamladı - müqayisə rejimi\n")
    
    return(list(
      success = TRUE,
      curriculum = results$claude$text,  # Default to Claude
      claude_curriculum = results$claude$text,
      gpt_curriculum = results$gpt$text,
      method = "dual_ai_comparison",
      claude_tokens = results$claude$tokens_used,
      gpt_tokens = results$gpt$tokens_used,
      synthesis_tokens = 0,
      total_duration = results$claude$duration + results$gpt$duration,
      comparison_available = TRUE
    ))
    
  } else if (!is.null(results$claude) && results$claude$success) {
    # Only Claude success
    cat("✅ Claude uğurlu - yekun nəticə\n")
    
    return(list(
      success = TRUE,
      curriculum = results$claude$text,
      claude_curriculum = results$claude$text,
      gpt_curriculum = NULL,
      method = "claude_only",
      claude_tokens = results$claude$tokens_used,
      gpt_tokens = 0,
      synthesis_tokens = 0,
      total_duration = results$claude$duration,
      comparison_available = FALSE
    ))
    
  } else if (!is.null(results$gpt) && results$gpt$success) {
    # Only GPT success
    cat("✅ GPT uğurlu - yekun nəticə\n")
    
    return(list(
      success = TRUE,
      curriculum = results$gpt$text,
      claude_curriculum = NULL,
      gpt_curriculum = results$gpt$text,
      method = "gpt_only",
      claude_tokens = 0,
      gpt_tokens = results$gpt$tokens_used,
      synthesis_tokens = 0,
      total_duration = results$gpt$duration,
      comparison_available = FALSE
    ))
    
  } else {
    # Both failed - use DEMO
    cat("⚠️ Hər iki AI xəta verdi - DEMO mode\n")
    return(generate_curriculum_demo(subject, grade, hours_per_week, weeks_per_year, 
                                     reference_countries, special_focus))
  }
}

# Build curriculum prompt
build_curriculum_prompt <- function(subject, grade, hours_per_week, weeks_per_year,
                                     reference_countries = NULL, special_focus = NULL) {
  
  total_hours <- hours_per_week * weeks_per_year
  
  grade_info <- GRADES[GRADES$grade == grade, ]
  stage <- grade_info$stage[1]
  age <- grade_info$age_range[1]
  
  subject_info <- SUBJECTS[SUBJECTS$name_az == subject, ]
  category <- subject_info$category[1]
  
  countries_text <- ""
  if (!is.null(reference_countries) && length(reference_countries) > 0) {
    country_names <- COUNTRIES[COUNTRIES$code %in% reference_countries, "name_az"]
    countries_text <- glue("\n\nREFERANS ÖLKƏLƏR: {paste(country_names, collapse=', ')}")
  }
  
  focus_text <- ""
  if (!is.null(special_focus) && special_focus != "") {
    focus_text <- glue("\n\nXÜSUSİ FOKUS: {special_focus}")
  }
  
  prompt <- glue("
    Azərbaycan Respublikası üçün professional təhsil kurikulumu hazırlayın.
    
    PARAMETRLƏR:
    - Fənn: {subject} ({category})
    - Sinif: {grade} ({stage} mərhələsi, yaş: {age})
    - Həftəlik saat: {hours_per_week}
    - İllik həftə: {weeks_per_year}
    - Ümumi saat: {total_hours}{countries_text}{focus_text}
    
    Aşağıdakı strukturda ətraflı cavab verin:
    
    # 1. TƏSVIR VƏ FƏLSƏFƏ
    (300-400 söz)
    
    # 2. MƏQSƏD VƏ VƏZİFƏLƏR
    - Ümumi məqsəd
    - Xüsusi məqsədlər (5-7 maddə)
    
    # 3. ÖYRƏNMƏ NƏTİCƏLƏRİ
    (12-15 maddə - Bloom taksonomiyası)
    
    # 4. MƏZMUN STRUKTURU
    (Həftəlik təqvim - {weeks_per_year} həftə)
    
    # 5. METODOLOGİYA
    
    # 6. QİYMƏTLƏNDİRMƏ
    
    # 7. RESURSLAR
    
    # 8. STANDARTLARA UYĞUNLUQ
    
    Professional, strukturlaşdırılmış və Azərbaycan dilində yazın.
  ")
  
  return(prompt)
}

# DEMO MODE
generate_curriculum_demo <- function(subject, grade, hours_per_week, weeks_per_year,
                                     reference_countries = NULL, special_focus = NULL) {
  
  cat("🎮 DEMO MODE\n")
  Sys.sleep(2)
  
  total_hours <- hours_per_week * weeks_per_year
  
  demo_curriculum <- glue("
# {subject} - {grade}-ci Sinif Kurikulumu (DEMO)

⚠️ **Bu DEMO kurikulumdur**
💰 Real kurikulum üçün API credit əlavə edin

## Parametrlər:
- Həftəlik: {hours_per_week} saat
- İllik: {weeks_per_year} həftə
- Ümumi: {total_hours} saat

[DEMO məzmun]
  ")
  
  return(list(
    success = TRUE,
    curriculum = as.character(demo_curriculum),
    claude_curriculum = NULL,
    gpt_curriculum = NULL,
    method = "DEMO",
    claude_tokens = 0,
    gpt_tokens = 0,
    synthesis_tokens = 0,
    total_duration = 2.0,
    comparison_available = FALSE
  ))
}

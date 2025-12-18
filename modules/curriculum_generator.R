# =============================================================================
# CURRICULUM GENERATOR MODULE - SEPARATE AI OUTPUTS
# =============================================================================

# UI
curriculum_generator_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    # Header
    div(
      style = "background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
               color: white; padding: 40px; border-radius: 15px; 
               margin-bottom: 30px; text-align: center;",
      h2(icon("magic"), " Dual AI Kurikulum Generator", style = "margin: 0; font-size: 2.5em;"),
      p("Claude Sonnet 4.5 və GPT-4o ilə professional kurikulum", 
        style = "font-size: 1.2em; margin-top: 15px;")
    ),
    
    # Main Form
    fluidRow(
      box(
        title = tagList(icon("edit"), " Parametrlər"),
        status = "primary",
        solidHeader = TRUE,
        width = 8,
        
        fluidRow(
          column(6,
                 selectInput(ns("subject"),
                             label = tagList(icon("book"), " Fənn *"),
                             choices = setNames(SUBJECTS$name_az, SUBJECTS$name_az),
                             width = "100%")
          ),
          column(6,
                 selectInput(ns("grade"),
                             label = tagList(icon("graduation-cap"), " Sinif *"),
                             choices = setNames(GRADES$grade, GRADES$level_az),
                             width = "100%")
          )
        ),
        
        fluidRow(
          column(4,
                 numericInput(ns("hours_per_week"),
                              label = tagList(icon("clock"), " Saat/Həftə *"),
                              value = 4,
                              min = 1,
                              max = 10,
                              width = "100%")
          ),
          column(4,
                 numericInput(ns("weeks_per_year"),
                              label = tagList(icon("calendar"), " Həftə/İl *"),
                              value = 36,
                              min = 1,
                              max = 52,
                              width = "100%")
          ),
          column(4,
                 textInput(ns("academic_year"),
                           label = tagList(icon("calendar-alt"), " Tədris ili"),
                           value = "2024-2025",
                           width = "100%")
          )
        ),
        
        hr(),
        
        selectInput(ns("reference_countries"),
                    label = tagList(icon("globe"), " Referans Ölkələr"),
                    choices = setNames(COUNTRIES$code, COUNTRIES$name_az),
                    selected = c("AZ", "FI", "SG"),
                    multiple = TRUE,
                    width = "100%"),
        
        textAreaInput(ns("special_focus"),
                      label = tagList(icon("bullseye"), " Xüsusi Fokus"),
                      placeholder = "STEM, kritik təfəkkür...",
                      rows = 3,
                      width = "100%"),
        
        hr(),
        
        actionButton(ns("btn_generate"),
                     label = tagList(icon("magic"), " Dual AI Kurikulum Yarat"),
                     class = "btn btn-success btn-lg",
                     style = "width: 100%; padding: 15px; font-size: 1.2em;")
      ),
      
      # Info Panel
      box(
        title = tagList(icon("info-circle"), " Məlumat"),
        status = "info",
        solidHeader = TRUE,
        width = 4,
        
        h4("🤖 Dual AI:"),
        tags$ul(
          tags$li(tags$b("Claude Sonnet 4.5"), " - Azərbaycan fokuslu"),
          tags$li(tags$b("GPT-4o"), " - Beynəlxalq best practice")
        ),
        
        hr(),
        
        h4("📋 Nəticə:"),
        tags$ul(
          tags$li("2 ayrı kurikulum"),
          tags$li("Hər biri tam format"),
          tags$li("Ayrı-ayrı HTML export")
        ),
        
        hr(),
        
        uiOutput(ns("info_totals"))
      )
    ),
    
    # Progress
    uiOutput(ns("progress_section")),
    
    # Results
    uiOutput(ns("results_section"))
  )
}

# SERVER
curriculum_generator_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    ns <- session$ns
    
    # Reactive values
    rv <- reactiveValues(
      generating = FALSE,
      claude_curriculum = NULL,
      gpt_curriculum = NULL,
      generation_info = NULL
    )
    
    # Calculate totals
    output$info_totals <- renderUI({
      hours <- input$hours_per_week
      weeks <- input$weeks_per_year
      
      if (is.null(hours) || is.null(weeks)) {
        return(div(
          style = "background: #f3e5f5; padding: 15px; border-radius: 10px;",
          h4(style = "margin-top: 0; color: #7b1fa2;", "📊 Hesablamalar:"),
          p("Yüklənir...")
        ))
      }
      
      total_hours <- hours * weeks
      
      div(
        style = "background: #f3e5f5; padding: 15px; border-radius: 10px;",
        h4(style = "margin-top: 0; color: #7b1fa2;", "📊 Hesablamalar:"),
        p(tags$b("Ümumi saat:"), " ", total_hours, " saat"),
        p(tags$b("Təxmini müddət:"), " ", weeks, " həftə")
      )
    })
    
    # Generate button
    observeEvent(input$btn_generate, {
      
      if (is.null(input$subject) || input$subject == "") {
        showNotification("⚠️ Fənn seçilməlidir!", type = "error", duration = 3)
        return()
      }
      
      if (is.null(input$grade) || input$grade == "") {
        showNotification("⚠️ Sinif seçilməlidir!", type = "error", duration = 3)
        return()
      }
      
      rv$generating <- TRUE
      rv$claude_curriculum <- NULL
      rv$gpt_curriculum <- NULL
      rv$generation_info <- NULL
      
      tryCatch({
        
        result <- generate_curriculum_dual_ai(
          subject = input$subject,
          grade = as.integer(input$grade),
          hours_per_week = input$hours_per_week,
          weeks_per_year = input$weeks_per_year,
          reference_countries = input$reference_countries,
          special_focus = input$special_focus
        )
        
        if (result$success) {
          
          rv$generation_info <- result
          rv$claude_curriculum <- result$claude_curriculum
          rv$gpt_curriculum <- result$gpt_curriculum
          
          # Save Claude to database
          if (!is.null(result$claude_curriculum)) {
            curriculum_data <- list(
              name = paste(input$subject, input$grade, "sinif - Claude"),
              subject_id = SUBJECTS[SUBJECTS$name_az == input$subject, "id"][1],
              subject_name = input$subject,
              grade = as.integer(input$grade),
              academic_year = input$academic_year,
              hours_per_week = input$hours_per_week,
              weeks_per_year = input$weeks_per_year,
              total_hours = input$hours_per_week * input$weeks_per_year,
              description = substr(result$claude_curriculum, 1, 500),
              content_structure = result$claude_curriculum,
              azerbaijan_standards = "Azərbaycan Təhsil Standartları",
              international_standards = paste(input$reference_countries, collapse = ","),
              reference_countries = paste(input$reference_countries, collapse = ","),
              generated_by = "AI",
              ai_model = "Claude Sonnet 4.5",
              creation_method = result$method,
              status = "draft",
              created_by = "system",
              philosophy = NA,
              learning_outcomes = NA,
              methodology = NA,
              assessment = NA,
              resources = NA
            )
            
            save_curriculum(curriculum_data)
          }
          
          showNotification("✅ Dual AI kurikulum yaradıldı!", type = "message", duration = 5)
          
        } else {
          showNotification(paste("❌ Xəta:", result$error), type = "error", duration = 10)
        }
        
        rv$generating <- FALSE
        
      }, error = function(e) {
        rv$generating <- FALSE
        showNotification(paste("❌ Xəta:", as.character(e)), type = "error", duration = 10)
      })
    })
    
    # Progress section
    output$progress_section <- renderUI({
      if (!rv$generating) return(NULL)
      
      box(
        title = tagList(icon("spinner", class = "fa-spin"), " Yaradılır..."),
        status = "warning",
        solidHeader = TRUE,
        width = 12,
        
        div(style = "padding: 20px; text-align: center;",
            h4("🤖 Dual AI kurrikulumları hazırlayır..."),
            p("Claude və GPT paralel işləyir. Bu proses 60-90 saniyə çəkə bilər."))
      )
    })
    
    # Results section
    output$results_section <- renderUI({
      req(rv$generation_info)
      
      info <- isolate(rv$generation_info)
      
      # Summary box
      summary_ui <- box(
        title = tagList(icon("chart-bar"), " Dual AI Nəticələr"),
        status = "success",
        solidHeader = TRUE,
        width = 12,
        collapsible = TRUE,
        
        fluidRow(
          column(3,
                 div(style = "text-align: center; padding: 20px; background: #e8f5e9; border-radius: 10px;",
                     h3(style = "margin: 0; color: #2e7d32;", info$method),
                     p("Metod")
                 )
          ),
          column(3,
                 div(style = "text-align: center; padding: 20px; background: #e3f2fd; border-radius: 10px;",
                     h3(style = "margin: 0; color: #1565c0;", 
                        info$claude_tokens + info$gpt_tokens),
                     p("Ümumi Token")
                 )
          ),
          column(3,
                 div(style = "text-align: center; padding: 20px; background: #fff3e0; border-radius: 10px;",
                     h3(style = "margin: 0; color: #ef6c00;", 
                        round(info$total_duration, 1), " san"),
                     p("Ümumi Müddət")
                 )
          ),
          column(3,
                 div(style = "text-align: center; padding: 20px; background: #f3e5f5; border-radius: 10px;",
                     h3(style = "margin: 0; color: #7b1fa2;", 
                        ifelse(!is.null(info$claude_curriculum) && !is.null(info$gpt_curriculum), "2", 
                               ifelse(!is.null(info$claude_curriculum) || !is.null(info$gpt_curriculum), "1", "0"))),
                     p("Kurikulum")
                 )
          )
        )
      )
      
      result_ui <- tagList(summary_ui)
      
      # Claude curriculum box
      if (!is.null(info$claude_curriculum)) {
        claude_ui <- box(
          title = tagList(icon("robot"), " Claude Sonnet 4.5 Kurikulumu"),
          status = "primary",
          solidHeader = TRUE,
          width = 12,
          collapsible = TRUE,
          collapsed = FALSE,
          
          fluidRow(
            column(9,
                   div(style = "background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 10px; margin-bottom: 15px;",
                       h4(style = "margin: 0;", "🤖 Claude Sonnet 4.5"),
                       p(style = "margin: 5px 0 0 0;", "Azərbaycan fokuslu, strukturlaşdırılmış yanaşma"),
                       p(style = "margin: 5px 0 0 0; font-size: 0.9em;", 
                         "📊 ", format(info$claude_tokens, big.mark=","), " tokens | ",
                         "⏱️ ", round(info$total_duration / 2, 1), " saniyə")
                   )
            ),
            column(3,
                   actionButton(ns("btn_export_claude"),
                                label = tagList(icon("download"), " Claude HTML Export"),
                                class = "btn btn-primary btn-lg",
                                style = "width: 100%; padding: 15px; font-weight: bold; margin-top: 10px;")
            )
          ),
          
          div(style = "max-height: 600px; overflow-y: auto; padding: 20px; background: #f8f9fa; border: 3px solid #667eea; border-radius: 10px;",
              pre(style = "white-space: pre-wrap; font-family: 'Segoe UI'; line-height: 1.8; font-size: 1em;",
                  info$claude_curriculum))
        )
        
        result_ui <- tagList(result_ui, claude_ui)
      }
      
      # GPT curriculum box
      if (!is.null(info$gpt_curriculum)) {
        gpt_ui <- box(
          title = tagList(icon("robot"), " GPT-4o Kurikulumu"),
          status = "success",
          solidHeader = TRUE,
          width = 12,
          collapsible = TRUE,
          collapsed = FALSE,
          
          fluidRow(
            column(9,
                   div(style = "background: linear-gradient(135deg, #10b981 0%, #059669 100%); color: white; padding: 20px; border-radius: 10px; margin-bottom: 15px;",
                       h4(style = "margin: 0;", "🤖 GPT-4o"),
                       p(style = "margin: 5px 0 0 0;", "Beynəlxalq best practice, innovativ yanaşma"),
                       p(style = "margin: 5px 0 0 0; font-size: 0.9em;", 
                         "📊 ", format(info$gpt_tokens, big.mark=","), " tokens | ",
                         "⏱️ ", round(info$total_duration / 2, 1), " saniyə")
                   )
            ),
            column(3,
                   actionButton(ns("btn_export_gpt"),
                                label = tagList(icon("download"), " GPT HTML Export"),
                                class = "btn btn-success btn-lg",
                                style = "width: 100%; padding: 15px; font-weight: bold; margin-top: 10px;")
            )
          ),
          
          div(style = "max-height: 600px; overflow-y: auto; padding: 20px; background: #f8f9fa; border: 3px solid #10b981; border-radius: 10px;",
              pre(style = "white-space: pre-wrap; font-family: 'Segoe UI'; line-height: 1.8; font-size: 1em;",
                  info$gpt_curriculum))
        )
        
        result_ui <- tagList(result_ui, gpt_ui)
      }
      
      return(result_ui)
    })
    
    # Export Claude HTML
    observeEvent(input$btn_export_claude, {
      
      req(rv$claude_curriculum, rv$generation_info)
      
      subject_val <- isolate(input$subject)
      grade_val <- isolate(input$grade)
      hours_val <- isolate(input$hours_per_week)
      weeks_val <- isolate(input$weeks_per_year)
      year_val <- isolate(input$academic_year)
      countries_val <- isolate(input$reference_countries)
      info <- isolate(rv$generation_info)
      
      withProgress(message = 'Claude HTML yaradılır...', value = 0.5, {
        
        tryCatch({
          
          curriculum_data <- list(
            name = paste(subject_val, grade_val, "sinif - Claude Sonnet 4.5"),
            subject_name = subject_val,
            grade = grade_val,
            hours_per_week = hours_val,
            weeks_per_year = weeks_val,
            total_hours = hours_val * weeks_val,
            academic_year = year_val,
            reference_countries = paste(
              COUNTRIES[COUNTRIES$code %in% countries_val, "name_az"],
              collapse = ", "
            )
          )
          
          result <- export_curriculum_html(
            curriculum_data = curriculum_data,
            curriculum_content = isolate(rv$claude_curriculum),
            generation_info = list(
              method = "Claude Sonnet 4.5",
              claude_tokens = info$claude_tokens,
              gpt_tokens = 0,
              synthesis_tokens = 0,
              total_duration = info$total_duration / 2
            )
          )
          
          if (result$success) {
            showNotification(
              HTML(paste0(
                "<strong>✅ Claude HTML yaradıldı!</strong><br>",
                "Fayl: ", result$filename, "<br>",
                "Ölçü: ", round(result$size / 1024, 1), " KB"
              )),
              type = "message",
              duration = 10
            )
            
            Sys.sleep(0.5)
            browseURL(result$path)
          }
          
        }, error = function(e) {
          showNotification(paste0("❌ Xəta: ", as.character(e)), type = "error", duration = 10)
        })
      })
    })
    
    # Export GPT HTML
    observeEvent(input$btn_export_gpt, {
      
      req(rv$gpt_curriculum, rv$generation_info)
      
      subject_val <- isolate(input$subject)
      grade_val <- isolate(input$grade)
      hours_val <- isolate(input$hours_per_week)
      weeks_val <- isolate(input$weeks_per_year)
      year_val <- isolate(input$academic_year)
      countries_val <- isolate(input$reference_countries)
      info <- isolate(rv$generation_info)
      
      withProgress(message = 'GPT HTML yaradılır...', value = 0.5, {
        
        tryCatch({
          
          curriculum_data <- list(
            name = paste(subject_val, grade_val, "sinif - GPT-4o"),
            subject_name = subject_val,
            grade = grade_val,
            hours_per_week = hours_val,
            weeks_per_year = weeks_val,
            total_hours = hours_val * weeks_val,
            academic_year = year_val,
            reference_countries = paste(
              COUNTRIES[COUNTRIES$code %in% countries_val, "name_az"],
              collapse = ", "
            )
          )
          
          result <- export_curriculum_html(
            curriculum_data = curriculum_data,
            curriculum_content = isolate(rv$gpt_curriculum),
            generation_info = list(
              method = "GPT-4o",
              claude_tokens = 0,
              gpt_tokens = info$gpt_tokens,
              synthesis_tokens = 0,
              total_duration = info$total_duration / 2
            )
          )
          
          if (result$success) {
            showNotification(
              HTML(paste0(
                "<strong>✅ GPT HTML yaradıldı!</strong><br>",
                "Fayl: ", result$filename, "<br>",
                "Ölçü: ", round(result$size / 1024, 1), " KB"
              )),
              type = "message",
              duration = 10
            )
            
            Sys.sleep(0.5)
            browseURL(result$path)
          }
          
        }, error = function(e) {
          showNotification(paste0("❌ Xəta: ", as.character(e)), type = "error", duration = 10)
        })
      })
    })
    
  })
}

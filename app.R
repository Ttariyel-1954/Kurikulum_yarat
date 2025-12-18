# =============================================================================
# AI CURRICULUM GENERATOR - MAIN APP
# =============================================================================

source("global.R")
source("modules/curriculum_generator.R")

# =============================================================================
# UI
# =============================================================================

header <- dashboardHeader(
  title = "AI Kurikulum Generator",
  titleWidth = 300
)

sidebar <- dashboardSidebar(
  width = 300,
  sidebarMenu(
    id = "tabs",
    menuItem("🚀 Yeni Kurikulum", tabName = "generator", icon = icon("magic")),
    menuItem("📚 Kurikulum Kitabxanası", tabName = "library", icon = icon("book")),
    menuItem("📊 Statistika", tabName = "statistics", icon = icon("chart-bar")),
    menuItem("⚙️ Parametrlər", tabName = "parameters", icon = icon("cog")),
    menuItem("ℹ️ Haqqında", tabName = "about", icon = icon("info-circle"))
  )
)

body <- dashboardBody(
  
  tags$head(
    tags$style(HTML("
      .content-wrapper, .right-side { background-color: #ecf0f5; }
      .box { border-radius: 8px; }
      .small-box { border-radius: 8px; }
      .view-btn, .delete-btn { padding: 4px 10px !important; font-size: 12px !important; }
    "))
  ),
  
  tabItems(
    
    tabItem(tabName = "generator", curriculum_generator_ui("generator")),
    
    tabItem(
      tabName = "library",
      fluidRow(
        box(
          title = tagList(icon("book"), " Kurikulum Kitabxanası"),
          status = "primary",
          solidHeader = TRUE,
          width = 12,
          collapsible = TRUE,
          div(style = "margin-bottom: 15px;",
              p(icon("info-circle"), " Kurikuluma baxmaq üçün ", tags$b("'Bax'"), 
                ", silmək üçün ", tags$b("'Sil'"), " düyməsinə basın.")
          ),
          DT::dataTableOutput("library_table")
        )
      )
    ),
    
    tabItem(
      tabName = "statistics",
      h2(icon("chart-bar"), " Statistika", style = "margin-bottom: 20px;"),
      fluidRow(
        infoBoxOutput("total_curricula", width = 3),
        infoBoxOutput("draft_curricula", width = 3),
        infoBoxOutput("total_subjects", width = 3),
        infoBoxOutput("total_grades", width = 3)
      ),
      fluidRow(
        box(
          title = "Fənnlərə görə kurikulumlar",
          status = "primary",
          solidHeader = TRUE,
          width = 6,
          plotlyOutput("chart_by_subject", height = 350)
        ),
        box(
          title = "Siniflərə görə kurikulumlar",
          status = "info",
          solidHeader = TRUE,
          width = 6,
          plotlyOutput("chart_by_grade", height = 350)
        )
      )
    ),
    
    tabItem(
      tabName = "parameters",
      h2(icon("cog"), " Sistem Parametrləri", style = "margin-bottom: 20px;"),
      fluidRow(
        box(
          title = "API Status",
          status = "primary",
          solidHeader = TRUE,
          width = 6,
          div(style = "padding: 10px;",
              h4(icon("robot"), " Claude API"),
              p(textOutput("claude_status")),
              hr(),
              h4(icon("robot"), " GPT API"),
              p(textOutput("gpt_status"))
          )
        ),
        box(
          title = "Database Məlumatı",
          status = "info",
          solidHeader = TRUE,
          width = 6,
          div(style = "padding: 10px;",
              h4(icon("database"), " SQLite"),
              p(tags$b("Path:"), textOutput("db_path", inline = TRUE)),
              p(tags$b("Ölçü:"), textOutput("db_size", inline = TRUE)),
              p(tags$b("Cədvəllər:"), "curricula, generation_logs, user_preferences")
          )
        )
      ),
      fluidRow(
        box(
          title = "Sistem Məlumatı",
          status = "success",
          solidHeader = TRUE,
          width = 12,
          div(style = "padding: 10px;",
              h4("📦 Quraşdırılmış Paketlər"),
              verbatimTextOutput("system_info")
          )
        )
      )
    ),
    
    tabItem(
      tabName = "about",
      fluidRow(
        box(
          title = tagList(icon("info-circle"), " Haqqında"),
          status = "primary",
          solidHeader = TRUE,
          width = 12,
          div(style = "padding: 20px; line-height: 1.8;",
              h3("🎓 AI Kurikulum Generator"),
              p("Azərbaycan təhsil sistemi üçün süni intellekt əsaslı professional kurikulum yaradıcısı."),
              hr(),
              h4("✨ Xüsusiyyətlər:"),
              tags$ul(
                tags$li("Dual AI: Claude Sonnet 4.5 və GPT-4o"),
                tags$li("17 Fənn, 11 Sinif"),
                tags$li("10 Beynəlxalq Referans Ölkə"),
                tags$li("Professional HTML Export"),
                tags$li("SQLite Database"),
                tags$li("Statistika Dashboard")
              ),
              hr(),
              p(tags$b("GitHub:"), " ", 
                tags$a(href = "https://github.com/Ttariyel-1954/Kurikulum_yarat", 
                       target = "_blank", "Ttariyel-1954/Kurikulum_yarat")),
              p("© 2024 ARTI - Azerbaijan Republic Education Institute")
          )
        )
      )
    )
  ),
  
  tags$script(HTML("
    $(document).on('click', '.view-btn', function() {
      var id = $(this).data('id');
      Shiny.setInputValue('view_curriculum', id, {priority: 'event'});
    });
    $(document).on('click', '.delete-btn', function() {
      var id = $(this).data('id');
      Shiny.setInputValue('delete_curriculum', id, {priority: 'event'});
    });
  "))
)

ui <- dashboardPage(header, sidebar, body, skin = "blue")

# =============================================================================
# SERVER
# =============================================================================

server <- function(input, output, session) {
  
  curriculum_generator_server("generator")
  
  # ========================================================================
  # LIBRARY
  # ========================================================================
  
  rv_library <- reactiveValues(refresh = 0, delete_id = NULL)
  
  output$library_table <- DT::renderDataTable({
    rv_library$refresh
    curricula <- get_all_curricula()
    if (nrow(curricula) == 0) {
      return(data.frame(Məlumat = "Hələ kurikulum yaradılmayıb"))
    }
    curricula$Əməliyyatlar <- sprintf(
      '<button class="btn btn-info btn-sm view-btn" data-id="%s" style="margin-right: 5px;">
        <i class="fa fa-eye"></i> Bax
      </button>
      <button class="btn btn-danger btn-sm delete-btn" data-id="%s">
        <i class="fa fa-trash"></i> Sil
      </button>',
      curricula$id, curricula$id
    )
    display_data <- curricula[, c("id", "name", "subject_name", "grade", 
                                   "academic_year", "ai_model", "created_at", "Əməliyyatlar")]
    colnames(display_data) <- c("ID", "Ad", "Fənn", "Sinif", "Tədris ili", "AI Model", "Yaradılma", "Əməliyyatlar")
    DT::datatable(display_data, options = list(pageLength = 10, columnDefs = list(
      list(width = '50px', targets = 0), list(width = '160px', targets = 7)
    )), escape = FALSE, selection = 'none', rownames = FALSE)
  })
  
  observeEvent(input$view_curriculum, {
    curriculum_id <- input$view_curriculum
    if (is.null(curriculum_id) || curriculum_id == "") return()
    curriculum <- get_curriculum_by_id(as.integer(curriculum_id))
    if (is.null(curriculum)) {
      showNotification("⚠️ Kurikulum tapılmadı!", type = "error", duration = 3)
      return()
    }
    showModal(modalDialog(
      title = tagList(icon("eye"), " ", curriculum$name),
      div(style = "padding: 10px;",
        div(style = "background: #e3f2fd; padding: 15px; border-radius: 8px; margin-bottom: 20px;",
            fluidRow(
              column(3, p(tags$b("Fənn:"), " ", curriculum$subject_name)),
              column(3, p(tags$b("Sinif:"), " ", curriculum$grade)),
              column(3, p(tags$b("AI:"), " ", curriculum$ai_model)),
              column(3, p(tags$b("Tarix:"), " ", substr(curriculum$created_at, 1, 10)))
            )
        ),
        div(style = "max-height: 500px; overflow-y: auto; background: #fafafa; padding: 20px; border-radius: 8px; border: 2px solid #0284c7;",
            pre(style = "white-space: pre-wrap; font-family: 'Segoe UI'; line-height: 1.7; font-size: 0.95em;",
                curriculum$content_structure)
        )
      ),
      footer = tagList(modalButton("Bağla", icon = icon("times"))),
      easyClose = TRUE, size = "l"
    ))
  })
  
  observeEvent(input$delete_curriculum, {
    curriculum_id <- input$delete_curriculum
    if (is.null(curriculum_id) || curriculum_id == "") return()
    curriculum <- get_curriculum_by_id(as.integer(curriculum_id))
    if (is.null(curriculum)) {
      showNotification("⚠️ Kurikulum tapılmadı!", type = "error", duration = 3)
      return()
    }
    showModal(modalDialog(
      title = tagList(icon("exclamation-triangle"), " Təsdiq"),
      div(style = "padding: 20px;",
        h4(style = "color: #d32f2f; margin-top: 0;", "Bu kurikulumu silmək istədiyinizdən əminsiniz?"),
        hr(),
        div(style = "background: #f5f5f5; padding: 15px; border-radius: 8px;",
            p(style = "margin: 5px 0;", tags$b("Ad:"), " ", curriculum$name),
            p(style = "margin: 5px 0;", tags$b("Fənn:"), " ", curriculum$subject_name),
            p(style = "margin: 5px 0;", tags$b("Sinif:"), " ", curriculum$grade),
            p(style = "margin: 5px 0;", tags$b("Yaradılma:"), " ", curriculum$created_at)
        ),
        hr(),
        div(style = "background: #ffebee; padding: 15px; border-radius: 8px; border-left: 4px solid #d32f2f;",
            p(style = "color: #d32f2f; font-weight: bold; margin: 0;", 
              icon("exclamation-triangle"), " Bu əməliyyat geri qaytarıla bilməz!")
        )
      ),
      footer = tagList(
        modalButton("Ləğv et", icon = icon("times")),
        actionButton("confirm_delete", label = tagList(icon("trash"), " Sil"),
                     class = "btn btn-danger", style = "font-weight: bold;")
      ),
      easyClose = TRUE, size = "m"
    ))
    rv_library$delete_id <- as.integer(curriculum_id)
  })
  
  observeEvent(input$confirm_delete, {
    curriculum_id <- rv_library$delete_id
    if (is.null(curriculum_id)) return()
    tryCatch({
      result <- delete_curriculum(curriculum_id)
      if (result) {
        showNotification("✅ Kurikulum uğurla silindi!", type = "message", duration = 3)
        rv_library$refresh <- rv_library$refresh + 1
      } else {
        showNotification("❌ Silinmə zamanı xəta!", type = "error", duration = 5)
      }
      removeModal()
    }, error = function(e) {
      showNotification(paste("❌ Xəta:", as.character(e)), type = "error", duration = 5)
      removeModal()
    })
  })
  
  # ========================================================================
  # STATISTICS - FIXED
  # ========================================================================
  
  stats_data <- reactive({ get_curriculum_statistics() })
  
  output$total_curricula <- renderInfoBox({
    stats <- stats_data()
    infoBox("Ümumi", stats$total, icon = icon("book"), color = "blue")
  })
  
  output$draft_curricula <- renderInfoBox({
    stats <- stats_data()
    draft_count <- if(!is.null(stats$by_status) && "draft" %in% names(stats$by_status)) {
      as.integer(stats$by_status[["draft"]])
    } else {
      0
    }
    infoBox("Draft", draft_count, icon = icon("edit"), color = "yellow")
  })
  
  output$total_subjects <- renderInfoBox({
    stats <- stats_data()
    subject_count <- if(!is.null(stats$by_subject)) length(stats$by_subject) else 0
    infoBox("Fənnlər", subject_count, icon = icon("graduation-cap"), color = "green")
  })
  
  output$total_grades <- renderInfoBox({
    stats <- stats_data()
    grade_count <- if(!is.null(stats$by_grade)) length(stats$by_grade) else 0
    infoBox("Siniflər", grade_count, icon = icon("users"), color = "purple")
  })
  
  output$chart_by_subject <- renderPlotly({
    stats <- stats_data()
    if (is.null(stats$by_subject) || length(stats$by_subject) == 0) {
      return(plot_ly() %>% layout(title = list(text = "Məlumat yoxdur", font = list(size = 16))))
    }
    df <- data.frame(subject = names(stats$by_subject), count = as.numeric(stats$by_subject), stringsAsFactors = FALSE)
    plot_ly(df, x = ~subject, y = ~count, type = "bar", marker = list(color = "#0284c7")) %>%
      layout(xaxis = list(title = "Fənn", tickangle = -45), yaxis = list(title = "Say"), margin = list(b = 120))
  })
  
  output$chart_by_grade <- renderPlotly({
    stats <- stats_data()
    if (is.null(stats$by_grade) || length(stats$by_grade) == 0) {
      return(plot_ly() %>% layout(title = list(text = "Məlumat yoxdur", font = list(size = 16))))
    }
    df <- data.frame(grade = names(stats$by_grade), count = as.numeric(stats$by_grade), stringsAsFactors = FALSE)
    df$grade <- factor(df$grade, levels = as.character(sort(as.numeric(df$grade))))
    plot_ly(df, x = ~grade, y = ~count, type = "bar", marker = list(color = "#10b981")) %>%
      layout(xaxis = list(title = "Sinif"), yaxis = list(title = "Say"))
  })
  
  # ========================================================================
  # PARAMETERS
  # ========================================================================
  
  output$claude_status <- renderText({
    if (CONFIG$anthropic_key != "" && CONFIG$anthropic_key != "your_claude_api_key_here") {
      "✅ Konfiqurasiya edilib"
    } else {
      "❌ API key yoxdur"
    }
  })
  
  output$gpt_status <- renderText({
    if (CONFIG$openai_key != "" && CONFIG$openai_key != "your_openai_api_key_here") {
      "✅ Konfiqurasiya edilib"
    } else {
      "⚠️ API key yoxdur (optional)"
    }
  })
  
  output$db_path <- renderText({ CONFIG$db_path })
  
  output$db_size <- renderText({
    if (file.exists(CONFIG$db_path)) {
      paste(round(file.size(CONFIG$db_path) / 1024, 2), "KB")
    } else {
      "Database yoxdur"
    }
  })
  
  output$system_info <- renderPrint({
    cat("R Version:", R.version.string, "\n")
    cat("Platform:", R.version$platform, "\n\n")
    cat("Paketlər:\n")
    cat("- shiny:", as.character(packageVersion("shiny")), "\n")
    cat("- DT:", as.character(packageVersion("DT")), "\n")
    cat("- plotly:", as.character(packageVersion("plotly")), "\n")
    cat("- RSQLite:", as.character(packageVersion("RSQLite")), "\n")
  })
}

shinyApp(ui, server)

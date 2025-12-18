# =============================================================================
# KURIKULUM GENERATOR - MAIN APPLICATION
# =============================================================================

# Load global configuration
source("global.R")

# Load modules
source("modules/curriculum_generator.R", encoding = "UTF-8")

# =============================================================================
# UI
# =============================================================================

ui <- dashboardPage(
  
  # Header
  dashboardHeader(
    title = "🎓 Kurikulum Generator",
    titleWidth = 300
  ),
  
  # Sidebar
  dashboardSidebar(
    width = 300,
    sidebarMenu(
      id = "sidebar_menu",
      
      menuItem("🚀 Yeni Kurikulum", 
               tabName = "generator", 
               icon = icon("magic")),
      
      menuItem("📚 Kurikulum Kitabxanası", 
               tabName = "library", 
               icon = icon("book")),
      
      menuItem("📊 Statistika", 
               tabName = "statistics", 
               icon = icon("chart-bar")),
      
      menuItem("⚙️ Parametrlər", 
               tabName = "settings", 
               icon = icon("cog")),
      
      menuItem("ℹ️ Haqqında", 
               tabName = "about", 
               icon = icon("info-circle"))
    ),
    
    hr(),
    
    # Info box
    div(style = "padding: 15px; color: #ecf0f1; font-size: 0.9em;",
        tags$p(style = "margin: 5px 0;",
               icon("database"), " Database: OK"),
        tags$p(style = "margin: 5px 0;",
               icon("robot"), " AI: Claude + GPT"),
        tags$p(style = "margin: 5px 0;",
               icon("globe"), " Referans: 10 ölkə")
    )
  ),
  
  # Body
  dashboardBody(
    
    # Custom CSS
    tags$head(
      tags$style(HTML("
        .content-wrapper { background-color: #ecf0f1; }
        .box { border-radius: 10px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
        .info-box { border-radius: 10px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
        .btn { border-radius: 8px; font-weight: 600; }
        .main-header .logo { font-weight: bold; font-size: 18px; }
      "))
    ),
    
    tabItems(
      
      # Generator Tab
      tabItem(
        tabName = "generator",
        curriculum_generator_ui("curriculum_gen")
      ),
      
      # Library Tab
      tabItem(
        tabName = "library",
        h2("Kurikulum Kitabxanası"),
        p("Yaradılmış kurrikulumlar burada göstəriləcək."),
        hr(),
        
        fluidRow(
          column(12,
                 box(
                   title = "Kurikulum Siyahısı",
                   status = "primary",
                   solidHeader = TRUE,
                   width = 12,
                   DTOutput("library_table")
                 )
          )
        )
      ),
      
      # Statistics Tab
      tabItem(
        tabName = "statistics",
        h2("📊 Statistika"),
        
        fluidRow(
          infoBoxOutput("stat_total", width = 3),
          infoBoxOutput("stat_subjects", width = 3),
          infoBoxOutput("stat_grades", width = 3),
          infoBoxOutput("stat_recent", width = 3)
        ),
        
        fluidRow(
          box(
            title = "Fənn üzrə",
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("plot_by_subject")
          ),
          box(
            title = "Sinif üzrə",
            status = "success",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("plot_by_grade")
          )
        )
      ),
      
      # Settings Tab
      tabItem(
        tabName = "settings",
        h2("⚙️ Parametrlər"),
        
        fluidRow(
          box(
            title = "AI Konfiqurasiyası",
            status = "warning",
            solidHeader = TRUE,
            width = 6,
            
            p("API Keys .env faylında konfiqurasiya edilir."),
            verbatimTextOutput("api_status")
          ),
          
          box(
            title = "Database",
            status = "info",
            solidHeader = TRUE,
            width = 6,
            
            verbatimTextOutput("db_info")
          )
        )
      ),
      
      # About Tab
      tabItem(
        tabName = "about",
        h2("ℹ️ Haqqında"),
        
        box(
          width = 12,
          status = "primary",
          
          h3("🎓 Kurikulum Generator v1.0"),
          p("Süni intellekt əsaslı professional təhsil kurikulumu generatoru."),
          
          hr(),
          
          h4("🌟 Xüsusiyyətlər:"),
          tags$ul(
            tags$li("Dual AI: Claude Sonnet 4.5 + GPT-5.1"),
            tags$li("17 fənn, 11 sinif dəstəyi"),
            tags$li("10 beynəlxalq ölkə standartları"),
            tags$li("8-bölməli professional struktur"),
            tags$li("PDF, DOCX, HTML export"),
            tags$li("Azərbaycan Dövlət Standartlarına uyğun")
          ),
          
          hr(),
          
          h4("📚 Referans ölkələr:"),
          p(paste(COUNTRIES$name_az, collapse = ", ")),
          
          hr(),
          
          h4("👨‍💻 Hazırlayan:"),
          p("ARTI - Azerbaijan Republic Education Institute"),
          p("Versiya: 1.0.0 | Tarix: December 2024")
        )
      )
    )
  )
)

# =============================================================================
# SERVER
# =============================================================================

server <- function(input, output, session) {
  
  # Generator Module
  curriculum_generator_server("curriculum_gen")
  
  # Library Table
  output$library_table <- renderDT({
    curricula <- get_all_curricula()
    
    if (nrow(curricula) == 0) {
      return(datatable(data.frame(Mesaj = "Hələ kurikulum yaradılmayıb")))
    }
    
    display <- curricula %>%
      select(name, subject_name, grade, academic_year, status, created_at) %>%
      mutate(created_at = format(as.POSIXct(created_at), "%d.%m.%Y %H:%M"))
    
    names(display) <- c("Ad", "Fənn", "Sinif", "Tədris ili", "Status", "Yaradılma")
    
    datatable(
      display,
      options = list(
        pageLength = 15,
        language = list(
          search = "Axtar:",
          lengthMenu = "Göstər _MENU_",
          info = "_TOTAL_ nəticədən _START_ - _END_"
        )
      ),
      rownames = FALSE
    )
  })
  
  # Statistics
  stats <- reactive({
    get_curriculum_statistics()
  })
  
  output$stat_total <- renderInfoBox({
    infoBox(
      "Ümumi",
      stats()$total,
      icon = icon("book"),
      color = "purple"
    )
  })
  
  output$stat_subjects <- renderInfoBox({
    infoBox(
      "Fənn",
      nrow(stats()$by_subject),
      icon = icon("layer-group"),
      color = "blue"
    )
  })
  
  output$stat_grades <- renderInfoBox({
    infoBox(
      "Sinif",
      nrow(stats()$by_grade),
      icon = icon("graduation-cap"),
      color = "green"
    )
  })
  
  output$stat_recent <- renderInfoBox({
    infoBox(
      "Son 7 gün",
      stats()$recent,
      icon = icon("clock"),
      color = "orange"
    )
  })
  
  output$plot_by_subject <- renderPlotly({
    data <- stats()$by_subject
    
    if (nrow(data) == 0) return(NULL)
    
    plot_ly(data, x = ~count, y = ~reorder(subject_name, count),
            type = 'bar', orientation = 'h',
            marker = list(color = '#667eea')) %>%
      layout(xaxis = list(title = "Say"),
             yaxis = list(title = ""))
  })
  
  output$plot_by_grade <- renderPlotly({
    data <- stats()$by_grade
    
    if (nrow(data) == 0) return(NULL)
    
    plot_ly(data, x = ~as.factor(grade), y = ~count,
            type = 'bar',
            marker = list(color = '#10b981')) %>%
      layout(xaxis = list(title = "Sinif"),
             yaxis = list(title = "Say"))
  })
  
  # API Status
  output$api_status <- renderText({
    claude_status <- ifelse(CONFIG$anthropic_key != "" && 
                              CONFIG$anthropic_key != "your_claude_api_key_here",
                            "✅ Konfiqurasiya edilib", 
                            "❌ Konfiqurasiya edilməyib")
    
    gpt_status <- ifelse(CONFIG$openai_key != "" && 
                           CONFIG$openai_key != "your_openai_api_key_here",
                         "✅ Konfiqurasiya edilib", 
                         "❌ Konfiqurasiya edilməyib")
    
    paste0(
      "Claude API: ", claude_status, "\n",
      "GPT API: ", gpt_status, "\n",
      "Model: ", CONFIG$claude_model
    )
  })
  
  # DB Info
  output$db_info <- renderText({
    stats <- stats()
    
    paste0(
      "Database yolu: ", CONFIG$db_path, "\n",
      "Ümumi kurikulum: ", stats$total, "\n",
      "Database ölçüsü: ", 
      format(file.info(CONFIG$db_path)$size / 1024, digits = 2), " KB"
    )
  })
}

# =============================================================================
# RUN APP
# =============================================================================

shinyApp(ui = ui, server = server)

library(tidyverse)
library(shiny)

d = readr::read_csv(here::here("data/weather.csv"))

d_vars = c("Average temp" = "temp_avg",
           "Min temp" = "temp_min",
           "Max temp" = "temp_max",
           "Total precip" = "precip",
           "Snow depth" = "snow",
           "Wind direction" = "wind_direction",
           "Wind speed" = "wind_speed",
           "Air pressure" = "air_press")

ui = fluidPage(
  titlePanel("Weather Data"),
  sidebarLayout(
    sidebarPanel(
      selectInput(
        "region", "Select a region",
        choices = sort(unique(d$region)),
        selected = "West"
      ),
      selectInput(
        "name", "Select an airport",
        choices = c()
      ),
      selectInput(
        "var", "Select a variable",
        choices = d_vars, selected = "temp"
      ),
      actionButton("download_modal", "Download")
    ),
    mainPanel( 
      plotOutput("plot")
    )
  )
)

server = function(input, output, session) {
  
  observe({
    showModal( modalDialog(
      title = "Download data",
      shiny::dateRangeInput(
        "dl_dates", "Select date range",
        start = min(d_city()$date), end = max(d_city()$date)
      ),
      checkboxGroupInput(
        "dl_vars", "Select variables to download",
        choices = names(d), selected = names(d), inline = TRUE
      ),
      footer = list(
        downloadButton("download"),
        modalButton("Cancel")
      )
    ) )
  }) |>
    bindEvent(input$download_modal)
  
  output$download = downloadHandler(
    filename = function() {
      paste0(
        input$name |>
          stringr::str_replace(" ", "_") |>
          tolower(), 
        ".csv"
      )
    },
    content = function(file) {
      readr::write_csv(
        d_city() |>
          filter(date >= input$dl_dates[1] & date <= input$dl_dates[2]) |>
          select(input$dl_vars), 
        file
      )
    }
  )
  
  d_city = reactive({
    req(input$name)
    d |>
      filter(name %in% input$name)
  })
  
  observe({
    updateSelectInput(
      inputId = "name", 
      choices = d |>
        filter(region == input$region) |>
        pull(name) |>
        unique() |>
        sort()
    )
  })
  
  output$plot = renderPlot({
    d_city() |>
      ggplot(aes(x=date, y=.data[[input$var]])) +
      ggtitle(input$var) +
      geom_line() +
      theme_minimal()
  })
}

shinyApp(ui = ui, server = server)


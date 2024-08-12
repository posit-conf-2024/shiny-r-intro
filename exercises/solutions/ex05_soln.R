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

shinyApp(
  ui = fluidPage(
    titlePanel("Weather Data"),
    sidebarLayout(
      sidebarPanel(
        selectInput(
          "region", "Select a region",
          choices = c(),
        ),
        selectInput(
          "name", "Select an airport",
          choices = c()
        ),
        selectInput(
          "var", "Select a variable",
          choices = d_vars, selected = "temp"
        ),
        hr(),
        fileInput("upload", "Upload a file", accept = ".csv")
      ),
      mainPanel( 
        plotOutput("plot")
      )
    )
  ),
  server = function(input, output, session) {
    
    d = reactive({
      req(input$upload)
      ext = tools::file_ext(input$upload$datapath)
      
      validate(
        need(ext == "csv", "Please upload a csv file")
      )
      
      readr::read_csv(input$upload$datapath)
    })
    
    d_city = reactive({
      req(input$name)
      req(d())
      
      d() |>
        filter(name %in% input$name)
    })
    
    observe({
      updateSelectInput(
        inputId = "name", 
        choices = d() |>
          filter(region == input$region) |>
          pull(name) |>
          unique() |>
          sort()
      )
    })
    
    observe({
      updateSelectInput(
        inputId = "region", 
        choices = d() |>
          pull(region) |>
          unique() |>
          sort()
      )
    }) |>
      bindEvent(d())
    
    output$plot = renderPlot({
      d_city() |>
        ggplot(aes(x=date, y=.data[[input$var]])) +
        ggtitle(input$var) +
        geom_line() +
        theme_minimal()
    })
  }
)


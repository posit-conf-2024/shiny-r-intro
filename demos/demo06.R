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
        choices = d_vars, selected = "temp_avg"
      ),
      downloadButton("download")
    ),
    mainPanel( 
      plotOutput("plot")
    )
  )
)

server = function(input, output, session) {
  
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
      readr::write_csv(d_city(), file)
    }
  )
  
  d_city = reactive({
    req(input$name)
    d |>
      filter(name %in% input$name)
  })
  
  observe({
    updateSelectInput(
      session, "name",
      choices = d |>
        distinct(region, name) |>
        filter(region == input$region) |>
        pull(name)
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


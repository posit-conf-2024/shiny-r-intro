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
      radioButtons(
        "name", "Select an airport",
        choices = c(
          "Seattle-Tacoma",
          "Raleigh-Durham",
          "Houston Intercontinental",
          "Denver",
          "Los Angeles",
          "John F. Kennedy"
        )
      ),
      selectInput(
        "var", "Select a variable",
        choices = d_vars, selected = "temp_avg"
      )
    ),
    mainPanel( 
      plotOutput("plot"),
      tableOutput("minmax")
    )
  )
)

server = function(input, output, session) {
  output$minmax = renderTable({
    d |>
      filter(name %in% input$name) |>
      mutate(
        year = lubridate::year(date) |> as.integer()
      ) |>
      summarize(
        min_temp = min(temp_min),
        max_temp = max(temp_max),
        .by = year
      )
  })
  
  output$plot = renderPlot({
    d |>
      filter(name %in% input$name) |>
      ggplot(aes(x=date, y=.data[[input$var]])) +
      geom_line() +
      theme_minimal()
  })
}

shinyApp(ui = ui, server = server)

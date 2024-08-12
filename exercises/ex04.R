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
        choices = c("West", "Midwest", "Northeast", "South")
      ),
      selectInput(
        "name", "Select an airport", choices = c()
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
  observe({
    updateSelectInput(
      session, "name",
      choices = d |>
        distinct(region, name) |>
        filter(region == input$region) |>
        pull(name)
    )
  })
  
  d_city = reactive({
    d |>
      filter(name %in% input$name)
  })
  
  output$plot = renderPlot({
    d_city() |>
      ggplot(aes(x=date, y=.data[[input$var]])) +
      ggtitle(names(d_vars)[d_vars==input$var]) +
      geom_line() +
      theme_minimal()
  })
  
  output$minmax = renderTable({
    d_city() |>
      mutate(
        year = lubridate::year(date) |> as.integer()
      ) |>
      summarize(
        `min temp` = min(temp_min),
        `max temp` = max(temp_max),
        .by = year
      )
  })
}

shinyApp(ui = ui, server = server)

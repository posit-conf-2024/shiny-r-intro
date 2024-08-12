library(tidyverse)
library(shiny)

d = readr::read_csv(here::here("data/weather.csv"))

ui = fluidPage(
  titlePanel("Temperatures at Major Airports"),
  sidebarLayout(
    sidebarPanel(
      #checkboxGroupInput(
      selectInput(
        "name", "Select an airport",
        choices = c(
          "Seattle-Tacoma",
          "Raleigh-Durham",
          "Houston Intercontinental",
          "Denver",
          "Los Angeles",
          "John F. Kennedy"
        ),
        selected = c("Seattle-Tacoma", "Raleigh-Durham"),
        multiple = TRUE
      ) 
    ),
    mainPanel( 
      plotOutput("plot")
    )
  )
)

server = function(input, output, session) {
  output$plot = renderPlot({
    d |>
      filter(name %in% input$name) |>
      ggplot(aes(x=date, y=temp_avg, color=name)) +
      geom_line() +
      theme_minimal()
  })
}

shinyApp(ui = ui, server = server)

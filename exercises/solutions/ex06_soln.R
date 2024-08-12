library(tidyverse)
library(shiny)
library(bslib)

d = readr::read_csv(here::here("data/weather.csv"))

d_vars = c("Average temp" = "temp_avg",
           "Min temp" = "temp_min",
           "Max temp" = "temp_max",
           "Total precip" = "precip",
           "Snow depth" = "snow",
           "Wind direction" = "wind_direction",
           "Wind speed" = "wind_speed",
           "Air pressure" = "air_press")

ui = page_sidebar(
  theme = bs_theme(bootswatch = "zephyr", base_font = "Prompt", code_font = "Fira Sans"),
  title = "Weather Data",
  sidebar = sidebar(
    selectInput(
      "region", "Select a region", 
      choices = c("West", "Midwest", "Northeast", "South")
    ),
    selectInput(
      "name", "Select an airport", choices = c()
    )
  ),
  card(
    card_header(
      textOutput("title"),
      popover(
        bsicons::bs_icon("gear", title = "Settings"),
        selectInput(
          "var", "Select a variable",
          choices = d_vars, selected = "temp_avg"
        )
      ),
      class = "d-flex justify-content-between align-items-center"
    ),
    card_body(
      plotOutput("plot")
    ),
    full_screen = TRUE
  ),
  uiOutput("valueboxes")
)

server = function(input, output, session) {
  bslib::bs_themer()
  
  observe({
    updateSelectInput(
      session, "name",
      choices = d |>
        distinct(region, name) |>
        filter(region == input$region) |>
        pull(name)
    )
  })
  
  output$valueboxes = renderUI({
    clean = function(x) {
      round(x,1) |> paste("°C")
    }
    
    layout_columns(
      value_box(
        title = "Average Temp",
        value = mean(d_city()$temp_avg, na.rm=TRUE) |> clean(),
        showcase = bsicons::bs_icon("thermometer-half"),
        theme = "success"
      ),
      value_box(
        title = "Minimum Temp",
        value = min(d_city()$temp_min, na.rm=TRUE) |> clean(),
        showcase = bsicons::bs_icon("thermometer-snow"),
        theme = "primary"
      ),
      value_box(
        title = "Maximum Temp",
        value = max(d_city()$temp_max, na.rm=TRUE) |> clean(),
        showcase = bsicons::bs_icon("thermometer-sun"),
        theme = "danger"
      )
    )
  })
  
  output$title = renderText({
    names(d_vars)[d_vars==input$var]
  })
  
  d_city = reactive({
    req(input$name)
    d |>
      filter(name %in% input$name)
  })
  
  output$plot = renderPlot({
    d_city() |>
      ggplot(aes(x=date, y=.data[[input$var]])) +
      geom_line() +
      theme_minimal()
  })
}

thematic::thematic_shiny()

shinyApp(ui = ui, server = server)

library(tidyverse)

start = lubridate::ymd("2020-01-01")
end = lubridate::ymd(today())

regions = list(
  Northeast = c("ME", "NH", "VT", "MA", "RI", "CT", "NY", "NJ", "PA"),
  South = c("DE", "MD", "VA", "WV", "NC", "SC", "GA", "FL", "KY", "TN", "AL", "MS", "AR", "LA", "TX", "OK"),
  Midwest = c("OH", "MI", "IN", "IL", "WI", "MN", "IA", "MO", "ND", "SD", "NE", "KS"),
  West = c("MT", "ID", "WY", "CO", "NM", "AZ", "UT", "NV", "WA", "OR", "CA", "AK", "HI")
) 
regions = map2_dfr(
  regions,
  names(regions),
  ~ tibble(state = .x, region = .y)
)



stations_full =  "https://bulk.meteostat.net/v2/stations/full.json.gz" |>
  url() |>
  gzcon() |>
  readr::read_file() |>
  jsonlite::fromJSON(simplifyVector = FALSE) |>
  tibble(json = _) |>
  unnest_wider(json) |>
  filter(country == "US")

stations = stations_full  |>
  mutate(
    name = map_chr(name, "en") |> 
      stringr::str_remove_all("Airport|International") |>
      stringr::str_squish(),
    daily_start = map_chr(inventory, c("daily","start"), .default = NA) |> lubridate::ymd(),
    daily_end = map_chr(inventory, c("daily","end"), .default = NA) |> lubridate::ymd(),
    state = region,
    icao = map_chr(identifiers, "icao", .default = NA)
  ) |>
  unnest_wider(location) |>
  filter(
    #str_detect(name, "International"),
    daily_start <= start,
    #daily_end >= end,
    !is.na(state),
    !is.na(icao),
    !state %in% c("HI", "AK"),
    state %in% state.abb,
    icao %in% c("KATL", "KDFW", "KDEN", "KLAX", "KORD", 
                "KJFK", "KMCO", "KLAS", "KCLT", "KMIA", 
                "KSEA", "KSFO", "KEWR", "KPHX", "KIAH", 
                "KBOS", "KRDU", "KPDX")
  ) |>
  select(-region) |>
  left_join(
    regions, by = "state"
  ) |> 
  select(id, name, icao, country, state, region, longitude, latitude)

read_station_data = function(id, start = NULL, end = NULL) {
  df = glue::glue("https://bulk.meteostat.net/v2/daily/{id}.csv.gz") |>
    readr::read_csv(
      col_names = c("date", "tavg", "tmin", "tmax", "prcp", "snow", "wdir", "wspd", "wpgt", "pres", "tsun"),
      show_col_types = FALSE, progress = FALSE
    ) |>
    select(-tsun) |>
    mutate(
      date = lubridate::ymd(date),
      id = id
    ) |>
    relocate(
      id
    )
  
  if (!is.null(start))
    df = filter(df, date >= ymd(start))
  
  if (!is.null(end))
    df = filter(df, date <= ymd(end))
  
  df
}


d = map_dfr(
  stations$id, read_station_data, 
  start = start, end = end,
  .progress = TRUE
) |>
  full_join(x = stations, y = _, by = "id") |> 
  select(-wpgt) |>
  rename(
    airport_code = icao,
    temp_avg = tavg, 
    temp_min = tmin,
    temp_max = tmax,
    wind_direction = wdir,
    wind_speed = wspd, 
    precip = prcp,
    air_press = pres
  ) 

d |> 
  filter(airport_code != 'KPDX') |>
  write_csv(here::here("data/weather.csv"))

d |> 
  filter(airport_code == 'KPDX') |>
  write_csv(here::here("data/portland.csv"))


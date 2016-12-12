
library(jsonlite) #connecting to API
library(dplyr) #pipeline
library(lubridate) #to clean date/time
library(tidyr) #for separate() function
library(ggplot2) #graphing
library(scales) #axis scaling
library(leaflet) #for interactive plots
library(RColorBrewer) #adding color!

#Accessing API
bike <- fromJSON("https://data.phila.gov/resource/pbdj-svpx.geojson")

#Defining the two tables of interest
bike_prop <- bike$features$properties
bike_geom <- bike$features$geometry

#Unlisting coordinate into two columns, then binding back to dataset
coords <- data.frame(matrix(unlist(bike_geom$coordinates), nrow = 804, byrow = T)) 

#Selecting columns of interest
bike_data <- bike_prop %>% 
  cbind(coords) %>%
  rename(lat = X1, long = X2) %>%
  separate(theft_date, into = c("Date","Time"), sep="T", remove = FALSE) %>%
  select(location = location_b, theft_date = Date, theft_hour, stolen_val, lat, long)

bike_data$theft_hour <- strptime(bike_data$theft_hour, "%H") %>%
  substr( 12, 16) #to make a better time format

#Converting columns to correct format
bike_data$stolen_val <- as.numeric(bike_data$stolen_val) 
bike_data$theft_date <- as.Date(bike_data$theft_date)

head(bike_data)
plot(bike_data$theft_date, bike_data$stolen_val)


#Graphing thefts/day
dplot <- bike_data %>% 
  group_by(theft_date) %>% 
  tally() %>% 
  arrange(desc(n))
ggplot(dplot, aes(theft_date, n)) + geom_line() +
  scale_x_date(labels = date_format("%m-%Y")) +xlab("Date") + ylab("Daily Thefts")

#Grouping by location of theft
hist <- bike_data %>%
  group_by(location) %>%
  tally() %>%
  arrange(desc(n))
head(hist, 10)
tail(hist, 10)

#Grouping by time of theft
ttime <- bike_prop %>%
  group_by(theft_hour) %>%
  tally() %>%
  arrange(desc(n))
plot(ttime, xlab = "Hour of the day", ylab = "Number of Thefts")
head(ttime)

summary(bike_data$stolen_val)
hist(bike_data$stolen_val, xlab = "Stolen Value", main = "", breaks = 30)


#Adding color to months
bike_data$Month <- month(bike_data$theft_date, label=TRUE, abbr=TRUE)
bike_data$Colors <- factor(bike_data$Month, labels=brewer.pal(6, 'Paired'))

#Map showing timeline of thefts
leaflet() %>%
  addProviderTiles('CartoDB.Positron') %>%
  setView(lng=-75.06048, lat=40.03566, zoom = 10) %>%
  addCircleMarkers(lng=bike_data$long, lat=bike_data$lat, 
      popup=paste(bike_data$theft_date, bike_data$theft_hour, sep=' at '), 
      color=bike_data$Colors)


#Interactive map clustering locations
points <- cbind(bike_data$long, bike_data$lat)
points <- points[-796,]

leaflet() %>%
  addProviderTiles('CartoDB.Positron',
                   options = providerTileOptions(noWrap = TRUE)) %>% 
  #setView(-75.1652, 39.9526, zoom = 10) %>%
  addMarkers(data = points, 
      popup=paste(bike_data$theft_date, bike_data$theft_hour, sep=' at '),
      clusterOptions = markerClusterOptions()
  )


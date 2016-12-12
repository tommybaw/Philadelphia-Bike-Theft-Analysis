#Analyzing Bike Thefts in Philadelphia

Studies have shown that there are patterns behind bicycle thefts. Some factors include daylight/darkness, geographic location, and characteristics of the bicycle. The goal of this analysis is to see what insights can be drawn and confirmed by previous studies using packages in R. 

I decided to analyze the most recent dataset uploaded by the City of Philadelphia ranging from 9/15/2014 to 2/8/2015. Included are the 804 bicycle thefts reported to the police during that time including supplemental information such as the date, time, location, and value of the bike.

##Data Munging

The list of packages used in my analysis.
```
library(jsonlite) #connecting to API
library(dplyr) #pipeline
library(lubridate) #to clean date/time
library(tidyr) #for separate() function
library(ggplot2) #graphing
library(scales) #axis scaling
library(leaflet) #for interactive plots
library(RColorBrewer) #adding color!
```

In order to load the data, a request was made directly through the API using jsonlite, allowing for a connection between JSON data and the R terminal. From there I defined the two tables containing the variables of interest as well as printing the structure to see what steps to take for concatenation. Some things I noticed:

- Coordinates is contained as a list of vectors
- Theft_date is listed as a string
- Numeric columns are listed as characters

```
bike <- fromJSON("https://data.phila.gov/resource/pbdj-svpx.geojson")
bike_prop <- bike$features$properties
bike_geom <- bike$features$geometry

> str(bike)
List of 3
 $ type   ∶ chr "FeatureCollection"
 $ features:'data.frame':804 obs.of  3 variables:
  ..$ type     ∶ chr [1:804] "Feature" "Feature" "Feature" "Feature" ...
  ..$ geometry ∶'data.frame':804 obs.of  2 variables:
  ....$ type      ∶ chr [1:804] "Point" "Point" "Point" "Point" ...
  ....$ coordinates:List of 804
  ......$∶ num [1:2] 39.9 -75.2
  ......$∶ num [1:2]39.9 -75.1
		:
		:
  ..$ properties:'data.frame':804 obs.of  33 variables:
  ....$ stolen_val                ∶ chr [1:804] "1400" "500" "600" "400" ...
  ....$ theft_date               ∶ chr [1:804] "2014-10-26T00:00:00.000" "2014-10-26T00:00:00.000"
		:
```

This was first cleaned by unlisting coordinates into a column for latitude and longitude. I then used the dplyr and tidyr package to clean the date, time, and then selected only the relevant columns for analysis.
```
#Unlisting coordinate into two columns,then binding back to dataset
coords <- data.frame(matrix(unlist(bike_geom$coordinates),nrow = 804,byrow = T)) 

#Selecting columns of interest
bike_data <- bike_prop %>% 
  cbind(coords) %>%
  rename(lat = X1,long = X2) %>%
  separate(theft_date,into = c("Date","Time"),sep="T",remove = FALSE) %>%
  select(location = location_b,theft_date = Date,theft_hour,stolen_val,lat,long)

bike_data$theft_hour <- strptime(bike_data$theft_hour,"%H") %>%
  substr( 12,16) #to make a better time format

#Converting columns to correct format
bike_data$stolen_val <- as.numeric(bike_data$stolen_val) 
bike_data$theft_date <- as.Date(bike_data$theft_date)
```

We now have a clean dataset to work with.




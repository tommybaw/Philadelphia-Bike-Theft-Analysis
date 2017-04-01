# Analyzing Bike Thefts in Philadelphia

Studies have shown that there are patterns behind bicycle thefts. Some factors include daylight/darkness, geographic location, and characteristics of the bicycle. The goal of this analysis is to see what insights can be drawn and confirmed by previous studies using packages in R. 

I decided to analyze the most recent dataset uploaded by the City of Philadelphia ranging from 9/15/2014 to 2/8/2015. Included are the 804 bicycle thefts reported to the police during that time including supplemental information such as the date, time, location, and value of the bike.

## Data Munging

The list of packages used in my analysis.
```r
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

```r
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
```r
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

![alt tag](https://github.com/tommybaw/Philadelphia-Bike-Theft-Analysis/blob/master/Other/Dataset.png)


Now for the fun part! 

## Theft Trends

With the dates of reported thefts we can look at seasonality. Using ggplot can we see if the number of thefts changes over time?
```r
dplot <- bike_data %>%
group_by(theft_date) %>%
tally() %>%
arrange(desc(n))
ggplot(dplot,aes(theft_date,n)) + geom_line() +
scale_x_date(labels = date_format("%m-%Y")) +xlab("Date") + ylab("Daily Thefts")
```
![alt tag](https://github.com/tommybaw/Philadelphia-Bike-Theft-Analysis/blob/master/Other/Trend.png)

There is a definite downward trend after each month. One can guess that as we get closer to the colder months, there will be less bikes in the area to be stolen. There were even days after December where there were no thefts reported. But even with this information we can’t make any conclusions regarding causation, only that there is a strong correlation between temperature and thefts.



## Time of day


Grouping by hour of the day shows that thefts occur most often at 5PM. The plot also has an upward trend when getting closer to the end of the work day and during darker hours of the day.
```r
ttime <- bike_prop %>%
  group_by(theft_hour) %>%
  tally() %>%
  arrange(desc(n))
plot(ttime,xlab = "Hour of the day",ylab = "Number of Thefts")

> head(ttime)
# A tibble: 6 × 2
  theft_hour     n
       <chr> <int>
1         17    82
2         18    70
3         16    64
4         14    63
5         15    56
```

![alt tag](https://github.com/tommybaw/Philadelphia-Bike-Theft-Analysis/blob/master/Other/Time.png)



## Stolen Value

This seemed like an interesting variable to look into as a more valuable bike would be more appealing to steal. But we quickly see that it would be difficult to make that conclusion. We can once again talk about correlation not being causation, meaning there probably aren’t a whole lot of $1,000+ bikes being used in Philadelphia compared to ones of lesser value. It would then make sense that there will be a much higher number of thefts for lower end bikes. The summary statistics and histogram confirm this by showing a highly right skewed distribution. More information is needed to determine likelihood of theft based on value. 
```r
> summary(bike_data$stolen_val)
   Min.1st Qu.  Median    Mean 3rd Qu.    Max.
    0.0   150.0   300.0   432.3   550.0  6000.0

hist(bike_data$stolen_val,xlab = "Stolen Value",main = "",breaks = 30)
```
![alt tag](https://github.com/tommybaw/Philadelphia-Bike-Theft-Analysis/blob/master/Other/Value.png)



## Geospatial Analysis

One of the more interesting aspects of this dataset is the longitude and latitude information provided for the location of each theft. With the leaflet package it’s now possible to plot each point on a map of Philadelphia. To look at seasonality again, I added some color where a green dot appears for thefts in September and October, red in November and December, and blue in January and February. 

```r
#Adding color to months
bike_data$Month <- month(bike_data$theft_date,label=TRUE,abbr=TRUE)
bike_data$Colors <- factor(bike_data$Month,labels=brewer.pal(6,'Paired'))

#Map showing timeline of thefts
leaflet() %>%
  addProviderTiles('CartoDB.Positron') %>%
  setView(lng=-75.06048,lat=40.03566,zoom = 10) %>%
  addCircleMarkers(lng=bike_data$long,lat=bike_data$lat,
      popup=paste(bike_data$theft_date,bike_data$theft_hour,sep=' at '),
      color=bike_data$Colors)
```

![alt tag](https://github.com/tommybaw/Philadelphia-Bike-Theft-Analysis/blob/master/Other/ColorMap.png)

The mapping shows a large cluster of thefts occurring in center city and thinning out as it travels northeast. Green is the most predominant color as expected followed by red. By clicking on a specific dot we can see the date and time the theft occurred but with so many points on this map it seems a bit cluttered. Next we’ll try to make this more visually appealing.

##Adding Clustering

Part of the leaflet package is the option to add clusters. Hovering over each will show the area it covers while clicking will zoom in and show more refined clusters all the way down to individual incidents. Let’s go step by step on what trends we see.

```r
points <- cbind(bike_data$long,bike_data$lat)
points <- points[-796,]

leaflet() %>%
  addProviderTiles('CartoDB.Positron',
                   options = providerTileOptions(noWrap = TRUE)) %>% 
  #setView(-75.1652,39.9526,zoom = 10) %>%
  addMarkers(data = points,
      popup=paste(bike_data$theft_date,bike_data$theft_hour,sep=' at '),
      clusterOptions = markerClusterOptions()
  )
```
![alt tag](https://github.com/tommybaw/Philadelphia-Bike-Theft-Analysis/blob/master/Other/Maploop.gif)

With clusters we can get a better picture of relative thefts by location. 591 of the total 804 thefts occur around center city (~ 74%). 

Zooming in, the large cluster now splits into three smaller regions with the two more popular areas being represented by center city and University City. As a very recent Drexel graduate, I was very curious with the latter.

Drexel is definitely a popular area for thefts. Good thing I never rode a bike!



## Final Thoughts

So what can we conclude after all this? 

Time of day and year appear to have an effect on bicycle thefts. So we can warn people not to leave their bikes out at night or near certain heavily populated areas. But it might be more important to note that at the end of the day, the data may be biased since it only contains thefts reported to the police. With a city as large as Philadelphia there’s a good chance some neighborhoods are less likely to report a stolen bike than others.


### Future Ideas

This initial analysis left me with some questions that I hope to see the City of Philadelphia enhancing the dataset with.
- What type of lock was on the bike? (E.g. cable lock, U-lock, no lock)
- Adding onto value of bike, what type of bike was this? (E.g. road, mountain, BMX)

In the future I’d also like to include the original data from 1/1/2010 – 9/16/2013. It would be interesting to implement the leaflet map into an R shiny app to visualize trends on a yearly/hourly	 basis. 

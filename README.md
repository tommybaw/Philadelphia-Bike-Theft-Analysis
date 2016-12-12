# Philadelphia-Bike-Theft-Analysis
Taking a closer look at the dataset on OpenDataPhilly using R


Studies have shown that there are patterns behind bicycle thefts. Some factors include
daylight/darkness, geographic location, and characteristics of the bicycle. The goal of this analysis
is to see what insights can be drawn and confirmed by previous studies using packages in R.

The dataset can be found here: https://www.opendataphilly.org/dataset/bicycle-thefts

## Getting started
To pull the data, simply run the first line:
```
bike <- fromJSON("https://data.phila.gov/resource/pbdj-svpx.geojson")
```

![alt tag](https://github.com/tommybaw/Philadelphia-Bike-Theft-Analysis/blob/master/Maploop.gif)


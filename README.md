# Philadelphia-Bike-Theft-Analysis
Taking a closer look at the dataset on OpenDataPhilly using R


Studies have shown that there are patterns behind bicycle thefts. Some factors include
daylight/darkness, geographic location, and characteristics of the bicycle. The goal of this analysis
is to see what insights can be drawn and confirmed by previous studies using packages in R.

The dataset can be found here: https://www.opendataphilly.org/dataset/bicycle-thefts

## Getting started
Make sure to have all packages installed.

Then simply run the code in Analysis.R

To pull the data, simply run:
```
bike <- fromJSON("https://data.phila.gov/resource/pbdj-svpx.geojson")
```
**Current visualization:**
![alt tag](https://github.com/tommybaw/Philadelphia-Bike-Theft-Analysis/blob/master/Other/Maploop.gif)


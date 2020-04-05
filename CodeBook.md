---
title: "CodeBook"
author: "JoseO!"
date: "4/3/2020"
output: html_document
---
## Getting and Cleaning Data -- Code Book

This is a Code Book document corresponding to the course project of "Getting and Cleaning Data" course on Coursera.

## Safety first: "RAW Codebook"

This CodeBook **updates and enhaces** the information found in the original "raw" dataset CodeBook from Samgung's UCI HAR team. Yo can found it [here](InputData/UCI HAR Dataset/README.txt). So, in order to fully understand this dataset, it is **highly recommended** to understand first what all the original measurements are all about.

As a summary: the original dataset is obtained from measuring the activity on specific sensors on Samsung devices for 30 test subjects. The measured devices are: accelerometer and gyroscope and, for each one, a series of data is obtained; basically: acceleration and angular velocity (in each one of the XYZ axis). After that, data is processed in order to compute a series of values and **features** to feed them to a ML System.

Please note that, as explained in the corresponding [README](InputData/UCI HAR Dataset/README.txt) file, after the whole processing, **al values are normalized to [-1,1]**. This fact has an important consequence, and it is that, despite original measurements where in "G" and "rad/s" units, normalized values no longer have units. That is: **data in this dataset has no units, it is obtained from normalized data**.

## Source dataset(s), and transformations

### "RAW" origin data
The origin dataset is composed by two series of data devised originally to train/test a Machine Learning system. Thus, the original "raw" data is decomposed in two subsets of three data sources each:

* Training dataset
    * Features ("X""), inputs.
    * Results ("Y"), outputs (activity code).
    * Subjects
* Test dataset
    * Features ("X""), inputs.
    * Results ("Y"), outputs (activity code.
    * Subjects
    
Each "X" subset corresponds to 561 features derived from original raw measurements, and "subjects" give us an unique subject ID for each row (measurement)

In order to make data more tidy, we must also use the activty labels instead of the activity codes. Activity labels can be found also in the original repository, in [activity_labels.txt](InputData/UCI HAR Dataset/activity_labels.txt).

### Transformations

Transformation of the source "raw" dataset(s) into the desired dataset is accomplished by a series of steps:

1. Read activity labels (from [activity_labels.txt](InputData/UCI HAR Dataset/activity_labels.txt)) and add two labels: activity_id and subject
2. Read feature names (from [features.txt](InputData/UCI HAR Dataset/features.txt))
3. Read N 561 features lines from both train/test data (X_{train,test}.txt)
    1. ```cbind``` each one of them with data from subjects (subject_{train,test}.txt)
    2. ```cbind``` each one of them with data from activities (y_{train,test}.txt)
4. Bind (```rbind```) both data sub-sets into one
5. Add column names (from step 1)
6. Add a column derived from the activity id column to have a human-friendly activity label:
```
full_ds$activity <- activity_labels[with(full_ds,activity_id)]
```
7. Filter columns. The assignment description tells us to keep only those measurements corresponding to mean and stdev. After carefully looking throung the original codebook, we can find out that those column share a common pattern, and this pattern is that the have either the atom "mean()" or the atom "std()" in their names. So, in order to keep only those columns, we need to select (grep) in the dataset column names these regular expressions **but also keep some other insteresting columns for us: activity and subject:
```
mean_std_names <- append(grep("(mean|std)\\(\\)",feature_names,value=T),c("activity","subject"))
full_ds <- full_ds[mean_std_names]
```
8. Once we have our filtered columns, we can advance and rename variables (column names) to make our dataset more tidy. The assignment does not give us much clues, so we can decide on our own. In my case: I've decided to apply some basic transformations; basically:
    a. I prefer "." to "-" (and "_") for separators in variable names names.
    b. Also, I prefer always lowercase. A t or f at the beginning of the variable name is quite cryptic, so I've decided to use "time" or "freq" (for frequency; I believe frequency is too long ad freq is quite explanatory).
    c. Also, expand other abbreviations (Acc -> acceleration)
    d. Finally, use "stdev" instead of "std" for standard deviation. Personal preference.
9. At this point, we have a dataset corresponding to steps 1-4 of the assignment, we can go further and make necessary transformations to also accomplish step 5.
10. In order to do that, we neeed to average all values grouping by subject/activity; we can use  the ```aggregate``` function for that. Note that first we select all but the last two column (activity and subject, which we don't want to average, but use as grouping criteria instead); after that, we call aggregate, passing in the columns we want to average and the grouping criteria (we can make use of this parameter also to name the new columns: activity and subject). Once this is done, in order to make this dataset also tidy and make explicit the last transformation, we rename all column names starting with (t|f) (Time|Frequency) an add them a ".average" suffix.
```
selected_columns <- head(mean_std_names,-2)
new_ds <- aggregate(x=full_ds[selected_columns],by=list(activity=full_ds$activity,subject=full_ds$subject),FUN=mean)
new_names <- gsub("^([tf].+)$","\\1.average",names(new_ds))
names(new_ds) <- new_names
```
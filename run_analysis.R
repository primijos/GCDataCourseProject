# R Script for the final project for the "Getting and Cleaning Data"
# José Oliver - JoseO! - primijos at gmail dot com

# some constants
# Number of lines to read for each dataset. Useful if you want to perform
# some quick change/test in the script logic and just load part of the
# test / training data sets
LINES <- -1 #use -1 to read all
# relative path for input dataset
ROOT_PATH <- "./InputData/UCI HAR Dataset"
# features names file
FEATURES_PATH <- sprintf("%s/%s",ROOT_PATH,"features.txt")
# activities integer -> name mapping file
ACTIVITIES_PATH <- sprintf("%s/%s",ROOT_PATH,"activity_labels.txt")

# function to load features from a dataset, must receive the dataset
# we want to load, either "test" or "train", no error checking is
# performed, just resort to "file not found" errors if none of those
# values is passed. Since this is for internal usage, looks enough
load_dataset <- function(which_ds,lines=-1) {
    # compute names for data, activities and subjects based
    # on root path and dataset (train/test)
    ds_file <- sprintf("%s/%s/X_%s.txt",ROOT_PATH,which_ds,which_ds)
    ac_file <- sprintf("%s/%s/y_%s.txt",ROOT_PATH,which_ds,which_ds)
    su_file <- sprintf("%s/%s/subject_%s.txt",ROOT_PATH,which_ds,which_ds)
    # actual data reading
    # despite it looks a proper function to use, AVOID using read.fortran.
    # For some reason it eats all my laptop's memory (8GB) and drives the
    # computer into a memory trash state. Instead, use read.table
    # DO NOT ds <- read.fortran(ds_file,c("561F16"), n=lines)
    ds <- read.table(ds_file, nrows=lines)
    act <- read.fortran(ac_file,c("1I1"), n=lines)
    subjects <- read.fortran(su_file,c("1I2"),n=lines)
    # join columns and return result
    cbind(cbind(ds,act),subjects)
}

# Load activity labels; we can throw away the numeric part (gsub) and just
# keep the text description. Since they are ordered in the file we don't
# need to order or do any mapping: for activity code "i" the "ith" element
# of this vector corresponds to its label.
# I personally prefer lowercase, so we apply tolower to the labels also
activity_labels <- tolower(gsub("^[0-9]+ ","",readLines(ACTIVITIES_PATH)))

# Load feature names from the features_path file. Since the load_dataset function will
# also add columns for activity and subject, we must add those column names too
feature_names <- append(gsub("^[0-9]+ ","",readLines(FEATURES_PATH)),c("activity_id","subject"))
train_ds <- load_dataset("train", lines=LINES)
test_ds <- load_dataset("test", lines=LINES)
# Concatenate/merge both dataframes. Since they have the exact same shape, it can be done
# directly.
full_ds <- rbind(train_ds,test_ds)
# at this point, full_ds corresponds to the first task in the project task list

# add names for columns
names(full_ds) <- feature_names

# add a new column "activity" with descriptive values corresponding to "activity id"
full_ds$activity <- activity_labels[with(full_ds,activity_id)]

# get only columns containing the measurements on the mean and standard deviation;
# from the project description there's certain ambiguity, but looks like the most
# plausible interpretation is to keep those columns refereing to mean/stdev, and
# those columns include "mean()" and "std()" in their names, so we can find them
# using grep. Don't forget to get also "activity" and "subject" columns, we need
# them later
mean_std_names <- append(grep("(mean|std)\\(\\)",feature_names,value=T),c("activity","subject"))
full_ds <- full_ds[mean_std_names]
# at this point, full_ds corresponds to the second+third task in the project task list

# we are told to use descriptive variable names, so I've decided to apply some
# transformations; basically: I prefer "." to "-" (and "_") for separators in
# variable names names. Also, I prefer always lowercase. A t or f at the beginning
# of the variable name is quite cryptic, so I've decided to use "time" or "freq"
# (for frequency; I believe frequency is too long ad freq is quite explanatory).
# Also, expand other abbreviations (Acc -> acceleration)
# Finally, use "stdev" instead of "std" for standard deviation. Personal preference.
mean_std_names <- gsub("-",".",mean_std_names)
mean_std_names <- gsub("([XYZ])$","\\L\\1",mean_std_names,perl=T,fixed=F)
mean_std_names <- gsub("\\(\\)","",mean_std_names)
mean_std_names <- gsub("^f","freq",mean_std_names)
mean_std_names <- gsub("^t","time",mean_std_names)
mean_std_names <- gsub("Acc",".acceleration",mean_std_names)
mean_std_names <- gsub("Body",".body",mean_std_names)
mean_std_names <- gsub("Gravity",".gravity",mean_std_names)
mean_std_names <- gsub("Gyro",".gyro",mean_std_names)
mean_std_names <- gsub("Jerk",".jerk",mean_std_names)
mean_std_names <- gsub("Mag",".magnitude",mean_std_names)
mean_std_names <- gsub("\\.std",".stdev",mean_std_names)
names(full_ds) <- mean_std_names
# at this point, full_ds corresponds to the 4th task in the project task list

# Now we need to create a new data set by grouping by activity+subject. We want
# to compute the average of the rest of the columns.
# First select with columns we want to average: all of them but the last two
selected_columns <- head(mean_std_names,-2)

# Do the aggregation
new_ds <- aggregate(x=full_ds[selected_columns],by=list(activity=full_ds$activity,subject=full_ds$subject),FUN=mean)

# add ".average" to the end of every column in order to make clear that the values
# in those columns are the average of others (actually, in this case, the average of
# a mean. Apply the change only for time/frequency columns, do not apply to
# activity/subject columns. For doing so, just gsub those names beginning with t or f
new_names <- gsub("^([tf].+)$","\\1.average",names(new_ds))
names(new_ds) <- new_names
# at this point, new_ds corresponds to the 5th task in the project task list
# done

#!/bin/bash

# Task 1: Examine a table
echo "Task 1: Examine the schema of the Shakespeare table"
bq show bigquery-public-data:samples.shakespeare

# Task 2: Run the help command
echo -e "\nTask 2: Run the help command for bq query"
bq help query

echo -e "\nList all bq commands"
bq help

# Task 3: Run queries
echo -e "\nTask 3: Run a query to count the number of times the substring 'raisin' appears"
bq query --use_legacy_sql=false \
'SELECT
   word,
   SUM(word_count) AS count
 FROM
   `bigquery-public-data`.samples.shakespeare
 WHERE
   word LIKE "%raisin%"
 GROUP BY
   word'

echo -e "\nRun a query to search for the word 'huzzah'"
bq query --use_legacy_sql=false \
'SELECT
   word
 FROM
   `bigquery-public-data`.samples.shakespeare
 WHERE
   word = "huzzah"'

# Task 4: Create a new table
echo -e "\nTask 4: Create a new dataset named 'babynames'"
bq mk babynames

echo -e "\nConfirm the new dataset"
bq ls

echo -e "\nDownload the baby names data"
curl -LO http://www.ssa.gov/OACT/babynames/names.zip

echo -e "\nUnzip the baby names data"
unzip names.zip

echo -e "\nLoad the data into a new table named 'names2010'"
bq load babynames.names2010 yob2010.txt name:string,gender:string,count:integer

echo -e "\nConfirm the new table"
bq ls babynames

echo -e "\nShow the schema of the new table"
bq show babynames.names2010

# Task 5: Run queries on the new table
echo -e "\nTask 5: Query the top 5 most popular girls' names"
bq query "SELECT name, count FROM babynames.names2010 WHERE gender = 'F' ORDER BY count DESC LIMIT 5"

echo -e "\nQuery the top 5 most unusual boys' names"
bq query "SELECT name, count FROM babynames.names2010 WHERE gender = 'M' ORDER BY count ASC LIMIT 5"

echo -e "\nAll tasks have been successfully completed."

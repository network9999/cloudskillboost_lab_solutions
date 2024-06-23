#!/bin/bash

# Function to execute a BigQuery query
function execute_query {
    local query="$1"
    local output_file="$2"
    bq query --nouse_legacy_sql "$query" > "$output_file"
}

# Task 1: Pin a project to the BigQuery resource tree
# This cannot be automated with CLI as it involves UI interaction.

# Task 2: Find the total number of customers who went through checkout
# Fixing and running various queries to identify errors and get correct results

echo "Task 2: Find the total number of customers who went through checkout"

# Corrected query to view 1000 items
query1="SELECT * FROM \`data-to-insights.ecommerce.rev_transactions\` LIMIT 1000"
execute_query "$query1" "task2_query1_results.txt"

# Query to count unique visitors who reached checkout
query2="SELECT COUNT(DISTINCT fullVisitorId) AS visitor_count FROM \`data-to-insights.ecommerce.rev_transactions\` WHERE hits_page_pageTitle = 'Checkout Confirmation'"
execute_query "$query2" "task2_query2_results.txt"

# Task 3: List the cities with the most transactions with your ecommerce site
echo "Task 3: List the cities with the most transactions with your ecommerce site"

# Query to list cities with distinct visitors and total transactions
query3="SELECT geoNetwork_city, SUM(totals_transactions) AS total_products_ordered, COUNT(DISTINCT fullVisitorId) AS distinct_visitors, SUM(totals_transactions) / COUNT(DISTINCT fullVisitorId) AS avg_products_ordered FROM \`data-to-insights.ecommerce.rev_transactions\` GROUP BY geoNetwork_city HAVING avg_products_ordered > 20 ORDER BY avg_products_ordered DESC"
execute_query "$query3" "task3_query_results.txt"

# Task 4: Find the total number of products in each product category
echo "Task 4: Find the total number of products in each product category"

# Query to count distinct products in each product category
query4="SELECT COUNT(DISTINCT hits_product_v2ProductName) as number_of_products, hits_product_v2ProductCategory FROM \`data-to-insights.ecommerce.rev_transactions\` WHERE hits_product_v2ProductName IS NOT NULL GROUP BY hits_product_v2ProductCategory ORDER BY number_of_products DESC LIMIT 5"
execute_query "$query4" "task4_query_results.txt"

echo "All tasks completed. Check the result files for details."

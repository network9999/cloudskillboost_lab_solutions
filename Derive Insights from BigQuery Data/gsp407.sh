#!/bin/bash

# Task 1: Pin the lab project in BigQuery
echo "Task 1: Pin the lab project in BigQuery"

# Task 2: Explore ecommerce data and identify duplicate records
echo -e "\nTask 2: Explore ecommerce data and identify duplicate records"

# Expand the project and view table details
echo "Expanding data-to-insights project and viewing all_sessions_raw table details..."
bq show --format=prettyjson data-to-insights:ecommerce.all_sessions_raw

# Identify duplicate rows
echo "Identifying duplicate rows in all_sessions_raw table..."
bq query --use_legacy_sql=false \
'SELECT COUNT(*) as num_duplicate_rows, * FROM
`data-to-insights.ecommerce.all_sessions_raw`
GROUP BY
fullVisitorId, channelGrouping, time, country, city, totalTransactionRevenue, transactions, timeOnSite, pageviews, sessionQualityDim, date, visitId, type, productRefundAmount, productQuantity, productPrice, productRevenue, productSKU, v2ProductName, v2ProductCategory, productVariant, currencyCode, itemQuantity, itemRevenue, transactionRevenue, transactionId, pageTitle, searchKeyword, pagePathLevel1, eCommerceAction_type, eCommerceAction_step, eCommerceAction_option
HAVING num_duplicate_rows > 1;'

# Task 3: Write basic SQL on ecommerce data
echo -e "\nTask 3: Write basic SQL on ecommerce data"

# Query for total unique visitors and product views
echo "Querying for total unique visitors and product views..."
bq query --use_legacy_sql=false \
'SELECT
  COUNT(*) AS product_views,
  COUNT(DISTINCT fullVisitorId) AS unique_visitors
FROM `data-to-insights.ecommerce.all_sessions`;'

# Query for unique visitors by referring site
echo "Querying for unique visitors by referring site..."
bq query --use_legacy_sql=false \
'SELECT
  COUNT(DISTINCT fullVisitorId) AS unique_visitors,
  channelGrouping
FROM `data-to-insights.ecommerce.all_sessions`
GROUP BY channelGrouping
ORDER BY channelGrouping DESC;'

# Query for unique product names
echo "Querying for unique product names..."
bq query --use_legacy_sql=false \
'SELECT
  (v2ProductName) AS ProductName
FROM `data-to-insights.ecommerce.all_sessions`
GROUP BY ProductName
ORDER BY ProductName;'

# Query for the five products with the most views
echo "Querying for the five products with the most views..."
bq query --use_legacy_sql=false \
'SELECT
  COUNT(*) AS product_views,
  (v2ProductName) AS ProductName
FROM `data-to-insights.ecommerce.all_sessions`
WHERE type = "PAGE"
GROUP BY v2ProductName
ORDER BY product_views DESC
LIMIT 5;'

# Bonus: Refine the query to count unique product views
echo "Refining the query to count unique product views..."
bq query --use_legacy_sql=false \
'WITH unique_product_views_by_person AS (
  SELECT
    fullVisitorId,
    (v2ProductName) AS ProductName
  FROM `data-to-insights.ecommerce.all_sessions`
  WHERE type = "PAGE"
  GROUP BY fullVisitorId, v2ProductName
)
SELECT
  COUNT(*) AS unique_view_count,
  ProductName
FROM unique_product_views_by_person
GROUP BY ProductName
ORDER BY unique_view_count DESC
LIMIT 5;'

# Query for the total number of distinct products ordered and total units ordered
echo "Querying for the total number of distinct products ordered and total units ordered..."
bq query --use_legacy_sql=false \
'SELECT
  COUNT(*) AS product_views,
  COUNT(productQuantity) AS orders,
  SUM(productQuantity) AS quantity_product_ordered,
  v2ProductName
FROM `data-to-insights.ecommerce.all_sessions`
WHERE type = "PAGE"
GROUP BY v2ProductName
ORDER BY product_views DESC
LIMIT 5;'

# Expand the query to include the average amount of product per order
echo "Expanding the query to include the average amount of product per order..."
bq query --use_legacy_sql=false \
'SELECT
  COUNT(*) AS product_views,
  COUNT(productQuantity) AS orders,
  SUM(productQuantity) AS quantity_product_ordered,
  SUM(productQuantity) / COUNT(productQuantity) AS avg_per_order,
  (v2ProductName) AS ProductName
FROM `data-to-insights.ecommerce.all_sessions`
WHERE type = "PAGE"
GROUP BY v2ProductName
ORDER BY product_views DESC
LIMIT 5;'

# Completion message
echo -e "\nAll tasks have been successfully completed."

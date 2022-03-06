## SQL projects

The database contains three tables: website sessions, pageviews and orders.

The website_sessions table contains the following columns (472871 rows):
| Column Name | 
|-------------|
|website_session_id|
|created_at|
|user_id|
|is_repeat_session|
|utm_source|
|utm_campaign|
|utm_content|
|device_type|
|http_refer|

The website_pageviews table (1188124 rows):
| Column Name | 
|-------------|
|website_pageview_id|
|created_at|
|website_session_id|
|pageview_url|

The orders table (32313 rows):
| Column Name | 
|-------------|
|order_id|
|created_at|
|website_session_id|
|user_id|
|primary_product_id|
|item_purchased|
|price_usd|
|cogs_usd|

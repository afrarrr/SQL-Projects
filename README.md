## SQL projects

The database contains three tables: website sessions, pageviews and orders.

The website_sessions table contains the following columns:
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

The website_pageviews table:
| Column Name | 
|-------------|
|website_pageview_id|
|created_at|
|website_session_id|
|pageview_url|

The orders table:
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

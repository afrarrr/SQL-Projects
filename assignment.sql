USE mavenfuzzyfactory;

/* Find top traffic sources before April 12, 2012 */
SELECT utm_source, utm_campaign, http_referer, count(distinct(website_session_id)) AS sessions
FROM website_sessions
WHERE created_at < '2012-04-12'
GROUP BY utm_source, utm_campaign, http_referer
ORDER BY sessions desc;

/* Find the traffic source conversion rate for gsearch before 2012-04-14 */
select count(distinct website_sessions.website_session_id) as sessions, 
	   count(distinct orders.order_id) as orders,
       count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) as session_to_order_conv_rate
from website_sessions left join orders on website_sessions.website_session_id = orders.website_session_id
where utm_source='gsearch' and utm_campaign='nonbrand' and website_sessions.created_at < '2012-04-14';

/* Pull gsearch nonbrand session volume by week */
select min(date(created_at)) as week_start_date, count(distinct website_session_id) as sessions
from website_sessions
where utm_source='gsearch' and utm_campaign='nonbrand' and website_sessions.created_at < '2012-05-10'
group by year(created_at), week(created_at);

/* calculate conversion rate based on device type for gsearch and nonbrand*/
select device_type, 
count(distinct website_sessions.website_session_id) as sessions, 
count(distinct orders.order_id) as orders, 
count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) as session_to_order_conv_rate
from website_sessions left join orders on website_sessions.website_session_id = orders.website_session_id
where utm_source='gsearch' and utm_campaign='nonbrand' and website_sessions.created_at < '2012-05-11'
group by device_type;

/* calculate sessions based on device type by week between 2012-04-15 and 2012-06-09 */
select min(date(created_at)) as week_start_at,
	   count(distinct case when device_type='desktop'then website_session_id else null end) as desktop_sessions,
	   count(distinct case when device_type='mobile'then website_session_id else null end) as mobile_sessions
from website_sessions
where utm_source='gsearch' 
	  and utm_campaign='nonbrand' 
      and website_sessions.created_at < '2012-06-09'
	  and website_sessions.created_at > '2012-04-15'
group by year(created_at), week(created_at);

/* pull the most-viewed website pages and rank by session volume by 2012-06-09 */
select * from website_pageviews;
select pageview_url, count(distinct website_session_id) as sessions
from website_pageviews
where created_at < '2012-06-09'
group by pageview_url
order by sessions desc;

/* pull all entry pages and rank them by volume */
-- step 1: find the first landing page for each session 
-- step 2: find the url for that pageview
create temporary table first_page_per_session
select website_session_id, min(website_pageview_id) as landing_page
from website_pageviews
where created_at < '2012-06-12'
group by website_session_id;

select * from first_page_per_session;

select website_pageviews.pageview_url, count(distinct first_page_per_session.landing_page) as sessions_hitting_page
from website_pageviews left join first_page_per_session 
on website_pageviews.website_pageview_id = first_page_per_session.landing_page
group by website_pageviews.pageview_url
order by sessions_hitting_page desc;

/* Calculate the bounce rate. Get the request on June 14, 2012 */
-- step 1: find the first website_pageview_id for relevant sessions
create temporary table first_view_page
select website_session_id, min(website_pageview_id) as first_page
from website_pageviews
where created_at < '2012-06-14'
group by website_session_id;

-- step 2: identifying the landing page for each session 
create temporary table first_url
select first_view_page.website_session_id,website_pageviews.pageview_url as landing_page
from first_view_page left join website_pageviews
on first_view_page.first_page = website_pageviews.website_pageview_id;

-- step 3: counting pageviews for each sessions to identify bounces
create temporary table bouncedsession
select first_url.website_session_id, first_url.landing_page,
	   count(website_pageviews.website_pageview_id) as counts_of_page_viewed
from first_url left join website_pageviews 
	 on first_url.website_session_id = website_pageviews.website_session_id
group by first_url.website_session_id, first_url.landing_page
having counts_of_page_viewed = 1;

-- step 4: calculate the bounce rate
select count(distinct first_url.website_session_id) as sessions,
count(distinct bouncedsession.website_session_id) as bounced_sessions,
count(distinct bouncedsession.website_session_id)/count(distinct first_url.website_session_id) as bouncedrate
from first_url left join bouncedsession on first_url.website_session_id = bouncedsession.website_session_id;

/*Build a conversation funnel and analyze how many customers make it to each step from August 5th to September 5th 2012*/
-- step 1: select all pageviews for relevant sessions
-- step 2: identify each pageview as the specific funnel step
-- step 3: create the session-level conversion funnel view 
-- step 4: aggregate the data to access funnel performance
create temporary table conversation_funnel
select website_session_id, 
	max(products_page) as to_product_page,
    max(fuzzy_page) as to_fuzzy_page,
    max(cart_page) as to_cart_page,
    max(shipping_page) as to_shipping_page,
    max(billing_page) as to_billing_page,
    max(thankyou_page) as to_thankyou_page
from(
select  website_sessions.website_session_id, website_pageviews.pageview_url,
	case when pageview_url="/products" then 1 else 0 end as products_page,
    case when pageview_url="/the-original-mr-fuzzy" then 1 else 0 end as fuzzy_page,
    case when pageview_url="/cart" then 1 else 0 end as cart_page,
    case when pageview_url="/shipping" then 1 else 0 end as shipping_page,
    case when pageview_url="/billing" then 1 else 0 end as billing_page,
    case when pageview_url="/thank-you-for-your-order" then 1 else 0 end as thankyou_page
from website_sessions left join website_pageviews
	on website_sessions.website_session_id = website_pageviews.website_session_id
where website_sessions.utm_source="gsearch" and website_sessions.utm_campaign="nonbrand" and website_sessions.created_at > '2012-08-05' and website_sessions.created_at < '2012-09-05'
order by website_sessions.website_session_id, website_sessions.created_at
) as subquerry
group by website_sessions.website_session_id;

select website_session_id, 
	count(distinct case when to_product_page=1 then website_session_id else null end)/count(distinct website_session_id) as lander_click_rate,
    count(distinct case when to_fuzzy_page=1 then website_session_id else null end)/count(distinct case when to_product_page=1 then website_session_id else null end) as product_click_rate,
    count(distinct case when to_cart_page=1 then website_session_id else null end)/count(distinct case when to_fuzzy_page=1 then website_session_id else null end) as fuzzy_click_rate,
    count(distinct case when to_shipping_page=1 then website_session_id else null end)/count(distinct case when to_cart_page=1 then website_session_id else null end) as cart_click_rate,
    count(distinct case when to_billing_page=1 then website_session_id else null end)/count(distinct case when to_shipping_page=1 then website_session_id else null end) as shipping_click_rate,
    count(distinct case when to_thankyou_page=1 then website_session_id else null end)/count(distinct case when to_billing_page=1 then website_session_id else null end) as billing_click_rate
from conversation_funnel;

/* Testing a new billing page /billing-2 compared with /billing. What % sessions on those pages end up placing an order? */
-- step 1: find out when the testing starts?
select min(website_pageview_id)
from website_pageviews
where pageview_url="/billing-2";

-- step 2: join pageview with order and calculate the rate
select pageview_url,
	count(distinct website_session_id) as sessions,
    count(distinct order_id) as orders,
    count(distinct order_id)/count(distinct website_session_id) as order_rate
from (
select website_pageviews.website_session_id, 
	   website_pageviews.pageview_url, 
       orders.order_id
from website_pageviews left join orders
	on website_pageviews.website_session_id = orders.website_session_id
where website_pageviews.website_pageview_id >= 53550 
	and website_pageviews.created_at < "2012-11-10"
	and website_pageviews.pageview_url in('/billing','/billing-2')
) as subquerry
group by pageview_url;

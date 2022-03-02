USE mavenfuzzyfactory;

/* 1. Gsearch seems to be the biggest driver of our business. Could you pull monthly trends for 
   Gsearch sessions and orders so we can showcase the growth there? */
select month(website_sessions.created_at) as 'month', 
	   count(distinct website_sessions.website_session_id) as sessions,
	   count(distinct orders.order_id) as orders,
       count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) as conversion_rate
from website_sessions left join orders
on website_sessions.website_session_id = orders.website_session_id
where utm_source = 'gsearch'and website_sessions.created_at<'2012-11-27'
group by month(website_sessions.created_at);

/* 2. Next, it would be great to splitting out nonbrand and brand companies seperately */
select month(website_sessions.created_at) as 'month',
	   count(distinct case when website_sessions.utm_campaign='brand'then website_sessions.website_session_id else null end) as brand_sessions,
	   count(distinct case when website_sessions.utm_campaign='brand' then orders.order_id else null end) as brand_orders,
	   count(distinct case when website_sessions.utm_campaign='nonbrand'then website_sessions.website_session_id else null end) as nonbrand_sessions,
       count(distinct case when website_sessions.utm_campaign='nonbrand' then orders.order_id else null end) as nonbrand_orders
from website_sessions left join orders
on website_sessions.website_session_id = orders.website_session_id
where utm_source = 'gsearch'and website_sessions.created_at<'2012-11-27'
group by month(website_sessions.created_at);

/* 3. Dive into nonbrand, based on device type, pull monthly sessions and order split by device type */
select month(website_sessions.created_at) as 'month',
	   count(distinct case when website_sessions.device_type = 'desktop'then orders.order_id else null end) as 'desktop_orders',
       count(distinct case when website_sessions.device_type = 'desktop'then website_sessions.website_session_id else null end) as 'desktop_sessions',
       count(distinct case when website_sessions.device_type = 'mobile'then orders.order_id else null end) as 'mobile_orders',
       count(distinct case when website_sessions.device_type = 'mobile'then website_sessions.website_session_id else null end) as 'mobile_sessions'
from website_sessions left join orders
on website_sessions.website_session_id = orders.website_session_id
where utm_source = 'gsearch'and utm_campaign='nonbrand'and website_sessions.created_at<'2012-11-27'
group by month(website_sessions.created_at);   

/* 4. Can you pull monthly trends for Gsearch, alongside monthly trends for each of our other channels? */
-- step 1: find all other channels
select distinct utm_source, utm_campaign, http_referer
from website_sessions
where website_sessions.created_at<'2012-11-27';
-- step 2: pull monthly trends for all channels
select month(website_sessions.created_at) as 'month',
	   count(distinct case when utm_source = 'gsearch' then website_session_id else null end) as gsearch_sessions,
       count(distinct case when utm_source = 'bsearch' then website_session_id else null end) as bsearch_sessions,
       count(distinct case when utm_source is null and http_referer is null then website_session_id else null end) as onlyhttp_sessions,
       count(distinct case when utm_source is null and http_referer is not null then website_session_id else null end) as direct_sessions
from website_sessions
where website_sessions.created_at < '2012-11-27'
group by month(website_sessions.created_at);

/* 5. Could you pull session to order conversion rates, by month for the 8 months? */
select month(website_sessions.created_at) as month,
	   count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) as session_to_order_conv_rate
from website_sessions left join orders
	 on website_sessions.website_session_id = orders.website_session_id
where website_sessions.created_at < '2012-11-27'
group by month(website_sessions.created_at);

/* 6. For the gsearch lander test(url=/lander-1 compared with url=/home), please estimate the revenue that test earned us 
 (Jun 19 – Jul 28), and use nonbrand sessions and revenue since then to calculate incremental value) */
-- step 1: find the first pageview from the test started
select min(website_pageview_id) as first_page_view
from website_pageviews
where pageview_url = '/lander-1';
-- result: fist pageview_id for this test is 23504

-- step 2: find the relevant sessions during the test period for /home and /lander-1
create temporary table first_pageview
select website_pageviews.website_session_id, 
       min(website_pageviews.website_pageview_id) AS first_pageview_id
from website_pageviews left join website_sessions on
	 website_pageviews.website_session_id = website_sessions.website_session_id
where website_pageviews.created_at < '2012-07-28' 
	  and website_pageview_id >= 23504 
      and website_sessions.utm_source='gsearch'
      and website_sessions.utm_campaign='nonbrand'
group by website_pageviews.website_session_id;

create temporary table session_with_landing_page
select first_pageview.website_session_id, website_pageviews.pageview_url
from first_pageview left join website_pageviews
on first_pageview.website_session_id = website_pageviews.website_session_id
where website_pageviews.pageview_url in('/lander-1','/home');

select session_with_landing_page.pageview_url, 
	   count(distinct session_with_landing_page.website_session_id) as sessions, 
	   count(distinct orders.order_id) as orders,
       count(distinct orders.order_id)/ count(distinct session_with_landing_page.website_session_id) as conversion_rate
from session_with_landing_page left join orders 
	 on session_with_landing_page.website_session_id = orders.website_session_id
group by session_with_landing_page.pageview_url;
-- /home conversion_rate is 0.0318; /lander-1 conversion_rate is 0.0406
-- 0.0088 additional order per session 
-- calculate the orders from the test end and then calculate the additional orders we get 
select max(website_sessions.website_session_id) as end_pageview
from website_sessions left join website_pageviews
	on website_sessions.website_session_id = website_pageviews.website_session_id
where website_sessions.utm_campaign='nonbrand' 
	  and website_sessions.utm_source='gsearch' 
      and website_sessions.created_at<'2012-11-27'
      and website_pageviews.pageview_url='/home';
-- result is 17145. After that we redirected customers to another page rather than /home

select count(distinct website_sessions.website_session_id) as sessions
from website_sessions
where website_session_id > 17145 
	  and created_at < '2012-11-27'
      and utm_source='gsearch'
      and utm_campaign='nonbrand';
-- result is 22980 sessions. 0.0088 additional order per session 
-- so we had about additional 202 orders because of the new landing page

/* 7. Based on the previous landing page analysis, show a full conversion funnel from each of 
   the two pages to others during the test period*/
create temporary table full_conversion
select website_session_id, 
	   max(home_page) as to_home_page,
       max(lander_page) as to_lander_page,
	   max(products_page) as to_product_page,
       max(fuzzy_page) as to_fuzzy_page,
       max(cart_page) as to_cart_page,
       max(shipping_page) as to_shipping_page,
       max(billing_page) as to_billing_page,
       max(thankyou_page) as to_thankyou_page
from (
select  website_sessions.website_session_id, website_pageviews.pageview_url,
	case when pageview_url="/home" then 1 else 0 end as home_page,
    case when pageview_url="/lander-1" then 1 else 0 end as lander_page,
	case when pageview_url="/products" then 1 else 0 end as products_page,
    case when pageview_url="/the-original-mr-fuzzy" then 1 else 0 end as fuzzy_page,
    case when pageview_url="/cart" then 1 else 0 end as cart_page,
    case when pageview_url="/shipping" then 1 else 0 end as shipping_page,
    case when pageview_url="/billing" then 1 else 0 end as billing_page,
    case when pageview_url="/thank-you-for-your-order" then 1 else 0 end as thankyou_page
from website_sessions left join website_pageviews
	on website_sessions.website_session_id = website_pageviews.website_session_id
where website_sessions.utm_source="gsearch" 
	  and website_sessions.utm_campaign="nonbrand" 
      and website_sessions.created_at >='2012-06-19' 
      and website_sessions.created_at <= '2012-07-28'
) as subquerry
group by website_session_id;

-- build conversion funnel from home page and lander page
select case when to_home_page = 1 then 'from_home_page'
            when to_lander_page = 1 then 'from_lander_page'
       end as segment,
       count(distinct website_session_id) as sessions,
       count(distinct case when to_product_page = 1 then website_session_id else null end) as made_it_to_product,
       count(distinct case when to_fuzzy_page = 1 then website_session_id else null end) as made_it_to_fuzzy,
       count(distinct case when to_cart_page = 1 then website_session_id else null end) as made_it_to_cart,
       count(distinct case when to_shipping_page = 1 then website_session_id else null end) as made_it_to_shipping,
       count(distinct case when to_billing_page = 1 then website_session_id else null end) as made_it_to_billing,
       count(distinct case when to_thankyou_page = 1 then website_session_id else null end) as made_it_to_thankyou
from full_conversion
group by segment;

-- calculate the conversion rate from home page and from lander page 
select case when to_home_page = 1 then 'from_home_page'
            when to_lander_page = 1 then 'from_lander_page'
       end as segment,
       count(distinct case when to_product_page = 1 then website_session_id else null end)/count(distinct website_session_id) as homeorlander_click_rt,
       count(distinct case when to_fuzzy_page = 1 then website_session_id else null end)/count(distinct case when to_product_page = 1 then website_session_id else null end) as product_click_rt,
       count(distinct case when to_cart_page = 1 then website_session_id else null end)/count(distinct case when to_fuzzy_page = 1 then website_session_id else null end) as fuzzy_click_rt,
       count(distinct case when to_shipping_page = 1 then website_session_id else null end)/count(distinct case when to_cart_page = 1 then website_session_id else null end) as cart_click_rt,
       count(distinct case when to_billing_page = 1 then website_session_id else null end)/count(distinct case when to_shipping_page = 1 then website_session_id else null end) as shipping_click_rt,
       count(distinct case when to_thankyou_page = 1 then website_session_id else null end)/count(distinct case when to_billing_page = 1 then website_session_id else null end) as billing_click_rt
from full_conversion
group by segment;

/* 8. Please analyze the lift generated from the billingtest (Sep 10 – Nov 10), in terms of revenue per billing page session, 
   and then pull the number of billing page sessions for the past month to understand monthly impact.*/
select count(distinct website_session_id)as sessions, pageview_url, sum(price_usd)/count(website_session_id) as revenue_per_session
from(
select website_pageviews.website_session_id, website_pageviews.pageview_url,
	   orders.order_id, orders.price_usd
from website_pageviews left join orders 
     on website_pageviews.website_session_id = orders.website_session_id
where website_pageviews.pageview_url in('/billing','/billing-2') 
	  and website_pageviews.created_at < '2012-11-10' 
      and website_pageviews.created_at > '2012-09-10'
) as subquerry
group by 2;
-- result: 22.79 for /billing, 31.31 for /billing-2
-- lift 8.52 per session 

select count(distinct website_pageviews.website_session_id) as sessions,
       count(distinct website_pageviews.website_session_id) * 8.52 as increased_revenue
from website_pageviews
where created_at >= '2012-10-27' 
      and created_at <= '2012-11-27'
      and website_pageviews.pageview_url in('/billing','/billing-2');


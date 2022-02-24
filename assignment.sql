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

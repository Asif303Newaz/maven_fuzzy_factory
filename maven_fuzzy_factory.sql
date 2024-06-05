select * from mavenfuzzyfactory.orders
limit 10;
-- counts the total number of sessions

select count(website_session_id) from website_sessions; -- 472871

-- count the pageviews under each session

select count(website_pageview_id) from website_pageviews; -- 1188124

-- On average, how many pages does a visitor visit in each session

Select
count(distinct website_session_id) as total_Sessions,
count(website_pageview_id) as total_previews,
count(website_pageview_id)/count(distinct website_session_id) as Avr_Number_of_previews_per_session
from website_pageviews;  -- 2.5125

-- In CVR, calculate the count of orders per session

SELECT
	COUNT(DISTINCT W.WEBSITE_SESSION_ID) AS TOTAL_SESSIONS, -- 472871
    COUNT(DISTINCT O.ORDER_ID) AS TOTAL_ORDERS, -- 32313
    COUNT(DISTINCT O.ORDER_ID)/COUNT(DISTINCT W.WEBSITE_SESSION_ID) AS CVR -- 0.0683
FROM WEBSITE_SESSIONS W
LEFT JOIN ORDERS O
    ON O.WEBSITE_SESSION_ID = W.WEBSITE_SESSION_ID;

select min(created_at), -- 2012-03-19
max(created_at) -- 2015-03-19
from 
website_sessions;

-- Calculate the monthly Conversion Rate (CVR) for the past year.

SELECT
year(W.CREATED_AT) as session_year,
month(W.CREATED_AT) AS session_month,
	-- COUNT(DISTINCT W.WEBSITE_SESSION_ID) AS TOTAL_SESSIONS, -- 472871
    -- COUNT(DISTINCT O.ORDER_ID) AS TOTAL_ORDERS, -- 32313
    COUNT(DISTINCT O.ORDER_ID)/COUNT(DISTINCT W.WEBSITE_SESSION_ID) AS CVR
FROM WEBSITE_SESSIONS W
LEFT JOIN ORDERS O
    ON O.WEBSITE_SESSION_ID = W.WEBSITE_SESSION_ID
WHERE W.CREATED_AT between '2012-04-01' and '2013-03-31'
group by 1, 2
order by 1,2;

-- Calculate the monthly Conversion Rate (CVR) for the past year, broken down by week

SELECT
    MIN(DATE(W.CREATED_AT)) AS week_start_date,
    COUNT(DISTINCT O.ORDER_ID) / COUNT(DISTINCT W.WEBSITE_SESSION_ID) AS CVR
FROM 
    WEBSITE_SESSIONS W
LEFT JOIN 
    ORDERS O ON O.WEBSITE_SESSION_ID = W.WEBSITE_SESSION_ID
WHERE 
    W.CREATED_AT BETWEEN '2012-04-01' AND '2013-03-31'
GROUP BY 
    YEAR(W.CREATED_AT), WEEK(W.CREATED_AT)
ORDER BY 
    week_start_date;
    
-- On which device is the conversion rate (CVR) highest

SELECT
	W.DEVICE_TYPE,
	-- COUNT(DISTINCT W.WEBSITE_SESSION_ID) AS TOTAL_SESSIONS, -- 472871
    -- COUNT(DISTINCT O.ORDER_ID) AS TOTAL_ORDERS, -- 32313
    COUNT(DISTINCT O.ORDER_ID)/COUNT(DISTINCT W.WEBSITE_SESSION_ID) AS CVR -- 0.0305
FROM WEBSITE_SESSIONS W
LEFT JOIN ORDERS O
    ON O.WEBSITE_SESSION_ID = W.WEBSITE_SESSION_ID
WHERE W.CREATED_AT BETWEEN '2012-04-01' AND '2013-03-31'
GROUP BY 1
ORDER BY 1;

-- Provide the CVR report for mobile and PC individually, on a week-by-week basis

SELECT 
    week_start_date,
    MAX(CASE WHEN device_type = 'desktop' THEN CVR ELSE NULL END) AS desktop_CVR,
    MAX(CASE WHEN device_type = 'mobile' THEN CVR ELSE NULL END) AS mobile_CVR
FROM (
    SELECT
        W.device_type,
        MIN(DATE(W.CREATED_AT)) AS week_start_date,
        COUNT(DISTINCT O.ORDER_ID) / COUNT(DISTINCT W.WEBSITE_SESSION_ID) AS CVR
    FROM 
        WEBSITE_SESSIONS W
    LEFT JOIN 
        ORDERS O ON O.WEBSITE_SESSION_ID = W.WEBSITE_SESSION_ID
    WHERE 
        W.CREATED_AT BETWEEN '2012-04-01' AND '2013-03-31'
    GROUP BY 
        W.device_type, YEAR(W.CREATED_AT), WEEK(W.CREATED_AT)
) AS subquery
GROUP BY 
    week_start_date
ORDER BY 
    week_start_date;

-- Site Traffic Breakdown by UTM_SOURCE, UTM_CAMPAIGN, HTTTP_REFERER
-- GSEARCH_PAID_SESSIONS, BSEARCH_PAID_SESSIONS, ORGANIC_SEARCH_SESSIONS, DIRECT_TYPE_IN_SESSION
-- GSEARCH_PAID_ORDERS, BSEARCH_PAID_ORDERS, ORGANIC_SEARCH_ORDERS, DIRECT_TYPE_IN_ORDERS
-- GSEARCH_PAID_CVR, BSEARCH_PAID_CVR, ORGANIC_SEARCH_CVR, DIRECT_TYPE_IN_CVR


SELECT
	UTM_SOURCE,
	UTM_CAMPAIGN,
	HTTP_REFERER,
    COUNT(DISTINCT WEBSITE_SESSION_ID) AS TOTAL_SESSIONS
FROM WEBSITE_SESSIONS
	WHERE WEBSITE_SESSIONS.CREATED_AT < '2013-06-30'
GROUP BY 1, 2, 3;

SELECT
	YEAR(W.CREATED_AT) AS YEAR,
    MONTH(W.CREATED_AT) AS MONTH,
    COUNT(DISTINCT CASE WHEN W.UTM_SOURCE = 'gsearch' THEN W.WEBSITE_SESSION_ID ELSE NULL END) AS GSEARCH_PAID_SESSIONS,
    COUNT(DISTINCT CASE WHEN W.UTM_SOURCE = 'bsearch' THEN W.WEBSITE_SESSION_ID ELSE NULL END) AS BSEARCH_PAID_SESSIONS,
    COUNT(DISTINCT CASE WHEN W.UTM_SOURCE IS NULL AND W.HTTP_REFERER IS NOT NULL THEN W.WEBSITE_SESSION_ID ELSE NULL END) AS ORGANIC_SEARCH_SESSIONS,
    COUNT(DISTINCT CASE WHEN W.UTM_SOURCE IS NULL AND W.HTTP_REFERER IS NULL THEN W.WEBSITE_SESSION_ID ELSE NULL END) AS DIRECT_TYPE_IN_SESSIONS,
	COUNT(DISTINCT CASE WHEN W.UTM_SOURCE = 'gsearch' THEN O.ORDER_ID ELSE NULL END) AS GSEARCH_PAID_ORDERS,
    COUNT(DISTINCT CASE WHEN W.UTM_SOURCE = 'bsearch' THEN O.ORDER_ID ELSE NULL END) AS BSEARCH_PAID_ORDERS,
    COUNT(DISTINCT CASE WHEN W.UTM_SOURCE IS NULL AND W.HTTP_REFERER IS NOT NULL THEN O.ORDER_ID ELSE NULL END) AS ORGANIC_SEARCH_ORDERS,
    COUNT(DISTINCT CASE WHEN W.UTM_SOURCE IS NULL AND W.HTTP_REFERER IS NULL THEN O.ORDER_ID ELSE NULL END) AS DIRECT_TYPE_IN_ORDERS,
    COUNT(DISTINCT CASE WHEN W.UTM_SOURCE = 'gsearch' THEN O.ORDER_ID ELSE NULL END) / COUNT(DISTINCT CASE WHEN W.UTM_SOURCE = 'gsearch' THEN W.WEBSITE_SESSION_ID ELSE NULL END) AS GSEARCH_PAID_CVR,
    COUNT(DISTINCT CASE WHEN W.UTM_SOURCE = 'bsearch' THEN O.ORDER_ID ELSE NULL END) / COUNT(DISTINCT CASE WHEN W.UTM_SOURCE = 'bsearch' THEN W.WEBSITE_SESSION_ID ELSE NULL END) AS BSEARCH_PAID_CVR,
    COUNT(DISTINCT CASE WHEN W.UTM_SOURCE IS NULL AND W.HTTP_REFERER IS NOT NULL THEN O.ORDER_ID ELSE NULL END) / COUNT(DISTINCT CASE WHEN W.UTM_SOURCE IS NULL AND HTTP_REFERER IS NOT NULL THEN W.WEBSITE_SESSION_ID ELSE NULL END) AS ORGANIC_SEARCH_CVR,
    COUNT(DISTINCT CASE WHEN W.UTM_SOURCE IS NULL AND W.HTTP_REFERER IS NULL THEN O.ORDER_ID ELSE NULL END) / COUNT(DISTINCT CASE WHEN W.UTM_SOURCE IS NULL AND HTTP_REFERER IS NULL THEN W.WEBSITE_SESSION_ID ELSE NULL END) AS DIRECT_TYPE_IN_CVR
FROM WEBSITE_SESSIONS W
LEFT JOIN ORDERS O
	ON O.WEBSITE_SESSION_ID = W.WEBSITE_SESSION_ID
WHERE W.CREATED_AT < '2013-06-30'
GROUP BY 1,2
ORDER BY 1,2;


-- 'gsearch' and 'nonbrand' mobile vs desktop performance (session/conversion) comparison.

SELECT
    YEAR(website_sessions.created_at) AS yr,
    MONTH(website_sessions.created_at) AS mo,
    COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN website_sessions.website_session_id ELSE NULL END) AS desktop_sessions,
    COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN orders.order_id ELSE NULL END) AS desktop_orders,
    COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_sessions.website_session_id ELSE NULL END) AS mobile_sessions,
    COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN orders.order_id ELSE NULL END) AS mobile_orders
FROM website_sessions
LEFT JOIN orders
    ON orders.website_session_id = website_sessions.website_session_id
WHERE
    website_sessions.created_at < '2012-11-27'
    AND website_sessions.utm_source = 'gsearch'
    AND website_sessions.utm_campaign = 'nonbrand'
GROUP BY yr, mo;


-- Could you get the most-viewed website pages, ranked by session volume?

select pageview_url, count(distinct website_session_id) as total_pageview
 from website_pageviews
 group by pageview_url
 order by total_pageview desc;
 
 -- Identify the top entry pages and rank them on entry volume using COMMON TABLE EXPRESSION (CTE)
 
 with First_Pageview as
(select website_pageview_id,
min(website_pageview_id) as starting_pageview_id
 from website_pageviews
 group by website_session_id)
 
 select website_pageviews.pageview_url as landing_page,
 count(First_Pageview.website_session_id) as number_of_sessions
 from First_Pageview
 left join website_pageviews
 on website_pageviews.website_pageview_id = First_Pageview.starting_pageview_id
 group by landing_page
 order by number_of_sessions desc;
 ;











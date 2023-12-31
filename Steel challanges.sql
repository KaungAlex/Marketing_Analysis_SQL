-- 1. How many transactions were completed during each marketing campaign?
select 
c.campaign_name,
count(t.transaction_id) as TotalTransaction
from transactions t 
join marketing_campaigns c on c.product_id = t.product_id 
group by c.campaign_name

-- 2. Which product had the highest sales quantity?
select * 
from (
select 
a.product_name,
a.Qty,
ROW_NUMBER() over(order by  a.Qty desc) as ranks
from (

select 
s.product_name ,
sum(t.quantity) as Qty
from 
transactions t 
join sustainable_clothing s on s.product_id = t.product_id
group by s.product_name,t.quantity) a ) b 
where b.ranks = 1


-- 3. What is the total revenue generated from each marketing campaign?

select 
m.campaign_name,
sum(sc.price * t.quantity) as Revenue
from sustainable_clothing sc 
join transactions t on t.product_id = sc.product_id
join marketing_campaigns m on m.product_id = t.product_id
group by m.campaign_name
order by sum(sc.price * t.quantity) desc

-- 4. What is the top-selling product category based on the total revenue generated?
select 
* from (
select 
a.category,
a.Revenue ,
ROW_NUMBER () over(order by a.Revenue desc) as Ranks
from (
select 
sc.category,
sum(sc.price * t.quantity) as Revenue
from sustainable_clothing sc 
join transactions t on t.product_id = sc.product_id
join marketing_campaigns m on m.product_id = t.product_id
group by sc.category) a)b
where b.Ranks =1 



-- 5. Which products had a higher quantity sold compared to the average quantity sold?
select 
b.product_name,
b.qty 
from (
select 
a.product_name,
a.qty,
avg(a.qty) over() as Average
from (
select sc.product_name,
sum(t.quantity)  as qty
from transactions t 
join sustainable_clothing sc on sc.product_id = t.product_id
group by sc.product_name) a ) b 
where b.qty > b.Average 
order by b.qty desc


-- 6. What is the average revenue generated per day during the marketing campaigns?

select 
a.purchase_date,
a.campaign_name,
avg(a.Revenue) over(partition by a.campaign_name) as Average_Revenue
from (
select 
t.purchase_date,
m.campaign_name,
sum(sc.price * t.quantity) as Revenue
from sustainable_clothing sc 
join transactions t on t.product_id = sc.product_id
join marketing_campaigns m on m.product_id = t.product_id
group by t.purchase_date,m.campaign_name) a 


--7. What is the percentage contribution of each product to the total revenue?


select sc.product_name,
(sum(sc.price * t.quantity)/
(select sum(sc.price* t.quantity) from transactions t  join sustainable_clothing sc on t.product_id = sc.product_id) ) *100
 as Pct_Ratio 
from sustainable_clothing sc
join transactions t on t.product_id = sc.product_id
group by product_name
order by Pct_Ratio desc

--- 8. Compare the average quantity sold during marketing campaigns to outside the marketing campaigns

select 
avg(a.TotalQty) as campaign
into #cam
from 
(
select 
sum(t.quantity) as TotalQty
from transactions t
left join marketing_campaigns m on m.product_id = t.product_id
where m. campaign_name is not null
group by m.campaign_name)a 


select 
avg(a.TotalQty) as no_campaign
into #no_cam
from

(
select 
sum(t.quantity) as TotalQty
from transactions t
left join marketing_campaigns m on m.product_id = t.product_id
where m. campaign_name is  null
group by m.campaign_name)a 

select no_campaign,campaign,
Qty_campaing_outside = no_campaign - campaign
from #no_cam, #cam

-- 9. Compare the revenue generated by products inside the marketing campaigns to outside the campaigns

select 
avg(a.Campaigns_Revenue) as Camp_Reve
into #camp_sales
from (
select 
sum(t.quantity * sc.price) as Campaigns_Revenue

from transactions t
left join marketing_campaigns m on m.product_id = t.product_id
left join sustainable_clothing sc on t.product_id = sc.product_id
where m.campaign_name is not null
group by sc.product_name) a 

select 
avg(Outside_Revenue) as Outside_Revenue
into #Outside_Revenue
from (
select 
sum(t.quantity * sc.price) as Outside_Revenue
from transactions t
left join marketing_campaigns m on m.product_id = t.product_id
left join sustainable_clothing sc on t.product_id = sc.product_id
where m.campaign_name is null
group by sc.product_name) a 

select Outside_Revenue,Camp_Reve,
Out_Campaign_performance = Outside_Revenue - Camp_Reve
from #camp_sales,#Outside_Revenue


-- 10. Rank the products by their average daily quantity sold
select top 10 * from marketing_campaigns
select top 10 * from sustainable_clothing 
select top 10 * from transactions


select 
a.product_name,
a.AvgQty,
DENSE_RANK () over(order by a.AvgQty desc) as Ranks
from
(
select 
sc.product_name,
avg(t.quantity) as AvgQty
from transactions t
join sustainable_clothing sc on sc.product_id = t.product_id
group by sc.product_name )a

create database swiggy_pro1

--table 1

create table goldmembers_signup
(
userid int,
gold_signup_date date
)
insert into goldmembers_signup values(1,'09-22-2017'),(3,'04-21-2017')

--table 2

create table users
(
userid int,
signup_date date
)
insert into users values(1,'09-02-2014'),(2,'01-15-2015'),(3,'04-11-2014')

--table 3

create table sales
(
userid int,
created_date date,
product_id int
)
insert into sales values(1,'04-19-2017',2),
(3,'12-18-2019',1),
(2,'07-20-2020',3),
(1,'10-23-2019',2),
(1,'03-19-2018',3),
(3,'12-20-2016',2),
(1,'11-09-2016',1),
(1,'05-20-2016',3),
(2,'09-24-2017',1),
(1,'03-11-2017',2),
(1,'03-11-2016',1),
(3,'11-10-2016',1),
(3,'12-07-2017',2),
(3,'12-15-2016',2),
(2,'11-08-2017',2),
(2,'09-10-2018',3)

--table 4

create table product
(
product_id int,
product_name text,
price float
)
insert into product values(1,'pizza',980),(2,'cake',870),(3,'biryani',330)

select * from goldmembers_signup
select * from users
select * from sales
select * from product


--1. What is the total amount each customer spent on swiggy?
select s.userid,sum(p.price) as total_amount from sales s join product p on s.product_id=p.product_id
group by s.userid


--2. How many days has each customer visited swiggy?
select userid,count(distinct created_date) as visited_date from sales group by userid


--3. What was the first product purchased by each customer?
select * from
(select *, rank() over(partition by userid order by created_date)as rnk from sales) a where rnk=1


--4. What is the most purchased item on the menu and how many times was it purchased by all customer?
/*select top 1 product_id, count(product_id) as most_purchased from sales group by product_id order by count(product_id) desc*/
/*select top 1 product_id from sales group by product_id order by count(product_id) desc*/
select userid,count(product_id) as most_purchased from sales where product_id=
(select top 1 product_id from sales group by product_id order by count(product_id) desc)
group by userid


--5. Which item was the most popular for each customer?
select*from
(select*,rank() over(partition by userid order by cnt desc) rnk from
(select userid,product_id,count(product_id) as cnt from sales group by userid,product_id)a)b
where rnk=1


--6. Which item was purchased first by the customer after they became a member?
select * from
(select *,rank() over(partition by userid order by created_date) as rnk from
(select s.userid,s.created_date,s.product_id,g.gold_signup_date from sales s inner join goldmembers_signup g on s.userid=g.userid
and created_date>=gold_signup_date)a)b where rnk=1

--7. Which item was purchased just before the customer became a member?
select * from
(select *,rank() over(partition by userid order by created_date desc) as rnk from
(select s.userid,s.created_date,s.product_id,g.gold_signup_date from sales s inner join goldmembers_signup g on s.userid=g.userid
and created_date<=gold_signup_date)a)b where rnk=1


--8.What is the total orders and amount spent for each member before they become a member?
select b.userid,count(product_id) as total_orders,sum(price)as total_amount from
(select a.userid,a.product_id,p.price from product p inner join
(select s.userid,s.product_id from sales s inner join goldmembers_signup g on s.userid=g.userid
and created_date<=gold_signup_date)a on p.product_id=a.product_id) b group by userid


/*9. If buying each product generates points for eg 5rs=2 swiggy point and each product has different purchasing points for eg
p1 5rs=1 swiggy point, for p2 10rs=5 swiggy point and p3(biryani) 5rs=1 swiggy point, calculate ponits collected by each customer
and for which product most points have been given till now. */
select d.userid,sum(total_points) as total_points_earned from
(select *,amt/points as total_points from
(select *,case when product_id=1 then 5 when product_id=2 then 2 when product_id=3 then 5 else 0 end as points from
(select a.userid,a.product_id,sum(price) as amt from
(select s.*, p.price from sales s inner join product p on s.product_id=p.product_id)a group by userid,product_id)b)c)d group by userid

--and for which product most points have been given till now.
select * from
(select *,rank() over(order by total_points_earned desc) as rnk from
(select d.product_id,sum(total_points) as total_points_earned from
(select *,amt/points as total_points from
(select *,case when product_id=1 then 5 when product_id=2 then 2 when product_id=3 then 5 else 0 end as points from
(select a.userid,a.product_id,sum(price) as amt from
(select s.*, p.price from sales s inner join product p on s.product_id=p.product_id)a group by userid,product_id)b)c)d group by product_id)e)f
where rnk=1


/*--10. In the 1st one year after a customer joins the gold program (including their join date) irrespective of what the customer has purchased 
they earn 5 swiggy points	for every 10rs spent who earned more 1 or 3 and what was their points earnings in their 1st year?--

[logic 10rs=5pts --> 2rs=1pt -->1rs=0.5pt]*/
select *,rank() over(order by total_points desc) as rnk from
(select b.userid,price*0.5 as total_points from
(select a.*,p.price from
(select s.userid,s.created_date,s.product_id,g.gold_signup_date from sales s inner join goldmembers_signup g on s.userid=g.userid
and created_date>=gold_signup_date and created_date<=DATEADD(YEAR,1,gold_signup_date))a inner join product p on a.product_id=p.product_id)b)c


--11. Rank all the transaction of the customer
select *,rank() over(partition by userid order by created_date) as rnk from sales


/*--12. Rank all the transactions for each member whenever they are a swiggy gold member for every non gold member transaction mark as NA--

[cast function used for typecasting purpose]*/
select b.*,case when rnk=0 then 'NA' else rnk end as RNK from
(select a.*,cast((case when gold_signup_date is null then 0 else rank() over(partition by userid order by created_date desc) end) as varchar) as rnk from
(select s.userid,s.created_date,g.gold_signup_date from sales s left join goldmembers_signup g on s.userid=g.userid 
and created_date>=gold_signup_date)a)b


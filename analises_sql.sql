-- ============================================================
-- PORTFÓLIO 1: GLOBAL SUPERSTORE ANALYTICS
-- Dataset: 3000 pedidos, 50 países, 3 categorias (2021-2024)
-- ============================================================

-- 1. VISÃO GERAL EXECUTIVA
SELECT 
    COUNT(DISTINCT [Order ID]) as total_orders,
    COUNT(DISTINCT Country) as countries,
    COUNT(DISTINCT [Product Name]) as products,
    ROUND(SUM(Sales), 2) as total_revenue,
    ROUND(SUM(Profit), 2) as total_profit,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 2) as profit_margin_pct
FROM sales;

-- 2. RECEITA E LUCRO POR ANO (TIME SERIES)
SELECT 
    strftime('%Y', [Order Date]) as year,
    ROUND(SUM(Sales), 2) as revenue,
    ROUND(SUM(Profit), 2) as profit,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 2) as margin_pct,
    COUNT(*) as order_count,
    ROUND(AVG(Sales), 2) as avg_order_value
FROM sales
GROUP BY strftime('%Y', [Order Date])
ORDER BY year;

-- 3. TOP 10 PAÍSES POR RECEITA
SELECT 
    Country,
    Region,
    ROUND(SUM(Sales), 2) as total_revenue,
    ROUND(SUM(Profit), 2) as total_profit,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 2) as margin_pct,
    COUNT(DISTINCT [Order ID]) as orders
FROM sales
GROUP BY Country, Region
ORDER BY total_revenue DESC
LIMIT 10;

-- 4. ANÁLISE POR CATEGORIA E SUB-CATEGORIA (DRILL-DOWN)
SELECT 
    Category,
    [Sub-Category],
    ROUND(SUM(Sales), 2) as revenue,
    ROUND(SUM(Profit), 2) as profit,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 2) as margin_pct,
    COUNT(*) as items_sold,
    ROUND(AVG(Discount), 2) as avg_discount
FROM sales
GROUP BY Category, [Sub-Category]
ORDER BY Category, revenue DESC;

-- 5. ANÁLISE DE SEGMENTO DE CLIENTE
SELECT 
    Segment,
    ROUND(SUM(Sales), 2) as revenue,
    ROUND(SUM(Profit), 2) as profit,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 2) as margin_pct,
    COUNT(DISTINCT [Order ID]) as orders,
    ROUND(AVG(Sales), 2) as avg_order_value
FROM sales
GROUP BY Segment
ORDER BY revenue DESC;

-- 6. ANÁLISE DE DESCONTO vs LUCRATIVIDADE (CORRELATION)
SELECT 
    Discount,
    COUNT(*) as order_count,
    ROUND(AVG(Sales), 2) as avg_sales,
    ROUND(AVG(Profit), 2) as avg_profit,
    ROUND(AVG(Profit) / AVG(Sales) * 100, 2) as avg_margin_pct
FROM sales
GROUP BY Discount
ORDER BY Discount;

-- 7. MÉDIA MÓVEL DE RECEITA (12 MESES) — WINDOW FUNCTION
WITH monthly AS (
    SELECT 
        strftime('%Y-%m', [Order Date]) as month,
        ROUND(SUM(Sales), 2) as revenue
    FROM sales
    GROUP BY strftime('%Y-%m', [Order Date])
),
ranked AS (
    SELECT 
        month,
        revenue,
        ROW_NUMBER() OVER (ORDER BY month) as rn
    FROM monthly
)
SELECT 
    r1.month,
    r1.revenue,
    ROUND(AVG(r2.revenue), 2) as moving_avg_12m
FROM ranked r1
JOIN ranked r2 ON r2.rn BETWEEN r1.rn - 11 AND r1.rn
GROUP BY r1.month, r1.revenue
ORDER BY r1.month;

-- 8. RANKING DE PRODUTOS POR RECEITA (DENSE_RANK)
SELECT 
    [Product Name],
    [Sub-Category],
    ROUND(SUM(Sales), 2) as revenue,
    ROUND(SUM(Profit), 2) as profit,
    DENSE_RANK() OVER (ORDER BY SUM(Sales) DESC) as revenue_rank,
    DENSE_RANK() OVER (ORDER BY SUM(Profit) DESC) as profit_rank
FROM sales
GROUP BY [Product Name], [Sub-Category]
ORDER BY revenue DESC
LIMIT 20;

-- 9. ANÁLISE DE SHIPPING TIME (LAG/LEAD)
SELECT 
    Ship Mode,
    ROUND(AVG(
        CAST(strftime('%s', Ship_Date) - strftime('%s', Order_Date) AS REAL) / 86400
    ), 1) as avg_ship_days,
    MIN(CAST(strftime('%s', Ship_Date) - strftime('%s', Order_Date) AS REAL) / 86400) as min_ship_days,
    MAX(CAST(strftime('%s', Ship_Date) - strftime('%s', Order_Date) AS REAL) / 86400) as max_ship_days,
    COUNT(*) as order_count
FROM sales
GROUP BY [Ship Mode]
ORDER BY avg_ship_days;

-- 10. PARETO ANALYSIS — 20% DOS PRODUTOS = 80% DA RECEITA
WITH product_revenue AS (
    SELECT 
        [Product Name],
        ROUND(SUM(Sales), 2) as revenue
    FROM sales
    GROUP BY [Product Name]
),
ranked AS (
    SELECT 
        [Product Name],
        revenue,
        SUM(revenue) OVER (ORDER BY revenue DESC) as running_total,
        (SELECT ROUND(SUM(Sales), 2) FROM sales) as grand_total
    FROM product_revenue
)
SELECT 
    [Product Name],
    revenue,
    ROUND(running_total / grand_total * 100, 2) as cumulative_pct
FROM ranked
ORDER BY revenue DESC
LIMIT 20;

-- 11. CTE RECURSIVA — HIERARQUIA REGIÃO > PAÍS > CATEGORIA
WITH RECURSIVE hierarchy AS (
    SELECT 'Global' as level0, '' as level1, '' as level2, '' as level3
    UNION ALL
    SELECT 'Global', Region, '', '' FROM sales GROUP BY Region
    UNION ALL
    SELECT 'Global', Region, Country, '' FROM sales GROUP BY Region, Country
    UNION ALL
    SELECT 'Global', Region, Country, Category FROM sales GROUP BY Region, Country, Category
)
SELECT DISTINCT * FROM hierarchy ORDER BY level0, level1, level2, level3;

-- 12. COHORT ANALYSIS — CLIENTES POR MÊS DE PRIMEIRA COMPRA
WITH first_orders AS (
    SELECT 
        [Order ID],
        strftime('%Y-%m', MIN([Order Date])) as cohort_month
    FROM sales
    GROUP BY [Order ID]
),
monthly_orders AS (
    SELECT 
        strftime('%Y-%m', [Order Date]) as order_month,
        [Order ID]
    FROM sales
)
SELECT 
    f.cohort_month,
    COUNT(DISTINCT f.[Order ID]) as cohort_size,
    COUNT(DISTINCT m.[Order ID]) as active_orders,
    ROUND(COUNT(DISTINCT m.[Order ID]) * 100.0 / COUNT(DISTINCT f.[Order ID]), 1) as retention_pct
FROM first_orders f
LEFT JOIN monthly_orders m ON f.[Order ID] = m.[Order ID]
GROUP BY f.cohort_month
ORDER BY f.cohort_month;

-- 13. YEAR-OVER-YEAR GROWTH (LAG)
WITH yearly AS (
    SELECT 
        strftime('%Y', [Order Date]) as year,
        ROUND(SUM(Sales), 2) as revenue
    FROM sales
    GROUP BY strftime('%Y', [Order Date])
)
SELECT 
    year,
    revenue,
    LAG(revenue) OVER (ORDER BY year) as prev_year_revenue,
    ROUND((revenue - LAG(revenue) OVER (ORDER BY year)) / LAG(revenue) OVER (ORDER BY year) * 100, 2) as yoy_growth_pct
FROM yearly
ORDER BY year;

-- 14. IDENTIFICAR PRODUTOS PREJUIZO (NEGATIVE PROFIT)
SELECT 
    [Product Name],
    [Sub-Category],
    Category,
    ROUND(SUM(Sales), 2) as revenue,
    ROUND(SUM(Profit), 2) as profit,
    ROUND(AVG(Discount), 3) as avg_discount,
    COUNT(*) as times_sold
FROM sales
WHERE Profit < 0
GROUP BY [Product Name], [Sub-Category], Category
ORDER BY profit ASC
LIMIT 15;

-- 15. QUARTERLY ROLLUP COM CASE (SEM ROLLUP natives)
SELECT 
    strftime('%Y', [Order Date]) as year,
    CASE 
        WHEN CAST(strftime('%m', [Order Date]) AS INT) <= 3 THEN 'Q1'
        WHEN CAST(strftime('%m', [Order Date]) AS INT) <= 6 THEN 'Q2'
        WHEN CAST(strftime('%m', [Order Date]) AS INT) <= 9 THEN 'Q3'
        ELSE 'Q4'
    END as quarter,
    ROUND(SUM(Sales), 2) as revenue,
    ROUND(SUM(Profit), 2) as profit,
    COUNT(DISTINCT [Order ID]) as orders
FROM sales
GROUP BY year, quarter
ORDER BY year, quarter;

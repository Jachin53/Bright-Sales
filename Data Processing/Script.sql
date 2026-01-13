SELECT 
    main.*,
    -- Overall average unit price across dataset
    ROUND(avg_metrics.total_sales / avg_metrics.total_quantity, 2) AS AVG_UNIT_PRICE
FROM (
    SELECT 
        -- Cleaned and formatted date
        TO_DATE(DATE, 'DD/MM/YYYY') AS Date,

        -- Cleaned Sales and Cost of Sales
        ROUND(CASE WHEN SALES IS NULL THEN 0 ELSE SALES END, 2) AS Sales,
        ROUND(CASE WHEN COST_OF_SALES IS NULL THEN 0 ELSE COST_OF_SALES END, 2) AS Cost_Of_Sales,
        QUANTITY_SOLD,

        -- Temporal components
        COALESCE(DAYNAME(TO_DATE(DATE, 'DD/MM/YYYY')), 'None') AS day_of_week,
        COALESCE(MONTHNAME(TO_DATE(DATE, 'DD/MM/YYYY')), 'None') AS month_name,
        COALESCE(YEAR(TO_DATE(DATE, 'DD/MM/YYYY')), 0) AS year,
        COALESCE(QUARTER(TO_DATE(DATE, 'DD/MM/YYYY')), 0) AS quarter,

        -- Weekday vs Weekend classification
        CASE 
            WHEN DAYOFWEEK(TO_DATE(DATE, 'DD/MM/YYYY')) BETWEEN 2 AND 6 THEN 'Week-day'
            WHEN DAYOFWEEK(TO_DATE(DATE, 'DD/MM/YYYY')) IN (1, 7) THEN 'Weekend'
            ELSE 'Unknown'
        END AS Day_classification,

        -- Seasonal classification
        CASE 
            WHEN MONTH(TO_DATE(DATE, 'DD/MM/YYYY')) IN (12, 1, 2) THEN 'SUMMER'
            WHEN MONTH(TO_DATE(DATE, 'DD/MM/YYYY')) IN (3, 4, 5) THEN 'AUTUMN'
            WHEN MONTH(TO_DATE(DATE, 'DD/MM/YYYY')) IN (6, 7, 8) THEN 'WINTER'
            WHEN MONTH(TO_DATE(DATE, 'DD/MM/YYYY')) IN (9, 10, 11) THEN 'SPRING'
            ELSE 'Unknown'
        END AS Season_classification,

        -- Profit status
        CASE 
            WHEN SALES > COST_OF_SALES THEN 'Profit'
            ELSE 'Loss'
        END AS Profit_Classification,

        -- Margin Bucketing
        CASE 
            WHEN SALES - COST_OF_SALES >= 5000 THEN 'High Margin'
            WHEN SALES - COST_OF_SALES BETWEEN 0 AND 4999 THEN 'Low Margin'
            ELSE 'Negative Margin'
        END AS Margin_Bucket,

        -- Volume segmentation
        CASE 
            WHEN QUANTITY_SOLD >= 9000 THEN 'High Volume'
            WHEN QUANTITY_SOLD BETWEEN 6000 AND 8999 THEN 'Medium Volume'
            ELSE 'Low Volume'
        END AS Volume_Segment,

        -- Cost efficiency flag
        CASE 
            WHEN COST_OF_SALES / SALES > 1 THEN 'Overcosted'
            ELSE 'Efficient'
        END AS Cost_Efficiency_Flag,

        -- Cost efficiency percentage
        ROUND(
            CASE 
                WHEN SALES = 0 THEN NULL
                ELSE (COST_OF_SALES / SALES) * 100
            END, 2
        ) AS Cost_Efficiency_Pct,

        -- Daily Sales Price per Unit
        ROUND(
            CASE 
                WHEN QUANTITY_SOLD IS NULL OR QUANTITY_SOLD = 0 THEN NULL
                ELSE SALES / QUANTITY_SOLD
            END, 2
        ) AS Daily_Unit_Price,

        -- Daily % Gross Profit
        ROUND(
            CASE 
                WHEN SALES = 0 THEN NULL
                ELSE (SALES - COST_OF_SALES) / SALES * 100
            END, 2
        ) AS Daily_Gross_Profit_Pct,

        -- Daily Gross Profit per Unit
        ROUND(
            CASE 
                WHEN QUANTITY_SOLD = 0 THEN NULL
                ELSE (SALES - COST_OF_SALES) / QUANTITY_SOLD
            END, 2
        ) AS Daily_Gross_Profit_Per_Unit

    FROM SALES.BRIGHT.CASE
) main
CROSS JOIN (
    SELECT 
        SUM(SALES) AS total_sales,
        SUM(QUANTITY_SOLD) AS total_quantity
    FROM SALES.BRIGHT.CASE
) avg_metrics;

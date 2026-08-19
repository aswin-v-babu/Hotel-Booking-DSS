# Hotel Booking Decision Support System

A Decision Support System (DSS) built on the Hotel Booking Demand dataset, demonstrating a full data warehousing and business intelligence lifecycle: data warehouse design, ETL, reporting, visualisation, and a relational vs. graph database comparison.

Built as part of the **Data Storage Solutions for Data Analytics (B9DA111)** module, MSc Data Analytics, Dublin Business School.

## Overview

The project uses Microsoft SQL Server for data warehousing, SQL-based ETL, SQL Server Reporting Services (SSRS) for reporting, Tableau for visualisation, and Neo4j for a graph database comparison. The goal is to show how structured and unstructured data models can support analytical decision-making using ~119,000 hotel booking records (city and resort hotels) sourced from Kaggle.

## Data Warehouse Design

A star schema was implemented with a central fact table and seven dimension tables:

- **FactBooking** — revenue (ADR), stay nights, guests, lead time, cancellation status
- **DimDate, DimHotel, DimGuest, DimMarketSegment, DimRoom, DimStay, DimBookingStatus**

## Repository Structure

```
sql/
  01_data_warehouse_schema.sql   # Star schema: fact and dimension table DDL
  02_etl_load.sql                # ETL: extraction, transformation, dimension/fact loading, validation
tableau/
  hotel_booking_dashboard.twbx   # Interactive Tableau dashboard (revenue trends, cancellations, filtering)
reports/
  tabular_revenue_by_month.pdf   # SSRS tabular report
  matrix_cancellations.pdf       # SSRS matrix report (cancellations by market segment & hotel type)
  drill_down_revenue.pdf         # SSRS drill-down report
  drill_up_revenue.pdf           # SSRS drill-up report
docs/
  DSS_Report.pdf                 # Full project report, including SQL vs. Cypher (Neo4j) comparison
```

## ETL Process

- **Extract:** Operational CSV data staged into `dbo.hotel_bookings`, with row-count and sample checks.
- **Transform:** Date standardisation via `DATEFROMPARTS`, derived metrics (total nights, total guests), null handling with `ISNULL`, and data type conversions using `CAST`/`TRY_CAST`.
- **Load:** Dimensions loaded first via `INSERT INTO ... SELECT DISTINCT`, followed by the fact table using a CTE to join staging rows against each dimension for correct surrogate keys. A reset-and-reseed strategy supports repeatable runs during development.
- **Validate:** Row-count checks across all tables confirm ~119,390 fact rows, matching the source dataset scale.

## Reporting (SSRS)

Four report types were built: a tabular monthly revenue report, a matrix report of cancellations by market segment and hotel type, a parameterised report filterable by year, and a drill-down/drill-up report for exploring revenue from yearly summaries down to monthly detail.

## Visualisation (Tableau)

An interactive dashboard covering monthly revenue trends, revenue comparison by hotel type, cancellation analysis by market segment, and year-based filtering.

## SQL vs. Cypher (Neo4j) Comparison

Seven equivalent analytical queries were run against both the SQL Server star schema and a Neo4j graph model to compare query verbosity, relationship handling, and readability.

| Aspect | SQL (Relational) | Neo4j (Graph) |
|---|---|---|
| Query verbosity | High | Low |
| Relationship handling | Join-based | Native |
| Schema rigidity | Strong | Flexible |
| Analytical aggregations | Efficient | Intuitive |
| Readability | Moderate | High |
| Scalability for relationships | Limited | Excellent |

**Key finding:** SQL performs best for structured, repeatable reporting and star-schema-based BI pipelines, while Neo4j is stronger for relationship-heavy analysis (e.g. customer–hotel–market segment connections), with shorter, more expressive queries. The two models are complementary rather than competing.

## Tools Used

Microsoft SQL Server · SQL Server Reporting Services (SSRS) · Tableau · Neo4j (Cypher) · T-SQL

## Author

**Aswin Vaduvana Babu**
Group project with Adwaitha Shyam and Anantha Krishnan Kunnappilly
MSc Data Analytics, Dublin Business School

## References

Full reference list available in [`docs/DSS_Report.pdf`](docs/DSS_Report.pdf).

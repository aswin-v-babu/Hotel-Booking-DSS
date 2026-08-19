
-----Extract----

USE HotelDW;
SELECT COUNT(*) AS StagingRows FROM dbo.hotel_bookings;


SELECT TOP 20
    hotel,
    arrival_date_year,
    arrival_date_month,
    arrival_date_day_of_month,
    DATEFROMPARTS(
        arrival_date_year,
        CASE LTRIM(RTRIM(arrival_date_month))
            WHEN 'January' THEN 1 WHEN 'February' THEN 2
            WHEN 'March' THEN 3 WHEN 'April' THEN 4
            WHEN 'May' THEN 5 WHEN 'June' THEN 6
            WHEN 'July' THEN 7 WHEN 'August' THEN 8
            WHEN 'September' THEN 9 WHEN 'October' THEN 10
            WHEN 'November' THEN 11 WHEN 'December' THEN 12
        END,
        arrival_date_day_of_month
    ) AS full_date_calc,
    (ISNULL(stays_in_week_nights,0) + ISNULL(stays_in_weekend_nights,0)) AS total_stay_nights_calc,
    (ISNULL(adults,0) + ISNULL(children,0) + ISNULL(babies,0)) AS total_guests_calc,
    adr
FROM dbo.hotel_bookings;


USE HotelDW;
GO

-- 1) Delete from Fact first
DELETE FROM dbo.FactBooking;

-- 2) Then delete from Dimensions
DELETE FROM dbo.DimBookingStatus;
DELETE FROM dbo.DimStay;
DELETE FROM dbo.DimRoom;
DELETE FROM dbo.DimMarketSegment;
DELETE FROM dbo.DimGuest;
DELETE FROM dbo.DimHotel;
DELETE FROM dbo.DimDate;
GO




DBCC CHECKIDENT ('dbo.FactBooking', RESEED, 0);
DBCC CHECKIDENT ('dbo.DimBookingStatus', RESEED, 0);
DBCC CHECKIDENT ('dbo.DimStay', RESEED, 0);
DBCC CHECKIDENT ('dbo.DimRoom', RESEED, 0);
DBCC CHECKIDENT ('dbo.DimMarketSegment', RESEED, 0);
DBCC CHECKIDENT ('dbo.DimGuest', RESEED, 0);
DBCC CHECKIDENT ('dbo.DimHotel', RESEED, 0);
DBCC CHECKIDENT ('dbo.DimDate', RESEED, 0);



INSERT INTO dbo.DimHotel (hotel_type)
SELECT DISTINCT hotel
FROM dbo.hotel_bookings;

----Reloading Dimensions---------

INSERT INTO dbo.DimMarketSegment (market_segment, distribution_channel, deposit_type)
SELECT DISTINCT market_segment, distribution_channel, deposit_type
FROM dbo.hotel_bookings;


INSERT INTO dbo.DimRoom (reserved_room_type, assigned_room_type, booking_changes)
SELECT DISTINCT reserved_room_type, assigned_room_type, booking_changes
FROM dbo.hotel_bookings;

INSERT INTO dbo.DimStay (
    week_nights, weekend_nights, total_nights,
    required_car_parking_spaces, total_special_requests
)
SELECT DISTINCT
    stays_in_week_nights,
    stays_in_weekend_nights,
    stays_in_week_nights + stays_in_weekend_nights,
    required_car_parking_spaces,
    total_of_special_requests
FROM dbo.hotel_bookings;

INSERT INTO dbo.DimBookingStatus (reservation_status, cancellation_flag)
SELECT DISTINCT reservation_status, is_canceled
FROM dbo.hotel_bookings;

INSERT INTO dbo.DimGuest (
    country, customer_type, is_repeated_guest,
    previous_cancellations, previous_not_canceled,
    adults, children, babies
)
SELECT DISTINCT
    ISNULL(country,'') AS country,
    customer_type,
    CAST(is_repeated_guest AS INT),
    CAST(previous_cancellations AS INT),
    CAST(previous_bookings_not_canceled AS INT),
    CAST(adults AS INT),
    ISNULL(CAST(children AS INT), 0),
    ISNULL(CAST(babies AS INT), 0)
FROM dbo.hotel_bookings;

INSERT INTO dbo.DimDate (
    full_date, year, month_name, month_number,
    week_number, day_number, reservation_status_date
)
SELECT DISTINCT
    DATEFROMPARTS(
        arrival_date_year,
        CASE LTRIM(RTRIM(arrival_date_month))
            WHEN 'January' THEN 1 WHEN 'February' THEN 2
            WHEN 'March' THEN 3 WHEN 'April' THEN 4
            WHEN 'May' THEN 5 WHEN 'June' THEN 6
            WHEN 'July' THEN 7 WHEN 'August' THEN 8
            WHEN 'September' THEN 9 WHEN 'October' THEN 10
            WHEN 'November' THEN 11 WHEN 'December' THEN 12
        END,
        arrival_date_day_of_month
    ),
    arrival_date_year,
    arrival_date_month,
    CASE LTRIM(RTRIM(arrival_date_month))
        WHEN 'January' THEN 1 WHEN 'February' THEN 2
        WHEN 'March' THEN 3 WHEN 'April' THEN 4
        WHEN 'May' THEN 5 WHEN 'June' THEN 6
        WHEN 'July' THEN 7 WHEN 'August' THEN 8
        WHEN 'September' THEN 9 WHEN 'October' THEN 10
        WHEN 'November' THEN 11 WHEN 'December' THEN 12
    END,
    arrival_date_week_number,
    arrival_date_day_of_month,
    reservation_status_date
FROM dbo.hotel_bookings;



---Reloading Fact---


;WITH hb AS (
    SELECT
        hb.*,
        DATEFROMPARTS(
            hb.arrival_date_year,
            CASE LTRIM(RTRIM(hb.arrival_date_month))
                WHEN 'January' THEN 1 WHEN 'February' THEN 2
                WHEN 'March' THEN 3 WHEN 'April' THEN 4
                WHEN 'May' THEN 5 WHEN 'June' THEN 6
                WHEN 'July' THEN 7 WHEN 'August' THEN 8
                WHEN 'September' THEN 9 WHEN 'October' THEN 10
                WHEN 'November' THEN 11 WHEN 'December' THEN 12
            END,
            hb.arrival_date_day_of_month
        ) AS full_date_calc,
        (ISNULL(hb.stays_in_week_nights,0) + ISNULL(hb.stays_in_weekend_nights,0)) AS total_nights_calc,
        (ISNULL(hb.adults,0) + ISNULL(hb.children,0) + ISNULL(hb.babies,0)) AS total_guests_calc
    FROM dbo.hotel_bookings hb
)
INSERT INTO dbo.FactBooking (
    Date_ID, Hotel_ID, Guest_ID, MarketSegment_ID, Room_ID, Stay_ID, BookingStatus_ID,
    is_canceled, lead_time, adr, total_stay_nights, total_guests
)
SELECT
    d.Date_ID,
    h.Hotel_ID,
    g.Guest_ID,
    m.MarketSegment_ID,
    r.Room_ID,
    s.Stay_ID,
    bs.BookingStatus_ID,
    hb.is_canceled,
    hb.lead_time,
    hb.adr,
    hb.total_nights_calc,
    hb.total_guests_calc
FROM hb
JOIN dbo.DimHotel h
  ON h.hotel_type = hb.hotel
JOIN dbo.DimMarketSegment m
  ON m.market_segment = hb.market_segment
 AND m.distribution_channel = hb.distribution_channel
 AND m.deposit_type = hb.deposit_type
JOIN dbo.DimRoom r
  ON r.reserved_room_type = hb.reserved_room_type
 AND r.assigned_room_type = hb.assigned_room_type
 AND r.booking_changes = hb.booking_changes
JOIN dbo.DimStay s
  ON s.week_nights = hb.stays_in_week_nights
 AND s.weekend_nights = hb.stays_in_weekend_nights
 AND s.total_nights = hb.total_nights_calc
 AND s.required_car_parking_spaces = hb.required_car_parking_spaces
 AND s.total_special_requests = hb.total_of_special_requests
JOIN dbo.DimBookingStatus bs
  ON bs.reservation_status = hb.reservation_status
 AND bs.cancellation_flag = hb.is_canceled
JOIN dbo.DimGuest g
  ON ISNULL(g.country,'') = ISNULL(hb.country,'')
 AND g.customer_type = hb.customer_type
 AND g.is_repeated_guest = hb.is_repeated_guest
 AND g.previous_cancellations = hb.previous_cancellations
 AND g.previous_not_canceled = hb.previous_bookings_not_canceled
 AND g.adults = hb.adults
 AND g.children = ISNULL(hb.children,0)
 AND g.babies  = ISNULL(hb.babies,0)
JOIN dbo.DimDate d
  ON d.full_date = hb.full_date_calc
 AND d.reservation_status_date = hb.reservation_status_date;



 ----Validate ETL----

 SELECT 'FactBooking' AS TableName, COUNT(*) AS Rows FROM dbo.FactBooking
UNION ALL SELECT 'DimDate', COUNT(*) FROM dbo.DimDate
UNION ALL SELECT 'DimHotel', COUNT(*) FROM dbo.DimHotel
UNION ALL SELECT 'DimGuest', COUNT(*) FROM dbo.DimGuest
UNION ALL SELECT 'DimMarketSegment', COUNT(*) FROM dbo.DimMarketSegment
UNION ALL SELECT 'DimRoom', COUNT(*) FROM dbo.DimRoom
UNION ALL SELECT 'DimStay', COUNT(*) FROM dbo.DimStay
UNION ALL SELECT 'DimBookingStatus', COUNT(*) FROM dbo.DimBookingStatus;

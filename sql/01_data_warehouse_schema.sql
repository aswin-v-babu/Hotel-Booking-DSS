


USE HotelDW;
GO


CREATE TABLE DimDate (
    Date_ID INT IDENTITY(1,1) PRIMARY KEY,
    full_date DATE,
    year INT,
    month_name VARCHAR(20),
    month_number INT,
    week_number INT,
    day_number INT,
    reservation_status_date DATE
);

CREATE TABLE DimHotel (
    Hotel_ID INT IDENTITY(1,1) PRIMARY KEY,
    hotel_type VARCHAR(50)
);


CREATE TABLE DimGuest (
    Guest_ID INT IDENTITY(1,1) PRIMARY KEY,
    country VARCHAR(5),
    customer_type VARCHAR(50),
    is_repeated_guest INT,
    previous_cancellations INT,
    previous_not_canceled INT,
    adults INT,
    children INT,
    babies INT
);

CREATE TABLE DimMarketSegment (
    MarketSegment_ID INT IDENTITY(1,1) PRIMARY KEY,
    market_segment VARCHAR(50),
    distribution_channel VARCHAR(50),
    deposit_type VARCHAR(50)
);

CREATE TABLE DimRoom (
    Room_ID INT IDENTITY(1,1) PRIMARY KEY,
    reserved_room_type VARCHAR(10),
    assigned_room_type VARCHAR(10),
    booking_changes INT
);

CREATE TABLE DimStay (
    Stay_ID INT IDENTITY(1,1) PRIMARY KEY,
    week_nights INT,
    weekend_nights INT,
    total_nights INT,
    required_car_parking_spaces INT,
    total_special_requests INT
);


CREATE TABLE DimBookingStatus (
    BookingStatus_ID INT IDENTITY(1,1) PRIMARY KEY,
    reservation_status VARCHAR(50),
    cancellation_flag INT
);


CREATE TABLE FactBooking (
    Booking_ID INT IDENTITY(1,1) PRIMARY KEY,
    Date_ID INT FOREIGN KEY REFERENCES DimDate(Date_ID),
    Hotel_ID INT FOREIGN KEY REFERENCES DimHotel(Hotel_ID),
    Guest_ID INT FOREIGN KEY REFERENCES DimGuest(Guest_ID),
    MarketSegment_ID INT FOREIGN KEY REFERENCES DimMarketSegment(MarketSegment_ID),
    Room_ID INT FOREIGN KEY REFERENCES DimRoom(Room_ID),
    Stay_ID INT FOREIGN KEY REFERENCES DimStay(Stay_ID),
    BookingStatus_ID INT FOREIGN KEY REFERENCES DimBookingStatus(BookingStatus_ID),

    is_canceled INT,
    lead_time INT,
    adr FLOAT,
    total_stay_nights INT,
    total_guests INT
);

-- Fix string 'NULL' values
UPDATE dbo.hotel_bookings
SET agent = NULL
WHERE agent = 'NULL';

UPDATE dbo.hotel_bookings
SET company = NULL
WHERE company = 'NULL';

-- Handle missing children values
UPDATE dbo.hotel_bookings
SET children = 0
WHERE children IS NULL;


SELECT name FROM sys.tables;

INSERT INTO DimHotel (hotel_type)
SELECT DISTINCT hotel
FROM dbo.hotel_bookings;

SELECT * FROM DimHotel;

INSERT INTO DimMarketSegment (market_segment, distribution_channel, deposit_type)
SELECT DISTINCT market_segment, distribution_channel, deposit_type
FROM dbo.hotel_bookings;

SELECT * FROM DimMarketSegment;

INSERT INTO DimGuest (
    country,
    customer_type,
    is_repeated_guest,
    previous_cancellations,
    previous_not_canceled,
    adults,
    children,
    babies
)
SELECT DISTINCT
    country,
    customer_type,
    CAST(is_repeated_guest AS INT),
    CAST(previous_cancellations AS INT),
    CAST(previous_bookings_not_canceled AS INT),
    CAST(adults AS INT),
    ISNULL(CAST(children AS INT), 0),
    ISNULL(CAST(babies AS INT), 0)
FROM dbo.hotel_bookings;

SELECT TOP 20 * FROM DimGuest;


SELECT COUNT(*) FROM DimHotel;
SELECT COUNT(*) FROM DimMarketSegment;
SELECT COUNT(*) FROM DimRoom;
SELECT COUNT(*) FROM DimStay;
SELECT COUNT(*) FROM DimBookingStatus;
SELECT COUNT(*) FROM DimDate;


INSERT INTO DimRoom (reserved_room_type, assigned_room_type, booking_changes)
SELECT DISTINCT
    reserved_room_type,
    assigned_room_type,
    booking_changes
FROM dbo.hotel_bookings;

SELECT COUNT(*) AS RoomCount FROM DimRoom;


INSERT INTO DimStay (
    week_nights,
    weekend_nights,
    total_nights,
    required_car_parking_spaces,
    total_special_requests
)
SELECT DISTINCT
    stays_in_week_nights,
    stays_in_weekend_nights,
    stays_in_week_nights + stays_in_weekend_nights,
    required_car_parking_spaces,
    total_of_special_requests
FROM dbo.hotel_bookings;

SELECT COUNT(*) AS StayCount FROM DimStay;


INSERT INTO DimBookingStatus (reservation_status, cancellation_flag)
SELECT DISTINCT
    reservation_status,
    is_canceled
FROM dbo.hotel_bookings;


SELECT COUNT(*) AS StatusCount FROM DimBookingStatus;

INSERT INTO DimDate (
    full_date,
    year,
    month_name,
    month_number,
    week_number,
    day_number,
    reservation_status_date
)
SELECT DISTINCT
    DATEFROMPARTS(
        arrival_date_year,
        CASE arrival_date_month
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
    CASE arrival_date_month
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


SELECT COUNT(*) AS DateCount FROM DimDate;


SELECT 'DimHotel' AS TableName, COUNT(*) AS Rows FROM DimHotel
UNION ALL
SELECT 'DimMarketSegment', COUNT(*) FROM DimMarketSegment
UNION ALL
SELECT 'DimRoom', COUNT(*) FROM DimRoom
UNION ALL
SELECT 'DimStay', COUNT(*) FROM DimStay
UNION ALL
SELECT 'DimBookingStatus', COUNT(*) FROM DimBookingStatus
UNION ALL
SELECT 'DimDate', COUNT(*) FROM DimDate;

SELECT COUNT(*) AS cnt
FROM dbo.hotel_bookings hb
JOIN dbo.DimHotel h
  ON h.hotel = hb.hotel;



truncate table dbo.FactBooking;

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

 --Checking

 SELECT COUNT(*) AS FactRows FROM dbo.FactBooking;

 select top 20 * from dbo.FactBooking;

SELECT COUNT(*) AS BadDateFK
FROM dbo.FactBooking f
LEFT JOIN dbo.DimDate d ON f.Date_ID = d.Date_ID
WHERE d.Date_ID IS NULL;


SELECT h.hotel_type,
       SUM(f.adr * f.total_stay_nights) AS TotalRevenue
FROM dbo.FactBooking f
JOIN dbo.DimHotel h ON f.Hotel_ID = h.Hotel_ID
GROUP BY h.hotel_type
ORDER BY TotalRevenue DESC;


---------------------------------------




USE HotelDW;
GO

DBCC SHRINKFILE (HotelDW_log, 1);
GO


ALTER DATABASE HotelDW SET RECOVERY SIMPLE;
GO


INSERT INTO FactBooking (Date_ID, Hotel_ID, Guest_ID, MarketSegment_ID,
    Room_ID, Stay_ID, BookingStatus_ID, is_canceled, lead_time, adr,
    total_stay_nights, total_guests)
SELECT TOP (50000)
    d.Date_ID,
    h.Hotel_ID,
    g.Guest_ID,
    m.MarketSegment_ID,
    r.Room_ID,
    s.Stay_ID,
    b.BookingStatus_ID,
    hb.is_canceled,
    hb.lead_time,
    hb.adr,
    hb.stays_in_week_nights + hb.stays_in_weekend_nights,
    hb.adults + ISNULL(hb.children,0) + ISNULL(hb.babies,0)
FROM dbo.hotel_bookings hb
JOIN DimDate d ON d.year = hb.arrival_date_year
JOIN DimHotel h ON h.hotel_type = hb.hotel
JOIN DimMarketSegment m ON m.market_segment = hb.market_segment
JOIN DimRoom r ON r.reserved_room_type = hb.reserved_room_type
JOIN DimStay s ON s.total_nights = hb.stays_in_week_nights + hb.stays_in_weekend_nights
JOIN DimBookingStatus b ON b.reservation_status = hb.reservation_status
JOIN DimGuest g ON g.country = hb.country;


SELECT COUNT(*) AS FactRows FROM FactBooking;

SELECT TOP 10 * FROM FactBooking;


SELECT hotel_type, COUNT(*)
FROM FactBooking f
JOIN DimHotel h ON f.Hotel_ID = h.Hotel_ID
GROUP BY hotel_type;

SELECT SUM(is_canceled) FROM FactBooking;


SELECT TOP 5
    g.Guest_ID,
    COUNT(f.Booking_ID) AS TotalBookings
FROM FactBooking f
JOIN DimGuest g ON f.Guest_ID = g.Guest_ID
GROUP BY g.Guest_ID
ORDER BY TotalBookings DESC;


SELECT
    d.year,
    d.month_name,
    COUNT(f.Booking_ID) AS TotalBookings
FROM FactBooking f
JOIN DimDate d ON f.Date_ID = d.Date_ID
GROUP BY d.year, d.month_name, d.month_number
ORDER BY d.year, d.month_number;

SELECT
    h.hotel_type,
    SUM(f.is_canceled) AS TotalCancellations
FROM FactBooking f
JOIN DimHotel h ON f.Hotel_ID = h.Hotel_ID
GROUP BY h.hotel_type;


SELECT
    d.month_name,
    AVG(f.adr) AS AvgADR
FROM FactBooking f
JOIN DimDate d ON f.Date_ID = d.Date_ID
GROUP BY d.month_name, d.month_number
ORDER BY d.month_number;


SELECT
    m.market_segment,
    COUNT(f.Booking_ID) AS TotalBookings
FROM FactBooking f
JOIN DimMarketSegment m 
    ON f.MarketSegment_ID = m.MarketSegment_ID
GROUP BY m.market_segment
ORDER BY TotalBookings DESC;


SELECT
    r.reserved_room_type,
    COUNT(f.Booking_ID) AS TimesBooked
FROM FactBooking f
JOIN DimRoom r ON f.Room_ID = r.Room_ID
GROUP BY r.reserved_room_type
ORDER BY TimesBooked DESC;


SELECT DISTINCT
    g.Guest_ID,
    h.hotel_type,
    m.market_segment
FROM FactBooking f
JOIN DimGuest g ON f.Guest_ID = g.Guest_ID
JOIN DimHotel h ON f.Hotel_ID = h.Hotel_ID
JOIN DimMarketSegment m ON f.MarketSegment_ID = m.MarketSegment_ID;

Select * from dbo.FactBooking;
Select * from dbo.DimGuest;
Select * from dbo.DimHotel;
Select * from dbo.DimDate;
Select * from dbo.DimMarketSegment;
Select * from dbo.DimRoom;

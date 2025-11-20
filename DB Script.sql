------------------------------------------------------------
-- GHOSTBUSTERS FLEET – FULL REBUILD & SEED SCRIPT
-- Targets SQL Server / (localdb)\MSSQLLocalDB
------------------------------------------------------------
USE [GhostbustersFleet];
GO

------------------------------------------------------------
-- 1. DROP CHILD TABLES (FK ORDER)
------------------------------------------------------------
IF OBJECT_ID('dbo.MaintenanceEvent', 'U') IS NOT NULL
    DROP TABLE dbo.MaintenanceEvent;
IF OBJECT_ID('dbo.RentedEquipment', 'U') IS NOT NULL
    DROP TABLE dbo.RentedEquipment;
IF OBJECT_ID('dbo.Vehicle', 'U') IS NOT NULL
    DROP TABLE dbo.Vehicle;
IF OBJECT_ID('dbo.Rental', 'U') IS NOT NULL
    DROP TABLE dbo.Rental;
IF OBJECT_ID('dbo.Equipment', 'U') IS NOT NULL
    DROP TABLE dbo.Equipment;
IF OBJECT_ID('dbo.Customer', 'U') IS NOT NULL
    DROP TABLE dbo.Customer;
IF OBJECT_ID('dbo.Employee', 'U') IS NOT NULL
    DROP TABLE dbo.Employee;
GO

------------------------------------------------------------
-- 2. DROP SEQUENCES (IF ANY)
------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sys.sequences WHERE name = 'Seq_CustomerCode')
    DROP SEQUENCE Seq_CustomerCode;
IF EXISTS (SELECT 1 FROM sys.sequences WHERE name = 'Seq_RentalCode')
    DROP SEQUENCE Seq_RentalCode;
IF EXISTS (SELECT 1 FROM sys.sequences WHERE name = 'Seq_MaintenanceCode')
    DROP SEQUENCE Seq_MaintenanceCode;
GO

------------------------------------------------------------
-- 3. RECREATE SEQUENCES FOR CODES
------------------------------------------------------------
CREATE SEQUENCE Seq_CustomerCode AS INT
    START WITH 1 INCREMENT BY 1;

CREATE SEQUENCE Seq_RentalCode AS INT
    START WITH 1 INCREMENT BY 1;

CREATE SEQUENCE Seq_MaintenanceCode AS INT
    START WITH 1 INCREMENT BY 1;
GO

------------------------------------------------------------
-- 4. CREATE TABLES (MATCH EF + NEW CODE FIELDS)
------------------------------------------------------------

--------------------
-- Employee
--------------------
CREATE TABLE dbo.Employee
(
    EmployeeId   UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_Employee_EmployeeId DEFAULT (NEWID()),
    [Name]       NVARCHAR(100)   NOT NULL,
    Username     NVARCHAR(50)    NOT NULL,
    [Password]   NVARCHAR(200)   NOT NULL,
    CONSTRAINT PK_Employee PRIMARY KEY (EmployeeId),
    CONSTRAINT UQ_Employee_Username UNIQUE (Username)
);
GO

--------------------
-- Customer
--------------------
CREATE TABLE dbo.Customer
(
    CustomerId      UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_Customer_CustomerId DEFAULT (NEWID()),

    -- NEW business-facing code: CT-0001, CT-0002, ...
    CustomerCode    VARCHAR(32) NOT NULL
        CONSTRAINT DF_Customer_CustomerCode 
            DEFAULT ('CT-' + RIGHT('0000' + CAST(NEXT VALUE FOR Seq_CustomerCode AS VARCHAR(4)), 4)),

    CustomerName    NVARCHAR(200) NOT NULL,
    CustomerAddress NVARCHAR(MAX) NULL,
    CustomerGovtId  NVARCHAR(100) NULL,
    CustomerEmail   NVARCHAR(200) NULL,
    CustomerPhone   NVARCHAR(50)  NULL,

    CONSTRAINT PK_Customer PRIMARY KEY (CustomerId),
    CONSTRAINT UQ_Customer_Code UNIQUE (CustomerCode)
);
GO

CREATE INDEX IX_Customer_Phone ON dbo.Customer(CustomerPhone);
GO

--------------------
-- Equipment
--------------------
CREATE TABLE dbo.Equipment
(
    EquipmentId          UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_Equipment_EquipmentId DEFAULT (NEWID()),

    -- Already in EF entity
    EquipmentCode        VARCHAR(32)  NOT NULL,
    EquipmentName        NVARCHAR(200) NOT NULL,
    EquipmentDescription NVARCHAR(MAX) NULL,
    EquipmentValue       DECIMAL(12,2) NOT NULL,
    EquipmentCategory    NVARCHAR(50)  NOT NULL,
    EquipmentType        NVARCHAR(50)  NOT NULL,

    -- Tracking code like TRK-[Type]-0001
    EquipmentTrackingId  NVARCHAR(100) NULL,

    -- Available | UnderMaintenance | OutForRental | Damaged
    EquipmentAvailability NVARCHAR(30) NOT NULL,

    CONSTRAINT PK_Equipment PRIMARY KEY (EquipmentId)
);
GO

CREATE UNIQUE INDEX UQ_Equipment_EquipmentCode 
    ON dbo.Equipment(EquipmentCode);
GO

--------------------
-- Vehicle (1:1 with Equipment)
--------------------
CREATE TABLE dbo.Vehicle
(
    VehicleId    UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_Vehicle_VehicleId DEFAULT (NEWID()),
    EquipmentId  UNIQUEIDENTIFIER NOT NULL,
    [Year]       INT             NULL,
    [Make]       NVARCHAR(100)   NULL,
    [Model]      NVARCHAR(100)   NULL,
    Odometer     INT             NULL,
    VIN          NVARCHAR(50)    NULL,
    LicensePlate NVARCHAR(50)    NULL,

    CONSTRAINT PK_Vehicle PRIMARY KEY (VehicleId),

    CONSTRAINT FK_Vehicle_Equipment
        FOREIGN KEY (EquipmentId)
        REFERENCES dbo.Equipment(EquipmentId)
);
GO

CREATE UNIQUE INDEX UQ_Vehicle_EquipmentId ON dbo.Vehicle(EquipmentId);
CREATE UNIQUE INDEX UQ_Vehicle_VIN          ON dbo.Vehicle(VIN) WHERE VIN IS NOT NULL;
CREATE UNIQUE INDEX UQ_Vehicle_LicensePlate ON dbo.Vehicle(LicensePlate) WHERE LicensePlate IS NOT NULL;
GO

--------------------
-- Rental
--------------------
CREATE TABLE dbo.Rental
(
    RentalId   UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_Rental_RentalId DEFAULT (NEWID()),

    -- NEW business-facing code: RT-0001, RT-0002, ...
    RentalCode VARCHAR(32) NOT NULL
        CONSTRAINT DF_Rental_RentalCode 
            DEFAULT ('RT-' + RIGHT('0000' + CAST(NEXT VALUE FOR Seq_RentalCode AS VARCHAR(4)), 4)),

    CustomerId UNIQUEIDENTIFIER NULL,
    StartDate  DATE            NOT NULL,
    EndDate    DATE            NOT NULL,
    [Status]   NVARCHAR(20)    NOT NULL,   -- Draft | Reserved | CheckedOut | Returned | Closed
    [Note]     NVARCHAR(MAX)   NULL,
    [Scope]    NVARCHAR(20)    NULL,       -- Internal / External

    CONSTRAINT PK_Rental PRIMARY KEY (RentalId),

    CONSTRAINT FK_Rental_Customer
        FOREIGN KEY (CustomerId)
        REFERENCES dbo.Customer(CustomerId)
);
GO

--------------------
-- RentedEquipment (line items)
--------------------
CREATE TABLE dbo.RentedEquipment
(
    RentedEquipmentId     UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_RentedEquipment_RentedEquipmentId DEFAULT (NEWID()),
    RentalId              UNIQUEIDENTIFIER NOT NULL,
    EquipmentId           UNIQUEIDENTIFIER NOT NULL,
    EquipmentDailyRate    DECIMAL(10,2) NOT NULL,
    EquipmentSecurityFee  DECIMAL(10,2) NOT NULL,
    EquipmentDamageFee    DECIMAL(10,2) NOT NULL,

    CONSTRAINT PK_RentedEquipment PRIMARY KEY (RentedEquipmentId),

    CONSTRAINT FK_RentedEquipment_Equipment
        FOREIGN KEY (EquipmentId)
        REFERENCES dbo.Equipment(EquipmentId),

    CONSTRAINT FK_RentedEquipment_Rental
        FOREIGN KEY (RentalId)
        REFERENCES dbo.Rental(RentalId)
);
GO

--------------------
-- MaintenanceEvent
--------------------
CREATE TABLE dbo.MaintenanceEvent
(
    MaintenanceEventId UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_MaintenanceEvent_MaintenanceEventId DEFAULT (NEWID()),

    -- NEW business-facing code: MT-GEN-0001, ...
    MaintenanceCode    VARCHAR(32) NOT NULL
        CONSTRAINT DF_MaintenanceEvent_MaintenanceCode
            DEFAULT ('MT-GEN-' + RIGHT('0000' + CAST(NEXT VALUE FOR Seq_MaintenanceCode AS VARCHAR(4)), 4)),

    EquipmentId        UNIQUEIDENTIFIER NOT NULL,
    RentalId           UNIQUEIDENTIFIER NULL,
    LastServiceDate    DATE            NOT NULL,
    NextServiceDue     DATE            NULL,
    EventStatus        NVARCHAR(20)    NOT NULL,   -- Open | Closed
    OpenedAt           DATETIME2(0)    NOT NULL 
        CONSTRAINT DF_MaintenanceEvent_OpenedAt DEFAULT (SYSUTCDATETIME()),
    ClosedAt           DATETIME2(0)    NULL,
    MaintenanceOutcome NVARCHAR(20)    NULL,       -- Working | Damaged
    Notes              NVARCHAR(MAX)   NULL,

    CONSTRAINT PK_MaintenanceEvent PRIMARY KEY (MaintenanceEventId),

    CONSTRAINT FK_MaintenanceEvent_Equipment
        FOREIGN KEY (EquipmentId)
        REFERENCES dbo.Equipment(EquipmentId),

    CONSTRAINT FK_MaintenanceEvent_Rental
        FOREIGN KEY (RentalId)
        REFERENCES dbo.Rental(RentalId)
);
GO

------------------------------------------------------------
-- 5. SEED EMPLOYEES (10 TOTAL, INCLUDING ADMIN)
------------------------------------------------------------
INSERT INTO dbo.Employee ([Name], Username, [Password])
VALUES
('System Administrator', 'Admin',       'Admin@123!'),
('Dana Barrett',         'dana.b',     'Pass@1001'),
('Peter Venkman',        'pvenkman',   'Ghost#01'),
('Ray Stantz',           'ray.s',      'Proton#02'),
('Egon Spengler',        'egon.s',     'PKE-Meter3'),
('Winston Zeddemore',    'winston.z',  'Trap#404'),
('Janine Melnitz',       'janine.m',   'Desk@Ops'),
('Louis Tully',          'louis.t',    'Keymaster1'),
('Jill Diagnostics',     'jill.diag',  'Diagnostics!'),
('Ops Bot',              'ops.bot',    'AutoSeed01');
GO

------------------------------------------------------------
-- 6. SEED 50 CUSTOMERS
--  - 10-digit phones
--  - Govt IDs = alphanumeric (three letters + 7 digits)
------------------------------------------------------------
;WITH N AS
(
    SELECT TOP (50)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects
)
INSERT INTO dbo.Customer (CustomerName, CustomerAddress, CustomerGovtId, CustomerEmail, CustomerPhone)
SELECT
    CONCAT('Customer ', n)                          AS CustomerName,
    CONCAT('Unit ', n, ', 100 Ghost Ave, Toronto')  AS CustomerAddress,
    CONCAT('GBR', RIGHT('0000000' + CAST(n AS VARCHAR(7)), 7)) AS CustomerGovtId,
    CONCAT('client', n, '@example.com')             AS CustomerEmail,
    -- 10-digit phone: 647 + 7 digits
    CONCAT('647', RIGHT('0000000' + CAST(n AS VARCHAR(7)), 7)) AS CustomerPhone
FROM N;
GO

------------------------------------------------------------
-- 7. SEED ~500 EQUIPMENT ITEMS
--    Vehicles: 5 of each type
--    Other categories per your Ghost business
------------------------------------------------------------
DECLARE @EquipmentTypes TABLE
(
    EquipmentCategory NVARCHAR(50),
    EquipmentType     NVARCHAR(50),
    Qty               INT,
    BaseValue         DECIMAL(12,2)
);

INSERT INTO @EquipmentTypes (EquipmentCategory, EquipmentType, Qty, BaseValue)
VALUES
('Vehicle',     'SUV',                 5,  90000),
('Vehicle',     'Van',                 5,  95000),
('Vehicle',     'Pickup',              5,  85000),

('PPE',         'Hazmat Suit',        40,   1200),
('PPE',         'Respirator',         30,    600),
('PPE',         'Containment Harness',30,    800),

('Tools',       'Proton Pack',        60,  15000),
('Tools',       'Ghost Trap',         60,   8000),
('Tools',       'PKE Meter',          40,   5000),

('Electronics', 'Drone',              60,  14000),
('Electronics', 'Camera',             50,  11000),
('Electronics', 'Mic',                40,   7000),
('Electronics', 'Sensor',             40,   4000),

('Hardware',    'Server Node',        35,  20000);

;WITH EquipCTE AS
(
    SELECT
        et.EquipmentCategory,
        et.EquipmentType,
        et.BaseValue,
        ROW_NUMBER() OVER (PARTITION BY et.EquipmentCategory, et.EquipmentType ORDER BY (SELECT NULL)) AS rn,
        et.Qty
    FROM @EquipmentTypes et
),
Expanded AS
(
    -- Expand each type up to its Qty using recursive CTE
    SELECT EquipmentCategory, EquipmentType, BaseValue, 1 AS rn
    FROM @EquipmentTypes
    UNION ALL
    SELECT e.EquipmentCategory, e.EquipmentType, e.BaseValue, e2.rn + 1
    FROM @EquipmentTypes e
    JOIN Expanded e2
        ON e.EquipmentCategory = e2.EquipmentCategory
       AND e.EquipmentType     = e2.EquipmentType
       AND e2.rn < e.Qty
)
INSERT INTO dbo.Equipment
(
    EquipmentCode,
    EquipmentName,
    EquipmentDescription,
    EquipmentValue,
    EquipmentCategory,
    EquipmentType,
    EquipmentTrackingId,
    EquipmentAvailability
)
SELECT
    -- EQP-[TypeAbbrev]-0001
    'EQP-' 
      + REPLACE(UPPER(LEFT(EquipmentType, 4)), ' ', '') 
      + '-' + RIGHT('0000' + CAST(rn AS VARCHAR(4)), 4) AS EquipmentCode,
    -- Techy name
    CONCAT(EquipmentType, ' Unit ', rn) AS EquipmentName,
    CONCAT(
        EquipmentType,
        ' configured for high-intensity ghost diagnostics (unit ',
        rn, '). Category: ', EquipmentCategory
    ) AS EquipmentDescription,
    BaseValue + (rn * 100) AS EquipmentValue,
    EquipmentCategory,
    EquipmentType,
    -- TRK-[TypeAbbrev]-0001
    CONCAT(
        'TRK-',
        REPLACE(UPPER(LEFT(EquipmentType, 4)), ' ', ''),
        '-',
        RIGHT('0000' + CAST(rn AS VARCHAR(4)), 4)
    ) AS EquipmentTrackingId,
    -- Rotate availability
    CASE rn % 4
        WHEN 1 THEN 'Available'
        WHEN 2 THEN 'OutForRental'
        WHEN 3 THEN 'UnderMaintenance'
        ELSE 'Damaged'
    END AS EquipmentAvailability
FROM Expanded
OPTION (MAXRECURSION 0);
GO

------------------------------------------------------------
-- 8. SEED VEHICLES (5 OF EACH VEHICLE TYPE)
--    Link 1:1 with Equipment rows where Category='Vehicle'
------------------------------------------------------------
;WITH VehicleEquip AS
(
    SELECT
        e.EquipmentId,
        e.EquipmentType,
        ROW_NUMBER() OVER (PARTITION BY e.EquipmentType ORDER BY e.EquipmentId) AS rn
    FROM dbo.Equipment e
    WHERE e.EquipmentCategory = 'Vehicle'
)
INSERT INTO dbo.Vehicle (EquipmentId, [Year], [Make], [Model], Odometer, VIN, LicensePlate)
SELECT
    v.EquipmentId,
    2023 + (v.rn % 3) AS [Year],
    CASE v.EquipmentType
        WHEN 'SUV'    THEN 'Ecto Motors'
        WHEN 'Van'    THEN 'Specter Labs'
        WHEN 'Pickup' THEN 'Phantom Works'
        ELSE 'GhostCorp'
    END AS [Make],
    CONCAT(v.EquipmentType, ' Mk-', v.rn) AS [Model],
    5000 * v.rn AS Odometer,

    -- VIN is now unique
    CONCAT('VIN', RIGHT(CONVERT(VARCHAR(32), ABS(CHECKSUM(NEWID()))), 10)) AS VIN,

    -- LICENSE PLATE unique for entire DB
    CONCAT(
        CASE v.EquipmentType 
            WHEN 'SUV'    THEN 'GBS'
            WHEN 'Van'    THEN 'GBV'
            WHEN 'Pickup' THEN 'GBP'
            ELSE 'GBX'
        END,
        RIGHT(CONVERT(VARCHAR(10), ABS(CHECKSUM(NEWID()))), 4)
    ) AS LicensePlate
FROM VehicleEquip v;
GO

------------------------------------------------------------
-- 9. SEED 200 RENTALS (JAN–DEC, ALL STATUSES)
------------------------------------------------------------
DECLARE @Today    DATE = CAST(GETDATE() AS DATE);

;WITH N AS
(
    SELECT TOP (200)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects
),
Customers AS
(
    SELECT 
        CustomerId,
        ROW_NUMBER() OVER (ORDER BY CustomerId) AS rn
    FROM dbo.Customer
)
INSERT INTO dbo.Rental (CustomerId, StartDate, EndDate, [Status], [Note], [Scope])
SELECT
    CASE 
        WHEN (n % 4) = 0 THEN NULL          -- Internal
        ELSE c.CustomerId                   -- External
    END AS CustomerId,

    -- StartDate based on scenario (past, active, future)
    CASE 
        WHEN (n % 6) IN (1, 2) THEN DATEADD(DAY, - (30 + (n % 30)), @Today)              -- Past rentals
        WHEN (n % 6) IN (3, 4) THEN DATEADD(DAY, - (n % 5), @Today)                      -- Currently active
        ELSE                DATEADD(DAY, 1 + (n % 30), @Today)                           -- Future bookings
    END AS StartDate,

    -- EndDate always after StartDate
    CASE 
        WHEN (n % 6) IN (1, 2) THEN                                                  -- Past
            DATEADD(DAY, 3 + (n % 10), DATEADD(DAY, - (30 + (n % 30)), @Today))
        WHEN (n % 6) IN (3, 4) THEN                                                  -- Active
            DATEADD(DAY, 1 + (n % 10), @Today)
        ELSE                                                                         -- Future
            DATEADD(DAY, 3 + (n % 10), DATEADD(DAY, 1 + (n % 30), @Today))
    END AS EndDate,

    -- Status aligned with dates:
    --  * Past rentals -> Returned/Closed
    --  * Overlapping today -> CheckedOut
    --  * Future rentals -> Draft/Reserved
    CASE (n % 6)
        WHEN 1 THEN 'Returned'      -- Completed in the past
        WHEN 2 THEN 'Closed'        -- Completed and closed in the past
        WHEN 3 THEN 'CheckedOut'    -- Currently out
        WHEN 4 THEN 'CheckedOut'    -- Currently out
        WHEN 5 THEN 'Draft'         -- Future draft booking
        ELSE       'Reserved'       -- Future reserved rental
    END AS [Status],

    CONCAT('Auto-generated rental #', n) AS [Note],
    CASE WHEN (n % 4) = 0 THEN 'Internal' ELSE 'External' END AS [Scope]
FROM N
LEFT JOIN Customers c
    ON ((n - 1) % 50) + 1 = c.rn;
GO


------------------------------------------------------------
-- 10. SEED RENTED EQUIPMENT:
--     Ensure almost every equipment is rented at least once
------------------------------------------------------------
;WITH Equip AS
(
    SELECT 
        e.EquipmentId,
        e.EquipmentValue,
        ROW_NUMBER() OVER (ORDER BY e.EquipmentId) AS rn
    FROM dbo.Equipment e
),
Rents AS
(
    SELECT
        r.RentalId,
        ROW_NUMBER() OVER (ORDER BY r.StartDate, r.RentalId) AS rn
    FROM dbo.Rental r
)
INSERT INTO dbo.RentedEquipment
(
    RentalId,
    EquipmentId,
    EquipmentDailyRate,
    EquipmentSecurityFee,
    EquipmentDamageFee
)
SELECT
    r.RentalId,
    e.EquipmentId,
    CAST(e.EquipmentValue * 0.015 AS DECIMAL(10,2)) AS DailyRate,
    CAST(e.EquipmentValue * 0.10  AS DECIMAL(10,2)) AS SecurityFee,
    CAST(e.EquipmentValue * 0.25  AS DECIMAL(10,2)) AS DamageFee
FROM Equip e
JOIN Rents r
    ON ((e.rn - 1) % 200) + 1 = r.rn;
GO

------------------------------------------------------------
-- 11. SEED 100 MAINTENANCE EVENTS
------------------------------------------------------------
;WITH EquipTop AS
(
    SELECT TOP (100)
        e.EquipmentId,
        ROW_NUMBER() OVER (ORDER BY e.EquipmentId) AS rn
    FROM dbo.Equipment e
    ORDER BY e.EquipmentId
),
RentSample AS
(
    -- Sample rentals to tie maintenance to.
    -- We don't filter by date here, but LastServiceDate will always be AFTER the rental's EndDate.
    SELECT 
        r.RentalId,
        r.EndDate,
        ROW_NUMBER() OVER (ORDER BY r.EndDate, r.RentalId) AS rn
    FROM dbo.Rental r
)
INSERT INTO dbo.MaintenanceEvent
(
    EquipmentId,
    RentalId,
    LastServiceDate,
    NextServiceDue,
    EventStatus,
    OpenedAt,
    ClosedAt,
    MaintenanceOutcome,
    Notes
)
SELECT
    e.EquipmentId,
    rs.RentalId,  -- Always associated with a rental (non-NULL)

    -- Last service happens shortly AFTER the rental ends
    DATEADD(DAY, 1 + (e.rn % 10), rs.EndDate) AS LastServiceDate,

    -- Next service ~60 days after last service
    DATEADD(DAY, 60, DATEADD(DAY, 1 + (e.rn % 10), rs.EndDate)) AS NextServiceDue,

    -- Some events are still open, others closed
    CASE WHEN (e.rn % 4) = 0 THEN 'Open' ELSE 'Closed' END AS EventStatus,

    -- Opened around the last service date
    CAST(DATEADD(DAY, 1 + (e.rn % 10), rs.EndDate) AS DATETIME2(0)) AS OpenedAt,

    -- Closed a few days after opening (if closed)
    CASE 
        WHEN (e.rn % 4) = 0 THEN NULL
        ELSE CAST(DATEADD(DAY, 5 + (e.rn % 10), rs.EndDate) AS DATETIME2(0))
    END AS ClosedAt,

    CASE WHEN (e.rn % 5) = 0 THEN 'Damaged' ELSE 'Working' END AS MaintenanceOutcome,
    CONCAT('Auto-generated maintenance event #', e.rn) AS Notes
FROM EquipTop e
JOIN RentSample rs
    ON ((e.rn - 1) % 200) + 1 = rs.rn;  -- Distribute maintenance across many rentals
GO

------------------------------------------------------------
-- DONE
-- You now have:
--  - 10 Employees
--  - 50 Customers with CT-0001 style codes
--  - ~500 Equipment (with EQP-[TypeAbbrev]-0001 and TRK-* tracking IDs)
--  - 200 Rentals across the year with RT-0001 style codes & all statuses
--  - RentedEquipment rows covering essentially every equipment item
--  - 100 MaintenanceEvent rows with MT-GEN-0001 style codes
------------------------------------------------------------

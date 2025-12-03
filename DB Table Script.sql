------------------------------------------------------------
-- PHASE 1 - DATABASE & SCHEMA
------------------------------------------------------------

-- 0. Create database if it doesn't exist
IF DB_ID('GhostbustersFleet') IS NULL
BEGIN
    CREATE DATABASE GhostbustersFleet;
END;
GO

USE [GhostbustersFleet];
GO

------------------------------------------------------------
-- 1. DROP TABLES IN FK ORDER
------------------------------------------------------------
IF OBJECT_ID('dbo.Maintenance', 'U') IS NOT NULL
    DROP TABLE dbo.Maintenance;

IF OBJECT_ID('dbo.RentedEquipment', 'U') IS NOT NULL
    DROP TABLE dbo.RentedEquipment;

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
-- 2. DROP & CREATE SEQUENCES
------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sys.sequences WHERE name = 'Seq_CustomerCode')
    DROP SEQUENCE Seq_CustomerCode;
IF EXISTS (SELECT 1 FROM sys.sequences WHERE name = 'Seq_RentalCode')
    DROP SEQUENCE Seq_RentalCode;
GO

CREATE SEQUENCE Seq_CustomerCode AS INT
    START WITH 1 INCREMENT BY 1;

CREATE SEQUENCE Seq_RentalCode AS INT
    START WITH 1 INCREMENT BY 1;
GO

------------------------------------------------------------
-- 3. CREATE TABLES
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

    CustomerCode    VARCHAR(32) NOT NULL
        CONSTRAINT DF_Customer_CustomerCode 
            DEFAULT ('CT-' + RIGHT('0000' + CAST(NEXT VALUE FOR Seq_CustomerCode AS VARCHAR(4)), 4)),

    CustomerName    NVARCHAR(200) NOT NULL,
    CustomerAddress NVARCHAR(MAX) NULL,
    CustomerGovtId  NVARCHAR(100) NULL,
    CustomerEmail   NVARCHAR(200) NULL,
    CustomerPhone   NVARCHAR(50)  NULL,

    Username        NVARCHAR(50)  NULL,
    [Password]      NVARCHAR(200) NULL,

    CONSTRAINT PK_Customer PRIMARY KEY (CustomerId),
    CONSTRAINT UQ_Customer_Code UNIQUE (CustomerCode)
);
GO

CREATE INDEX IX_Customer_Phone ON dbo.Customer(CustomerPhone);
GO

CREATE UNIQUE INDEX UQ_Customer_Username ON dbo.Customer(Username)
WHERE Username IS NOT NULL;
GO

--------------------
-- Equipment
--------------------
CREATE TABLE dbo.Equipment
(
    EquipmentId           UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_Equipment_EquipmentId DEFAULT (NEWID()),

    EquipmentCode         VARCHAR(32)      NOT NULL,
    EquipmentDescription  NVARCHAR(MAX)    NULL,
    EquipmentValue        DECIMAL(12,2)    NOT NULL,
    EquipmentCategory     NVARCHAR(50)     NOT NULL,
    EquipmentType         NVARCHAR(50)     NOT NULL,
    EquipmentTrackingId   NVARCHAR(100)    NULL,

    -- Available | UnderMaintenance | OutForRental | Damaged | Unavailable
    EquipmentAvailability NVARCHAR(30)     NOT NULL,

    CONSTRAINT PK_Equipment PRIMARY KEY (EquipmentId)
);
GO

CREATE UNIQUE INDEX UQ_Equipment_EquipmentCode 
    ON dbo.Equipment(EquipmentCode);
GO

--------------------
-- Rental
--------------------
CREATE TABLE dbo.Rental
(
    RentalId   UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_Rental_RentalId DEFAULT (NEWID()),

    RentalCode VARCHAR(32) NOT NULL
        CONSTRAINT DF_Rental_RentalCode 
            DEFAULT ('RT-' + RIGHT('0000' + CAST(NEXT VALUE FOR Seq_RentalCode AS VARCHAR(4)), 4)),

    CustomerId UNIQUEIDENTIFIER NULL,
    StartDate  DATE            NOT NULL,
    EndDate    DATE            NOT NULL,

    -- Draft | Reserved | CheckedOut | Returned | Overdue | Closed
    [Status]   NVARCHAR(20)    NOT NULL,

    [Note]     NVARCHAR(MAX)   NULL,

    -- Internal / External
    [Scope]    NVARCHAR(20)    NULL,

    CONSTRAINT PK_Rental PRIMARY KEY (RentalId),
    CONSTRAINT FK_Rental_Customer
        FOREIGN KEY (CustomerId)
        REFERENCES dbo.Customer(CustomerId)
);
GO

--------------------
-- RentedEquipment
--------------------
CREATE TABLE dbo.RentedEquipment
(
    RentedEquipmentId UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_RentedEquipment_RentedEquipmentId DEFAULT (NEWID()),
    RentalId          UNIQUEIDENTIFIER NOT NULL,
    EquipmentId       UNIQUEIDENTIFIER NOT NULL,

    CONSTRAINT PK_RentedEquipment PRIMARY KEY (RentedEquipmentId),

    CONSTRAINT FK_RentedEquipment_Equipment
        FOREIGN KEY (EquipmentId)
        REFERENCES dbo.Equipment(EquipmentId),

    CONSTRAINT FK_RentedEquipment_Rental
        FOREIGN KEY (RentalId)
        REFERENCES dbo.Rental(RentalId)
);
GO

CREATE UNIQUE INDEX UQ_RentedEquipment_Rental_Equipment
    ON dbo.RentedEquipment(RentalId, EquipmentId);
GO

--------------------
-- Maintenance
--------------------
CREATE TABLE dbo.Maintenance
(
    MaintenanceId   UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_Maintenance_MaintenanceId DEFAULT (NEWID()),

    -- MT-[TypeCode]-xxx
    MaintenanceCode NVARCHAR(32)     NOT NULL,

    EquipmentId     UNIQUEIDENTIFIER NOT NULL,
    RentalId        UNIQUEIDENTIFIER NULL,

    LastServiceDate DATE             NOT NULL,

    -- Open | Closed
    [Status]        NVARCHAR(20)     NOT NULL,

    -- Only dates (no time)
    OpenDate        DATE             NOT NULL,
    CloseDate       DATE             NULL,

    -- Working | Damaged (never NULL)
    Outcome         NVARCHAR(20)     NOT NULL,

    Technician      NVARCHAR(200)    NULL,
    Notes           NVARCHAR(MAX)    NULL,

    CONSTRAINT PK_Maintenance PRIMARY KEY (MaintenanceId),

    CONSTRAINT FK_Maintenance_Equipment
        FOREIGN KEY (EquipmentId)
        REFERENCES dbo.Equipment(EquipmentId),

    CONSTRAINT FK_Maintenance_Rental
        FOREIGN KEY (RentalId)
        REFERENCES dbo.Rental(RentalId)
);
GO

CREATE UNIQUE INDEX UQ_Maintenance_Code 
    ON dbo.Maintenance(MaintenanceCode);
GO

-- Ensure 1:1 Maintenance snapshot per Equipment
CREATE UNIQUE INDEX UQ_Maintenance_Equipment
    ON dbo.Maintenance(EquipmentId);
GO
------------------------------------------------------------
-- PHASE 2 - CORE SEED: EMPLOYEES, CUSTOMERS, EQUIPMENT
------------------------------------------------------------

USE [GhostbustersFleet];
GO

------------------------------------------------------------
-- 1. EMPLOYEES
------------------------------------------------------------
DELETE FROM dbo.Employee;
GO

INSERT INTO dbo.Employee ([Name], Username, [Password])
VALUES
    ('System Administrator', 'Admin',       'Admin@123!'),
    ('Dana Barrett',         'dana.b',      'Pass@1001'),
    ('Peter Venkman',        'pvenkman',    'Ghost#01'),
    ('Ray Stantz',           'ray.s',       'Proton#02'),
    ('Egon Spengler',        'egon.s',      'PKE-Meter3'),
    ('Winston Zeddemore',    'winston.z',   'Trap#404'),
    ('Janine Melnitz',       'janine.m',    'Desk#202'),
    ('Louis Tully',          'louis.t',     'Keymaster#1');
GO

------------------------------------------------------------
-- 2. CUSTOMERS
------------------------------------------------------------
DELETE FROM dbo.Customer;
GO

DECLARE @i INT = 1;
WHILE @i <= 25
BEGIN
    INSERT INTO dbo.Customer
        (CustomerName, CustomerAddress, CustomerGovtId, CustomerEmail, CustomerPhone)
    VALUES
        (
            CONCAT('Customer ', @i),
            CONCAT('Unit ', @i, ', 100 Ghost Ave, Toronto'),
            CONCAT('GBR', RIGHT('0000000' + CAST(@i AS VARCHAR(7)), 7)),
            CONCAT('client', @i, '@example.com'),
            CONCAT('647', RIGHT('0000000' + CAST(@i AS VARCHAR(7)), 7))
        );

    SET @i += 1;
END;
GO

-- Ghostbusters internal team
INSERT INTO dbo.Customer (CustomerName, CustomerAddress, CustomerGovtId, CustomerEmail, CustomerPhone, Username, [Password])
VALUES ('Ghostbusting Team', 'HQ – Firehouse, NYC', 'GBR0000000', 'team@ghostbusters.local', '4165550000', 'ghostbusters', 'Ghost!2025');
GO

------------------------------------------------------------
-- 3. EQUIPMENT (500 ITEMS ACROSS CATEGORIES/TYPES)
------------------------------------------------------------

DELETE FROM dbo.Equipment;
GO

------------------------------------------------------------
-- VEHICLES (15 total)
------------------------------------------------------------

-- Smart Cargo Van (VAN) - 5 units
;WITH v_nums AS (
    SELECT 1 AS n
    UNION ALL SELECT n+1 FROM v_nums WHERE n < 5
)
INSERT INTO dbo.Equipment (
    EquipmentCode,
    EquipmentDescription,
    EquipmentValue,
    EquipmentCategory,
    EquipmentType,
    EquipmentTrackingId,
    EquipmentAvailability
)
SELECT
    'EQ-VAN-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Smart cargo van unit ' + CAST(n AS NVARCHAR(10)) +
    ' with integrated equipment racks, in-van control console, 360° cameras, and live link to all mounted sensors, drones, and ghosting tools.',
    CAST(110000 + (n-1)*2000 AS DECIMAL(12,2)),
    'Vehicles',
    'Smart Cargo Van',
    'TRK-VAN-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Available'
FROM v_nums
OPTION (MAXRECURSION 0);
GO

-- Surveillance SUV (SUV) - 5 units
;WITH v_nums AS (
    SELECT 1 AS n
    UNION ALL SELECT n+1 FROM v_nums WHERE n < 5
)
INSERT INTO dbo.Equipment (
    EquipmentCode,
    EquipmentDescription,
    EquipmentValue,
    EquipmentCategory,
    EquipmentType,
    EquipmentTrackingId,
    EquipmentAvailability
)
SELECT
    'EQ-SUV-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Surveillance SUV unit ' + CAST(n AS NVARCHAR(10)) +
    ' with rooftop sensor dome, thermal/optical masts, and a cabin console synced to cameras, drones, and containment units.',
    CAST(100000 + (n-1)*2000 AS DECIMAL(12,2)),
    'Vehicles',
    'Surveillance SUV',
    'TRK-SUV-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Available'
FROM v_nums
OPTION (MAXRECURSION 0);
GO

-- Mobile Command Truck (MCT) - 5 units
;WITH v_nums AS (
    SELECT 1 AS n
    UNION ALL SELECT n+1 FROM v_nums WHERE n < 5
)
INSERT INTO dbo.Equipment (
    EquipmentCode,
    EquipmentDescription,
    EquipmentValue,
    EquipmentCategory,
    EquipmentType,
    EquipmentTrackingId,
    EquipmentAvailability
)
SELECT
    'EQ-MCT-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Mobile command truck unit ' + CAST(n AS NVARCHAR(10)) +
    ' acting as rolling HQ with multi-screen ops wall, satellite uplink, and central control over all field electronics and vehicles.',
    CAST(130000 + (n-1)*2000 AS DECIMAL(12,2)),
    'Vehicles',
    'Mobile Command Truck',
    'TRK-MCT-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Available'
FROM v_nums
OPTION (MAXRECURSION 0);
GO

------------------------------------------------------------
-- GHOSTING TOOLS
------------------------------------------------------------

-- Proton Pack Mk IV (24 units)
;WITH g_nums AS (
    SELECT 1 AS n
    UNION ALL SELECT n+1 FROM g_nums WHERE n < 24
)
INSERT INTO dbo.Equipment (
    EquipmentCode, EquipmentDescription, EquipmentValue,
    EquipmentCategory, EquipmentType, EquipmentTrackingId, EquipmentAvailability
)
SELECT
    'EQ-PPK-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Proton Pack Mk IV unit ' + CAST(n AS NVARCHAR(10)) +
    ' with stabilized stream emitter, adjustable output channels, and automatic logging into the central spectral containment registry.',
    CAST(90000 + (n-1)*1000 AS DECIMAL(12,2)),
    'Ghosting Tools',
    'Proton Pack Mk IV',
    'TRK-PPK-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Available'
FROM g_nums
OPTION (MAXRECURSION 0);
GO

-- Remote Ghost Trap (23 units)
;WITH g_nums AS (
    SELECT 1 AS n
    UNION ALL SELECT n+1 FROM g_nums WHERE n < 23
)
INSERT INTO dbo.Equipment (
    EquipmentCode, EquipmentDescription, EquipmentValue,
    EquipmentCategory, EquipmentType, EquipmentTrackingId, EquipmentAvailability
)
SELECT
    'EQ-GTR-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Remote ghost trap unit ' + CAST(n AS NVARCHAR(10)) +
    ' with wireless arming, proximity triggers, and auto-reporting back to vans when a capture is detected.',
    CAST(50000 + (n-1)*500 AS DECIMAL(12,2)),
    'Ghosting Tools',
    'Remote Ghost Trap',
    'TRK-GTR-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Available'
FROM g_nums
OPTION (MAXRECURSION 0);
GO

-- PKE Meter v3 (23 units)
;WITH g_nums AS (
    SELECT 1 AS n
    UNION ALL SELECT n+1 FROM g_nums WHERE n < 23
)
INSERT INTO dbo.Equipment (
    EquipmentCode, EquipmentDescription, EquipmentValue,
    EquipmentCategory, EquipmentType, EquipmentTrackingId, EquipmentAvailability
)
SELECT
    'EQ-PKE-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'PKE Meter v3 unit ' + CAST(n AS NVARCHAR(10)) +
    ' with expanded spectral range, haptic feedback, and live mapping to tablets and vehicle dashboards.',
    CAST(40000 + (n-1)*400 AS DECIMAL(12,2)),
    'Ghosting Tools',
    'PKE Meter v3',
    'TRK-PKE-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Available'
FROM g_nums
OPTION (MAXRECURSION 0);
GO

-- Spectral Containment Backpack (23 units)
;WITH g_nums AS (
    SELECT 1 AS n
    UNION ALL SELECT n+1 FROM g_nums WHERE n < 23
)
INSERT INTO dbo.Equipment (
    EquipmentCode, EquipmentDescription, EquipmentValue,
    EquipmentCategory, EquipmentType, EquipmentTrackingId, EquipmentAvailability
)
SELECT
    'EQ-SCB-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Spectral containment backpack unit ' + CAST(n AS NVARCHAR(10)) +
    ' designed for temporary field storage with secure uplink to stationary containment units.',
    CAST(60000 + (n-1)*700 AS DECIMAL(12,2)),
    'Ghosting Tools',
    'Spectral Containment Backpack',
    'TRK-SCB-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Available'
FROM g_nums
OPTION (MAXRECURSION 0);
GO

------------------------------------------------------------
-- CONTAINERS & STORAGE
------------------------------------------------------------

-- Stationary Containment Unit (24 units)
;WITH c_nums AS (
    SELECT 1 AS n
    UNION ALL SELECT n+1 FROM c_nums WHERE n < 24
)
INSERT INTO dbo.Equipment (
    EquipmentCode, EquipmentDescription, EquipmentValue,
    EquipmentCategory, EquipmentType, EquipmentTrackingId, EquipmentAvailability
)
SELECT
    'EQ-CTU-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Stationary containment unit ' + CAST(n AS NVARCHAR(10)) +
    ' with multi-chamber storage, redundant power, and constant health reporting to HQ servers and command trucks.',
    CAST(60000 + (n-1)*800 AS DECIMAL(12,2)),
    'Containers & Storage',
    'Stationary Containment Unit',
    'TRK-CTU-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Available'
FROM c_nums
OPTION (MAXRECURSION 0);
GO

-- Shielded Storage Crate (23 units)
;WITH c_nums AS (
    SELECT 1 AS n
    UNION ALL SELECT n+1 FROM c_nums WHERE n < 23
)
INSERT INTO dbo.Equipment (
    EquipmentCode, EquipmentDescription, EquipmentValue,
    EquipmentCategory, EquipmentType, EquipmentTrackingId, EquipmentAvailability
)
SELECT
    'EQ-CRT-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Shielded storage crate unit ' + CAST(n AS NVARCHAR(10)) +
    ' for transporting cursed or high-EMF objects, grounded and tracked by the fleet monitoring system.',
    CAST(20000 + (n-1)*500 AS DECIMAL(12,2)),
    'Containers & Storage',
    'Shielded Storage Crate',
    'TRK-CRT-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Available'
FROM c_nums
OPTION (MAXRECURSION 0);
GO

-- Portable Locker (23 units)
;WITH c_nums AS (
    SELECT 1 AS n
    UNION ALL SELECT n+1 FROM c_nums WHERE n < 23
)
INSERT INTO dbo.Equipment (
    EquipmentCode, EquipmentDescription, EquipmentValue,
    EquipmentCategory, EquipmentType, EquipmentTrackingId, EquipmentAvailability
)
SELECT
    'EQ-LKR-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Portable locker unit ' + CAST(n AS NVARCHAR(10)) +
    ' used for staging gear at jobsites, with RFID access control and status updates to smart cargo vans.',
    CAST(8000 + (n-1)*300 AS DECIMAL(12,2)),
    'Containers & Storage',
    'Portable Locker',
    'TRK-LKR-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Available'
FROM c_nums
OPTION (MAXRECURSION 0);
GO

------------------------------------------------------------
-- ELECTRONICS & IMAGING
-- (CAM, BOD, DRN, SEN, VCT - each 23 units)
------------------------------------------------------------

-- 8K Cinema Camera Rig (CAM)
;WITH e_nums AS (
    SELECT 1 AS n
    UNION ALL SELECT n+1 FROM e_nums WHERE n < 23
)
INSERT INTO dbo.Equipment (
    EquipmentCode, EquipmentDescription, EquipmentValue,
    EquipmentCategory, EquipmentType, EquipmentTrackingId, EquipmentAvailability
)
SELECT
    'EQ-CAM-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    '8K cinema camera rig unit ' + CAST(n AS NVARCHAR(10)) +
    ' with low-light sensor, gyro-stabilized mount, and encrypted video feed to command trucks and cargo vans.',
    CAST(15000 + (n-1)*600 AS DECIMAL(12,2)),
    'Electronics & Imaging',
    '8K Cinema Camera Rig',
    'TRK-CAM-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Available'
FROM e_nums
OPTION (MAXRECURSION 0);
GO

-- Low-Light Body Camera (BOD)
;WITH e_nums AS (
    SELECT 1 AS n
    UNION ALL SELECT n+1 FROM e_nums WHERE n < 23
)
INSERT INTO dbo.Equipment (
    EquipmentCode, EquipmentDescription, EquipmentValue,
    EquipmentCategory, EquipmentType, EquipmentTrackingId, EquipmentAvailability
)
SELECT
    'EQ-BOD-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Low-light body camera unit ' + CAST(n AS NVARCHAR(10)) +
    ' worn on PPE harness, streaming encrypted POV footage back to nearby vehicles and the HQ archive.',
    CAST(4000 + (n-1)*200 AS DECIMAL(12,2)),
    'Electronics & Imaging',
    'Low-Light Body Camera',
    'TRK-BOD-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Available'
FROM e_nums
OPTION (MAXRECURSION 0);
GO

-- Thermal Imaging Drone (DRN)
;WITH e_nums AS (
    SELECT 1 AS n
    UNION ALL SELECT n+1 FROM e_nums WHERE n < 23
)
INSERT INTO dbo.Equipment (
    EquipmentCode, EquipmentDescription, EquipmentValue,
    EquipmentCategory, EquipmentType, EquipmentTrackingId, EquipmentAvailability
)
SELECT
    'EQ-DRN-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Thermal imaging drone unit ' + CAST(n AS NVARCHAR(10)) +
    ' with obstacle avoidance, spectral-spectrum tuning, and one-touch docking to Ghostbusters vehicles.',
    CAST(20000 + (n-1)*800 AS DECIMAL(12,2)),
    'Electronics & Imaging',
    'Thermal Imaging Drone',
    'TRK-DRN-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Available'
FROM e_nums
OPTION (MAXRECURSION 0);
GO

-- Environmental Sensor Array (SEN)
;WITH e_nums AS (
    SELECT 1 AS n
    UNION ALL SELECT n+1 FROM e_nums WHERE n < 23
)
INSERT INTO dbo.Equipment (
    EquipmentCode, EquipmentDescription, EquipmentValue,
    EquipmentCategory, EquipmentType, EquipmentTrackingId, EquipmentAvailability
)
SELECT
    'EQ-SEN-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Environmental sensor array unit ' + CAST(n AS NVARCHAR(10)) +
    ' that samples EMF, temperature, and air composition, streaming live data to the fleet network and command trucks.',
    CAST(9000 + (n-1)*400 AS DECIMAL(12,2)),
    'Electronics & Imaging',
    'Environmental Sensor Array',
    'TRK-SEN-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Available'
FROM e_nums
OPTION (MAXRECURSION 0);
GO

-- Vehicle Control Tablet (VCT)
;WITH e_nums AS (
    SELECT 1 AS n
    UNION ALL SELECT n+1 FROM e_nums WHERE n < 23
)
INSERT INTO dbo.Equipment (
    EquipmentCode, EquipmentDescription, EquipmentValue,
    EquipmentCategory, EquipmentType, EquipmentTrackingId, EquipmentAvailability
)
SELECT
    'EQ-VCT-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Vehicle control tablet unit ' + CAST(n AS NVARCHAR(10)) +
    ' that can arm traps, view live camera and drone feeds, and adjust vehicle systems from inside the van or on foot.',
    CAST(3000 + (n-1)*150 AS DECIMAL(12,2)),
    'Electronics & Imaging',
    'Vehicle Control Tablet',
    'TRK-VCT-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Available'
FROM e_nums
OPTION (MAXRECURSION 0);
GO

------------------------------------------------------------
-- PPE & WEARABLES (HZM, RSP, HLM - each 23 units)
------------------------------------------------------------

-- Class-IV Hazmat Suit
;WITH p_nums AS (
    SELECT 1 AS n
    UNION ALL SELECT n+1 FROM p_nums WHERE n < 23
)
INSERT INTO dbo.Equipment (
    EquipmentCode, EquipmentDescription, EquipmentValue,
    EquipmentCategory, EquipmentType, EquipmentTrackingId, EquipmentAvailability
)
SELECT
    'EQ-HZM-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Class-IV hazmat suit unit ' + CAST(n AS NVARCHAR(10)) +
    ' with sealed respirator, biometric monitoring, and suit-telemetry upload to the nearest command vehicle.',
    CAST(2500 + (n-1)*100 AS DECIMAL(12,2)),
    'PPE & Wearables',
    'Class-IV Hazmat Suit',
    'TRK-HZM-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Available'
FROM p_nums
OPTION (MAXRECURSION 0);
GO

-- Multi-Stage Respirator
;WITH p_nums AS (
    SELECT 1 AS n
    UNION ALL SELECT n+1 FROM p_nums WHERE n < 23
)
INSERT INTO dbo.Equipment (
    EquipmentCode, EquipmentDescription, EquipmentValue,
    EquipmentCategory, EquipmentType, EquipmentTrackingId, EquipmentAvailability
)
SELECT
    'EQ-RSP-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Multi-stage respirator unit ' + CAST(n AS NVARCHAR(10)) +
    ' with changeable spectral filters and connectivity to suit and vehicle monitoring systems.',
    CAST(500 + (n-1)*50 AS DECIMAL(12,2)),
    'PPE & Wearables',
    'Multi-Stage Respirator',
    'TRK-RSP-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Available'
FROM p_nums
OPTION (MAXRECURSION 0);
GO

-- Smart Safety Helmet
;WITH p_nums AS (
    SELECT 1 AS n
    UNION ALL SELECT n+1 FROM p_nums WHERE n < 23
)
INSERT INTO dbo.Equipment (
    EquipmentCode, EquipmentDescription, EquipmentValue,
    EquipmentCategory, EquipmentType, EquipmentTrackingId, EquipmentAvailability
)
SELECT
    'EQ-HLM-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Smart safety helmet unit ' + CAST(n AS NVARCHAR(10)) +
    ' with HUD visor, comms headset, and link to vehicle navigation and sensor overlays.',
    CAST(800 + (n-1)*80 AS DECIMAL(12,2)),
    'PPE & Wearables',
    'Smart Safety Helmet',
    'TRK-HLM-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Available'
FROM p_nums
OPTION (MAXRECURSION 0);
GO

------------------------------------------------------------
-- POWER & ENERGY SYSTEMS (PFC, HBR - 23 units each)
------------------------------------------------------------

-- Portable Fusion Power Cell
;WITH pow_nums AS (
    SELECT 1 AS n
    UNION ALL SELECT n+1 FROM pow_nums WHERE n < 23
)
INSERT INTO dbo.Equipment (
    EquipmentCode, EquipmentDescription, EquipmentValue,
    EquipmentCategory, EquipmentType, EquipmentTrackingId, EquipmentAvailability
)
SELECT
    'EQ-PFC-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Portable fusion power cell unit ' + CAST(n AS NVARCHAR(10)) +
    ' used to power traps, sensor arrays, and container systems during remote operations.',
    CAST(15000 + (n-1)*500 AS DECIMAL(12,2)),
    'Power & Energy Systems',
    'Portable Fusion Power Cell',
    'TRK-PFC-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Available'
FROM pow_nums
OPTION (MAXRECURSION 0);
GO

-- High-Capacity Battery Rack
;WITH pow_nums AS (
    SELECT 1 AS n
    UNION ALL SELECT n+1 FROM pow_nums WHERE n < 23
)
INSERT INTO dbo.Equipment (
    EquipmentCode, EquipmentDescription, EquipmentValue,
    EquipmentCategory, EquipmentType, EquipmentTrackingId, EquipmentAvailability
)
SELECT
    'EQ-HBR-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'High-capacity battery rack unit ' + CAST(n AS NVARCHAR(10)) +
    ' designed to mount in trailers or containers, providing buffered power to all connected electronics.',
    CAST(8000 + (n-1)*400 AS DECIMAL(12,2)),
    'Power & Energy Systems',
    'High-Capacity Battery Rack',
    'TRK-HBR-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Available'
FROM pow_nums
OPTION (MAXRECURSION 0);
GO

------------------------------------------------------------
-- NETWORKING & COMMUNICATIONS (FMR, CRB - 23 each)
------------------------------------------------------------

-- Field Mesh Router Node
;WITH n_nums AS (
    SELECT 1 AS n
    UNION ALL SELECT n+1 FROM n_nums WHERE n < 23
)
INSERT INTO dbo.Equipment (
    EquipmentCode, EquipmentDescription, EquipmentValue,
    EquipmentCategory, EquipmentType, EquipmentTrackingId, EquipmentAvailability
)
SELECT
    'EQ-FMR-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Field mesh router node unit ' + CAST(n AS NVARCHAR(10)) +
    ' that forms an auto-configuring wireless mesh network around a job site, linking back to command vehicles.',
    CAST(4000 + (n-1)*300 AS DECIMAL(12,2)),
    'Networking & Communications',
    'Field Mesh Router Node',
    'TRK-FMR-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Available'
FROM n_nums
OPTION (MAXRECURSION 0);
GO

-- Command Radio Base Station
;WITH n_nums AS (
    SELECT 1 AS n
    UNION ALL SELECT n+1 FROM n_nums WHERE n < 23
)
INSERT INTO dbo.Equipment (
    EquipmentCode, EquipmentDescription, EquipmentValue,
    EquipmentCategory, EquipmentType, EquipmentTrackingId, EquipmentAvailability
)
SELECT
    'EQ-CRB-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Command radio base station unit ' + CAST(n AS NVARCHAR(10)) +
    ' mounted in vehicles or containers, coordinating field team comms and linking to HQ.',
    CAST(8000 + (n-1)*500 AS DECIMAL(12,2)),
    'Networking & Communications',
    'Command Radio Base Station',
    'TRK-CRB-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Available'
FROM n_nums
OPTION (MAXRECURSION 0);
GO

------------------------------------------------------------
-- FIELD SUPPORT TOOLS (MSK, TIP - 23 each)
------------------------------------------------------------

-- Multi-Tool Service Kit
;WITH f_nums AS (
    SELECT 1 AS n
    UNION ALL SELECT n+1 FROM f_nums WHERE n < 23
)
INSERT INTO dbo.Equipment (
    EquipmentCode, EquipmentDescription, EquipmentValue,
    EquipmentCategory, EquipmentType, EquipmentTrackingId, EquipmentAvailability
)
SELECT
    'EQ-MSK-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Multi-tool service kit unit ' + CAST(n AS NVARCHAR(10)) +
    ' with precision tools for repairing ghosting gear, vehicle-mounted electronics, and container hardware on-site.',
    CAST(3000 + (n-1)*200 AS DECIMAL(12,2)),
    'Field Support Tools',
    'Multi-Tool Service Kit',
    'TRK-MSK-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Available'
FROM f_nums
OPTION (MAXRECURSION 0);
GO

-- Telescopic Inspection Pole
;WITH f_nums AS (
    SELECT 1 AS n
    UNION ALL SELECT n+1 FROM f_nums WHERE n < 23
)
INSERT INTO dbo.Equipment (
    EquipmentCode, EquipmentDescription, EquipmentValue,
    EquipmentCategory, EquipmentType, EquipmentTrackingId, EquipmentAvailability
)
SELECT
    'EQ-TIP-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Telescopic inspection pole unit ' + CAST(n AS NVARCHAR(10)) +
    ' with camera-equipped head for inspecting vents, crawlspaces, and ceiling voids, streaming video to vehicles and tablets.',
    CAST(1500 + (n-1)*150 AS DECIMAL(12,2)),
    'Field Support Tools',
    'Telescopic Inspection Pole',
    'TRK-TIP-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'Available'
FROM f_nums
OPTION (MAXRECURSION 0);
GO

------------------------------------------------------------
-- 4. STANDARDIZE VALUE & DESCRIPTION (PER TYPE)
-- (This enforces same value & same description for each type)
------------------------------------------------------------

-- Vehicles
UPDATE dbo.Equipment
SET EquipmentValue = 115000,
    EquipmentDescription = 'High-tech cargo van with integrated sensor systems and onboard control console.'
WHERE EquipmentType = 'Smart Cargo Van';

UPDATE dbo.Equipment
SET EquipmentValue = 108000,
    EquipmentDescription = 'Reconnaissance SUV equipped with thermal, optical, and remote monitoring systems.'
WHERE EquipmentType = 'Surveillance SUV';

UPDATE dbo.Equipment
SET EquipmentValue = 135000,
    EquipmentDescription = 'Mobile operations hub with full fleet integration and multi-channel controls.'
WHERE EquipmentType = 'Mobile Command Truck';

-- Ghosting Tools
UPDATE dbo.Equipment
SET EquipmentValue = 95000,
    EquipmentDescription = 'Energy-based containment device used for spectral neutralization operations.'
WHERE EquipmentType = 'Proton Pack Mk IV';

UPDATE dbo.Equipment
SET EquipmentValue = 55000,
    EquipmentDescription = 'Wireless trap unit for remote spectral capture with auto-reporting.'
WHERE EquipmentType = 'Remote Ghost Trap';

UPDATE dbo.Equipment
SET EquipmentValue = 45000,
    EquipmentDescription = 'Environmental scanner for detecting and analyzing paranormal energy signatures.'
WHERE EquipmentType = 'PKE Meter v3';

UPDATE dbo.Equipment
SET EquipmentValue = 70000,
    EquipmentDescription = 'Portable containment system for temporary field storage of spectral entities.'
WHERE EquipmentType = 'Spectral Containment Backpack';

-- Containers & Storage
UPDATE dbo.Equipment
SET EquipmentValue = 70000,
    EquipmentDescription = 'Multi-chamber storage system for secure spectral containment.'
WHERE EquipmentType = 'Stationary Containment Unit';

UPDATE dbo.Equipment
SET EquipmentValue = 30000,
    EquipmentDescription = 'Reinforced crate designed for transporting hazardous paranormal objects.'
WHERE EquipmentType = 'Shielded Storage Crate';

UPDATE dbo.Equipment
SET EquipmentValue = 12000,
    EquipmentDescription = 'RFID-secured locker for staging and storing equipment on site.'
WHERE EquipmentType = 'Portable Locker';

-- Electronics & Imaging
UPDATE dbo.Equipment
SET EquipmentValue = 25000,
    EquipmentDescription = 'High-resolution camera system with low-light and gyro-stabilized imaging.'
WHERE EquipmentType = '8K Cinema Camera Rig';

UPDATE dbo.Equipment
SET EquipmentValue = 6000,
    EquipmentDescription = 'Body-mounted camera optimized for low-light field operations.'
WHERE EquipmentType = 'Low-Light Body Camera';

UPDATE dbo.Equipment
SET EquipmentValue = 35000,
    EquipmentDescription = 'Autonomous drone with thermal and spectral imaging capabilities.'
WHERE EquipmentType = 'Thermal Imaging Drone';

UPDATE dbo.Equipment
SET EquipmentValue = 16000,
    EquipmentDescription = 'Multi-sensor platform for real-time monitoring of EMF and environmental shifts.'
WHERE EquipmentType = 'Environmental Sensor Array';

UPDATE dbo.Equipment
SET EquipmentValue = 5500,
    EquipmentDescription = 'Wireless control tablet linked to vehicles and equipment management systems.'
WHERE EquipmentType = 'Vehicle Control Tablet';

-- PPE & Wearables
UPDATE dbo.Equipment
SET EquipmentValue = 3500,
    EquipmentDescription = 'Full-protection hazmat suit with integrated biometric and environmental sensors.'
WHERE EquipmentType = 'Class-IV Hazmat Suit';

UPDATE dbo.Equipment
SET EquipmentValue = 800,
    EquipmentDescription = 'Advanced respirator with multi-stage filtration for hazardous environments.'
WHERE EquipmentType = 'Multi-Stage Respirator';

UPDATE dbo.Equipment
SET EquipmentValue = 1500,
    EquipmentDescription = 'Helmet with integrated HUD, comms, and proximity alerting system.'
WHERE EquipmentType = 'Smart Safety Helmet';

-- Power & Energy
UPDATE dbo.Equipment
SET EquipmentValue = 22000,
    EquipmentDescription = 'High-density portable power supply for field equipment support.'
WHERE EquipmentType = 'Portable Fusion Power Cell';

UPDATE dbo.Equipment
SET EquipmentValue = 12000,
    EquipmentDescription = 'Battery rack providing stable and redundant power for connected systems.'
WHERE EquipmentType = 'High-Capacity Battery Rack';

-- Networking & Comms
UPDATE dbo.Equipment
SET EquipmentValue = 9500,
    EquipmentDescription = 'Mesh-network node providing on-site communication coverage.'
WHERE EquipmentType = 'Field Mesh Router Node';

UPDATE dbo.Equipment
SET EquipmentValue = 14000,
    EquipmentDescription = 'Base station enabling multi-channel team communications and fleet coordination.'
WHERE EquipmentType = 'Command Radio Base Station';

-- Field Support
UPDATE dbo.Equipment
SET EquipmentValue = 4500,
    EquipmentDescription = 'Technical kit containing precision tools for equipment maintenance and repair.'
WHERE EquipmentType = 'Multi-Tool Service Kit';

UPDATE dbo.Equipment
SET EquipmentValue = 3000,
    EquipmentDescription = 'Extendable inspection tool with integrated camera for confined spaces.'
WHERE EquipmentType = 'Telescopic Inspection Pole';
GO
------------------------------------------------------------
-- PHASE 3 - RENTALS, RENTED-EQUIPMENT, MAINTENANCE, AVAILABILITY
------------------------------------------------------------

USE [GhostbustersFleet];
GO

------------------------------------------------------------
-- 1. RENTAL SEED (150 rows for 2025)
------------------------------------------------------------
DELETE FROM dbo.RentedEquipment;
DELETE FROM dbo.Maintenance;
DELETE FROM dbo.Rental;
GO

DECLARE @CustomerCount INT;
SELECT @CustomerCount = COUNT(*) FROM dbo.Customer;

IF @CustomerCount = 0
BEGIN
    RAISERROR('No customers found. Seed Customer table before seeding Rental.', 16, 1);
    RETURN;
END;

IF OBJECT_ID('tempdb..#CustomersWithRow') IS NOT NULL
    DROP TABLE #CustomersWithRow;

SELECT 
    CustomerId,
    CustomerName,
    ROW_NUMBER() OVER (ORDER BY CustomerName) AS rn
INTO #CustomersWithRow
FROM dbo.Customer;

------------------------------------------------------------
-- 1.1 CLOSED RENTALS (100) – Jan–Oct 2025
------------------------------------------------------------
;WITH nums AS (
    SELECT 1 AS n
    UNION ALL SELECT n+1 FROM nums WHERE n < 100
)
INSERT INTO dbo.Rental (CustomerId, StartDate, EndDate, [Status], [Note], [Scope])
SELECT
    c.CustomerId,
    DATEADD(DAY, ((n - 1) % 270), CAST('2025-01-01' AS DATE)),
    DATEADD(DAY, 2 + ((n - 1) % 7),
             DATEADD(DAY, ((n - 1) % 270), CAST('2025-01-01' AS DATE))),
    'Closed',
    'Closed rental ' + CAST(n AS NVARCHAR(10)) + ' (normal completion, maintenance closed as Working).',
    CASE WHEN c.CustomerName = 'Ghostbusting Team' THEN 'Internal' ELSE 'External' END
FROM nums
JOIN #CustomersWithRow c
  ON ((n - 1) % @CustomerCount) + 1 = c.rn
OPTION (MAXRECURSION 0);

------------------------------------------------------------
-- 1.2 RESERVED RENTALS (15) – Dec 2025
------------------------------------------------------------
;WITH nums AS (
    SELECT 1 AS n
    UNION ALL SELECT n+1 FROM nums WHERE n < 15
)
INSERT INTO dbo.Rental (CustomerId, StartDate, EndDate, [Status], [Note], [Scope])
SELECT
    c.CustomerId,
    DATEADD(DAY, (n - 1) * 2, CAST('2025-12-01' AS DATE)),
    DATEADD(DAY, 3 + ((n - 1) % 5),
             DATEADD(DAY, (n - 1) * 2, CAST('2025-12-01' AS DATE))),
    'Reserved',
    'Reserved rental ' + CAST(n AS NVARCHAR(10)) + ' (future December 2025 booking).',
    CASE WHEN c.CustomerName = 'Ghostbusting Team' THEN 'Internal' ELSE 'External' END
FROM nums
JOIN #CustomersWithRow c
  ON ((n - 1) % @CustomerCount) + 1 = c.rn
OPTION (MAXRECURSION 0);

------------------------------------------------------------
-- 1.3 CHECKEDOUT RENTALS (20) – Nov 2025
------------------------------------------------------------
;WITH nums AS (
    SELECT 1 AS n
    UNION ALL SELECT n+1 FROM nums WHERE n < 20
)
INSERT INTO dbo.Rental (CustomerId, StartDate, EndDate, [Status], [Note], [Scope])
SELECT
    c.CustomerId,
    DATEADD(DAY, (n - 1), CAST('2025-11-05' AS DATE)),
    DATEADD(DAY, 5 + (n % 5),
             DATEADD(DAY, (n - 1), CAST('2025-11-05' AS DATE))),
    'CheckedOut',
    'Checked-out rental ' + CAST(n AS NVARCHAR(10)) + ' (customer currently in possession).',
    CASE WHEN c.CustomerName = 'Ghostbusting Team' THEN 'Internal' ELSE 'External' END
FROM nums
JOIN #CustomersWithRow c
  ON ((n - 1) % @CustomerCount) + 1 = c.rn
OPTION (MAXRECURSION 0);

------------------------------------------------------------
-- 1.4 RETURNED RENTALS (10) – Nov 2025
------------------------------------------------------------
;WITH nums AS (
    SELECT 1 AS n
    UNION ALL SELECT n+1 FROM nums WHERE n < 10
)
INSERT INTO dbo.Rental (CustomerId, StartDate, EndDate, [Status], [Note], [Scope])
SELECT
    c.CustomerId,
    DATEADD(DAY, (n - 1), CAST('2025-11-01' AS DATE)),
    DATEADD(DAY, 3 + ((n - 1) % 3),
             DATEADD(DAY, (n - 1), CAST('2025-11-01' AS DATE))),
    'Returned',
    'Returned rental ' + CAST(n AS NVARCHAR(10)) + ' (equipment awaiting or undergoing maintenance).',
    CASE WHEN c.CustomerName = 'Ghostbusting Team' THEN 'Internal' ELSE 'External' END
FROM nums
JOIN #CustomersWithRow c
  ON ((n - 1) % @CustomerCount) + 1 = c.rn
OPTION (MAXRECURSION 0);

------------------------------------------------------------
-- 1.5 OVERDUE RENTALS (5) – mid-year damage cases
------------------------------------------------------------
;WITH nums AS (
    SELECT 1 AS n
    UNION ALL SELECT n+1 FROM nums WHERE n < 5
)
INSERT INTO dbo.Rental (CustomerId, StartDate, EndDate, [Status], [Note], [Scope])
SELECT
    c.CustomerId,
    DATEADD(DAY, (n - 1) * 14, CAST('2025-06-01' AS DATE)),
    DATEADD(DAY, 7 + ((n - 1) % 4),
             DATEADD(DAY, (n - 1) * 14, CAST('2025-06-01' AS DATE))),
    'Overdue',
    'Overdue rental ' + CAST(n AS NVARCHAR(10)) + ' (to be associated with Damaged maintenance outcome).',
    CASE WHEN c.CustomerName = 'Ghostbusting Team' THEN 'Internal' ELSE 'External' END
FROM nums
JOIN #CustomersWithRow c
  ON ((n - 1) % @CustomerCount) + 1 = c.rn
OPTION (MAXRECURSION 0);
GO

------------------------------------------------------------
-- 2. RENTED-EQUIPMENT: 3–6 items per rental
------------------------------------------------------------
DELETE FROM dbo.RentedEquipment;
GO

DECLARE @EquipmentCount INT;
SELECT @EquipmentCount = COUNT(*) FROM dbo.Equipment;

IF @EquipmentCount = 0
BEGIN
    RAISERROR('No equipment found. Seed Equipment table before seeding RentedEquipment.', 16, 1);
    RETURN;
END;

;WITH RentalRows AS (
    SELECT 
        RentalId,
        ROW_NUMBER() OVER (ORDER BY StartDate, RentalId) AS r_n
    FROM dbo.Rental
),
EquipRows AS (
    SELECT 
        EquipmentId,
        ROW_NUMBER() OVER (ORDER BY EquipmentCode) AS e_n
    FROM dbo.Equipment
),
Nums AS (
    SELECT 1 AS n
    UNION ALL SELECT n+1 FROM Nums WHERE n < 6   -- 1..6
),
RentalWithCount AS (
    SELECT 
        r.RentalId,
        r.r_n,
        CASE (r.r_n % 4)
            WHEN 1 THEN 3
            WHEN 2 THEN 4
            WHEN 3 THEN 5
            ELSE 6
        END AS EquipPerRental
    FROM RentalRows r
)
INSERT INTO dbo.RentedEquipment (RentalId, EquipmentId)
SELECT
    rw.RentalId,
    e.EquipmentId
FROM RentalWithCount rw
JOIN Nums n
    ON n.n <= rw.EquipPerRental
JOIN EquipRows e
    ON e.e_n = ((rw.r_n - 1) * 4 + n.n - 1) % @EquipmentCount + 1
OPTION (MAXRECURSION 0);
GO

------------------------------------------------------------
-- 3. MAINTENANCE SEED – 1 row per equipment
------------------------------------------------------------

DELETE FROM dbo.Maintenance;
GO

;WITH EquipRental AS (
    SELECT
        E.EquipmentId,
        E.EquipmentCode,
        R.RentalId,
        R.[Status]    AS RentalStatus,
        R.StartDate   AS RentalStartDate,
        R.EndDate     AS RentalEndDate,
        ROW_NUMBER() OVER (
            PARTITION BY E.EquipmentId
            ORDER BY 
                R.EndDate DESC,
                R.StartDate DESC,
                R.RentalId DESC
        ) AS rn
    FROM dbo.Equipment E
    LEFT JOIN dbo.RentedEquipment RE
        ON RE.EquipmentId = E.EquipmentId
    LEFT JOIN dbo.Rental R
        ON R.RentalId = RE.RentalId
),
LatestRentalPerEquipment AS (
    SELECT
        EquipmentId,
        EquipmentCode,
        RentalId,
        RentalStatus,
        RentalStartDate,
        RentalEndDate
    FROM EquipRental
    WHERE rn = 1
),
-- Extract TypeCode from EquipmentCode: EQ-XXX-### -> XXX
EquipWithType AS (
    SELECT
        EquipmentId,
        EquipmentCode,
        RentalId,
        RentalStatus,
        RentalStartDate,
        RentalEndDate,
        SUBSTRING(
            EquipmentCode,
            4,
            CHARINDEX('-', EquipmentCode + '-', 4) - 4
        ) AS TypeCode
    FROM LatestRentalPerEquipment
),
NumberedByType AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY EquipmentCode) AS Seq,
        ROW_NUMBER() OVER (PARTITION BY TypeCode ORDER BY EquipmentCode) AS SeqInType,
        EquipmentId,
        EquipmentCode,
        TypeCode,
        RentalId,
        RentalStatus,
        RentalStartDate,
        RentalEndDate
    FROM EquipWithType
)
INSERT INTO dbo.Maintenance (
    MaintenanceId,
    MaintenanceCode,
    EquipmentId,
    RentalId,
    LastServiceDate,
    [Status],
    OpenDate,
    CloseDate,
    Outcome,
    Technician,
    Notes
)
SELECT
    NEWID() AS MaintenanceId,

    -- MT-[TypeCode]-xxx
    'MT-' + ne.TypeCode + '-' + RIGHT('000' + CAST(ne.SeqInType AS VARCHAR(3)), 3) AS MaintenanceCode,

    ne.EquipmentId,
    ne.RentalId,

    -- LastServiceDate (DATE)
    CAST(
        CASE 
            WHEN ne.RentalStatus IN ('Closed','Overdue') AND ne.RentalEndDate IS NOT NULL
                 THEN DATEADD(DAY, 1, ne.RentalEndDate)
            WHEN ne.RentalStatus = 'Returned' AND ne.RentalEndDate IS NOT NULL
                 THEN ne.RentalEndDate
            WHEN ne.RentalStatus IN ('CheckedOut','Reserved') AND ne.RentalStartDate IS NOT NULL
                 THEN DATEADD(DAY, -3, ne.RentalStartDate)
            ELSE '2024-12-15'
        END
        AS DATE
    ) AS LastServiceDate,

    -- Maintenance.Status
    CASE 
        WHEN ne.RentalStatus = 'Returned' THEN 'Open'
        WHEN ne.RentalStatus = 'Overdue'  THEN 'Closed'
        ELSE 'Closed'
    END AS [Status],

    -- OpenDate (DATE)
    CAST(
        CASE 
            WHEN ne.RentalStatus = 'Returned' AND ne.RentalEndDate IS NOT NULL
                 THEN ne.RentalEndDate
            WHEN ne.RentalStatus = 'Overdue' AND ne.RentalEndDate IS NOT NULL
                 THEN DATEADD(DAY, 1, ne.RentalEndDate)
            WHEN ne.RentalStatus IS NULL
                 THEN CAST('2024-12-10' AS DATE)
            ELSE
                 ISNULL(
                     DATEADD(DAY, -2, ne.RentalStartDate),
                     CAST('2024-12-10' AS DATE)
                 )
        END
        AS DATE
    ) AS OpenDate,

    -- CloseDate (DATE)
    CAST(
        CASE 
            WHEN ne.RentalStatus = 'Returned' THEN NULL
            WHEN ne.RentalStatus = 'Overdue' AND ne.RentalEndDate IS NOT NULL
                 THEN DATEADD(DAY, 3, ne.RentalEndDate)
            WHEN ne.RentalStatus IN ('Closed','CheckedOut','Reserved') AND ne.RentalEndDate IS NOT NULL
                 THEN DATEADD(DAY, 1, ne.RentalEndDate)
            WHEN ne.RentalStatus IS NULL
                 THEN CAST('2024-12-15' AS DATE)
            ELSE NULL
        END
        AS DATE
    ) AS CloseDate,

    -- Outcome (never NULL)
    CASE 
        WHEN ne.RentalStatus = 'Overdue' THEN 'Damaged'
        ELSE 'Working'
    END AS Outcome,

    -- Technician: NULL for Open, else 5 realistic names
    CASE 
        WHEN ne.RentalStatus = 'Returned' THEN NULL
        ELSE
            CASE ((ne.Seq - 1) % 5)
                WHEN 0 THEN 'Alex Carter'
                WHEN 1 THEN 'Priya Nair'
                WHEN 2 THEN 'Miguel Santos'
                WHEN 3 THEN 'Jordan Lee'
                ELSE      'Emma Novak'
            END
    END AS Technician,

    -- Notes: NULL for Open, descriptive text for closed
    CASE 
        WHEN ne.RentalStatus = 'Returned'
            THEN NULL
        WHEN ne.RentalStatus = 'Overdue'
            THEN 'Inspection complete; equipment marked as damaged from overdue rental.'
        WHEN ne.RentalStatus = 'Closed'
            THEN 'Routine post-rental check completed; equipment cleared for service.'
        WHEN ne.RentalStatus IN ('CheckedOut','Reserved')
            THEN 'Last maintenance completed prior to current or upcoming rental.'
        ELSE
            'Baseline inspection completed before first deployment.'
    END AS Notes
FROM NumberedByType ne;
GO

------------------------------------------------------------
-- 4. EQUIPMENT AVAILABILITY SYNC
-- Rules:
--   If latest Maintenance.Outcome = Damaged -> Damaged
--   Else if latest Rental.Status = Returned -> UnderMaintenance
--   Else if latest Rental.Status = CheckedOut -> OutForRental
--   Else if latest Rental.Status = Reserved -> Unavailable
--   Else -> Available
------------------------------------------------------------

;WITH LatestRental AS (
    SELECT
        e.EquipmentId,
        r.RentalId,
        r.[Status]       AS RentalStatus,
        r.StartDate      AS RentalStartDate,
        r.EndDate        AS RentalEndDate,
        ROW_NUMBER() OVER (
            PARTITION BY e.EquipmentId
            ORDER BY 
                r.EndDate DESC,
                r.StartDate DESC,
                r.RentalId DESC
        ) AS rn
    FROM dbo.Equipment e
    LEFT JOIN dbo.RentedEquipment re
        ON re.EquipmentId = e.EquipmentId
    LEFT JOIN dbo.Rental r
        ON r.RentalId = re.RentalId
),
LatestRentalPerEquipment AS (
    SELECT
        EquipmentId,
        RentalId,
        RentalStatus,
        RentalStartDate,
        RentalEndDate
    FROM LatestRental
    WHERE rn = 1
),
LatestMaintenance AS (
    SELECT
        m.EquipmentId,
        m.RentalId,
        m.Outcome       AS MaintenanceOutcome,
        m.[Status]      AS MaintenanceStatus,
        ROW_NUMBER() OVER (
            PARTITION BY m.EquipmentId
            ORDER BY 
                m.OpenDate DESC,
                m.CloseDate DESC,
                m.MaintenanceId DESC
        ) AS rn
    FROM dbo.Maintenance m
),
LatestMaintenancePerEquipment AS (
    SELECT
        EquipmentId,
        RentalId,
        MaintenanceOutcome,
        MaintenanceStatus
    FROM LatestMaintenance
    WHERE rn = 1
)
UPDATE e
SET EquipmentAvailability =
    CASE
        WHEN lm.MaintenanceOutcome = 'Damaged' THEN 'Damaged'
        WHEN lr.RentalStatus = 'Returned'      THEN 'UnderMaintenance'
        WHEN lr.RentalStatus = 'CheckedOut'    THEN 'OutForRental'
        WHEN lr.RentalStatus = 'Reserved'      THEN 'Unavailable'
        ELSE 'Available'
    END
FROM dbo.Equipment e
LEFT JOIN LatestRentalPerEquipment lr
    ON lr.EquipmentId = e.EquipmentId
LEFT JOIN LatestMaintenancePerEquipment lm
    ON lm.EquipmentId = e.EquipmentId;
GO

------------------------------------------------------------
-- OPTIONAL: sanity checks
------------------------------------------------------------

-- Availability distribution
SELECT EquipmentAvailability, COUNT(*) AS Cnt
FROM dbo.Equipment
GROUP BY EquipmentAvailability
ORDER BY EquipmentAvailability;

-- Rental status distribution
SELECT [Status], COUNT(*) AS Cnt
FROM dbo.Rental
GROUP BY [Status]
ORDER BY [Status];

-- Maintenance outcome vs status
SELECT Outcome, [Status], COUNT(*) AS Cnt
FROM dbo.Maintenance
GROUP BY Outcome, [Status]
ORDER BY Outcome, [Status];
GO

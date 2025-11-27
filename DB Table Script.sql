------------------------------------------------------------
-- GHOSTBUSTERS FLEET – CORE TABLES REBUILD (NEW REQUIREMENTS)
-- Targets: SQL Server / (localdb)\MSSQLLocalDB
------------------------------------------------------------
USE [GhostbustersFleet];
GO

------------------------------------------------------------
-- 1. DROP TABLES (CHILD → PARENT) + OLD VEHICLE/MAINTENANCEEVENT
------------------------------------------------------------
IF OBJECT_ID('dbo.Maintenance', 'U') IS NOT NULL
    DROP TABLE dbo.Maintenance;

IF OBJECT_ID('dbo.MaintenanceEvent', 'U') IS NOT NULL
    DROP TABLE dbo.MaintenanceEvent;   -- legacy name, just in case

IF OBJECT_ID('dbo.RentedEquipment', 'U') IS NOT NULL
    DROP TABLE dbo.RentedEquipment;

IF OBJECT_ID('dbo.Rental', 'U') IS NOT NULL
    DROP TABLE dbo.Rental;

IF OBJECT_ID('dbo.Vehicle', 'U') IS NOT NULL
    DROP TABLE dbo.Vehicle;            -- dropped per new requirement

IF OBJECT_ID('dbo.Equipment', 'U') IS NOT NULL
    DROP TABLE dbo.Equipment;

IF OBJECT_ID('dbo.Customer', 'U') IS NOT NULL
    DROP TABLE dbo.Customer;

IF OBJECT_ID('dbo.Employee', 'U') IS NOT NULL
    DROP TABLE dbo.Employee;
GO

------------------------------------------------------------
-- 2. DROP / RECREATE SEQUENCES FOR BUSINESS CODES
------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sys.sequences WHERE name = 'Seq_CustomerCode')
    DROP SEQUENCE Seq_CustomerCode;

IF EXISTS (SELECT 1 FROM sys.sequences WHERE name = 'Seq_RentalCode')
    DROP SEQUENCE Seq_RentalCode;

IF EXISTS (SELECT 1 FROM sys.sequences WHERE name = 'Seq_MaintenanceCode')
    DROP SEQUENCE Seq_MaintenanceCode;
GO

-- CustomerCode: CT-001, CT-002, ... (3 digits)
CREATE SEQUENCE Seq_CustomerCode AS INT
    START WITH 1 INCREMENT BY 1;

-- RentalCode: RT-0001, RT-0002, ... (4 digits)
CREATE SEQUENCE Seq_RentalCode AS INT
    START WITH 1 INCREMENT BY 1;

-- Maintenance numeric part; the app can still compose "MT-[TYPE]-xxxx"
CREATE SEQUENCE Seq_MaintenanceCode AS INT
    START WITH 1 INCREMENT BY 1;
GO

------------------------------------------------------------
-- 3. EMPLOYEE (unchanged, this table is "perfect")
------------------------------------------------------------
CREATE TABLE dbo.Employee
(
    EmployeeId UNIQUEIDENTIFIER NOT NULL
        CONSTRAINT DF_Employee_EmployeeId DEFAULT (NEWID()),

    [Name]     NVARCHAR(100)   NOT NULL,
    Username   NVARCHAR(50)    NOT NULL,
    [Password] NVARCHAR(200)   NOT NULL,

    CONSTRAINT PK_Employee PRIMARY KEY (EmployeeId),
    CONSTRAINT UQ_Employee_Username UNIQUE (Username)
);
GO

------------------------------------------------------------
-- 4. CUSTOMER
--   CustomerCode: CT-001 style, auto from Seq_CustomerCode
--   Username / Password OPTIONAL (null allowed)
------------------------------------------------------------
CREATE TABLE dbo.Customer
(
    CustomerId      UNIQUEIDENTIFIER NOT NULL
        CONSTRAINT DF_Customer_CustomerId DEFAULT (NEWID()),

    CustomerCode    VARCHAR(32) NOT NULL
        CONSTRAINT DF_Customer_CustomerCode
            DEFAULT (
                'CT-' + RIGHT('000' + CAST(NEXT VALUE FOR Seq_CustomerCode AS VARCHAR(3)), 3)
            ),

    CustomerName    NVARCHAR(200) NOT NULL,
    CustomerAddress NVARCHAR(MAX) NULL,
    CustomerGovtId  NVARCHAR(100) NULL,
    CustomerEmail   NVARCHAR(200) NULL,
    CustomerPhone   NVARCHAR(50)  NULL,

    -- Login credentials (optional)
    Username        NVARCHAR(50)  NULL,
    [Password]      NVARCHAR(200) NULL,

    CONSTRAINT PK_Customer PRIMARY KEY (CustomerId),
    CONSTRAINT UQ_Customer_Code UNIQUE (CustomerCode)
);
GO

-- Lookups by phone are common
CREATE INDEX IX_Customer_Phone ON dbo.Customer(CustomerPhone);

-- Optional: ensure usernames (when present) are unique
CREATE UNIQUE INDEX UQ_Customer_Username
    ON dbo.Customer(Username)
    WHERE Username IS NOT NULL;
GO

------------------------------------------------------------
-- 5. EQUIPMENT
--   EquipmentAvailability will be controlled by rental & maintenance logic:
--     Available / Unavailable / OutForRental / UnderMaintenance / Damaged
------------------------------------------------------------
CREATE TABLE dbo.Equipment
(
    EquipmentId           UNIQUEIDENTIFIER NOT NULL
        CONSTRAINT DF_Equipment_EquipmentId DEFAULT (NEWID()),

    EquipmentCode         VARCHAR(32)   NOT NULL,     -- e.g. EQP-CAM-001 (app-generated)
    EquipmentName         NVARCHAR(200) NOT NULL,
    EquipmentDescription  NVARCHAR(MAX) NULL,
    EquipmentValue        DECIMAL(12,2) NOT NULL,     -- >= 0 (enforced at app or via CHECK)
    EquipmentCategory     NVARCHAR(50)  NOT NULL,     -- e.g. Vehicle, PPE, Tools
    EquipmentType         NVARCHAR(50)  NOT NULL,     -- e.g. Camera, Van, Proton Pack
    EquipmentTrackingId   NVARCHAR(100) NULL,         -- optional, unique when present
    EquipmentAvailability NVARCHAR(30)  NOT NULL      -- see mapping rules

    CONSTRAINT PK_Equipment PRIMARY KEY (EquipmentId)
);
GO

CREATE UNIQUE INDEX UQ_Equipment_EquipmentCode
    ON dbo.Equipment(EquipmentCode);

CREATE UNIQUE INDEX UQ_Equipment_TrackingId
    ON dbo.Equipment(EquipmentTrackingId)
    WHERE EquipmentTrackingId IS NOT NULL;
GO

------------------------------------------------------------
-- 6. RENTAL
--   RentalCode: RT-0001 style, auto from Seq_RentalCode
--   Status: Draft / Reserved / CheckedOut / Returned / Overdue / Closed
------------------------------------------------------------
CREATE TABLE dbo.Rental
(
    RentalId   UNIQUEIDENTIFIER NOT NULL
        CONSTRAINT DF_Rental_RentalId DEFAULT (NEWID()),

    RentalCode VARCHAR(32) NOT NULL
        CONSTRAINT DF_Rental_RentalCode
            DEFAULT ('RT-' + RIGHT('0000' + CAST(NEXT VALUE FOR Seq_RentalCode AS VARCHAR(4)), 4)),

    CustomerId UNIQUEIDENTIFIER NULL,          -- nullable for internal scope
    StartDate  DATE            NOT NULL,
    EndDate    DATE            NOT NULL,
    [Status]   NVARCHAR(20)    NOT NULL,       -- see CHECK below
    [Note]     NVARCHAR(MAX)   NULL,
    [Scope]    NVARCHAR(20)    NULL,          -- e.g. 'Internal' / 'External'

    CONSTRAINT PK_Rental PRIMARY KEY (RentalId),

    CONSTRAINT FK_Rental_Customer
        FOREIGN KEY (CustomerId)
        REFERENCES dbo.Customer(CustomerId),

    -- EndDate must be at or after StartDate
    CONSTRAINT CK_Rental_Dates CHECK (EndDate >= StartDate),

    -- Allowed statuses, including Overdue
    CONSTRAINT CK_Rental_Status CHECK (
        [Status] IN (
            'Draft',
            'Reserved',
            'CheckedOut',
            'Returned',
            'Overdue',
            'Closed'
        )
    )
);
GO

------------------------------------------------------------
-- 7. RENTEDEQUIPMENT
--   Pure bridge table: (RentalId, EquipmentId)
--   All pricing will be handled elsewhere/UI (per new requirement).
------------------------------------------------------------
CREATE TABLE dbo.RentedEquipment
(
    RentedEquipmentId UNIQUEIDENTIFIER NOT NULL
        CONSTRAINT DF_RentedEquipment_RentedEquipmentId DEFAULT (NEWID()),

    RentalId          UNIQUEIDENTIFIER NOT NULL,
    EquipmentId       UNIQUEIDENTIFIER NOT NULL,

    CONSTRAINT PK_RentedEquipment PRIMARY KEY (RentedEquipmentId),

    CONSTRAINT FK_RentedEquipment_Rental
        FOREIGN KEY (RentalId)
        REFERENCES dbo.Rental(RentalId),

    CONSTRAINT FK_RentedEquipment_Equipment
        FOREIGN KEY (EquipmentId)
        REFERENCES dbo.Equipment(EquipmentId)
);
GO

-- Optional: prevent the same equipment being added twice to the same rental
CREATE UNIQUE INDEX UQ_RentedEquipment_Rental_Equipment
    ON dbo.RentedEquipment(RentalId, EquipmentId);
GO

------------------------------------------------------------
-- 8. MAINTENANCE (renamed from MaintenanceEvent)
--   One *current* record per Equipment (enforced by unique index).
--   MaintenanceCode: MT-[TYPE]-xxxx should be composed by the app.
--   Status: Open / Closed
--   Outcome: Working / Damaged (set on close)
------------------------------------------------------------
CREATE TABLE dbo.Maintenance
(
    MaintenanceId    UNIQUEIDENTIFIER NOT NULL
        CONSTRAINT DF_Maintenance_MaintenanceId DEFAULT (NEWID()),

    MaintenanceCode  VARCHAR(32)  NOT NULL,     -- e.g. MT-CAM-0001 (app-built)
    EquipmentId      UNIQUEIDENTIFIER NOT NULL,
    RentalId         UNIQUEIDENTIFIER NULL,     -- last rental that triggered this maintenance

    LastServiceDate  DATE         NOT NULL,
    [Status]         NVARCHAR(20) NOT NULL,     -- Open / Closed
    OpenDate         DATETIME2(0) NOT NULL
        CONSTRAINT DF_Maintenance_OpenDate DEFAULT (SYSUTCDATETIME()),
    CloseDate        DATETIME2(0) NULL,

    Outcome          NVARCHAR(20) NULL,        -- Working / Damaged
    Technician       NVARCHAR(200) NULL,
    Notes            NVARCHAR(MAX) NULL,

    CONSTRAINT PK_Maintenance PRIMARY KEY (MaintenanceId),

    CONSTRAINT FK_Maintenance_Equipment
        FOREIGN KEY (EquipmentId)
        REFERENCES dbo.Equipment(EquipmentId),

    CONSTRAINT FK_Maintenance_Rental
        FOREIGN KEY (RentalId)
        REFERENCES dbo.Rental(RentalId),

    CONSTRAINT CK_Maintenance_Status CHECK (
        [Status] IN ('Open', 'Closed')
    ),

    CONSTRAINT CK_Maintenance_Outcome CHECK (
        Outcome IS NULL OR Outcome IN ('Working', 'Damaged')
    )
);
GO

-- Only ONE row per Equipment (latest record overwrites previous one)
CREATE UNIQUE INDEX UQ_Maintenance_Equipment
    ON dbo.Maintenance(EquipmentId);

-- MaintenanceCode should be unique across all equipment
CREATE UNIQUE INDEX UQ_Maintenance_Code
    ON dbo.Maintenance(MaintenanceCode);
GO

------------------------------------------------------------
-- NOTE
--  - No seed data is included here (we’ll design table-by-table population
--    once you send the workflow for each module).
--  - Code generation rules:
--      CustomerCode  = CT-001, CT-002, ...
--      RentalCode    = RT-0001, RT-0002, ...
--      Maintenance   = app composes MT-[TYPE]-xxxx using Seq_MaintenanceCode
------------------------------------------------------------

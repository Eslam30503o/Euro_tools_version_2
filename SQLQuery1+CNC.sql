CREATE DATABASE Warehouse;
GO

USE Warehouse;
GO
-------------------------Categories--------------------------------------------------------------
CREATE TABLE Categories (
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName NVARCHAR(50) NOT NULL
);
---------------------------Items------------------------------------------------------------
CREATE TABLE Items (
    ItemID INT IDENTITY(1,1) PRIMARY KEY,
    ItemCode NVARCHAR(100) UNIQUE NOT NULL, -- الباركود النهائي
    ItemName NVARCHAR(100) NOT NULL,        -- الاسم
    Description NVARCHAR(255),              -- الوصف
    CategoryID INT FOREIGN KEY REFERENCES Categories(CategoryID),
    Unit NVARCHAR(20),                      -- الوحدة (قطعة، مجموعة…)
    ReorderLevel INT DEFAULT 0,             -- الحد الأدنى للتنبيه
    CurrentStock INT DEFAULT 0,             -- الكمية الحالية
    CreatedAt DATETIME DEFAULT GETDATE()
);
-------------------------ToolAttributes--------------------------------------------------------------
CREATE TABLE ToolAttributes (
    ToolAttrID INT IDENTITY(1,1) PRIMARY KEY,
    ItemID INT FOREIGN KEY REFERENCES Items(ItemID) ON DELETE CASCADE,
    ToolType NVARCHAR(20) NOT NULL,  -- نوع الأداة (Endmill, Drill, Reamer…)
    
    Diameter DECIMAL(10,2) NULL,     -- Φ
    Radius DECIMAL(10,2) NULL,       -- R
    Length DECIMAL(10,2) NULL,       -- L
    Hardness DECIMAL(10,2) NULL,     -- H
    Pitch DECIMAL(10,2) NULL,        -- P (للـ Thread)
    Source CHAR(1) NULL CHECK (Source IN ('I','O')), -- محلي أو مستورد
    Material NVARCHAR(50) NULL       -- Carbide للـ Reamer
);
------------------------------Users---------------------------------------------------------
CREATE TABLE Users (
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    Username NVARCHAR(50) NOT NULL UNIQUE,
    Password NVARCHAR(255) NOT NULL,
    Role NVARCHAR(20) NOT NULL CHECK (Role IN ('Admin','Manager','Supervisor','User')),
    CreatedAt DATETIME DEFAULT GETDATE()
);
--------------------------Transactions-------------------------------------------------------------
CREATE TABLE Transactions (
    TransactionID INT IDENTITY(1,1) PRIMARY KEY,
    ItemID INT NOT NULL FOREIGN KEY REFERENCES Items(ItemID),
    UserID INT NOT NULL FOREIGN KEY REFERENCES Users(UserID),
    Action NVARCHAR(50) NOT NULL,         -- نوع العملية (Add, Remove, Update …)
    QuantityChange INT NOT NULL,          -- الكمية اللي اتغيرت (+ أو -)
    Timestamp DATETIME DEFAULT GETDATE()  -- وقت العملية
);
-----------------------Stored Procedure----------------------------------------------------------------
CREATE PROCEDURE sp_UpdateQuantity
    @UserID INT,               -- مين اللي عمل العملية
    @ItemID INT,               -- الأداة اللي بتتعدل
    @Action NVARCHAR(50),      -- Add أو Remove
    @QuantityChange INT        -- الكمية المضافة أو المصروفة
AS
BEGIN
    SET NOCOUNT ON;

    -- 1️⃣ تحديث الكمية في Items
    IF @Action = 'Add'
        UPDATE Items
        SET CurrentStock = CurrentStock + @QuantityChange
        WHERE ItemID = @ItemID;

    ELSE IF @Action = 'Remove'
    BEGIN
        -- نتأكد إن الكمية كافية قبل ما نصرف
        IF (SELECT CurrentStock FROM Items WHERE ItemID = @ItemID) >= @QuantityChange
            UPDATE Items
            SET CurrentStock = CurrentStock - @QuantityChange
            WHERE ItemID = @ItemID;
        ELSE
            THROW 50000, 'Not enough stock. Transaction cancelled.', 1;
    END

    -- 2️⃣ تسجيل العملية في Transactions
    INSERT INTO Transactions (UserID, ItemID, Action, QuantityChange, Timestamp)
    VALUES (@UserID, @ItemID, @Action, @QuantityChange, GETDATE());
END;
GO
----------------------Stored Procedure لإضافة Item-----------------------------------------------------------------
CREATE PROCEDURE sp_AddNewItem
    @ItemCode NVARCHAR(100),
    @ItemName NVARCHAR(100),
    @Description NVARCHAR(255) = NULL,
    @CategoryID INT,
    @Unit NVARCHAR(20),
    @ReorderLevel INT = 0,
    @InitialStock INT = 0
AS
BEGIN
    SET NOCOUNT ON;

    -- التحقق إن الكود مش مكرر
    IF EXISTS (SELECT 1 FROM Items WHERE ItemCode = @ItemCode)
    BEGIN
        RAISERROR('ItemCode already exists. Please use a unique code.', 16, 1);
        RETURN;
    END;

    -- إدخال العنصر الجديد
    INSERT INTO Items (ItemCode, ItemName, Description, CategoryID, Unit, ReorderLevel, CurrentStock)
    VALUES (@ItemCode, @ItemName, @Description, @CategoryID, @Unit, @ReorderLevel, @InitialStock);

    PRINT 'New item has been added successfully.';
END;
GO
-----------------------------------------------------------------------------------------------------------
ALTER TABLE ToolAttributes
ADD 
    MaterialType NVARCHAR(50) NULL,
    LocalOrImported CHAR(1) NULL;
------------------------- Stored Procedure لإضافة Item مع ToolAttributes:--------------------------------------------------------------
CREATE PROCEDURE sp_AddToolItem
    @ItemCode NVARCHAR(100),
    @ItemName NVARCHAR(100),
    @Description NVARCHAR(255) = NULL,
    @CategoryID INT,
    @Unit NVARCHAR(20),
    @ReorderLevel INT = 0,
    @CurrentStock INT = 0,
    @Diameter DECIMAL(10,2) = NULL,
    @Radius DECIMAL(10,2) = NULL,
    @Length DECIMAL(10,2) = NULL,
    @Hardness INT = NULL,
    @Pitch DECIMAL(10,2) = NULL,
    @MaterialType NVARCHAR(50) = NULL,
    @LocalOrImported CHAR(1) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- إضافة الـ Item في جدول Items
    INSERT INTO Items (ItemCode, ItemName, Description, CategoryID, Unit, ReorderLevel, CurrentStock)
    VALUES (@ItemCode, @ItemName, @Description, @CategoryID, @Unit, @ReorderLevel, @CurrentStock);

    DECLARE @NewItemID INT = SCOPE_IDENTITY();

    -- إضافة الخصائص في جدول ToolAttributes
    INSERT INTO ToolAttributes (ItemID, Diameter, Radius, Length, Hardness, Pitch, MaterialType, LocalOrImported)
    VALUES (@NewItemID, @Diameter, @Radius, @Length, @Hardness, @Pitch, @MaterialType, @LocalOrImported);
END;
GO
---------------------------------------------------------------------------------------
ALTER PROCEDURE sp_AddToolItem
    @ItemCode NVARCHAR(100),
    @ItemName NVARCHAR(100),
    @Description NVARCHAR(255) = NULL,
    @CategoryID INT,
    @Unit NVARCHAR(20),
    @ReorderLevel INT = 0,
    @InitialStock INT = 0,
    -- ToolAttributes
    @Diameter DECIMAL(10,2) = NULL,
    @Radius DECIMAL(10,2) = NULL,
    @Length DECIMAL(10,2) = NULL,
    @Hardness DECIMAL(10,2) = NULL,
    @Pitch DECIMAL(10,2) = NULL,
    @MaterialType NVARCHAR(50) = NULL,
    @LocalOrImported CHAR(1) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- ✅ تحقق من تكرار الكود
    IF EXISTS (SELECT 1 FROM Items WHERE ItemCode = @ItemCode)
    BEGIN
        RAISERROR('ItemCode already exists. Please use a unique code.', 16, 1);
        RETURN;
    END;

    -- ✅ تحقق من الحقول المطلوبة حسب نوع الأداة
    IF @ItemName = 'Endmill'
    BEGIN
        IF @Diameter IS NULL OR @Length IS NULL OR @Hardness IS NULL OR @LocalOrImported IS NULL
        BEGIN
            RAISERROR('Endmill requires Diameter, Length, Hardness, and LocalOrImported.', 16, 1);
            RETURN;
        END
    END
    ELSE IF @ItemName = 'Ballwill'
    BEGIN
        IF @Diameter IS NULL OR @Length IS NULL OR @Hardness IS NULL OR @LocalOrImported IS NULL
        BEGIN
            RAISERROR('Ballwill requires Diameter, Length, Hardness, and LocalOrImported.', 16, 1);
            RETURN;
        END
    END
    ELSE IF @ItemName = 'Drill'
    BEGIN
        IF @Diameter IS NULL OR @Length IS NULL OR @Hardness IS NULL OR @LocalOrImported IS NULL
        BEGIN
            RAISERROR('Drill requires Diameter, Length, Hardness, and LocalOrImported.', 16, 1);
            RETURN;
        END
    END
    ELSE IF @ItemName = 'Thread'
    BEGIN
        IF @Diameter IS NULL OR @Pitch IS NULL OR @Length IS NULL OR @LocalOrImported IS NULL
        BEGIN
            RAISERROR('Thread requires Diameter, Pitch, Length, and LocalOrImported.', 16, 1);
            RETURN;
        END
    END
    ELSE IF @ItemName = 'Reamer'
    BEGIN
        IF @Radius IS NULL OR @MaterialType IS NULL
        BEGIN
            RAISERROR('Reamer requires Radius and MaterialType (e.g., Carbide).', 16, 1);
            RETURN;
        END
    END
    ELSE IF @ItemName = 'Inserts'
    BEGIN
        IF @Radius IS NULL
        BEGIN
            RAISERROR('Inserts require Radius (must be 2, 3.5, or 5).', 16, 1);
            RETURN;
        END
    END
    ELSE IF @ItemName = 'Shells'
    BEGIN
        IF @Diameter IS NULL OR @Radius IS NULL
        BEGIN
            RAISERROR('Shells require Diameter and Radius.', 16, 1);
            RETURN;
        END
        IF @Diameter = 15 AND @Length IS NULL
        BEGIN
            RAISERROR('Shells with Diameter = 15 require Length.', 16, 1);
            RETURN;
        END
    END

    -- ✅ إضافة الـ Item
    INSERT INTO Items (ItemCode, ItemName, Description, CategoryID, Unit, ReorderLevel, CurrentStock)
    VALUES (@ItemCode, @ItemName, @Description, @CategoryID, @Unit, @ReorderLevel, @InitialStock);

    DECLARE @NewItemID INT = SCOPE_IDENTITY();

    -- ✅ إضافة ToolAttributes
    INSERT INTO ToolAttributes (ItemID, Diameter, Radius, Length, Hardness, Pitch, MaterialType, LocalOrImported)
    VALUES (@NewItemID, @Diameter, @Radius, @Length, @Hardness, @Pitch, @MaterialType, @LocalOrImported);

    PRINT 'Tool item with attributes has been added successfully.';
END;
GO
---------------------------------------------------------------------------------------
ALTER TABLE ToolAttributes
ADD 
    MaterialType NVARCHAR(50) NULL,     -- Carbide أو غيره
    LocalOrImported CHAR(1) NULL CHECK (LocalOrImported IN ('I', 'O')); -- I = محلي, O = مستورد
---------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_AddToolItem
    @ItemCode NVARCHAR(100),
    @ItemName NVARCHAR(100),
    @Description NVARCHAR(255),
    @CategoryID INT,
    @Unit NVARCHAR(20),
    @ReorderLevel INT = 0,
    @CurrentStock INT = 0,
    @MaterialType NVARCHAR(50) = NULL,
    @Radius DECIMAL(5,2) = NULL,
    @Length DECIMAL(10,2) = NULL,
    @LocalOrImported NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- ✅ إدخال الـ Item الأساسي
        INSERT INTO Items (ItemCode, ItemName, Description, CategoryID, Unit, ReorderLevel, CurrentStock)
        VALUES (@ItemCode, @ItemName, @Description, @CategoryID, @Unit, @ReorderLevel, @CurrentStock);

        DECLARE @NewItemID INT = SCOPE_IDENTITY();

        -- ✅ تحقق ذكي على القواعد الخاصة بالـ Inserts
        IF @ItemName = N'Inserts'
        BEGIN
            IF @Radius IS NULL OR @Radius NOT IN (2, 3.5, 5)
            BEGIN
                RAISERROR(N'Invalid Radius for Inserts. Allowed values: 2, 3.5, 5.', 16, 1);
                ROLLBACK TRANSACTION;
                RETURN;
            END
        END

        -- ✅ إدخال الخصائص في ToolAttributes
        INSERT INTO ToolAttributes (ItemID, MaterialType, Radius, Length,  LocalOrImported)
        VALUES (@NewItemID, @MaterialType, @Radius, @Length,  @LocalOrImported);

        COMMIT TRANSACTION;
        PRINT N'Item and ToolAttributes added successfully.';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO
----------------------------sp_AddToolItem-----------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_AddToolItem
    @ItemCode NVARCHAR(100),
    @ItemName NVARCHAR(100),
    @Description NVARCHAR(255),
    @CategoryID INT,
    @Unit NVARCHAR(20),
    @ReorderLevel INT = 0,
    @CurrentStock INT = 0,
    -- Tool Attributes
    @Diameter DECIMAL(10,2) = NULL,
    @Radius DECIMAL(10,2) = NULL,
    @Length DECIMAL(10,2) = NULL,
    @Hardness DECIMAL(10,2) = NULL,
    @Pitch DECIMAL(10,2) = NULL,
    @MaterialType NVARCHAR(50) = NULL,
    @LocalOrImported CHAR(1) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF EXISTS (SELECT 1 FROM Items WHERE ItemCode = @ItemCode)
        BEGIN
            RAISERROR(N'ItemCode already exists.', 16, 1);
            RETURN;
        END

        -- Validations by tool type
        IF @ItemName = 'Endmill' OR @ItemName = 'Drill' OR @ItemName = 'Ballwill'
        BEGIN
            IF @Diameter IS NULL OR @Length IS NULL OR @Hardness IS NULL OR @LocalOrImported IS NULL
            BEGIN
                RAISERROR(N'Missing attributes for %s', 16, 1, @ItemName);
                RETURN;
            END
        END
        ELSE IF @ItemName = 'Thread'
        BEGIN
            IF @Diameter IS NULL OR @Pitch IS NULL OR @Length IS NULL OR @LocalOrImported IS NULL
            BEGIN
                RAISERROR(N'Thread requires Diameter, Pitch, Length, LocalOrImported.', 16, 1);
                RETURN;
            END
        END
        ELSE IF @ItemName = 'Reamer'
        BEGIN
            IF @Radius IS NULL OR @MaterialType IS NULL
            BEGIN
                RAISERROR(N'Reamer requires Radius and MaterialType.', 16, 1);
                RETURN;
            END
        END
        ELSE IF @ItemName = 'Inserts'
        BEGIN
            IF @Radius NOT IN (2, 3.5, 5)
            BEGIN
                RAISERROR(N'Inserts require Radius = 2, 3.5, or 5.', 16, 1);
                RETURN;
            END
        END
        ELSE IF @ItemName = 'Shells'
        BEGIN
            IF @Diameter IS NULL OR @Radius IS NULL
            BEGIN
                RAISERROR(N'Shells require Diameter and Radius.', 16, 1);
                RETURN;
            END
            IF @Diameter = 15 AND @Length IS NULL
            BEGIN
                RAISERROR(N'Shells with Diameter 15 require Length.', 16, 1);
                RETURN;
            END
        END

        INSERT INTO Items (ItemCode, ItemName, Description, CategoryID, Unit, ReorderLevel, CurrentStock)
        VALUES (@ItemCode, @ItemName, @Description, @CategoryID, @Unit, @ReorderLevel, @CurrentStock);

        DECLARE @ItemID INT = SCOPE_IDENTITY();

        INSERT INTO ToolAttributes (ItemID, Diameter, Radius, Length, Hardness, Pitch, MaterialType, LocalOrImported)
        VALUES (@ItemID, @Diameter, @Radius, @Length, @Hardness, @Pitch, @MaterialType, @LocalOrImported);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
-------------------------Tool Item (sp_GetToolItem)--------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_GetToolItem
    @ItemID INT
AS
BEGIN
    SELECT i.*, t.*
    FROM Items i
    LEFT JOIN ToolAttributes t ON i.ItemID = t.ItemID
    WHERE i.ItemID = @ItemID;
END;
-------------------------Tool Item (sp_UpdateToolItem)--------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_UpdateToolItem
    @ItemID INT,
    @ItemCode NVARCHAR(100),
    @ItemName NVARCHAR(100),
    @Description NVARCHAR(255),
    @CategoryID INT,
    @Unit NVARCHAR(20),
    @ReorderLevel INT,
    @CurrentStock INT,
    @Diameter DECIMAL(10,2) = NULL,
    @Radius DECIMAL(10,2) = NULL,
    @Length DECIMAL(10,2) = NULL,
    @Hardness DECIMAL(10,2) = NULL,
    @Pitch DECIMAL(10,2) = NULL,
    @MaterialType NVARCHAR(50) = NULL,
    @LocalOrImported CHAR(1) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE Items
        SET ItemCode = @ItemCode,
            ItemName = @ItemName,
            Description = @Description,
            CategoryID = @CategoryID,
            Unit = @Unit,
            ReorderLevel = @ReorderLevel,
            CurrentStock = @CurrentStock
        WHERE ItemID = @ItemID;

        UPDATE ToolAttributes
        SET Diameter = @Diameter,
            Radius = @Radius,
            Length = @Length,
            Hardness = @Hardness,
            Pitch = @Pitch,
            MaterialType = @MaterialType,
            LocalOrImported = @LocalOrImported
        WHERE ItemID = @ItemID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
-------------------------Tool Item (sp_DeleteToolItem)--------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_DeleteToolItem
    @ItemID INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM ToolAttributes WHERE ItemID = @ItemID;
        DELETE FROM Items WHERE ItemID = @ItemID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
----------------------------------------------------------------------------------------------------------------
ALTER PROCEDURE sp_AddToolItem
    @UserID INT,  -- 🆕 المستخدم اللي بينفذ العملية
    @ItemCode NVARCHAR(100),
    @ItemName NVARCHAR(100),
    @Description NVARCHAR(255) = NULL,
    @CategoryID INT,
    @Unit NVARCHAR(20),
    @ReorderLevel INT = 0,
    @InitialStock INT = 0,
    -- ToolAttributes
    @Diameter DECIMAL(10,2) = NULL,
    @Radius DECIMAL(10,2) = NULL,
    @Length DECIMAL(10,2) = NULL,
    @Hardness DECIMAL(10,2) = NULL,
    @Pitch DECIMAL(10,2) = NULL,
    @MaterialType NVARCHAR(50) = NULL,
    @LocalOrImported CHAR(1) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- 🔐 التحقق من صلاحيات المستخدم
    DECLARE @UserRole NVARCHAR(20);
    SELECT @UserRole = Role FROM Users WHERE UserID = @UserID;

    IF @UserRole NOT IN ('Admin', 'Manager')
    BEGIN
        RAISERROR('⛔ غير مسموح لك بإضافة أدوات. الصلاحية مطلوبة: Admin أو Manager', 16, 1);
        RETURN;
    END;

    -- ✅ تحقق من تكرار الكود
    IF EXISTS (SELECT 1 FROM Items WHERE ItemCode = @ItemCode)
    BEGIN
        RAISERROR('ItemCode already exists. Please use a unique code.', 16, 1);
        RETURN;
    END;

    -- ✅ تحقق من الحقول المطلوبة حسب نوع الأداة
    IF @ItemName = 'Endmill'
    BEGIN
        IF @Diameter IS NULL OR @Length IS NULL OR @Hardness IS NULL OR @LocalOrImported IS NULL
        BEGIN
            RAISERROR('Endmill requires Diameter, Length, Hardness, and LocalOrImported.', 16, 1);
            RETURN;
        END
    END
    ELSE IF @ItemName = 'Ballwill'
    BEGIN
        IF @Diameter IS NULL OR @Length IS NULL OR @Hardness IS NULL OR @LocalOrImported IS NULL
        BEGIN
            RAISERROR('Ballwill requires Diameter, Length, Hardness, and LocalOrImported.', 16, 1);
            RETURN;
        END
    END
    ELSE IF @ItemName = 'Drill'
    BEGIN
        IF @Diameter IS NULL OR @Length IS NULL OR @Hardness IS NULL OR @LocalOrImported IS NULL
        BEGIN
            RAISERROR('Drill requires Diameter, Length, Hardness, and LocalOrImported.', 16, 1);
            RETURN;
        END
    END
    ELSE IF @ItemName = 'Thread'
    BEGIN
        IF @Diameter IS NULL OR @Pitch IS NULL OR @Length IS NULL OR @LocalOrImported IS NULL
        BEGIN
            RAISERROR('Thread requires Diameter, Pitch, Length, and LocalOrImported.', 16, 1);
            RETURN;
        END
    END
    ELSE IF @ItemName = 'Reamer'
    BEGIN
        IF @Radius IS NULL OR @MaterialType IS NULL
        BEGIN
            RAISERROR('Reamer requires Radius and MaterialType (e.g., Carbide).', 16, 1);
            RETURN;
        END
    END
    ELSE IF @ItemName = 'Inserts'
    BEGIN
        IF @Radius IS NULL
        BEGIN
            RAISERROR('Inserts require Radius (must be 2, 3.5, or 5).', 16, 1);
            RETURN;
        END
    END
    ELSE IF @ItemName = 'Shells'
    BEGIN
        IF @Diameter IS NULL OR @Radius IS NULL
        BEGIN
            RAISERROR('Shells require Diameter and Radius.', 16, 1);
            RETURN;
        END
        IF @Diameter = 15 AND @Length IS NULL
        BEGIN
            RAISERROR('Shells with Diameter = 15 require Length.', 16, 1);
            RETURN;
        END
    END

    -- ✅ إدراج الأداة
    INSERT INTO Items (ItemCode, ItemName, Description, CategoryID, Unit, ReorderLevel, CurrentStock)
    VALUES (@ItemCode, @ItemName, @Description, @CategoryID, @Unit, @ReorderLevel, @InitialStock);

    DECLARE @NewItemID INT = SCOPE_IDENTITY();

    -- ✅ إدراج الخصائص
    INSERT INTO ToolAttributes (ItemID, Diameter, Radius, Length, Hardness, Pitch, MaterialType, LocalOrImported)
    VALUES (@NewItemID, @Diameter, @Radius, @Length, @Hardness, @Pitch, @MaterialType, @LocalOrImported);

    PRINT '✅ Tool item has been added successfully.';
END
GO
----------------------------------------------------------------------------------------------------------------
ALTER PROCEDURE sp_UpdateToolItem
    @UserID INT,  -- 🆕 المستخدم اللي بيعمل التعديل
    @ItemID INT,
    @ItemCode NVARCHAR(100),
    @ItemName NVARCHAR(100),
    @Description NVARCHAR(255) = NULL,
    @CategoryID INT,
    @Unit NVARCHAR(20),
    @ReorderLevel INT = 0,
    @CurrentStock INT = 0,
    -- ToolAttributes
    @Diameter DECIMAL(10,2) = NULL,
    @Radius DECIMAL(10,2) = NULL,
    @Length DECIMAL(10,2) = NULL,
    @Hardness DECIMAL(10,2) = NULL,
    @Pitch DECIMAL(10,2) = NULL,
    @MaterialType NVARCHAR(50) = NULL,
    @LocalOrImported CHAR(1) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- 🔐 تحقق من صلاحية المستخدم
    DECLARE @UserRole NVARCHAR(20);
    SELECT @UserRole = Role FROM Users WHERE UserID = @UserID;

    IF @UserRole NOT IN ('Admin', 'Manager', 'Supervisor')
    BEGIN
        RAISERROR('⛔ غير مسموح لك بتعديل الأدوات. الصلاحية مطلوبة: Admin أو Manager أو Supervisor.', 16, 1);
        RETURN;
    END;

    -- ✅ تحديث الجدول Items
    UPDATE Items
    SET
        ItemCode = @ItemCode,
        ItemName = @ItemName,
        Description = @Description,
        CategoryID = @CategoryID,
        Unit = @Unit,
        ReorderLevel = @ReorderLevel,
        CurrentStock = @CurrentStock,
        CreatedAt = GETDATE()
    WHERE ItemID = @ItemID;

    -- ✅ تحديث الخصائص في ToolAttributes
    UPDATE ToolAttributes
    SET
        Diameter = @Diameter,
        Radius = @Radius,
        Length = @Length,
        Hardness = @Hardness,
        Pitch = @Pitch,
        MaterialType = @MaterialType,
        LocalOrImported = @LocalOrImported
    WHERE ItemID = @ItemID;

    PRINT '✅ Tool item has been updated successfully.';
END
GO
----------------------------------------------------------------------------------------------------------------
ALTER PROCEDURE sp_DeleteToolItem
    @UserID INT,
    @ItemID INT
AS
BEGIN
    SET NOCOUNT ON;

    -- 🔐 جلب الصلاحية
    DECLARE @UserRole NVARCHAR(20);
    SELECT @UserRole = Role FROM Users WHERE UserID = @UserID;

    -- ❌ التحقق من الصلاحية
    IF @UserRole NOT IN ('Admin', 'Manager')
    BEGIN
        RAISERROR('⛔ غير مسموح لك بحذف الأدوات. الصلاحية مطلوبة: Admin أو Manager.', 16, 1);
        RETURN;
    END;

    -- ✅ حذف ToolAttributes أولاً (لو موجودة)
    DELETE FROM ToolAttributes WHERE ItemID = @ItemID;

    -- ✅ حذف من جدول Items
    DELETE FROM Items WHERE ItemID = @ItemID;

    PRINT '🗑️ Tool item has been deleted successfully.';
END
GO
----------------------------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_GetToolItem
    @UserID INT,
    @ItemID INT = NULL  -- لو عايز يجيب عنصر واحد أو كل العناصر
AS
BEGIN
    SET NOCOUNT ON;

    -- 🔐 صلاحية المستخدم
    DECLARE @UserRole NVARCHAR(20);
    SELECT @UserRole = Role FROM Users WHERE UserID = @UserID;

    IF @UserRole NOT IN ('Admin', 'Manager', 'Supervisor', 'User')
    BEGIN
        RAISERROR('⛔ لا تملك صلاحية عرض الأدوات.', 16, 1);
        RETURN;
    END;

    -- ✅ قراءة البيانات
    SELECT 
        I.ItemID,
        I.ItemCode,
        I.ItemName,
        I.Description,
        I.CategoryID,
        I.Unit,
        I.ReorderLevel,
        I.CurrentStock,
        TA.Diameter,
        TA.Radius,
        TA.Length,
        TA.Hardness,
        TA.Pitch,
        TA.MaterialType,
        TA.LocalOrImported
    FROM Items I
    LEFT JOIN ToolAttributes TA ON I.ItemID = TA.ItemID
    WHERE (@ItemID IS NULL OR I.ItemID = @ItemID);
END
GO
------------------------توليد الباركود التلقائي----------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_AddToolItem
    @ItemName NVARCHAR(100),
    @Description NVARCHAR(255) = NULL,
    @CategoryID INT,
    @Unit NVARCHAR(20),
    @ReorderLevel INT = 0,
    @InitialStock INT = 0,
    -- ToolAttributes
    @Diameter DECIMAL(10,2) = NULL,
    @Radius DECIMAL(10,2) = NULL,
    @Length DECIMAL(10,2) = NULL,
    @Hardness DECIMAL(10,2) = NULL,
    @Pitch DECIMAL(10,2) = NULL,
    @MaterialType NVARCHAR(50) = NULL,
    @LocalOrImported CHAR(1) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- ✅ تحقق من الحقول المطلوبة حسب نوع الأداة
    IF @ItemName = 'Endmill'
    BEGIN
        IF @Diameter IS NULL OR @Length IS NULL OR @Hardness IS NULL OR @LocalOrImported IS NULL
        BEGIN
            RAISERROR('Endmill requires Diameter, Length, Hardness, and LocalOrImported.', 16, 1);
            RETURN;
        END
    END
    ELSE IF @ItemName = 'Ballwill'
    BEGIN
        IF @Diameter IS NULL OR @Length IS NULL OR @Hardness IS NULL OR @LocalOrImported IS NULL
        BEGIN
            RAISERROR('Ballwill requires Diameter, Length, Hardness, and LocalOrImported.', 16, 1);
            RETURN;
        END
    END
    ELSE IF @ItemName = 'Drill'
    BEGIN
        IF @Diameter IS NULL OR @Length IS NULL OR @Hardness IS NULL OR @LocalOrImported IS NULL
        BEGIN
            RAISERROR('Drill requires Diameter, Length, Hardness, and LocalOrImported.', 16, 1);
            RETURN;
        END
    END
    ELSE IF @ItemName = 'Thread'
    BEGIN
        IF @Diameter IS NULL OR @Pitch IS NULL OR @Length IS NULL OR @LocalOrImported IS NULL
        BEGIN
            RAISERROR('Thread requires Diameter, Pitch, Length, and LocalOrImported.', 16, 1);
            RETURN;
        END
    END
    ELSE IF @ItemName = 'Reamer'
    BEGIN
        IF @Radius IS NULL OR @MaterialType IS NULL
        BEGIN
            RAISERROR('Reamer requires Radius and MaterialType.', 16, 1);
            RETURN;
        END
    END
    ELSE IF @ItemName = 'Inserts'
    BEGIN
        IF @Radius IS NULL OR @Radius NOT IN (2, 3.5, 5)
        BEGIN
            RAISERROR('Inserts require Radius of 2, 3.5 or 5.', 16, 1);
            RETURN;
        END
    END
    ELSE IF @ItemName = 'Shells'
    BEGIN
        IF @Diameter IS NULL OR @Radius IS NULL
        BEGIN
            RAISERROR('Shells require Diameter and Radius.', 16, 1);
            RETURN;
        END
        IF @Diameter = 15 AND @Length IS NULL
        BEGIN
            RAISERROR('Shells with Diameter = 15 require Length.', 16, 1);
            RETURN;
        END
    END

    -- 🏷️ توليد الباركود
    DECLARE @ItemCode NVARCHAR(100) = '';

    IF @ItemName = 'Endmill'
    BEGIN
        SET @ItemCode = 
            'E' + CAST(@Diameter AS NVARCHAR) +
            (CASE WHEN @Radius IS NOT NULL THEN 'R' + CAST(@Radius AS NVARCHAR) ELSE '' END) +
            'L' + CAST(@Length AS NVARCHAR) +
            'H' + CAST(@Hardness AS NVARCHAR) +
            ISNULL(@LocalOrImported, '');
    END
    ELSE IF @ItemName = 'Ballwill'
    BEGIN
        SET @ItemCode = 
            'B' + CAST(@Diameter AS NVARCHAR) +
            'L' + CAST(@Length AS NVARCHAR) +
            'H' + CAST(@Hardness AS NVARCHAR) +
            ISNULL(@LocalOrImported, '');
    END
    ELSE IF @ItemName = 'Drill'
    BEGIN
        SET @ItemCode = 
            'D' + CAST(@Diameter AS NVARCHAR) +
            'L' + CAST(@Length AS NVARCHAR) +
            'H' + CAST(@Hardness AS NVARCHAR) +
            ISNULL(@LocalOrImported, '');
    END
    ELSE IF @ItemName = 'Thread'
    BEGIN
        SET @ItemCode = 
            'M' + CAST(@Diameter AS NVARCHAR) +
            'P' + CAST(@Pitch AS NVARCHAR) +
            'L' + CAST(@Length AS NVARCHAR) +
            ISNULL(@LocalOrImported, '');
    END
    ELSE IF @ItemName = 'Reamer'
    BEGIN
        SET @ItemCode = 
            'R' + CAST(@Radius AS NVARCHAR) +
            ISNULL(@MaterialType, '');
    END
    ELSE IF @ItemName = 'Inserts'
    BEGIN
        SET @ItemCode = 
            'I' + 'R' + CAST(@Radius AS NVARCHAR);
    END
    ELSE IF @ItemName = 'Shells'
    BEGIN
        SET @ItemCode = 
            'S' + 'Φ' + CAST(@Diameter AS NVARCHAR) +
            'R' + CAST(@Radius AS NVARCHAR) +
            (CASE WHEN @Diameter = 15 THEN 'L' + CAST(@Length AS NVARCHAR) ELSE '' END);
    END

    -- ✅ تحقق من تكرار الباركود
    IF EXISTS (SELECT 1 FROM Items WHERE ItemCode = @ItemCode)
    BEGIN
        RAISERROR('ItemCode already exists. Please use different specifications.', 16, 1);
        RETURN;
    END;

    -- ✅ إضافة العنصر
    INSERT INTO Items (ItemCode, ItemName, Description, CategoryID, Unit, ReorderLevel, CurrentStock)
    VALUES (@ItemCode, @ItemName, @Description, @CategoryID, @Unit, @ReorderLevel, @InitialStock);

    DECLARE @NewItemID INT = SCOPE_IDENTITY();

    -- ✅ إضافة خصائص الأداة
    INSERT INTO ToolAttributes (ItemID, Diameter, Radius, Length, Hardness, Pitch, MaterialType, LocalOrImported)
    VALUES (@NewItemID, @Diameter, @Radius, @Length, @Hardness, @Pitch, @MaterialType, @LocalOrImported);

    PRINT '✔ Tool item has been added successfully with code: ' + @ItemCode;
END
GO
----------------------------------------------------------------------------------------------------------------
ALTER TABLE Items
ADD BarCode1 NVARCHAR(100) NULL;
----------------------------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_AddToolItem
    @ItemName NVARCHAR(100),
    @Description NVARCHAR(255) = NULL,
    @CategoryID INT,
    @Unit NVARCHAR(20),
    @ReorderLevel INT = 0,
    @InitialStock INT = 0,
    @BarCode1 NVARCHAR(100) = NULL,  -- الباركود الأصلي من المصنع، لو متوفر
    -- ToolAttributes
    @Diameter DECIMAL(10,2) = NULL,
    @Radius DECIMAL(10,2) = NULL,
    @Length DECIMAL(10,2) = NULL,
    @Hardness DECIMAL(10,2) = NULL,
    @Pitch DECIMAL(10,2) = NULL,
    @MaterialType NVARCHAR(50) = NULL,
    @LocalOrImported CHAR(1) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- التحقق من الحقول المطلوبة حسب نوع الأداة (زي ما قبل كده)
    IF @ItemName = 'Endmill'
    BEGIN
        IF @Diameter IS NULL OR @Length IS NULL OR @Hardness IS NULL OR @LocalOrImported IS NULL
        BEGIN
            RAISERROR('Endmill requires Diameter, Length, Hardness, and LocalOrImported.', 16, 1);
            RETURN;
        END
    END
    -- باقي التحقق لأنواع الأدوات ...

    -- توليد BarCode2 تلقائياً (الكود المولد)
    DECLARE @BarCode2 NVARCHAR(100) = '';

    IF @ItemName = 'Endmill'
    BEGIN
        SET @BarCode2 = 
            'E' + CAST(@Diameter AS NVARCHAR) +
            (CASE WHEN @Radius IS NOT NULL THEN 'R' + CAST(@Radius AS NVARCHAR) ELSE '' END) +
            'L' + CAST(@Length AS NVARCHAR) +
            'H' + CAST(@Hardness AS NVARCHAR) +
            ISNULL(@LocalOrImported, '');
    END
    -- باقي توليد الباركود للكائنات الأخرى زي قبل...

    -- تحقق عدم تكرار BarCode2 في الجدول
    IF EXISTS (SELECT 1 FROM Items WHERE ItemCode = @BarCode2)
    BEGIN
        RAISERROR('Generated BarCode2 already exists. Please check input values.', 16, 1);
        RETURN;
    END;

    -- تحقق من عدم تكرار BarCode1 لو مش NULL
    IF @BarCode1 IS NOT NULL
    BEGIN
        IF EXISTS (SELECT 1 FROM Items WHERE BarCode1 = @BarCode1)
        BEGIN
            RAISERROR('BarCode1 (factory barcode) already exists. Please check input.', 16, 1);
            RETURN;
        END
    END

    -- إدخال البيانات في جدول Items مع الباركودين
    INSERT INTO Items (ItemCode, BarCode1, ItemName, Description, CategoryID, Unit, ReorderLevel, CurrentStock)
    VALUES (@BarCode2, @BarCode1, @ItemName, @Description, @CategoryID, @Unit, @ReorderLevel, @InitialStock);

    DECLARE @NewItemID INT = SCOPE_IDENTITY();

    -- إضافة ToolAttributes
    INSERT INTO ToolAttributes (ItemID, Diameter, Radius, Length, Hardness, Pitch, MaterialType, LocalOrImported)
    VALUES (@NewItemID, @Diameter, @Radius, @Length, @Hardness, @Pitch, @MaterialType, @LocalOrImported);

    PRINT '✔ Tool item added. Factory BarCode1: ' + ISNULL(@BarCode1,'(none)') + ', Generated BarCode2: ' + @BarCode2;
END
GO
----------------------------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_UpdateToolItem
    @ItemID INT,
    @ItemName NVARCHAR(100),
    @Description NVARCHAR(255) = NULL,
    @CategoryID INT,
    @Unit NVARCHAR(20),
    @ReorderLevel INT = 0,
    @BarCode1 NVARCHAR(100) = NULL,  -- الباركود الأصلي من المصنع لو موجود
    -- ToolAttributes
    @Diameter DECIMAL(10,2) = NULL,
    @Radius DECIMAL(10,2) = NULL,
    @Length DECIMAL(10,2) = NULL,
    @Hardness DECIMAL(10,2) = NULL,
    @Pitch DECIMAL(10,2) = NULL,
    @MaterialType NVARCHAR(50) = NULL,
    @LocalOrImported CHAR(1) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- تحقق من وجود ItemID
    IF NOT EXISTS (SELECT 1 FROM Items WHERE ItemID = @ItemID)
    BEGIN
        RAISERROR('Item not found.', 16, 1);
        RETURN;
    END;

    -- التحقق من الحقول المطلوبة حسب نوع الأداة (زي ما قبل كده)
    IF @ItemName = 'Endmill'
    BEGIN
        IF @Diameter IS NULL OR @Length IS NULL OR @Hardness IS NULL OR @LocalOrImported IS NULL
        BEGIN
            RAISERROR('Endmill requires Diameter, Length, Hardness, and LocalOrImported.', 16, 1);
            RETURN;
        END
    END
    -- باقي التحقق لأنواع الأدوات ...

    -- توليد BarCode2 تلقائياً (الكود المولد)
    DECLARE @BarCode2 NVARCHAR(100) = '';

    IF @ItemName = 'Endmill'
    BEGIN
        SET @BarCode2 = 
            'E' + CAST(@Diameter AS NVARCHAR) +
            (CASE WHEN @Radius IS NOT NULL THEN 'R' + CAST(@Radius AS NVARCHAR) ELSE '' END) +
            'L' + CAST(@Length AS NVARCHAR) +
            'H' + CAST(@Hardness AS NVARCHAR) +
            ISNULL(@LocalOrImported, '');
    END
    -- باقي توليد الباركود للكائنات الأخرى زي قبل...

    -- تحقق عدم تكرار BarCode2 في سجل مختلف
    IF EXISTS (SELECT 1 FROM Items WHERE ItemCode = @BarCode2 AND ItemID <> @ItemID)
    BEGIN
        RAISERROR('Generated BarCode2 already exists for another item. Please check input values.', 16, 1);
        RETURN;
    END;

    -- تحقق من عدم تكرار BarCode1 في سجل مختلف لو مش NULL
    IF @BarCode1 IS NOT NULL
    BEGIN
        IF EXISTS (SELECT 1 FROM Items WHERE BarCode1 = @BarCode1 AND ItemID <> @ItemID)
        BEGIN
            RAISERROR('BarCode1 (factory barcode) already exists for another item. Please check input.', 16, 1);
            RETURN;
        END
    END

    -- تحديث جدول Items
    UPDATE Items
    SET 
        ItemCode = @BarCode2,
        BarCode1 = @BarCode1,
        ItemName = @ItemName,
        Description = @Description,
        CategoryID = @CategoryID,
        Unit = @Unit,
        ReorderLevel = @ReorderLevel
    WHERE ItemID = @ItemID;

    -- تحديث ToolAttributes
    UPDATE ToolAttributes
    SET
        Diameter = @Diameter,
        Radius = @Radius,
        Length = @Length,
        Hardness = @Hardness,
        Pitch = @Pitch,
        MaterialType = @MaterialType,
        LocalOrImported = @LocalOrImported
    WHERE ItemID = @ItemID;

    PRINT '✔ Tool item updated. Factory BarCode1: ' + ISNULL(@BarCode1,'(none)') + ', Generated BarCode2: ' + @BarCode2;
END
GO
----------------------------------------------------------------------
IF OBJECT_ID('sp_DeleteToolItem', 'P') IS NOT NULL
    DROP PROCEDURE sp_DeleteToolItem;
GO
------------------------------------------------------------------
IF OBJECT_ID('sp_GetToolItem', 'P') IS NOT NULL
    DROP PROCEDURE sp_GetToolItem;
GO
------------------------------------------------------------------
CREATE PROCEDURE sp_DeleteToolItem
    @ItemID INT
AS
BEGIN
    SET NOCOUNT ON;

    -- تأكد أن الأداة موجودة
    IF NOT EXISTS (SELECT 1 FROM Items WHERE ItemID = @ItemID)
    BEGIN
        RAISERROR('Item not found.', 16, 1);
        RETURN;
    END

    -- حذف صف الخصائص المرتبطة
    DELETE FROM ToolAttributes WHERE ItemID = @ItemID;

    -- حذف الأداة
    DELETE FROM Items WHERE ItemID = @ItemID;

    PRINT 'Tool item deleted successfully.';
END;
GO
----------------------------------------------------------------------
CREATE PROCEDURE sp_GetToolItem
    @ItemID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        i.ItemID,
        i.ItemCode,
        i.ItemName,
        i.Description,
        i.CategoryID,
        i.Unit,
        i.ReorderLevel,
        i.CurrentStock,
        i.CreatedAt,
        ta.Diameter,
        ta.Radius,
        ta.Length,
        ta.Hardness,
        ta.Pitch,
        ta.MaterialType,
        ta.LocalOrImported
    FROM Items i
    LEFT JOIN ToolAttributes ta ON i.ItemID = ta.ItemID
    WHERE i.ItemID = @ItemID;
END;
GO
---------------------------------------------------------------------------------
CREATE PROCEDURE sp_AddTransaction
    @ItemID INT,
    @UserID INT,
    @Action NVARCHAR(10), -- مثلاً 'IN' أو 'OUT'
    @QuantityChange INT
AS
BEGIN
    SET NOCOUNT ON;

    -- تحقق من وجود العنصر والمستخدم
    IF NOT EXISTS (SELECT 1 FROM Items WHERE ItemID = @ItemID)
    BEGIN
        RAISERROR('Item not found.', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Users WHERE UserID = @UserID)
    BEGIN
        RAISERROR('User not found.', 16, 1);
        RETURN;
    END

    -- تحقق من صلاحية الكمية في حالة حركة OUT (نقصان)
    IF @Action = 'OUT'
    BEGIN
        DECLARE @CurrentStock INT;
        SELECT @CurrentStock = CurrentStock FROM Items WHERE ItemID = @ItemID;

        IF @QuantityChange > @CurrentStock
        BEGIN
            RAISERROR('Not enough stock.', 16, 1);
            RETURN;
        END
    END

    -- أضف الحركة
    INSERT INTO Transactions (ItemID, UserID, Action, QuantityChange, Timestamp)
    VALUES (@ItemID, @UserID, @Action, @QuantityChange, GETDATE());

    -- حدّث المخزون في Items
    IF @Action = 'IN'
    BEGIN
        UPDATE Items
        SET CurrentStock = CurrentStock + @QuantityChange
        WHERE ItemID = @ItemID;
    END
    ELSE IF @Action = 'OUT'
    BEGIN
        UPDATE Items
        SET CurrentStock = CurrentStock - @QuantityChange
        WHERE ItemID = @ItemID;
    END

    PRINT 'Transaction added and stock updated successfully.';
END
GO
----------------------------------------------------------------
CREATE PROCEDURE sp_GetTransactions
AS
BEGIN
    SELECT t.TransactionID, t.ItemID, i.ItemName, t.UserID, u.Username, t.Action, t.QuantityChange, t.Timestamp
    FROM Transactions t
    INNER JOIN Items i ON t.ItemID = i.ItemID
    INNER JOIN Users u ON t.UserID = u.UserID
    ORDER BY t.Timestamp DESC;
END
GO
----------------------------------------------------------------------------------------------------
CREATE VIEW vw_ToolDetails AS
SELECT 
    I.ItemID,
    I.ItemCode,
    I.ItemName,
    I.Description,
    C.CategoryName,
    I.Unit,
    I.ReorderLevel,
    I.CurrentStock,
    TA.Diameter,
    TA.Radius,
    TA.Length,
    TA.Hardness,
    TA.Pitch,
    TA.MaterialType,
    TA.LocalOrImported,
    I.CreatedAt
FROM Items I
LEFT JOIN ToolAttributes TA ON I.ItemID = TA.ItemID
LEFT JOIN Categories C ON I.CategoryID = C.CategoryID;
-----------------------------------------------------------------------------------------------
SELECT * FROM vw_ToolDetails;
------------------------------------------------------------------------------------
CREATE VIEW vw_StockTransactions AS
SELECT 
    T.TransactionID,
    T.Timestamp,
    U.Username AS PerformedBy,
    I.ItemCode,
    I.ItemName,
    T.Action,
    T.QuantityChange
FROM Transactions T
INNER JOIN Items I ON T.ItemID = I.ItemID
INNER JOIN Users U ON T.UserID = U.UserID;
--------------------------------------------------------------------------------
SELECT * FROM vw_StockTransactions;








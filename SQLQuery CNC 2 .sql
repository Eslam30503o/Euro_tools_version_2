CREATE TABLE SubCategories (
    SubCategoryID INT IDENTITY(1,1) PRIMARY KEY,
    SubCategoryName NVARCHAR(100) NOT NULL,
    CategoryID INT NOT NULL FOREIGN KEY REFERENCES Categories(CategoryID)
);
--------------------------------------------------------
ALTER TABLE Items
ADD SubCategoryID INT NULL
    FOREIGN KEY REFERENCES SubCategories(SubCategoryID);
--------------------------------------------------------------
INSERT INTO Categories (CategoryName)
VALUES 
    (N'Mold'),
    (N'Automation');
-----------------------------------------------------------------------------------
SELECT * FROM Categories;
------------------------------------------------------
INSERT INTO SubCategories (SubCategoryName, CategoryID)
VALUES 
-- Mold Subcategories
(N'Mold Base', 1),
(N'Ejector Pins', 1),
(N'Cooling Components', 1),
(N'Mold Inserts', 1),
(N'Springs', 1),
(N'Guiding Components', 1),

-- Automation - Mechanical
(N'Mechanical', 2),
-- Automation - Pneumatic
(N'Pneumatic', 2),
-- Automation - Electrical
(N'Electrical', 2);
--------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_AddToolItem
    @ItemCode NVARCHAR(100),
    @ItemName NVARCHAR(100),
    @Description NVARCHAR(255) = NULL,
    @CategoryID INT,
    @SubCategoryID INT = NULL,  -- مهم هنا، متنساش الفاصلة قبلها!
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

    -- هنا باقي كود الإجراء
END;
GO

-------------------------------------------------------------------------------
CREATE OR ALTER VIEW vw_FullToolItemDetails AS
SELECT 
    I.ItemID,
    I.ItemCode,
    I.BarCode1,
    I.ItemName,
    I.Description,
    C.CategoryName,
    SC.SubCategoryName,
    I.Unit,
    I.ReorderLevel,
    I.CurrentStock,
    I.CreatedAt,
    TA.Diameter,
    TA.Radius,
    TA.Length,
    TA.Hardness,
    TA.Pitch,
    TA.MaterialType,
    TA.LocalOrImported
FROM Items I
LEFT JOIN ToolAttributes TA ON I.ItemID = TA.ItemID
LEFT JOIN Categories C ON I.CategoryID = C.CategoryID
LEFT JOIN SubCategories SC ON I.SubCategoryID = SC.SubCategoryID;
GO

-------------------------------------------------------------
-------------------------------------------------------------------------
IF OBJECT_ID('sp_AddToolItem', 'P') IS NOT NULL
    DROP PROCEDURE sp_AddToolItem;
GO

CREATE PROCEDURE sp_AddToolItem
    @UserID INT, -- المستخدم اللي بيضيف الأداة
    @ItemName NVARCHAR(100),
    @Description NVARCHAR(255) = NULL,
    @CategoryID INT,
    @SubCategoryID INT = NULL,
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

    -- التحقق من صلاحيات المستخدم
    DECLARE @UserRole NVARCHAR(20);
    SELECT @UserRole = Role FROM Users WHERE UserID = @UserID;

    IF @UserRole NOT IN ('Admin', 'Manager')
    BEGIN
        RAISERROR('⛔ غير مسموح لك بإضافة أدوات. الصلاحية مطلوبة: Admin أو Manager', 16, 1);
        RETURN;
    END;

    -- توليد الكود التلقائي (باركود)
    DECLARE @ItemCode NVARCHAR(100) = '';

    IF @ItemName = 'Endmill'
    BEGIN
        IF @Diameter IS NULL OR @Length IS NULL OR @Hardness IS NULL OR @LocalOrImported IS NULL
        BEGIN
            RAISERROR('Endmill requires Diameter, Length, Hardness, and LocalOrImported.', 16, 1);
            RETURN;
        END

        SET @ItemCode = 
            'E' + CAST(@Diameter AS NVARCHAR(10)) +
            ISNULL('R' + CAST(@Radius AS NVARCHAR(10)), '') +
            'L' + CAST(@Length AS NVARCHAR(10)) +
            'H' + CAST(@Hardness AS NVARCHAR(10)) +
            ISNULL(@LocalOrImported, '');
    END
    ELSE IF @ItemName = 'Ballwill'
    BEGIN
        -- تحقق من الحقول المطلوبة
        IF @Diameter IS NULL OR @Length IS NULL OR @Hardness IS NULL OR @LocalOrImported IS NULL
        BEGIN
            RAISERROR('Ballwill requires Diameter, Length, Hardness, and LocalOrImported.', 16, 1);
            RETURN;
        END

        SET @ItemCode = 
            'B' + CAST(@Diameter AS NVARCHAR(10)) +
            'L' + CAST(@Length AS NVARCHAR(10)) +
            'H' + CAST(@Hardness AS NVARCHAR(10)) +
            ISNULL(@LocalOrImported, '');
    END
    ELSE IF @ItemName = 'Drill'
    BEGIN
        -- تحقق من الحقول المطلوبة
        IF @Diameter IS NULL OR @Length IS NULL OR @Hardness IS NULL OR @LocalOrImported IS NULL
        BEGIN
            RAISERROR('Drill requires Diameter, Length, Hardness, and LocalOrImported.', 16, 1);
            RETURN;
        END

        SET @ItemCode = 
            'D' + CAST(@Diameter AS NVARCHAR(10)) +
            'L' + CAST(@Length AS NVARCHAR(10)) +
            'H' + CAST(@Hardness AS NVARCHAR(10)) +
            ISNULL(@LocalOrImported, '');
    END
    ELSE IF @ItemName = 'Thread'
    BEGIN
        -- تحقق من الحقول المطلوبة
        IF @Diameter IS NULL OR @Pitch IS NULL OR @Length IS NULL OR @LocalOrImported IS NULL
        BEGIN
            RAISERROR('Thread requires Diameter, Pitch, Length, and LocalOrImported.', 16, 1);
            RETURN;
        END

        SET @ItemCode = 
            'M' + CAST(@Diameter AS NVARCHAR(10)) +
            'P' + CAST(@Pitch AS NVARCHAR(10)) +
            'L' + CAST(@Length AS NVARCHAR(10)) +
            ISNULL(@LocalOrImported, '');
    END
    ELSE IF @ItemName = 'Reamer'
    BEGIN
        IF @Radius IS NULL OR @MaterialType IS NULL
        BEGIN
            RAISERROR('Reamer requires Radius and MaterialType.', 16, 1);
            RETURN;
        END

        SET @ItemCode = 
            'R' + CAST(@Radius AS NVARCHAR(10)) +
            ISNULL(@MaterialType, '');
    END
    ELSE IF @ItemName = 'Inserts'
    BEGIN
        IF @Radius IS NULL OR @Radius NOT IN (2, 3.5, 5)
        BEGIN
            RAISERROR('Inserts require Radius of 2, 3.5 or 5.', 16, 1);
            RETURN;
        END

        SET @ItemCode = 'I' + 'R' + CAST(@Radius AS NVARCHAR(10));
    END
    ELSE IF @ItemName = 'Shells'
    BEGIN
        IF @Diameter IS NULL OR @Radius IS NULL
        BEGIN
            RAISERROR('Shells require Diameter and Radius.', 16, 1);
            RETURN;
        END

        SET @ItemCode = 
            'SΦ' + CAST(@Diameter AS NVARCHAR(10)) +
            'R' + CAST(@Radius AS NVARCHAR(10)) +
            CASE WHEN @Diameter = 15 THEN 'L' + CAST(@Length AS NVARCHAR(10)) ELSE '' END;
    END
    ELSE
    BEGIN
        -- لو اسم الأداة مش من الأنواع اللي متعرف عليها، نديها كود فريد بسيط
        SET @ItemCode = NEWID();
    END

    -- تحقق من تكرار ItemCode
    IF EXISTS (SELECT 1 FROM Items WHERE ItemCode = @ItemCode)
    BEGIN
        RAISERROR('ItemCode already exists. Please check the specifications.', 16, 1);
        RETURN;
    END

    -- إضافة الأداة في جدول Items
    INSERT INTO Items (ItemCode, ItemName, Description, CategoryID, SubCategoryID, Unit, ReorderLevel, CurrentStock)
    VALUES (@ItemCode, @ItemName, @Description, @CategoryID, @SubCategoryID, @Unit, @ReorderLevel, @InitialStock);

    DECLARE @NewItemID INT = SCOPE_IDENTITY();

    -- إضافة خصائص الأداة في ToolAttributes
    INSERT INTO ToolAttributes (ItemID, Diameter, Radius, Length, Hardness, Pitch, MaterialType, LocalOrImported)
    VALUES (@NewItemID, @Diameter, @Radius, @Length, @Hardness, @Pitch, @MaterialType, @LocalOrImported);

    PRINT '✔ Tool item has been added successfully with ItemCode: ' + @ItemCode;
END;
GO
-------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------
IF OBJECT_ID('sp_UpdateToolItem', 'P') IS NOT NULL
    DROP PROCEDURE sp_UpdateToolItem;
GO

CREATE PROCEDURE sp_UpdateToolItem
    @UserID INT,
    @ItemID INT,
    @ItemName NVARCHAR(100),
    @Description NVARCHAR(255) = NULL,
    @CategoryID INT,
    @SubCategoryID INT = NULL,
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

    -- 🔐 التحقق من صلاحية المستخدم
    DECLARE @UserRole NVARCHAR(20);
    SELECT @UserRole = Role FROM Users WHERE UserID = @UserID;

    IF @UserRole NOT IN ('Admin', 'Manager', 'Supervisor')
    BEGIN
        RAISERROR('⛔ غير مسموح لك بتعديل الأدوات. الصلاحية مطلوبة: Admin أو Manager أو Supervisor.', 16, 1);
        RETURN;
    END;

    -- 🧠 توليد كود جديد بناءً على ItemName
    DECLARE @NewCode NVARCHAR(100);

    IF @ItemName = 'Endmill'
        SET @NewCode = 'E' + CAST(@Diameter AS NVARCHAR) + ISNULL('R' + CAST(@Radius AS NVARCHAR), '') +
                       'L' + CAST(@Length AS NVARCHAR) + 'H' + CAST(@Hardness AS NVARCHAR) + ISNULL(@LocalOrImported, '');
    ELSE IF @ItemName = 'Ballwill'
        SET @NewCode = 'B' + CAST(@Diameter AS NVARCHAR) + 'L' + CAST(@Length AS NVARCHAR) + 'H' + CAST(@Hardness AS NVARCHAR) + ISNULL(@LocalOrImported, '');
    ELSE IF @ItemName = 'Drill'
        SET @NewCode = 'D' + CAST(@Diameter AS NVARCHAR) + 'L' + CAST(@Length AS NVARCHAR) + 'H' + CAST(@Hardness AS NVARCHAR) + ISNULL(@LocalOrImported, '');
    ELSE IF @ItemName = 'Thread'
        SET @NewCode = 'M' + CAST(@Diameter AS NVARCHAR) + 'P' + CAST(@Pitch AS NVARCHAR) + 'L' + CAST(@Length AS NVARCHAR) + ISNULL(@LocalOrImported, '');
    ELSE IF @ItemName = 'Reamer'
        SET @NewCode = 'R' + CAST(@Radius AS NVARCHAR) + ISNULL(@MaterialType, '');
    ELSE IF @ItemName = 'Inserts'
        SET @NewCode = 'IR' + CAST(@Radius AS NVARCHAR);
    ELSE IF @ItemName = 'Shells'
        SET @NewCode = 'SΦ' + CAST(@Diameter AS NVARCHAR) + 'R' + CAST(@Radius AS NVARCHAR) +
                      CASE WHEN @Diameter = 15 THEN 'L' + CAST(@Length AS NVARCHAR) ELSE '' END;
    ELSE
        SET @NewCode = NEWID(); -- fallback

    -- ✅ تأكد من عدم تكرار الكود في عنصر آخر
    IF EXISTS (SELECT 1 FROM Items WHERE ItemCode = @NewCode AND ItemID <> @ItemID)
    BEGIN
        RAISERROR('🔁 الكود المقترح موجود بالفعل في عنصر آخر.', 16, 1);
        RETURN;
    END

    -- ✅ تحديث بيانات العنصر
    UPDATE Items
    SET 
        ItemCode = @NewCode,
        ItemName = @ItemName,
        Description = @Description,
        CategoryID = @CategoryID,
        SubCategoryID = @SubCategoryID,
        Unit = @Unit,
        ReorderLevel = @ReorderLevel,
        CurrentStock = @CurrentStock,
        CreatedAt = GETDATE()
    WHERE ItemID = @ItemID;

    -- ✅ تحديث خصائص الأداة
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

    PRINT '✔ Tool item updated successfully with new code: ' + @NewCode;
END;
GO
-------------------------------------
--------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_DeleteToolItem', 'P') IS NOT NULL
    DROP PROCEDURE sp_DeleteToolItem;
GO

CREATE PROCEDURE sp_DeleteToolItem
    @UserID INT,
    @ItemID INT
AS
BEGIN
    SET NOCOUNT ON;

    -- 🔐 جلب صلاحية المستخدم
    DECLARE @UserRole NVARCHAR(20);
    SELECT @UserRole = Role FROM Users WHERE UserID = @UserID;

    -- ❌ التحقق من الصلاحية
    IF @UserRole NOT IN ('Admin', 'Manager')
    BEGIN
        RAISERROR('⛔ غير مسموح لك بحذف الأدوات. الصلاحية مطلوبة: Admin أو Manager.', 16, 1);
        RETURN;
    END;

    -- ✅ التحقق من وجود الأداة
    IF NOT EXISTS (SELECT 1 FROM Items WHERE ItemID = @ItemID)
    BEGIN
        RAISERROR('❌ لم يتم العثور على الأداة المحددة.', 16, 1);
        RETURN;
    END;

    -- ✅ حذف الخصائص المرتبطة (ToolAttributes) أولاً
    DELETE FROM ToolAttributes WHERE ItemID = @ItemID;

    -- ✅ حذف الأداة من جدول Items
    DELETE FROM Items WHERE ItemID = @ItemID;

    PRINT '🗑️ تم حذف الأداة بنجاح.';
END;
GO
-----------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_GetToolItem', 'P') IS NOT NULL
    DROP PROCEDURE sp_GetToolItem;
GO

CREATE PROCEDURE sp_GetToolItem
    @UserID INT,
    @ItemID INT = NULL  -- لو NULL يرجّع كل الأدوات، لو رقم يرجّع أداة واحدة
AS
BEGIN
    SET NOCOUNT ON;

    -- 🔐 التحقق من صلاحية المستخدم
    DECLARE @UserRole NVARCHAR(20);
    SELECT @UserRole = Role FROM Users WHERE UserID = @UserID;

    IF @UserRole NOT IN ('Admin', 'Manager', 'Supervisor', 'User')
    BEGIN
        RAISERROR('⛔ لا تملك صلاحية عرض الأدوات.', 16, 1);
        RETURN;
    END;

    -- ✅ إرجاع بيانات الأدوات (مع التصنيفات والخصائص)
    SELECT 
        I.ItemID,
        I.ItemCode,
        I.BarCode1,
        I.ItemName,
        I.Description,
        C.CategoryName,
        SC.SubCategoryName,
        I.Unit,
        I.ReorderLevel,
        I.CurrentStock,
        I.CreatedAt,
        TA.Diameter,
        TA.Radius,
        TA.Length,
        TA.Hardness,
        TA.Pitch,
        TA.MaterialType,
        TA.LocalOrImported
    FROM Items I
    LEFT JOIN ToolAttributes TA ON I.ItemID = TA.ItemID
    LEFT JOIN Categories C ON I.CategoryID = C.CategoryID
    LEFT JOIN SubCategories SC ON I.SubCategoryID = SC.SubCategoryID
    WHERE (@ItemID IS NULL OR I.ItemID = @ItemID);
END;
GO
---------------------------------------------------------------------------
CREATE OR ALTER VIEW vw_ReorderAlerts AS
SELECT 
    I.ItemID,
    I.ItemCode,
    I.ItemName,
    I.CurrentStock,
    I.ReorderLevel,
    C.CategoryName,
    SC.SubCategoryName
FROM Items I
LEFT JOIN Categories C ON I.CategoryID = C.CategoryID
LEFT JOIN SubCategories SC ON I.SubCategoryID = SC.SubCategoryID
WHERE I.CurrentStock <= I.ReorderLevel;
------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_SearchItems
    @Keyword NVARCHAR(100) = NULL,
    @CategoryID INT = NULL,
    @SubCategoryID INT = NULL,
    @Unit NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        I.ItemID,
        I.ItemCode,
        I.ItemName,
        I.Description,
        C.CategoryName,
        SC.SubCategoryName,
        I.Unit,
        I.CurrentStock
    FROM Items I
    LEFT JOIN Categories C ON I.CategoryID = C.CategoryID
    LEFT JOIN SubCategories SC ON I.SubCategoryID = SC.SubCategoryID
    WHERE (@Keyword IS NULL OR I.ItemName LIKE '%' + @Keyword + '%')
      AND (@CategoryID IS NULL OR I.CategoryID = @CategoryID)
      AND (@SubCategoryID IS NULL OR I.SubCategoryID = @SubCategoryID)
      AND (@Unit IS NULL OR I.Unit = @Unit);
END;
-------------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_GetTransactionsByDate
    @StartDate DATETIME,
    @EndDate DATETIME
AS
BEGIN
    SELECT 
        T.TransactionID,
        T.Timestamp,
        I.ItemCode,
        I.ItemName,
        U.Username,
        T.Action,
        T.QuantityChange
    FROM Transactions T
    JOIN Items I ON T.ItemID = I.ItemID
    JOIN Users U ON T.UserID = U.UserID
    WHERE T.Timestamp BETWEEN @StartDate AND @EndDate
    ORDER BY T.Timestamp DESC;
END;
-------------------------------------------------------------------------------
ALTER TABLE SubCategories
ADD SubCategoryCode NVARCHAR(10) NULL;
----------------------------------------------------------------
UPDATE SubCategories SET SubCategoryCode = 'E' WHERE SubCategoryName LIKE '%Endmill%'
UPDATE SubCategories SET SubCategoryCode = 'B' WHERE SubCategoryName LIKE '%Ballmill%'
UPDATE SubCategories SET SubCategoryCode = 'D' WHERE SubCategoryName LIKE '%Drill%'
UPDATE SubCategories SET SubCategoryCode = 'M' WHERE SubCategoryName LIKE '%Thread%'
UPDATE SubCategories SET SubCategoryCode = 'R' WHERE SubCategoryName LIKE '%Reamer%'
UPDATE SubCategories SET SubCategoryCode = 'I' WHERE SubCategoryName LIKE '%Inserts%'
UPDATE SubCategories SET SubCategoryCode = 'S' WHERE SubCategoryName LIKE '%Shell%'


SELECT * 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'SubCategories' AND COLUMN_NAME = 'SubCategoryCode';
<<<<<<< Updated upstream
<<<<<<< HEAD
=======
>>>>>>> Stashed changes


ALTER TABLE Items
ADD Type NVARCHAR(50) NULL;
<<<<<<< Updated upstream
=======
>>>>>>> 7b7fe8a9359d678567045f0e488e7e16650e19bb
=======
>>>>>>> Stashed changes








ALTER TABLE Transactions ADD RecipientName NVARCHAR(100) ;

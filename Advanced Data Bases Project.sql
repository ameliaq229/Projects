USE MBikeRental
GO

-- STORED PROCEDURES

-- Update Motorbike
CREATE PROC uspUpdateMbike (
    @bike_id CHAR(5),
    @bike_plate_number VARCHAR(8) = 'NIL', 
    @bike_status VARCHAR(15) = 'NIL', 
    @stat_address VARCHAR(100) = 'NIL'
)
AS
BEGIN
	-- Checks for any errors during execution
    IF @@ERROR <> 0  
    BEGIN
        SELECT 'Error occurred during execution' AS 'Unable to update';
        RETURN -216;
    END

	-- Checks if the specified Motorbike ID exists in the system
    IF NOT EXISTS (SELECT * FROM Motorbike WHERE bike_id = @bike_id) 
    BEGIN
        SELECT 'Motorbike ID does not exist in the system' AS 'Unable to update';
        RETURN -201; -- Bike ID doesn't exist
    END

	-- Checks if the specified Motorbike plate number already exists in the system
    IF EXISTS (SELECT * FROM Motorbike WHERE bike_plate_number = @bike_plate_number) 
    BEGIN
        SELECT 'Motorbike plate number already exists in the system' AS 'Unable to update';
        RETURN -203; -- Plate number already exists
    END

	-- Checks if the specified Motorbike plate number is valid
    IF ((LEN(@bike_plate_number) != 8) OR (PATINDEX('[A-Z][A-Z][A-Z][0-9][0-9][0-9][0-9][A-Z]', @bike_plate_number) = 0)) 
        AND (@bike_plate_number != 'NIL')
    BEGIN
        SELECT 'Invalid Motorbike plate number given' AS 'Unable to update';
        RETURN -214; -- Invalid Plate number
    END

	-- Checks if the specified Motorbike status is valid
    IF @bike_status != 'NIL' AND @bike_status != 'Available' AND @bike_status != 'Not Available' 
    BEGIN
        SELECT 'Invalid Motorbike status given' AS 'Unable to update';
        RETURN -207; -- Invalid bike status
    END

	-- Checks if the specified BikeStation address exists in the system
    IF NOT EXISTS (SELECT * FROM BikeStation WHERE stat_address = @stat_address) AND @stat_address != 'NIL'
    BEGIN
        SELECT 'Motorbike station address does not exist in the system' AS 'Unable to update';
        RETURN -209; -- Station address doesn't exist
    END

	-- Checks if nothing is given to update
    IF @bike_plate_number = 'NIL' AND @bike_status = 'NIL' AND @stat_address = 'NIL' 
    BEGIN
        SELECT 'Nothing given to update' AS 'Unable to update';
        RETURN -211; -- Nothing given to update
    END

	-- Gets the BikeStation ID for the specified station address
    DECLARE @bike_station CHAR(3); 
    SELECT @bike_station = stat_id
    FROM BikeStation
    WHERE stat_address = @stat_address;
	
	-- Variable to contain the UPDATE SQL
    DECLARE @cmdSQL VARCHAR (255); 

	-- If a new plate number is provided, include it in the update statement
    IF @bike_plate_number <> 'NIL' 
        SET @cmdSQL = 'SET bike_plate_number = ''' + UPPER(@bike_plate_number) + '''';

	-- If a new status is provided, include it in the update statement
    IF @bike_status <> 'NIL' 
    BEGIN
        IF @cmdSQL IS NULL
            SET @cmdSQL = 'SET bike_status = ''' + @bike_status + '''';
        ELSE
            SET @cmdSQL = @cmdSQL + ', bike_status = ''' + @bike_status + '''';
    END

	-- If a new station ID is provided, include it in the update statement
    IF @bike_station <> 'NIL' 
    BEGIN
        IF @cmdSQL IS NULL
            SET @cmdSQL = 'SET bike_station = ''' + @bike_station + '''';
        ELSE
            SET @cmdSQL = @cmdSQL + ', bike_station = ''' + @bike_station + '''';
    END

	-- Constructs the UPDATE statement and execute it
    SET @cmdSQL = 'UPDATE Motorbike ' + @cmdSQL + ' WHERE bike_id = ''' + @bike_id + '''';  
    EXEC (@cmdSQL);
    RETURN;
END;
GO

--DROP PROC uspUpdateMbike
--GO

-- Testing

DECLARE @status INT -- Invalid BikeID (Error -201 | MotorbikeID does not exist in the system)
SELECT * FROM Motorbike
EXEC @status = uspUpdateMbike 'B002','NIL','NIL','NIL'
SELECT @status AS 'Error Message'
SELECT * FROM Motorbike
GO

DECLARE @status INT -- Invalid BikePlateNumber (Error -203 | MotorbikePlateNumber already exists in the system)
SELECT * FROM Motorbike
EXEC @status = uspUpdateMbike 'B0002','FAA1111A','NIL','NIL'
SELECT @status AS 'Error Message'
SELECT * FROM Motorbike
GO

DECLARE @status INT -- Invalid BikePlateNumber (Error -214 | MotorbikePlateNumber in Invalid Format)
SELECT * FROM Motorbike
EXEC @status = uspUpdateMbike 'B0002','FAH822B','Not Available','NIL'
SELECT @status AS 'Error Message'
SELECT * FROM Motorbike
GO

DECLARE @status INT -- Invalid BikeStatus (Error -207 | MotorbikeStatus in Invalid Format)
SELECT * FROM Motorbike
EXEC @status = uspUpdateMbike 'B0002','FAH8222B','Not Avail','NIL'
SELECT @status AS 'Error Message'
SELECT * FROM Motorbike
GO

DECLARE @status INT -- Invalid BikeStationAddress (Error -209 | MotorbikeStationAddress does not exist in the system)
SELECT * FROM Motorbike
EXEC @status = uspUpdateMbike 'B0002','FAH8222B','Not Available','Chinatown'
SELECT @status AS 'Error Message'
SELECT * FROM Motorbike
GO

DECLARE @status INT -- Nothing Given to update (Error -211 | Nothing given to update)
SELECT * FROM Motorbike
EXEC @status = uspUpdateMbike 'B0002','NIL','NIL','NIL'
SELECT @status AS 'Error Message'
SELECT * FROM Motorbike
GO

DECLARE @status INT -- Successful Update
SELECT * FROM Motorbike
EXEC @status = uspUpdateMbike 'B0002','SLR8977B','Not Available','Bedok'
SELECT @status AS 'Error Message'
SELECT * FROM Motorbike
GO

-- Create Motorbike
CREATE PROC uspCreateMbike (
    @bike_plate_number VARCHAR(8),
    @bike_brand VARCHAR(15), 
    @bike_model VARCHAR(20), 
    @bike_engine_cc DECIMAL(5,1), 
    @bike_status VARCHAR(15), 
    @stat_address VARCHAR(100), 
    @bike_id CHAR(5) OUTPUT
)
AS
BEGIN
	-- Checks for any errors during execution
    IF @@ERROR <> 0 
    BEGIN
        SELECT 'Error occurred during execution' AS 'Unable to create';
        RETURN -216;
    END

	-- Checks if the specified Motorbike plate number already exists in the system
    IF EXISTS (SELECT * FROM Motorbike WHERE bike_plate_number = @bike_plate_number) 
    BEGIN
        SELECT 'Motorbike plate number already exists in the system' AS 'Unable to create';
        RETURN -212; -- Existing plate number
    END

	-- Checks if the specified Motorbike status is valid
    IF @bike_status != 'Available' AND @bike_status != 'Not Available' 
    BEGIN
        SELECT 'Invalid Motorbike status given' AS 'Unable to create';
        RETURN -207; -- Invalid bike status
    END

	-- Checks if the specified BikeStation address exists in the system
    IF NOT EXISTS (SELECT * FROM BikeStation WHERE stat_address = @stat_address) 
    BEGIN
        SELECT 'Motorbike station address does not exist in the system' AS 'Unable to create';
        RETURN -209; -- Station address doesn't exist
    END

	-- Checks if the specified Motorbike plate number is valid
    IF (LEN(@bike_plate_number) != 8) OR (PATINDEX('[A-Z][A-Z][A-Z][0-9][0-9][0-9][0-9][A-Z]', @bike_plate_number) = 0) 
    BEGIN
        SELECT 'Invalid Motorbike plate number given' AS 'Unable to create';
        RETURN -214; -- Invalid Plate number
    END

	-- Determines the category based on engine cc
    DECLARE @bike_cat CHAR(2); 
    IF @bike_engine_cc < 200
        SET @bike_cat = 'C1';
    ELSE IF @bike_engine_cc > 200
        SET @bike_cat = 'C3';
    ELSE 
        SET @bike_cat = 'C2';

	-- Generates a new bike ID
    DECLARE @max_bike_id INT;
    SELECT @max_bike_id = ISNULL(MAX(CAST(SUBSTRING(bike_id, 2, LEN(bike_id) - 1) AS INT)), 0) FROM Motorbike;

    DECLARE @bike_id_suffix VARCHAR(4);
    SET @bike_id_suffix = RIGHT('0000' + CAST(@max_bike_id + 1 AS VARCHAR(4)), 4);
    SET @bike_id = 'B' + @bike_id_suffix;

	-- Gets the BikeStation ID for the specified station address
    DECLARE @bike_station CHAR(3); 
    SELECT @bike_station = stat_id
    FROM BikeStation
    WHERE stat_address = @stat_address;

	-- Inserts the new Motorbike record into the Motorbike table
    INSERT INTO Motorbike (bike_id, bike_plate_number, bike_brand, bike_model, bike_engine_cc, bike_status, bike_category, bike_station) 
    VALUES (@bike_id, UPPER(@bike_plate_number), @bike_brand, @bike_model, @bike_engine_cc, @bike_status, @bike_cat, @bike_station);

    RETURN;
END;
GO

--DROP PROC uspCreateMbike
--GO

-- Testing

SELECT * FROM Motorbike -- Invalid MotorbikePlateNumber (Error -212 | MotorbikePlateNumber already exists in the system)
DECLARE @status INT, @bike_id CHAR(5)
EXEC @status = uspCreateMbike 'FAG7777G','Porsche','Cayenne','200','Available','Woodlands', @bike_id OUTPUT
SELECT @status AS 'Error Message', @bike_id AS 'Motorbike ID' 
SELECT * FROM Motorbike 
GO  

SELECT * FROM Motorbike -- Invalid BikeStatus (Error -207 | MotorbikeStatus in Invalid Format)
DECLARE @status INT, @bike_id CHAR(5)
EXEC @status = uspCreateMbike 'SFF6667GH','Porsche','Cayenne','200','Avails','Woodlands', @bike_id OUTPUT
SELECT @status AS 'Error Message', @bike_id AS 'Motorbike ID' 
SELECT * FROM Motorbike 
GO  

SELECT * FROM Motorbike -- Motorbike Invalid BikeStationAddress (Error -209 | MotorbikeStationAddress does not exist in the system)
DECLARE @status INT, @bike_id CHAR(5)
EXEC @status = uspCreateMbike 'SFF6667GH','Porsche','Cayenne','200','Available','Paris', @bike_id OUTPUT
SELECT @status AS 'Error Message', @bike_id AS 'Motorbike ID' 
SELECT * FROM Motorbike 
GO  

SELECT * FROM Motorbike -- Invalid BikePlateNumber (Error -214 | MotorbikePlateNumber in Invalid Format)
DECLARE @status INT, @bike_id CHAR(5)
EXEC @status = uspCreateMbike 'SF06667GH','Porsche','Cayenne','200','Available','Woodlands', @bike_id OUTPUT
SELECT @status AS 'Error Message', @bike_id AS 'Motorbike ID' 
SELECT * FROM Motorbike 
GO  

SELECT * FROM Motorbike -- Successful Creation
DECLARE @status INT, @bike_id CHAR(5)
EXEC @status = uspCreateMbike 'SFF6667GH','Porsche','Cayenne','200','Available','Woodlands', @bike_id OUTPUT
SELECT @status AS 'Error Message', @bike_id AS 'Motorbike ID' 
SELECT * FROM Motorbike 
GO  

-- Select Motorbike
CREATE PROCEDURE uspSelectMbike 
    @bike_id CHAR(5) = 'ALL',
    @bike_plate_number VARCHAR(8) = 'ALL',
    @bike_brand VARCHAR(15) = 'ALL',
    @bike_model VARCHAR(20) = 'ALL',
    @bike_status VARCHAR(15) = 'ALL',
    @bike_category CHAR(3) = 'ALL',
    @stat_address VARCHAR(100) = 'ALL',
    @stat_zone VARCHAR(7) = 'ALL'
AS
BEGIN
    -- Checks for any errors during execution
	IF @@ERROR <> 0
    BEGIN
        SELECT 'Error occurred during execution' AS 'Unable to select';
        RETURN -216;
    END

	-- Checks if the specified Motorbike ID exists in the system
    IF NOT EXISTS (SELECT * FROM Motorbike WHERE bike_id = @bike_id) AND @bike_id != 'ALL'
    BEGIN
        SELECT 'Motorbike ID does not exist in the system' AS 'Unable to select';
        RETURN -201; -- Bike ID doesn't exist
    END

	-- Checks if the specified Motorbike plate number exists in the system
    IF NOT EXISTS (SELECT * FROM Motorbike WHERE bike_plate_number = @bike_plate_number) AND @bike_plate_number != 'ALL'
    BEGIN
        SELECT 'Motorbike plate number does not exist in the system' AS 'Unable to select';
        RETURN -202; -- Plate number doesn't exists
    END

	-- Checks if the specified Motorbike brand exists in the system
    IF NOT EXISTS (SELECT * FROM Motorbike WHERE bike_brand = @bike_brand) AND @bike_brand != 'ALL'
    BEGIN
        SELECT 'Motorbike brand does not exist in the system' AS 'Unable to select';
        RETURN -204; -- Bike brand doesn't exist
    END

	-- Checks if the specified Motorbike model exists in the system
    IF NOT EXISTS (SELECT * FROM Motorbike WHERE bike_model = @bike_model) AND @bike_model != 'ALL'
    BEGIN
        SELECT 'Motorbike model does not exist in the system' AS 'Unable to select';
        RETURN -205; -- Bike model doesn't exist
    END

	-- Checks if the specified Motorbike status is valid
    IF (@bike_status != 'Available' AND @bike_status != 'Not Available') AND @bike_status != 'ALL'
    BEGIN
        SELECT 'Invalid Motorbike status given' AS 'Unable to select';
        RETURN -207; -- Invalid bike status
    END

	-- Checks if the specified Motorbike category is valid
    IF NOT EXISTS (SELECT * FROM BikeCategory WHERE cat_id = @bike_category) AND @bike_category != 'ALL'
    BEGIN
        SELECT 'Invalid Motorbike category given' AS 'Unable to select';
        RETURN -210; -- Invalid bike category
    END

	-- Checks if the specified BikeStation address exists in the system
    IF NOT EXISTS (SELECT * FROM BikeStation WHERE stat_address = @stat_address) AND @stat_address != 'ALL'
    BEGIN
        SELECT 'Motorbike station address does not exist in the system' AS 'Unable to select';
        RETURN -209; -- Station address doesn't exist
    END

	-- Checks if the specified BikeStation zone exists in the system
    IF NOT EXISTS (SELECT * FROM BikeStation WHERE stat_zone = @stat_zone) AND @stat_zone != 'ALL'
    BEGIN
        SELECT 'Motorbike station zone does not exist in the system' AS 'Unable to select';
        RETURN -215; -- Station zone doesn't exist
    END

	-- Declares the variables for filtering criteria
    DECLARE @id CHAR(5), @plate_number VARCHAR(8), @brand VARCHAR(15), @model VARCHAR(20), @status VARCHAR(15), @category CHAR(2), @address VARCHAR(100), @zone VARCHAR(7);

	-- Sets the variables based on specified values or NULL if 'ALL' for selection
    SET @id = CASE WHEN @bike_id != 'ALL' THEN @bike_id ELSE NULL END;
    SET @plate_number = CASE WHEN @bike_plate_number != 'ALL' THEN @bike_plate_number ELSE NULL END;
    SET @brand = CASE WHEN @bike_brand != 'ALL' THEN @bike_brand ELSE NULL END;
    SET @model = CASE WHEN @bike_model != 'ALL' THEN @bike_model ELSE NULL END;
    SET @status = CASE WHEN @bike_status != 'ALL' THEN @bike_status ELSE NULL END;
    SET @category = CASE WHEN @bike_category != 'ALL' THEN @bike_category ELSE NULL END;
    SET @address = CASE WHEN @stat_address != 'ALL' THEN @stat_address ELSE NULL END;
    SET @zone = CASE WHEN @stat_zone != 'ALL' THEN @stat_zone ELSE NULL END;

	-- Selects the Motorbikes based on specified criteria
    IF @bike_id = 'ALL' AND @bike_plate_number = 'ALL' AND @bike_brand = 'ALL' AND @bike_model = 'ALL' AND @bike_status = 'ALL' AND @bike_category = 'ALL' AND @stat_address = 'ALL' AND @stat_zone = 'ALL'
        SELECT * FROM Motorbike m
        INNER JOIN BikeStation s ON m.bike_station = s.stat_id;
    ELSE
        SELECT * FROM Motorbike m
        INNER JOIN BikeStation s ON m.bike_station = s.stat_id
        WHERE bike_id = @id OR bike_plate_number = @plate_number OR bike_brand = @brand OR bike_model = @model OR bike_status = @status OR bike_category = @category OR stat_address = @address OR stat_zone = @zone;
END;
GO

--DROP PROC uspSelectMbike
--GO

-- Testing

DECLARE @status INT -- Invalid BikeID (Error -201 | MotorbikeID does not exist in the system)
EXEC @status = uspSelectMbike 'B001','ALL','ALL','ALL','ALL','ALL','ALL','ALL'
SELECT @status AS 'Error Message'
GO  

DECLARE @status INT -- Invalid BikePlatenumber (Error -202 | MotorbikePlateNuumber does not exist in the system)
EXEC @status = uspSelectMbike 'B0001','SAP6666F','ALL','ALL','ALL','ALL','ALL','ALL'
SELECT @status AS 'Error Message'
GO  

DECLARE @status INT -- Invalid BikeBrand (Error -204 | MotorbikeBrand does not exist in the system)
EXEC @status = uspSelectMbike 'B0001','FAF6666F','Tesla','ALL','ALL','ALL','ALL','ALL'
SELECT @status AS 'Error Message'
GO  

DECLARE @status INT -- Invalid BikeModel (Error -205 | MotorbikeModel does not exist in the system)
EXEC @status = uspSelectMbike 'B0001','FAF6666F','Honda','Crayon','ALL','ALL','ALL','ALL'
SELECT @status AS 'Error Message'
GO  

DECLARE @status INT -- Invalid BikeStatus (Error -207 | MotorbikeStatus in Invalid Format)
EXEC @status = uspSelectMbike 'B0001','FAF6666F','Honda','Fino','Not Avail','ALL','ALL','ALL'
SELECT @status AS 'Error Message'
GO  

DECLARE @status INT -- Invalid BikeCategory (Error -210 | MotorbikeCategory does not exist in the system)
EXEC @status = uspSelectMbike 'B0001','FAF6666F','Honda','Fino','Not Available','D2','ALL','ALL'
SELECT @status AS 'Error Message'
GO  

DECLARE @status INT -- Invalid BikeStationAddress (Error -209 | MotorbikeStationAddress does not exist in the system)
EXEC @status = uspSelectMbike 'B0001','FAF6666F','Honda','Fino','Not Available','C3','Chinatown','ALL'
SELECT @status AS 'Error Message'
GO  

DECLARE @status INT -- Invalid BikeStationZone (Error -215 | MotorbikeStationZone does not exist in the system)
EXEC @status = uspSelectMbike 'B0001','FAF6666F','Honda','Fino','Not Available','C3','Clementi','North-East'
SELECT @status AS 'Error Message'
GO  

DECLARE @status INT -- Successful Selection
EXEC @status = uspSelectMbike 'ALL','ALL','Yamaha','ALL','ALL','ALL','ALL','East'
SELECT @status AS 'Error Message'
GO  

-- Check Motorbike Availability
CREATE PROC uspCheckMbikeAvailability (
    @bike_id CHAR(5), 
    @stat_address VARCHAR(100)
)
AS
BEGIN
	-- Checks for any errors during execution
    IF @@ERROR <> 0
    BEGIN
        SELECT 'Error occurred during execution' AS 'Unable to check';
        RETURN -216;
    END

	-- Checks if the specified Motorbike ID exists in the system
    IF NOT EXISTS (SELECT * FROM Motorbike WHERE bike_id = @bike_id)
    BEGIN
        SELECT 'Motorbike ID does not exist' AS 'Unable to check';
        RETURN -201; -- Bike ID doesn't exist
    END

	-- Checks if the specified BikeStation address exists in the system
    IF NOT EXISTS (SELECT * FROM BikeStation WHERE stat_address = @stat_address)
    BEGIN
        SELECT 'Motorbike station address does not exist in the system' AS 'Unable to check';
        RETURN -209; -- Station address doesn't exist
    END

	-- Checks if the specified Motorbike is in the specified station address
    IF (SELECT stat_address
        FROM BikeStation s
        INNER JOIN Motorbike m ON s.stat_id = m.bike_station
        WHERE bike_id = @bike_id) != @stat_address
    BEGIN
        SELECT 'Motorbike not in station address' AS 'Unable to check';
        RETURN -213; -- Bike not in this station
    END

	-- Checks if the specified Motorbike is available
    IF (SELECT bike_status
        FROM Motorbike
        WHERE bike_id = @bike_id) = 'Available'
    BEGIN
        SELECT bike_id, bike_plate_number, bike_brand, bike_model, bike_engine_cc, cat_licence_class, stat_address, cat_rental_rate
        FROM Motorbike m
        INNER JOIN BikeStation s ON m.bike_station = s.stat_id
        INNER JOIN BikeCategory c ON m.bike_category = c.cat_id
        WHERE bike_id = @bike_id;
    END
    ELSE
    BEGIN
		-- Returns other available Motorbike details in the specified station address
        SELECT bike_id, bike_plate_number, bike_brand, bike_model, bike_engine_cc, cat_licence_class, stat_address, cat_rental_rate
        FROM Motorbike m
        INNER JOIN BikeStation s ON m.bike_station = s.stat_id
        INNER JOIN BikeCategory c ON m.bike_category = c.cat_id
        WHERE bike_status = 'Available' AND stat_address = @stat_address
        GROUP BY cat_licence_class, bike_brand, bike_model, bike_engine_cc, bike_id, bike_plate_number, bike_status, stat_address, cat_rental_rate;
    END

    RETURN;
END;
GO

--DROP PROC uspCheckMbikeAvailability
--GO

-- Testing

SELECT * FROM Motorbike
DECLARE @status INT -- Invalid BikeID (Error -201 | MotorbikeID does not exist in the system)
EXEC @status = uspCheckMbikeAvailability 'B0050','Woodlands'
SELECT @status AS 'Error Message'
GO

DECLARE @status INT -- Invalid BikeStationAddress (Error -209 | MotorbikeStationAddress does not exist in the system)
EXEC @status = uspCheckMbikeAvailability 'B0005','Downtown'
SELECT @status AS 'Error Message'
GO

DECLARE @status INT -- Motorbike not found in station (Error -213 | Motorbike not in this Station Address)
EXEC @status = uspCheckMbikeAvailability 'B0005','Ang Mo Kio'
SELECT @status AS 'Error Message'
GO

DECLARE @status INT -- Successful Checking (Motorbike B0005 currently available)
EXEC @status = uspCheckMbikeAvailability 'B0005','Woodlands'
SELECT @status AS 'Error Message'
GO

DECLARE @status INT -- Successful Checking (Motorbike B0006 currently not available | other available bikes in the station address provided shown)
EXEC @status = uspCheckMbikeAvailability 'B0006','Woodlands'
SELECT @status AS 'Error Message'
GO

-- VIEWS

-- brand view 
CREATE VIEW MbikeBrandView
AS
SELECT bike_brand,bike_status,bike_model,bike_engine_cc,cat_licence_class,cat_rental_rate,cat_distance_rate,cat_late_penalty_rate,stat_address,bike_plate_number
FROM Motorbike m
INNER JOIN BikeStation s on m.bike_station = s.stat_id
INNER JOIN BikeCategory c on m.bike_category = c.cat_id
GROUP BY bike_brand, bike_status,bike_model,bike_engine_cc,cat_licence_class,cat_rental_rate,cat_distance_rate,cat_late_penalty_rate,stat_address,bike_plate_number
GO

--DROP VIEW MbikeBrandView
--GO

-- Testing

SELECT * FROM brandView -- Shows all 
GO

SELECT * FROM brandView WHERE bike_brand = 'Honda' -- Shows all Honda's 
GO

-- Bike Overview
CREATE VIEW MbikeOverview
AS
SELECT bike_plate_number,bike_brand,bike_model,bike_engine_cc,bike_status,cat_licence_class,cat_rental_rate,cat_distance_rate,cat_late_penalty_rate,stat_address
FROM Motorbike m
INNER JOIN BikeStation s on m.bike_station = s.stat_id
INNER JOIN BikeCategory c on m.bike_category = c.cat_id
GO

--DROP VIEW MbikeOverview
--GO

-- Testing

SELECT * FROM MbikeOverview -- Shows all 
GO

SELECT * FROM MbikeOverview WHERE cat_licence_class = '2' -- Shows all cat liscense class 2 Motorbikes 
GO

-- Motorbike By Category
CREATE VIEW MbikeCountByCategory
AS
SELECT bike_category, COUNT(*) AS TotalMotorbikes, cat_engine_cc, cat_rental_rate, cat_distance_rate, cat_late_penalty_rate
FROM Motorbike m
INNER JOIN BikeCategory c on m.bike_category = c.cat_id
GROUP BY bike_category, cat_engine_cc,cat_rental_rate, cat_distance_rate, cat_late_penalty_rate
GO

--DROP VIEW MbikeCountByCategory
--GO

-- Testing

SELECT * FROM MbikeCountByCategory -- Shows all 
GO

SELECT * FROM MbikeCountByCategory WHERE bike_category = 'C3' -- Shows all category 3 Motorbikes 
GO

-- Bike Availabilities
CREATE VIEW MbikeAvailabilities
AS
SELECT
    stat_zone,
    COUNT(*) AS 'Total Motorbikes',
    COUNT(CASE WHEN bike_status = 'Available' THEN 1 END) AS 'Total Motorbikes Available'
FROM Motorbike m
INNER JOIN BikeStation s ON m.bike_station = s.stat_id
INNER JOIN BikeCategory c ON m.bike_category = c.cat_id
GROUP BY stat_zone;
GO

--DROP VIEW MbikeAvailabilities
--GO

-- Testing

SELECT * FROM MbikeAvailabilities -- Shows all
GO

SELECT * FROM MbikeAvailabilities WHERE [Total Motorbikes] >=2 -- Shows all station zones with more than 1 motorbike
GO

-- Triggers

-- bike has been Inserted
CREATE TRIGGER insertedMbike
ON Motorbike
AFTER INSERT
AS
PRINT'Motorbike has been successfully inserted'
GO

--DROP TRIGGER insertedbike
--GO

-- Testing

SELECT * FROM Motorbike -- Motorbike has been successfully inserted 
DECLARE @status INT, @bike_id CHAR(5)
EXEC @status = uspCreateMbike 'SNA6623L','BMW','X5','200','Available','Bukit Merah', @bike_id OUTPUT
SELECT @status AS 'Error Message', @bike_id 
SELECT * FROM Motorbike 
GO  

-- bike has been updated
CREATE TRIGGER updatedMbike
ON Motorbike
AFTER UPDATE
AS
PRINT'Motorbike has been successfully updated'
GO

--DROP TRIGGER updatedbike
--GO

-- bike plate number has been updated
CREATE TRIGGER updatedMbikeplatenumber
ON Motorbike
AFTER UPDATE
AS
	IF UPDATE(bike_plate_number)
		PRINT'Motorbike plate number has been successfully updated'
GO

--DROP TRIGGER updatedbikeplatenumber
--GO

-- bike station has been updated
CREATE TRIGGER updatedMbikestation
ON Motorbike
AFTER UPDATE
AS
	IF UPDATE(bike_station)
		PRINT'bike station has been successfully updated'
GO

--DROP TRIGGER updatedbikestation
--GO
 
-- Testing

DECLARE @status INT -- Motorbike has been successfully updated | Motorbike plate number has been successfully updated | bike station has been successfully updated
SELECT * FROM Motorbike
EXEC @status = uspUpdateMbike 'B0001','SNA8222B','NIL','Bukit Batok'
SELECT @status AS 'Error Message'
SELECT * FROM Motorbike
GO

-- bike status has been updated
CREATE TRIGGER updatedMbikestatus
ON Motorbike
AFTER UPDATE
AS
	IF UPDATE(bike_status)
		PRINT'bike status has been successfully updated'
GO

--DROP TRIGGER updatedbikestatus
--GO

-- bike has been deleted
CREATE TRIGGER deletedMbike
ON Motorbike
INSTEAD OF DELETE
AS
    --IF @@ROWCOUNT > 0
    BEGIN
        PRINT 'Motorbike is now unavailable not deleted';
		UPDATE Motorbike
			SET bike_status = 'Not Available'
			WHERE bike_id IN (SELECT bike_id FROM deleted);
    END
GO

--DROP TRIGGER deletedbike
--GO

-- Testing

DELETE FROM Motorbike -- Motorbike is now unavailable not deleted | Motorbike has been successfully updated | bike status has been successfully updated
WHERE bike_id = 'B0007';
SELECT * FROM Motorbike
GO
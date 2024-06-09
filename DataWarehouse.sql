-- Create the Dimension Tables

CREATE TABLE DimCategory (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(64) NOT NULL,
    category_description TEXT
);

CREATE TABLE DimSupplier (
    supplier_id SERIAL PRIMARY KEY,
    supplier_name VARCHAR(64) NOT NULL,
    contact_info VARCHAR(64),
    country VARCHAR(64)
);

CREATE TABLE DimProduct (
    product_id SERIAL PRIMARY KEY,
    category_id INT NOT NULL,
    supplier_id INT NOT NULL,
    product_name VARCHAR(64) NOT NULL,
    product_description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (category_id) REFERENCES DimCategory(category_id),
    FOREIGN KEY (supplier_id) REFERENCES DimSupplier(supplier_id)
);

CREATE TABLE DimCustomer (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(32) NOT NULL,
    last_name VARCHAR(32) NOT NULL,
    email VARCHAR(64) NOT NULL,
    phone VARCHAR(32),
    address VARCHAR(64)
);

CREATE TABLE DimEmployee (
    employee_id SERIAL PRIMARY KEY,
    first_name VARCHAR(32) NOT NULL,
    last_name VARCHAR(32) NOT NULL,
    role VARCHAR(32) NOT NULL,
    contact_info VARCHAR(64)
);

CREATE TABLE DimDate (
    date_id SERIAL PRIMARY KEY,
    date DATE,
    day INT,
    month INT,
    year INT,
    quarter INT,
    week_of_year INT
);

-- Create the Fact Tables

CREATE TABLE FactOrders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL,
    product_id INT NOT NULL,
    order_date_id INT NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES DimCustomer(customer_id),
    FOREIGN KEY (product_id) REFERENCES DimProduct(product_id),
    FOREIGN KEY (order_date_id) REFERENCES DimDate(date_id)
);

CREATE TABLE FactShipments (
    shipment_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL,
    shipment_date_id INT NOT NULL,
    status VARCHAR(32) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES FactOrders(order_id),
    FOREIGN KEY (shipment_date_id) REFERENCES DimDate(date_id)
);

CREATE TABLE FactInventory (
    inventory_id SERIAL PRIMARY KEY,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    location VARCHAR(64) NOT NULL,
    FOREIGN KEY (product_id) REFERENCES DimProduct(product_id)
);

-- SCD Type 2 for Products

-- Drop existing constraints if needed
ALTER TABLE DimProduct DROP CONSTRAINT IF EXISTS dimproduct_pkey;
ALTER TABLE DimProduct DROP COLUMN IF EXISTS product_id CASCADE;

-- Add new columns for SCD Type 2
ALTER TABLE DimProduct
ADD COLUMN product_scd_id SERIAL PRIMARY KEY,
ADD COLUMN start_date TIMESTAMP,
ADD COLUMN end_date TIMESTAMP,
ADD COLUMN current_flag BOOLEAN DEFAULT TRUE;

-- Create or replace the trigger function
CREATE OR REPLACE FUNCTION DimProduct_update_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF (OLD.price <> NEW.price OR OLD.product_description <> NEW.product_description) AND OLD.current_flag AND NEW.current_flag THEN
        
        UPDATE DimProduct
        SET end_date = current_timestamp,
            current_flag = FALSE
        WHERE product_scd_id = OLD.product_scd_id;

        
        INSERT INTO DimProduct (
            category_id, supplier_id, product_name, product_description, price, start_date, end_date, current_flag
        )
        VALUES (
            OLD.category_id, OLD.supplier_id, OLD.product_name, NEW.product_description, NEW.price,
            current_timestamp, '9999-12-31', TRUE
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
CREATE TRIGGER DimProduct_update
AFTER UPDATE ON DimProduct
FOR EACH ROW
EXECUTE FUNCTION DimProduct_update_trigger();

-- Example usage
UPDATE DimProduct SET price = 29.99 WHERE product_name = 'Classic Acrylics Set' AND current_flag = TRUE;

CREATE OR REPLACE FUNCTION load_data_to_warehouse()
RETURNS VOID AS $$
BEGIN
    -- Insert into DimCategory
    INSERT INTO DimCategory (category_name, category_description)
    SELECT DISTINCT 
        CAST(category_name AS VARCHAR(64)), 
        CAST(category_description AS TEXT)
    FROM TempFile1;

    -- Insert into DimSupplier
    INSERT INTO DimSupplier (supplier_name, contact_info, country)
    SELECT DISTINCT 
        CAST(supplier_name AS VARCHAR(64)), 
        CAST(supplier_contact_info AS VARCHAR(64)),
        CAST(country AS VARCHAR(64))
    FROM TempFile2;

    -- Insert into DimProduct
    INSERT INTO DimProduct (category_id, supplier_id, product_name, product_description, price, start_date, end_date, current_flag)
    SELECT DISTINCT 
        c.category_id, 
        s.supplier_id, 
        CAST(product_name AS VARCHAR(64)), 
        CAST(product_description AS TEXT),
        CAST(product_price AS DECIMAL(10, 2)),
        current_timestamp,
        '9999-12-31',
        TRUE
    FROM TempFile1 t1
    JOIN DimCategory c ON t1.category_name = c.category_name
    JOIN DimSupplier s ON s.supplier_name = (
        SELECT supplier_name 
        FROM DimSupplier 
        ORDER BY random() 
        LIMIT 1
    );

    -- Insert into DimCustomer
    INSERT INTO DimCustomer (first_name, last_name, email, phone, address)
    SELECT DISTINCT 
        CAST(first_name AS VARCHAR(32)),
        CAST(last_name AS VARCHAR(32)),
        CAST(email AS VARCHAR(64)),
        CAST(phone AS VARCHAR(32)),
        CAST(address AS VARCHAR(64))
    FROM TempFile2;

    -- Insert into DimEmployee
    INSERT INTO DimEmployee (first_name, last_name, role, contact_info)
    SELECT DISTINCT 
        CAST(employee_name AS VARCHAR(32)), 
        CAST(employee_surname AS VARCHAR(32)), 
        CAST(role AS VARCHAR(32)), 
        CAST(employee_contact_info AS VARCHAR(64))
    FROM TempFile2;

    -- Insert into DimDate
    INSERT INTO DimDate (date, day, month, year, quarter, week_of_year)
    SELECT DISTINCT 
        CAST(order_date AS DATE),
        EXTRACT(DAY FROM CAST(order_date AS DATE)),
        EXTRACT(MONTH FROM CAST(order_date AS DATE)),
        EXTRACT(YEAR FROM CAST(order_date AS DATE)),
        EXTRACT(QUARTER FROM CAST(order_date AS DATE)),
        EXTRACT(WEEK FROM CAST(order_date AS DATE))
    FROM TempFile1;

    -- Insert into FactOrders
    INSERT INTO FactOrders (customer_id, product_id, order_date_id, total_amount)
    SELECT DISTINCT 
        c.customer_id, 
        p.product_id, 
        d.date_id,
        CAST(total_amount AS DECIMAL(10, 2))
    FROM TempFile1 t1
    JOIN DimProduct p ON t1.product_name = p.product_name
    JOIN DimCustomer c ON c.email = (
        SELECT email 
        FROM DimCustomer 
        ORDER BY random() 
        LIMIT 1
    )
    JOIN DimDate d ON d.date = CAST(order_date AS DATE);

    -- Insert into FactShipments
    INSERT INTO FactShipments (order_id, shipment_date_id, status)
    SELECT DISTINCT 
        o.order_id, 
        d.date_id,
        CAST(shipment_status AS VARCHAR(32))
    FROM TempFile1 t1
    JOIN FactOrders o ON o.product_id = (SELECT product_id FROM DimProduct WHERE product_name = t1.product_name LIMIT 1)
    JOIN DimDate d ON d.date = CAST(shipment_date AS DATE);

    -- Insert into FactInventory
    INSERT INTO FactInventory (product_id, quantity, location)
    SELECT DISTINCT 
        p.product_id, 
        CAST(inventory_quantity AS INT),
        CAST(inventory_location AS VARCHAR(64))
    FROM TempFile1 t1
    JOIN DimProduct p ON t1.product_name = p.product_name;

    -- Drop temporary tables
    DROP TABLE TempFile1;
    DROP TABLE TempFile2;

END;
$$ LANGUAGE plpgsql;

-- Call the function to load data
SELECT load_data_to_warehouse();
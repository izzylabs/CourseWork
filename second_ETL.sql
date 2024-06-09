-- View all extensions
SELECT * FROM pg_extension;

-- Install the required extension
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- Create a foreign server that connects to 'datawarehouse'
CREATE SERVER same_server_postgres
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'localhost', dbname 'CourseWork', port '5432');

-- Create a user mapping for the current user
CREATE USER MAPPING FOR CURRENT_USER
    SERVER same_server_postgres
    OPTIONS (user 'postgres', password '220073dsi');

-- Import tables from the remote database into the local schema
IMPORT FOREIGN SCHEMA public
FROM SERVER same_server_postgres
INTO public;

-- Check if import works
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public';

-- Create function to transfer data to data warehouse
CREATE OR REPLACE FUNCTION transferring_data()
RETURNS void AS $$
BEGIN
    -- Transferring data from categories to DimCategory
    INSERT INTO DimCategory (category_name, category_description)
    SELECT c.Category_Name, c.Category_Description
    FROM public.categories c
    LEFT JOIN DimCategory dc ON c.Category_Name = dc.category_name
    WHERE dc.category_name IS NULL;

    -- Transferring data from suppliers to DimSupplier
    INSERT INTO DimSupplier (supplier_name, contact_info, country)
    SELECT s.Supplier_Name, s.Contact_Info, s.Country
    FROM public.suppliers s
    LEFT JOIN DimSupplier ds ON s.Supplier_Name = ds.supplier_name
    WHERE ds.supplier_name IS NULL;

    -- Transferring data from products to DimProduct
    INSERT INTO DimProduct (category_id, supplier_id, product_name, product_description, price)
    SELECT 
        c.category_id,
        s.supplier_id,
        p.Product_Name,
        p.Product_Description,
        p.Price
    FROM public.products p
    JOIN DimCategory c ON p.CategoryID = c.category_id
    JOIN DimSupplier s ON p.SupplierID = s.supplier_id
    LEFT JOIN DimProduct dp ON p.Product_Name = dp.product_name
    WHERE dp.product_name IS NULL;

    -- Transferring data from customers to DimCustomer
    INSERT INTO DimCustomer (first_name, last_name, email, phone, address)
    SELECT c.First_Name, c.Last_Name, c.Email, c.Phone, c.Address
    FROM public.customers c
    LEFT JOIN DimCustomer dc ON c.Email = dc.email
    WHERE dc.email IS NULL;

    -- Transferring data from employees to DimEmployee
    INSERT INTO DimEmployee (first_name, last_name, role, contact_info)
    SELECT e.First_Name, e.Last_Name, e.Role, e.Contact_Info
    FROM public.employees e
    LEFT JOIN DimEmployee de ON e.Contact_Info = de.contact_info
    WHERE de.contact_info IS NULL;

    -- Transferring data from orders to FactOrders
    INSERT INTO FactOrders (customer_id, product_id, order_date, total_amount)
    SELECT 
        c.customer_id,
        p.product_id,
        o.Order_Date,
        o.Total_Amount
    FROM public.orders o
    JOIN DimCustomer c ON o.CustomerID = c.customer_id
    JOIN DimProduct p ON o.ProductID = p.product_id
    LEFT JOIN FactOrders fo ON o.OrderID = fo.order_id
    WHERE fo.order_id IS NULL;

    -- Transferring data from shipments to FactShipments
    INSERT INTO FactShipments (order_id, shipment_date, status)
    SELECT 
        o.order_id,
        s.Shipment_Date,
        s.Status
    FROM public.shipments s
    JOIN FactOrders o ON s.OrderID = o.order_id
    LEFT JOIN FactShipments fs ON s.ShipmentID = fs.shipment_id
    WHERE fs.shipment_id IS NULL;

    -- Transferring data from inventory to FactInventory
    INSERT INTO FactInventory (product_id, quantity, location)
    SELECT 
        p.product_id,
        i.Quantity,
        i.Location
    FROM public.inventory i
    JOIN DimProduct p ON i.ProductID = p.product_id
    LEFT JOIN FactInventory fi ON i.InventoryID = fi.inventory_id
    WHERE fi.inventory_id IS NULL;

END;
$$ LANGUAGE plpgsql;

-- Call the function to transfer data
SELECT transferring_data();

-- Check data in dimension and fact tables
SELECT * FROM DimCategory;
SELECT * FROM DimSupplier;
SELECT * FROM DimProduct;
SELECT * FROM DimCustomer;
SELECT * FROM DimEmployee;
SELECT * FROM FactOrders;
SELECT * FROM FactShipments;
SELECT * FROM FactInventory;
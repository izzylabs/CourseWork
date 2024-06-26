CREATE FUNCTION load_data_from_csv(
    file1_path TEXT,
    file2_path TEXT
)
RETURNS VOID AS $$
BEGIN
    -- Create temporary tables
    CREATE TEMP TABLE TempFile1 (
        category_name TEXT,
        category_description TEXT,
        product_name TEXT,
        product_description TEXT,
        product_price TEXT,
        product_stock_quantity TEXT,
        inventory_quantity TEXT,
        inventory_location TEXT,
        order_date TEXT,
        order_total_amount TEXT,
        shipment_date TEXT,
        shipment_status TEXT
    );

    CREATE TEMP TABLE TempFile2 (
        first_name TEXT,
        last_name TEXT,
        email TEXT,
        phone TEXT,
        address TEXT,
        supplier_name TEXT,
        supplier_contact_info TEXT,
        country TEXT,
        employee_name TEXT,
        employee_surname TEXT,
        role TEXT,
        employee_contact_info TEXT
    );
    
    -- Load data into temporary tables
    EXECUTE FORMAT('COPY TempFile1 (category_name, category_description, product_name, product_description, price, stock_quantity, inventory_quantity, location, order_date, total_amount, shipment_date, status) FROM %L DELIMITER '','' CSV HEADER', file1_path);
	EXECUTE FORMAT('COPY TempFile2 (first_name, last_name, email, address, supplier_name, contact_info, country, employee_name, employee_surname, role, employee_contact_info) FROM %L DELIMITER '','' CSV HEADER', file2_path);

    -- Insert into Categories
    INSERT INTO Categories (Category_Name, Category_Description)
    SELECT DISTINCT 
        CAST(category_name AS VARCHAR(64)), 
        CAST(category_description AS TEXT)
    FROM TempFile1;

    -- Insert into Suppliers
    INSERT INTO Suppliers (Supplier_Name, Contact_Info, Country)
    SELECT DISTINCT 
        CAST(supplier_name AS VARCHAR(64)), 
        CAST(supplier_contact_info AS VARCHAR(64)),
        CAST(country AS VARCHAR(64))
    FROM TempFile2;

    -- Insert into Products
    INSERT INTO Products (CategoryID, SupplierID, Product_Name, Product_Description, Price, Stock_Quantity)
    SELECT DISTINCT 
        c.CategoryID, 
        s.SupplierID, 
        CAST(product_name AS VARCHAR(64)), 
        CAST(product_description AS TEXT),
        CAST(product_price AS DECIMAL(10, 2)),
        CAST(product_stock_quantity AS INT)
    FROM TempFile1 t1
    JOIN Categories c ON t1.category_name = c.Category_Name
    JOIN Suppliers s ON s.Supplier_Name = (
        SELECT Supplier_Name 
        FROM Suppliers 
        ORDER BY random() 
        LIMIT 1
    );

    -- Insert into Inventory
    INSERT INTO Inventory (ProductID, Quantity, Location)
    SELECT DISTINCT 
        p.ProductID, 
        CAST(inventory_quantity AS INT),
        CAST(inventory_location AS VARCHAR(64))
    FROM TempFile1 t1
    JOIN Products p ON t1.product_name = p.Product_Name;

    -- Insert into Customers
    INSERT INTO Customers (First_Name, Last_Name, Email, Phone, Address)
    SELECT DISTINCT 
        CAST(first_name AS VARCHAR(32)),
        CAST(last_name AS VARCHAR(32)),
        CAST(email AS VARCHAR(64)),
        CAST(phone AS VARCHAR(32)),
        CAST(address AS VARCHAR(64))
    FROM TempFile2;

    -- Insert into Orders
    INSERT INTO Orders (CustomerID, ProductID, Order_Date, Total_Amount)
    SELECT DISTINCT 
        c.CustomerID, 
        p.ProductID, 
        CAST(order_date AS DATE),
        CAST(total_amount AS DECIMAL(10, 2))
    FROM TempFile1 t1
    JOIN Products p ON t1.product_name = p.Product_Name
    CROSS JOIN Customers c
    LIMIT 100;

    -- Insert into Shipments
    INSERT INTO Shipments (OrderID, Shipment_Date, Status)
    SELECT DISTINCT 
        o.OrderID, 
        CAST(shipment_date AS DATE),
        CAST(shipment_status AS VARCHAR(32))
    FROM TempFile1 t1
    JOIN Orders o ON o.ProductID = (SELECT ProductID FROM Products WHERE Product_Name = t1.product_name LIMIT 1);

    -- Insert into Employees
    INSERT INTO Employees (First_Name, Last_Name, Role, Contact_Info)
    SELECT DISTINCT 
        CAST(employee_name AS VARCHAR(32)), 
        CAST(employee_surname AS VARCHAR(32)), 
        CAST(role AS VARCHAR(32)), 
        CAST(employee_contact_info AS VARCHAR(64))
    FROM TempFile2;

    -- Drop temporary tables
    DROP TABLE TempFile1;
    DROP TABLE TempFile2;

END
$$ LANGUAGE plpgsql;

-- Call the function
SELECT * FROM load_data_from_csv('C:/Users/dasha/Documents/Epam/Databases/CourseWork/file1.csv', 'C:/Users/dasha/Documents/Epam/Databases/CourseWork/file2.csv');


SELECT * FROM categories
SELECT * FROM customers
SELECT * FROM employees
SELECT * FROM inventory
SELECT * FROM orders 
SELECT * FROM products
SELECT * FROM shipments
SELECT * FROM suppliers

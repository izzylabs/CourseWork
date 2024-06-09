-- Create the Customers table
CREATE TABLE Customers (
    CustomerID SERIAL PRIMARY KEY,
    First_Name VARCHAR(32) NOT NULL,
    Last_Name VARCHAR(32) NOT NULL,
    Email VARCHAR(64) NOT NULL,
    Phone VARCHAR(32),
    Address VARCHAR(64)
);

-- Create the Categories table
CREATE TABLE Categories (
    CategoryID SERIAL PRIMARY KEY,
    Category_Name VARCHAR(64) NOT NULL,
    Category_Description TEXT
);

-- Create the Suppliers table
CREATE TABLE Suppliers (
    SupplierID SERIAL PRIMARY KEY,
    Supplier_Name VARCHAR(64) NOT NULL,
    Contact_Info VARCHAR(64),
    Country VARCHAR(64)
);

-- Create the Products table
CREATE TABLE Products (
    ProductID SERIAL PRIMARY KEY,
    CategoryID INT NOT NULL,
    SupplierID INT NOT NULL,
    Product_Name VARCHAR(64) NOT NULL,
    Product_Description TEXT,
    Price DECIMAL(10, 2) NOT NULL,
    Stock_Quantity INT NOT NULL,
    FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID),
    FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID)
);

-- Create the Inventory table
CREATE TABLE Inventory (
    InventoryID SERIAL PRIMARY KEY,
    ProductID INT NOT NULL,
    Inventory_Quantity INT NOT NULL,
    Location VARCHAR(64) NOT NULL,
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

-- Create the Orders table
CREATE TABLE Orders (
    OrderID SERIAL PRIMARY KEY,
    CustomerID INT NOT NULL,
    ProductID INT NOT NULL,
    Order_Date DATE NOT NULL,
    Total_Amount DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

-- Create the Shipments table
CREATE TABLE Shipments (
    ShipmentID SERIAL PRIMARY KEY,
    OrderID INT NOT NULL,
    Shipment_Date DATE,
    Status VARCHAR(32) NOT NULL,
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID)
);

-- Create the Employees table
CREATE TABLE Employees (
    EmployeeID SERIAL PRIMARY KEY,
    Employee_Name VARCHAR(32) NOT NULL,
    Employee_Surmane VARCHAR(32) NOT NULL,
    Role VARCHAR(32) NOT NULL,
    Contact_Info VARCHAR(64)
);


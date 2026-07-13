
CREATE SCHEMA IF NOT EXISTS fmcg;
CREATE TABLE fmcg.categories(
    CategoryID INT PRIMARY KEY,
    CategoryName VARCHAR(45)
);
CREATE TABLE fmcg.countries(
    CountryID INT PRIMARY KEY,
    CountryName VARCHAR(45),
    CountryCode VARCHAR(2)
);
CREATE TABLE fmcg.cities(
    CityID INT PRIMARY KEY,
    CityName VARCHAR(45),
    Zipcode DECIMAL (5,0),
    CountryID INT,
    
    Foreign Key (CountryID) REFERENCES fmcg.countries(CountryID) 
);
CREATE TABLE fmcg.customers(
    CustomerID INT PRIMARY KEY,
    FirstName VARCHAR(45),
    MiddleInitial VARCHAR(1),
    LastName VARCHAR(45),
    cityID INT,
    Address VARCHAR(90),

    FOREIGN KEY (cityID) REFERENCES fmcg.cities(cityID)
);
CREATE TABLE fmcg.employees(
    EmployeeID INT PRIMARY KEY,
    FirstName VARCHAR(45),
    MiddleInitial VARCHAR(1),
    LastName VARCHAR(45),
    BirthDate DATE,
    Gender VARCHAR(10),
    CityID INT,
    HireDate Date,

    FOREIGN KEY (cityID) REFERENCES fmcg.cities(cityID)
);
CREATE TABLE fmcg.products(
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(45),
    Price DECIMAL(10,4),
    CategoryID INT,
    Class VARCHAR(45),
    ModifyDate DATE,
    Resistant VARCHAR(15),
    IsAllergic VARCHAR,
    VitalityDays DECIMAL(3,0),

    FOREIGN KEY(CategoryID) REFERENCES fmcg.categories(CategoryID)
);
CREATE TABLE fmcg.sales(
    SalesID INT PRIMARY KEY,
    SalesPersonID INT,
    CustomerID INT,
    ProductID INT,
    Quantity INT,
    Discount DECIMAL(10,2),
    TotalPrice Decimal(10,2),
    SalesDate TIMESTAMP,
    TransactionNumber VARCHAR(25),

    FOREIGN KEY(SalesPersonID) REFERENCES fmcg.employees(EmployeeID),
    FOREIGN KEY(CustomerID) REFERENCES fmcg.customers(CustomerID),
    Foreign Key (ProductID) REFERENCES fmcg.products(ProductID)
);
SELECT TABLE_NAME
FROM information_schema.tables
WHERE table_schema = 'fmcg'
ORDER BY table_name;


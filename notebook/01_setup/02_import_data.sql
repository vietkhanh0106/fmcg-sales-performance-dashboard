
\copy fmcg.categories(CategoryID, CategoryName)
FROM 'dataset/Dataset/categories.csv'
DELIMITER ',' CSV HEADER NULL 'NULL';

\copy fmcg.countries(CountryID, CountryName, CountryCode)
FROM 'dataset/Dataset/countries.csv'
DELIMITER ',' CSV HEADER NULL 'NULL';

\copy fmcg.cities(CityID, CityName, Zipcode, CountryID)
FROM 'dataset/Dataset/cities.csv'
DELIMITER ',' CSV HEADER NULL 'NULL';

\copy fmcg.customers(CustomerID, FirstName, MiddleInitial, LastName, CityID, Address)
FROM 'dataset/Dataset/customers.csv'
DELIMITER ',' CSV HEADER NULL 'NULL';

\copy fmcg.employees(EmployeeID, FirstName, MiddleInitial, LastName, BirthDate, Gender, CityID, HireDate)
FROM 'dataset/Dataset/employees.csv'
DELIMITER ',' CSV HEADER NULL 'NULL';

\copy fmcg.products(ProductID, ProductName, Price, CategoryID, Class, ModifyDate, Resistant, IsAllergic, VitalityDays)
FROM 'dataset/Dataset/products.csv'
DELIMITER ',' CSV HEADER NULL 'NULL';

\copy fmcg.sales(SalesID, SalesPersonID, CustomerID, ProductID, Quantity, Discount, TotalPrice, SalesDate, TransactionNumber)
FROM 'dataset/Dataset/sales.csv'
DELIMITER ',' CSV HEADER NULL 'NULL';


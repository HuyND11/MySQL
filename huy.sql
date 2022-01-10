create database Project_Huy;
use Project_huy;

create table Type_Products (	
	Type_Id varchar(5) primary key,
    Type_Name varchar(50)
    );
    
create table Brands(
	Brand_Id varchar(5) primary key,
    Brand_Name varchar(50)
    );
    
create table Products(
	Prod_Id varchar(5) primary key,
    Type_Id varchar(5),
    Brand_Id varchar(5),
    Prod_Name varchar(50),
    foreign key (Brand_Id) references Brands(Brand_Id),
    foreign key (Type_Id) references Type_Products(Type_Id)
    );
    
create table Providers(
	Prov_Id varchar(5) primary key,
    Prov_Name varchar(50),
    Address varchar(100),
    Phone_Number char(10),
    Email varchar(50)
    );
    
create table Employees(
	Emp_Id varchar(5) primary key,
    Emp_name varchar(50),
    Job_Name varchar(20),
    Address varchar(100),
    Phone_Number char(10),
    Email varchar(50),
    User_Name varchar(50),
    Password varchar(50)
    );
    
create table Customers(
	Cus_Id varchar(5) primary key,
    Cus_Name varchar(50),
    Address varchar(100),
    Phone_Number char(10),
    Email varchar(50),
    User_Name varchar(50),
    Password varchar(50)
    );
    
create table Bill_In(
	Bill_Id varchar(5) primary key,
    Prov_Id varchar(5),
    Emp_Id varchar(5),
    Date_Time datetime,
    foreign key (Prov_Id) references Providers(Prov_Id),
    foreign key (Emp_Id) references Employees(Emp_Id)
    );
    
create table Bill_Out(
	Bill_Id varchar(5) primary key,
    Cus_Id varchar(5),
    Emp_Id varchar(5),
    Date_Time datetime,
    foreign key (Cus_Id) references Customers(Cus_Id),
    foreign key (Emp_Id) references Employees(Emp_Id)
    );
    
create table Detail_Bill_In(
	Bill_Id varchar(5),
    Prod_Id varchar(5),
    Quantity int,
    Price float,
    primary key(Bill_Id,Prod_Id),
    foreign key (Bill_Id) references Bill_In(Bill_Id),
    foreign key (Prod_Id) references Products(Prod_Id)
    );
    
create table Detail_Bill_Out(
	Bill_Id varchar(5),
    Prod_Id varchar(5),
    Quantity int,
    Price float,
    primary key(Bill_Id,Prod_Id),
    foreign key (Bill_Id) references Bill_Out(Bill_Id),
    foreign key (Prod_Id) references Products(Prod_Id)
    );
    
create table Histories(
	His_Id int  auto_increment primary key,
    Event varchar(50),
    Date_Time datetime
    );
    
create view exp_sales 
as
	SELECT p.Prod_Id, b.Brand_Name, tp.Type_Name, p.Prod_Name, sum(dbo.quantity) as Sale, month(bo.date_time) as Months, year(bo.date_time) as years
    FROM detail_bill_out as dbo
    JOIN products as p
    on p.Prod_Id = dbo.Prod_Id
    join bill_out as bo
    ON bo.Bill_Id = dbo.Bill_Id
    JOIN brands as b
    on b.Brand_Id = p.Brand_Id
    JOIN type_products as tp
    on tp.Type_Id = p.Type_Id
    GROUP by p.Prod_Id
    order by sale desc;
    

create view average_imp_price as 
	select p.Prod_Id, p.prod_name, round(avg(dbi.price), 2) as average_price
    from products as p
    	join detail_bill_in as dbi on p.prod_id = dbi.prod_id
    group by p.prod_id
    order by average_price desc;
    
    
create view employees_do_not_import as
	select emp_id, emp_name 
    from employees
    where emp_id not in (select distinct Emp_Id from bill_in);
    

create view products_disappear_this_year as
	select prod_id, prod_name
	from products
	where prod_id not in (select dbi.prod_id from detail_bill_in as dbi
							join bill_in as bi on dbi.Bill_Id = bi.Bill_Id
						 where year(bi.date_time) = year(now()))
		  and 
		  prod_id not in (select dbo.prod_id from detail_bill_out as dbo
							join bill_out as bo on bo.Bill_Id = dbo.Bill_Id
						 where year(bo.date_time) = year(now()));
                         
                         
create view Revenue_Products
as
	SELECT DBo.Prod_Id, SUM(DBo.Quantity * DBO.Price) as Revenue
    FROM detail_bill_out as DBO
    JOIN bill_out as BO
    ON DBO.Bill_Id = BO.Bill_Id
    GROUP by dbo.prod_id, year(BO.Date_time);


    
CREATE TRIGGER `Insert_History(Envent_Insert)_Detail_Bill_In` AFTER INSERT ON `detail_bill_in`
 FOR EACH ROW BEGIN
	INSERT INTO histories (Event, date_time)
    VALUES
    	('Insert Detail_Bill_In', now())
END$$
DELIMITER ;

CREATE TRIGGER `Insert_History(Envent_Insert)_Detail_bill_out` BEFORE INSERT ON `detail_bill_out`
 FOR EACH ROW INSERT INTO histories (Event, date_time)
    VALUES
    	('Insert Detail_Bill_In', now());
        
        
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `Show_Sales_Each_month`(IN `Prod_Id` VARCHAR(5), IN `Month` INT)
BEGIN
	SELECT DBO.Prod_Id, DBO.Quantity
    FROM detail_bill_out as DBO
    JOIN bill_out as BO
    ON DBO.Bill_Id = BO.Bill_Id
    WHERE DBO.Prod_Id = Prod_Id and Month(BO.Date_time) = Month;
END$$
DELIMITER ;


DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `Show_Revenue_Each_Month`(IN `Prod_Id` VARCHAR(5), IN `Month` INT)
BEGIN
	SELECT DBo.Prod_Id, (DBo.Quantity * DBO.Price) as Revenue
    FROM detail_bill_out as DBO
    JOIN bill_out as BO
    ON DBO.Bill_Id = BO.Bill_Id
    WHERE DBO.Prod_Id = Prod_Id and Month(BO.Date_time) = Month;
END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `Show_Sales_Each_Year`(IN `Year` INT)
BEGIN
        SELECT prod_Id, Brand_Name, Type_Name, prod_name, sale
        FROM exp_sales
        WHERE sale = (SELECT max(sale) FROM exp_sales) AND years = year;
END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `Show_Revenue_Each_Year`(IN `Prod_Id` VARCHAR(5), IN `Year` INT)
BEGIN
	SELECT DBo.Prod_Id, SUM(DBo.Quantity * DBO.Price) as Revenue
    FROM detail_bill_out as DBO
    JOIN bill_out as BO
    ON DBO.Bill_Id = BO.Bill_Id
    WHERE year(BO.Date_time) = year and dbo.Prod_Id = prod_Id
    GROUP by dbo.prod_id, year(BO.Date_time);
END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `Quantity_Product_Sell_One-Day`(IN `Day` INT, IN `Month` INT)
BEGIN
	SELECT p.Prod_Id, tp.Type_Name,b.Brand_Name,p.Prod_Name, sum(dbo.Quantity) as Total
    FROM products as p 
    JOIN detail_bill_out as dbo
    ON dbo.Prod_Id = p.Prod_Id
    JOIN type_products as tp
    ON tp.Type_Id = p.Type_Id
    JOIN brands as b
    ON b.Brand_Id = p.Brand_Id
    JOIN bill_out as bo
    ON bo.Bill_Id = dbo.Bill_Id
    WHERE dayofmonth(bo.Date_Time) = Day and month(bo.Date_Time) = Month 
    GROUP BY dayofmonth(bo.Date_Time),p.Prod_Id;
END$$
DELIMITER ;

delimiter $$
drop trigger if exists Check_Inventory;
CREATE TRIGGER `Check_Inventory` AFTER INSERT ON `detail_bill_out`
 FOR EACH ROW BEGIN
	if (new.Quantity > (SELECT Quantity FROM products where Prod_id = new.Prod_Id)) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Not Enough Quantity';
    ELSE
        UPDATE products
        SET Quantity = Quantity - (new.Quantity)
        WHERE Prod_Id = new.Prod_Id;
    END IF;
END$$

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `Max_Sales_Each_Month`(IN `Month` INT)
BEGIN
        SELECT prod_Id, Brand_Name, Type_Name, prod_name, sale
        FROM exp_sales
        WHERE sale = (SELECT max(sale) FROM exp_sales) AND months = month;
END$$
DELIMITER ;

delimiter $$
CREATE TRIGGER `Insert_History(Envent_Insert)_Detail_Bill_In` AFTER INSERT ON `detail_bill_in`
 FOR EACH ROW BEGIN
	INSERT INTO histories (Event, date_time)
    VALUES
    	('Insert Detail_Bill_In', now());
END
delimiter $$

delimiter $$
CREATE TRIGGER `Insert_History(Envent_Insert)_Detail_bill_out` BEFORE INSERT ON `detail_bill_out`
 FOR EACH ROW INSERT INTO histories (Event, date_time)
    VALUES
    	('Insert Detail_Bill_In', now())
	
delimiter $$        
CREATE TRIGGER `Insert_Quantity_To_Products` AFTER INSERT ON `detail_bill_in`
 FOR EACH ROW BEGIN
	UPDATE products
    SET Quantity = (new.Quantity) + Quantity
    WHERE Prod_Id = new.Prod_Id
    ;
END$$


DELIMITER $$
CREATE DEFINER=`root`@`localhost` FUNCTION `Show_Sales_Each_Day`(`Prod_Id` VARCHAR(5), `Day` INT, `Month` INT) RETURNS int(11)
BEGIN
	RETURN( SELECT sum(dbo.Quantity) as Total
    FROM products as p 
    JOIN detail_bill_out as dbo
    ON dbo.Prod_Id = p.Prod_Id
    JOIN type_products as tp
    ON tp.Type_Id = p.Type_Id
    JOIN brands as b
    ON b.Brand_Id = p.Brand_Id
    JOIN bill_out as bo
    ON bo.Bill_Id = dbo.Bill_Id
    WHERE dayofmonth(bo.Date_Time) = Day and month(bo.Date_Time) = Month and p.Prod_Id = Prod_Id
    GROUP BY dayofmonth(bo.Date_Time));
END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER=`root`@`localhost` FUNCTION `Show_The_Times_Customer's_Export`(`Cus_Id` VARCHAR(5)) RETURNS int(11)
BEGIN
	RETURN (SELECT count(bill_out.cus_Id) FROM bill_out
            WHERE bill_out.cus_Id = Cus_Id
            GROUP BY bill_out.cus_Id);
END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER=`root`@`localhost` FUNCTION `Show_The_Times_Provider's_Import`(`Prov_Id` VARCHAR(5)) RETURNS int(11)
BEGIN
	RETURN (SELECT count(bill_in.prov_Id) FROM bill_in
            WHERE bill_in.prov_Id = Prov_Id
            GROUP BY bill_in.Prov_Id);
END$$
DELIMITER ;

   
INSERT INTO `customers` (`Cus_Id`, `Cus_Name`, `Address`, `Phone_Number`, `Email`, `User_Name`, `Password`) 
VALUES 
	('C01', 'Nguyễn Đức huy', '101B Lê Hữu Trác, phường Phước Mỹ, quận Sơn Trà, thành phố Đà Nẵng', '0971168760', 'huy.nguyen23@student.passerellesnumeriques.org', 'huy.nguyen23', 'Ronnguyenn2862@.'),
	('C02', 'Đinh Thị Nhi', '100/21/33 Lê Quan Binh, Quận 12, Thành Phố Hồ Chí Minh', '01678454875', 'Nhi.Dinh1998.Gmail.com', 'Nhi.Dinh1998', 'hahahaha'), 
	('C03', 'Võ Thị Kim Dung', '121 Hồng Lĩnh, phường Đập Đá, thị xã An Nhơn, tỉnh Bình Định', '01268754896', 'kim.dung1997.Gmail.com', 'kimdung1997', 'dungdung');

INSERT INTO `providers` (`Prov_Id`, `Prov_Name`, `Address`, `Phone_Number`, `Email`) 
VALUES 
	('P01', 'Nguyễn Thị Thảo Nguyên', 'Hải Lăng, Quảng Trị', '0397124293', 'nguyen.nguyen23@student.passerellesnumeriques.org'), 
	('P02', 'Đinh Thị Lai', 'thôn Trung Thành, xã Phước Lộc, huyện Tuy Phước, tỉnh Bình Định', '01236585495', 'Laidinh1962@gmail.com');
    
INSERT INTO `employees` (`Emp_Id`, `Emp_name`, `Job_Name`, `Address`, `Phone_Number`, `Email`, `User_Name`, `Password`) 
VALUES 
	('E01', 'John', 'Manager', '102 Royal street, Texas state, USA', '0332114585', 'Jonhny1123@gmail.com', 'John1123', '**********'), 
	('E02', 'Alex', 'Cashier', '2201 Panacan street, Ohio state, USA', '0122125487', 'Alex1212114@gmail.com', 'Alex1212114', '**********');

INSERT INTO `brands` (`Brand_Id`, `Brand_Name`) 
VALUES 
	('AD', 'Adidas'), 
	('NK', 'Nike'), 
	('PM', 'Puma'), 
	('VS', 'Vans');
    
INSERT INTO `type_products` (`Type_Id`, `Type_Name`) 
VALUES 
    ('SD', 'Sandals'), 
    ('AS', 'Athletic Shoes'), 
    ('FS', 'Football Shoes'), 
    ('SK', 'Sneaker');
    
    
INSERT INTO `products` (`Prod_Id`, `Type_Id`, `Brand_Id`, `Prod_Name`) 
VALUES 
    ('P01', 'AS', 'AD', 'Adidas - Pxs0202'), 
    ('P02', 'FS', 'VS', 'Vans - k001'), 
    ('P03', 'SD', 'PM', 'Puma - 0202'), 
    ('P04', 'SK', 'NK', 'Nike 360'), 
    ('P05', 'SD', 'NK', 'Sandal - Nike 2022'), 
    ('P06', 'FS', 'PM', 'Football Shoes - Puma');
    
INSERT INTO `bill_in` (`Bill_Id`, `Prov_Id`, `Emp_Id`, `Date_Time`) 
VALUES 
	('B01', 'P01', 'E01', '2021-10-15 12:29:01'), 
	('B02', 'P02', 'E01', '2021-10-18 07:29:01.000000');

INSERT INTO `detail_bill_in` (`Bill_Id`, `Prod_Id`, `Quantity`, `Price`) 
VALUES 
	('B01', 'P01', '20', '300'), 
	('B01', 'P02', '30', '500'), 
	('B02', 'P03', '30', '750'), 
	('B02', 'P05', '50', '350'), 
	('B02', 'P06', '100', '1000');
    
INSERT INTO `bill_out` (`Bill_Id`, `Cus_Id`, `Emp_Id`, `Date_Time`) 
VALUES 
('B01', 'C01', 'E01', '2021-10-18 07:39:13.000000');
    
    
INSERT INTO `detail_bill_out` (`Bill_Id`, `Prod_Id`, `Quantity`, `Price`) 
VALUES 
('B01', 'P01', '10', '300');


    

    
    


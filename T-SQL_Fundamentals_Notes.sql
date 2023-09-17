-- LOGICAL ORDER

/*	FROM
	WHERE
	GROUP BY
	HAVING
	SELECT
		Expressions
		DISTINCT
	ORDER BY
		TOP/OFFSET-FETCH	*/


-- TOP FILTER 

/*	Not standard and doesn't support a skipping capability 
	Proprietary T-SQL feature, used to limit the number or percentage of rows returned by a query
	If DISTINCT is used in the SELECT clause, the TOP filter is evaluated after duplicate rows have been removed	*/
SELECT TOP(5) orderid, orderdate, custid, empid 
FROM Sales.Orders
ORDER BY orderdate DESC;


-- TOP Filter with percentage
SELECT TOP(1) PERCENT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC; -- Adding orderid DESC here will make the ORDER BY list unique add provide a rule for ties.


-- TOP Filter WITH TIES
	-- Returns top 5 rows plus rows that have the same sort value(orderdate).
SELECT TOP(5) WITH TIES orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC;


-- OFFSET-FETCH FILTER

/*	Considered an extension of the ORDERBY clause 
	OFFSET = how many rows to skip, FETCH = how many rows to filter after the skipped rows	*/
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY  orderdate, orderid
OFFSET 50 ROWS FETCH NEXT 25 ROWS ONLY; -- You can use FIRST instead of NEXT
/*	FETCH cannot be used without OFFSET
	Does not support percentage and with ties option	*/


/*	The OVER clause exposes to the function a subset of the rows from the underlying queries result set 
	The Over clause can restrict the rows in the window by using a window partition subclass (PARTITION BY)
	It can define ordering for the calculation (if relevant) using a window order subclause (ORDER BY)	*/
SELECT orderid, custid, val,
	ROW_NUMBER() OVER(PARTITION BY custid
					ORDER BY val) AS rownum
FROM Sales.OrderValues
ORDER BY custid, val;


-- PREDICATES AND OPERATORS 
	-- IN Predicate = check wether a value or scalar expression is equal to at least one of the elements in a set.
SELECT orderid, empid, orderdate
FROM Sales.Orders
WHERE orderid IN(10248, 10249, 10250)

	-- BETWEEN Predicate = check wether a value is in a specified range
SELECT orderid, empid, orderdate
FROM Sales.Orders
WHERE orderid BETWEEN 10300 AND 10310

	-- LIKE Predicate = can check wether a character string value meets a specified pattern.
SELECT empid, firstname, lastname
FROM HR.Employees
WHERE lastname LIKE N'D%';
/*	N is used before 'D%' to denote that a character string is of a unicode data type (NCHAR or NVARCHAR)
	this is opposed to character data type (CHAR or VARCHAR) / N stands for National */

	-- T-SQL supports =,>,<,>=,<=,<>,!=,!<,!>,	of which the last 3 are not standard.
SELECT orderid, empid, orderdate
FROM Sales.Orders
WHERE orderdate >= '20160101';
/*	You can use logical operators AND/OR to combine logical expressions
	If you want to negate an expression you can use the NOT operator */
SELECT orderid, empid, orderdate
FROM Sales.Orders
WHERE orderdate >= '20160101'
		AND empid IN(1, 3, 5);

	-- Also supports arithmatic operators +,-,*,/, and modulo %
SELECT orderid, productid, qty, unitprice, discount,
	qty * unitprice * (1-discount) AS val 
FROM Sales.OrderDetails;

/*	If operands are of 2 different types, the one with the lower precedence is promoted to the higher 
	-- Operator Precedence Rules 
		1.) () parentheses
		2.) * multiplication,/ division,% modulo 
		3.) +(positive),-(negative),+(concatenation),+(addition),-(subtraction)
		4.) =,>,<,>=,<=,<>,!=,!<,!> Comparison Operators 
		5.) NOT
		6.) AND
		7.) BETWEEN, IN, LIKE, OR
		8.) = Assignment		*/
SELECT orderid, custid, empid, orderdate 
FROM Sales.Orders
WHERE
		custid = 1
	AND empid IN(1,3,5)
	OR custid = 85
	AND empid IN(2,4,6);
	-- Below is the same example using parentheses for better logical understanding/readability
SELECT orderid, custid, empid, orderdate 
FROM Sales.Orders
WHERE
	(custid = 1
		AND empid IN(1,3,5))
	OR 
	(custid = 85
		AND empid IN(2,4,6));


-- CASE EXPRESSIONS
/*	CASE Expressions = scalar expression that returns a value based on conditional logic.
	Allowed in the SELECT, HAVING, WHERE, and ORDER BY clauses and in CHECK constraints.
	2 froms simple and searched 
	
	Simple = Compare 1 value or scalar expression with a list of possible values and return value of 1st match.
	if no value is equal to the tested value, CASE expression returns value in the ELSE clause
	if no ELSE clause, it defaults to ELSE NULL */
SELECT productid, productname, categoryid,
	CASE categoryid 
		WHEN 1 THEN 'Beverages'
		WHEN 2 THEN 'Condiments'
		WHEN 3 THEN 'Confections'
		WHEN 4 THEN 'Dairy Products'
		WHEN 5 THEN 'Grains/Cereals'
		WHEN 6 THEN 'Meat/Poultry'
		WHEN 7 THEN 'Produce'
		WHEN 8 THEN 'Seafood'
		ELSE 'Unknown Category'
	END AS categoryname
FROM Production.Products;

/*	Searched = returns the value in the THEN clause that is associated with the first WHEN predicate that evaluates to TRUE
	if none of the WHEN predicates evaluate to TRUE, CASE expression returns val in ELSE clause, or NULL if not present.	*/
SELECT orderid, custid, val,
	CASE	
		WHEN val < 1000.00						THEN 'Less than 1000'
		WHEN val BETWEEN 1000.00 AND 3000.00	THEN 'Between 1000 and 3000'
		WHEN val > 3000.00						THEN 'More than 3000'
		ELSE 'unknown'
	END AS valuecategory
FROM Sales.OrderValues;
	-- Every simple CASE expression can easily be converted into a searched but the reverse is not true.


-- NULLS
/*	NULL = NULL evaluates to unknown 
	Accept TRUE both false and Unknown are discarded, Accept FALSE both True and Unknown are accepted
	When you negate UNKNOWN you still get UNKNOWN
	You should use IS NULL instead of = NULL to return rows that have null values	*/
SELECT custid, country, region, city
FROM Sales.Customers 
WHERE region IS NULL;
	-- Returning all rows for which region is different than 'WA', including those with missing values.
SELECT custid, country, region, city
FROM Sales.Customers 
WHERE region <> N'WA'
	OR region IS NULL; 


-- All-AT-ONCE OPERATIONS 
/*	all queries that appear in the same logical query processing phase are evaluated logically at the same point in time 
	explains why you cannot refer to all column alias in the SELECT clause in the same SELECT clause	*/
SELECT
	orderid, 
	YEAR(orderdate) AS orderyear,
	orderyear + 1 AS nextyear -- Throws an exception
FROM Sales.Orders;

	-- another exaple of avoiding all-at-once errors
SELECT col1, col2
FROM dbo.T1
WHERE col1 <> 0 AND col2/col1 > 2; -- Evaluates expressions in WHERE clause in any order due to all-at-once based on cost estimations.
	-- Here to avoid the above error, the order of the WHEN clauses are guaranteed
SELECT col1, col2
FROM dbo.T1
WHERE
	CASE 
		WHEN col1 = 0 THEN 'no' -- or 'yes' if row should be returned
		WHEN col2/col1 > 2 THEN 'yes'
		ELSE 'no' 
	END = 'yes';
	-- mathmatical work around that avoids division
SELECT col1, col2
FROM dbo.T1
WHERE (col1 > 0 AND col2 > 2*col1) OR (col1 < 0 AND col2 < 2*col1);


-- DATA TYPES
/*	2 kinds of character data, regular and Unicode; regular(CHAR and VARCHAR)1byteperchar, Unicode(NCHAR and NVARCHAR)2bytesperchar
	Unicode data types support multiple languages, regular supports one language in addition to English 
	regular 'this is a regular literal', Unicode N'this is a unicode literal'
	regular has defined storage amount(Char(25)), Unicode has variable storage based on need + 2extra bytes for offset data.
	Unicode has faster read operations but updates might result in row expansion, so row updates are less efficient than regular
	can also define variable length data types with the MAX specifier instead of a max # of characters.	*/


-- COLLATION
/*	a property of character data that encapsulates several aspects: language support, sort order, case sensitivity, accent sensitivity, & more
	Query to get the set of supported collations and their descriptions (query fn_helpcollations)	*/
SELECT name_description 
FROM sys.fn_helpcollations(); 
	-- EX explanation of Latin1_General_Cl_AS:
	/*	-Latin1_General	code page 1252 is used (supports English&German characters, as well as characters of most Western European Countries)
		-Dictionary Sorting	sorting&comparing of character data are based on dictionary order (A and a < B and b)
			Dictionary order is used by default when no ordering is specified explicitly, if BIN appeared it would be sorting and comparing
			based on binary representation (A < B < a < b)
		-Cl	the data is case insensitive (a = A)
		-AS	the data is accent sensitive 
	On premise installation, coallation can be defined at 4 different levels (instance, databse, column, and expression) 
	the lowest effective level is the one that should be used.
	In Azure SQL coallation can be defined at (databse, column, and expression level) 
	Database collation determines the collation of metadata, including object and column names
	-In a case insensitive environment, the following query uses a case insensitive comparison */
SELECT empid, firstname, lastname
FROM HR.Employees
WHERE lastname = N'davis'; -- Returns 'Davis' even though it is not an exact character match
	-- You can make the filter case sensitive even though the column's coallation is case insensitive by converting collation of expression 
SELECT empid, firstname, lastname
FROM HR.Employees
WHERE lastname COLLATE Latin1_General_CS_AS = N'davis'; -- Now returns with no match


-- OPERATORS & FUNCTIONS 
	-- string concatenation and functions that operate on character strings 
	/* Functions that operate on strings
		SUBSTRING, LEFT, RIGHT, LEN, DATALENGTH, CHARINDEX, PATINDEX, REPLACE, REPLICATE,
		STUFF, UPPER, LOWER, RTRIM, LTRIM, FORMAT, COMPRESS, DECOMPRESS, and STRING_SPLIT	*/

	--String concatenation
SELECT empid, firstname + N' ' + lastname AS fullname --if 1 column is null, null is returned
FROM HR.Employees;
	--You can substitue NULLS by using the COALESCE function to return an empty string instead
SELECT custid, country, region, city,
	country + COALESCE( N',' + region, N'') + N',' + city AS location --returns first that is not null
FROM Sales.Customers;
	--you can also use the CONCAT Function
SELECT custid, country, region, city,
	CONCAT(country, N',' + region, N',' + city) AS location -- subs NULLS with empty strings
FROM Sales.Customers;

	-- SUBSTRING Function
/*	SUBSTRING(string, start, length) Operates on the input string and extracts a substring starting at start
	and that is length characters long. The following code returns 'abc'	*/
SELECT SUBSTRING('abcde', 1, 3); -- To return everything, specify the maximum length of data type

	-- LEFT and RIGHT Functions
/*	Abbreviations of the SUBSTRING Function, returns a specified number of characters from the left or right 
	of the input string. 
	Syntax:	LEFT(string, n), RIGHT(string, n)
	The following code returns 'cde'	*/
SELECT RIGHT('abcde', 3);

	-- LEN and DATALENGTH Functions 
/*	LEN returns the number of characters in the input string.
	Syntax: LEN(string)
	To get the number of bytes use the DATALENGTH Function instead(Regular 1 byte, Unicode 2 bytes)	*/
SELECT LEN(N'abcde'); --Returns 5 for Unicode so this may have been changed in later versions of SQL
SELECT DATALENGTH(N'abcde');

	--CHARINDEX Function
/*	Returns the position of the first argument (substring), within the 2nd argument (string).
	Has an optional 3rd argument (start_pos), which if not specified begins looking from the first char.
	If the substring is not found, 0 is returned.
	Syntax:	CHARINDEX(substring, string[, start_pos])
	The following returns 6 as the first position of a space.	*/
SELECT CHARINDEX(' ','Itzik Ben-Gan');

	--PATINDEX Function
/*	Returns the position of the first occurence of a pattern within a string.
	Syntax:	PATINDEX(pattern, string)
	The following is how to find the first occurence of a digit within a string.	*/
SELECT PATINDEX('%[0-9]%', 'abcd123efgh'); --returns 5

	--REPLACE Function 
/*	Replaces all occurences of a substring with another.
	Syntax: REPLACE(string, substring1, substring2)
	Replaces all occurence of substring1 in string with substring2
	The following substitues all occurences of a dash with a colon.	*/
SELECT REPLACE('1-a 2-b', '-', ':'); --Returns '1:a 2:b'
	/* REPLACE can be used to count the number of occurences of a character within a string by replacing the character 
	   with an empty string and calculating the original length minus the new length of the string.	*/
SELECT empid, lastname,
	LEN(lastname) - LEN(REPLACE(lastname, 'e', '')) AS numoccur
FROM HR.Employees;

	--REPLICATE Function
/*	Replicates a string a requested number of times.
	Syntax: REPLICATE(string, n)
	The following replicates 'abc' 3 times	*/
SELECT REPLICATE('abc', 3);--Return 'abcabcabc'
	/* The following demonstrates the REPLICATE Function with the RIGHT Function and string concatenation 
	   to generate a 10 digit representation of the supplier ID integer with leading zeros	*/
SELECT supplierid,
	RIGHT(REPLICATE('0', 9) + CAST(supplierid AS VARCHAR(10)), 10) AS strsupplierid
FROM Production.Suppliers;--FORMAT Function can produce the same results at a higher cost.
	
	--STUFF Function
/*	Syntax: STUFF(string, pos, delete_length, insert_string)
	Operates on string input, deletes number of characters specified in delete_length starting at pos. 
	Inserts insert_string at pos.
	The following operates on 'xyz', deletes 1 char from second character and inserts 'abc'	*/
SELECT STUFF('xyz', 2, 1, 'abc');--Put 0 if you wish to just insert and not delete

	--UPPER and LOWER Function 
/*	Return the input string with all uppercase or lowercase characters.
	Syntax: UPPER(string), LOWER(string)	*/
SELECT UPPER('Itzik Ben-Gan');--returns 'ITZIK BEN-GAN'
SELECT LOWER('Itzik Ben-Gan');--returns 'itzik ben-gan'

	--RTRIM and LTRIM Function
/*	Returns the input string with leading or trailing spaces removed.
	Syntax: RTRIM(string), LTRIM(string)
	If you want to remove both leading and trailing spaces use the result of one function as the input of another.	*/
SELECT RTRIM(LTRIM('   abc   '));--returns 'abc'

	--FORMAT Function
/*	Use to format an input value as a character string nased on a Microsoft .NET format string & an optional 
	culture specification.
	Syntax: FORMAT(input, format_string, culture)	
	http://go.microsoft.com/fwlink/?Linkid=211776	Numerous possibilities for formatting inputs.
	Costs more so you should refrain from using it unless you can accept performance penalties. */
SELECT FORMAT(1759, '000000000');--returns 000001759

	--COMPRESS and DECOMPRESS Function
/*	Use the GZIP algorithm to compress and decompress the input.
	Syntax: COMPRESS(string), DECOMPRESS(string)
	COMPRESS takes a character or binary string as input and returns a compressed VARBINARY(MAX) typed value. 
	The following is an example with a constant as input.	*/
SELECT COMPRESS(N'This is my cv. Imagine it was much longer.');--results in a binary value holding the compressed form of the input string .
/*	The following is an example of an INSERT statement within a stored procedure for storing employees cv's in compressed form.	*/
INSERT INTO dbo.EmployeeCVs( empid, cv ) VALUES( @empid, COMPRESS(@cv) );
/*	The DECOMPRESS Function takes a binary string as input and returns a decompressed VARBINARY(MAX) typed value.
	You will need to CAST the returned value if the value you originaly compressed was of a character string type.	*/
SELECT 
	CAST(
		DECOMPRESS(COMPRESS(N'This is my cv. Imagine it was much longer.'))
			AS NVARCHAR(MAX));
/* To return the actual CV if you were to use the INSERT example above, would be as follows */
SELECT empid, CAST(DECOMPRESS(cv) AS NVARCHAR(MAX) AS cv
FROM dbo.EmployeeCVs;

	--STRING_SPLIT Function
/*	Splits an input string with a seperated list of values into the individual elements.
	Syntax:	SELECT value FROM STRING_SPLIT(string, seperator);
	A table function, it accepts a string with a seperated list of values plus a sperator	
	and it returns a table result with a string column called val with the individual elements	*/
SELECT CAST(value AS INT) AS myvalue --You need to CAST to the desired column type 
	FROM STRING_SPLIT('10248,10249,10250', ',') AS S;
/*	A common use for this is for passing a seperated list of values representing keys, such as orderid's
	to a stored procedure or user defined function and returning the rows from some table such as Orders 
	that have the input keys. This is achieved by joining the SPLIT_STRING function with the target table 
	and matching the keys from both sides	*/

	--LIKE Predicate
/*	Can use to check wether a character string matches a specific pattern.
	% Wildcard: % sign represents a string of any size including an empty string.
	You can use funtioncs such as SUBSTRING and LEFT instead of LIKE to represent the same thing
	but the like predicate tends to get optimized better	*/
SELECT empid, lastname
FROM HR.Employees
WHERE lastname LIKE N'D%';	-- Returns Employees where the lastname starts with D
	-- _(UNDERSCORE Wildcard) Represents a single character 
SELECT empid, lastname
FROM HR.Employees
WHERE lastname LIKE N'_e%'; -- Returns Employees where the second character in laastname is e.
	--[<list of chracters>] Wildcard
/*	Square brackets with a list of characters that represents a single character that must be 
	one of the characters in the list	*/
SELECT empid, lastname 
FROM HR.Employees
WHERE lastname LIKE N'[ABC]%';--Returns where first char in lastname is one of the following 
	--[<character>-<character>] Wildcard
/*	Square brackets with a character range, represents a single char that must be in the range	*/
SELECT empid, lastname 
FROM HR.Employees
WHERE lastname LIKE N'[A-E]%';
	--[^<character list or range>] Wildcard 
/*	Square brackets with a caret sign, followed by a character list or range. Represents a single character 
	that is not in the specified list or range	*/
SELECT empid, lastname
FROM HR.Employees
WHERE lastname LIKE N'[^A-E]%';-- Returns Employees where the first char of lastname is not in the range/list.
	-- ESCAPE Character
/*	If you want to search for a char that is also used as a widcard such as %,_,[ or ]. You can use an escape char.
	You specify a char that you know for sure doesn't appear in the data as the escape char in front of the char 
	you are looking for and specify the Keyword ESCAPE followed by the escape char right after the pattern.	*/
col1 LIKE '%!_%'ESCAPE'!'	-- Checks to see if col1 contains an underscore 


	-- WORKING WITH DATE AND TIME DATA
/*	2 Legacy Types (DATETIME and SMALLDATETIME), along with 4 later additions (DATE, TIME, DATETIME2, DATETIMEOFFSET).
	The DATE and TIME data types provide a seperation between date and time. DATETIME2 has better precision and range then
	legacy types.DATETIMEOFFSET is similiar to DATETIME2 but allows for offset from UTC.	*/

	-- Literals
/*	T-SQL doesn't provide the means to express a date and time literal, instead you can specify a literal of a different 
	type that can be converted(explicitly or implicitly) to a date and time datatype. It is best practice to use character strings 
	to express date and time values as shown below.	*/
SELECT orderid, custid, empid, orderdate
FROM Sales.Orders 
WHERE orderdate = '20160212';
--Implicit Conversion takes place when running the above code that is equivalent to the below code due to data type precedence 
SELECT orderid, custid, empid, orderdate
FROM Sales.Orders 
WHERE orderdate = CAST('20160212' AS DATE); --The literal character string is of lower precedence so it is converted. 

/*	DATEFORMAT is a setting that determines how SQL Server interprets the literals you enter when they are converted from a character 
	string type to a date and time type(expressed as a combination of characters d, m, and y). For example the us_english language setting 
	sets the DATEFORMAT to mdy, wheres British is set to dmy	*/
SET LANGUAGE British;
SELECT CAST('02/12/2016' AS DATE);--Returns as December

SET LANGUAGE us_English;
SELECT CAST('02/12/2016' AS DATE);--Returns as Feburary
-- Some fromats of literals are language dependent 
-- Using literal formats that are considered neutral is a good practice, see below.
SET LANGUAGE British;
SELECT CAST('20160212' AS DATE);

SET LANGUAGE us_English;
SELECT CAST('20160212' AS DATE); --Both now return Feb because of neutral literals being used. 

	-- Filtering Date Ranges 
--Instead of using a function such as below to return data from a certain year.
SELECT orderid, custid, empid, orderdate
FROM Sales.Orders 
WHERE YEAR(orderdate) = 2015;
-- You should not manipulate the filtered column due to performance issues involving indexes, instead do below.
SELECT orderid, custid, empid, orderdate
FROM Sales.Orders 
WHERE orderdate >= '20150101' AND orderdate < '20160101';
-- Similiary to get data from a certain month you should use the below code. 
SELECT orderid, custid, empid, orderdate
FROM Sales.Orders 
WHERE orderdate >= '20160201' AND orderdate < '20160301';

	-- Date and Time Functions 
/*	Function			Return Type			Description
	GETDATE				DATETIME			Current date and time
	CURRENT_TIMESTAMP	DATETIME			Same as GETDATE but ANSI SQL Compliant 
	GETUTCDATE			DATETIME			Current date and time in UTC
	SYSDATETIME			DATETIME2			Current date and time
	SYSUTCDATETIME		DATETIME2			Current date and time in UTC
	SYSDATETIMEOFFSET	DATETIMEOFFSET		Current date and time, including offset from UTC	*/
SELECT
	GETDATE()			AS [GETDATE],
	CURRENT_TIMESTAMP	AS [CURRENT_TIMESTAMP],
	GETUTCDATE()		AS [GETUTCDATE],
	SYSDATETIME()		AS [SYSDATETIME],
	SYSUTCDATETIME()	AS [SYSUTCDATETIME],
	SYSDATETIMEOFFSET()	AS [SYSDATETIMEOFFSET]; --Example of using functions 
-- None return only the date or only the time but you can get these by converting shown below.
SELECT
	CAST(SYSDATETIME() AS DATE) AS [current_date],
	CAST(SYSDATETIME() AS TIME) AS [current_time];

	-- CAST, CONVERT, and PARSE Functions and their TRY_counterparts
/*	Used to convert an input value to some target type. If you put TRY_ infront of any of these functions,
	NULL will be returned instead of the function just failing. 
	Syntax:
	CAST(value AS datatype)		Cast is standard and recommended unless you need a style num or culture
	TRY_CAST(value AS datatype)
	CONVERT(datatype, value [,style_number])	third argument happens in some cases, style num dictates format 
	TRY_CONVERT(datatype, value [,style_number])
	PARSE(value AS datatype [USING culture])
	TRY_PARSE(value AS datatype [USING culture])	*/

	-- The SWITCHOFFSET Function 
/*	Adjusts an input DATETIMEOFFSET value to a specified target offset from UTC
	Syntax:
	SWITCHOFFSET(datetimeoffset_value, UTC_offset)
	The below code adjusts the current system datetimeoffset value to offset -05:00	*/
SELECT SWITCHOFFSET(SYSDATETIMEOFFSET(), '-05:00');

	-- The TODATETIMEOFFSET Function 
/*	Constructs a DATETIMEOFFSET typed value from a local date and time value and an offset from UTC
	Syntax:
	TODATETIMEOFFSET(local_date_and_time_value, UTC_offset)
	Functions simply merges the input date and time value with the specified offset to create a new datetimeoffset value.	*/

	-- The AT TIME ZONE Function
/*	Accepts an input date and time value and converts it to a datetimeoffset value that corresponds to
	the specified target time zone.
	Syntax:
	dt_val AT TIME ZONE time_zone
	Accepts DATETIME, SMALLDATETIME, DATETIME2, and DATETIMEOFFSET as inputs
	You can use the below query to get a list of timezones, their offset from UTC and wether currently Daylight Savings Time.	*/
SELECT name, current_utc_offset, is_currently_dst
FROM sys.time_zone_info;

	-- The DATEADD Function
/*	Use to add a specific number of units of a specified date part to an input date and time value 
	Syntax:
	DATEADD(part, n, dt_val)
	Valid values for the part include: year, quarter, month, dayofyear, day, week, weekday, hour,
	minute, second, millisecond, microsecond, and nanosecond	*/
SELECT DATEADD(year, 1, '20160212'); --Returns as 2017

	-- The DATEDIFF and DATEDIFF_BIG Functions
/*	Return the difference between two date and time values in terms of a specified date part. Former returns as INT
	and later returns as BIGINT
	Syntax:
	DATEDIFF(part, dt_val1, dt_val2), DATEDIFF_BIG(part, dt_val1, dt_val2)
	The following returns the difference in days between two values	*/
SELECT DATEDIFF(day, '20150212', '20160212');--Returns 365
-- You can use the DATEDIFF_BIG function when the returned value is too large for an int, see below
SELECT DATEDIFF_BIG(millisecond, '00010101', '20160212'); -- Returns 63590832000000

	-- The DATEPART Function
/*	Returns an integer representing a requested part of a date and time value
	Syntax:
	DATEPART(part, dt__val)
	Valid parts include:  year, quarter, month, dayofyear, day, week, weekday, hour,
	minute, second, millisecond, microsecond, nanosecond, TZoffset, and ISO_WEEK
	The following returns the month part of the input value	*/
SELECT DATEPART(month, '20160212'); -- Returns the int 2

	-- The YEAR, MONTH, and DAY Functions
/*	Abbreviations for the DATEPART Function returning the integer representations of 
	the year, month, and day parts of an input date and time value.
	Syntax:
	YEAR(dt_val)
	MONTH(dt_val)
	DAY(dt_val)	*/
SELECT
	DAY('20160212') AS theday,
	MONTH('20160212') AS themonth,
	YEAR('20160212') AS theyear;

	-- The DATENAME Function
/*	Returns a character string representing a part of a date and time value.
	Syntax:
	DATENAME(dt_val,part)
	Similiar to DATEPART but it returns the name of the requested value instead of the number	*/
SELECT DATENAME(month, '20160212'); --Returns February 

	-- The ISDATE Function 
/*	Accepts a character string as input and returns 1 if it is convertible to a date and time data
	type and 0 if it isn't.
	Syntax:
	ISDATE(string)	*/
SELECT ISDATE('20160212'); -- Returns 1
SELECT ISDATE('20160230'); -- Returns 0

	-- The FROMPARTS Function 
/*	Accept integer inputs representing parts of a date and time value and construct a value of the
	requested type from those parts.
	Syntax:
	DATEFROMPARTS(year, month, day)
	DATETIME2FROMPARTS(year, month, day, hours, minutes, seconds, fractions, precision)
	DATETIMEFROMPARTS(year, month, day, hour, mintues, seconds, milliseconds)
	DATETIMEOFFSETFROMPARTS(year, month, day, hours, minutes, seconds, fractions,hour_offset, minute_offset, precision)
	SMALLDATETIMEFROMPARTS(year, month, day, hour, minute)
	TIMEFROMPARTS(hour, minute, seconds, fractions, precision)	*/

	-- The EOMONTH Function 
/*  Accepts as input date and time value and returns the respective end-of-month date as a DATE typed value.
	Also supports on optional 2nd parameter indicating how many month to add (or subtract if negative)
	Syntax:
	EOMONTH(input [,months_to_add])	*/
SELECT EOMONTH(SYSDATETIME()); -- Returns end of current month 
-- Following returns orders placed on the last day of the month
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
WHERE orderdate = EOMONTH(orderdate);


	-- QUERYING METADATA
	-- Catalog Views
/*	Provide detailed information about objects in the database, including infromation that is specific to sql server.
	If you want to list the tables in a database along with their schema names, you can query the sys.tables view as follows.	*/
USE TSQLV4;

SELECT SCHEMA_NAME(schema_id) AS table_schema_name, name AS table_name
FROM sys.tables;
-- The following provides you infromation about columns in a table
SELECT
	name AS column_name,
	TYPE_NAME(system_type_id) AS column_type,
	max_length,
	collation_name,
	is_nullable
FROM sys.columns
WHERE object_id = OBJECT_ID(N'Sales.Orders');

	-- Information Schema Views
/*	A set of views that resides in a schema called INFORMATION_SCHEMA and provides metadata information 
	in a standard manner.
	The following lists the user tables in the current database along with their schema names.	*/
SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = N'BASE TABLE';
-- The following provides most of the information available about the columns in Sales.Orders Table
SELECT
	COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH,
	COLLATION_NAME, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = N'Sales'
	AND TABLE_NAME = N'Orders';

	-- System Stored Procedures and Functions 
/*	Internally query the system catalog and give you back more "digested" metadata information.
	sp_tables stored procedure returns a list of objects(such as tables and views) that can be queried in the 
	current database.	*/
EXEC sys.sp_tables;
-- sp_help returns information about that object
EXEC sys.sp_help
	@objname = N'Sales.Orders';
-- sp_columns returns info about columns in an object 
EXEC sys.sp_columns 
	@table_name = N'Orders',
	@table_owner = N'Sales';
-- sp_helpconstraint returns info about constrains in an object 
EXEC sys.sp_helpconstraint
	@objname = N'Sales.Orders';



	-- CHAPTER 2 EXERCISES

-- Returns orders placed in June 2015 
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
WHERE orderdate >= '20150601' AND orderdate < '20150701';

-- Returns orders that were placed on the last day of the month 
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
WHERE orderdate = EOMONTH(orderdate);

-- Returns Employees with a lastname containing the letter e twice or more
SELECT empid, firstname, lastname 
FROM HR.Employees
WHERE (LEN(lastname) - LEN(REPLACE(lastname, 'e', ''))) >= 2;

-- Returns orders with a total value (quantity + unit price) gretaer than 10,000 sorted 
-- by total value 
SELECT orderid, SUM(qty*unitprice) AS totalvalue
FROM Sales.OrderDetails
GROUP BY orderid
HAVING SUM(qty*unitprice) > 10000
ORDER BY totalvalue DESC;

-- Write a query against the HR.Employees table that returns employees with a lastname that
-- starts with a lowercase English letter in the range a through z. Collation is case insensitive.
SELECT empid, lastname
FROM HR.Employees 
WHERE lastname COLLATE Latin1_General_CS_AS LIKE N'[abcdefghijklmnopqrstuvwxyz]%';

-- Explain the difference between the following two queries 
SELECT empid, COUNT(*) AS numorders
FROM Sales.Orders 
WHERE orderdate < '20160501'
GROUP BY empid;

SELECT empid, COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY empid
HAVING MAX(orderdate) < '20160501';
/*	The WHERE clause is a row filter, the HAVING clause is a group filter.
	The first query filters only orders placed before May 2016, groups them by empid,
	and returns the number of orders each employee handled among the filtered ones.
	In other words the query doesn't include orders placed in May 2016 or later in
	the count. The second query groups all orders by empid, then filters only groups having 
	a maximum date of activity prior to May 2016, then it computes the order count in 
	each employee group. The query discards the entire employee group if the employee handled 
	any orders since May 2016. In other words it returns employees who didn't handle any orders 
	since May 2016 the total number of orders they handled.	*/

-- Write a query against the Sales.Orders table that returns the three shipped-to countries
-- with the highest average freight in 2015 
SELECT TOP(3)shipcountry, AVG(freight) AS avgfreight
FROM Sales.Orders
WHERE orderdate >= '20150101' AND orderdate < '20160101'
GROUP BY shipcountry
ORDER BY avgfreight DESC;

-- Write a query against the Sales.Orders table that calculates row numbers for orders
-- based on order date ordering (using the orderid as the tiebreaker) for each customer seperately.
SELECT custid, orderdate, orderid,
	ROW_NUMBER() OVER(PARTITION BY custid ORDER BY orderdate, orderid) AS rownum
FROM Sales.Orders
ORDER BY custid, rownum;

-- Using the HR.Employees table, write a SELECT statement that returns for each employee
-- the gender based on the title of courtesy. For 'Ms' or 'Mrs' return Female; for 'Mr' 
-- return Male; and in all other cases (for ex 'Dr') return 'Unknown'.
SELECT empid, firstname, lastname, titleofcourtesy, 
	CASE titleofcourtesy
		WHEN 'Ms.'THEN 'Female'
		WHEN 'Mrs.'THEN 'Female'
		WHEN 'Mr.'THEN 'Male'
		ELSE 'Unknown'
	END AS gender
FROM HR.Employees;

-- Write a query against the Sales.Customers table that returns for each customer the custid
-- and region. Sort the rows in the output by region, having nulls sort last (after non-null
-- values). Note that the default sort behavior for nulls in T-SQL is to sort nulls first 
-- before non null values 
SELECT custid, region
FROM Sales.Customers
ORDER BY 
	CASE WHEN region IS NULL THEN 1 ELSE 0 END, region; 



	-- CHAPTER 3 JOINS

	-- JOINS
/*	Within the FROM clause, table operators operate on input tables.
	T-SQL supports JOIN, APPLY, PIVOT, and UNPIVOT.
	A JOIN table operator operates on two input tables.
	The three fundamental types of joins are cross, inner, and outer joins.	*/

	-- CROSS JOINS
/*	Simplest type of join, implements only one logical query processing phase, 
	A Cartesian Product. Each row from one input is matched with all rows from another.
	(M rows in one table and N rows in another = MxN rows)	*/
SELECT C.custid, E.empid
FROM Sales.Customers AS C
	CROSS JOIN HR.Employees AS E; -- SQL-92 Syntax instead of SQL-89
/*	If you do not assign alias to the tables in the FROM clause, 
	the names of the columns in the virtual table are prefixed by the full
	source table names.	*/

	-- Self CROSS JOINS
/*	You can join multiple instances of the same table. This capability is known as a
	self join and is supported with all fundamental join types (cross, inner, and outer)	*/
SELECT
	E1.empid, E1.firstname, E1.lastname,
	E2.empid, E2.firstname, E2.lastname
FROM HR.Employees AS E1
	CROSS JOIN HR.Employees AS E2; -- Result produces all possible combinations

	-- Producing Tables of Numbers
/*	CROSS JOINS can be handy to produce a result set with a sequence of integers
	for example (1,2,3,...)	*/
USE TSQLV4;

DROP TABLE IF EXISTS dbo.Digits;

CREATE TABLE dbo.Digits
(
	digit INT NOT NULL PRIMARY KEY
);

INSERT INTO dbo.Digits(digit)
	VALUES (0), (1), (2), (3), (4), (5), (6), (7), (8), (9);

SELECT digit FROM dbo.Digits;	-- Populates the Digits table with the inserted values

/*	To produce a sequence of integers in the range of 1 through 1,000 you can apply 
	CROSS JOINS between three instances of the Digits table, each representing a 
	different power of 10(1, 10, 100)	*/
SELECT D3.digit * 100 + D2.digit * 10 + D1.digit + 1 AS n
FROM dbo.Digits AS D1
	CROSS JOIN dbo.Digits AS D2
	CROSS JOIN dbo.Digits as D3
ORDER BY n;


	-- INNER JOINS
/*	Applies two logical querying phases - It applies a cartesian product between the 
	two input tables like in a CROSS JOIN, and then it filters rows based on a predicate 
	you specify. You specify the predicate that is used to filter rows in the ON clause.
	The predicate is also known as the JOIN CONDITION.
	The following performs a join between the Employees and the Order Tables, matching
	employees and orders based on the predicate E.empid = O.empid	*/
SELECT E.empid, E.firstname, E.lastname, O.orderid 
FROM HR.Employees AS E
	INNER JOIN Sales.Orders AS O 
		ON E.empid = O.empid; -- This is the join condition 
/*	This join matches each employee row with all order rows that have the same employee id
	as in the employee row.	The ON clause also returns only rows for which the 
	predicate returns TRUE. It does not return return rows for which the predicate evaluates
	to FALSE or UNKNOWN.	*/ 

	-- COMPOSITE JOINS 
/*	A join where you need to match multiple attributes from each side. Usually needed when a 
	Primary key - Foreign Key relationship is based on more than one attribute	*/
FROM dbo.Table1 AS T1
	INNER JOIN dbo.Table2 AS T2
	ON T1.col1 = T2.col2
	AND T1.col2 = T2.col2 -- As an example of if there were multiple key relationships 
-- The next example would be used for auditing updates to column values 
USE TSQLV4;

DROP TABLE IF EXISTS Sales.OrderDetailsAudit;

CREATE TABLE Sales.OrderDetailsAudit
(
	lsn			INT			NOT NULL	IDENTITY, --Log Serial Number
	orderid		INT			NOT NULL,
	productid	INT			NOT NULL,
	dt			DATETIME	NOT NULL,
	loginname	sysname		NOT NULL,
	columnname	sysname		NOT NULL,
	oldval		SQL_VARIANT,
	newval		SQL_VARIANT,
		CONSTRAINT PK_OrderDetailsAudit PRIMARY KEY(lsn),
		CONSTRAINT FK_OrderDetailsAudit_OrderDeatils
			FOREIGN KEY(orderid, productid)
			REFERENCES Sales.OrderDetails(orderid, productid)
);
/*	So now you need to write a query against the OrderDetails and OrderDetailsAudit 
	tables that returns info about all value changes that took place in the column qty	*/
SELECT OD.orderid, OD.productid, OD.qty,
	ODA.dt, ODA.loginname, ODA.oldval, ODA.newval
FROM Sales.OrderDetails AS OD
	INNER JOIN Sales.OrderDetailsAudit AS ODA
		ON OD.orderid = ODA.orderid
		AND OD.productid = ODA.productid
	WHERE ODA.columnname = N'qty'; -- Composite because it is based on multiple attributes 

	-- NON-EQUI JOINS
/*	When a join condition involves only an equality operator, the join is said to be an 
	equi join. When a join condition involves any operator besides equality, the join is
	said to be a non-equi join. A join that has an explicit join predicate that is based
	on a binary operator(equality or inequality) is known as a theta join. Both equi and
	non-equi joins are types of theta joins.	*/
SELECT	
	E1.empid, E1.firstname, E1.lastname,
	E2.empid, E2.firstname, E2.lastname
FROM HR.Employees AS E1
	INNER JOIN HR.Employees AS E2
		ON E1.empid < E2.empid; -- Produces unique pairs of employees 
/*	Using an inner join with a join condition that says that they key on the left side 
	must be smaller than the key on the right side eliminates the two inapplicable cases.
	Self pairs are eliminated because both sides are equal.		*/

	-- MULTI-JOIN QUERIES
/*	In general, when more than one table operator appears in the FROM clause, the table
	operators are processed from left to right. The following query joins the Customers
	and the Orders tables to match customers with their orders, then it joins the result
	of the first join with the OrderDetails table to match orders with their order lines.	*/
SELECT
	C.custid, C.companyname, O.orderid,
	OD.productid, OD.qty
FROM Sales.Customers AS C
	INNER JOIN Sales.Orders AS O
		ON C.custid = O.custid
	INNER JOIN Sales.OrderDetails AS OD
		ON O.orderid = OD.orderid;

	-- OUTER JOINS
/*	Outer joins apply 3 logical processing phases, Cartesian Product, ON filter, and
	a 3rd phase called adding outter rows. In an outter join you mark a table as 
	preserved by using the keywords LEFT OUTER JOIN, RIGHT OUTER JOIN, or FULL OUTER
	JOIN between the table names, the OUTER keyword is optional. The LEFT and RIGHT
	keywords decide which side of the table to preserve.
	The following query joins the Customers and Orders tables, based on a match between
	the Customers custid and the Orders custid, to return customers and their orders.
	The join type is a left outer join; therefore the query also returns customers
	who did not place any orders.	*/
SELECT C.custid, C.companyname, O.orderid
FROM Sales.Customers AS C
	LEFT OUTER JOIN Sales.Orders AS O
	ON C.custid = O.custid
WHERE O.orderid IS NULL; -- Adding this displays preserved NULL values from join
/*	When you need to express a predicate that is not final - meaning a predicate that 
	determines which rows to match from the nonpreserved side - specify the predicate in 
	the ON clause. When you need a filter to be applied after the outer rows are produced,
	and you want the filter to be final, specify the predicate in the WHERE clause. */


	-- BEYOND the Fundamentals of OUTER JOINS

	-- Including Missing Values
/*	Outer Joins can be used to identify and include missing values when querying data.
	As an example suppose you need to query all Orders from the Orders table. You need
	to ensure you get at least one row in the output for each date in the range
	January 1, 2014 through December 31, 2016. You don't want to do anything special
	with dates within the range that have orders but you do want the output to include the 
	dates with no orders, with NULLs as a placeholder in the attributes of the order. */
/*	As the first step in the solution, you need to produce a sequence of all dates in the 
	requested range. You can achieve this by querying the NUMS table and filtering as many 
	numbers as the number of days in the requested date range. DATEDIFF can be used to 
	calculate that number. By adding n-1 days to the starting point of the date range,
	you get the actual date in the sequence.	*/
SELECT DATEADD(day, n-1, CAST('20140101' AS DATE)) AS orderdate
FROM dbo.Nums
WHERE n <= DATEDIFF(day, '20140101', '20161231') + 1
ORDER BY orderdate; -- Returns a sequence of all dates in the range
/*	The next step is to extend the previous query, adding a left outer join between Nums
	and the Orders tables. This join compares the order date produced from the Nums 
	table and the orderdate from the Orders table by using the expression 
	DATEADD(day,Nums.n-1,CAST('20140101' AS DATE))	*/
SELECT DATEADD(day, Nums.n - 1, CAST('20140101' AS DATE)) AS orderdate,
	O.orderid, O.custid, O.empid
FROM dbo.Nums
	LEFT OUTER JOIN Sales.Orders AS O
		ON DATEADD(day, Nums.n - 1, CAST('20140101' AS DATE)) = O.orderdate
WHERE Nums.n <= DATEDIFF(day, '20140101', '20161231') + 1
ORDER BY orderdate;
	
	-- Filtering Attributes from the Nonpreserved side of an Outer Join
/*	When you need to review code involving outer joins for logical bugs, one of
	the things you should examine is the WHERE clause. If the predicate in the 
	WHERE clause refers to an attribute from the nonpreserved side of a join using
	and expression in the form <attribute> <operator> <value>, it's usually an 
	indication of a bug. This is because attributes from the nonpreserved side of 
	the join are NULLs in the outer row. For Example	*/
SELECT C.custid, C.companyname, O.orderid, O.orderdate
FROM Sales.Customers AS C
	LEFT OUTER JOIN Sales.Orders AS O
		ON C.custid = O.custid
	WHERE O.orderdate >= '20160101';-- This evaluates to UNKNOWN, eliminating all outer rows

	-- Using Outer Joins in a Multi Join Query
/*	All at once operations in which all expressions that appear in the same logical query 
	processing phase are evaluated as a set, at the same point in time; is not applicable 
	to the processing of table operators in the FROM phase. Table operators are logically
	evaluated from left to right. Rearranging the order in which outer joins are processed 
	might result in a different output, so you cannot rearrange them at will. Below is an
	example of a bug due to logical processing in a multi join query.	*/
SELECT C.custid, O.orderid, OD.productid, OD.qty
FROM Sales.Customers AS C
	LEFT OUTER JOIN Sales.Orders AS O 
		ON C.custid = O.custid
	INNER JOIN Sales.OrderDetails AS OD -- This nullifies the outer join resulting in an error
		ON O.orderid = OD.orderid;
-- A work around if you want to display customers with no orders in the output is to use
-- a second left outer join as below
SELECT C.custid, O.orderid, OD.productid, OD.qty
FROM Sales.Customers AS C
	LEFT OUTER JOIN Sales.Orders AS O 
		ON C.custid = O.custid
	LEFT OUTER JOIN Sales.OrderDetails AS OD
		ON O.orderid = OD.orderid; -- Now the outer rows produced by the first join aren't filtered out
-- Another option is to use an inner join first betweeen Orders and OrderDetails, then you
-- can apply an outer join between the Customers table
SELECT C.custid, O.orderid, OD.productid, OD.qty
FROM Sales.Customers AS C
	LEFT OUTER JOIN 
		(Sales.Orders AS O
			INNER JOIN Sales.OrderDetails AS OD
				ON O.orderid = OD.orderid)
		ON C.custid = O.custid;

	-- Using the COUNT Aggregate with Outer Joins
/*	When you group the result of an outer join and use the COUNT(*) aggregate, the
	aggregate takes into consideration both inner rows and outer rows, because it counts 
	rows regardless of their contents. Usually, you're not suppose to take outer rows into 
	consideration for counting, so this results in an error. Example below	*/
SELECT C.custid, COUNT(*) AS numorders
FROM Sales.Customers AS C
	LEFT OUTER JOIN Sales.Orders AS O
		ON C.custid = O.custid
	GROUP BY C.custid; 
-- Customers who did not place orders still show up in the result as 1
/*	The COUNT(*) aggregate function cannot detect wether a row really represents an order.
	To fix this problem you should use COUNT(<column>) instead of COUNT(*) and provide
	a column from the nonpreserved side of the join. For example	*/
SELECT C.custid, COUNT(O.orderid) AS numorders
FROM Sales.Customers AS C
	LEFT OUTER JOIN Sales.Orders AS O
		ON C.custid = O.custid
	GROUP BY C.custid; 
-- Customers who did not place an order now show up as 0


	-- CHAPTER 3 EXERCISES

-- Write a query that generates 5 copies of each employee row
SELECT E.empid, E.firstname, E.lastname, N.n
FROM HR.Employees AS E
	CROSS JOIN dbo.Nums AS N
WHERE N.n <= 5
ORDER BY n, empid;
-- Write a query that returns a row for each employee and day in the range June 12, 2016
-- through June 16, 2016 
SELECT E.empid, DATEADD(day, D.n-1,CAST('20160612' AS DATE))AS dt
FROM HR.Employees AS E
	CROSS JOIN dbo.Nums AS D
WHERE D.n <= DATEDIFF(day, '20160612', '20160616') + 1
ORDER BY empid, dt;

-- Explain what is wrong in the following query and provide a correct alternative
SELECT Customers.custid, Customers.companyname, Orders.orderid, Orders.orderdate
FROM Sales.Customers AS C
	INNER JOIN Sales.Orders AS O
		ON Customers.custid = Orders.custid;
		-- Solution
SELECT C.custid, C.companyname, O.orderid, O.orderdate
FROM Sales.Customers AS C
	INNER JOIN Sales.Orders AS O
		ON C.custid = O.custid;
	
-- Return US customers and for each customer return the total number of orders and total quantities
SELECT C.custid, COUNT(DISTINCT O.orderid) AS numorders, SUM(OD.qty) AS totalqty
FROM Sales.Customers AS C
	INNER JOIN
		Sales.Orders AS O
		ON C.custid = O.custid 
	INNER JOIN
		Sales.OrderDetails AS OD
		ON O.orderid = OD.orderid
WHERE C.country = N'USA'
GROUP BY C.custid;

-- Return customers and their orders, including customers who placed no orders
SELECT C.custid, C.companyname, O.orderid, O.orderdate
FROM Sales.Customers AS C
	LEFT OUTER JOIN Sales.Orders AS O
	ON C.custid = O.custid;

-- Return customers who placed no orders
SELECT C.custid, C.companyname, O.orderid, O.orderdate
FROM Sales.Customers AS C
	LEFT OUTER JOIN Sales.Orders AS O
	ON C.custid = O.custid
WHERE O.orderid IS NULL;

-- Return customers with orders placed on February 12, 2016 along 
-- with their orders 
SELECT C.custid, C.companyname, O.orderid, O.orderdate
FROM Sales.Customers AS C
	INNER JOIN Sales.Orders AS O
	ON C.custid = O.custid 
WHERE O.orderdate = '20160212';

-- Write a query that returns all customers in the output, but matches them with their
-- respective orders only if they were placed on February 12, 2016 
SELECT C.custid, C.companyname, O.orderid, O.orderdate
FROM Sales.Customers AS C
	LEFT OUTER JOIN Sales.Orders AS O
	ON C.custid = O.custid
	AND O.orderdate = '20160212';

-- Explain why the following is not a correct solution to the previous problem
SELECT C.custid, C.companyname, O.orderid, O.orderdate
FROM Sales.Customers AS C
	LEFT OUTER JOIN Sales.Orders AS O
	ON C.custid = O.custid
WHERE O.orderdate = '20160212'
	OR O.orderid IS NULL;
	-- Not all orders will be joined from the Orders table because of the predicates 
	-- established for the Left Outer Join, many of the customers will be discarded 

-- Return all customers, and for each return a Yes/No value depending on whether the
-- customer placed orders on February 12, 2016
SELECT DISTINCT C.custid, C.companyname,
	CASE WHEN O.orderid IS NOT NULL THEN 'Yes' ELSE 'No' END AS HasOrderOn20160212
FROM Sales.Customers AS C
	LEFT OUTER JOIN Sales.Orders AS O 
	ON C.custid = O.custid 
	AND O.orderdate = '20160212';


	-- CHAPTER 4 SUBQUERIES 
/*	Sql supports writting queries within queries, or nesting queries. The outermost query
	is a query whose result set is returned to the caller and is known as the outer query,
	the inner query is a query whose result is used by the outer query and is known as a
	subquery. Unlike the results of expressions that use constants, the result of a subquery
	can change because of changes in the queried tables. A subquery can be either self contained 
	correlated. A self-contained subquery has no dependency on tables from the outer query,
	wheres a correlated subquery does. A subquery can return a single value, multiple values, 
	or a whole table result. Both self contained and correlated subqueries can return a scalar
	or multiple values.	*/

	-- Self Contained Subqueries 
/*	Self contained subqueries are subqueries that are independent of the tables in the outer
	query. They are convenient to debug, because you can always highlight the inner query, run
	it, and ensure that it does what it is suppose to do.	*/

	-- Self Contained Scalar Subqueries 
/*	Such a subquery can appear anywhere in the outer query where a single-valued expression
	can appear (Such as WHERE or SELECT).
	In the next example, suppose you need to query the Orders table and return information about
	the order that has the maximum orderid in the table.	*/
-- Here's how it accomplished using a variable 
USE TSQLV4;

DECLARE @maxid AS INT = (SELECT MAX(orderid)
						FROM Sales.Orders);

SELECT orderid, orderdate, empid, custid
FROM Sales.Orders
WHERE orderid = @maxid;
-- Here's how it is accomplished using a scalar self contained subquery
SELECT orderid, orderdate, empid, custid
FROM Sales.Orders 
WHERE orderid = (SELECT MAX(O.orderid)
				FROM Sales.Orders AS O);
/*	When using an equality predicate, if more than one value is returned it results
	in the subquery failing, such as in the below example	*/
SELECT orderid
FROM Sales.Orders
WHERE empid =
	(SELECT E.empid
	FROM HR.Employees AS E
	WHERE E.lastname LIKE N'D%');-- More than one employee meets this condition
-- If a scalar subquery returns no value, the empty result is converted to a NULL

	-- Self Contained Multivalued Subqueries 
/*	A subquery that returns multiple values as a single column. Some predicates such as 
	the IN predicate operate on a multivalued subquery. 
	The form of the IN predicate is 
		<scalar_expression> IN (<multivalued subquery>)
	The predicate evaluates to TRUE if scalar_expression is equal to any of the values 
	returned by the subquery. Going off of the previous example, because more than one
	employee can have the lastname starting with the same letter, this request should be 
	handled with the IN predicate, not with an equality operator.	*/
SELECT orderid
FROM Sales.Orders
WHERE empid IN
	(SELECT E.empid
	FROM HR.Employees AS E
	WHERE E.lastname LIKE N'D%');
-- IN predicate makes this query valid with any number of values returned (none, 1, or more)
-- JOINS and SUBQUERIES can solve the same problems, check for performance and go with the best.

/*	Suppose you need to write a query that returns orders placed by customers from the
	United States. You can write a query against the Orders table that returns orders where the 
	customerid is in the set of customerid's of customers from the united states.	*/
SELECT custid, orderid, orderdate, empid
FROM Sales.Orders 
WHERE custid IN
	(SELECT C.custid
	FROM Sales.Customers AS C
	WHERE C.country = N'USA');
-- As with any other predicate, you can negate the IN predicate with the NOT operator
SELECT custid, companyname
FROM Sales.Customers 
WHERE custid NOT IN
	(SELECT O.custid
	FROM Sales.Orders AS O
	WHERE O.custid IS NOT NULL);
-- It is considered a best practice to qualify the subquery to exclude NULLS.
/*	There is no need to specify the DISTINCT clause in the subquery. The database engine
	is smart enough to consider removing duplicates without you asking it to do so 
	explicitly.	*/

/*	This next example demonstrates the use of multiple self contained subqueries in
	the same query - both single and multivalued. To start we create a table called
	dbo.Orders and populate it with even numbered orders from the Sales.Orders table	*/
USE TSQLV4;

DROP TABLE IF EXISTS dbo.Orders;
CREATE TABLE dbo.ORDERS
(
	orderid INT NOT NULL
	CONSTRAINT PK_Orders PRIMARY KEY
);

INSERT INTO dbo.Orders(orderid)
	SELECT orderid
	FROM Sales.Orders
	WHERE orderid % 2 = 0; -- even numbered because when divided by 2 the remainder is 0
/*	You need to write a query that returns all individual orderids that are missing between
	the minimum and maximum ones in the table. To return all missing orderids, query the Nums
	table and filter only numbers that are between the minimum and maximum ones in the 
	dbo.Orders table and that do not appear as orderids in the Orders table. */
SELECT n
FROM dbo.Nums
WHERE n BETWEEN (SELECT MIN(O.orderid) FROM dbo.Orders AS O)
			AND (SELECT MAX(O.orderid) FROM dbo.Orders AS O)
	AND n NOT IN (SELECT O.orderid FROM dbo.Orders AS O);
-- Returns all odd numbered values because dbo.Orders contains all Even values 

	-- Correlated Subqueries 
/*	Subqueries that refer to attributes from the tables that appear in the outer query.
	Logically, the subquery is evaluated seperately for each outer row. The below
	example returns orders with the maximum orderid for each customer.	*/
SELECT custid, orderid, orderdate, empid
FROM Sales.Orders AS O1
WHERE orderid = 
	(SELECT MAX(O2.orderid)
	FROM Sales.Orders AS O2
	WHERE O2.custid = O1.custid);
-- For each row in O1 the subquery returns the MAX orderid for the current customer

/*	Correlated subqueries are usually harder to figure out. To simplify things, it
	is suggested that you focus your attention on a single row in the outer table and
	think about the logical processing that takes place in the inner query for that row.	
	To troubleshoot correlated subqueries, you need to substitue the correlation with a
	constant, and after ensuring the code is correct, substitue the constant with
	the correlation. 
	For this next example, suppose you need to query the Sales.OrderValues view  and 
	return for each order the percentage of the current order value out of the customer
	total.	*/
SELECT orderid, custid, val,
	CAST(100. * val / (SELECT SUM(O2.val)
					   FROM Sales.OrderValues AS O2
					   WHERE O2.custid = O1.custid)
				AS NUMERIC(5,2)) AS pct
FROM Sales.OrderValues AS O1
ORDER BY custid, orderid;

	-- The EXISTS Predicate
/*	T-SQL supports a predicate called EXISTS that accepts a subquery as input and returns
	TRUE if the subquery returns any rows and FALSE otherwise. For Example */
SELECT custid, companyname
FROM Sales.Customers AS C
WHERE country = N'Spain'
	AND EXISTS 
		(SELECT * FROM Sales.Orders AS O
		WHERE O.custid = C.custid);
-- EXISTS predicate returns TRUE if the current customer has related orders in the Orders table
-- You can also negate the EXISTS predicate with the NOT operator
SELECT custid, companyname
FROM Sales.Customers AS C
WHERE country = N'Spain'
	AND NOT EXISTS 
		(SELECT * FROM Sales.Orders AS O
		WHERE O.custid = C.custid);
-- The IN and EXISTS predicate lend themselves towards good optimization.
-- The use of * with EXISTS is not a bad practice due to performance of the database engine
-- EXISTS uses 2 valued predicate logic

	-- Beyond the Fundamental of Subqueries
/*	Suppose you need to query the Orders table and return, for each order, information
	about the current order and also the previous orderid. "previous" implies order
	and rows in a tbale have no order. You can achieve this one way by using an expression
	that means "the maximum value that is smaller than the current value".	*/
SELECT orderid, orderdate, empid, custid,
	(SELECT MAX(O2.orderid)
	 FROM Sales.Orders AS O2
	 WHERE O2.orderid < O1.orderid) AS prevorderid
FROM Sales.Orders AS O1;
-- If you phrase the concept of "next" as "the minimum value that is greater than the current
-- value"
SELECT orderid, orderdate, empid, custid,
	(SELECT MIN(O2.orderid)
	 FROM Sales.Orders AS O2
	 WHERE O2.orderid < O1.orderid) AS nextorderid
FROM Sales.Orders AS O1;
-- T-SQL supports window functions called LAG and LEAD that you use to obtain elements
-- from a previous or next row much more easily

	-- Using Running Aggregates
/*	Running aggregates are aggregates that accumlate value based on some order. In the next
	example, for the earliest year recorded in the view(2014), the running total is equal
	to that year's quantity. For the second year(2015), the running total is the sum of the 
	first year plus the second year, and so on.	*/
SELECT orderyear, qty,
	(SELECT SUM(O2.qty)
	 FROM Sales.OrderTotalsByYear AS O2
	 WHERE O2.orderyear <= O1.orderyear) AS runqty
FROM Sales.OrderTotalsByYear AS O1
ORDER BY orderyear;
-- T-SQL supports window aggregate function that compute running totals more easily/efficiently

	-- Dealing with Misbehaving Subqueries
/*	When you use the NOT IN predicate against a subquery that returns at least one NULL, the
	query always returns an empty set. If you want to check wether a customerid appears only
	in the set of known values, you should exclude the NULLs - either explicitly or implicitly.
	To exclude them explicitly, add the predicate O.custid IS NOT NULL to the subquery like this.*/
SELECT custid, companyname
FROM Sales.Customers
WHERE custid NOT IN(SELECT O.custid
					FROM Sales.Orders AS O
					WHERE O.custid IS NOT NULL);
-- You can also exclude NULLs implicitly by using the NOT EXISTS predicate instead of NOT IN
SELECT custid, companyname
FROM Sales.Customers AS C
WHERE NOT EXISTS
	(SELECT *
	 FROM Sales.Orders AS O
	 WHERE O.custid = C.custid);
-- EXISTS always returns TRUE or FALSE and never UNKNOWN
-- It is safer to use NOT EXISTS then NOT IN because EXISTS handles known customerids only.


	-- CHAPTER 4 EXERCISES

-- Write a query that returns all orders placed on the last day of activity that can
-- be found in the Orders table
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders 
WHERE orderdate = 
		(SELECT MAX(O.orderdate)
		 FROM Sales.Orders AS O);

-- Write a query that returns all orders placed by the customer(s) who placed the highest 
-- number of orders. Note that more than one customer might have the same number of orders
SELECT TOP (1) WITH TIES O.custid
FROM Sales.Orders AS O
GROUP BY O.custid
ORDER BY COUNT(*) DESC;

SELECT custid, orderid, orderdate, empid 
FROM Sales.Orders 
WHERE custid IN
	(SELECT TOP (1) WITH TIES O.custid
	FROM Sales.Orders AS O
	GROUP BY O.custid
	ORDER BY COUNT(*) DESC);

-- Write a query that returns employees who did not place orders on or after May 1, 2016
SELECT E.empid, E.firstname, E.lastname
FROM HR.Employees AS E
WHERE E.empid NOT IN
	(SELECT O.empid
	 FROM Sales.Orders AS O
	 WHERE O.orderdate >= '20160501');

-- Write a query that returns countries where there are customers but not employees 
SELECT DISTINCT country
FROM Sales.Customers 
WHERE country NOT IN
	(SELECT E.country FROM HR.Employees AS E);

-- Write a query that returns for each customer all orders placed on the customer's 
-- last day of activity 
SELECT custid, orderid, orderdate, empid
FROM Sales.Orders AS O1
WHERE orderdate =
		(SELECT MAX(O2.orderdate)
		 FROM Sales.Orders AS O2
		 WHERE O2.custid = O1.custid)
ORDER BY custid;

-- Write a query that returns customers who placed orders in 2015 but not in 2016
SELECT DISTINCT custid, companyname
FROM Sales.Customers AS C
WHERE EXISTS
	(SELECT *
	 FROM Sales.Orders AS O
	 WHERE O.custid = C.custid
		AND O.orderdate >= '20150101'
		AND O.orderdate < '20160101')
	AND NOT EXISTS
	(SELECT *
	 FROM Sales.Orders AS O
	 WHERE O.custid = C.custid
		AND O.orderdate >= '20160101'
		AND O.orderdate < '20170101');

-- Write a query that returns customers who ordered product 12
SELECT custid, companyname
FROM Sales.Customers AS C
WHERE EXISTS
	(SELECT *
	 FROM Sales.Orders AS O
	 WHERE O.custid = C.custid 
	 AND EXISTS
	 (SELECT *
	  FROM Sales.OrderDetails AS OD
	  WHERE OD.orderid = O.orderid
		AND OD.productid = 12));

-- Write a query that calculates a running total quantity for each customer and month
SELECT custid, ordermonth, qty, 
	(SELECT SUM(O.qty)
	 FROM Sales.CustOrders AS O
	 WHERE C.custid = O.custid
		AND O.ordermonth <= C.ordermonth) AS runqty 
FROM Sales.CustOrders AS C
ORDER BY custid, ordermonth;

-- Explain the difference between IN and EXISTS
/*	The IN predicate uses 3 valued predicate logic wheres EXISTS uses 2 valued.
	NOT IN returns UNKNOWN where NOT EXISTS returns TRUE when dealing with NULLs.	*/

-- Write a query that returns for each order the number of days that passed since the
-- same customers previous order. To determine recency among orders, use orderdate
-- as the primary sort element and orderid as the tiebreaker. 
SELECT custid, orderdate, orderid, 
	DATEDIFF(day,
		(SELECT TOP(1) O2.orderdate
		 FROM Sales.Orders AS O2
		 WHERE O2.custid = O1.custid
		  AND (	O2.orderdate = O1.orderdate AND O2.orderid < O1.orderid
				OR O2.orderdate < O1.orderdate )
		ORDER BY O2.orderdate DESC, O2.orderid DESC),
		orderdate) AS diff
FROM Sales.Orders AS O1
ORDER BY custid, orderdate, orderid;


	-- CHAPTER 5 TABLE EXPRESSIONS

/*	A table expression is a named query expression that represents a valid relational table.
	4 types of table expressions: Derived, Common(CTE's), Views, and Inline Table-Valued
	Fuctions(inline TVFs). Table expressions are not physically materialized anywhere,
	they are virtual. The outer query and inner query are merged into one query directly
	against the underlying objects. Table expressions also help you circumvent certain restrictions 
	in the language, such as the inability to refer to column aliases assigned in the SELECT 
	clause in query clauses that are logically processed before the SELECT clause.	*/

	-- Derived Tables
/*	Also known as table subqueries, are defined in the FROM clause of an outer query.
	You specify the query that defines the derived table within parentheses, followed by 
	the AS clause and the derived table name. For Example.	*/
USE TSQLV4;

SELECT *
FROM (SELECT custid, companyname
	  FROM Sales.Customers
	  WHERE country = N'USA') AS USACusts

	-- 3 requirements to be a valid inner query in a table expression definition
/*	1.)	Order is not guaranteed. Disallows an ORDER BY clause in queries that are used to
		define table expressions, unless ORDER BY serves a purpose other than presentation.
		Such as using (TOP or OFFSET-FETCH) filter, then using ORDER BY is for filtering. 
	2.) All columns must have names. You must assign column aliases to all expressions 
		in the SELECT list of the query that is used to define a table expression.
	3.) All column names must be unique. 
	All 3 requirements are related to the fact that the table expression is suppose to
	represent a relation. All relation attributes must have names; all attribute names 
	must be unique; and, because the relation's body is a set of tuples, there's no order.	*/

	-- Assigning Column Aliases 
/*	One of the benefits of using table expressions is that, in any clause of the outer query,
	you can refer to column aliases that were assigned in the SELECT clause of the 
	inner query. For Example. */
SELECT
	YEAR(orderdate) AS orderyear,
	COUNT(DISTINCT custid) AS numcusts
FROM Sales.Orders 
GROUP BY orderyear; -- This is invalid because it refers to an alias
-- Next, a query with a derived table using inline aliasing form
SELECT orderyear, COUNT(DISTINCT custid) AS numcusts
FROM (SELECT YEAR(orderdate) AS orderyear, custid
	  FROM Sales.Orders) AS D -- Creates a derived table called "D"
GROUP BY orderyear; -- Allows you to refer to column aliases
-- Table expressions are usually for logical(not performance) related reasons.

-- This is an example of external aliasing 
SELECT orderyear, COUNT(DISTINCT custid) AS numcusts
FROM (SELECT YEAR(orderdate), custid
	  FROM Sales.Orders) AS D(orderyear, custid) -- external alias
GROUP BY orderyear;
-- External aliasing is best when the table expression won't undergo further revision.

	-- Using Arguments
/*	In the query that defines a derived table, you can refer to arguments. The arguments
	can be local variables and input parameters to a routine, such as a stored procedure
	or function. For Example.	*/
DECLARE @empid AS INT = 3;

SELECT orderyear, COUNT(DISTINCT custid) AS numcusts
FROM (SELECT YEAR(orderdate) AS orderyear, custid
	  FROM Sales.Orders
	  WHERE empid = @empid) AS D
GROUP BY orderyear;

	-- Nesting
/*	If you need to define a derived table based on a query that itself is based on
	a derived table, you can nest those. For Example. */
SELECT orderyear, numcusts
FROM (SELECT orderyear, COUNT(DISTINCT custid) AS numcusts
	  FROM (SELECT YEAR(orderdate) AS orderyear, custid
			FROM Sales.Orders) AS D1
	  GROUP BY orderyear) AS D2
WHERE numcusts > 70;

	-- Multiple References
/*	If you define a derived table and alias it as one input of a join, you can't
	refer to the same alias in the other input of the join.	The next example is
	multiple derived tables based on the same query.	*/
SELECT Cur.orderyear,
	Cur.numcusts AS curnumcusts, Prv.numcusts AS prvnumcusts,
	Cur.numcusts - Prv.numcusts AS growth
FROM (SELECT YEAR(orderdate) AS orderyear,
		COUNT(DISTINCT custid) AS numcusts
	  FROM Sales.Orders
	  GROUP BY YEAR(orderdate)) AS Cur
	LEFT OUTER JOIN
	 (SELECT YEAR(orderdate) AS orderyear,
		COUNT(DISTINCT custid) AS numcusts
	  FROM Sales.Orders
	  GROUP BY YEAR(orderdate)) AS Prv
	ON Cur.orderyear = Prv.orderyear + 1;
/*	The fact that you cannot refer to multiple instances of the same derived table in the
	same join forces you to maintain multiple copies of the same query definition.
	This leads to lengthy code.	*/

	-- Common Table Expressions
/*	Common Table Expressions (CTEs) are another standard form of table expression similiar to
	derived tables, yet with a couple of important advantages.
	CTEs are defined by using the WITH statement and having the following general form.
	WITH <CTE_NAME.[(<target_column_list>)]
	AS
	(
		<inner_query_defining_CTE>
	)
	<outer_query_against_CTE>;	*/
WITH USACusts AS
(
	SELECT custid, companyname
	FROM Sales.Customers
	WHERE country = N'USA'
)
SELECT * FROM USACusts;
-- AS with derived tables, as soon as the outer query finishes, the CTE goes out of scope

	-- Assigning Column Aliases in CTEs
/*	CTEs also support inline or external column aliasing.	*/
-- Inline Alias
WITH C AS
(
	SELECT YEAR(orderdate) AS orderyear, custid
	FROM Sales.Orders
)
SELECT orderyear, COUNT(DISTINCT custid) AS numcusts
FROM C
GROUP BY orderyear;
-- External Alias
WITH C(orderyear, custid) AS
(
	SELECT YEAR(orderdate), custid
	FROM Sales.Orders
)
SELECT orderyear, COUNT(DISTINCT custid) AS numcusts
FROM C
GROUP BY orderyear;

	-- Using Arguments in CTEs
DECLARE @empidex AS INT = 3;

WITH C AS 
(
	SELECT YEAR(orderdate) As orderyear, custid
	FROM Sales.Orders
	WHERE empid = @empidex
)
SELECT orderyear, COUNT(DISTINCT custid) AS numcusts
FROM C
GROUP BY orderyear;

	-- Defining Multiple CTEs
/*	CTEs have serveral advantages over derived tables. One is that if you need to refer from
	one CTE to another, you don't nest them; rather, you seperate them by commas. Each
	CTE can refer to all previously defined CTEs, and the outer query can refer to all CTEs	*/
WITH C1 AS
(
	SELECT YEAR(orderdate) AS orderyear, custid 
	FROM Sales.Orders
),
C2 AS
(
	SELECT orderyear, COUNT(DISTINCT custid) AS numcusts
	FROM C1
	GROUP BY orderyear
)
SELECT orderyear, numcusts
FROM C2
WHERE numcusts > 70;
-- You cannot nest CTEs of define them within the parentheses of a derived table 

	-- Multiple References in CTEs
/*	The fact that a CTE is named and dervied first and then queried has another advantage:
	as far as the FROM clause of the outer query is concerned, the CTE already exists;
	therefore, you can refer to multiple instances of the same CTE in table operators
	like joins. For Example	*/
WITH YearlyCount AS
(
	SELECT YEAR(orderdate) AS orderyear,
		COUNT(DISTINCT custid) AS numcusts
	FROM Sales.Orders
	GROUP BY YEAR(orderdate)
)
SELECT Cur.orderyear,
	Cur.numcusts AS curnumcusts, Prv.numcusts AS prvnumcusts,
	Cur.numcusts - Prv.numcusts AS growth
FROM YearlyCount AS Cur
	LEFT OUTER JOIN YearlyCount AS Prv -- Joining multiple instances of the same CTE
	ON Cur.orderyear = Prv.orderyear + 1;
-- You only need to maintain one copy of the inner query
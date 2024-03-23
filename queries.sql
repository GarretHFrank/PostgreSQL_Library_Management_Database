--=================== STORED PROCEDURE QUERY QUESTIONS =================================== */

--#1- How many copies of the book titled with a specific titile are owned by a specificied library branch? */
CREATE OR REPLACE FUNCTION book_copies_at_branch(
  book_title varchar(70), 
  branch_name varchar(70)
)
RETURNS TABLE (
  "Branch_ID" integer,
  "Branch_Name" varchar(70),
  "Number_of_Copies" integer,
  "Book_Title" varchar(70)
)
AS $$
BEGIN
  RETURN QUERY
  SELECT copies.book_copies_branchid AS "Branch_ID",
         branch.library_branch_branchname AS "Branch_Name",
         copies.book_copies_no_of_copies AS "Number_of_Copies",
         book.book_title AS "Book_Title"
  FROM tbl_book_copies AS copies
       INNER JOIN tbl_book AS book ON copies.book_copies_BookID = book.book_bookid
       INNER JOIN tbl_library_branch AS branch ON copies.book_copies_branchid = branch.library_branch_branchid
  WHERE book.book_title = book_copies_at_branch.book_title AND branch.library_branch_branchname = book_copies_at_branch.branch_name;
END;
$$
LANGUAGE plpgsql;

SELECT * FROM book_copies_at_branch('It', 'Central');


/* #2- Retrieve the names of all borrowers who have any books checked out. */

CREATE OR REPLACE FUNCTION book_loaned_out()
RETURNS TABLE (
  "Borrower_Name" varchar(70) 
)
AS $$
BEGIN
  RETURN QUERY
  SELECT borrower.borrower_borrowername AS "Borrower_Name"
  FROM tbl_borrower AS borrower
  WHERE EXISTS  (  SELECT *
  				  FROM tbl_book_loans AS loans
   				  WHERE loans.book_loans_CardNo = borrower.borrower_cardno
			   );
END;
$$
LANGUAGE plpgsql;

SELECT * FROM book_loaned_out();


/* #3- For each book that is loaned out from the specified branch and whose DueDate is today, retrieve the book title, the borrower's name, and the borrower's address.  */

CREATE OR REPLACE FUNCTION loaner_info(
	book_due_date character varying,
	branch_name varchar(70)
)
RETURNS TABLE (
    "Date_Out" date,
    "Branch_Name" varchar(70),
	"Book_Title" varchar(70),
	"Borrowers_Name" varchar(70),
	"Borrowers_Address" varchar(70)
)
AS $$
BEGIN
  RETURN QUERY
  SELECT  
    loans.book_loans_dateout AS "Date_Out",
  	branch.library_branch_branchname AS "Branch_Name",
	book.book_title AS "Book_Title",
  	borrower.borrower_borrowername AS "Borrower_Name",
	borrower.borrower_borroweraddress AS "Borrower_Address"
  FROM tbl_book_loans AS loans
  INNER JOIN tbl_book AS book ON loans.book_loans_bookid = book.book_bookid
  INNER JOIN tbl_borrower AS borrower ON loans.book_loans_cardno = borrower.borrower_cardno
  INNER JOIN tbl_library_branch as branch ON loans.book_loans_branchid = branch.library_branch_branchid
  WHERE loans.book_loans_duedate = loaner_info.book_due_date::date 
  		AND branch.library_branch_branchname = loaner_info.branch_name;

END;
$$
LANGUAGE plpgsql;

SELECT * FROM loaner_info('2018-02-02','Sharpstown') ;


/* #4- Retrieve the names, addresses, and number of books checked out for all borrowers who have more than five books checked out. */

CREATE OR REPLACE FUNCTION books_loaned_out(
	books_checked_out integer
)
RETURNS TABLE (
	"Borrowers_Name" varchar(70),
	"Borrowers_Address" varchar(70),
	"Books_Checked_Out" integer
)
AS $$
BEGIN
  RETURN QUERY
  SELECT  
  	borrower.borrower_borrowername AS "Borrower_Name",
	borrower.borrower_borroweraddress AS "Borrower_Address",
	COUNT(borrower.borrower_borrowername)::integer  AS "Books_Checked_Out"
  FROM tbl_book_loans AS loans
  INNER JOIN tbl_borrower AS borrower ON loans.book_loans_cardno = borrower.borrower_cardno
  GROUP BY borrower.borrower_borrowername, borrower.borrower_borroweraddress
  HAVING COUNT (borrower.borrower_borrowername) > books_loaned_out.books_checked_out
  ORDER BY borrower.borrower_borrowername;
END;
$$
LANGUAGE plpgsql;

SELECT * FROM books_loaned_out(5) ;


/* #5- For each book authored by "Stephen King", retrieve the title and the number of copies owned by the library branch specified.*/

CREATE OR REPLACE FUNCTION book_author_at_branch(
    author_name varchar(70), 
    branch_name varchar(70)
)
RETURNS TABLE (
    "Branch_Name" varchar(70),
    "Book_Title" varchar(70),
    "Number_of_Copies" integer,
	"Total_Copies_per_author" integer
)
AS $$
BEGIN
  RETURN QUERY
  SELECT
	 branch.library_branch_branchname AS "Branch_Name",
	 book.book_title AS "Book_Title",
	 copies.book_copies_no_of_copies AS "Number_of_Copies",
	 SUM(copies.book_copies_no_of_copies) OVER (PARTITION BY authors.book_authors_authorname)::integer AS "Total_Copies_per_author"
  FROM tbl_book_authors AS authors
       INNER JOIN tbl_book AS book ON authors.book_authors_bookid = book.book_bookid
	   INNER JOIN tbl_book_copies AS copies ON authors.book_authors_bookid = copies.book_copies_bookid
       INNER JOIN tbl_library_branch AS branch ON copies.book_copies_branchid = branch.library_branch_branchid
  WHERE authors.book_authors_authorname = book_author_at_branch.author_name 
  	   AND branch.library_branch_branchname = book_author_at_branch.branch_name;
END;
$$
LANGUAGE plpgsql;

SELECT * FROM book_author_at_branch('Stephen King', 'Sharpstown');
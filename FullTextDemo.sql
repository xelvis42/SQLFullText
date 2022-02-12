USE FullTextDemo

-- Full Text Search Overview
-- https://msdn.microsoft.com/en-us/library/ms142571(v=sql.110).aspx

-----------------------------------------
-- char, varchar, nchar, nvarchar, text, ntext columns
-----------------------------------------

	-----------------------------------------
	--creating FULL TEXT INDEX to search char, varchar, nchar, nvarchar, text, ntext columns
	-----------------------------------------

	--Creates a full-text catalog for a database. One full-text catalog can have several full-text indexes, 
	--but a full-text index can only be part of one full-text catalog. 
	-- https://msdn.microsoft.com/en-us/library/ms189520.aspx
	CREATE FULLTEXT CATALOG problem_catalog;

	--create a unique index on the table that is being indexed for full text search
	-- https://msdn.microsoft.com/en-us/library/ms188783.aspx
	CREATE UNIQUE INDEX ui_problemID ON dbo.Problem(problemID)

	--Creates a full-text index on a table or indexed view (https://msdn.microsoft.com/en-us/library/ms191432.aspx) in a database in SQL Server. 
	--Only one full-text index is allowed per table or indexed view, and each full-text index applies to a single table or indexed view. 
	--A full-text index can contain up to 1024 columns.
	-- https://msdn.microsoft.com/en-us/library/ms187317.aspx
	CREATE FULLTEXT INDEX ON dbo.Problem (
	ControlNo LANGUAGE 1033,
	Post LANGUAGE 1033,
	Problem LANGUAGE 1033)
	KEY INDEX ui_problemID ON problem_catalog;

	-------------------------------------------------------------------------
	--Searching char, varchar, nchar, nvarchar, text, ntext columns with FULL TEXT queries
	-------------------------------------------------------------------------

		--------------------------------
		--CONTAINS - https://msdn.microsoft.com/en-us/library/ms187787.aspx
		--------------------------------
		--CONTAINS can search for: 
		--	A word or phrase.
		--	The prefix of a word or phrase.
		--	A word near another word.
		--	A word inflectionally generated from another (for example, the word drive is the inflectional stem of drives, drove, driving, and driven).
		--	A word that is a synonym of another word using a thesaurus (for example, the word "metal" can have synonyms such as "aluminum" and "steel").
		
		--looks for any row in dbo.Problem that contains "provides"
		SELECT Problem FROM dbo.Problem
		WHERE CONTAINS(*, 'provides');

		--looks for any row in dbo.Problem that contains "provide"
		SELECT Problem FROM dbo.Problem
		WHERE CONTAINS(*, 'provide');

		--looks for any row in dbo.Problem that contains the prefix "pro"
		SELECT Problem FROM dbo.Problem
		WHERE CONTAINS(*, '"pro*"');

		--will look for inflectional forms of words (can also specify use of thesaurus)
		SELECT Problem FROM dbo.Problem
		WHERE CONTAINS(*, 'FORMSOF(INFLECTIONAL, provides)');

		--this will return any row where the two words are within 5 search terms
		SELECT Problem FROM dbo.Problem
		WHERE CONTAINS(* , 'NEAR((dumpster,requested),5)');

		--adding true means the words have to appear in that order, false is the default
		SELECT Problem FROM dbo.Problem
		WHERE CONTAINS(* , 'NEAR((dumpster,requested),5, TRUE)');

		--------------------------------
		--FREETEXT - https://msdn.microsoft.com/en-us/library/ms176078.aspx
		--------------------------------
		--FREETEXT searches for values that match the meaning and not just the exact wording of the words in the search condition

		--with freetext don't have to specify inflectional (or thesaurus) results 
		SELECT Problem FROM dbo.Problem
		WHERE FREETEXT(*, 'provides');

		--returns all rows with inflectional forms of dumpster and/or requested
		SELECT Problem FROM dbo.Problem
		WHERE FREETEXT(*, 'dumpster requested');

		--------------------------------
		--FREETEXTTABLE - https://msdn.microsoft.com/en-us/library/ms177652.aspx
		--CONTAINSTABLE - https://msdn.microsoft.com/en-us/library/ms189760.aspx
		--------------------------------
		--used for the same kinds of matches as FREETEXT and CONTAINS, but returns a relevance ranking value and key for each row
		--provides relative ranking of results which has no meaning outside the table
		SELECT * FROM CONTAINSTABLE(dbo.Problem, * , 'NEAR((dumpster,requested),5)');
		SELECT * FROM FREETEXTTABLE(dbo.Problem, *, 'dumpster requested')

		--can be used to find the top results using INNER JOIN and ORDER BY/SELECT TOP # 
		SELECT f.RANK, p.problemID, p.Problem
		FROM dbo.Problem AS p 
		INNER JOIN FREETEXTTABLE(dbo.Problem, *, 'dumpster requested') AS f
		ON p.problemID = f.[KEY]
		ORDER BY f.RANK DESC

-----------------------------------------
-- Comparison between FREETEXT and LIKE 
-----------------------------------------
SELECT Problem FROM dbo.Problem 
WHERE FREETEXT(*, 'provide');

SELECT Problem FROM dbo.Problem
WHERE Problem LIKE '% provide%' OR Problem LIKE 'provide%';

-----------------------------------------
-- varbinary(MAX) columns
-----------------------------------------

	--------------------------------------------------------------------
	--INFORMATION ABOUT SUPPORTED DOC TYPES
	--------------------------------------------------------------------

	--list of all full text index supported document types
	-- https://msdn.microsoft.com/en-us/library/ms174373.aspx
	SELECT * FROM sys.fulltext_document_types

	-----------------------------------------
	--creating FULL TEXT INDEX to search varbinary(MAX) columns
	-----------------------------------------

	CREATE FULLTEXT CATALOG documents_catalog;
	CREATE UNIQUE INDEX ui_documentID ON dbo.Document(documentID)
	
	--designating the associated TYPE COLUMN is necessary when indexing a varbinary(MAX) column	
	CREATE FULLTEXT INDEX ON dbo.Document (
	documentName LANGUAGE 1033,
	documentBinary TYPE COLUMN documentExtension LANGUAGE 1033)
	KEY INDEX ui_documentID ON documents_catalog;

	-------------------------------------------------------------------------
	--Searching varbinary(MAX) columns with FULL TEXT queries
	-------------------------------------------------------------------------

		--------------------------------
		--CONTAINS - https://msdn.microsoft.com/en-us/library/ms187787.aspx
		--------------------------------
		
		--looks for any row in dbo.Document that contains "donut"
		SELECT * FROM dbo.Document		
		WHERE CONTAINS(*, 'donut');

		--looks for any row in dbo.Document that contains "donuts"
		SELECT * FROM dbo.Document		
		WHERE CONTAINS(*, 'donuts');

		--looks for any row in dbo.Document that contains "donuts" and is an email message
		SELECT * FROM dbo.Document		
		WHERE CONTAINS(*, 'donuts') AND documentExtension = '.msg';

		--------------------------------
		--FREETEXT - https://msdn.microsoft.com/en-us/library/ms176078.aspx
		--------------------------------
		--FREETEXT searches for values that match the meaning and not just the exact wording of the words in the search condition

		--with freetext don't have to specify inflectional (or thesaurus) results 
		SELECT * FROM dbo.Document
		WHERE FREETEXT(*, 'donut');

		--returns all rows with inflectional forms of donut and treat
		SELECT * FROM dbo.Document
		WHERE FREETEXT(*, 'donut treat');

		--------------------------------
		--FREETEXTTABLE - https://msdn.microsoft.com/en-us/library/ms177652.aspx
		--CONTAINSTABLE - https://msdn.microsoft.com/en-us/library/ms189760.aspx
		--------------------------------
		--used for the same kinds of matches as FREETEXT and CONTAINS, but returns a relevance ranking value and key for each row
		--provides relative ranking of results which has no meaning outside the table
		SELECT * FROM CONTAINSTABLE(dbo.Document, * , 'donuts');
		SELECT * FROM FREETEXTTABLE(dbo.Document, *, 'donut')

		--can be used to find the top results using INNER JOIN and ORDER BY/SELECT TOP # 
		SELECT f.RANK, p.documentID, p.documentName
		FROM dbo.Document AS p 
		INNER JOIN FREETEXTTABLE(dbo.Document, *, 'donut') AS f
		ON p.documentID = f.[KEY]
		ORDER BY f.RANK DESC

		--------------------------------------------------------------------
		--SEARCH PROPERTY LISTS - https://msdn.microsoft.com/en-us/library/ee677637(v=sql.110).aspx
		--------------------------------------------------------------------

		--creating search property list
		-- https://msdn.microsoft.com/en-us/library/ee677625(v=sql.110).aspx
		CREATE SEARCH PROPERTY LIST document_SPL;

		--add properties to search, must include:
		--Title, PROPERTY_SET_GUID, PROPERTY_INT_ID, and PROPERTY_DESCRIPTION
		--most windows/microsoft property info can be found at https://msdn.microsoft.com/library/dd561977.aspx
		--other properties can be found using the filtdump.exe utility
		-- https://msdn.microsoft.com/en-us/library/ee677605(v=sql.110).aspx
		ALTER SEARCH PROPERTY LIST document_SPL
		   ADD 'System.Author'
		   WITH ( PROPERTY_SET_GUID = 'F29F85E0-4FF9-1068-AB91-08002B27B3D9', PROPERTY_INT_ID = 4, 
			  PROPERTY_DESCRIPTION = 'System.Author - Author of the item.' );
		ALTER SEARCH PROPERTY LIST document_SPL
		   ADD 'System.Company'
		   WITH ( PROPERTY_SET_GUID = 'D5CDD502-2E9C-101B-9397-08002B2CF9AE', PROPERTY_INT_ID = 15, 
			  PROPERTY_DESCRIPTION = 'System.Company - Company of the item.' );
		ALTER SEARCH PROPERTY LIST document_SPL
		   ADD 'System.Document.WordCount'
		   WITH ( PROPERTY_SET_GUID = 'F29F85E0-4FF9-1068-AB91-08002B27B3D9', PROPERTY_INT_ID = 15, 
			  PROPERTY_DESCRIPTION = 'System.Document.WordCount' );
		
		--associate property list with full text index
		-- https://msdn.microsoft.com/en-us/library/ms188359(v=sql.110).aspx
		ALTER FULLTEXT INDEX ON dbo.Document
		SET SEARCH PROPERTY LIST = document_SPL;

		--use CONTAINS search to search properties
		SELECT documentName FROM dbo.Document
		WHERE CONTAINS ( PROPERTY ( documentBinary, 'System.Company' ), '"Social Security Administration"')

--------------------------------------------------------------------
--INFORMATION ABOUT FULL TEXT INDEXES
--------------------------------------------------------------------

--a list of all columns with full text indexes withing the database
-- https://msdn.microsoft.com/en-us/library/ms188335.aspx
SELECT o.name AS [Table Name], c.name AS [Column Name], fic.type_column_id, fl.name AS [Language Name]
FROM sys.fulltext_index_columns AS fic
INNER JOIN sys.objects AS o
ON o.object_id = fic.object_id
INNER JOIN sys.columns AS c
ON (o.object_id = c.object_id AND fic.column_id = c.column_id)
INNER JOIN sys.fulltext_languages AS fl
ON fic.language_id = fl.lcid

--info about system stopwords
-- https://msdn.microsoft.com/en-us/library/cc280523.aspx
SELECT * FROM sys.fulltext_system_stopwords

--count of stopwords by language
SELECT l.name AS [Language], COUNT(s.stopword) AS [Stopword Count] FROM sys.fulltext_system_stopwords AS s
INNER JOIN sys.fulltext_languages AS l
ON l.lcid = s.language_id
GROUP BY l.name
ORDER BY [Stopword Count] ASC

--list of English stopwords
SELECT stopword FROM sys.fulltext_system_stopwords WHERE language_id = '1033'

--shows list of indexed words by table
-- https://msdn.microsoft.com/en-us/library/cc280900.aspx
SELECT * FROM sys.dm_fts_index_keywords(DB_ID('FullTextDemo'), OBJECT_ID('dbo.Problem'))
SELECT * FROM sys.dm_fts_index_keywords(DB_ID('FullTextDemo'), OBJECT_ID('dbo.Document'))

--shows list of indexed words by document/row
-- https://msdn.microsoft.com/en-us/library/cc280607.aspx
SELECT * FROM sys.dm_fts_index_keywords_by_document(DB_ID('FullTextDemo'), OBJECT_ID('dbo.Problem'))
SELECT * FROM sys.dm_fts_index_keywords_by_document(DB_ID('FullTextDemo'), OBJECT_ID('dbo.Document'))

--list of indexed words by document joined with document name
SELECT ud.documentName, kbd.display_term, kbd.occurrence_count
FROM sys.dm_fts_index_keywords_by_document(DB_ID('FullTextDemo'), OBJECT_ID('dbo.Document')) AS kbd
INNER JOIN dbo.Document AS ud
ON ud.documentID = kbd.document_id
ORDER BY documentName, occurrence_count DESC, display_term

--list of indexed search property terms
-- https://msdn.microsoft.com/en-us/library/ee677646.aspx
SELECT * FROM sys.dm_fts_index_keywords_by_property(DB_ID('FullTextDemo'), OBJECT_ID('dbo.Document'))

--list of indexed search property terms joined together to show document name and property type
-- https://msdn.microsoft.com/en-us/library/ee677608.aspx
SELECT d.documentName AS [Document Name], kbp.display_term AS [Display Term], rsp.property_name AS Property
FROM sys.dm_fts_index_keywords_by_property(DB_ID('FullTextDemo'), OBJECT_ID('dbo.Document')) AS kbp
INNER JOIN dbo.Document AS d
ON d.documentID = kbp.document_id
INNER JOIN sys.registered_search_properties AS rsp
ON kbp.property_id = rsp.property_id

--sys.dm_fts_parser() returns the final tokenization result after applying a given word breaker, thesaurus, and stoplist combination to a query string input. 
--The tokenization result is equivalent to the output of the Full-Text Engine for the specified query string
-- https://msdn.microsoft.com/en-us/library/cc280463.aspx
SELECT * FROM sys.dm_fts_parser('"The tokenization result is equivalent to the output of the Full-Text Engine for the specified query string."', 1033, 0, 0);

--same query, but Exact Match only
SELECT display_term FROM sys.dm_fts_parser('"The tokenization result is equivalent to the output of the Full-Text Engine for the specified query string."', 1033, 0, 0)
WHERE special_term = 'Exact Match'

--by using sys.dm_fts_parser with FORMSOF(FREETEXT), can see what other forms of a word will match. 
--this will pull up inflectional and thesaurus matches
SELECT * FROM sys.dm_fts_parser ('FORMSOF(FREETEXT, "ran")', 1033, 0, 0)

--Configure and Manage Thesaurus Files for Full-Text Search
--Thesaurus matching occurs for all FREETEXT and FREETEXTABLE queries and for any CONTAINS and CONTAINSTABLE queries that specify the FORMSOF THESAURUS clause
https://msdn.microsoft.com/en-us/library/ms142491(v=sql.110).aspx

--------------------------------------------------------------------
--Using FILTDUMP.EXE to determine search properties
--------------------------------------------------------------------

--This utility is located @ C:\Program Files\Windows Kits\8.0\bin\x86\filtdump.exe
--filtdump should be run in the same directory as the file
--Recommend creating a batch file with PAUSE so the cmd prompt window does not close.
--To run from the desktop:
	--copy filtdump.exe and file to a common location
	--create batch file in Notepad
		--[pathname]\filtdump [filename]
		--PAUSE
	--execute batch file

--Below is an example of what is returned for a system property. For the document that was "dumped" the property System.Document.WordCount has a value of 20. 
--The PROPERTY_SET_GUID and PROPERTY_INT_ID that are needed for ALTER SEARCH PROPERTY LIST are in the Attribute Line. In this case F29F85E0-4FF9-1068-AB91-08002B27B3D9 and 15, respectively. 

--CHUNK: ---------------------------------------------------------------
--    Attribute = {F29F85E0-4FF9-1068-AB91-08002B27B3D9}\15 (System.Document.WordCount)
--    idChunk = 14
--    BreakType = 3 (Paragraph)
--    Flags (chunkstate) =  (Value)
--    Locale = 0 (0x0)
--    IdChunkSource = 14
--    cwcStartSource = 0
--    cwcLenSource = 0

--VALUE: ---------------------------------------------------------------
--Type = 3 (0x3), VT_I4
--Value = "20"


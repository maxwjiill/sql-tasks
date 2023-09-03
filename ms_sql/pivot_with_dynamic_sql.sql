
-------------------------------------------------
/*----------- �������� ������� ��� ������� (������������) ----*/
-------------------------------------------------

--CREATE TABLE dbo.testtable (Object char(1), Subject char(1), Amount int)

--INSERT INTO dbo.testtable (Object, Subject, Amount) VALUES 
--('A', 'Q', 1),
--('B', 'W', 2),
--('C', 'E', 3),
--('D', 'Q', 8),
--('F', 'W', 5),
--('G', 'Q', 3),
--('A', 'Q', 9),
--('A', 'W', 9),
--('D', 'E', 7)





-------------------------------------------------
/*-- ���������, ���� ������������ ������� PIVOT*/
-------------------------------------------------

SELECT 
	*
FROM  
(
  SELECT Object, Subject, Amount
  FROM dbo.testtable
) AS SourceTable  
PIVOT  
(  
  SUM(Amount) 
  FOR Subject IN ([E], [Q], [W])  
) AS PivotTable; 


-------------------------------------------------------
/*-- ���������, ���� ������������ dynamic sql*/
-------------------------------------------------------

IF OBJECT_ID('tempdb..#prepTable') IS NOT NULL DROP TABLE #prepTable;

CREATE TABLE #prepTable (Obj char(1));

DECLARE @i int = 1; -- �������
DECLARE @col char(1); -- �������
DECLARE @row char(1); -- ������
DECLARE @query nvarchar(max); -- ������� ������

-- ������� ������� "��������", �� ������� Subject
WHILE @i <= (SELECT COUNT(DISTINCT Subject) FROM dbo.testtable)
BEGIN
	-- ������������ ���������� ���������� �������
	SET @col = (
		SELECT Subject FROM (
			SELECT ROW_NUMBER() OVER (ORDER BY Subject) AS RowNumber, Subject FROM (
					SELECT DISTINCT Subject FROM dbo.testtable
				) AS countDistSubj
		) AS countRowSubj WHERE RowNumber = @i
	);

	-- ���������� �������
	SET @query = 'ALTER TABLE #prepTable ADD ' + @col + ' int'

	EXEC sp_executesql @query
	-- ��������� ��������
	SET @i += 1;
END

-- ������� ����� �� ������������ �������
INSERT INTO #prepTable (Obj) SELECT DISTINCT Object FROM dbo.testtable

-- ����� ��������
SET @i = 1;

DECLARE @valueSum int; -- �������� �����

-- ���� ��� ������� ���� ��� ��������
WHILE @i <= (SELECT COUNT(*) FROM (SELECT DISTINCT Object, Subject FROM dbo.testtable) AS countSumRows)
BEGIN
	SELECT @row = Object, @col = Subject, @valueSum = Amount FROM (
			SELECT Object, Subject, SUM(Amount) AS Amount, ROW_NUMBER() OVER(ORDER BY Object) AS RowNumber FROM dbo.testtable GROUP BY Object, Subject
		) AS maintable WHERE RowNumber = @i;

	SET @query = 'UPDATE #prepTable SET ' + @col + ' = ' + CAST(@valueSum AS char(2)) + ' WHERE Obj = ''' + @row + ''''
	EXEC sp_executesql @query
	SET @i += 1;
END

SELECT * FROM #prepTable
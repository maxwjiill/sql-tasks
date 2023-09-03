
-------------------------------------------------
/*----------- Создание таблицы для задания (раскоментить) ----*/
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
/*-- Результат, если использовать функцию PIVOT*/
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
/*-- Результат, если использовать dynamic sql*/
-------------------------------------------------------

IF OBJECT_ID('tempdb..#prepTable') IS NOT NULL DROP TABLE #prepTable;

CREATE TABLE #prepTable (Obj char(1));

DECLARE @i int = 1; -- счетчик
DECLARE @col char(1); -- столбец
DECLARE @row char(1); -- строка
DECLARE @query nvarchar(max); -- будущий запрос

-- перебор будущих "столбцов", по столбцу Subject
WHILE @i <= (SELECT COUNT(DISTINCT Subject) FROM dbo.testtable)
BEGIN
	-- присваивание переменной очередного столбца
	SET @col = (
		SELECT Subject FROM (
			SELECT ROW_NUMBER() OVER (ORDER BY Subject) AS RowNumber, Subject FROM (
					SELECT DISTINCT Subject FROM dbo.testtable
				) AS countDistSubj
		) AS countRowSubj WHERE RowNumber = @i
	);

	-- добавление столбца
	SET @query = 'ALTER TABLE #prepTable ADD ' + @col + ' int'

	EXEC sp_executesql @query
	-- инкремент счетчика
	SET @i += 1;
END

-- вставка строк из существующей таблицы
INSERT INTO #prepTable (Obj) SELECT DISTINCT Object FROM dbo.testtable

-- сброс счетчика
SET @i = 1;

DECLARE @valueSum int; -- значение суммы

-- цикл для вставки сумм как значений
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
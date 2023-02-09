-- 学习用pgsql表
-- 1，创建表

CREATE TABLE weather (
    city            varchar(80),
    temp_lo         int,           -- 最低温度
    temp_hi         int,           -- 最高温度
    prcp            real,          -- 湿度
    date            date
);

-- 2，删除表
DROP TABLE tablename;

-- 3，向表里插入数据
-- 不明文制定列
INSERT INTO weather VALUES ('San Francisco', 46, 50, 0.25, '1994-11-27');
-- 明文指定列
INSERT INTO weather (city, temp_lo, temp_hi, prcp, date)
    VALUES ('San Francisco', 43, 57, 0.0, '1994-11-29');
-- 明文不给某列加内容
INSERT INTO weather (date, city, temp_hi, temp_lo)
    VALUES ('1994-11-29', 'Hayward', 54, 37);

-- 4，查询
SELECT * FROM weather;
SELECT city, temp_lo, temp_hi, prcp, date FROM weather;
-- 请注意这里的AS子句是如何给输出列重新命名的（AS子句是可选的）。
SELECT city, (temp_hi+temp_lo)/2 AS temp_avg, date FROM weather;
-- 一个查询可以使用WHERE子句"修饰"，它指定需要哪些行。
-- WHERE子句包含一个布尔（真值）表达式，只有那些使布尔表达式为真的行才会被返回。
-- 在条件中可以使用常用的布尔操作符（AND、OR和NOT）。 
-- 比如，下面的查询检索旧金山的下雨天的天气：
SELECT * FROM weather
    WHERE city = 'San Francisco' AND prcp > 0.0;
-- 你可以要求返回的查询结果是排好序的：
SELECT * FROM weather
    ORDER BY city;
-- 在这个例子里，排序的顺序并未完全被指定，因此你可能看到属于旧金山的行被随机地排序。
-- 可以增加排序条件
SELECT * FROM weather
    ORDER BY city, temp_lo;
-- 使用DISTINCT制定通过某个key 去重
SELECT DISTINCT city
    FROM weather;

-- 5，左右全外，内：
-- （1）左右指的是左表(第一个表weather)右表(第二个表cities)；
-- （2）内指的是交集，外指的是并集；
-- 左外
-- 这个查询是一个左外连接， 因为在连接操作符左部的表中的行在输出中至少要出现一次， 
-- 而在右部的表的行只有在能找到匹配的左部表行是才被输出。 
-- 如果输出的左部表的行没有对应匹配的右部表的行，那么右部表行的列将填充空值（null）。
-- 练习：. 还有右外连接和全外连接。试着找出来它们能干什么。
SELECT *
    FROM weather LEFT OUTER JOIN cities ON (weather.city = cities.name);
-- 右外
SELECT *
    FROM weather RIGHT OUTER JOIN cities ON (weather.city = cities.name);
-- 全外
SELECT *
    FROM weather FULL OUTER JOIN cities ON (weather.city = cities.name);
-- inner呢，和outer的区别是什么
-- https://blog.csdn.net/youmoo/article/details/7821465
-- inner join  A 和 B 获得的是A和B的交集(intersect),即韦恩图(venn diagram) 相交的部分.
-- outer join A和B获得的是A和B的并集(union), 即韦恩图(venn diagram)的所有部分.
SELECT *
    FROM weather INNER JOIN cities ON (weather.city = cities.name);
-- 总结：
-- （1）OUTER JOIN有左/右/全部之分：左/右是获取左/右的全部+另外一个表符合条件的并集；
--    全部，是左右的获取全部
-- （2）INNER JOIN没有左右之分，获取交集

-- 6，自连接：我们也可以把一个表和自己连接起来
-- 比如，假设我们想找出那些在其它天气记录的温度范围之外的天气记录。
-- 这样我们就需要拿 weather表里每行的temp_lo和temp_hi列与weather表里其它行的temp_lo和temp_hi列进行比较。
-- 我们可以用下面的查询实现这个目标：
SELECT W1.city, W1.temp_lo AS low, W1.temp_hi AS high,
    W2.city, W2.temp_lo AS low, W2.temp_hi AS high
    FROM weather W1, weather W2
    WHERE W1.temp_lo < W2.temp_lo
    AND W1.temp_hi > W2.temp_hi;
-- 在上面我们把weather表重新标记为W1和W2以区分连接的左部和右部。
-- 你还可以用这样的别名在其它查询里节约一些敲键，比如：
SELECT *
    FROM weather w, cities c
    WHERE w.city = c.name;

-- 7，聚集函数
-- 子查询
SELECT max(temp_lo) FROM weather;
SELECT city FROM weather WHERE temp_lo = max(temp_lo);     -- 错误
-- 上面这个方法不能运转，
-- 因为聚集max不能被用于WHERE子句中
--（存在这个限制是因为WHERE子句决定哪些行可以被聚集计算包括；因此显然它必需在聚集函数之前被计算）。
-- 不过，我们通常都可以用其它方法实现我们的目的；这里我们就可以使用子查询：
SELECT * FROM weather
    WHERE temp_lo = (SELECT max(temp_lo) FROM weather);     -- 正确
-- 理解GROUP的例子: 把city相同的行数进行合并
-- 需要在 SELECT 的item中指明GROUP BY的item，不能直接SELECT *
SELECT city, temp_lo
    FROM weather;

"San Francisco"	46
"San Francisco"	43
"Hayward"	37

SELECT city, SUM(temp_lo)
    FROM weather
    GROUP BY city;

"Hayward"	37
"San Francisco"	89

-- WHERE GROUP HAVING
SELECT city, max(temp_lo)       -- 获取城市和最低问温度的最高值
    FROM weather                -- 从天气表
    WHERE city LIKE 'S%'(1)     -- 以S开头的city 
    GROUP BY city               -- 用city做聚集
    HAVING max(temp_lo) < 40;   -- 最低问温度的最高值低于40的
-- 理解聚集和SQL的WHERE以及HAVING子句之间的关系:
-- WHERE和HAVING的基本区别如下：WHERE在分组和聚集计算之前选取输入行
--（因此，它控制哪些行进入聚集计算）， 而HAVING在分组和聚集之后选取分组行。

-- 因此，WHERE子句不能包含聚集函数； 因为试图用聚集函数判断哪些行应输入给聚集运算是没有意义的。
-- 相反，HAVING子句总是包含聚集函数
-- （严格说来，你可以写不使用聚集的HAVING子句， 但这样做很少有用。
-- 同样的条件用在WHERE阶段会更有效）。
-- 在前面的例子里，我们可以在WHERE里应用城市名称限制，因为它不需要聚集。
-- 这样比放在HAVING里更加高效，因为可以避免那些未通过 WHERE检查的行参与到分组和聚集计算中。

-- 8，更新
-- 你可以用UPDATE命令更新现有的行
-- 假设你发现所有 11 月 28 日以后的温度读数都低了两度，那么你就可以用下面的方式改正数据：
UPDATE weather
    SET temp_hi = temp_hi - 2,  temp_lo = temp_lo - 2
    WHERE date > '1994-11-28';

-- 9，删除
-- 数据行可以用DELETE命令从表中删除
-- 假设你对Hayward的天气不再感兴趣，那么你可以用下面的方法把那些行从表中删除：
DELETE FROM weather WHERE city = 'Hayward'; -- 所有属于Hayward的天气记录都被删除。
-- 我们用下面形式的语句的时候一定要小心
DELETE FROM tablename;
-- 如果没有一个限制，DELETE将从指定表中删除所有行，把它清空。
-- 做这些之前系统不会请求你确认！

-- 10，高级特性

-- 11，视图
-- 假设天气记录和城市为止的组合列表对我们的应用有用，
-- 但我们又不想每次需要使用它时都敲入整个查询。
-- 我们可以在该查询上创建一个视图，这会给该查询一个名字，我们可以像使用一个普通表一样来使用它：
CREATE VIEW myview AS
    SELECT city, temp_lo, temp_hi, prcp, date, location
        FROM weather, cities
        WHERE city = name;
SELECT * FROM myview;
-- 用户通过始终如一的接口封装表的结构细节，这样可以避免表结构随着应用的进化而改变。
-- 视图几乎可以用在任何可以使用表的地方。在其他视图基础上创建视图也并不少见。

-- 12，外键
-- 我们希望确保在cities表中有相应项之前任何人都不能在weather表中插入行。
-- 这叫做维持数据的引用完整性。在过分简化的数据库系统中，可以通过先检查cities表中是否有匹配的记录存在，
-- 然后决定应该接受还是拒绝即将插入weather表的行。这种方法有一些问题且并不方便，
-- 于是PostgreSQL可以为我们来解决：
CREATE TABLE cities (
        city     varchar(80) primary key,
        location point
);
CREATE TABLE weather (
        city      varchar(80) references cities(city),
        temp_lo   int,
        temp_hi   int,
        prcp      real,
        date      date
);
-- 现在尝试插入一个非法的记录：
INSERT INTO weather VALUES ('Berkeley', 45, 53, 0.0, '1994-11-28');
-- 报错：
ERROR:  insert or update on table "weather" violates foreign key constraint "weather_city_fkey"
DETAIL:  Key (city)=(Berkeley) is not present in table "cities".

-- 13，事务
-- 事务是所有数据库系统的基础概念。事务最重要的一点是它将多个步骤捆绑成了一个单一的、
-- 要么全完成要么全不完成的操作。步骤之间的中间状态对于其他并发事务是不可见的，
-- 并且如果有某些错误发生导致事务不能完成，则其中任何一个步骤都不会对数据库造成影响。

-- PostgreSQL实际上将每一个SQL语句都作为一个事务来执行。如果我们没有发出BEGIN命令，
-- 则每个独立的语句都会被加上一个隐式的BEGIN以及（如果成功）COMMIT来包围它。
-- 一组被BEGIN和COMMIT包围的语句也被称为一个事务块。

-- BEGIN和COMMIT
-- 在PostgreSQL中，开启一个事务需要将SQL命令用BEGIN和COMMIT命令包围起来。
-- 因此我们的银行事务看起来会是这样：
BEGIN;
UPDATE accounts SET balance = balance - 100.00
    WHERE name = 'Alice';
-- etc etc
COMMIT;

-- ROLLBACK
-- 如果，在事务执行中我们并不想提交（或许是我们注意到Alice的余额不足），
-- 我们可以发出ROLLBACK命令而不是COMMIT命令，这样所有目前的更新将会被取消。

-- SAVEPOINT
-- 保存点允许我们有选择性地放弃事务的一部分而提交剩下的部分。
-- 在使用SAVEPOINT定义一个保存点后，我们可以在必要时利用ROLLBACK TO回滚到该保存点。
-- 该事务中位于保存点和回滚点之间的数据库修改都会被放弃，但是早于该保存点的修改则会被保存。
-- 在回滚到保存点之后，它的定义依然存在，因此我们可以多次回滚到它。
-- 反过来，如果确定不再需要回滚到特定的保存点，它可以被释放以便系统释放一些资源。
-- 记住不管是释放保存点还是回滚到保存点，都会释放定义在该保存点之前的所有其他保存点。即 只能有一个保存点
-- 假设我们从Alice的账户扣款100美元，然后存款到Bob的账户，结果直到最后才发现我们应该存到Wally的账户。
-- 我们可以通过使用保存点来做这件事：
BEGIN;
UPDATE accounts SET balance = balance - 100.00
    WHERE name = 'Alice';
SAVEPOINT my_savepoint;
UPDATE accounts SET balance = balance + 100.00
    WHERE name = 'Bob';
-- oops ... forget that and use Wally's account
ROLLBACK TO my_savepoint;
UPDATE accounts SET balance = balance + 100.00
    WHERE name = 'Wally';
COMMIT;

-- 14，窗口函数
-- 自己理解：在每一个查询到的行上建立一个窗口(某个item相同的集合)，用于展示和计算
-- 一个窗口函数在一系列与当前行有某种关联的表行上执行一种计算。
-- 这与一个聚集函数所完成的计算有可比之处。
-- 但是与通常的聚集函数不同的是，使用窗口函数并不会导致行被分组成为一个单独的输出行--行保留它们独立的标识。
-- 在这些现象背后，窗口函数可以访问的不仅仅是查询结果的当前行。
-- 下面是一个例子用于展示如何将每一个员工的薪水与他/她所在部门的平均薪水进行比较：
SELECT depname, empno, salary, avg(salary) OVER (PARTITION BY depname) FROM empsalary;
-- 理解 从empsalary查询depname...,获取通过depname分区的窗口中salary的平均值
-- 结果如下：
  depname  | empno | salary |          avg
-----------+-------+--------+-----------------------
 develop   |    11 |   5200 | 5020.0000000000000000
 develop   |     7 |   4200 | 5020.0000000000000000
 develop   |     9 |   4500 | 5020.0000000000000000
 develop   |     8 |   6000 | 5020.0000000000000000
 develop   |    10 |   5200 | 5020.0000000000000000
 personnel |     5 |   3500 | 3700.0000000000000000
 personnel |     2 |   3900 | 3700.0000000000000000
 sales     |     3 |   4800 | 4866.6666666666666667
 sales     |     1 |   5000 | 4866.6666666666666667
 sales     |     4 |   4800 | 4866.6666666666666667
(10 rows)
-- 最开始的三个输出列直接来自于表empsalary，并且表中每一行都有一个输出行。
-- 第四列表示对与当前行具有相同depname值的所有表行取得平均值
-- 这实际和一般的avg聚集函数是相同的函数，
-- 但是OVER子句使得它被当做一个窗口函数处理，并在一个合适的行集合上计算。

-- 一个窗口函数调用总是包含一个直接跟在窗口函数名及其参数之后的OVER子句。
-- 这使得它从句法上和一个普通函数或聚集函数区分开来。
-- OVER子句决定究竟查询中的哪些行被分离出来由窗口函数处理。
-- OVER子句中的PARTITION BY列表指定了将具有相同PARTITION BY表达式值的行分到组或者分区。
-- 对于每一行，窗口函数都会在当前行同一分区的行上进行计算。

-- 我们可以通过OVER上的ORDER BY控制窗口函数处理行的顺序（窗口的ORDER BY并不一定要符合行输出的顺序。）
-- 下面是一个例子：
SELECT depname, empno, salary,
       rank() OVER (PARTITION BY depname ORDER BY salary DESC) FROM empsalary;

  depname  | empno | salary | rank
-----------+-------+--------+------
 develop   |     8 |   6000 |    1
 develop   |    10 |   5200 |    2
 develop   |    11 |   5200 |    2
 develop   |     9 |   4500 |    4
 develop   |     7 |   4200 |    5
 personnel |     2 |   3900 |    1
 personnel |     5 |   3500 |    2
 sales     |     1 |   5000 |    1
 sales     |     4 |   4800 |    2
 sales     |     3 |   4800 |    2
(10 rows)

-- 如上所示，rank函数在当前行的分区内按照ORDER BY子句的顺序为每一个可区分的ORDER BY值产生了一个数字等级。
-- rank不需要显式的参数，因为它的行为完全决定于OVER子句。

-- 一个窗口函数所考虑的行属于那些通过查询的FROM子句产生并通过WHERE、GROUP BY、HAVING过滤的"虚拟表"。
-- 例如，一个由于不满足WHERE条件被删除的行是不会被任何窗口函数所见的。
-- 在一个查询中可以包含多个窗口函数，每个窗口函数都可以用不同的OVER子句来按不同方式划分数据，
-- 但是它们都作用在由虚拟表定义的同一个行集上。

-- 我们已经看到如果行的顺序不重要时ORDER BY可以忽略。
-- PARTITION BY同样也可以被忽略，在这种情况下只会产生一个包含所有行的分区。

-- 这里有一个与窗口函数相关的重要概念：对于每一行，在它的分区中的行集被称为它的窗口帧。
-- 很多（但不是全部）窗口函数只作用在窗口帧中的行上，而不是整个分区。
-- 默认情况下，如果使用ORDER BY，则帧包括从分区开始到当前行的所有行，
-- 以及后续任何与当前行在ORDER BY子句上相等的行。如果ORDER BY被忽略，
-- 则默认帧包含整个分区中所有的行。 [1] 下面是使用sum的例子：
SELECT salary, sum(salary) OVER () FROM empsalary;

 salary |  sum
--------+-------
   5200 | 47100
   5000 | 47100
   3500 | 47100
   4800 | 47100
   3900 | 47100
   4200 | 47100
   4500 | 47100
   4800 | 47100
   6000 | 47100
   5200 | 47100
(10 rows)
-- 如上所示，由于在OVER子句中没有ORDER BY，窗口帧和分区一样，
-- 而如果缺少PARTITION BY则和整个表一样。
-- 换句话说，每个合计都会在整个表上进行，这样我们为每一个输出行得到的都是相同的结果。
-- 但是如果我们加上一个ORDER BY子句，我们会得到非常不同的结果：
SELECT salary, sum(salary) OVER (ORDER BY salary) FROM empsalary;
 salary |  sum
--------+-------
   3500 |  3500
   3900 |  7400
   4200 | 11600
   4500 | 16100
   4800 | 25700
   4800 | 25700
   5000 | 30700
   5200 | 41100
   5200 | 41100
   6000 | 47100
(10 rows)
-- 这里的合计是从第一个（最低的）薪水一直到当前行，包括任何与当前行相同的行（注意相同薪水行的结果）。

-- 窗口函数只允许出现在查询的SELECT列表和ORDER BY子句中。
-- 它们不允许出现在其他地方，例如GROUP BY、HAVING和WHERE子句中。
-- 这是因为窗口函数的执行逻辑是在处理完这些子句之后。
-- 另外，窗口函数在普通聚集函数之后执行。这意味着可以在窗口函数的参数中包括一个聚集函数，但反过来不行。

-- 如果需要在窗口计算执行后进行过滤或者分组，我们可以使用子查询。例如：
SELECT depname, empno, salary, enroll_date
FROM
  (SELECT depname, empno, salary, enroll_date,
          rank() OVER (PARTITION BY depname ORDER BY salary DESC, empno) AS pos
     FROM empsalary
  ) AS ss
WHERE pos < 3;

-- 当一个查询涉及到多个窗口函数时，可以将每一个分别写在一个独立的OVER子句中。
-- 但如果多个函数要求同一个窗口行为时，这种做法是冗余的而且容易出错的。
-- 替代方案是，每一个窗口行为可以被放在一个命名的WINDOW子句中，然后在OVER中引用它。例如：
SELECT sum(salary) OVER w, avg(salary) OVER w
  FROM empsalary
  WINDOW w AS (PARTITION BY depname ORDER BY salary DESC);

-- 15，继承
-- 继承是面向对象数据库中的概念。它展示了数据库设计的新的可能性。

-- 城市表
CREATE TABLE city (
  name       text,
  population real,
  altitude   int
);
INSERT INTO city VALUES ('Las Vegas', 500000, 2174);
INSERT INTO city VALUES ('Mariposa', 500000, 1953);

-- 首府表（继承于城市表）
-- 州首都多一个附加列state用于显示它们的州，他字段自动继承自city
CREATE TABLE capitals (
  state      char(2)
) INHERITS (city);
INSERT INTO capital VALUES ('Mariposa', 500000, 845, 1);

-- 如下查询可以寻找所有海拔500尺以上的城市名称，包括州首都：
SELECT name, altitude
  FROM city
  WHERE altitude > 500;
-- 它的返回为：
   name    | altitude
-----------+----------
 Las Vegas |     2174
 Mariposa  |     1953
 Madison   |      845
(3 rows)

-- 在另一方面，下面的查询可以查找所有海拔高于500尺且不是州首府的城市
-- (即用ONLY限制查询只包含city不包含其子表capital)
-- 其中cities之前的ONLY用于指示查询只在cities表上进行而不会涉及到继承层次中位于cities之下的其他表。
SELECT name, altitude
    FROM ONLY city
    WHERE altitude > 500;

   name    | altitude
-----------+----------
 Las Vegas |     2174
 Mariposa  |     1953
(2 rows)

-- 15，词法结构
-- 15.1 关键词和标识符
SELECT * FROM MY_TABLE;
UPDATE MY_TABLE SET A = 5;
INSERT INTO MY_TABLE VALUES (3, 'hi there');
-- 上例中的SELECT、UPDATE或VALUES记号是关键词的例子，即SQL语言中具有特定意义的词。
-- 记号MY_TABLE和A则是标识符的例子。
-- 15.2 大小写
-- 关键词和不被引号修饰的标识符是大小写不敏感的。因此：
UPDATE MY_TABLE SET A = 5;
-- 可以等价地写成：
uPDaTE my_TabLE SeT a = 5;
-- 一个常见的习惯是将关键词写成大写，而名称写成小写，例如：
UPDATE my_table SET a = 5;
-- 15.3 受限标识符或被引号修饰的标识符
-- （1）它是由双引号（"）包围的一个任意字符序列。
-- 一个受限标识符总是一个标识符而不会是一个关键字。
-- 因此"select"可以用于引用一个名为"select"的列或者表，
-- 而一个没有引号修饰的select则会被当作一个关键词，从而在本应使用表或列名的地方引起解析错误。
-- 在上例中使用受限标识符的例子如下：
UPDATE "my_table" SET "a" = 5;
-- 标识符如果要包含一个双引号，则写两个双引号
-- （2）一种受限标识符的变体允许包括转义的用代码点标识的Unicode字符
-- （3）将一个标识符变得受限同时也使它变成大小写敏感的

-- 16， 常量
-- 16.1 字符串常量
-- 在SQL中，一个字符串常量是一个由单引号（'）包围的任意字符序列，
-- 例如'This is a string'。为了在一个字符串中包括一个单引号，可以写两个相连的单引号，
-- 例如'Dianne''s horse'。注意这和一个双引号（"）不同。
-- 两个只由空白及至少一个新行分隔的字符串常量会被连接在一起，并且将作为一个写在一起的字符串常量来对待。例如：
SELECT 'foo'
'bar';
-- 等同于：
SELECT 'foobar';
-- 但是：
SELECT 'foo'      'bar';
-- 则不是合法的语法（这种有些奇怪的行为是SQL指定的，PostgreSQL遵循了该标准）

-- 16.2 C风格转义的字符串常量
反斜线转义序列	解释
\b	退格
\f	换页
\n	换行
\r	回车
\t	制表符
\o, \oo, \ooo (o = 0 - 7)	八进制字节值
\xh, \xhh (h = 0 - 9, A - F)	十六进制字节值
\uxxxx, \Uxxxxxxxx (x = 0 - 9, A - F)	16 或 32-位十六进制 Unicode 字符值
-- 跟随在一个反斜线后面的任何其他字符被当做其字面意思。因此，要包括一个反斜线字符，请写两个反斜线（\\）。
-- 在一个转义字符串中包括一个单引号除了普通方法''之外，还可以写成\'。

-- 17，操作符优先级
操作符/元素	结合性	描述
.	左	表/列名分隔符
::	左	PostgreSQL-风格的类型转换
[ ]	左	数组元素选择
+ -	右	一元加、一元减
^	左	指数
* / %	左	乘、除、模
+ -	左	加、减
（任意其他操作符）	左	所有其他本地以及用户定义的操作符
BETWEEN IN LIKE ILIKE SIMILAR	 	范围包含，设置成员，字符串匹配
< > = <= >= <>	 	比较操作符
IS ISNULL NOTNULL	 	IS TRUE、IS FALSE、IS NULL、IS DISTINCT FROM等
NOT	右	逻辑否定
AND	左	逻辑合取
OR	左	逻辑析取

-- 18，数组构造器
-- 一个数组构造器是一个能构建一个数组值并且将值用于它的成员元素的表达式。例如：
SELECT ARRAY[1,2,3+4]; => {1,2,7}

-- 默认情况下，数组元素类型是成员表达式的公共类型，
-- 使用和UNION或CASE结构（见第 10.5 节）相同的规则决定。
-- 你可以通过显式将数组构造器造型为想要的类型来重载，例如：
SELECT ARRAY[1,2,22.7]::integer[]; => {1,2,23}

-- 多维数组值可以通过嵌套数组构造器来构建。
-- 在内层的构造器中，关键词ARRAY可以被忽略。例如，这些语句产生相同的结果：
SELECT ARRAY[ARRAY[1,2], ARRAY[3,4]]; => {{1,2},{3,4}}
SELECT ARRAY[[1,2],[3,4]]; => {{1,2},{3,4}}
-- 因为多维数组必须是矩形的，处于同一层次的内层构造器必须产生相同维度的子数组。
-- 任何被应用于外层ARRAY构造器的造型会自动传播到所有的内层构造器。

-- 多维数组构造器元素可以是任何得到一个正确种类数组的任何东西，而不仅仅是一个子-ARRAY结构。例如：
CREATE TABLE arr(f1 int[], f2 int[]);
INSERT INTO arr VALUES (ARRAY[[1,2],[3,4]], ARRAY[[5,6],[7,8]]);
SELECT ARRAY[f1, f2, '{{9,10},{11,12}}'::int[]] FROM arr;
------------------------------------------------
 {{{1,2},{3,4}},{{5,6},{7,8}},{{9,10},{11,12}}}
(1 row)

-- 你可以构造一个空数组，但是因为无法得到一个无类型的数组，你必须显式地把你的空数组造型成想要的类型。例如：
SELECT ARRAY[]::integer[];
-------
 {}
(1 row)

-- 也可以从一个子查询的结果构建一个数组。在这种形式中，数组构造器被写为关键词ARRAY后跟着一个加了
-- 圆括号（不是方括号）的子查询。例如：
SELECT ARRAY(SELECT oid FROM pg_proc WHERE proname LIKE 'bytea%');
-----------------------------------------------------------------------
 {2011,1954,1948,1952,1951,1244,1950,2005,1949,1953,2006,31,2412,2413}
(1 row)
-- 子查询必须返回一个单一列。如果子查询的输出列是非数组类型， 
-- 结果的一维数组将为该子查询结果中的每一行有一个元素， 
-- 并且有一个与子查询的输出列匹配的元素类型。 
-- 如果子查询的输出列是一种数组类型，结果将是同类型的一个数组， 但是要高一个维度。
-- 在这种情况下，该子查询的所有行必须产生同样维度的数组， 否则结果就不会是矩形形式。
-- 用ARRAY构建的一个数组值的下标总是从一开始。

-- 19，行构造器
-- 一个行构造器是能够构建一个行值（也称作一个组合类型）并用值作为其成员域的表达式。例如：
SELECT ROW(1,2.5,'this is a test');
-- 当在列表中有超过一个表达式时，关键词ROW是可选的。
-- 一个行构造器可以包括语法rowvalue.*，它将被扩展为该行值的元素的一个列表，
-- 就像在一个顶层SELECT列表中使用.*时发生的事情一样。例如，如果表t有列f1和f2，那么这些是相同的：
SELECT ROW(t.*, 42) FROM t;
SELECT ROW(t.f1, t.f2, 42) FROM t;
-- 默认情况下，由一个ROW表达式创建的值是一种匿名记录类型。
-- 如果必要，它可以被造型为一种命名的组合类型 — 或者是一个表的行类型，
-- 或者是一种用CREATE TYPE AS创建的组合类型。为了避免歧义，可能需要一个显式造型。例如：
CREATE TABLE mytable(f1 int, f2 float, f3 text);
CREATE FUNCTION getf1(mytable) RETURNS int AS 'SELECT $1.f1' LANGUAGE SQL;
-- 不需要造型因为只有一个 getf1() 存在
SELECT getf1(ROW(1,2.5,'this is a test'));
 getf1
-------
     1
(1 row)
CREATE TYPE myrowtype AS (f1 int, f2 text, f3 numeric);
CREATE FUNCTION getf1(myrowtype) RETURNS int AS 'SELECT $1.f1' LANGUAGE SQL;
-- 现在我们需要一个造型来指示要调用哪个函数：
SELECT getf1(ROW(1,2.5,'this is a test'));
ERROR:  function getf1(record) is not unique
SELECT getf1(ROW(1,2.5,'this is a test')::mytable);
 getf1
-------
     1
(1 row)
SELECT getf1(CAST(ROW(11,'this is a test',2.5) AS myrowtype));
 getf1
-------
    11
(1 row)
-- 行构造器可以被用来构建存储在一个组合类型表列中的组合值，
-- 或者被传递给一个接受组合参数的函数。还有，可以比较两个行值，
-- 或者用IS NULL或IS NOT NULL测试一个行，例如：
SELECT ROW(1,2.5,'this is a test') = ROW(1, 3, 'not the same');
SELECT ROW(table.*) IS NULL FROM table;  -- detect all-null rows
-- 详见第 9.23 节。如第 9.22 节中所讨论的，行构造器也可以被用来与子查询相连接。

-- 20，调用函数(包含函数定义和调用)
-- 定义一个函数
CREATE FUNCTION concat_lower_or_upper(a text, b text, uppercase boolean DEFAULT false)
RETURNS text
AS
$$
 SELECT CASE
        WHEN $3 THEN UPPER($1 || ' ' || $2)
        ELSE LOWER($1 || ' ' || $2)
        END;
$$
LANGUAGE SQL IMMUTABLE STRICT;

-- 使用位置记号
-- 如下例子，所有参数被按照顺序指定。结果是大写形式，因为uppercase被指定为true。
SELECT concat_lower_or_upper('Hello', 'World', true);
-----------------------
 HELLO WORLD
 -- 如下例子，uppercase参数被忽略，因此它接收它的默认值false，并导致小写形式的输出。
 -- 在位置记号法中，参数可以按照从右往左被忽略(即从左到右对应)并且因此而得到默认值。
SELECT concat_lower_or_upper('Hello', 'World');
-----------------------
 hello world
-- 使用命名记号
-- 在命名记号法中，每一个参数名都用=> 指定来把它与参数表达式分隔开。例如：
SELECT concat_lower_or_upper(a => 'Hello', b => 'World');
-----------------------
 hello world
 -- 使用命名记号法的一个优点是参数可以用任何顺序指定

-- 使用混合记号
-- 混合记号法组合了位置和命名记号法。不过，正如已经提到过的，命名参数不能超越位置参数。例如：
SELECT concat_lower_or_upper('Hello', 'World', uppercase => true);
-----------------------
 HELLO WORLD
 -- 注意: 命名的和混合的调用记号法当前不能在调用聚集函数时使用（但是当聚集函数被用作窗口函数时它们可以被使用）。


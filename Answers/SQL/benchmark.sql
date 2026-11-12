-- 仅在独立性能练习库：先schema+seed，本文件只执行一次。
-- 200名合成学生、50场新活动、10000条取消历史、2000条当前报名。
-- 当前每个新增活动最多200人，容量300；时间均在报名窗口内。
CREATE TEMPORARY TABLE bench_numbers(n INT PRIMARY KEY);
INSERT INTO bench_numbers
WITH digits AS (
  SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3
  UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7
  UNION ALL SELECT 8 UNION ALL SELECT 9
)
SELECT a.n+10*b.n+100*c.n+1000*d.n
FROM digits a CROSS JOIN digits b CROSS JOIN digits c CROSS JOIN digits d;

INSERT INTO students(student_no,student_name,department)
SELECT CONCAT('B',LPAD(n+1,4,'0')),CONCAT('测试学生',n+1),'测试院系'
FROM bench_numbers WHERE n<200;

INSERT INTO events(event_id,club_id,title,starts_at,ends_at,opens_at,closes_at,capacity,state)
SELECT 100+n,1,CONCAT('测试活动',n),
 '2030-04-10 14:00:00','2030-04-10 16:00:00',
 '2030-03-01 10:00:00','2030-04-10 12:00:00',300,'published'
FROM bench_numbers WHERE n<50;

INSERT INTO registrations(student_no,event_id,state,requested_at,cancelled_at,cancel_reason)
SELECT CONCAT('B',LPAD(MOD(n,200)+1,4,'0')),100+FLOOR(n/200),'cancelled',
 DATE_ADD('2030-03-01 10:00:00',INTERVAL n SECOND),
 DATE_ADD('2030-03-01 10:05:00',INTERVAL n SECOND),'benchmark_cancel'
FROM bench_numbers;

INSERT INTO registrations(student_no,event_id,state,requested_at)
SELECT CONCAT('B',LPAD(MOD(n,200)+1,4,'0')),100+FLOOR(n/200),'confirmed',
 DATE_ADD('2030-03-20 10:00:00',INTERVAL n SECOND)
FROM bench_numbers WHERE n<2000;

-- 刷新统计后，先观察原有索引下的计划。
ANALYZE TABLE registrations;
EXPLAIN ANALYZE
SELECT attempt_id,event_id,state,requested_at FROM registrations
WHERE student_no='B0001' ORDER BY requested_at,attempt_id;
EXPLAIN ANALYZE
SELECT attempt_id,student_no,requested_at FROM registrations
WHERE event_id=100 AND state='confirmed'
ORDER BY requested_at,attempt_id;

-- 然后执行indexes.sql，再原样重复以上两条，保留各次实际结果。

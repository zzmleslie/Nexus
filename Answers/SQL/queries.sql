-- 在执行 seed.sql 的原始小数据上比较结果。
-- Q1 当前社群：S001 -> 开源社；结束经历另查出 attempt_id=1。
SELECT c.club_id,c.club_name,m.joined_at
FROM memberships m JOIN clubs c ON c.club_id=m.club_id
WHERE m.student_no='S001' AND m.state='active'
ORDER BY c.club_id;
SELECT attempt_id,club_id,joined_at,left_at
FROM memberships WHERE student_no='S001' AND state='left'
ORDER BY joined_at,attempt_id;

-- Q2 活动1当前名单：S001,S002；同名不影响身份。
SELECT r.student_no,s.student_name,r.requested_at
FROM registrations r JOIN students s ON s.student_no=r.student_no
WHERE r.event_id=1 AND r.state='confirmed'
ORDER BY r.requested_at,r.attempt_id;

-- Q3 活动1~4 当前人数分别2,0,0,1；剩余1,2,1,0。
SELECT e.event_id,e.title,e.capacity,COUNT(r.attempt_id) AS confirmed_count,
       e.capacity-COUNT(r.attempt_id) AS remaining
FROM events e LEFT JOIN registrations r
  ON r.event_id=e.event_id AND r.state='confirmed'
GROUP BY e.event_id,e.title,e.capacity
ORDER BY e.event_id;

-- Q4 当前人数至少2：只有活动1。
SELECT e.event_id,e.title,COUNT(r.attempt_id) AS confirmed_count
FROM events e JOIN registrations r
  ON r.event_id=e.event_id AND r.state='confirmed'
GROUP BY e.event_id,e.title
HAVING COUNT(r.attempt_id)>=2
ORDER BY e.event_id;

-- Q5 [2030-04-02,2030-04-04) 的活动是1、2，未报名者S003~S006。
SET @a='2030-04-02 00:00:00', @b='2030-04-04 00:00:00';
SELECT s.student_no,s.student_name
FROM students s
WHERE NOT EXISTS (
  SELECT 1 FROM registrations r JOIN events e ON e.event_id=r.event_id
  WHERE r.student_no=s.student_no AND r.state='confirmed'
    AND e.starts_at>=@a AND e.starts_at<@b
)
ORDER BY s.student_no;

-- 同义外连接版本：先限定要排除的匹配集合，再做 LEFT JOIN。
SELECT s.student_no,s.student_name
FROM students s LEFT JOIN (
  SELECT DISTINCT r.student_no
  FROM registrations r JOIN events e ON e.event_id=r.event_id
  WHERE r.state='confirmed' AND e.starts_at>=@a AND e.starts_at<@b
) matched ON matched.student_no=s.student_no
WHERE matched.student_no IS NULL
ORDER BY s.student_no;

-- Q6 S001/活动1：受理1、取消1、受理2。
SELECT attempt_id,action_at,action_name FROM (
  SELECT attempt_id,requested_at AS action_at,'accepted' AS action_name,1 AS action_order
  FROM registrations WHERE student_no='S001' AND event_id=1
  UNION ALL
  SELECT attempt_id,cancelled_at,'cancelled',2
  FROM registrations WHERE student_no='S001' AND event_id=1 AND cancelled_at IS NOT NULL
) timeline
ORDER BY action_at,attempt_id,action_order;

-- NULL 陷阱：预期返回0行，不是“除S001以外的人”。
SELECT student_no FROM students WHERE student_no NOT IN ('S001',NULL);

-- 选做：按社群给活动当前人数排名；DENSE_RANK保留并列。
WITH counts AS (
  SELECT e.event_id,e.club_id,e.title,COUNT(r.attempt_id) AS n
  FROM events e LEFT JOIN registrations r
    ON r.event_id=e.event_id AND r.state='confirmed'
  GROUP BY e.event_id,e.club_id,e.title
)
SELECT *,DENSE_RANK() OVER(PARTITION BY club_id ORDER BY n DESC) AS ranking
FROM counts ORDER BY club_id,ranking,event_id;

-- 选做：报名指定社群区间内全部活动；本答案采用空集时所有学生都符合。
SELECT s.student_no FROM students s
WHERE NOT EXISTS (
  SELECT 1 FROM events e
  WHERE e.club_id=1 AND e.starts_at>=@a AND e.starts_at<@b
    AND NOT EXISTS (
      SELECT 1 FROM registrations r WHERE r.event_id=e.event_id
        AND r.student_no=s.student_no AND r.state='confirmed'
    )
)
ORDER BY s.student_no;

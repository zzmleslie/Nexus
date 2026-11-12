-- 选择目标练习库后执行；不要赋给测试账号底层表的直接权限。
CREATE OR REPLACE SQL SECURITY DEFINER VIEW public_events AS
SELECT e.event_id,e.title,e.starts_at,e.ends_at,e.capacity,
       COUNT(r.attempt_id) AS confirmed_count,
       e.capacity-COUNT(r.attempt_id) AS remaining
FROM events e LEFT JOIN registrations r
  ON r.event_id=e.event_id AND r.state='confirmed'
WHERE e.state='published'
GROUP BY e.event_id,e.title,e.starts_at,e.ends_at,e.capacity;

-- 在benchmark.sql之后执行一次；保留原有约束和相关索引。
CREATE INDEX idx_registration_student_time
ON registrations(student_no,requested_at,attempt_id);
CREATE INDEX idx_registration_event_state_time
ON registrations(event_id,state,requested_at,attempt_id);
ANALYZE TABLE registrations;

-- 覆盖读取的小例子：输出只含所需索引中已有的信息。
EXPLAIN ANALYZE
SELECT attempt_id,requested_at FROM registrations
WHERE student_no='B0001' ORDER BY requested_at,attempt_id;

-- 只给非首列条件，实际是否采用索引以计划为准。
EXPLAIN SELECT attempt_id FROM registrations
WHERE requested_at>='2030-03-20 10:00:00';

SHOW INDEX FROM registrations;
SHOW TABLE STATUS LIKE 'registrations';

-- 示例：一次申请、批准、退出、重新申请。按顺序运行一次。
-- S006/社群1在seed中无经历。教学经办者已确认获社群1负责人授权。
-- 所有入社写路径约定先锁相同社群，再检查/修改；身份校验不是这里的SQL参数保证的。
START TRANSACTION;
SELECT club_id,organizer_no FROM clubs WHERE club_id=1 FOR UPDATE;
INSERT INTO memberships(student_no,club_id,state,applied_at)
VALUES('S006',1,'pending','2030-04-01 09:00:00');
SET @first_attempt=LAST_INSERT_ID();
UPDATE memberships SET state='active',handled_at='2030-04-01 09:30:00',
  joined_at='2030-04-01 09:30:00'
WHERE attempt_id=@first_attempt AND state='pending';
COMMIT;

START TRANSACTION;
SELECT club_id FROM clubs WHERE club_id=1 FOR UPDATE;
UPDATE memberships SET state='left',left_at='2030-04-02 09:00:00'
WHERE attempt_id=@first_attempt AND state='active';
COMMIT;

START TRANSACTION;
SELECT club_id FROM clubs WHERE club_id=1 FOR UPDATE;
INSERT INTO memberships(student_no,club_id,state,applied_at)
VALUES('S006',1,'pending','2030-04-03 09:00:00');
SET @second_attempt=LAST_INSERT_ID();
UPDATE memberships SET state='active',handled_at='2030-04-03 09:30:00',
  joined_at='2030-04-03 09:30:00'
WHERE attempt_id=@second_attempt AND state='pending';
COMMIT;
SELECT attempt_id,state,applied_at,joined_at,left_at
FROM memberships WHERE student_no='S006' AND club_id=1 ORDER BY attempt_id;

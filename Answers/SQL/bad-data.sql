-- 故意报错的练习：逐段运行。不是可以整批无错执行的初始化脚本。
-- 预期：重复主键错误。
INSERT INTO students VALUES ('S001','另一个人',NULL);
-- 预期：外键错误，学生不存在。
INSERT INTO registrations(student_no,event_id,state,requested_at)
VALUES ('NO-SUCH-STUDENT',1,'confirmed','2030-04-01 10:00:00');
-- 预期：NOT NULL 错误。
INSERT INTO students VALUES ('NULL-NAME',NULL,NULL);
-- 预期：CHECK 错误；语句失败后容量保持原值。
UPDATE events SET capacity=0 WHERE event_id=1;
-- 预期：CHECK 错误。
UPDATE events SET closes_at=opens_at WHERE event_id=1;
-- 预期：删除被历史引用的学生被外键拒绝。
DELETE FROM students WHERE student_no='S001';
-- 预期：条件唯一索引错误，同一学生活动已有当前正式报名。
INSERT INTO registrations(student_no,event_id,state,requested_at)
VALUES ('S001',1,'confirmed','2030-04-01 10:00:00');

-- 正常修改与回滚：事务 DML 可回滚；不要改成 DDL 后以为也可回滚。
START TRANSACTION;
UPDATE students SET department='软件工程' WHERE student_no='S001';
SELECT department FROM students WHERE student_no='S001';
ROLLBACK;
SELECT department FROM students WHERE student_no='S001';

-- 跨行容量：DDL 不会单独挡住下面的错误。仅测试副本、显式回滚。
START TRANSACTION;
INSERT INTO registrations(student_no,event_id,state,requested_at)
VALUES ('S004',4,'confirmed','2030-04-01 10:00:00');
SELECT COUNT(*) AS now_two_but_capacity_one
FROM registrations WHERE event_id=4 AND state='confirmed';
ROLLBACK;

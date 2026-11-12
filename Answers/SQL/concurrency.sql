-- 不是整批脚本！按标明的连接A/B与步骤逐段执行。
-- 前提：seed.sql后的活动3仍空，容量1；两个连接都选同一个练习库。

-- 第1步，A：锁住稳定活动记录，并写入合法的第一份报名，暂不提交。
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
START TRANSACTION;
SELECT event_id,capacity,state,opens_at,closes_at
FROM events WHERE event_id=3 FOR UPDATE;
SELECT COUNT(*) FROM registrations WHERE event_id=3 AND state='confirmed';
-- 已人工核对：人数0、published、教学时钟在窗口、S005存在且无当前报名。
INSERT INTO registrations(student_no,event_id,state,requested_at)
VALUES('S005',3,'confirmed','2030-04-01 10:00:00');

-- 第2步，切到B执行下一句。预期等待A，而非立即完成。
-- CALL book_event('S006',3,'2030-04-01 10:00:00');

-- 第3步，切回A提交，随后B应报告event_full。
COMMIT;

-- 第4步，在任一空闲连接核对：正式人数1，学生S005。
SELECT student_no,state FROM registrations WHERE event_id=3 AND state='confirmed';

-- 再测A回滚：在一个重新初始化的独立空练习库中重复第1/2步，
-- 把第3步改成ROLLBACK。预期B继续后成功，正式学生变为S006。
-- 不删除原实验历史来假装初始化；使用schema+seed重建另一个空库。

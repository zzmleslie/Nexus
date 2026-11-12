-- 由练习库拥有者创建。调用前必须没有外层事务，本过程自己管理边界。
-- p_now 是教学时钟；p_student 是教学参数，不构成身份鉴别。
-- 满员拒绝；所有学生可报名；所有并发报名/取消必须走同一活动锁约定。
DELIMITER $$
CREATE PROCEDURE book_event(
  IN p_student VARCHAR(16), IN p_event BIGINT, IN p_now DATETIME(6)
)
main: BEGIN
  DECLARE v_id BIGINT DEFAULT NULL;
  DECLARE v_capacity INT;
  DECLARE v_state VARCHAR(12);
  DECLARE v_open DATETIME(6);
  DECLARE v_close DATETIME(6);
  DECLARE v_count BIGINT DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
  START TRANSACTION;
  SELECT event_id,capacity,state,opens_at,closes_at
    INTO v_id,v_capacity,v_state,v_open,v_close
  FROM events WHERE event_id=p_event FOR UPDATE;
  IF v_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='event_not_found';
  END IF;
  IF p_now IS NULL OR v_state<>'published' OR p_now<v_open OR p_now>=v_close THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='not_in_registration_window';
  END IF;
  IF p_student IS NULL OR NOT EXISTS
    (SELECT 1 FROM students WHERE student_no=p_student) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='student_not_found';
  END IF;
  IF EXISTS (SELECT 1 FROM registrations WHERE student_no=p_student
             AND event_id=p_event AND state='confirmed') THEN
    COMMIT;
    SELECT 'already_registered' AS result;
    LEAVE main;
  END IF;
  -- RC 下，这是拿到活动锁后才建立的当前语句快照。
  -- 其他遵守约定的同活动写事务此时无法提交新的报名/取消。
  SELECT COUNT(*) INTO v_count FROM registrations
  WHERE event_id=p_event AND state='confirmed';
  IF v_count>=v_capacity THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='event_full';
  END IF;
  INSERT INTO registrations(student_no,event_id,state,requested_at)
  VALUES(p_student,p_event,'confirmed',p_now);
  COMMIT;
  SELECT 'registered' AS result;
END$$

CREATE PROCEDURE cancel_booking(
  IN p_student VARCHAR(16), IN p_event BIGINT, IN p_now DATETIME(6)
)
BEGIN
  DECLARE v_id BIGINT DEFAULT NULL;
  DECLARE v_state VARCHAR(12);
  DECLARE v_open DATETIME(6);
  DECLARE v_close DATETIME(6);
  DECLARE v_changed INT DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;
  SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
  START TRANSACTION;
  SELECT event_id,state,opens_at,closes_at
    INTO v_id,v_state,v_open,v_close
  FROM events WHERE event_id=p_event FOR UPDATE;
  IF v_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='event_not_found';
  END IF;
  IF p_now IS NULL OR v_state<>'published' OR p_now<v_open OR p_now>=v_close THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='not_in_cancellation_window';
  END IF;
  IF p_student IS NULL OR NOT EXISTS
    (SELECT 1 FROM students WHERE student_no=p_student) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='student_not_found';
  END IF;
  UPDATE registrations SET state='cancelled',cancelled_at=p_now,
      cancel_reason='student_cancelled'
  WHERE student_no=p_student AND event_id=p_event AND state='confirmed';
  SET v_changed=ROW_COUNT();
  COMMIT;
  SELECT v_changed AS cancelled_count;
END$$
DELIMITER ;

-- 完成建过程后，示例调用逐段执行；不要把这些注释当作已实测输出。
-- CALL book_event('S004',2,'2030-04-01 10:00:00'); -- registered
-- CALL book_event('S004',2,'2030-04-01 10:00:00'); -- already_registered
-- CALL cancel_booking('S004',2,'2030-04-01 10:01:00'); -- 1
-- CALL cancel_booking('S004',2,'2030-04-01 10:01:00'); -- 0
-- CALL book_event('S004',2,'2030-04-01 10:02:00'); -- new attempt
-- CALL book_event('S005',2,'2030-04-03 12:00:00'); -- 拒绝，close端点

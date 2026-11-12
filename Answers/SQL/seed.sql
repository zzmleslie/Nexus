-- 与 schema.sql 相同连接/目标库，在全新空表上执行一次。
INSERT INTO students VALUES
 ('S001','小林','计算机'),('S002','小周','自动化'),
 ('S003','小林','数学'),('S004','小陈','物理'),
 ('S005','小吴',NULL),('S006','小何','计算机');
INSERT INTO clubs(club_id,club_name,description,organizer_no) VALUES
 (1,'开源社','一起读代码','S001'),(2,'机器人社','一起做小车','S002');
INSERT INTO memberships
 (attempt_id,student_no,club_id,state,applied_at,handled_at,joined_at,left_at,decision_note)
VALUES
 (1,'S001',1,'left','2030-01-01 09:00:00','2030-01-02 09:00:00',
  '2030-01-02 09:00:00','2030-02-01 09:00:00','主动退出'),
 (2,'S001',1,'active','2030-03-01 09:00:00','2030-03-02 09:00:00',
  '2030-03-02 09:00:00',NULL,NULL),
 (3,'S002',2,'active','2030-03-01 09:00:00','2030-03-02 09:00:00',
  '2030-03-02 09:00:00',NULL,NULL),
 (4,'S003',1,'rejected','2030-03-01 10:00:00','2030-03-02 10:00:00',
  NULL,NULL,'材料尚不完整'),
 (5,'S004',1,'pending','2030-03-03 10:00:00',NULL,NULL,NULL,NULL);

INSERT INTO events
 (event_id,club_id,title,starts_at,ends_at,opens_at,closes_at,capacity,state)
VALUES
 (1,1,'读代码','2030-04-02 14:00:00','2030-04-02 16:00:00',
  '2030-03-01 10:00:00','2030-04-02 12:00:00',3,'published'),
 (2,2,'小车调试','2030-04-03 14:00:00','2030-04-03 16:00:00',
  '2030-03-01 10:00:00','2030-04-03 12:00:00',2,'published'),
 (3,1,'最后一个名额实验','2030-04-04 14:00:00','2030-04-04 16:00:00',
  '2030-03-01 10:00:00','2030-04-04 12:00:00',1,'published'),
 (4,2,'满员的小组','2030-04-05 14:00:00','2030-04-05 16:00:00',
  '2030-03-01 10:00:00','2030-04-05 12:00:00',1,'published');

INSERT INTO registrations
 (attempt_id,student_no,event_id,state,requested_at,cancelled_at,cancel_reason)
VALUES
 (1,'S001',1,'cancelled','2030-03-10 09:00:00','2030-03-11 09:00:00','时间有变'),
 (2,'S001',1,'confirmed','2030-03-12 09:00:00',NULL,NULL),
 (3,'S002',1,'confirmed','2030-03-12 10:00:00',NULL,NULL),
 (4,'S003',4,'confirmed','2030-03-13 10:00:00',NULL,NULL);

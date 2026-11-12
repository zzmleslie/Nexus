-- 管理账号执行。先在campus_nexus_lab中创建view.sql。
-- 若库名不同，改下面的限定库名。真实密码仅在本地设置，不提交。
CREATE ROLE IF NOT EXISTS 'cn_public_reader'@'%';
GRANT SELECT ON campus_nexus_lab.public_events TO 'cn_public_reader'@'%';
CREATE USER 'cn_reader'@'localhost'
IDENTIFIED BY '<仅在本地替换的测试密码，不要提交>';
GRANT 'cn_public_reader'@'%' TO 'cn_reader'@'localhost';
SET DEFAULT ROLE 'cn_public_reader'@'%' TO 'cn_reader'@'localhost';
SHOW GRANTS FOR 'cn_reader'@'localhost';
SHOW GRANTS FOR 'cn_public_reader'@'%';

-- 测试账号新连接中逐段执行（预期第一条查询成功，其余权限拒绝）：
-- SELECT CURRENT_USER(),CURRENT_ROLE();
-- SELECT * FROM campus_nexus_lab.public_events;
-- SELECT * FROM campus_nexus_lab.students;
-- UPDATE campus_nexus_lab.events SET capacity=999 WHERE event_id=1;
-- CREATE TABLE campus_nexus_lab.should_not_create(id INT);

-- 验证撤权时，管理员单独执行下面一条，再新建测试连接查视图：应拒绝。
-- REVOKE SELECT ON campus_nexus_lab.public_events FROM 'cn_public_reader'@'%';
-- 恢复权限可重新执行上面的GRANT SELECT，不必再次CREATE USER。

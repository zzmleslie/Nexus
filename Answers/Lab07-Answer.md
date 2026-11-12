---
title: Lab 7 参考答案：权限与恢复
project: Campus Nexus
lab: 7
status: reference
---

# Lab 7 参考答案

[权限题目](../Labs/Lab07-Security-Maintenance/Lab07.md) · [恢复题目](../Labs/Lab07-Security-Maintenance/Backup-Restore.md) · [答案目录](README.md)

## 1. 一个最小权限例子

先在练习库执行 view.sql，然后按 [permissions.sql](SQL/permissions.sql) 创建角色与测试用户。脚本使用 campus_nexus_lab 库名，自己的库名不同需修改。密码只有明显占位文字，必须在本地设置，不应提交真实密码。

GRANT角色之后，还要默认或显式激活；新连接查询 CURRENT_USER()、CURRENT_ROLE()，确认实际匹配账号与生效角色。某些环境连接localhost和127.0.0.1会匹配不同账号，先确认连接方式，不要用管理连接的成功冒充测试账号成功。

预期：只读用户查public_events成功；直接查students、UPDATE活动、CREATE TABLE都被拒绝。撤销角色上的视图SELECT后，在新连接中查询视图应被拒绝。若仍成功，查它是否经别的角色或直接授权获得权限。

视图用SQL SECURITY DEFINER访问底层对象，定义者需存在并有必要权限，读取者无需底层表的直接SELECT。视图不输出学生私人资料，但它没有实现“所有学生只看自己”：它展示相同的公开汇总。负责人社群范围和学生自身范围仍需可信身份与受控访问路径，不能靠传入一个student_no就信任身份。

## 2. 先保存恢复核对结果

在实际备份前记录各表行数，不预设你还停留在seed状态。另存三条查询：S001的成员经历；S001/活动1的时间线；每场活动当前人数。表结构用SHOW CREATE TABLE留关键约束证据。

除了行数，恢复后要重跑这些查询，并试一次应该被拒绝的坏数据。行数相同仍可能内容或约束不同。

## 3. 一个适合 Windows 的命令顺序

下列是给本地练习用的命令示例，先改路径与账号，确认目录存在。`mysql`与`mysqldump`需已在PATH或改为其完整路径。SOURCE在mysql客户端内执行也可以。

```powershell
mysqldump -u root -p --single-transaction --routines --triggers --events --no-tablespaces --set-gtid-purged=OFF --result-file=C:/lab-backup/campus.sql campus_nexus_lab
mysql -u root -p --execute="CREATE DATABASE campus_nexus_restore CHARACTER SET utf8mb4;"
mysql -u root -p campus_nexus_restore --execute="SOURCE C:/lab-backup/campus.sql"
```

`--result-file`让工具直接写文件，避免某些PowerShell版本的重定向编码问题。命令不带`--databases`，以免主动带出CREATE DATABASE/USE原库语句；恢复前仍检查文件，以及视图/例程是否包含固定的原库限定名。不要只因为命令退出就认定恢复目标一定正确。

这里关闭GTID写入是同一实例学习用的选择，不是生产复制备份通用参数。所需权限可能随服务器配置不同；缺权限先查具体错误，不要把所有警告当可忽略。[mysqldump文档](https://dev.mysql.com/doc/refman/8.0/en/mysqldump.html)

只使用InnoDB表时，single-transaction可得到数据一致性快照；期间避免并发DDL。触发器、例程、事件的包含选项需按实际使用核对。业务库逻辑导出不等于备份了数据库用户、角色和授权，权限脚本单独保存。

## 4. 验证视图没有偷偷连回旧库

恢复后执行SHOW CREATE VIEW public_events，查看它实际引用哪个库。若仍限定原库，在恢复库重新执行view.sql，确保基础表引用恢复库，再测试恢复库内的数据修改会不会反映在该视图中。不能让原库还在，掩盖恢复库的缺失数据。

同机恢复通常仍有原定义者账号；跨环境若DEFINER不存在，要用目标环境中有必要权限的定义者重新建立相关对象，不能无条件删除安全语义。过程中的未限定表名也应核对其所在目标库。导入报错应逐条查明。

## 5. “后悔药”怎么证明

先在恢复库核对三条证据，再把S001姓名改成“误改示例”并COMMIT，查询应看到变化。随后另建一个全新空库campus_nexus_restore2，导入同一备份并核对视图目标和证据，姓名应回到备份时的值。

这展示恢复到备份时点，而不是保住备份之后的全部合法更新。若要恢复到误操作前某时刻，需完整备份、二进制日志及可验证的恢复链；不能只把逻辑导出文件重导一次就称为时点恢复。

最后复用已有脚本，从空库建立整个参考版本：schema → seed → view → transactions。permissions只由管理连接按实际库名操作；已有用户和角色不重复创建，需对新目标库的视图重新GRANT并用测试连接验证。坏数据文件逐段测试，性能数据在另一个库。重做一次入社重入、报名取消重报、两连接抢名额、公开视图与越权拒绝，预留20～40分钟；首次排错另计。

这一版仍是教学数据库工程：没有前后端、没有完整审计或线上身份认证。能说明已保障的约束与尚未实现的边界，比一句“系统安全可靠”更准确。

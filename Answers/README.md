---
title: 参考答案入口
project: Campus Nexus
status: ready
---

# 参考答案入口

答案与讲义分开。先自己试一会儿，再对照卡住的那一段，不需要照着重做。

- [Lab 1：需求分析](Lab01-Answer.md)
- [Lab 2：E-R 设计](Lab02-Answer.md)
- [Lab 3：关系、范式与分解](Lab03-Answer.md)
- [Lab 4：建表与坏数据](Lab04-Answer.md)
- [Lab 5：查询与事务](Lab05-Answer.md)
- [Lab 6：索引与测量](Lab06-Answer.md)
- [Lab 7：权限与恢复](Lab07-Answer.md)

七份答案使用同一套小设计，SQL 都放在本目录的 `SQL/` 中。不要求你的表名、拆分方式与答案相同；比较的是业务含义与结果。

先从[独立业务材料](../00-业务背景与需求.md)理解业务，再看讲义任务。参考答案展示一种明确选择；业务材料中未决定的政策，不能因答案选了某方案就当成唯一规定。

本参考版本选择：满员拒绝、所有学生可报名、每社群一位当前负责人。入社申请可以待审、撤回、拒绝；通过后形成一段成员期间，退出后新申请。核心不做候补、场地或签到。不同政策仍然可以，但需要同步调整自己的规则与代码。

参考脚本使用 MySQL 8.0.18+ 的功能，使用显式练习时钟演示未来窗口，不能把它当作可信身份/时间校验的线上 API。执行顺序及预期结果见各 Lab 答案；请不要一口气执行所有 SQL 文件，坏数据与两会话实验需要逐段操作。

## SQL怎样接着运行

1. **Lab 4，新空库**：先选中自己的目标库，执行[schema.sql](SQL/schema.sql)再执行[seed.sql](SQL/seed.sql)。[bad-data.sql](SQL/bad-data.sql)逐项测试；[membership-demo.sql](SQL/membership-demo.sql)在同一连接按步骤演示。
2. **Lab 5，原始小数据**：运行[queries.sql](SQL/queries.sql)核对注释预期，再建[view.sql](SQL/view.sql)。若前面练习改过数据，要在新的空库重新初始化，或按自己的实际数据重算预期，不能沿用旧数字。
3. **Lab 5，事务副本**：建好[transactions.sql](SQL/transactions.sql)中的过程，再按[concurrency.sql](SQL/concurrency.sql)切换A/B连接逐步操作。每个新测试副本都要建立过程，不只导入表和数据；活动3初始应为空。
4. **Lab 6，独立性能库**：schema → seed → [benchmark.sql](SQL/benchmark.sql)，保存基线计划后再执行[indexes.sql](SQL/indexes.sql)。生成数据和新增索引只执行一次，原小数据不混进性能实验。
5. **Lab 7，管理连接与只读连接**：先建立目标库视图，再按[permissions.sql](SQL/permissions.sql)创建专用角色与用户并测试；固定库名需按目标修改，重复使用已有账号时只调整授权，不重复CREATE USER。备份恢复命令见[Lab 7答案](Lab07-Answer.md)。

这些脚本服务于各次练习，不是需要全部顺序执行的安装程序。选择自己的表设计时，参考的是操作与验证方法，不直接运行依赖参考表名的脚本。

当前交付环境没有可用的 MySQL 服务，SQL 未在真实 MySQL 中运行。提供的是参考实现与预期结果；已做的文档、静态检查和数学核对见[检查说明](../检查说明.md)，不把预期结果冒充实测输出。

[回到总导航](../README.md)

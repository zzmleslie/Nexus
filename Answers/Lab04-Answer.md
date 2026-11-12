---
title: Lab 4 参考答案：表与约束
project: Campus Nexus
lab: 4
status: reference
---

# Lab 4 参考答案

[题目](../Labs/Lab04-Implementation/Lab04.md) · [答案目录](README.md)

## 怎么执行

自己创建一个空练习库，字符集 utf8mb4，选择目标库后依次执行 [schema.sql](SQL/schema.sql)、[seed.sql](SQL/seed.sql)。脚本不包含删库或切库，便于在另一个空库重建。客户端要支持执行脚本；后续存储过程里的 DELIMITER 是客户端分隔符指令，不是送给服务器的一条 SQL。

先记 SELECT VERSION()、当前数据库和连接字符集。参考按 MySQL 8.0.18+ 编写，没有在交付环境实跑。以下是你运行时应核对的结果。

## 为什么这样选

学号使用 VARCHAR，保留前导零；姓名不唯一。内部尝试标识用 BIGINT 自增，便于分辨历次经历。DATETIME(6) 保存本实验约定的本地业务时间，连接与输入都按同一 Asia/Shanghai 含义，不声称它自动带时区。

必填项 NOT NULL，容量正整数和同一活动行内的时间关系用 CHECK，引用用外键。拒绝删除被历史引用的数据，避免级联清空报名；软删除、脱敏需另定政策，不在最小版中偷偷进行。

入社记录包含申请与一段可能存在的有效期间。pending 没有处理和加入时间；rejected/withdrawn 已处理但没加入；active 已加入未退出；left 保留加入和退出。状态组合由行内 CHECK 排除。它不记录每一次人工改动的完整审计轨迹；有这项需求时应加变更日志。

## 怎样只限制“当前”，又允许历史

报名的 active_slot 是生成列：confirmed 时为 1，其他状态为 NULL。唯一索引 (student_no,event_id,active_slot) 限制同一组合只有一个 1；历史记录的 NULL 则可出现多次。MySQL 唯一索引允许多个 NULL，这里利用的是明确的引擎语义，不是一般关系模型的候选码定义。[索引说明](https://dev.mysql.com/doc/refman/8.0/en/create-index.html)

入社的 open_slot 类似，但 pending 和 active 都为 1，因此同一学生同一社群既不能多份待审，也不能有效期间又提交另一份申请。退出后变为 NULL，后续新申请不受旧经历阻挡。

为什么不直接 UNIQUE(学生,活动)？它会把取消后的新尝试也拒绝。为什么不 UNIQUE(学生,活动,状态)？那样连第二次取消历史都可能被拒绝。

生成辅助列是受控派生值，不让用户自己填写；[生成列说明](https://dev.mysql.com/doc/refman/8.0/en/create-table-generated-columns.html)。这不是用 CHECK 检查跨行容量，也没有自动排除任意回填的历史成员期间重叠；后者要经过受控业务操作核对。

## 小数据应该是什么样

初始化后：6 个学生、2 个社群、5 次入社尝试、4 场活动、4 次报名尝试。S001 与 S003 同名，但身份不同。S001 的第一次入社已结束、第二次有效；对活动1先取消再重报，当前只计一次。活动1/2/3/4的当前正式人数依次为2/0/0/1。

[bad-data.sql](SQL/bad-data.sql) 要逐段运行，前七项分别由主键、外键、NOT NULL、容量 CHECK、时间 CHECK、删除引用限制和条件唯一性拒绝。错误编号/文本可能随客户端显示不同，重点是失败原因及原数据不变。

文件末尾故意让满员活动多插一人，再回滚：它展示表约束并没有自动限制人数。真正的容量保护在 Lab 5 的事务入口中完成。

CHECK 对 UNKNOWN 不按 FALSE 拒绝，因此脚本显式处理 NULL 并给必需列 NOT NULL；这也是为什么“写了一个比较式”不等于完整验证。[CHECK 说明](https://dev.mysql.com/doc/refman/8.0/en/create-table-check-constraints.html)

## 正常业务与重建

正常修改后 ROLLBACK，应看到原院系恢复。入社生命周期可另按 [membership-demo.sql](SQL/membership-demo.sql) 演示，在同一连接保持变量，预期出现 S006 的两次独立经历。真实系统还要鉴别操作者及限制直接写表，不能只凭“调用者说自己是负责人”。

讲义要求的正常取消可在原始seed上按下面步骤验证。教学时钟为2030年4月1日10:00，已知处在活动1的窗口内；此处核对合法DML与历史保留，不代替Lab 5完整的条件检查入口。

```sql
START TRANSACTION;
SELECT event_id FROM events WHERE event_id=1 FOR UPDATE;
UPDATE registrations
SET state='cancelled',cancelled_at='2030-04-01 10:00:00',
    cancel_reason='Lab4_cancel_test'
WHERE attempt_id=2 AND student_no='S001' AND state='confirmed';
SELECT attempt_id,state,requested_at,cancelled_at
FROM registrations WHERE student_no='S001' AND event_id=1;
ROLLBACK;
```

预期本次修改一条，原受理时间仍在，当前报名结束；ROLLBACK后原始seed恢复，便于继续其他测试。

换一个专用空库重跑 schema 与 seed，表数、关键约束、行数和查询结果应相同。DDL 与数据事务分开；不要指望回滚撤销创建或删除数据库。

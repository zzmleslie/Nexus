---
title: Lab 5 参考答案：查询与最后一个名额
project: Campus Nexus
lab: 5
status: reference
---

# Lab 5 参考答案

[查询题目](../Labs/Lab05-Queries-Transactions/Lab05.md) · [事务题目](../Labs/Lab05-Queries-Transactions/Transactions.md) · [答案目录](README.md)

## 六个查询怎样理解

完整写法在 [queries.sql](SQL/queries.sql)，按 Lab 4 原始 seed 核对：

1. 当前成员资格按 state=active；已退出经历另取 left。S001 当前属于开源社，历史中还有第一次退出，不能仅按 left_at IS NULL 判断，因为待审也没有退出时刻。
2. 活动1名单为 S001、S002，受理时刻后再按 attempt_id 排序。内部编号这里作为稳定并列项，不声称它在所有事务中代表精确提交先后。
3. 活动1～4人数为2、0、0、1，剩余1、2、1、0。LEFT JOIN 的状态条件放在 ON 中；若放 WHERE r.state='confirmed'，没有报名的活动会消失。COUNT(r.attempt_id) 不计补出的 NULL 行，COUNT(*) 则会计一行。
4. 至少2人只有活动1。WHERE 在分组前过滤记录，HAVING 在分组后筛选组。脚本按当前有效尝试计数，而条件唯一性保证其等于不同当前报名学生数。
5. 活动开始在 [4月2日,4月4日) 内的是1、2，未有效报名者为 S003～S006。NOT EXISTS 直接表达“没有匹配”，外连接版本先圈定要排除的学生集合，结果相同。NOT IN 遇到子查询中的 NULL 可能变 UNKNOWN，不适合不加分析直接替换。
6. S001/活动1输出“第一次受理、第一次取消、第二次受理”。UNION ALL 保留真实动作，不能随便去重；同一时刻用尝试编号和动作顺序消除展示歧义。

选做的 CTE 只是给中间集合命名，是否更快要测。DENSE_RANK 给相同人数相同名次，ROW_NUMBER 则要为稳定顺序补充并列键。双重 NOT EXISTS 表达“没有一场要求参加的活动是我没报的”；零场活动时条件对所有学生成立，若业务不接受，要另加 EXISTS 限定。

[view.sql](SQL/view.sql) 把当前公开活动统计变成视图，仍从基础数据计算，修改后重新查询应改变结果。聚合视图不作为通用可更新接口。

## 并发为什么会错

错误顺序：A看见0、B看见0、A插入并提交、B依旧按旧结果插入。两个人学号不同，当前唯一索引不会冲突；它限制重复报名，不限制活动总量。

事务原子性解决的是一组动作整体完成与否，不能凭 BEGIN/COMMIT 就推导互斥。必须有协调同活动写入的机制。

## 一个简单的可用策略

[transactions.sql](SQL/transactions.sql) 提供 book_event 与 cancel_booking：

1. 自己管理事务边界，调用前不能有外层事务；将本次事务设为 READ COMMITTED。
2. 用活动主键 FOR UPDATE 锁定同一稳定记录。
3. 检查存在、状态、窗口、学生存在与已有当前报名。
4. 拿到锁后读取当前人数，有空位才插入；取消也先锁同一活动。
5. 成功提交；异常处理器回滚并重新抛出，重复请求返回已有状态，不重复插入或重复减数。

为什么特意选 READ COMMITTED？这里的普通计数是拿到活动锁后建立的新语句快照；另一条遵守同一约定的同活动写事务此时不能越过活动锁提交。它不会读到旧 REPEATABLE READ 事务可能保留的早期快照。不要把本实现的理由生搬成“普通读永远最新”。[锁定读说明](https://dev.mysql.com/doc/refman/8.0/en/innodb-locking-reads.html)

这个证明依赖所有报名、取消、活动取消、容量修改都先锁同一活动。容量减少时还要拒绝低于当前人数；本参考版不提供容量修改入口。活动取消的最小管理员操作见下段。不要并发执行绕过约定的直接UPDATE，也不能宣称本方案已防住任意写表操作。

## 补充：活动取消怎样与已有报名协调

下面在独立测试副本中，以seed的活动1和固定教学时刻演示，操作者已确认有管理权限，活动尚未开始。先查询并核对状态、时间与原正式人数，再取消；不是一个接受任意参数的线上API，也不代替身份验证。

```sql
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
START TRANSACTION;
SELECT event_id,state,starts_at FROM events WHERE event_id=1 FOR UPDATE;
SELECT COUNT(*) AS before_count FROM registrations
WHERE event_id=1 AND state='confirmed';
UPDATE registrations
SET state='cancelled',cancelled_at='2030-04-01 10:05:00',
    cancel_reason='event_cancelled'
WHERE event_id=1 AND state='confirmed';
UPDATE events SET state='cancelled' WHERE event_id=1;
COMMIT;
SELECT attempt_id,state,requested_at,cancelled_at,cancel_reason
FROM registrations WHERE event_id=1 ORDER BY attempt_id;
```

在原始seed上，正式人数由2变为0，三次报名尝试仍在，原来已取消的一次不被改写；public_events不再显示活动1，book_event对该活动拒绝新报名。重复执行不会再次取消已经结束的报名。中途出错应回滚整个操作，不能只取消活动却漏掉名单。此实验会改变查询预期，因此不用它覆盖原始查询练习库。

## 两连接具体怎样试

[concurrency.sql](SQL/concurrency.sql) 不是批处理脚本：A持有活动3的锁并录入S005，B调用book_event(S006,3,教学时刻)等待，A提交后B重新读到满员并拒绝。最终一份当前报名。换全新测试库再做一轮，A改回滚，则B可成功。

取消S004/活动2一次返回1，再取消返回0；再次报名产生新尝试，旧取消仍在。close时刻报名拒绝。异常不会留下新报名；AUTO_INCREMENT 出现空号不表示数据损坏或事务没有回滚。

“半途主动ROLLBACK”使用concurrency.sql的A手工事务：写入后不提交，改为ROLLBACK，核对该写入消失且B随后可成功。不要在CALL外再包一层事务来验证：两个参考过程自行管理提交边界，不能依赖外层ROLLBACK撤销已经提交的CALL。

脚本的 p_student、p_now 是教学参数，不是线上可信身份和时钟。参考实现未替代用户认证、业务范围校验，也没有把存储过程默认 DEFINER 权限当作完整行级安全。

## 隔离级别与 ACID

用同一学生资料字段做两次普通 SELECT：A在RC事务中读，B提交修改后A下一次通常看见新值；RR下A第一次普通一致性读建立快照，B之后提交，A在同一快照上的再次普通读仍看见旧值。记录实际版本与步骤，不用锁定读冒充这项实验。

原子性：失败回滚不留半份业务结果；一致性：正确约束与操作共同保持不变量，不是数据库替你发明正确规则；隔离性：并发通过锁与隔离语义协调；持久性：已成功提交的数据进入数据库承诺的持久性机制，不能靠一张截图证明断电可恢复。

死锁选做的关键是统一锁顺序、处理被中止事务并有限重试；不要无限重试所有错误。请求编号应识别同一操作的重试，取消后主动再报名则是新操作。

场地选做的解法是锁同一场地稳定记录，再检查 `s1<e2 AND s2<e1` 的当前有效预约后批准；即使没有旧预约，也不能省略稳定协调点。相邻区间不重叠，包含和部分相交都重叠。设备还要另外追踪实际归还，不能拿日历结束代替实物状态。

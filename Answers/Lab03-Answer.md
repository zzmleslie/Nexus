---
title: Lab 3 参考答案：码、范式与分解
project: Campus Nexus
lab: 3
status: reference
---

# Lab 3 参考答案

[逻辑设计题目](../Labs/Lab03-Logical-Design/Lab03.md) · [分解题目](../Labs/Lab03-Logical-Design/Normalization-Practice.md) · [答案目录](README.md)

## 1. 从图转成关系

本版本的逻辑模式如下，名字与后续 SQL 一致：

```text
students(student_no, student_name, department)
clubs(club_id, club_name, description, organizer_no)
memberships(attempt_id, student_no, club_id, state,
            applied_at, handled_at, joined_at, left_at, decision_note)
events(event_id, club_id, title, starts_at, ends_at,
       opens_at, closes_at, capacity, state)
registrations(attempt_id, student_no, event_id, state,
              requested_at, cancelled_at, cancel_reason)
```

主键依次为 student_no、club_id、两个不同关系里的 attempt_id，以及 event_id。memberships 的 student_no/club_id 引用对应学生与社群；clubs.organizer_no 引用学生，可空；events.club_id 引用社群；registrations 的 student_no/event_id 引用学生与活动。

学生与社群的多次申请由 memberships 表达，学生与活动的多次报名由 registrations 表达。它们自己的时间、状态不能随便放到学生资料里，否则一个学生的多次经历会相互覆盖。

## 2. 函数依赖与候选码

五个关系各自的主标识决定本关系其余逻辑属性。业务没有规定社群名称、活动标题唯一，也没有规定同一学生对同一社群/活动只能尝试一次，因此这些组合不是跨全部历史的候选码。

以 registrations 为例，设 I=attempt_id，则 I⁺ 为本关系全部属性；空集不能决定 I，所以 I 最小。根据本版本给定的依赖，其他依赖不会产生 I，任何不含 I 的集合都推不出全部属性，因此只有候选码 {I}。其他四个关系在同样明确的“没有额外业务依赖”前提下类似。

不能仅说“我们加了 ID，所以只有这个候选码”。如果业务还规定一个全局不重复的编号，就应将它也列为候选码，并继续分析其他依赖。

对应任务四可核对两组经历：S001在1月2日加入、2月1日退出、3月2日再加入，对应两次不同attempt_id，当前仅第二次active；S001对活动1在3月10日报名、3月11日取消、3月12日重报，也对应两次attempt_id，当前仅第二次confirmed。不能用学生与社群或活动的组合限制全部历史只能一行。

仍需后续实现的约束包括容量上限、操作窗口、业务权限及任意历史回填的期间不重叠；它们不是仅凭主外键已经成立的结论。

在本答案采用的依赖集合下，各逻辑关系的非平凡函数依赖决定因素都是超码，满足 BCNF，也满足 3NF、2NF、1NF。NULL 是 SQL 实现的缺失表示；这里的经典 FD 判断针对业务中已定义的值及其依赖，不凭 NULL 巧合推断新 FD。

Lab 4 为条件唯一性增加的生成辅助列不在上述概念关系中。它会引入状态决定辅助值的派生依赖，不能不加区分地宣称“带所有物理辅助列的表仍严格 BCNF”；它是有明确目的、由数据库自动维护的实现选择。

## 3. 一个容易引入的冗余

若把 club_name 复制到每个 events 中，就出现 event_id→club_id→club_name，而 club_id 在活动关系中不是超码，club_name 也不是主属性。更新社群名可能改漏，没活动的社群也无法自然保存，删除最后一场活动可能丢掉社群资料。

拆成“活动信息”和“社群信息”，交集为 club_id；club_id 决定社群一边全部属性，因而二元分解无损。event_id→club_id 在活动中检查、club_id→club_name 在社群中检查，这个小例子的依赖可保持。这里说的是该依赖集合，不是任何拆表都天然正确。

## 4. 独立小题的完整推导

R(A,B,C)，F={AB→C,C→B}。

- AB⁺=ABC，A⁺=A，B⁺=B，所以 AB 是候选码。
- AC⁺=ABC，A⁺=A，C⁺=BC，所以 AC 也是候选码。
- A 不在任何依赖右侧，任何码都必须包含 A；只加 B 或 C 就已最小，所以没有其他候选码。

所有属性都是主属性。AB→C 的左边是超码；C→B 的左边不是超码，但右边 B 是主属性，因此原关系满足 3NF；C→B 违反 BCNF，所以最高为 3NF。

分解为 R1(C,B)、R2(A,C)：交集是 C，且 C→CB，故无损。

投影后非平凡依赖的一个生成集是 G={C→B}，AC 上没有非平凡 FD。计算 AB 在 G 下的闭包仍为 AB，不含 C，因此原来的 AB→C 不保持。C→B 仍保持。

可检查这个反例：R1={(c1,b1),(c2,b1)}，R2={(a1,c1),(a1,c2)}。两边各自符合投影 FD，连接得到 (a1,b1,c1)、(a1,b1,c2)，同一 AB 对应两个 C，违反 AB→C。

这与无损不冲突。无损保证“合法原关系投影后再连接能准确恢复”；它不保证“任意局部合法的子关系连接后都满足全部原 FD”。追求 BCNF 若丢掉本地可检查的依赖，可能需要跨关系检查，选择保持依赖的 3NF 设计有实际意义。

## 5. 4NF 选做

学生 s 有兴趣 h1、h2，语言 l1、l2，且两组完全独立，则有四个组合 (s,h1,l1)、(s,h1,l2)、(s,h2,l1)、(s,h2,l2)。存在非平凡多值依赖 S↠H 和 S↠L，S 又不是超码，因此违反 4NF。

拆成 (S,H) 与 (S,L) 在上述独立假设下无损。若语言与兴趣绑定，比如只允许 h1-l1、h2-l2，拆开再连接会制造原来不存在的组合。独立性必须来自业务，不是看见多值字段就直接拆。

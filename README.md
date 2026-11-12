---
title: Campus Nexus 数据库实践导航
project: Campus Nexus
version: "3.1"
updated: 2026-11-12
status: learning
---

# Campus Nexus：从这里开始

**第一步：阅读 [00-业务背景与需求](00-业务背景与需求.md)。** 先了解人员职责、入社和报名主流程及第16节的规则范围，再开始Lab 1；异常、日常例子和可选业务可随任务查阅，不必一次记住整份材料。该文只描述业务，不提前给出设计。

然后按下面顺序实践，共约12次基础练习，每次 **1～2小时**。时间以已具备相应前置知识为参考，环境配置、首次排错和选做另计；遇到难题可以拆开继续。每页明确目标、任务产出和完成检查。

## 打开哪一份

1. [Lab 1：需求分析](Labs/Lab01-Requirements/Lab01.md)——用户操作、数据字典、规则与需求检查，约一次。
2. [Lab 2：概念结构设计](Labs/Lab02-Conceptual-Design/Lab02.md)——实体、属性、联系及E-R图，约一次。
3. [Lab 3：逻辑设计与规范化](Labs/Lab03-Logical-Design/Lab03.md)——关系模式与范式，再做[分解练习](Labs/Lab03-Logical-Design/Normalization-Practice.md)，约两次。
4. [Lab 4：MySQL实现与完整性验证](Labs/Lab04-Implementation/Lab04.md)——建表、初始化、正常与异常操作，约两次。
5. [Lab 5：业务查询与事务](Labs/Lab05-Queries-Transactions/Lab05.md)——业务查询，再做[并发报名实验](Labs/Lab05-Queries-Transactions/Transactions.md)，约两次。
6. [Lab 6：索引设计与查询优化](Labs/Lab06-Physical-Design/Lab06.md)——计划、索引与测量比较，约两次。
7. [Lab 7：权限控制与备份恢复](Labs/Lab07-Security-Maintenance/Lab07.md)——账号权限，再做[恢复验证](Labs/Lab07-Security-Maintenance/Backup-Restore.md)，约两次。

## 答案在哪里

[打开答案目录](Answers/README.md)：每个 Lab 一份完整参考解说，使用同一套设计。建表、样例数据、查询、事务、性能和权限脚本都在 `Answers/SQL/`。**不是一口气执行全部文件**，先看相应答案的步骤。

先用自己的设计完成题目，再对照答案。答案是一种合理做法，表名和拆分方式不同不代表错。

## 文件怎么用

`Labs/` 放讲义，`Answers/` 放解说与示例；自己的图、SQL和短笔记放 `Work/Lab01/` 等目录，自行创建即可。Lab 1 有一个可选答题模板，其他 Lab 不再重复发空表。

整个文件夹可作为 Obsidian 库打开，也可在 Markdown 编辑器里读。相对链接不依赖原来的电脑路径，图用 Mermaid 表达；不支持图形预览也有文字解释。

使用 MySQL 8.0+、InnoDB、utf8mb4，参考脚本按 8.0.18+ 编写。只用专用练习库和虚构数据，不要求开发页面或后端。未决定的政策可以自己选择，改动记一句理由即可。

按教材找知识点看[课本知识索引](课本知识索引.md)。必做任务按完成检查核对，工具与满足业务的设计可以自行选择；选做最多挑一项，不做也能继续。

未定政策采用自己的明确方案即可；改变规则时记录“原来怎样、现在怎样、为什么”，同步修改需求、图、模式和测试。参考脚本的固定时钟只用于复现实验，不代表实际用户可以自行指定可信时间。

参考SQL目前**尚未完成MySQL实机验证**；[检查说明](检查说明.md)区分已完成的文档、数学和样例逻辑核对，以及待验证的DDL、事务、授权与恢复。输出说明是预期，不是实测日志。

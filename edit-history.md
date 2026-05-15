# 编辑记录

## 2026-05-15: 将编译流程从规则转换为 Skill

- **更改内容**: 创建 `.trae/skills/build/SKILL.md` skill，删除 `.trae/rules/finish-guide.md` 规则
- **更改原因**: 将编译流程从被动规则改为可主动调用的 skill，更灵活地控制何时触发编译
- **影响**: 编译不再作为 alwaysApply 规则自动触发，而是作为 skill 在需要时调用

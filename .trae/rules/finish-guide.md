---
description: Build project after changes
alwaysApply: true
---

当进行完阶段性修改后,需要对项目进行一次编译供用户测试
如果编译失败,请修复问题后再次编译
每次编译都需要先清理上次的PDB文件
编译命令:# 找到 MSBuild
# 编译 Release x64
& $msbuild "c:\CS2-DMA\dma.slnx" /p:Configuration=Release /p:Platform=x64 /t:Rebuild /m
或者直接用完整路径：
& "C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\MSBuild.exe" "c:\CS2-DMA\dma.slnx" /p:Configuration=Release /p:Platform=x64 /t:Rebuild /m

# BUAAPlaneFighter 北航一百号

北航师生自主研发"北航一百号"宇宙战机，对抗肆虐银河系的宇宙海盗团。

Made with **Godot 4.6 + Godot-MCP + Claude Code + Gemini**

---

## 玩法

| 操作 | 按键 |
|------|------|
| 移动 | 鼠标 |
| 射击 | 自动连射 |
| 暂停 | ESC / 鼠标移出窗口 |
| 确认 | X |
| 返回 | ESC |

- 消灭波次敌人 → WARNING DANGER → Boss 缓缓出场 → 击败通关
- 收集道具升级火力、获取护盾、激活浮游炮
- 5个关卡递增难度

---

## 项目结构

```
├── BUAA-Plane-Fighter.exe     # Windows 可执行文件
├── project.godot              # Godot 项目配置
├── assets/textures/           # 贴图资源
│   ├── enemies/               # 敌人贴图 (easy~fatal + 5 Boss)
│   └── player/                # 玩家战机贴图
├── scenes/                    # 场景文件
│   ├── game/                  # 主游戏场景
│   ├── player/                # 玩家
│   ├── enemies/               # 5种敌人 (Grunt/Fairy/Medium/Elite/Boss)
│   ├── bullets/               # 子弹模板
│   ├── items/                 # 4种道具
│   └── menus/                 # 主菜单 / 关卡选择
├── scripts/                   # GDScript 脚本
│   ├── game/main.gd           # 核心主控 (600+行)
│   ├── player/                # 玩家逻辑
│   ├── enemies/               # 敌人AI + Boss二阶段
│   ├── systems/               # 碰撞 / BGM / 弹幕模式库
│   ├── ui/                    # HUD / Boss血条 / 菜单
│   └── items/                 # 道具收集
```

---

## 打开方式

### 方式一：直接运行
双击 `BUAA-Plane-Fighter.exe` 即可运行。

### 方式二：Godot 编辑器
1. 下载 [Godot 4.6.3](https://godotengine.org/)
2. 打开 Godot → 导入 → 选择 `project.godot`
3. 按 F5 运行

---

## 技术栈

- **引擎**：Godot 4.6 + GDScript
- **AI 工具链**：Claude Code (DeepSeek-v4-pro) + Godot-MCP + Gemini
- **渲染**：D3D12 Forward+
- **音效**：AudioStreamGenerator 程序化 8-bit 合成
- **平台**：Windows 11

# PropOS Flutter App

物业运营管理平台移动端，覆盖 iOS / Android / HarmonyOS Next。

## 环境配置

环境变量通过 `--dart-define` 在编译时注入，无需 `.env` 文件。

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `API_BASE_URL` | 后端 API 地址 | `http://localhost:8080` |
| `USE_MOCK` | 启用 Mock 拦截器 | `false` |

### 运行命令

```bash
# 本地开发（使用默认值）
flutter run

# 指定后端地址
flutter run --dart-define=API_BASE_URL=https://api.propos.cn

# 启用 Mock 模式
flutter run --dart-define=USE_MOCK=true

# 生产构建
flutter build apk --dart-define=API_BASE_URL=https://api.propos.cn
```

### VS Code launch.json 配置示例

```json
{
  "configurations": [
    {
      "name": "dev",
      "request": "launch",
      "type": "dart",
      "args": ["--dart-define=API_BASE_URL=http://localhost:8080"]
    },
    {
      "name": "prod",
      "request": "launch",
      "type": "dart",
      "args": ["--dart-define=API_BASE_URL=https://api.propos.cn"]
    }
  ]
}
```

## 运行测试

```bash
flutter test
```

## 项目结构

```
lib/
  core/         # DI、API Client、路由、主题、常量
  features/     # 按业务模块划分（Clean Architecture）
  shared/       # 全局共享 Widget 和工具
```

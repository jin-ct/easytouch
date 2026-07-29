# 单元测试

本目录包含与平台无关模块的单元测试，基于 Qt Test 框架，可在
Windows / Linux / macOS 上独立于主程序构建运行（主程序仅支持 Windows）。

当前覆盖的模块：

- `ConfigFileManager`（`functions/configfilemanager.cpp`）——配置数据模型的
  `get` / `set` / `add` / `remove` / `clearList` 路径解析逻辑。
- `FileHelper`（`functions/filehelper.cpp`）——保存路径生成逻辑。

## 构建与运行

```bash
cmake -S tests -B tests/build -DCMAKE_BUILD_TYPE=Debug
cmake --build tests/build --parallel
cd tests/build && ctest --output-on-failure
```

在无显示环境（如 CI）中运行时设置 `QT_QPA_PLATFORM=offscreen`。

## 已知缺陷

`remove_objectField_knownBug` 通过 `QEXPECT_FAIL` 记录了一个已发现的缺陷：
`ConfigFileManager::remove()` 在删除对象字段时执行的是
`obj.remove(keys.last())`（`pop_back` 后指向父级键），应为 `obj.remove(l_name)`，
导致对象字段无法被删除。修复后请移除对应的 `QEXPECT_FAIL` 标记。

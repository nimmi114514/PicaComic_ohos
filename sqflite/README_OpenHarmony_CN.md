<p align="center">
  <h1 align="center"> <code>flutter_sqflite</code> </h1>
</p>

本项目基于 [sqflite@2.2.8+3](https://pub.dev/packages/sqflite/versions/2.2.8+3) 开发。

## 1. 安装与使用

### 1.1 安装方式

进入到工程目录并在 pubspec.yaml 中添加以下依赖：

<!-- tabs:start -->

#### pubspec.yaml

```yaml
dependencies:
  sqflite:
    git:
      url: "https://gitcode.com/openharmony-sig/flutter_sqflite.git"
      path: ./sqflite
```

执行命令

```bash
flutter pub get
```

<!-- tabs:end -->

### 1.2 使用案例

使用案例详见 [sqflite/example](./sqflite/example)

## 2. 约束与限制

### 2.1 兼容性

在以下版本中已测试通过

1. Flutter: 3.7.12-ohos-1.0.6; SDK: 5.0.0(12); IDE: DevEco Studio: 5.0.13.200; ROM: 5.1.0.120 SP3;

### 2.2 权限要求

以下权限中有`system_basic` 权限，而默认的应用权限是 `normal` ，只能使用 `normal` 等级的权限，所以可能会在安装hap包时报错**9568289**，请参考 [文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/bm-tool-V5#ZH-CN_TOPIC_0000001884757326__%E5%AE%89%E8%A3%85hap%E6%97%B6%E6%8F%90%E7%A4%BAcode9568289-error-install-failed-due-to-grant-request-permissions-failed) 修改应用等级为 `system_basic`

####  2.2.1在 entry 目录下的module.json5中添加权限

打开 `entry/src/main/module.json5`，添加：

```yaml
"requestPermissions": [
  {
   "name": "ohos.permission.INTERNET",
    "reason": "$string:network_reason",
    "usedScene": {
      "abilities": [
        "EntryAbility"
      ],
      "when":"inuse"
    }
  },
]
```

####  2.2.2在 entry 目录下添加申请以上权限的原因

打开 `entry/src/main/resources/base/element/string.json`，添加：

```yaml
{
  "string": [
    {
      "name": "network_reason",
      "value": "使用网络"
    },
  ]
}
```

## 3. 属性

> [!TIP] "ohos Support"列为 yes 表示 ohos 平台支持该属性；no 则表示不支持；partially 表示部分支持。使用方法跨平台一致，效果对标 iOS 或 Android 的效果。

#### **存储类型**

| Name   | Description  | Type   | **ohos Support** |
| ------ | ------------ | ------ | ---------------- |
| String | 存储字符串值 | String | yes              |
| int    | 存储整数值   | int    | yes              |
| double | 存储浮点数值 | double | yes              |
| bool   | 存储布尔值   | bool   | yes              |

#### OpenDatabaseOptions

| Name           | Description              | Type                       | **ohos Support** |
| -------------- | ------------------------ | -------------------------- | ---------------- |
| version        | 数据库版本               | int?                       | yes              |
| onConfigure    | 数据库配置回调           | OnDatabaseConfigureFn?     | yes              |
| onCreate       | 数据库首次创建回调       | OnDatabaseCreateFn?        | yes              |
| onUpgrade      | 数据库版本升级回调       | OnDatabaseVersionChangeFn? | yes              |
| onDowngrade    | 数据库版本降级回调       | OnDatabaseVersionChangeFn? | yes              |
| onOpen         | 数据库成功打开回调       | OnDatabaseOpenFn?          | yes              |
| readOnly       | 是否以只读模式打开数据库 | bool?                      | yes              |
| singleInstance | 是否强制单例模式         | bool?                      | yes              |

## 4. API

> [!TIP] "ohos Support"列为 yes 表示 ohos 平台支持该属性；no 则表示不支持；partially 表示部分支持。使用方法跨平台一致，效果对标 iOS 或 Android 的效果。

#### DatabaseFactory

| Name                                                      | **return value** | Description                          | Type     | **ohos Support** |
| --------------------------------------------------------- | ---------------- | ------------------------------------ | -------- | ---------------- |
| openDatabase(String path, {OpenDatabaseOptions? options}) | Future<Database> | 打开指定路径的数据库，可配置打开选项 | function | yes              |
| getDatabasesPath                                          | Future<String>   | 获取数据库默认存储路径               | function | yes              |
| setDatabasesPath(String path)                             | Future<void>     | 设置默认数据库存储路径               | function | yes              |
| deleteDatabase(String path)                               | Future<void>     | 删除指定路径的数据库                 | function | yes              |
| databaseExists(String path)                               | Future<bool>     | 检查指定路径的数据库是否存在         | function | yes              |

#### DatabaseExecutor

| Name                                                         | **return value**                   | Description                     | Type     | **ohos Support** |
| ------------------------------------------------------------ | ---------------------------------- | ------------------------------- | -------- | ---------------- |
| execute(String sql, [List<Object?>? arguments])              | Future<void>                       | 执行 SQL 语句                   | function | yes              |
| rawInsert(String sql, [List<Object?>? arguments])            | Future<int>                        | 直接执行插入 SQL 返回行数       | function | yes              |
| insert(String table, Map<String, Object?> values, {String?  nullColumnHack,ConflictAlgorithm? conflictAlgorithm}) | Future<int>                        | 插入 SQL 返回行数               | function | yes              |
| query(String table,<br/>      {bool? distinct,<br/>      List<String>? columns,<br/>      String? where,<br/>      List<Object?>? whereArgs,<br/>      String? groupBy,<br/>      String? having,<br/>      String? orderBy,<br/>      int? limit,<br/>      int? offset}); | Future<List<Map<String, Object?>>> | 查询返回结果集列表              | function | yes              |
| rawQuery(String sql,      [List<Object?>? arguments])        | Future<List<Map<String, Object?>>> | 直接执行 SQL 查询返回结果集列表 | function | yes              |
| rawQueryCursor(String sql, List<Object?>? arguments, {int? bufferSize}) | Future<QueryCursor>                | 执行原始 SQL 查询返回游标对象   | function | yes              |
| queryCursor(String table,<br/>      {bool? distinct,<br/>      List<String>? columns,<br/>      String? where,<br/>      List<Object?>? whereArgs,<br/>      String? groupBy,<br/>      String? having,<br/>      String? orderBy,<br/>      int? limit,<br/>      int? offset,<br/>      int? bufferSize}) | Future<QueryCursor>                | 查询返回游标对象                | function | yes              |
| rawUpdate(String sql, [List<Object?>? arguments])            | Future<int>                        | 直接执行更新 SQL 返回影响行数   | function | yes              |
| update(String table, Map<String, Object?> values,<br/>      {String? where,<br/>      List<Object?>? whereArgs,<br/>      ConflictAlgorithm? conflictAlgorithm}) | Future<int>                        | 执行更新 SQL 返回影响行数       | function | yes              |
| rawDelete(String sql, [List<Object?>? arguments])            | Future<int>                        | 直接执行SQL删除符合条件的数据行 | function | yes              |
| delete(String table, {String? where, List<Object?>? whereArgs}) | Future<int>                        | 删除符合条件的数据行            | function | yes              |
| batch                                                        | Batch                              | 获取批处理操作对象              | function | yes              |
| get database                                                 | Database                           | 获取底层数据库实例              | function | yes              |

#### **Batch**

| Name                                                         | **return value**      | Description            | Type     | **ohos Support** |
| ------------------------------------------------------------ | --------------------- | ---------------------- | -------- | ---------------- |
| commit({<br/>    bool? exclusive,<br/>    bool? noResult,<br/>    bool? continueOnError,<br/>  }) | Future<List<Object?>> | 提交批量操作           | function | yes              |
| apply({bool? noResult, bool? continueOnError})               | Future<List<Object?>> | 执行批量操作并自动提交 | function | yes              |
| rawInsert(String sql, [List<Object?>? arguments])            | void                  | 执行SQL插入语句        | function | yes              |
| insert(String table, Map<String, Object?> values,<br/>      {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) | void                  | 执行SQL插入语句        | function | yes              |
| rawUpdate(String sql, [List<Object?>? arguments])            | void                  | 执行SQL更新语句        | function | yes              |
| update(String table, Map<String, Object?> values,<br/>      {String? where,<br/>      List<Object?>? whereArgs,<br/>      ConflictAlgorithm? conflictAlgorithm}) | void                  | 执行SQL更新语句        | function | yes              |
| rawDelete(String sql, [List<Object?>? arguments])            | void                  | 执行SQL删除语句        | function | yes              |
| delete(String table, {String? where, List<Object?>? whereArgs}) | void                  | 执行SQL删除语句        | function | yes              |
| execute(String sql, [List<Object?>? arguments])              | void                  | 执行通用SQL语句        | function | yes              |
| query(String table,<br/>      {bool? distinct,<br/>      List<String>? columns,<br/>      String? where,<br/>      List<Object?>? whereArgs,<br/>      String? groupBy,<br/>      String? having,<br/>      String? orderBy,<br/>      int? limit,<br/>      int? offset}) | void                  | 执行 SQL 查询语句      | function | yes              |
| rawQuery(String sql, [List<Object?>? arguments])             | void                  | 执行 SQL 查询语句      | function | yes              |
| get length                                                   | int                   | 获取累计操作数量       | function | yes              |

## 5. 遗留问题

- [ ]  ohos 当前查询返回数据量特别大时，受 taskPool 限制，导致 序列化失败，无法正常返回数据。 : [issue#75](https://gitcode.com/openharmony-sig/flutter_sqflite/issues/75)。

## 6. 其他

## 7. 开源协议

本项目基于 [BSD 2-Clause License](https://gitcode.com/openharmony-sig/flutter_sqflite/blob/master/LICENSE)，请自由地享受和参与开源。

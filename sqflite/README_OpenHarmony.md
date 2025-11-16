<p align="center">
  <h1 align="center"> <code>flutter_sqflite</code> </h1>
</p>

This project is based on  [sqflite@2.2.8+3](https://pub.dev/packages/sqflite/versions/2.2.8+3).

## 1. Installation and Usage

### 1.1 Installation

Go to the project directory and add the following dependencies in pubspec.yaml：

<!-- tabs:start -->

#### pubspec.yaml

```yaml
dependencies:
  sqflite:
    git:
      url: "https://gitcode.com/openharmony-sig/flutter_sqflite.git"
      path: ./sqflite
```

Execute Command

```bash
flutter pub get
```

<!-- tabs:end -->

### 1.2 Usage

For use cases  [sqflite/example](./sqflite/example)

## 2. Constraints

### 2.1 Compatibility

This document is verified based on the following versions:

1. Flutter: 3.7.12-ohos-1.0.6; SDK: 5.0.0(12); IDE: DevEco Studio: 5.0.13.200; ROM: 5.1.0.120 SP3;

### 2.2 **Permission Requirements**

The following permissions include the `system_basic` permission, but the default application permission is `normal`. Only the `normal` permission can be used. Therefore, the error **9568289** may be reported during the installation of the HAP package. For details, see [Document](https://developer.huawei.com/consumer/en/doc/harmonyos-guides-V5/bm-tool-V5#EN_TOPIC_0000001884757326__%E5%AE%89%E8%A3%85hap%E6%97%B6%E6%8F%90%E7%A4%BAcode9568289-error-install-failed-due-to-grant-request-permissions-failed) Change the application level to `system_basic`.

####  2.2.1 **Add permissions to the module.json5 file in the entry directory**

Open  `entry/src/main/module.json5` and add the following information:

```yaml
"requestPermissions": [
      {
        "name": "ohos.permission.INTERNET",
        "reason": "$string:network_reason",
        "usedScene": {
          "abilities": [
            "EntryAbility"
          ],
          "when": "inuse"
        }
      },
    ]
```

#### 2.2.2 **Add the reason for applying for the preceding permission to the entry directory**

Open  `entry/src/main/resources/base/element/string.json` and add the following information:

```yaml
{
  "string": [
    {
      "name": "network_reason",
      "value": "use network"
    }
  ]
}
```

## 3. Properties

> [!TIP] If the value of **ohos Support** is **yes**, it means that the ohos platform supports this property; **no** means the opposite; **partially** means some capabilities of this property are supported. The usage method is the same on different platforms and the effect is the same as that of iOS or Android.

#### Storage type

| Name   | Description                 | Type   | **ohos Support** |
| ------ | --------------------------- | ------ | ---------------- |
| String | Store string values         | String | yes              |
| int    | Store integer values        | int    | yes              |
| double | Store floating-point values | double | yes              |
| bool   | Store boolean values        | bool   | yes              |

#### OpenDatabaseOptions

| Name           | Description                                           | Type                       | **ohos Support** |
| -------------- | ----------------------------------------------------- | -------------------------- | ---------------- |
| version        | Database version                                      | int?                       | yes              |
| onConfigure    | Database configuration callbacks                      | OnDatabaseConfigureFn?     | yes              |
| onCreate       | The database creates a callback for the first time.   | OnDatabaseCreateFn?        | yes              |
| onUpgrade      | Callback for database version upgrade                 | OnDatabaseVersionChangeFn? | yes              |
| onDowngrade    | Database version downgrade callback                   | OnDatabaseVersionChangeFn? | yes              |
| onOpen         | The callback was successfully opened in the database. | OnDatabaseOpenFn?          | yes              |
| readOnly       | Whether to open the database in read-only mode.       | bool?                      | yes              |
| singleInstance | Whether to enforce the singleton pattern.             | bool?                      | yes              |

## 4. API

> [!TIP] If the value of **ohos Support** is **yes**, it means that the ohos platform supports this property; **no** means the opposite; **partially** means some capabilities of this property are supported. The usage method is the same on different platforms and the effect is the same as that of iOS or Android.

#### **DatabaseFactory**

| Name                                                      | **return value** | Description                                                  | Type     | **ohos Support** |
| --------------------------------------------------------- | ---------------- | ------------------------------------------------------------ | -------- | ---------------- |
| openDatabase(String path, {OpenDatabaseOptions? options}) | Future<Database> | Open the database with the specified path, and you can configure the opening options. | function | yes              |
| getDatabasesPath                                          | Future<String>   | Obtain the default storage path of the database.             | function | yes              |
| setDatabasesPath(String path)                             | Future<void>     | Set the default database storage path.                       | function | yes              |
| deleteDatabase(String path)                               | Future<void>     | Deletes the database for the specified path.                 | function | yes              |
| databaseExists(String path)                               | Future<bool>     | Check whether the database for the specified path exists.    | function | yes              |

#### **DatabaseExecutor**

| Name                                                         | **return value**                   | Description                                                  | Type     | **ohos Support** |
| ------------------------------------------------------------ | ---------------------------------- | ------------------------------------------------------------ | -------- | ---------------- |
| execute(String sql, [List<Object?>? arguments])              | Future<void>                       | Execute SQL statements                                       | function | yes              |
| rawInsert(String sql, [List<Object?>? arguments])            | Future<int>                        | Directly execute the number of rows returned by inserting the SQL | function | yes              |
| insert(String table, Map<String, Object?> values, {String?  nullColumnHack,ConflictAlgorithm? conflictAlgorithm}) | Future<int>                        | The number of rows returned by the inserted SQL.             | function | yes              |
| query(String table,       {bool? distinct,       List<String>? columns,       String? where,       List<Object?>? whereArgs,       String? groupBy,       String? having,       String? orderBy,       int? limit,       int? offset}); | Future<List<Map<String, Object?>>> | The query returns a list of result sets.                     | function | yes              |
| rawQuery(String sql,      [List<Object?>? arguments])        | Future<List<Map<String, Object?>>> | Execute a SQL query directly to return a list of result sets | function | yes              |
| rawQueryCursor(String sql, List<Object?>? arguments, {int? bufferSize}) | Future<QueryCursor>                | Executing the original SQL query returns a cursor object.    | function | yes              |
| queryCursor(String table,       {bool? distinct,       List<String>? columns,       String? where,       List<Object?>? whereArgs,       String? groupBy,       String? having,       String? orderBy,       int? limit,       int? offset,       int? bufferSize}) | Future<QueryCursor>                | The query returns a cursor object.                           | function | yes              |
| rawUpdate(String sql, [List<Object?>? arguments])            | Future<int>                        | Performing an update directly with SQL returns the number of affected rows. | function | yes              |
| update(String table, Map<String, Object?> values,       {String? where,       List<Object?>? whereArgs,       ConflictAlgorithm? conflictAlgorithm}) | Future<int>                        | Performing an update SQL returns the number of affected rows. | function | yes              |
| rawDelete(String sql, [List<Object?>? arguments])            | Future<int>                        | Directly run SQL statements to delete data rows that meet the requirements. | function | yes              |
| delete(String table, {String? where, List<Object?>? whereArgs}) | Future<int>                        | Delete the data rows that match the criteria.                | function | yes              |
| batch                                                        | Batch                              | Get the batch op object                                      | function | yes              |
| get database                                                 | Database                           | Obtain the underlying DB instance                            | function | yes              |

#### **Batch**

| Name                                                         | **return value**      | Description                                    | Type     | **ohos Support** |
| ------------------------------------------------------------ | --------------------- | ---------------------------------------------- | -------- | ---------------- |
| commit({     bool? exclusive,     bool? noResult,     bool? continueOnError,   }) | Future<List<Object?>> | Submit a bulk action                           | function | yes              |
| apply({bool? noResult, bool? continueOnError})               | Future<List<Object?>> | Perform bulk actions and submit automatically. | function | yes              |
| rawInsert(String sql, [List<Object?>? arguments])            | void                  | Execute SQL insert statements                  | function | yes              |
| insert(String table, Map<String, Object?> values,       {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) | void                  | Execute SQL insert statements                  | function | yes              |
| rawUpdate(String sql, [List<Object?>? arguments])            | void                  | Run the SQL update statement.                  | function | yes              |
| update(String table, Map<String, Object?> values,       {String? where,       List<Object?>? whereArgs,       ConflictAlgorithm? conflictAlgorithm}) | void                  | Run the SQL update statement.                  | function | yes              |
| rawDelete(String sql, [List<Object?>? arguments])            | void                  | Run the SQL deletion statement                 | function | yes              |
| delete(String table, {String? where, List<Object?>? whereArgs}) | void                  | Run the SQL deletion statement                 | function | yes              |
| execute(String sql, [List<Object?>? arguments])              | void                  | Execute common SQL statements                  | function | yes              |
| query(String table,       {bool? distinct,       List<String>? columns,       String? where,       List<Object?>? whereArgs,       String? groupBy,       String? having,       String? orderBy,       int? limit,       int? offset}) | void                  | Execute a SQL query statement                  | function | yes              |
| rawQuery(String sql, [List<Object?>? arguments])             | void                  | Execute a SQL query statement                  | function | yes              |
| get length                                                   | int                   | Obtain the cumulative number of operations.    | function | yes              |



## 5. Known Issues

- [ ]  ohos  When query results contain excessively large datasets, serialization failures occur due to taskPool limitations, preventing normal data return. : [issue#75](https://gitcode.com/openharmony-sig/flutter_sqflite/issues/75).

## 6. Others

## 7.**License**

This project is licensed under [BSD 2-Clause License](https://gitcode.com/openharmony-sig/flutter_sqflite/blob/master/LICENSE)

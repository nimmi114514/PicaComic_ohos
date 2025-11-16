/*
 * Copyright (c) 2024 Hunan OpenValley Digital Industry Development Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'test_page.dart';

/// New features test page.
class NewFeaturesTestPage extends TestPage {
  /// New features test page.
  NewFeaturesTestPage({Key? key}) : super('New features tests', key: key) {
    test('Attach', () async {
      await initDeleteDb('main.db');
      await initDeleteDb('secondary.db');

      // 初始化两个数据库
      final db = await initDatabase('main.db');
      final secondaryDb = await initDatabase('secondary.db');

      // 插入示例数据
      await db.insert('users', {'name': 'Alice'});
      await secondaryDb.insert('orders', {'product': 'Laptop', 'user_id': 1});

      // 附加第二个数据库
      await attachDatabase(db, secondaryDb, 'secondary');

      // 执行跨数据库查询
      final results = await db.rawQuery('''
    SELECT users.name, orders.product 
    FROM users
    INNER JOIN secondary.orders ON users.id = orders.user_id
  ''');

      // 分离数据库
      await db.execute('DETACH DATABASE secondary');

      // 关闭数据库
      await db.close();
      await secondaryDb.close();
      expect(results[0]['product'], 'Laptop');
    });

    test('Tokenizer', () async {
      const dbName = 'tokenizer';
      const sqlCreateTable =
          'CREATE VIRTUAL TABLE example USING fts4(name, content, tokenize=icu zh_CN)';
      await initDeleteDb(dbName);

      final databasePath = await getDatabasesPath();
      final path = join(databasePath, dbName);
      final database = await openDatabase(
        path,
        version: 1,
        onCreate: (Database db, int version) async {
          // 创建FTS虚拟表
          await db.execute(sqlCreateTable);
        },
      );

      // 插入数据
      await database.insert('example', {
        'name': 'jack',
        'content': 'This is a sample text for full-text search in Flutter 中国'
      });

      // 搜索
      final results = await database.query('example',
          where: 'content MATCH ?', whereArgs: ['sample text']);
      expect(results[0]['name'], 'jack');
    });

    test('Bigint sort', () async {
      final path = await initDeleteDb('bigint.db');
      final db = await openDatabase(path);
      final String _tableName = "users";
      db.execute(
          "CREATE TABLE users(id INTEGER PRIMARY KEY, name TEXT, age INTEGER, create_t UNLIMITED INT)");
      List<Map<String, dynamic>> users = [];
      for (int i = 0; i < 5; i++) {
        users.add(getUser());
      }
      await db.transaction((txn) async {
        Batch batch = txn.batch();
        for (var user in users) {
          batch.insert('users', user);
        }
        await batch.commit();
      });

      final maps = await db.query(_tableName, orderBy: 'create_t ASC');
      List<int> createTimes =
          maps.map((user) => user['create_t'] as int).toList();
      expect(isASC(createTimes), true);
    });

    test('Time-consuming task', () async {
      final path = await initDeleteDb('time_consuming_task.db');
      final db = await openDatabase(path);

      // 创建表
      await db.execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY,
          name TEXT,
          age INTEGER,
          city TEXT,
          registration_date INTEGER
        )
      ''');

      await db.execute('''
        CREATE TABLE orders (
          id INTEGER PRIMARY KEY,
          user_id INTEGER,
          product_name TEXT,
          price REAL,
          quantity INTEGER,
          order_date INTEGER,
          FOREIGN KEY (user_id) REFERENCES users (id)
        )
      ''');

      await db.execute('''
        CREATE TABLE logs ( 
          id INTEGER PRIMARY KEY,
          user_id INTEGER,
          action TEXT,
          timestamp INTEGER,
          details TEXT,
          FOREIGN KEY (user_id) REFERENCES users (id)
        )
      ''');

      // 插入10万名用户
      final batch = db.batch();
      for (int i = 1; i <= 100000; i++) {
        batch.insert('users', {
          'name': '用户 $i',
          'age': 18 + (i % 60),
          'city': ['北京', '上海', '广州', '深圳', '杭州'][i % 5],
          'registration_date': DateTime.now()
              .subtract(Duration(days: i % 365))
              .millisecondsSinceEpoch,
        });
      }
      await batch.commit(noResult: true);

      // 插入10万条订单
      final orderBatch = db.batch();
      for (int i = 1; i <= 100000; i++) {
        orderBatch.insert('orders', {
          'user_id': (i % 100000) + 1,
          'product_name': ['手机', '电脑', '平板', '耳机', '手表'][i % 5],
          'price': 100 + (i % 9000),
          'quantity': 1 + (i % 5),
          'order_date': DateTime.now()
              .subtract(Duration(days: i % 365))
              .millisecondsSinceEpoch,
        });
      }
      await orderBatch.commit(noResult: true);

      // 插入10万条日志记录
      final logBatch = db.batch();
      for (int i = 1; i <= 100000; i++) {
        logBatch.insert('logs', {
          'user_id': (i % 100000) + 1,
          'action': ['登录', '浏览', '购买', '评论', '分享'][i % 5],
          'timestamp': DateTime.now()
              .subtract(Duration(days: i % 365))
              .millisecondsSinceEpoch,
          'details': '这是用户 ${(i % 100000) + 1} 的详细日志记录 #$i',
        });
      }
      await logBatch.commit(noResult: true);

      final stopwatch = Stopwatch()..start();

      try {
        // 执行复杂查询
        await db.rawQuery('''
        SELECT 
          u.id,
          u.name,
          u.city,
          COUNT(DISTINCT o.id) as order_count,
          SUM(o.price * o.quantity) as total_spent,
          AVG(o.price) as avg_order_value,
          COUNT(l.id) as log_count,
          (SELECT COUNT(*) FROM orders o2 
           WHERE o2.user_id = u.id AND o2.price > 5000) as premium_orders,
          (SELECT product_name FROM orders o3 
           WHERE o3.user_id = u.id 
           GROUP BY product_name 
           ORDER BY COUNT(*) DESC 
           LIMIT 1) as favorite_product,
          (SELECT action FROM logs l2 
           WHERE l2.user_id = u.id 
           GROUP BY action 
           ORDER BY COUNT(*) DESC 
           LIMIT 1) as most_common_action
        FROM users u
        LEFT JOIN orders o ON u.id = o.user_id
        LEFT JOIN logs l ON u.id = l.user_id
        WHERE u.age BETWEEN 25 AND 45
          AND u.registration_date > ?
          AND u.city IN ('北京', '上海', '广州')
          AND EXISTS (
            SELECT 1 FROM logs l3 
            WHERE l3.user_id = u.id 
            AND l3.action = '购买'
            AND l3.timestamp > ?
          )
        GROUP BY u.id
        HAVING total_spent > 800
        ORDER BY total_spent DESC
        LIMIT 500
      ''', [
          DateTime.now().subtract(Duration(days: 365)).millisecondsSinceEpoch,
          DateTime.now().subtract(Duration(days: 30)).millisecondsSinceEpoch,
        ]);

        stopwatch.stop();
        expect(true, true);
        debugPrint(
            "Time-consuming task：查询完成！耗时: ${stopwatch.elapsedMilliseconds / 1000} 秒。");
      } catch (e) {
        stopwatch.stop();
        expect(false, true);
        debugPrint(
            "Time-consuming task：查询出错: $e\n耗时: ${stopwatch.elapsedMilliseconds / 1000} 秒。");
      }
    });
  }

  Map<String, dynamic> getUser() {
    int now = 9223372036854775807;
    return {
      'name': 'Jack',
      'age': Random().nextInt(30000),
      'create_t': now - Random().nextInt(30000),
    };
  }

  bool isASC(List<int> users) {
    for (int i = 0; i < users.length - 1; i++) {
      if (users[i] > users[i + 1]) {
        return false;
      }
    }
    return true;
  }

  // 初始化数据库并创建表
  Future<Database> initDatabase(String name) async {
    final path = join(await getDatabasesPath(), name);
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        if (name == 'main.db') {
          await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY,
            name TEXT
          )
        ''');
        } else {
          await db.execute('''
          CREATE TABLE orders (
            id INTEGER PRIMARY KEY,
            product TEXT,
            user_id INTEGER
          )
        ''');
        }
      },
    );
  }

  // 附加数据库的核心方法
  Future<void> attachDatabase(
      Database mainDb, Database secondaryDb, String alias) async {
    // 关闭目标数据库以释放文件锁
    await secondaryDb.close();
    // 获取附加数据库的绝对路径
    final path = join(await getDatabasesPath(), 'secondary.db');

    try {
      // 执行 ATTACH 命令
      await mainDb.execute('ATTACH DATABASE ? AS $alias', [path]);
      print("attach success}");
    } catch (error) {
      print("attach failed, ${error.toString()}");
    }
  }
}

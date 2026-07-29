#include <QtTest>
#include <QSignalSpy>
#include <QVariantMap>
#include <QVariantList>

#include "functions/configfilemanager.h"

// ConfigFileManager 是全应用的核心配置数据模型（settings.json、memory.json 等
// 均由它承载），其路径解析（"a.b.c" 与 "a.b.c[i]"）逻辑与平台无关。
// 这些测试全部使用 isSync=false，只验证内存中的读写逻辑，不触碰文件系统。
class TestConfigFileManager : public QObject
{
    Q_OBJECT

private slots:
    // ---- get / set: 普通嵌套字段 ----
    void set_createsNestedObjects();
    void set_overwritesExistingValue();
    void get_missingPathReturnsInvalid();

    // ---- get / set: 数组 ----
    void set_createsArrayWithPadding();
    void set_nestedArrayElement();

    // ---- add ----
    void add_appendsToExistingList();
    void add_setsValueWhenNotAList();
    void add_rejectsEmptyPathAndInvalidValue();

    // ---- clearList ----
    void clearList_emptiesList();
    void clearList_rejectsNonList();

    // ---- remove ----
    void remove_arrayElement();
    void remove_objectField_knownBug();

    // ---- 信号 ----
    void set_emitsConfigChanged();
};

void TestConfigFileManager::set_createsNestedObjects()
{
    ConfigFileManager cfg;
    QVERIFY(cfg.set("a.b.c", 42, false));

    QCOMPARE(cfg.get("a.b.c").toInt(), 42);

    // 中间层应为 map
    QVERIFY(cfg.get("a").canConvert<QVariantMap>());
    QVERIFY(cfg.get("a.b").toMap().contains("c"));
}

void TestConfigFileManager::set_overwritesExistingValue()
{
    ConfigFileManager cfg;
    cfg.set("k", "first", false);
    QCOMPARE(cfg.get("k").toString(), QStringLiteral("first"));

    cfg.set("k", "second", false);
    QCOMPARE(cfg.get("k").toString(), QStringLiteral("second"));
}

void TestConfigFileManager::get_missingPathReturnsInvalid()
{
    ConfigFileManager cfg;
    QVERIFY(!cfg.get("does.not.exist").isValid());

    // 空路径的 set 应被拒绝
    QVERIFY(!cfg.set("", 1, false));
}

void TestConfigFileManager::set_createsArrayWithPadding()
{
    ConfigFileManager cfg;
    // 写入 index 2，index 0/1 应被空值补齐
    QVERIFY(cfg.set("list[2]", QStringLiteral("x"), false));

    QVariant list = cfg.get("list");
    QCOMPARE(list.toList().size(), 3);
    QCOMPARE(cfg.get("list[2]").toString(), QStringLiteral("x"));
    QVERIFY(!cfg.get("list[0]").isValid());
    QVERIFY(!cfg.get("list[1]").isValid());
}

void TestConfigFileManager::set_nestedArrayElement()
{
    ConfigFileManager cfg;
    QVERIFY(cfg.set("a.items[1].name", QStringLiteral("bob"), false));

    QCOMPARE(cfg.get("a.items[1].name").toString(), QStringLiteral("bob"));
    QCOMPARE(cfg.get("a.items").toList().size(), 2);
}

void TestConfigFileManager::add_appendsToExistingList()
{
    ConfigFileManager cfg;
    cfg.set("arr", QVariantList{1, 2}, false);

    QVERIFY(cfg.add("arr", 3, false));

    QVariantList expected{1, 2, 3};
    QCOMPARE(cfg.get("arr").toList(), expected);
}

void TestConfigFileManager::add_setsValueWhenNotAList()
{
    ConfigFileManager cfg;
    // 目标不是数组时，add 相当于 set
    QVERIFY(cfg.add("scalar", 7, false));
    QCOMPARE(cfg.get("scalar").toInt(), 7);

    QVERIFY(cfg.add("scalar", 9, false));
    QCOMPARE(cfg.get("scalar").toInt(), 9);
}

void TestConfigFileManager::add_rejectsEmptyPathAndInvalidValue()
{
    ConfigFileManager cfg;
    QVERIFY(!cfg.add("", 1, false));
    QVERIFY(!cfg.add("path", QVariant(), false));
}

void TestConfigFileManager::clearList_emptiesList()
{
    ConfigFileManager cfg;
    cfg.set("arr", QVariantList{1, 2, 3}, false);

    QVERIFY(cfg.clearList("arr", false));
    QCOMPARE(cfg.get("arr").toList().size(), 0);
}

void TestConfigFileManager::clearList_rejectsNonList()
{
    ConfigFileManager cfg;
    cfg.set("scalar", 5, false);

    QVERIFY(!cfg.clearList("scalar", false));
    QVERIFY(!cfg.clearList("missing", false));
    QCOMPARE(cfg.get("scalar").toInt(), 5);
}

void TestConfigFileManager::remove_arrayElement()
{
    ConfigFileManager cfg;
    cfg.set("list", QVariantList{10, 20, 30}, false);

    QVERIFY(cfg.remove("list[1]", false));

    QVariantList expected{10, 30};
    QCOMPARE(cfg.get("list").toList(), expected);
}

// 已知缺陷：对象字段的 remove 未生效。
// remove() 在对象分支执行 `obj.remove(keys.last())`，pop_back 之后 keys.last()
// 是父级键而非待删除字段（应为 l_name），因此字段不会被删除。
// 该测试通过 QEXPECT_FAIL 记录此缺陷，待修复后应去掉标记。
void TestConfigFileManager::remove_objectField_knownBug()
{
    ConfigFileManager cfg;
    cfg.set("a.b", 1, false);
    cfg.set("a.c", 2, false);

    cfg.remove("a.b", false);

    QEXPECT_FAIL("", "remove() 无法删除对象字段（应使用 l_name 而非 keys.last()）",
                 Continue);
    QVERIFY(!cfg.get("a.b").isValid());

    // 兄弟字段应始终保留
    QCOMPARE(cfg.get("a.c").toInt(), 2);
}

void TestConfigFileManager::set_emitsConfigChanged()
{
    ConfigFileManager cfg;
    QSignalSpy spy(&cfg, &ConfigFileManager::configChanged);

    cfg.set("x.y", 5, false);

    QCOMPARE(spy.count(), 1);
    const QList<QVariant> args = spy.takeFirst();
    QCOMPARE(args.at(0).toString(), QStringLiteral("x.y"));
    QCOMPARE(args.at(1).toInt(), 5);
}

QTEST_GUILESS_MAIN(TestConfigFileManager)
#include "tst_configfilemanager.moc"

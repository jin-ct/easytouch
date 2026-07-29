#include <QtTest>
#include <QTemporaryDir>
#include <QDir>
#include <QDate>
#include <QFile>

#include "functions/filehelper.h"

// FileHelper 提供批注/截图等保存路径的生成逻辑，其静态方法与平台无关。
// openFolderDialog 需要 GUI 交互，这里不做测试。
class TestFileHelper : public QObject
{
    Q_OBJECT

private slots:
    void desktopFolder_returnsNonEmpty();
    void nowDateTimeName_createsDatedSubdirAndExtension();
    void nowDateTimeName_uniquifiesWhenNotDebounced();
};

void TestFileHelper::desktopFolder_returnsNonEmpty()
{
    QVERIFY(!FileHelper::desktopFolder().toString().isEmpty());
}

void TestFileHelper::nowDateTimeName_createsDatedSubdirAndExtension()
{
    QTemporaryDir tmp;
    QVERIFY(tmp.isValid());

    const QString result =
        FileHelper::getNowDateTimeNameFilePath(tmp.path(), "png", false).toString();

    const QString dateFolder = QDate::currentDate().toString("yyyy-MM-dd");
    const QString expectedDir = tmp.path() + "/" + dateFolder;

    // 日期子目录应被创建
    QVERIFY(QDir(expectedDir).exists());
    // 返回路径应位于该目录下，并带正确扩展名
    QVERIFY(result.startsWith(expectedDir + "/"));
    QVERIFY(result.endsWith(".png"));
}

void TestFileHelper::nowDateTimeName_uniquifiesWhenNotDebounced()
{
    QTemporaryDir tmp;
    QVERIFY(tmp.isValid());

    const QString first =
        FileHelper::getNowDateTimeNameFilePath(tmp.path(), "txt", false).toString();

    // 占用第一次返回的文件名，迫使下一次生成不同的路径
    QFile f(first);
    QVERIFY(f.open(QIODevice::WriteOnly));
    f.close();

    const QString second =
        FileHelper::getNowDateTimeNameFilePath(tmp.path(), "txt", false).toString();

    QVERIFY(!second.isEmpty());
    QVERIFY(second != first);
    QVERIFY(!QFile::exists(second));
}

QTEST_GUILESS_MAIN(TestFileHelper)
#include "tst_filehelper.moc"

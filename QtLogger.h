#ifndef QTLOGGER_H
#define QTLOGGER_H

#include <QApplication>
#include <QDateTime>
#include <QDate>
#include <QFile>
#include <QDir>
#include <QMutex>
#include <QMutexLocker>
#include <QTextStream>
#include <QQueue>
#include <QWaitCondition>
#include <QThread>
#include <QObject>
#include <QDebug>
#include <cstdio>

// Qt 6 兼容性处理
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
#include <QStringConverter>
#else
#include <QTextCodec>
#endif

/**
 * @brief 日志级别定义
 */
enum class LogLevel {
    DEBUG = 0,     // 调试级别
    INFO = 1,      // 信息级别
    WARNING = 2,   // 警告级别
    CRITICAL = 3,  // 严重错误级别
    FATAL = 4      // 致命错误级别
};

/**
 * @brief 日志配置结构
 */
struct LogConfig {
    QString logDir = "logs";                   // 日志目录
    QString logFilePrefix = "et";              // 日志文件前缀
    qint64 maxFileSize = 1 * 1024 * 1024;     // 单个日志文件最大1MB
    int maxFileCount = 10;                     // 保留最大文件数
    LogLevel minLevel = LogLevel::DEBUG;       // 最小日志级别
    bool consoleOutput = true;                 // 控制台输出
    bool coloredOutput = true;                 // 彩色输出
};

/**
 * @brief 日志消息结构
 */
struct LogMessage {
    LogLevel level;          // 日志级别
    QString message;         // 日志消息内容
    QString file;            // 源代码文件名
    int line;                // 源代码行号
    QString function;        // 函数名
    QDateTime timestamp;     // 时间戳
};

/**
 * @class LogWriter
 * @brief 日志异步写入线程类
 * @details 负责在独立线程中异步写入日志到文件
 */
class LogWriter : public QThread {
    Q_OBJECT

public:
    /**
     * @brief 构造函数
     * @param config 日志配置
     * @param parent 父对象
     */
    explicit LogWriter(const LogConfig& config, QObject* parent = nullptr);
    
    /**
     * @brief 析构函数
     */
    ~LogWriter();
    
    /**
     * @brief 将日志消息加入写入队列
     * @param msg 日志消息
     */
    void enqueue(const LogMessage& msg);
    
    /**
     * @brief 停止写入线程
     */
    void stop();

protected:
    void run() override;

private:
    void writeToFile(const LogMessage& msg);
    QString getLogFileName(const QDateTime& dateTime);
    QString formatLogLine(const LogMessage& msg);
    void writeToConsole(const LogMessage& msg);
    void checkRotation(const QString& fileName);
    void cleanupOldFiles();
    QString levelToString(LogLevel level);

private:
    LogConfig m_config;                // 日志配置
    QQueue<LogMessage> m_queue;        // 日志消息队列
    QMutex m_mutex;                    // 互斥锁
    QWaitCondition m_condition;        // 条件变量
    bool m_running;                    // 运行标志
};

/**
 * @class QtLogger
 * @brief Qt日志器单例类
 * @details 提供全局日志功能，支持异步写入和多种配置
 */
class QtLogger {
public:
    /**
     * @brief 获取单例实例
     * @return 日志器引用
     */
    static QtLogger& instance();
    
    /**
     * @brief 初始化日志系统
     * @param config 日志配置
     */
    void init(const LogConfig& config);
    
    /**
     * @brief 关闭日志系统
     */
    void shutdown();
    
    /**
     * @brief 设置日志级别
     * @param level 日志级别
     */
    void setLevel(LogLevel level);

private:
    QtLogger();
    ~QtLogger();
    
    // 禁止拷贝
    QtLogger(const QtLogger&) = delete;
    QtLogger& operator=(const QtLogger&) = delete;

    static void messageHandler(QtMsgType type, const QMessageLogContext& context, const QString& msg);
    void handleMessage(QtMsgType type, const QMessageLogContext& context, const QString& msg);

private:
    LogConfig m_config;        // 日志配置
    LogWriter* m_writer;       // 日志写入器
    QMutex m_mutex;            // 互斥锁
};

// 便捷宏定义
#define LOG_INIT(config) QtLogger::instance().init(config)
#define LOG_SHUTDOWN() QtLogger::instance().shutdown()
#define LOG_SET_LEVEL(level) QtLogger::instance().setLevel(level)

#endif // QTLOGGER_H

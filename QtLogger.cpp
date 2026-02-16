#include "QtLogger.h"

LogWriter::LogWriter(const LogConfig& config, QObject* parent)
    : QThread(parent)
    , m_config(config)
    , m_running(true)
{
    setObjectName("LogWriter");
}

LogWriter::~LogWriter()
{
    stop();
    wait();
}

void LogWriter::enqueue(const LogMessage& msg)
{
    QMutexLocker locker(&m_mutex);
    m_queue.enqueue(msg);
    m_condition.wakeOne();
}

void LogWriter::stop()
{
    QMutexLocker locker(&m_mutex);
    m_running = false;
    m_condition.wakeOne();
}

void LogWriter::run()
{
    while (m_running) {
        LogMessage msg;
        {
            QMutexLocker locker(&m_mutex);
            while (m_queue.isEmpty() && m_running) {
                m_condition.wait(&m_mutex);
            }
            
            if (!m_running && m_queue.isEmpty()) {
                break;
            }
            
            if (!m_queue.isEmpty()) {
                msg = m_queue.dequeue();
            }
        }
        
        if (!msg.message.isEmpty()) {
            writeToFile(msg);
        }
    }
    
    // 处理剩余消息
    QMutexLocker locker(&m_mutex);
    while (!m_queue.isEmpty()) {
        writeToFile(m_queue.dequeue());
    }
}

void LogWriter::writeToFile(const LogMessage& msg)
{
    QString logFileName = getLogFileName(msg.timestamp);
    
    QFile file(logFileName);
    if (file.open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text)) {
        QTextStream ts(&file);
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
        ts.setEncoding(QStringConverter::Utf8);
#else
        ts.setCodec(QTextCodec::codecForName("UTF-8"));
#endif
        ts << formatLogLine(msg) << "\n";
        file.close();
    }
    
    // 检查是否需要滚动
    checkRotation(logFileName);
    
    // 控制台输出
    if (m_config.consoleOutput) {
        writeToConsole(msg);
    }
}

QString LogWriter::getLogFileName(const QDateTime& dateTime)
{
    return QString("%1/%2_%3.log")
        .arg(m_config.logDir)
        .arg(m_config.logFilePrefix)
        .arg(dateTime.toString("yyyy-MM-dd"));
}

QString LogWriter::formatLogLine(const LogMessage& msg)
{
    QString levelStr = levelToString(msg.level);
    QString fileName = msg.file.isEmpty() ? "unknown" : msg.file;
    QString functionName = msg.function.isEmpty() ? "unknown" : msg.function;
    
    return QString("%1 [%2] (%3:%4, %5): %6")
        .arg(msg.timestamp.toString("yyyy-MM-dd hh:mm:ss.zzz"))
        .arg(levelStr)
        .arg(fileName)
        .arg(msg.line)
        .arg(functionName)
        .arg(msg.message);
}

// 写入日志到控制台
void LogWriter::writeToConsole(const LogMessage& msg)
{
    QString coloredMsg;
    
    if (m_config.coloredOutput) {
        // ANSI颜色代码
        static const char* colors[] = {
            "\033[36m",   // DEBUG - 青色
            "\033[32m",   // INFO - 绿色
            "\033[33m",   // WARNING - 黄色
            "\033[31m",   // CRITICAL - 红色
            "\033[35;1m"  // FATAL - 亮紫色
        };
        static const char* reset = "\033[0m";
        
        int colorIndex = static_cast<int>(msg.level);
        if (colorIndex >= 0 && colorIndex <= 4) {
            coloredMsg = QString("%1%2%3")
                .arg(colors[colorIndex])
                .arg(formatLogLine(msg))
                .arg(reset);
        }
    } else {
        coloredMsg = formatLogLine(msg);
    }
    
    // 根据级别选择输出流
    FILE* stream = (msg.level >= LogLevel::CRITICAL) ? stderr : stdout;
    fprintf(stream, "%s\n", coloredMsg.toUtf8().constData());
    fflush(stream);
}

// 检查日志滚动
void LogWriter::checkRotation(const QString& fileName)
{
    QFile file(fileName);
    if (file.exists() && file.size() > m_config.maxFileSize) {
        // 滚动日志：重命名为带序号的文件
        int index = 1;
        QString backupName;
        do {
            backupName = QString("%1.%2").arg(fileName).arg(index++);
        } while (QFile::exists(backupName));
        
        file.rename(backupName);
        
        // 清理旧文件
        cleanupOldFiles();
    }
}

void LogWriter::cleanupOldFiles()
{
    QDir dir(m_config.logDir);
    QStringList filters;
    filters << QString("%1_*.log*").arg(m_config.logFilePrefix);
    
    QFileInfoList fileList = dir.entryInfoList(filters, QDir::Files, QDir::Time);
    
    while (fileList.size() > m_config.maxFileCount) {
        QFileInfo oldestFile = fileList.takeLast();
        QFile::remove(oldestFile.absoluteFilePath());
    }
}

QString LogWriter::levelToString(LogLevel level)
{
    switch (level) {
        case LogLevel::DEBUG:    return "DEBUG";
        case LogLevel::INFO:     return "INFO ";
        case LogLevel::WARNING:  return "WARN ";
        case LogLevel::CRITICAL: return "ERROR";
        case LogLevel::FATAL:    return "FATAL";
        default:                 return "UNKNWN";
    }
}

QtLogger& QtLogger::instance()
{
    static QtLogger logger;
    return logger;
}

void QtLogger::init(const LogConfig& config)
{
    QMutexLocker locker(&m_mutex);
    
    m_config = config;
    
    QDir dir;
    dir.mkpath(m_config.logDir);
    
    // 启动异步写入线程
    if (!m_writer) {
        m_writer = new LogWriter(m_config);
        m_writer->start();
    }
    
    qInstallMessageHandler(messageHandler);
}

void QtLogger::shutdown()
{
    QMutexLocker locker(&m_mutex);
    
    if (m_writer) {
        m_writer->stop();
        m_writer->wait();
        delete m_writer;
        m_writer = nullptr;
    }
    
    qInstallMessageHandler(nullptr);
}

void QtLogger::setLevel(LogLevel level)
{
    QMutexLocker locker(&m_mutex);
    m_config.minLevel = level;
}

QtLogger::QtLogger()
    : m_writer(nullptr)
{
}

QtLogger::~QtLogger()
{
    shutdown();
}

void QtLogger::messageHandler(QtMsgType type, const QMessageLogContext& context, const QString& msg)
{
    QtLogger::instance().handleMessage(type, context, msg);
}

void QtLogger::handleMessage(QtMsgType type, const QMessageLogContext& context, const QString& msg)
{
    LogLevel level;
    
    switch (type) {
        case QtDebugMsg:    level = LogLevel::DEBUG; break;
        case QtInfoMsg:     level = LogLevel::INFO; break;
        case QtWarningMsg:  level = LogLevel::WARNING; break;
        case QtCriticalMsg: level = LogLevel::CRITICAL; break;
        case QtFatalMsg:    level = LogLevel::FATAL; break;
        default:            level = LogLevel::INFO; break;
    }
    
    if (level < m_config.minLevel) {
        return;
    }
    
    LogMessage logMsg;
    logMsg.level = level;
    logMsg.message = msg;
    logMsg.file = context.file ? QString::fromLatin1(context.file).section('/', -1) : QString();
    logMsg.line = context.line;
    logMsg.function = context.function ? QString::fromLatin1(context.function) : QString();
    logMsg.timestamp = QDateTime::currentDateTime();
    
    if (m_writer) {
        m_writer->enqueue(logMsg);
    }
    
    if (type == QtFatalMsg) {
        abort();
    }
}

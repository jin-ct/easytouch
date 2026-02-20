#include "updatehelper.h"
#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QProcess>
#include <QStandardPaths>
#include <QDebug>
#include <QTimer>
#include <QTextStream>
#include <QStringConverter>
#include <QThread>
#include <QSslError>
#include <QSslConfiguration>
#include <Windows.h>
#include <ShlObj.h>
#include <ShlDisp.h>
#include <Shlwapi.h>
#include <comdef.h>
#include <comutil.h>

#pragma comment(lib, "shlwapi.lib")
#pragma comment(lib, "comsuppw.lib")
#pragma comment(lib, "ole32.lib")
#pragma comment(lib, "oleaut32.lib")

UpdateHelper::UpdateHelper(QObject *parent)
    : QObject(parent)
    , networkManager(nullptr)
    , currentReply(nullptr)
{
    networkManager = new QNetworkAccessManager(this);
    
    connect(this, &UpdateHelper::updateAvailable, this, [=](const QString &version, const QString &downloadUrl){
        qDebug() << "updateAvailable: " << version << " " << downloadUrl;
        startDownload(downloadUrl);
    });
    connect(this, &UpdateHelper::updateCheckFinished, this, [=](bool hasUpdate){
        qDebug() << "updateCheckFinished: " << hasUpdate;
    });
    connect(this, &UpdateHelper::updateError, this, [=](const QString &error){
        qDebug() << "updateError: " << error;
    });
    connect(this, &UpdateHelper::updateProgress, this, [=](qint64 bytesReceived, qint64 bytesTotal){
        qDebug() << "updateProgress: " << bytesReceived << " / " << bytesTotal;
    });
}

UpdateHelper::~UpdateHelper()
{
    if (currentReply) {
        currentReply->deleteLater();
    }
}

QString UpdateHelper::getCurrentVersion() const
{
    QString version = QCoreApplication::applicationVersion();
    if (version.isEmpty()) {
        version = "1.0.0.0"; // 默认版本
    }
    return version;
}

void UpdateHelper::checkForUpdates(const QString &repoOwner, const QString &repoName)
{
    this->repoOwner = repoOwner;
    this->repoName = repoName;

    QString apiUrl = QString("https://api.github.com/repos/%1/%2/releases/latest")
                     .arg(repoOwner, repoName);

    QNetworkRequest request(apiUrl);
    request.setRawHeader("User-Agent", "EasyTouch-Updater/1.0");
    request.setRawHeader("Accept", "application/vnd.github.v3+json");

    // 配置 SSL，忽略证书错误（用于更新检查）
    QSslConfiguration sslConfig = request.sslConfiguration();
    sslConfig.setPeerVerifyMode(QSslSocket::VerifyNone);
    request.setSslConfiguration(sslConfig);

    currentReply = networkManager->get(request);
    connect(currentReply, &QNetworkReply::finished, this, &UpdateHelper::onReleaseInfoReceived);
    connect(currentReply, QOverload<QNetworkReply::NetworkError>::of(&QNetworkReply::errorOccurred),
            this, &UpdateHelper::onDownloadError);
    // 忽略 SSL 错误
    connect(currentReply, &QNetworkReply::sslErrors, this, [this](const QList<QSslError> &errors) {
        Q_UNUSED(errors);
        if (currentReply) {
            currentReply->ignoreSslErrors();
        }
    });
}

void UpdateHelper::onReleaseInfoReceived()
{
    if (!currentReply) {
        emit updateError("网络请求失败");
        emit updateCheckFinished(false);
        return;
    }

    if (currentReply->error() != QNetworkReply::NoError) {
        emit updateError(QString("网络错误: %1").arg(currentReply->errorString()));
        emit updateCheckFinished(false);
        currentReply->deleteLater();
        currentReply = nullptr;
        return;
    }

    QByteArray data = currentReply->readAll();
    currentReply->deleteLater();
    currentReply = nullptr;

    parseReleaseInfo(data);
}

void UpdateHelper::parseReleaseInfo(const QByteArray &data)
{
    QJsonParseError error;
    QJsonDocument doc = QJsonDocument::fromJson(data, &error);

    if (error.error != QJsonParseError::NoError) {
        emit updateError(QString("解析JSON失败: %1").arg(error.errorString()));
        emit updateCheckFinished(false);
        return;
    }

    QJsonObject release = doc.object();
    QString tagName = release["tag_name"].toString();

    if (tagName.isEmpty()) {
        emit updateError("未找到版本标签" + data);
        emit updateCheckFinished(false);
        return;
    }

    // 移除 "v" 前缀
    QString version = tagName.startsWith("v") ? tagName.mid(1) : tagName;
    latestVersion = version;

    // 查找名为 "easytouch-win-64.zip" 的资源文件
    QJsonArray assets = release["assets"].toArray();
    QString downloadUrlFound;

    for (const QJsonValue &assetValue : assets) {
        QJsonObject asset = assetValue.toObject();
        QString name = asset["name"].toString();
        if (name == "easytouch-win-64.zip" || name.contains("easytouch-win-64.zip")) {
            downloadUrlFound = asset["browser_download_url"].toString();
            break;
        }
    }

    if (downloadUrlFound.isEmpty()) {
        emit updateError("未找到 easytouch-win-64.zip 文件");
        emit updateCheckFinished(false);
        return;
    }

    downloadUrl = downloadUrlFound;

    // 比较版本号
    QString currentVersion = getCurrentVersion();
    bool needsUpdate = compareVersions(currentVersion, latestVersion);

    if (needsUpdate) {
        emit updateAvailable(latestVersion, downloadUrl);
        emit updateCheckFinished(true);
    } else {
        emit updateCheckFinished(false);
    }
}

void UpdateHelper::startDownload(const QString &downloadUrl)
{
    downloadUpdate(downloadUrl);
}

bool UpdateHelper::compareVersions(const QString &currentVersion, const QString &latestVersion)
{
    QStringList currentParts = currentVersion.split('.');
    QStringList latestParts = latestVersion.split('.');

    // 确保两个版本号都有相同数量的部分
    int maxParts = qMax(currentParts.size(), latestParts.size());
    while (currentParts.size() < maxParts) currentParts.append("0");
    while (latestParts.size() < maxParts) latestParts.append("0");

    for (int i = 0; i < maxParts; ++i) {
        int current = currentParts[i].toInt();
        int latest = latestParts[i].toInt();

        if (latest > current) {
            return true;
        } else if (latest < current) {
            return false;
        }
    }

    return false; // 版本相同
}

void UpdateHelper::downloadUpdate(const QString &downloadUrl)
{
    this->downloadUrl = downloadUrl;

    QString tempDir = getTempDir();
    QDir dir;
    if (!dir.exists(tempDir)) {
        dir.mkpath(tempDir);
    }

    zipFilePath = QDir(tempDir).filePath("update.zip");

    QNetworkRequest request(downloadUrl);
    request.setRawHeader("User-Agent", "EasyTouch-Updater/1.0");

    // 配置 SSL，忽略证书错误（用于更新下载）
    QSslConfiguration sslConfig = request.sslConfiguration();
    sslConfig.setPeerVerifyMode(QSslSocket::VerifyNone);
    request.setSslConfiguration(sslConfig);

    currentReply = networkManager->get(request);
    connect(currentReply, &QNetworkReply::downloadProgress, this, &UpdateHelper::onDownloadProgress);
    connect(currentReply, &QNetworkReply::finished, this, &UpdateHelper::onDownloadFinished);
    connect(currentReply, QOverload<QNetworkReply::NetworkError>::of(&QNetworkReply::errorOccurred),
            this, &UpdateHelper::onDownloadError);
    // 忽略 SSL 错误
    connect(currentReply, &QNetworkReply::sslErrors, this, [this](const QList<QSslError> &errors) {
        Q_UNUSED(errors);
        if (currentReply) {
            currentReply->ignoreSslErrors();
        }
    });
}

void UpdateHelper::onDownloadProgress(qint64 bytesReceived, qint64 bytesTotal)
{
    emit updateProgress(bytesReceived, bytesTotal);
}

void UpdateHelper::onDownloadFinished()
{
    if (!currentReply) {
        emit updateError("下载失败");
        return;
    }

    if (currentReply->error() != QNetworkReply::NoError) {
        emit updateError(QString("下载错误: %1").arg(currentReply->errorString()));
        currentReply->deleteLater();
        currentReply = nullptr;
        return;
    }

    // 保存文件
    QFile file(zipFilePath);
    if (!file.open(QIODevice::WriteOnly)) {
        emit updateError(QString("无法创建文件: %1").arg(zipFilePath));
        currentReply->deleteLater();
        currentReply = nullptr;
        return;
    }

    file.write(currentReply->readAll());
    file.close();

    currentReply->deleteLater();
    currentReply = nullptr;

    // 解压文件
    QString tempDir = getTempDir();
    extractPath = QDir(tempDir).filePath("extracted");
    extractZip(zipFilePath, extractPath);
}

void UpdateHelper::onDownloadError(QNetworkReply::NetworkError error)
{
    Q_UNUSED(error);
    if (currentReply) {
        emit updateError(QString("网络错误: %1").arg(currentReply->errorString()));
        currentReply->deleteLater();
        currentReply = nullptr;
    }
}

void UpdateHelper::extractZip(const QString &zipPath, const QString &extractPath)
{
    QDir dir;
    if (!dir.exists(extractPath)) {
        dir.mkpath(extractPath);
    }

    // 确保路径是绝对路径且格式正确
    QString absZipPath = QDir::toNativeSeparators(QFileInfo(zipPath).absoluteFilePath());
    QString absExtractPath = QDir::toNativeSeparators(QFileInfo(extractPath).absoluteFilePath());

    qDebug() << "解压 ZIP 文件:" << absZipPath;
    qDebug() << "解压到目录:" << absExtractPath;

    // 使用 PowerShell Expand-Archive 命令解压（更可靠）
    QString powershellCmd = QString("powershell.exe -Command \"Expand-Archive -Path '%1' -DestinationPath '%2' -Force\"")
                            .arg(absZipPath.replace("'", "''"))
                            .arg(absExtractPath.replace("'", "''"));

    QProcess extractProcess;
    extractProcess.start(powershellCmd);
    extractProcess.waitForFinished(30000); // 等待最多30秒

    if (extractProcess.exitCode() != 0) {
        QString errorOutput = extractProcess.readAllStandardError();
        QString stdOutput = extractProcess.readAllStandardOutput();
        qDebug() << "PowerShell 解压失败，退出码:" << extractProcess.exitCode();
        qDebug() << "错误输出:" << errorOutput;
        qDebug() << "标准输出:" << stdOutput;
        
        // 如果 PowerShell 失败，尝试使用 Shell API
        if (!extractUsingShellAPI(absZipPath, absExtractPath)) {
            emit updateError(QString("解压文件失败: %1").arg(errorOutput));
            return;
        }
    }

    // 检查解压后的目录是否有文件
    QDir extractDir(absExtractPath);
    QStringList files = extractDir.entryList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot);
    if (files.isEmpty()) {
        qDebug() << "警告: 解压后目录为空，尝试使用 Shell API";
        if (!extractUsingShellAPI(absZipPath, absExtractPath)) {
            emit updateError("解压文件失败: 解压后目录为空");
            return;
        }
    } else {
        qDebug() << "解压成功，文件数量:" << files.size();
    }

    // 删除压缩包
    QFile::remove(zipPath);

    // 创建更新脚本并执行
    createUpdateScript(extractPath);
}

bool UpdateHelper::extractUsingShellAPI(const QString &zipPath, const QString &extractPath)
{
    // 初始化 COM
    HRESULT hr = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
    bool needUninit = (SUCCEEDED(hr) || hr == RPC_E_CHANGED_MODE);
    
    if (FAILED(hr) && hr != RPC_E_CHANGED_MODE) {
        qDebug() << "COM 初始化失败:" << hr;
        return false;
    }

    // 使用 Windows Shell API 解压 ZIP 文件
    // 路径需要是绝对路径，且使用反斜杠
    QString zipPathNormalized = QDir::toNativeSeparators(QFileInfo(zipPath).absoluteFilePath());
    QString extractPathNormalized = QDir::toNativeSeparators(QFileInfo(extractPath).absoluteFilePath());

    std::wstring zipPathW = zipPathNormalized.toStdWString();
    std::wstring extractPathW = extractPathNormalized.toStdWString();

    qDebug() << "使用 Shell API 解压:" << zipPathNormalized << "->" << extractPathNormalized;

    // 使用 Shell32 API 解压
    IShellDispatch *pIShellDispatch = nullptr;
    hr = CoCreateInstance(CLSID_Shell, nullptr, CLSCTX_INPROC_SERVER,
                          IID_IShellDispatch, (void**)&pIShellDispatch);

    if (FAILED(hr) || !pIShellDispatch) {
        qDebug() << "创建 IShellDispatch 失败:" << hr;
        if (needUninit) CoUninitialize();
        return false;
    }

    VARIANT vZipFile, vDestFolder, vOptions, vItem;
    VariantInit(&vZipFile);
    VariantInit(&vDestFolder);
    VariantInit(&vOptions);
    VariantInit(&vItem);

    vZipFile.vt = VT_BSTR;
    vZipFile.bstrVal = SysAllocString(zipPathW.c_str());

    vDestFolder.vt = VT_BSTR;
    vDestFolder.bstrVal = SysAllocString(extractPathW.c_str());

    vOptions.vt = VT_I4;
    vOptions.lVal = 1024 | 16; // 1024=不显示进度对话框, 16=自动响应"是"

    Folder *pZipFolder = nullptr;
    hr = pIShellDispatch->NameSpace(vZipFile, &pZipFolder);

    if (FAILED(hr) || !pZipFolder) {
        qDebug() << "打开 ZIP 文件夹失败:" << hr;
        VariantClear(&vZipFile);
        VariantClear(&vDestFolder);
        VariantClear(&vOptions);
        pIShellDispatch->Release();
        if (needUninit) CoUninitialize();
        return false;
    }

    Folder *pDestFolder = nullptr;
    hr = pIShellDispatch->NameSpace(vDestFolder, &pDestFolder);

    if (FAILED(hr) || !pDestFolder) {
        qDebug() << "打开目标文件夹失败:" << hr;
        VariantClear(&vZipFile);
        VariantClear(&vDestFolder);
        VariantClear(&vOptions);
        pZipFolder->Release();
        pIShellDispatch->Release();
        if (needUninit) CoUninitialize();
        return false;
    }

    FolderItems *pItems = nullptr;
    hr = pZipFolder->Items(&pItems);

    if (FAILED(hr) || !pItems) {
        qDebug() << "获取 ZIP 文件列表失败:" << hr;
        VariantClear(&vZipFile);
        VariantClear(&vDestFolder);
        VariantClear(&vOptions);
        pDestFolder->Release();
        pZipFolder->Release();
        pIShellDispatch->Release();
        if (needUninit) CoUninitialize();
        return false;
    }

    vItem.vt = VT_DISPATCH;
    vItem.pdispVal = pItems;

    hr = pDestFolder->CopyHere(vItem, vOptions);
    
    qDebug() << "CopyHere 返回:" << hr;

    if (SUCCEEDED(hr)) {
        // 等待最多10秒，检查文件是否出现
        for (int i = 0; i < 100; ++i) {
            QDir extractDir(extractPathNormalized);
            QStringList files = extractDir.entryList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot);
            if (!files.isEmpty()) {
                qDebug() << "解压完成，文件数量:" << files.size();
                break;
            }
            QThread::msleep(100);
        }
    }

    // 清理资源
    pItems->Release();
    pDestFolder->Release();
    pZipFolder->Release();
    VariantClear(&vZipFile);
    VariantClear(&vDestFolder);
    VariantClear(&vOptions);
    VariantClear(&vItem);
    pIShellDispatch->Release();

    if (needUninit) {
        CoUninitialize();
    }

    return SUCCEEDED(hr);
}

void UpdateHelper::createUpdateScript(const QString &extractPath)
{
    QString tempDir = getTempDir();
    QString scriptPath = QDir(tempDir).filePath("update.bat");
    QString appDir = getAppDir();
    QString exeName = getExeName();
    QString exePath = QDir(appDir).filePath(exeName);

    QFile scriptFile(scriptPath);
    if (!scriptFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
        emit updateError("无法创建更新脚本");
        return;
    }

    QTextStream out(&scriptFile);
    out.setEncoding(QStringConverter::Utf8);

    // 写入批处理脚本
    out << "@echo off\n";
    out << "REM 简单等待应用程序完全退出\n";
    out << "timeout /t 3 /nobreak\n";
    out << "\n";
    out << "REM 复制文件\n";
    out << "xcopy /E /Y /I \"" << extractPath << "\\*\" \"" << appDir << "\"\n";
    out << "\n";
    out << "REM 清空临时目录\n";
    out << "rmdir /S /Q \"" << tempDir << "\"\n";
    out << "\n";
    out << "REM 启动程序\n";
    out << "start \"\" \"" << exePath << "\"\n";
    out << "\n";
    out << "REM 删除自身\n";
    out << "del \"%~f0\"\n";

    scriptFile.close();

    executeUpdate();
}

void UpdateHelper::executeUpdate()
{
    QString tempDir = getTempDir();
    QString scriptPath = QDir(tempDir).filePath("update.bat");

    // 启动脚本
    qint64 pid = 0;
    bool success = QProcess::startDetached("cmd.exe", QStringList() << "/c" << scriptPath, QString(), &pid);

    if (success) {
        // 退出应用程序
        QTimer::singleShot(500, qApp, &QCoreApplication::quit);
    } else {
        emit updateError("无法启动更新脚本");
    }
}

QString UpdateHelper::getTempDir() const
{
    QString appDir = getAppDir();
    return QDir(appDir).filePath("temp");
}

QString UpdateHelper::getAppDir() const
{
    return QCoreApplication::applicationDirPath();
}

QString UpdateHelper::getExeName() const
{
    return QFileInfo(QCoreApplication::applicationFilePath()).fileName();
}

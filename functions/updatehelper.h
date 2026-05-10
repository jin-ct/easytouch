#ifndef UPDATEHELPER_H
#define UPDATEHELPER_H

#include <QObject>
#include <QString>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QVector>

class UpdateHelper : public QObject
{
    Q_OBJECT
public:
    explicit UpdateHelper(QObject *parent = nullptr);
    ~UpdateHelper();

    Q_INVOKABLE void checkForUpdates(const QString &repoOwner, const QString &repoName, bool isRetrying = false);
    Q_INVOKABLE void startDownload(const QString &downloadUrl);
    Q_INVOKABLE QString getCurrentVersion() const;

signals:
    void updateAvailable(const QString &version, const QString &downloadUrl);
    void updateCheckFinished(bool hasUpdate);
    void updateProgress(qint64 bytesReceived, qint64 bytesTotal);
    void updateError(const QString &error);
    void networkError();

private slots:
    void onReleasesListReceived();
    void onDownloadProgress(qint64 bytesReceived, qint64 bytesTotal);
    void onDownloadFinished();
    void onDownloadError(QNetworkReply::NetworkError error);

private:
    void requestReleasesPage();
    void finalizeReleasesAndCompare();
    QString updateChannelSuffix() const;
    QString semverFromChannelTag(const QString &tagName, const QString &channelSuffix) const;
    static int compareSemver(const QString &a, const QString &b);
    QString findWin64AssetUrl(const QJsonObject &release) const;
    bool compareVersions(const QString &currentVersion, const QString &latestSemver);
    void downloadUpdate(const QString &downloadUrl);
    void extractZip(const QString &zipPath, const QString &extractPath);
    bool extractUsingShellAPI(const QString &zipPath, const QString &extractPath);
    void createUpdateScript(const QString &extractPath);
    void executeUpdate();
    QString getTempDir() const;
    QString getAppDir() const;
    QString getExeName() const;

    QNetworkAccessManager *networkManager;
    QNetworkReply *currentReply;
    QString latestVersion;
    QString downloadUrl;
    QString zipFilePath;
    QString extractPath;
    QString repoOwner;
    QString repoName;
    int m_releasesListPage = 1;
    static const int m_releaseListPerPage = 100;
    QVector<QJsonObject> m_releasesAccumulated;
    bool m_usingGitHubApi = false;
};

#endif // UPDATEHELPER_H

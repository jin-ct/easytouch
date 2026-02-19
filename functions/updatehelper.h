#ifndef UPDATEHELPER_H
#define UPDATEHELPER_H

#include <QObject>
#include <QString>

class QNetworkAccessManager;
class QNetworkReply;

class UpdateHelper : public QObject
{
    Q_OBJECT
public:
    explicit UpdateHelper(QObject *parent = nullptr);
    ~UpdateHelper();

};

#endif // UPDATEHELPER_H

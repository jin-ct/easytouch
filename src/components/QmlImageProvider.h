#ifndef QMLIMAGEPROVIDER_H
#define QMLIMAGEPROVIDER_H

#include <QQuickImageProvider>
#include <QMap>
#include <QImage>
#include <QPixmap>

class QmlImageProvider : public QQuickImageProvider
{
public:
    explicit QmlImageProvider(QObject *parent = nullptr);

   static QmlImageProvider* instance();

    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize);
    QPixmap requestPixmap(const QString &id, QSize *size, const QSize &requestedSize);

    qsizetype addImg(const QImage &img);
    void removeImg(qsizetype index);
    Q_INVOKABLE void removeImgQml(QVariant index);

    QMap<qsizetype, QImage> imgs{};

private:
    static QmlImageProvider* m_instance;
};

#endif // QMLIMAGEPROVIDER_H

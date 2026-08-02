#include "QmlImageProvider.h"
#include <QApplication>
#include <QDebug>
#include <QMutexLocker>

QmlImageProvider* QmlImageProvider::m_instance = nullptr;

QmlImageProvider::QmlImageProvider(QObject *parent)
    : QQuickImageProvider(QQuickImageProvider::Image)
{}

QmlImageProvider *QmlImageProvider::instance()
{
    if (!m_instance)
        m_instance = new QmlImageProvider(qApp);
    return m_instance;
}

QImage QmlImageProvider::requestImage(const QString &id, QSize *size, const QSize &requestedSize)
{
    if (id.isEmpty())
        return QImage();
    QMutexLocker locker(&mutex);
    return imgs[id.toInt()];
}

QPixmap QmlImageProvider::requestPixmap(const QString &id, QSize *size, const QSize &requestedSize)
{
    if (id.isEmpty())
        return QPixmap();
    QMutexLocker locker(&mutex);
    return QPixmap::fromImage(imgs[id.toInt()]);
}

qsizetype QmlImageProvider::addImg(const QImage &img)
{
    qsizetype index = imgs.isEmpty() ? 0 : imgs.lastKey() + 1;
    QMutexLocker locker(&mutex);
    imgs[index] = img;
    return index;
}

void QmlImageProvider::removeImg(qsizetype index)
{
    QMutexLocker locker(&mutex);
    imgs.remove(index);
}

void QmlImageProvider::removeImgQml(QVariant index)
{
    QMutexLocker locker(&mutex);
    removeImg(index.toInt());
}


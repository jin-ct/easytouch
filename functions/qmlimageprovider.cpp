#include "qmlimageprovider.h"
#include <QApplication>
#include <QDebug>

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
    return imgs[id.toInt()];
}

QPixmap QmlImageProvider::requestPixmap(const QString &id, QSize *size, const QSize &requestedSize)
{
    if (id.isEmpty())
        return QPixmap();
    return QPixmap::fromImage(imgs[id.toInt()]);
}

qsizetype QmlImageProvider::addImg(const QImage &img)
{
    qsizetype index = imgs.isEmpty() ? 0 : imgs.lastKey() + 1;
    imgs[index] = img;
    return index;
}

void QmlImageProvider::removeImg(qsizetype index)
{
    imgs.remove(index);
}

void QmlImageProvider::removeImgQml(QVariant index)
{
    removeImg(index.toInt());
}


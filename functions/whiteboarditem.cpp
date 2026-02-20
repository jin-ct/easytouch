#include "whiteboarditem.h"

#include <QPainter>
#include <QPainterPath>
#include <QMouseEvent>
#include <QTouchEvent>
#include <QDateTime>
#include <QDir>
#include <QCursor>
#include <QPixmap>
#include <cmath>

WhiteboardItem::WhiteboardItem(QQuickItem *parent)
    : QQuickPaintedItem(parent)
{
    setAcceptedMouseButtons(Qt::AllButtons);
    setAcceptHoverEvents(true);
    setFlag(ItemHasContents, true);

    // 创建自定义灰色小点光标
    QPixmap cursorPixmap(16, 16);
    cursorPixmap.fill(Qt::transparent);
    QPainter p(&cursorPixmap);
    p.setRenderHint(QPainter::Antialiasing, true);
    p.setBrush(QColor(128, 128, 128, 255));  // 灰色
    p.setPen(Qt::NoPen);
    p.drawEllipse(5, 5, 6, 6);  // 6x6 像素的灰色圆点，居中
    p.end();

    // 设置光标，热点在圆心
    QCursor customCursor(cursorPixmap, 8, 8);
    setCursor(customCursor);
}

void WhiteboardItem::ensureImage()
{
    const int w = int(width() * m_scaleFactor);
    const int h = int(height() * m_scaleFactor);
    if (w <= 0 || h <= 0)
        return;

    const QSize sz(w, h);
    if (m_image.size() == sz)
        return;

    QImage newImg(sz, QImage::Format_ARGB32_Premultiplied);
    newImg.fill(Qt::transparent);

    if (!m_image.isNull()) {
        QPainter p(&newImg);
        p.drawImage(0, 0, m_image);
    }

    m_image = newImg;
    update();
}

void WhiteboardItem::geometryChange(const QRectF &newGeometry, const QRectF &oldGeometry)
{
    QQuickPaintedItem::geometryChange(newGeometry, oldGeometry);
    if (newGeometry.size() != oldGeometry.size())
        ensureImage();
}

void WhiteboardItem::paint(QPainter *painter)
{
    if (m_image.isNull())
        ensureImage();
    if (!m_image.isNull()) {
        painter->setRenderHint(QPainter::Antialiasing, true);
        // 将高分辨率位图缩放绘制到实际控件大小，实现超采样抗锯齿
        const QRectF targetRect(0, 0, width(), height());
        const QRectF sourceRect(0, 0, m_image.width(), m_image.height());
        painter->drawImage(targetRect, m_image, sourceRect);
    }
}

void WhiteboardItem::setPenColor(const QColor &color)
{
    if (m_penColor == color)
        return;
    m_penColor = color;
    emit penColorChanged();
}

void WhiteboardItem::setPenWidth(qreal w)
{
    if (qFuzzyCompare(m_penWidth, w))
        return;
    m_penWidth = w;
    emit penWidthChanged();
}

void WhiteboardItem::setEraserMode(bool e)
{
    if (m_eraserMode == e)
        return;
    m_eraserMode = e;
    emit eraserModeChanged();
}

void WhiteboardItem::setEraserRadius(qreal r)
{
    if (qFuzzyCompare(m_eraserRadius, r))
        return;
    m_eraserRadius = r;
    emit eraserRadiusChanged();
}

void WhiteboardItem::clear()
{
    if (m_image.isNull())
        ensureImage();
    if (!m_image.isNull()) {
        m_image.fill(Qt::transparent);
        update();
    }
}

void WhiteboardItem::exportPng(const QString &path)
{
    if (m_image.isNull())
        return;

    QString outPath = path;
    if (QDir(path).isRelative())
        outPath = QDir::current().absoluteFilePath(path);

    m_image.save(outPath, "PNG");
}

void WhiteboardItem::mousePressEvent(QMouseEvent *event)
{
    if (event->button() != Qt::LeftButton) {
        QQuickPaintedItem::mousePressEvent(event);
        return;
    }
    event->accept();
    ensureImage();
    const QPointF pt = event->position();
    if (m_eraserMode) {
        eraseAt(pt);
        emit pointerMoved(pt.x(), pt.y(), true);
        return;
    }
    beginStroke(pt);
    emit pointerMoved(pt.x(), pt.y(), true);
}

void WhiteboardItem::mouseMoveEvent(QMouseEvent *event)
{
    if (!(event->buttons() & Qt::LeftButton)) {
        QQuickPaintedItem::mouseMoveEvent(event);
        return;
    }
    event->accept();
    ensureImage();
    const QPointF pt = event->position();
    if (m_eraserMode) {
        eraseAt(pt);
        emit pointerMoved(pt.x(), pt.y(), true);
        return;
    }
    continueStroke(pt);
    emit pointerMoved(pt.x(), pt.y(), true);
}

void WhiteboardItem::mouseReleaseEvent(QMouseEvent *event)
{
    if (event->button() != Qt::LeftButton) {
        QQuickPaintedItem::mouseReleaseEvent(event);
        return;
    }
    event->accept();
    endStroke();
    emit pointerMoved(m_lastPoint.x(), m_lastPoint.y(), false);
}

void WhiteboardItem::beginStroke(const QPointF &pt)
{
    m_strokePoints.clear();
    m_strokePoints.push_back(pt);
    m_lastPoint = pt;
    m_lastTimeMs = QDateTime::currentMSecsSinceEpoch();
    m_hasLastPoint = true;

    // 起笔画一个极短线段，避免起点是空的
    const QPointF to = pt + QPointF(0.1, 0.1);
    drawSegment(pt, to, speedToWidth(0.0));
}

void WhiteboardItem::continueStroke(const QPointF &pt)
{
    if (!m_hasLastPoint) {
        beginStroke(pt);
        return;
    }

    const qint64 now = QDateTime::currentMSecsSinceEpoch();
    qreal dt = qreal(now - m_lastTimeMs);
    if (dt <= 0)
        dt = 1;

    const qreal dx = pt.x() - m_lastPoint.x();
    const qreal dy = pt.y() - m_lastPoint.y();
    const qreal dist = std::sqrt(dx * dx + dy * dy);
    if (dist <= 0.0)
        return;

    const qreal speed = dist / dt; // 像素/毫秒
    const qreal w = speedToWidth(speed);

    // 记录原始点，用于样条拟合
    m_strokePoints.push_back(pt);

    // 点较少时，直接画直线，避免算法过于复杂
    if (m_strokePoints.size() < 4) {
        drawSegment(m_lastPoint, pt, w);
    } else {
        // 使用 Catmull-Rom 样条在 p1-p2 之间做平滑
        const int n = m_strokePoints.size();
        const QPointF &p0 = m_strokePoints[n - 4];
        const QPointF &p1 = m_strokePoints[n - 3];
        const QPointF &p2 = m_strokePoints[n - 2];
        const QPointF &p3 = m_strokePoints[n - 1]; // = pt

        const qreal baseLen = std::sqrt(std::pow(p2.x() - p1.x(), 2) +
                                        std::pow(p2.y() - p1.y(), 2));
        const int segments = qMax(4, int(baseLen / 4.0)); // 每约 4 像素一个采样点

        QPointF prev = p1;
        for (int i = 1; i <= segments; ++i) {
            const qreal t = qreal(i) / segments; // 0..1
            const QPointF cur = catmullRomPoint(p0, p1, p2, p3, t);
            drawSegment(prev, cur, w);
            prev = cur;
        }
    }

    m_lastPoint = pt;
    m_lastTimeMs = now;
}

void WhiteboardItem::endStroke()
{
    m_hasLastPoint = false;
}

void WhiteboardItem::drawSegment(const QPointF &from, const QPointF &to, qreal width)
{
    ensureImage();
    if (m_image.isNull())
        return;

    QPainter p(&m_image);
    // 坐标系放大到超采样分辨率，逻辑坐标仍然使用控件尺寸
    p.scale(m_scaleFactor, m_scaleFactor);
    p.setRenderHint(QPainter::Antialiasing, true);

    // 对长段做插值，避免鼠标事件过稀时出现断续感
    const qreal dx = to.x() - from.x();
    const qreal dy = to.y() - from.y();
    const qreal dist = std::sqrt(dx * dx + dy * dy);
    const qreal maxStep = 1.0; // 像素，更致密的插值，减弱折线感
    const int steps = qMax(1, int(dist / maxStep));

    for (int i = 0; i < steps; ++i) {
        const qreal t1 = qreal(i) / steps;
        const qreal t2 = qreal(i + 1) / steps;
        const QPointF p1(from.x() + dx * t1, from.y() + dy * t1);
        const QPointF p2(from.x() + dx * t2, from.y() + dy * t2);

        QPen pen(m_penColor, width, Qt::SolidLine, Qt::RoundCap, Qt::RoundJoin);
        p.setPen(pen);
        p.drawLine(p1, p2);
    }

    update();
}

void WhiteboardItem::eraseAt(const QPointF &pt)
{
    ensureImage();
    if (m_image.isNull())
        return;

    QPainter p(&m_image);
    p.scale(m_scaleFactor, m_scaleFactor);
    p.setRenderHint(QPainter::Antialiasing, true);
    p.setCompositionMode(QPainter::CompositionMode_Clear);
    p.setBrush(Qt::transparent);
    p.setPen(Qt::NoPen);
    p.drawEllipse(pt, m_eraserRadius, m_eraserRadius);

    update();
}

qreal WhiteboardItem::speedToWidth(qreal speed) const
{
    // 与 QML 中类似的映射：写得越快越细，越慢越粗
    const qreal minFactor = 1.5;
    const qreal maxFactor = 2.0;
    const qreal baseSpeed = 0.8;

    if (speed <= 0.0)
        return m_penWidth * maxFactor;

    qreal factor = baseSpeed / speed;
    if (factor < minFactor)
        factor = minFactor;
    if (factor > maxFactor)
        factor = maxFactor;
    return m_penWidth * factor;
}

QPointF WhiteboardItem::catmullRomPoint(const QPointF &p0,
                                        const QPointF &p1,
                                        const QPointF &p2,
                                        const QPointF &p3,
                                        qreal t) const
{
    const qreal t2 = t * t;
    const qreal t3 = t2 * t;

    const qreal x = 0.5 * (2.0 * p1.x()
                           + (-p0.x() + p2.x()) * t
                           + (2.0 * p0.x() - 5.0 * p1.x() + 4.0 * p2.x() - p3.x()) * t2
                           + (-p0.x() + 3.0 * p1.x() - 3.0 * p2.x() + p3.x()) * t3);

    const qreal y = 0.5 * (2.0 * p1.y()
                           + (-p0.y() + p2.y()) * t
                           + (2.0 * p0.y() - 5.0 * p1.y() + 4.0 * p2.y() - p3.y()) * t2
                           + (-p0.y() + 3.0 * p1.y() - 3.0 * p2.y() + p3.y()) * t3);

    return QPointF(x, y);
}



#ifndef WHITEBOARDITEM_H
#define WHITEBOARDITEM_H

#include <QQuickPaintedItem>
#include <QImage>
#include <QColor>
#include <QVector>

class WhiteboardItem : public QQuickPaintedItem
{
    Q_OBJECT
    Q_PROPERTY(QColor penColor READ penColor WRITE setPenColor NOTIFY penColorChanged)
    Q_PROPERTY(qreal penWidth READ penWidth WRITE setPenWidth NOTIFY penWidthChanged)
    Q_PROPERTY(bool eraserMode READ eraserMode WRITE setEraserMode NOTIFY eraserModeChanged)
    Q_PROPERTY(qreal eraserRadius READ eraserRadius WRITE setEraserRadius NOTIFY eraserRadiusChanged)

public:
    explicit WhiteboardItem(QQuickItem *parent = nullptr);

    void paint(QPainter *painter) override;

    QColor penColor() const { return m_penColor; }
    void setPenColor(const QColor &color);

    qreal penWidth() const { return m_penWidth; }
    void setPenWidth(qreal w);

    bool eraserMode() const { return m_eraserMode; }
    void setEraserMode(bool e);

    qreal eraserRadius() const { return m_eraserRadius; }
    void setEraserRadius(qreal r);

    Q_INVOKABLE void clear();
    Q_INVOKABLE void exportPng(const QString &path);

signals:
    void penColorChanged();
    void penWidthChanged();
    void eraserModeChanged();
    void eraserRadiusChanged();
    void pointerMoved(qreal x, qreal y, bool pressed);

protected:
    void geometryChange(const QRectF &newGeometry, const QRectF &oldGeometry) override;
    void mousePressEvent(QMouseEvent *event) override;
    void mouseMoveEvent(QMouseEvent *event) override;
    void mouseReleaseEvent(QMouseEvent *event) override;

private:
    void ensureImage();
    void beginStroke(const QPointF &pt);
    void continueStroke(const QPointF &pt);
    void endStroke();
    void drawSegment(const QPointF &from, const QPointF &to, qreal width);
    QPointF catmullRomPoint(const QPointF &p0,
                            const QPointF &p1,
                            const QPointF &p2,
                            const QPointF &p3,
                            qreal t) const;
    void eraseAt(const QPointF &pt);
    qreal speedToWidth(qreal speed) const;

    QImage m_image;
    qreal m_scaleFactor = 3.0;        // 超采样倍率（2x）
    QVector<QPointF> m_strokePoints;   // 当前笔画原始点，用于样条拟合
    QPointF m_lastPoint;
    qint64 m_lastTimeMs = 0;
    bool m_hasLastPoint = false;

    QColor m_penColor = Qt::red;
    qreal m_penWidth = 3.0;
    bool m_eraserMode = false;
    qreal m_eraserRadius = 18.0;
};

#endif // WHITEBOARDITEM_H



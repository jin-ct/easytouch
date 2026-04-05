#include "screenmovement.h"

#include <QWidget>
#include <QApplication>
#include <QScreen>
#include <QTimer>
#include <QPainter>
#include <QPixmap>
#include <QMouseEvent>
#include <QStyleOption>
#include <QGestureEvent>
#include <QPinchGesture>

#include <windows.h>
#include <windowsx.h>

// 某些 SDK 版本可能未定义，兼容处理
#ifndef WDA_EXCLUDEFROMCAPTURE
#define WDA_EXCLUDEFROMCAPTURE 0x00000011
#endif

// ============ 内部辅助窗口类 ============

// 全屏遮罩 + 框选
class MaskSelectOverlay : public QWidget
{
    Q_OBJECT
public:
    explicit MaskSelectOverlay(QWidget *parent = nullptr)
        : QWidget(parent)
    {
        setWindowFlag(Qt::FramelessWindowHint);
        setWindowFlag(Qt::Tool);
        setWindowFlag(Qt::WindowStaysOnTopHint);
        setAttribute(Qt::WA_TranslucentBackground);
        setAttribute(Qt::WA_DeleteOnClose);
        setMouseTracking(true);

        // 覆盖所有屏幕（简单起见，只取虚拟桌面矩形）
        QRect desktopRect;
        const auto screens = QGuiApplication::screens();
        for (QScreen *s : screens) {
            desktopRect = desktopRect.united(s->geometry());
        }
        setGeometry(desktopRect);

        m_displayText = QStringLiteral("拖动选择要镜像的区域");
    }

signals:
    void selectionFinished(const QRect &rect);

protected:
    void paintEvent(QPaintEvent *) override
    {
        QPainter p(this);
        p.setRenderHint(QPainter::Antialiasing, true);

        p.fillRect(rect(), QColor(0, 0, 0, 160));

        if (m_dragging || !m_selectedRect.isNull()) {
            QRect r = currentRect();

            p.setCompositionMode(QPainter::CompositionMode_Clear);
            p.fillRect(r, Qt::transparent);

            p.setCompositionMode(QPainter::CompositionMode_SourceOver);
            QPen pen(Qt::white);
            pen.setWidth(2);
            p.setPen(pen);
            p.setBrush(Qt::NoBrush);
            p.drawRect(r.adjusted(1, 1, -1, -1));
        }

        p.setPen(Qt::white);
        QFont f = p.font();
        f.setPointSize(16);
        p.setFont(f);
        p.drawText(rect(), Qt::AlignCenter, m_displayText);
    }

    void mousePressEvent(QMouseEvent *e) override
    {
        if (e->button() != Qt::LeftButton)
            return;
        m_dragging = true;
        m_beginPos = e->globalPosition().toPoint();
        m_endPos = m_beginPos;
        update();
    }

    void mouseMoveEvent(QMouseEvent *e) override
    {
        if (!m_dragging)
            return;
        m_endPos = e->globalPosition().toPoint();
        update();
    }

    void mouseReleaseEvent(QMouseEvent *e) override
    {
        if (!m_dragging || e->button() != Qt::LeftButton)
            return;
        m_dragging = false;
        m_endPos = e->globalPosition().toPoint();

        QRect r = currentRect();
        m_selectedRect = r;
        emit selectionFinished(r);
        close();
    }

private:
    QRect currentRect() const
    {
        QPoint p1 = m_beginPos;
        QPoint p2 = m_endPos;
        return QRect(p1, p2).normalized();
    }

    bool   m_dragging{false};
    QPoint m_beginPos;
    QPoint m_endPos;
    QRect  m_selectedRect;
    QString m_displayText;
};

// 原区域外侧的虚线边框，仅视觉提示，不拦截点击
class BorderOverlay : public QWidget
{
    Q_OBJECT
public:
    explicit BorderOverlay(const QRect &rect, QWidget *parent = nullptr)
        : QWidget(parent)
    {
        setWindowFlag(Qt::FramelessWindowHint);
        setWindowFlag(Qt::Tool);
        setWindowFlag(Qt::WindowStaysOnTopHint);
        setAttribute(Qt::WA_TranslucentBackground);
        setAttribute(Qt::WA_TransparentForMouseEvents);
        setAttribute(Qt::WA_DeleteOnClose);

        const int margin = 4;
        setGeometry(rect.adjusted(-margin, -margin, margin, margin));
    }

signals:
    void doubleClicked();

protected:
    void paintEvent(QPaintEvent *) override
    {
        QPainter p(this);
        p.setRenderHint(QPainter::Antialiasing, true);

        QPen pen(QColor(255, 255, 255, 230));
        pen.setStyle(Qt::DashLine);
        pen.setWidth(1);
        p.setPen(pen);
        p.setBrush(Qt::NoBrush);
        p.drawRect(rect().adjusted(1, 1, -1, -1));
    }

    void mouseDoubleClickEvent(QMouseEvent *e) override
    {
        if (e->button() == Qt::LeftButton)
            emit doubleClicked();
    }
};

// 镜像窗口
class MirrorWindow : public QWidget
{
    Q_OBJECT
public:
    explicit MirrorWindow(QWidget *parent = nullptr)
        : QWidget(parent)
    {
        setWindowFlag(Qt::FramelessWindowHint);
        setWindowFlag(Qt::Tool);
        setWindowFlag(Qt::WindowStaysOnTopHint);
        setAttribute(Qt::WA_TranslucentBackground);
        setAttribute(Qt::WA_DeleteOnClose);
        setAttribute(Qt::WA_AcceptTouchEvents);   // 接收触摸事件，确保能识别捏合手势
        setMouseTracking(true);

        grabGesture(Qt::PinchGesture);

        // 默认稍微有点不透明背景，方便看边框
        m_backgroundColor = QColor(0, 0, 0, 0);
    }

    // 在创建后由外部调用，设置虚拟桌面矩形和初始内容区域
    void initGeometry(const QRect &desktopRect, const QRect &mirrorRect)
    {
        m_desktopRect = desktopRect;
        // MirrorWindow 本身会被设置成 desktopRect 的几何
        // 基准尺寸仍然是原框选区域大小
        const QRect baseRect(mirrorRect.topLeft() - desktopRect.topLeft(), mirrorRect.size());
        m_baseSize = baseRect.size();
        m_hasBaseSize = m_baseSize.isValid();

        // 初始时整体放大一点，方便和原区域区分（例如 1.15 倍）
        m_currentScale = 1.15;
        QSizeF scaledSizeF = QSizeF(m_baseSize) * m_currentScale;
        QSize scaledSize = scaledSizeF.toSize();

        // 以原框选区域中心为基准向四周放大
        const QPoint center = baseRect.center();
        QRect scaledRect(QPoint(0, 0), scaledSize);
        scaledRect.moveCenter(center);

        m_contentRect = scaledRect;
        update();
    }

    void setSourcePixmap(const QPixmap &pm)
    {
        m_sourcePixmap = pm;
        update();
    }

    const QRect& getCurrContentRect() const {
        return m_contentRect;
    }

    void setIsFromSave(bool isFromSave) {
        this->isFromSave = isFromSave;
    }

signals:
    void singleClicked();
    void doubleClicked();
    void closeButtonClicked();
    void saveButtonClicked();

protected:
    // 让内容区域外的鼠标事件直接 OS 级穿透
    bool nativeEvent(const QByteArray &eventType, void *message, qintptr *result) override
    {
#if defined(Q_OS_WIN)
        if (eventType == "windows_generic_MSG" || eventType == "windows_dispatcher_MSG") {
            MSG *msg = static_cast<MSG *>(message);
            if (msg->message == WM_NCHITTEST) {
                Q_UNUSED(msg);
                const QPoint globalPos = QCursor::pos();
                const QPoint localPos = mapFromGlobal(globalPos);
                if (!m_contentRect.contains(localPos)) {
                    *result = HTTRANSPARENT;
                    return true;
                }
            }
        }
#endif
        return QWidget::nativeEvent(eventType, message, result);
    }

    bool event(QEvent *e) override
    {
        if (e->type() == QEvent::Gesture) {
            auto *ge = static_cast<QGestureEvent *>(e);
            if (QGesture *g = ge->gesture(Qt::PinchGesture)) {
                handlePinch(static_cast<QPinchGesture *>(g));
                return true;
            }
        }
        return QWidget::event(e);
    }

    void paintEvent(QPaintEvent *) override
    {
        QPainter p(this);
        p.setRenderHint(QPainter::Antialiasing, true);
        p.setRenderHint(QPainter::SmoothPixmapTransform, true); // 提升缩放后的图像清晰度

        if (m_backgroundColor.alpha() > 0)
            p.fillRect(rect(), m_backgroundColor);

        if (!m_sourcePixmap.isNull()) {
            // 只在内容矩形内绘制，避免拉伸到全屏
            if (!m_contentRect.isNull()) {
                p.drawPixmap(m_contentRect, m_sourcePixmap);
            }
        }

        QPen pen(QColor(66, 66, 66, 60));
        pen.setWidth(1);
        p.setPen(pen);
        p.setBrush(Qt::NoBrush);
        if (!m_contentRect.isNull())
            p.drawRect(m_contentRect.adjusted(-1, -1, 1, 1));

        if (m_showFrame) {
            // 外边框
            QPen pen(QColor(255, 255, 255, 220));
            pen.setWidth(2);
            p.setPen(pen);
            p.setBrush(Qt::NoBrush);
            if (!m_contentRect.isNull())
                p.drawRect(m_contentRect.adjusted(-2, -2, 2, 2));

            // 内容区域中间的按钮
            const int radius = 18;
            const QRect targetRect = m_contentRect.isNull() ? rect() : m_contentRect;
            const QSize buttonSize(radius * 2, radius * 2);
            const int spacing = 24;

            const int totalWidth = buttonSize.width() * 2 + spacing;
            const int baseX = targetRect.center().x() - totalWidth / 2;
            const int baseY = targetRect.center().y() - buttonSize.height() / 2;

            m_closeButtonRect = QRect(QPoint(baseX, baseY), buttonSize);
            m_saveButtonRect  = QRect(QPoint(baseX + buttonSize.width() + spacing, baseY), buttonSize);

            // 关闭按钮背景
            p.setBrush(QColor(255, 255, 255, 150));
            p.setPen(Qt::NoPen);
            p.drawEllipse(m_closeButtonRect);
            // 保存按钮背景
            p.drawEllipse(m_saveButtonRect);

            // 按钮灰色描边
            QPen btnBorderPen(QColor(180, 180, 180));
            btnBorderPen.setWidth(1);
            p.setPen(btnBorderPen);
            p.setBrush(Qt::NoBrush);
            p.drawEllipse(m_closeButtonRect.adjusted(0, 0, -1, -1));
            p.drawEllipse(m_saveButtonRect.adjusted(0, 0, -1, -1));

            // 关闭图标
            if (!m_closeIcon.isNull()) {
                const QRect iconRect = m_closeButtonRect.adjusted(8, 8, -8, -8);
                p.drawPixmap(iconRect, m_closeIcon);
            }

            // 保存图标或删除图标
            if (!isFromSave) {
                if (!m_saveIcon.isNull()) {
                    const QRect iconRect = m_saveButtonRect.adjusted(8, 8, -8, -8);
                    p.drawPixmap(iconRect, m_saveIcon);
                }
            } else {
                if (!m_deleteIcon.isNull()) {
                    const QRect iconRect = m_saveButtonRect.adjusted(8, 8, -8, -8);
                    p.drawPixmap(iconRect, m_deleteIcon);
                }
            }
        }
    }

    void mousePressEvent(QMouseEvent *e) override
    {
        // 正在进行捏合手势时忽略拖动
        if (m_gestureActive) {
            e->ignore();
            return;
        }

        if (e->button() == Qt::LeftButton) {
            const QPoint localPos = e->position().toPoint();
            if (m_contentRect.contains(localPos)) {
                m_dragging = true;
                m_dragStartPos = localPos;
                m_contentStartRect = m_contentRect;
            }
        }
        QWidget::mousePressEvent(e);
    }

    void mouseMoveEvent(QMouseEvent *e) override
    {
        if (m_gestureActive) {
            // 手势进行中不做拖动处理，仅交给基类
            m_dragging = false;
            QWidget::mouseMoveEvent(e);
            return;
        }

        if (m_dragging) {
            const QPoint localPos = e->position().toPoint();
            const QPoint delta = localPos - m_dragStartPos;
            m_contentRect = m_contentStartRect.translated(delta);
            update();
        }
        QWidget::mouseMoveEvent(e);
    }

    void mouseReleaseEvent(QMouseEvent *e) override
    {
        if (m_gestureActive) {
            m_dragging = false;
            QWidget::mouseReleaseEvent(e);
            return;
        }

        if (e->button() == Qt::LeftButton) {
            const QPoint localPos = e->position().toPoint();
            if (m_dragging && (m_dragStartPos - localPos).manhattanLength() < 4) {
                // 认为是单击
                if (m_closeButtonRect.contains(localPos)) {
                    emit closeButtonClicked();
                } else if (m_saveButtonRect.contains(localPos)) {
                    emit saveButtonClicked();
                } else {
                    m_showFrame = !m_showFrame;
                    update();
                    emit singleClicked();
                }
            }
            m_dragging = false;
        }
        QWidget::mouseReleaseEvent(e);
    }

    void mouseDoubleClickEvent(QMouseEvent *e) override
    {
        if (e->button() == Qt::LeftButton) {
            const QPoint pos = e->position().toPoint();
            if (m_showFrame && m_contentRect.contains(pos)) {
                emit doubleClicked();
            }
        }
        QWidget::mouseDoubleClickEvent(e);
    }

private:
    void handlePinch(QPinchGesture *g)
    {
        if (!m_hasBaseSize)
            return;

        // 手势开始时记录基准状态，只用一次
        if (g->state() == Qt::GestureStarted) {
            m_gestureActive = true;
            m_dragging = false;
            m_pinchActive = true;
            m_pinchStartRect = m_contentRect;

            // 基准缩放 = 当前内容宽度 / 基准宽度（防止多次手势之间累计误差）
            m_pinchStartScale =
                    (m_baseSize.width() > 0)
                        ? qreal(m_contentRect.width()) / qreal(m_baseSize.width())
                        : m_currentScale;

            m_pinchStartCenter = g->centerPoint();
        }
        else if (g->state() == Qt::GestureFinished || g->state() == Qt::GestureCanceled) {
            m_pinchActive = false;
            m_gestureActive = false;
            return;
        }

        if (!m_pinchActive)
            return;

        // 只处理缩放变化，其它（旋转等）暂不支持
        if (!(g->changeFlags() & QPinchGesture::ScaleFactorChanged))
            return;

        // totalScaleFactor 是“从手势开始到现在”的总缩放倍数
        const qreal totalFactor = g->totalScaleFactor();
        if (totalFactor <= 0.0)
            return;

        qreal targetScale = m_pinchStartScale * totalFactor;
        targetScale = qBound(0.3, targetScale, 10.0); // 全局限制缩放范围

        const qreal realStep = (m_pinchStartScale > 0.0) ? (targetScale / m_pinchStartScale) : 1.0;
        if (realStep <= 0.0 || qFuzzyCompare(realStep, 1.0))
            return;

        m_currentScale = targetScale;

        QPointF pivot = m_pinchStartCenter;
        if (!m_pinchStartRect.contains(pivot.toPoint())) {
            // 起始中心点在内容外（极少见），退化为以起始内容中心缩放
            pivot = m_pinchStartRect.isNull()
                        ? QPointF(rect().center())
                        : QPointF(m_pinchStartRect.center());
        }

        const QPointF oldTopLeft = m_pinchStartRect.topLeft();
        const QSizeF oldSize = m_pinchStartRect.size();

        const QPointF vecTL = oldTopLeft - pivot;
        const QSizeF newSize = oldSize * realStep;
        const QPointF newTopLeft = pivot + vecTL * realStep;

        QRect newRect(newTopLeft.toPoint(), newSize.toSize());

        // 过小则认为无效，防止意外缩到看不见
        if (newRect.width() < 40 || newRect.height() < 40)
            return;

        m_contentRect = newRect;

        update();
    }

    // 虚拟桌面矩形（用于定位初始内容区域）
    QRect  m_desktopRect;
    // 当前内容绘制区域（窗口局部坐标）
    QRect  m_contentRect;

    QPixmap m_sourcePixmap;
    QColor  m_backgroundColor;

    bool    m_dragging{false};
    QPoint  m_dragStartPos;
    QPoint  m_windowStartPos;

    bool    m_showFrame{false};
    QRect   m_closeButtonRect;
    QRect   m_saveButtonRect;

    bool    m_hasBaseSize{false};
    QSize   m_baseSize;
    qreal   m_currentScale{1.0};

    // 拖动相关
    QRect   m_contentStartRect;

    // 捏合缩放相关
    bool    m_pinchActive{false};
    bool    m_gestureActive{false};
    QRect   m_pinchStartRect;
    qreal   m_pinchStartScale{1.0};
    QPointF m_pinchStartCenter;

    QPixmap m_closeIcon{QStringLiteral(":/icon/close_2.svg")};
    QPixmap m_saveIcon{QStringLiteral(":/icon/save.svg")};
    QPixmap m_deleteIcon{QStringLiteral(":/icon/delete.svg")};

    int isFromSave{false};
};

// ============ ScreenMovement 实现 ============

ScreenMovement::ScreenMovement(QObject *parent)
    : QObject(parent)
    , m_maskOverlay(nullptr)
    , m_borderOverlay(nullptr)
    , m_mirrorWindow(nullptr)
    , m_captureTimer(nullptr)
{
}

ScreenMovement::~ScreenMovement()
{
    stopAll();
}

void ScreenMovement::start(const QVariant &sourceRect, const QVariant &mirrorRect, int saveId)
{
    this->saveId = saveId;
    stopAll();
    qDebug() << "ScreenMoveStarted:" << sourceRect.toRect() << mirrorRect.toRect();
    if (sourceRect.isValid() && mirrorRect.isValid()) {
        beginMirrorMode(sourceRect.toRect(), mirrorRect.toRect());
    } else if (sourceRect.isValid()) {
        beginMirrorMode(sourceRect.toRect(), sourceRect.toRect());
    } else {
        beginSelectMode();
    }
}

bool ScreenMovement::isStarted()
{
    return m_borderOverlay && m_mirrorWindow;
}

void ScreenMovement::allWindowsToTop()
{
    if (m_borderOverlay)
        SetWindowPos((HWND)m_borderOverlay->winId(), HWND_TOP, 0,0,0,0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE | SWP_NOSENDCHANGING);
    if (m_mirrorWindow)
        SetWindowPos((HWND)m_mirrorWindow->winId(), HWND_TOP, 0,0,0,0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE | SWP_NOSENDCHANGING);
    if (m_maskOverlay)
        SetWindowPos((HWND)m_maskOverlay->winId(), HWND_TOP, 0,0,0,0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE | SWP_NOSENDCHANGING);
}

void ScreenMovement::beginSelectMode()
{
    auto *overlay = new MaskSelectOverlay;
    m_maskOverlay = overlay;

    connect(overlay, &MaskSelectOverlay::selectionFinished, this, [this](const QRect &rect) {
        m_maskOverlay = nullptr;
        if (!rect.isNull() && rect.width() > 10 && rect.height() > 10) {
            beginMirrorMode(rect, rect);
            emit selectionFinished(rect);
        } else {
            emit closeRequested();
        }
    });

    overlay->showFullScreen();
    overlay->raise();
}

void ScreenMovement::beginMirrorMode(const QRect &sourceRect, const QRect &mirrorRect)
{
    m_sourceRect = sourceRect;

    // 计算虚拟桌面矩形，用于创建全屏镜像窗口
    QRect desktopRect;
    const auto screens = QGuiApplication::screens();
    for (QScreen *s : screens) {
        desktopRect = desktopRect.united(s->geometry());
    }

    // 原区域上的虚线边框
    m_borderOverlay = new BorderOverlay(sourceRect);
    m_borderOverlay->show();
    m_borderOverlay->raise();

    // 镜像窗口
    auto *mirror = new MirrorWindow;
    m_mirrorWindow = mirror;

    mirror->setIsFromSave(saveId >= 0);

    // 镜像窗口全屏覆盖虚拟桌面，仅在内容区域绘制/响应
    mirror->setGeometry(desktopRect);
    mirror->initGeometry(desktopRect, mirrorRect);

    connect(mirror, &MirrorWindow::closeButtonClicked, this, [this]() {
        emit closeRequested();
        stopAll();
    });
    connect(mirror, &MirrorWindow::saveButtonClicked, this, [=]() {
        if (saveId >= 0) {
            emit deleteRequested(saveId);
        } else {
            emit saveRequested(QVariant(m_sourceRect), QVariant(mirror->getCurrContentRect()));
        }
    });
    connect(mirror, &MirrorWindow::destroyed, this, [this]() {
        emit closeRequested();
        stopAll();
    });

    mirror->show();
    mirror->raise();

    // 把镜像窗口标记为“从屏幕捕获中排除”，实现视觉层面的“穿透” (Win10+)
    HWND hwnd = reinterpret_cast<HWND>(mirror->winId());
    if (hwnd) {
        SetWindowDisplayAffinity(hwnd, WDA_EXCLUDEFROMCAPTURE);
    }

    setupMirrorCapture();
}

void ScreenMovement::setupMirrorCapture()
{
    if (!m_mirrorWindow)
        return;

    if (!m_captureTimer) {
        m_captureTimer = new QTimer(this);
        connect(m_captureTimer, &QTimer::timeout, this, [this]() {
            if (!m_mirrorWindow)
                return;

            QScreen *screen = QGuiApplication::primaryScreen();
            if (!screen)
                return;

            QPixmap pm = screen->grabWindow(0,
                                            m_sourceRect.x(),
                                            m_sourceRect.y(),
                                            m_sourceRect.width(),
                                            m_sourceRect.height());

            auto *mirror = qobject_cast<MirrorWindow *>(m_mirrorWindow);
            if (mirror)
                mirror->setSourcePixmap(pm);
        });
    }

    m_captureTimer->start(33); // ~30fps
}

void ScreenMovement::stopMirrorCapture()
{
    if (m_captureTimer) {
        m_captureTimer->stop();
    }
}

void ScreenMovement::stopAll()
{
    stopMirrorCapture();

    if (m_maskOverlay) {
        m_maskOverlay->close();
        m_maskOverlay = nullptr;
    }
    if (m_borderOverlay) {
        m_borderOverlay->close();
        m_borderOverlay = nullptr;
    }
    if (m_mirrorWindow) {
        m_mirrorWindow->close();
        m_mirrorWindow = nullptr;
    }
}

#include "screenmovement.moc"

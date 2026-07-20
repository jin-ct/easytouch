#ifndef SCREENMOVEMENT_H
#define SCREENMOVEMENT_H

#include <QObject>
#include <QRect>
#include <QVariant>

class QWidget;
class QTimer;

class ScreenMovement : public QObject
{
    Q_OBJECT
public:
    explicit ScreenMovement(QObject *parent = nullptr);
    ~ScreenMovement() override;

    // 在调用 start 后才开始显示遮罩或镜像
    // 若 x,y,w,h 全部为 0 或负数，则进入遮罩框选模式
    // 否则直接以传入矩形作为镜像区域，跳过遮罩框选
    Q_INVOKABLE void start(const QVariant &sourceRect = QVariant(), const QVariant &mirrorRect = QVariant(), int saveId = -1);
    Q_INVOKABLE bool isStarted();
    Q_INVOKABLE void allWindowsToTop();
    Q_INVOKABLE void stopAll();

signals:
    // 用户完成框选后发出，rect 为屏幕坐标
    void selectionFinished(const QVariant &rect);

    void closeRequested();
    void saveRequested(const QVariant &sourceRect, const QVariant &mirrorRect);
    void deleteRequested(int saveId = -1);

private:
    void beginSelectMode();
    void beginMirrorMode(const QRect &sourceRect, const QRect &mirrorRect);

    void setupMirrorCapture();
    void stopMirrorCapture();

    QRect m_sourceRect;      // 原始镜像区域（屏幕坐标）
    QWidget *m_maskOverlay;  // 全屏黑色半透明遮罩 + 拉框
    QWidget *m_borderOverlay;// 覆盖在原区域上的虚线边框窗口
    QWidget *m_mirrorWindow; // 镜像窗口
    QTimer  *m_captureTimer; // 定时抓屏

    int saveId{-1};  // 若为从保存的位置记录进入镜像模式则 saveId >= 0
};

#endif // SCREENMOVEMENT_H

#ifndef SCREENMOVEMENT_H
#define SCREENMOVEMENT_H

#include <QObject>
#include <QRect>

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
    Q_INVOKABLE void start(int x = -1, int y = -1, int w = -1, int h = -1);

signals:
    // 用户完成框选后发出，rect 为屏幕坐标
    void selectionFinished(const QRect &rect);

    // 双击虚线区域或镜像窗口时发出
    void closeRequested();

private:
    void beginSelectMode();
    void beginMirrorMode(const QRect &rect);
    void stopAll();

    void setupMirrorCapture();
    void stopMirrorCapture();

    QRect m_sourceRect;      // 原始镜像区域（屏幕坐标）
    QWidget *m_maskOverlay;  // 全屏黑色半透明遮罩 + 拉框
    QWidget *m_borderOverlay;// 覆盖在原区域上的虚线边框窗口
    QWidget *m_mirrorWindow; // 镜像窗口
    QTimer  *m_captureTimer; // 定时抓屏
};

#endif // SCREENMOVEMENT_H

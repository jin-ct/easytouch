import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic
import QtQuick.Window
import FluentUI
import Functions

FluIconButton {
    id:control
    property var current : []
    property var currentVals : []
    property string title: qsTr("按键采集")
    property string message: qsTr("请在键盘上输入按键")
    property string positiveText: qsTr("确定")
    property string neutralText: qsTr("清空")
    property string negativeText: qsTr("取消")
    property color errorColor: Qt.rgba(250/255,85/255,85/255,1)
    signal accepted()
    padding: 0
    verticalPadding: 0
    horizontalPadding: 0
    text: ""
    color: {
        if(!enabled){
            return disableColor
        }
        if(pressed){
            return pressedColor
        }
        return hovered ? hoverColor : normalColor
    }
    onCurrentValsChanged: control.keyValsToString()
    QtObject{
        id: d
        function keyToString(key_code,shift = true)
        {
            switch(key_code)
            {
            case Qt.Key_Period:       return ".";
            case Qt.Key_Greater:      return shift ? ">" : ".";
            case Qt.Key_Comma:        return ",";
            case Qt.Key_Less:         return shift ? "<" : ",";
            case Qt.Key_Slash:        return "/";
            case Qt.Key_Question:     return shift ? "?" : "/";
            case Qt.Key_Semicolon:    return ";";
            case Qt.Key_Colon:        return shift ? ":" : ";";
            case Qt.Key_Apostrophe:   return "'";
            case Qt.Key_QuoteDbl:     return shift ? "'" : "\"";
            case Qt.Key_QuoteLeft:    return "`";
            case Qt.Key_AsciiTilde:   return shift ? "~" : "`";
            case Qt.Key_Minus:        return "-";
            case Qt.Key_Underscore:   return shift ? "_" : "-";
            case Qt.Key_Equal:        return "=";
            case Qt.Key_Plus:         return shift ? "+" : "=";
            case Qt.Key_BracketLeft:  return "[";
            case Qt.Key_BraceLeft:    return shift ? "{" : "[";
            case Qt.Key_BracketRight: return "]";
            case Qt.Key_BraceRight:   return shift ? "}" : "]";
            case Qt.Key_Backslash:    return "\\";
            case Qt.Key_Bar:          return shift ? "|" : "\\";
            case Qt.Key_Up:           return "Up";
            case Qt.Key_Down:         return "Down";
            case Qt.Key_Right:        return "Right";
            case Qt.Key_Left:         return "Left";
            case Qt.Key_Space:        return "Space";
            case Qt.Key_PageDown:     return "PgDown";
            case Qt.Key_PageUp:       return "PgUp";
            case Qt.Key_0:            return "0";
            case Qt.Key_1:            return "1";
            case Qt.Key_2:            return "2";
            case Qt.Key_3:            return "3";
            case Qt.Key_4:            return "4";
            case Qt.Key_5:            return "5";
            case Qt.Key_6:            return "6";
            case Qt.Key_7:            return "7";
            case Qt.Key_8:            return "8";
            case Qt.Key_9:            return "9";
            case Qt.Key_Exclam:       return shift ? "!" : "1";
            case Qt.Key_At:           return shift ? "@" : "2";
            case Qt.Key_NumberSign:   return shift ? "#" : "3";
            case Qt.Key_Dollar:       return shift ? "$" : "4";
            case Qt.Key_Percent:      return shift ? "%" : "5";
            case Qt.Key_AsciiCircum:  return shift ? "^" : "6";
            case Qt.Key_Ampersand:    return shift ? "&" : "7";
            case Qt.Key_Asterisk:     return shift ? "*" : "8";
            case Qt.Key_ParenLeft:    return shift ? "(" : "9";
            case Qt.Key_ParenRight:   return shift ? ")" : "0";
            case Qt.Key_A:            return "A";
            case Qt.Key_B:            return "B";
            case Qt.Key_C:            return "C";
            case Qt.Key_D:            return "D";
            case Qt.Key_E:            return "E";
            case Qt.Key_F:            return "F";
            case Qt.Key_G:            return "G";
            case Qt.Key_H:            return "H";
            case Qt.Key_I:            return "I";
            case Qt.Key_J:            return "J";
            case Qt.Key_K:            return "K";
            case Qt.Key_L:            return "L";
            case Qt.Key_M:            return "M";
            case Qt.Key_N:            return "N";
            case Qt.Key_O:            return "O";
            case Qt.Key_P:            return "P";
            case Qt.Key_Q:            return "Q";
            case Qt.Key_R:            return "R";
            case Qt.Key_S:            return "S";
            case Qt.Key_T:            return "T";
            case Qt.Key_U:            return "U";
            case Qt.Key_V:            return "V";
            case Qt.Key_W:            return "W";
            case Qt.Key_X:            return "X";
            case Qt.Key_Y:            return "Y";
            case Qt.Key_Z:            return "Z";
            case Qt.Key_F1:           return "F1";
            case Qt.Key_F2:           return "F2";
            case Qt.Key_F3:           return "F3";
            case Qt.Key_F4:           return "F4";
            case Qt.Key_F5:           return "F5";
            case Qt.Key_F6:           return "F6";
            case Qt.Key_F7:           return "F7";
            case Qt.Key_F8:           return "F8";
            case Qt.Key_F9:           return "F9";
            case Qt.Key_F10:          return "F10";
            case Qt.Key_F11:          return "F11";
            case Qt.Key_F12:          return "F12";
            case Qt.Key_Home:         return "Home";
            case Qt.Key_End:          return "End";
            case Qt.Key_Insert:       return "Insert";
            case Qt.Key_Delete:       return "Delete";
            case Qt.Key_Escape:       return "Esc";
            case Qt.Key_Enter:        return "Enter";
            case Qt.Key_Return:       return "Enter";
            case Qt.Key_Backspace:    return "Backspace";
            case Qt.Key_Context2:     return "Context";
            case Qt.Key_Tab:          return "Tab";
            case Qt.Key_Meta:         return "Win";
            case Qt.Key_Control:      return "Ctrl";
            case Qt.Key_Shift:        return "Shift";
            case Qt.Key_Alt:          return "Alt";
            }
            return "";
        }
    }
    function keyValsToString() {
        current = []
        currentVals.forEach(function(val) {
            let keyName = d.keyToString(val)
            if(keyName !== "")
                current.push(keyName)
        })
        current = current
    }
    background: Item{
        implicitHeight: 42
        implicitWidth: 42
    }
    contentItem: Item{
        implicitWidth: childrenRect.width
        implicitHeight: layout_row.height

        FluText{
            id: text_title
            text: control.text
            visible: control.text !== ""
            rightPadding: 8
            anchors{
                verticalCenter: layout_rect.verticalCenter
            }
        }

        Rectangle{
            id: layout_rect
            border.color: FluTheme.dark ? "#505050" : "#DFDFDF"
            border.width: 1
            radius: control.radius
            color: control.color
            height: control.height
            width: layout_row.width
            anchors{
                left: text_title.right
            }
            FluFocusRectangle{
                visible: control.activeFocus
            }
            Row{
                id:layout_row
                spacing: 5
                anchors.centerIn: parent
                Item{
                    width: 8
                    height: 1
                }
                Repeater{
                    model: control.current
                    delegate: Loader{
                        property var keyText: modelData
                        sourceComponent: com_item_key
                    }
                }
                Item{
                    width: 3
                    height: 1
                }
                FluIcon{
                    iconSource: FluentIcons.EditMirrored
                    iconSize: 13
                    anchors{
                        verticalCenter: parent.verticalCenter
                    }
                }
                Item{
                    width: 8
                    height: 1
                }
            }
        }
    }
    Component{
        id:com_item_key
        Rectangle{
            id:item_key_control
            color:FluTheme.primaryColor
            width: Math.max(item_text.implicitWidth+12,28)
            height: Math.max(item_text.implicitHeight,28)
            radius: 4
            FluText{
                id:item_text
                color: FluTheme.dark ? Qt.rgba(0,0,0,1)  : Qt.rgba(1,1,1,1)
                text: keyText
                anchors.centerIn: parent
            }
        }
    }
    FluContentDialog{
        id:content_dialog
        property var keysModel: []
        property var keyVals: []
        title: control.title
        buttonFlags: FluContentDialogType.NegativeButton | FluContentDialogType.PositiveButton | FluContentDialogType.NeutralButton
        positiveText: control.positiveText
        neutralText: control.neutralText
        negativeText: control.negativeText
        onVisibleChanged: {
            if(visible){
                control.keyValsToString()
                content_dialog.keysModel = control.current
            }
        }
        onPositiveClicked: {
            control.current = content_dialog.keysModel
            control.currentVals = content_dialog.keyVals
            control.accepted()
        }
        onNeutralClickListener: function() {
            content_dialog.keysModel = []
            content_dialog.keyVals = []
        }
        contentDelegate: Component{
            Item{
                implicitWidth: parent.width
                implicitHeight: 100
                Component.onCompleted: {
                    forceActiveFocus()
                }
                Keys.enabled: true
                Keys.onPressed:
                    (event)=>{
                        var keyName = d.keyToString(event.key,false)
                        if(keyName!=="" && content_dialog.keysModel.indexOf(keyName) === -1){
                            content_dialog.keyVals.push(event.key)
                            content_dialog.keysModel.push(keyName)
                        }
                        content_dialog.keysModel = content_dialog.keysModel
                    }
                Keys.onTabPressed:
                    (event)=>{
                        if(content_dialog.keysModel.indexOf("Tab") === -1){
                            content_dialog.keyVals.push(Qt.Key_Tab)
                            content_dialog.keysModel.push("Tab")
                            content_dialog.keysModel = content_dialog.keysModel
                        }
                        event.accepted = true
                    }
                Column {
                    spacing: 10
                    width: parent.width
                    Row {
                        spacing: 5
                        FluText {
                            id: messageText
                            text: control.message
                            leftPadding: 20
                        }
                        FluTextButton {
                            text: qsTr("打开屏幕键盘")
                            implicitHeight: messageText.implicitHeight
                            onClicked: {
                                Qt.openUrlExternally("C:/WINDOWS/system32/osk.exe")
                            }
                        }
                    }
                    Row {
                        spacing: 5
                        anchors.horizontalCenter: parent.horizontalCenter
                        topPadding: 12
                        Repeater{
                            model: content_dialog.keysModel
                            delegate: Loader{
                                property var keyText: modelData
                                sourceComponent: com_item_key
                            }
                        }
                    }
                }
            }
        }
    }
    onClicked: {
        content_dialog.open()
    }
}

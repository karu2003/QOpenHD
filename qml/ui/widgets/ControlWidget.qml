import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: controlWidget
    width: 100
    height: 100

    visible: settings.show_control

    widgetIdentifier: "control_widget"
    bw_verbose_name: "CONTROL INPUTS"

    defaultAlignment: 1
    defaultXOffset: 20
    defaultYOffset: 50
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: true

    property int m_control_yaw : 0
    property int m_control_roll: 0
    property int m_control_pitch: 0
    property int m_control_throttle: 0


    widgetDetailComponent: ScrollView {

        contentHeight: idBaseWidgetDefaultUiControlElements.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        BaseWidgetDefaultUiControlElements{
            id: idBaseWidgetDefaultUiControlElements
            Item {
                width: 240
                height: 32
                Text {
                    id: displaySwitcher
                    text: qsTr("Show two controls")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 6
                    anchors.right: parent.right
                    checked: settings.double_control
                    onCheckedChanged: settings.double_control = checked
                }
            }
            Item {
                width: 240
                height: 32
                Text {
                    text: qsTr("Reverse Pitch")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 6
                    anchors.right: parent.right
                    checked: settings.control_rev_pitch
                    onCheckedChanged: settings.control_rev_pitch = checked
                }
            }
            Item {
                width: 240
                height: 32
                Text {
                    text: qsTr("Reverse Roll")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 6
                    anchors.right: parent.right
                    checked: settings.control_rev_roll
                    onCheckedChanged: settings.control_rev_roll = checked
                }
            }
            Item {
                width: 240
                height: 32
                Text {
                    text: qsTr("Reverse yaw")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 6
                    anchors.right: parent.right
                    checked: settings.control_rev_yaw
                    onCheckedChanged: settings.control_rev_yaw = checked
                }
            }
            Item {
                width: 240
                height: 32
                Text {
                    text: qsTr("Reverse Throttle")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 6
                    anchors.right: parent.right
                    checked: settings.control_rev_throttle
                    onCheckedChanged: settings.control_rev_throttle = checked
                }
            }
        }
    }

    Item {
        id: widgetInner
        height: parent.height
        width: parent.width
        anchors.verticalCenter: parent.verticalCenter
        opacity: bw_current_opacity
        scale: bw_current_scale

        antialiasing: true


        /*------------------------------ Single Circle Version start------------------
        this could all be simplified and condensed with either or type of logic. However
        might add a 3rd type of display version then the either or logic would have to
        be undone...
*/
        Item {
            id: singleCircle
            height: parent.height
            width: parent.width
            anchors.verticalCenter: parent.verticalCenter

            visible: !settings.double_control

            Rectangle {
                id: circleGlow
                anchors.centerIn: circle
                width: (parent.width < parent.height ? parent.width : parent.height) + 2
                height: width
                color: "transparent"
                radius: width * 0.5

                border.color: settings.color_glow
                border.width: 3
            }

            Rectangle {
                id: circle
                anchors.centerIn: singleCircle
                width: parent.width < parent.height ? parent.width : parent.height
                height: width
                color: "transparent"
                radius: width * 0.5

                border.color: settings.color_shape
                border.width: 1
            }

            Rectangle {
                id: left_control
                anchors.centerIn: singleCircle
                width: (parent.width < parent.height ? parent.width : parent.height) * .1
                height: width
                color: settings.color_text

                //radius: width*0.5
                border.color: settings.color_glow
                border.width: 1

                visible: m_control_throttle < 1000 ? false : true

                transformOrigin: Item.Center

                transform: Translate {
                    x: settings.control_rev_yaw ? ((m_control_yaw - 1500) / 10)
                                                  * -1 : (m_control_yaw - 1500) / 10
                    y: settings.control_rev_throttle ? ((m_control_throttle - 2000) / 10)
                                                       + 50 : ((m_control_throttle - 2000)
                                                               / 10) * -1 - 50
                }
            }

            Rectangle {
                id: right_control
                anchors.centerIn: singleCircle
                width: (parent.width < parent.height ? parent.width : parent.height) * .1
                height: width
                color: settings.color_text
                radius: width * 0.5

                border.color: settings.color_glow
                border.width: 1

                visible: m_control_throttle < 1000 ? false : true

                transformOrigin: Item.Center

                transform: Translate {
                    x: settings.control_rev_roll ? ((m_control_roll - 1500)
                                                    / 10) * -1 : (m_control_roll - 1500) / 10
                    y: settings.control_rev_pitch ? ((m_control_pitch - 1500) / 10)
                                                    * -1 : (m_control_pitch - 1500) / 10
                }
            }
        }

        //------------------------------ Double Circle Version start------------------
        Item {
            id: doubleCircle
            height: parent.height
            width: parent.width
            anchors.verticalCenter: parent.verticalCenter

            visible: settings.double_control

            Rectangle {
                id: leftCircleGlow

                anchors.centerIn: leftCircle
                width: ((parent.width < parent.height ? parent.width : parent.height) / 2) + 2
                height: width
                color: "transparent"
                radius: width * 0.5

                border.color: settings.color_glow
                border.width: 3
            }

            Rectangle {
                id: leftCircle

                //    anchors.right: rightCircle.left
                width: (parent.width < parent.height ? parent.width : parent.height) / 2
                height: width
                color: "transparent"
                radius: width * 0.5

                border.color: settings.color_shape
                border.width: 1
            }

            Rectangle {
                id: rightCircleGlow

                anchors.centerIn: rightCircle
                width: ((parent.width < parent.height ? parent.width : parent.height) / 2) + 2
                height: width
                color: "transparent"
                radius: width * 0.5

                border.color: settings.color_glow
                border.width: 3
            }

            Rectangle {
                id: rightCircle

                anchors.left: leftCircle.right
                anchors.leftMargin: 5
                width: (parent.width < parent.height ? parent.width : parent.height) / 2
                height: width
                color: "transparent"
                radius: width * 0.5

                border.color: settings.color_shape
                border.width: 1
            }

            Rectangle {
                id: left_control_double
                anchors.centerIn: leftCircle
                width: (parent.width < parent.height ? parent.width : parent.height) * .1
                height: width
                color: settings.color_text
                border.color: settings.color_glow
                border.width: 1
                radius: width * 0.5

                visible: m_control_throttle < 1000 ? false : true

                transformOrigin: Item.Center

                transform: Translate {
                    x: settings.control_rev_yaw ? (((m_control_yaw - 1500) / 10) / 2)
                                                  * -1 : ((m_control_yaw - 1500) / 10) / 2
                    y: settings.control_rev_throttle ? ((((m_control_throttle - 2000) / 10) * -1 - 50) / 2) * -1 : (((m_control_throttle - 2000) / 10) * -1 - 50) / 2
                }
            }

            Rectangle {
                id: right_control_double
                anchors.centerIn: rightCircle
                width: (parent.width < parent.height ? parent.width : parent.height) * .1
                height: width
                color: settings.color_text
                border.color: settings.color_glow
                border.width: 1
                radius: width * 0.5

                visible: m_control_throttle < 1000 ? false : true

                transformOrigin: Item.Center

                transform: Translate {
                    x: settings.control_rev_roll ? (((m_control_roll - 1500) / 10) / 2)
                                                   * -1 : ((m_control_roll - 1500) / 10) / 2
                    y: settings.control_rev_pitch ? (((m_control_pitch - 1500) / 10) / 2)
                                                    * -1 : ((m_control_pitch - 1500) / 10) / 2
                }
            }
        }
    }
}

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Styles 1.4
import QtQuick.Extras 1.4
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import QtQuick.Shapes 1.0

import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: altitudeWidget
    width: 64
    height: 24
    // resize with right side (technically top right, but it doesn't matter because VCenter is set)
    defaultAlignment: 1
    defaultXOffset: 40
    defaultVCenter: true

    visible: settings.show_altitude

    widgetIdentifier: "altitude_widget"
    bw_verbose_name: "ALTITUDE"

    defaultHCenter: false

    hasWidgetDetail: true
    widgetDetailComponent: ScrollView {

        contentHeight: idBaseWidgetDefaultUiControlElements.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        BaseWidgetDefaultUiControlElements{
            id: idBaseWidgetDefaultUiControlElements

            show_vertical_lock: true
            show_horizontal_lock: true

            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Relative / MSL")
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
                    checked: settings.altitude_rel_msl
                    onCheckedChanged: settings.altitude_rel_msl = checked
                }
            }
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Show ladder")
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
                    checked: settings.show_altitude_ladder
                    onCheckedChanged: settings.show_altitude_ladder = checked
                }
            }
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Range")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: altitude_range_Slider
                    orientation: Qt.Horizontal
                    from: 40
                    value: settings.altitude_range
                    to: 150
                    stepSize: 10
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        // @disable-check M223
                        settings.altitude_range = altitude_range_Slider.value
                    }
                }
            }
        }
    }

    Item {
        id: widgetInner
        anchors.fill: parent
        opacity: bw_current_opacity

        //-----------------------ladder start---------------
        Item {
            id: altLadder

            anchors.left: parent.left
            anchors.leftMargin: 20 //tweak ladder left or right

            visible: settings.show_altitude_ladder

            transform: Scale {
                origin.x: -5
                origin.y: 12
                xScale: bw_current_scale
                yScale: bw_current_scale
            }

            AltitudeLadder {
                id: altitudeLadderC
                anchors.centerIn: parent
                width: 50
                height: 300
                clip: false
                color: settings.color_shape
                glow: settings.color_glow
                altitudeRelMsl: settings.altitude_rel_msl
                altitudeRange: settings.altitude_range
                imperial: settings.enable_imperial
                Behavior on altMsl {NumberAnimation { duration: settings.smoothing }}
                altMsl: _fcMavlinkSystem.alt_msl
                Behavior on altRel {NumberAnimation { duration: settings.smoothing }}
                altRel: _fcMavlinkSystem.alt_rel
                fontFamily: settings.font_text
            }
        }
        //-----------------------ladder end---------------
        Item {
            id: altPointer
            anchors.fill: parent

            Text {
                id: alt_text
                color: settings.color_text

                font.pixelSize: 14
                font.family: settings.font_text
                transform: Scale {
                    origin.x: 12
                    origin.y: 12
                    xScale: bw_current_scale
                    yScale: bw_current_scale
                }
                text: Number(// @disable-check M222
                             settings.enable_imperial ? (settings.altitude_rel_msl ? (_fcMavlinkSystem.alt_msl * 3.28) : (_fcMavlinkSystem.alt_rel * 3.28)) : (settings.altitude_rel_msl ? _fcMavlinkSystem.alt_msl : _fcMavlinkSystem.alt_rel)).toLocaleString(
                          Qt.locale(), 'f', 0) // @disable-check M222
                anchors.fill: parent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                style: Text.Outline
                styleColor: settings.color_glow
            }
            Shape {
                id: outlineGlow
                anchors.fill: parent

                transform: Scale {
                    origin.x: 12
                    origin.y: 12
                    xScale: bw_current_scale
                    yScale: bw_current_scale
                }
                ShapePath {
                    strokeColor: settings.color_glow
                    strokeWidth: 3
                    strokeStyle: ShapePath.SolidLine
                    fillColor: "transparent"
                    startX: 0
                    startY: 12
                    PathLine {
                        x: 0
                        y: 12
                    }
                    PathLine {
                        x: 12
                        y: 0
                    }
                    PathLine {
                        x: 58
                        y: 0
                    }
                    PathLine {
                        x: 58
                        y: 24
                    }
                    PathLine {
                        x: 12
                        y: 24
                    }
                    PathLine {
                        x: 0
                        y: 12
                    }
                }
            }
            Shape {
                id: outline
                anchors.fill: parent

                transform: Scale {
                    origin.x: 12
                    origin.y: 12
                    xScale: bw_current_scale
                    yScale: bw_current_scale
                }
                ShapePath {
                    strokeColor: settings.color_shape
                    strokeWidth: 1
                    strokeStyle: ShapePath.SolidLine
                    fillColor: "transparent"
                    startX: 0
                    startY: 12
                    PathLine {
                        x: 0
                        y: 12
                    }
                    PathLine {
                        x: 12
                        y: 0
                    }
                    PathLine {
                        x: 58
                        y: 0
                    }
                    PathLine {
                        x: 58
                        y: 24
                    }
                    PathLine {
                        x: 12
                        y: 24
                    }
                    PathLine {
                        x: 0
                        y: 12
                    }
                }
            }
        }
    }
}

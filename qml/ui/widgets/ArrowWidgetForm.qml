import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0
import QtQuick.Shapes 1.0

import OpenHD 1.0

BaseWidget {
    id: arrowWidget
    width: 24
    height: 24
    defaultYOffset: 85

    visible: settings.show_arrow

    widgetIdentifier: "arrow_widget"

    defaultHCenter: true
    defaultVCenter: false

    hasWidgetDetail: true
    widgetDetailComponent: Column {
        Item {
            width: parent.width
            height: 24
            Text {
                text: "Invert Arrow"
                color: "white"
                font.bold: true
                font.pixelSize: detailPanelFontPixels;
                anchors.left: parent.left
            }
            Switch {
                width: 32
                height: parent.height
                anchors.rightMargin: 12
                anchors.right: parent.right
                checked: settings.arrow_invert
                onCheckedChanged: settings.arrow_invert = checked
            }
        }
    }

    Item {
        id: widgetInner
        anchors.fill: parent

        Shape {
            id: arrow
            anchors.fill: parent
            antialiasing: true


            ShapePath {
                capStyle: ShapePath.RoundCap
                strokeColor: settings.color_glow
                fillColor: settings.color_shape
                strokeWidth: 1
                strokeStyle: ShapePath.SolidLine

                startX: 12
                startY: 0
                PathLine { x: 24;                 y: 12  }//right edge of arrow
                PathLine { x: 18;                 y: 12  }//inner right edge
                PathLine { x: 18;                 y: 24 }//bottom right edge
                PathLine { x: 6;                  y: 24 }//bottom left edge
                PathLine { x: 6;                  y: 12  }//inner left edge
                PathLine { x: 0;                  y: 12  }//outer left
                PathLine { x: 12;                  y: 0  }//back to start
            }

            transform: Rotation {
                origin.x: 12;
                origin.y: 12;
                angle: settings.arrow_invert ? OpenHD.home_course-180 : OpenHD.home_course
            }
        }

    }
}

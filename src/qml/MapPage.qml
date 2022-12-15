// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
// SPDX-FileCopyrightText: 2022 Harald Sitter <sitter@kde.org>

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.19 as Kirigami
import org.kde.kcoreaddons 1.0 as KCoreAddons
import QtQuick.Shapes 1.15

import org.kde.filelight 1.0

Kirigami.Page {
    id: page

    property url url: RadialMap.rootUrl
    property var contextMenu: undefined

    enabled: !ContextMenuContext.deleting
    topPadding: 0
    leftPadding: 0
    rightPadding: 0
    bottomPadding: 0

    Kirigami.Action {
        id: goToOverviewAction
        enabled: page.state === ""
        iconName: "go-home"
        text: i18nc("@action", "Go to Overview")
        onTriggered: pageStack.currentIndex = 0
    }

    Kirigami.Action {
        id: goUpAction
        enabled: page.state === ""
        iconName: "go-up"
        text: i18nc("@action", "Up")
        onTriggered: appWindow.slotUp()
        shortcut: "Alt+Up"
    }

    Kirigami.Action {
        id: rescanAction
        enabled: page.state !== "scanning"
        iconName: "view-refresh"
        text: i18nc("@action", "Rescan")
        onTriggered: appWindow.rescan()
        shortcut: StandardKey.Refresh
    }

    Kirigami.Action {
        id: stopAction
        enabled: page.state === "scanning"
        iconName: "process-stop"
        text: i18nc("@action", "Stop")
        onTriggered: appWindow.closeURL()
    }

    Kirigami.Action {
        id: zoomInAction
        enabled: page.state === ""
        iconName: "zoom-in"
        text: i18nc("@action", "Zoom In")
        displayHint: Kirigami.Action.AlwaysHide
        onTriggered: RadialMap.zoomIn()
        shortcut: StandardKey.ZoomIn
    }

    Kirigami.Action {
        id: zoomOutAction
        enabled: page.state === ""
        iconName: "zoom-out"
        text: i18nc("@action", "Zoom Out")
        displayHint: Kirigami.Action.AlwaysHide
        onTriggered: RadialMap.zoomOut()
        shortcut: StandardKey.ZoomOut
    }

    contextualActions: MainContext.historyActions.concat([
        goUpAction,
        goToOverviewAction,
        rescanAction,
        stopAction,
        zoomInAction,
        zoomOutAction,
        configureAction,
        helpAction,
        aboutAction
    ])

    Component {
        id: contextMenuComponent
        QQC2.Menu {
            id: contextMenu
            property var segment: undefined
            title: segment.displayName()

            onAboutToShow: page.contextMenu = this
            onAboutToHide: page.contextMenu = undefined

            QQC2.MenuItem {
                action: Kirigami.Action {
                    iconName: "document-open"
                    text: i18nc("@action Open file or directory from context menu", "Open")
                }
                onTriggered: Qt.openUrlExternally(contextMenu.segment.url())
            }
            QQC2.MenuItem {
                visible: segment.isFolder() && segment.url().toString().startsWith("file:")
                action: Kirigami.Action {
                    iconName: "utilities-terminal"
                    text: i18nc("@action", "Open Terminal Here")
                    onTriggered: ContextMenuContext.openTerminal(contextMenu.segment)
                }
            }
            QQC2.MenuItem {
                visible: segment.isFolder()
                action: Kirigami.Action {
                    iconName: "zoom-in"
                    text: i18nc("@action focuses the filelight view on a given map segment", "Center Map Here")
                    onTriggered: {
                        appWindow.updateURL(contextMenu.segment.url())
                        mapItem.createFromCacheObject(contextMenu.segment)
                    }
                }
            }
            QQC2.MenuItem {
                visible: segment.isFolder()
                action: Kirigami.Action {
                    iconName: "list-remove"
                    text: i18nc("@action", "Add to Do Not Scan List")
                    onTriggered: ContextMenuContext.doNotScan(contextMenu.segment)
                }
            }
            QQC2.MenuItem {
                visible: segment.isFolder()
                action: Kirigami.Action {
                    iconName: "view-refresh"
                    text: i18nc("@action rescan filelight map", "Rescan")
                    onTriggered: MainContext.rescanSingleDir(contextMenu.segment.url())
                }
            }
            QQC2.MenuItem {
                action: Kirigami.Action {
                    iconName: "edit-copy"
                    text: i18nc("@action", "Copy to clipboard")
                    onTriggered: ContextMenuContext.copyClipboard(contextMenu.segment)
                }
            }
            QQC2.MenuItem {
                action: Kirigami.Action {
                    iconName: "edit-delete"
                    text: i18nc("@action delete file or folder", "Delete")
                    onTriggered: ContextMenuContext.deleteFileFromSegment(contextMenu.segment)
                }
            }
        }
    }

    property var mouseyX: -1
    property var mouseyY: -1
    property var hoveredSegment: undefined
    property bool hoveringListItem: false

    RowLayout {
        anchors.fill: parent
        spacing: 0
        visible: page.state === ""

        QQC2.ScrollView {
            implicitWidth: Kirigami.Units.gridUnit * 10
            Layout.maximumWidth: Kirigami.Units.gridUnit * 22
            Layout.fillWidth: true
            Layout.fillHeight: true
            Kirigami.Theme.colorSet: Kirigami.Theme.View
            Kirigami.Theme.inherit: false

            // flush against both the toolbar and the window edge. without this we get a framed rectangle
            background: Rectangle {
	             color: Kirigami.Theme.backgroundColor
	        }
            Component.onCompleted: background.visible = true

            ListView {
                clip: true
                model: visible ? FileModel : undefined
                Component.onCompleted: currentIndex = -1
                reuseItems: true
                focus: true
                activeFocusOnTab: true
                keyNavigationEnabled: true
                keyNavigationWraps: true
                delegate: Kirigami.BasicListItem {
                    icon: ROLE_IsFolder ? "folder" : "file" // TODO mimetype?
                    text: display
                    subtitle: ROLE_HumanReadableSize
                    highlighted: {
                        if (hoveringListItem) {
                            return containsMouse
                        }
                        return (hoveredSegment === ROLE_Segment) || (hoveredSegment === "fake" && ROLE_Segment === "")
                    }
                    onContainsMouseChanged: {
                        if (containsMouse) {
                            hoveringListItem = true
                        }
                    }
                    onClicked: {
                        if (ROLE_IsFolder) {
                            MainContext.updateURL(ROLE_URL)
                            MainContext.openUrl(ROLE_URL)
                        }
                    }
                    onHoveredChanged: hoveredSegment = ROLE_Segment !== "" ? ROLE_Segment : "fake"

                    QQC2.Menu {
                        id: contextMenu

                        QQC2.MenuItem {
                            action: Kirigami.Action {
                                iconName: "document-open"
                                text: i18nc("@action Open file or directory from context menu", "Open")
                            }
                            onTriggered: Qt.openUrlExternally(ROLE_URL)
                        }
                        QQC2.MenuItem {
                            visible: ROLE_IsFolder && ROLE_URL.toString().startsWith("file:")
                            action: Kirigami.Action {
                                iconName: "utilities-terminal"
                                text: i18nc("@action", "Open Terminal Here")
                                onTriggered: ContextMenuContext.openTerminal(ROLE_URL)
                            }
                        }
                        QQC2.MenuItem {
                            visible: ROLE_IsFolder
                            action: Kirigami.Action {
                                iconName: "list-remove"
                                text: i18nc("@action", "Add to Do Not Scan List")
                                onTriggered: ContextMenuContext.doNotScan(ROLE_URL)
                            }
                        }
                        QQC2.MenuItem {
                            action: Kirigami.Action {
                                iconName: "edit-copy"
                                text: i18nc("@action", "Copy to clipboard")
                                onTriggered: ContextMenuContext.copyClipboard(ROLE_URL)
                            }
                        }
                        QQC2.MenuItem {
                            action: Kirigami.Action {
                                iconName: "edit-delete"
                                text: i18nc("@action delete file or folder", "Delete")
                                onTriggered: ContextMenuContext.deleteFile(FileModel.file(index))
                            }
                        }
                    }

                    TapHandler {
                        acceptedButtons: Qt.RightButton
                        onTapped: contextMenu.popup()
                    }
                }
            }
        }

        Kirigami.Separator {
            Layout.fillHeight: true
        }

        Item {
            id: shapeItem
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: Kirigami.Units.gridUnit * 10
            Layout.minimumWidth: Kirigami.Units.gridUnit * 10
            Layout.margins: Kirigami.Units.gridUnit
            antialiasing: true
            layer.enabled: true
            layer.samples: 32
            layer.smooth: true

            property var zOrderedShapes: []
            property bool hasShapes: zOrderedShapes.length > 0

            function objectToArray(object) {
                let newArray = [];
                for (let i in object) {
                    newArray.push(object[i]);
                }
                return newArray;
            }

            onChildrenChanged: {
                let children = objectToArray(shapeItem.children)
                children = children.filter(child => child instanceof Shape);
                children.sort((a, b) => b.z - a.z); // sort by level so the higher level object (the visible one) outscores ones it paints over
                zOrderedShapes = children
            }

            function tooltip({path, size, isFolder, files, totalFiles, isRoot = false} ) {
                let tips = [path, size]
                if (isFolder) {
                    const percent = Math.floor((100 * files) / totalFiles)
                    if (percent > 0) {
                        tips.push(i18ncp("Tooltip of folder, %1 is number of files", "%1 File (%2%)", "%1 Files (%2%)", files, percent))
                    } else {
                        tips.push(i18ncp("Tooltip of folder, %1 is number of files", "%1 File", "%1 Files", files))
                    }
                }
                if (isRoot) {
                    tips.push(i18nc("part of tooltip indicating that the item under the mouse is clickable", "Click to go up to parent directory"))
                }
                return tips.join("\n")
            }

            Instantiator {
                id: instantiator
                model: shapeItem.visible ? RadialMap.signature : undefined
                active: true
                asynchronous: true // arguable

                Instantiator {
                    // FIXME weird
                    Component.onCompleted: idx = index // lock index by breaking the binding
                    property var idx: index
                    readonly property var signatureRadius: {
                        if (shapeItem.width > shapeItem.height) {
                            return shapeItem.height / 2 / (instantiator.model.length + 1)
                        }
                        return shapeItem.width / 2 / (instantiator.model.length + 1)
                    }
                    readonly property var shapeRadius: signatureRadius * (idx + 2)

                    active: true
                    model: modelData
                    onObjectAdded: shapeItem.children.push(object)

                    delegate: SegmentShape {
                        // Qt doc: Note: model, index, and modelData roles are not accessible if the delegate contains required properties, unless it has also required properties with matching names.
                        required property var modelData
                        property bool segmentHover: hoveredSegment === segment.uuid || (segment.fake && hoveredSegment === "fake")

                        z: (instantiator.model.length - idx) // reverse order such that more central levels are above. this gives us segment appearance without having to actually paint segments (instead we stack full cicles)
                        segment: modelData
                        item: shapeItem
                        radius: shapeRadius
                        startAngle: -(modelData.start() / 16)
                        sweepAngle: -(modelData.length() / 16)
                        tooltipText: shapeItem.tooltip({isFolder: segment.isFolder(), path: segment.displayPath(), size: segment.humanReadableSize(),
                                                        files: segment.files(), totalFiles: RadialMap.numberOfChildren})
                        showTooltip: !contextMenu && !hoveringListItem && segmentHover && shapeItem.visible
                        fillColor: segmentHover ? Qt.darker(segment.color) : segment.color
                    }
                }
            }

            CenterShape {
                id: centerShape
                z: 500 // on top of everything, arbitrary high number of shapes
                visible: shapeItem.hasShapes
                segment: RadialMap.rootSegment
                segmentUuid: "root"
                item: shapeItem
                radius: {
                    if (instantiator.model === undefined) {
                        return 0
                    }
                    if (shapeItem.width > shapeItem.height) {
                        return shapeItem.height / 2 / (instantiator.model.length + 1)
                    }
                    return shapeItem.width / 2 / (instantiator.model.length + 1)
                }
                startAngle: 0
                sweepAngle: 360
                tooltipText: shapeItem.tooltip({isRoot: true, isFolder: true, path: RadialMap.displayPath, size: RadialMap.overallSize,
                                                files: RadialMap.numberOfChildren, totalFiles: RadialMap.numberOfChildren})
                showTooltip: !contextMenu && !hoveringListItem && hoveredSegment === segmentUuid && shapeItem.visible
                Kirigami.Theme.colorSet: Kirigami.Theme.View
                fillColor: Kirigami.Theme.backgroundColor
            }

            QQC2.Label {
                id: centerLabel
                z: 501
                visible: centerShape.visible
                text: RadialMap.overallSize
                Kirigami.Theme.colorSet: Kirigami.Theme.View
                color: Kirigami.Theme.textColor
                horizontalAlignment: Text.AlignHCenter
                // The diagonal of the circle is the hypotenuse of the largest square
                property var dimension: (2  * centerShape.radius) / Math.sqrt(2)
                width: dimension
                height: dimension
                anchors.centerIn: parent

                // Let the text scale way down but lock the maximum at the actual default font height.
                // This ensures that the text neatly fits into our dimensions.
                fontSizeMode: Text.Fit
                minimumPixelSize: 2
                Component.onCompleted: font.pixelSize = font.pixelSize
            }
        }
    }

    MouseArea {
        x: shapeItem.x
        y: shapeItem.y
        z: 502
        width: shapeItem.width
        height: shapeItem.height
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        function findTarget(mouse) {
            let children = shapeItem.zOrderedShapes
            for (var i in children) {
                const child = children[i]
                if (child === centerLabel) {
                    continue // not part of the shape objects
                }
                const contains = child.contains(Qt.point(mouse.x, mouse.y))
                if (contains) {
                    return child
                }
            }
            return null
        }

        onPositionChanged: (mouse) => {
            mouse.accepted = false
            const child = findTarget(mouse)
            if (child !== null) {
                hoveringListItem = false
                mouseyX = mouse.x
                mouseyY = mouse.y
                if (child.segmentUuid === undefined) {
                    hoveredSegment = "root"
                } else {
                    hoveredSegment = child.segmentUuid
                }
            } else {
                hoveredSegment = undefined
            }
        }

        onClicked: {
            const child = findTarget(mouse)
            if (child === null) {
                return
            }
            if (mouse.button === Qt.LeftButton) {
                if (child.segmentUuid === "root") {
                    appWindow.slotUp()
                    return
                }
                if (!child.segment.isFolder()) {
                    Qt.openUrlExternally(child.url)
                    return
                }
                MainContext.updateURL(child.url)
                MainContext.openUrl(child.url)
            } else if (mouse.button === Qt.RightButton) {
                console.log("click %1".arg(child))
                contextMenuComponent.createObject(child, {segment: child.segment}).popup()
            }
        }
        onPressAndHold: {
            if (mouse.source === Qt.MouseEventNotSynthesized) {
                const child = findTarget(mouse)
                contextMenu.segment = child.segment
                contextMenu.popup()
            }
        }
    }

    DropperItem {
        x: shapeItem.x
        y: shapeItem.y
        z: 503
        width: shapeItem.width
        height: shapeItem.height
        onUrlsDropped: function(urls) {
            const url = urls[0]
            appWindow.updateURL(url)
            appWindow.openURL(url)
        }
    }

    Kirigami.LoadingPlaceholder {
        id: scanPlaceholder
        visible: page.state === "scanning"
        anchors.centerIn: parent

        Timer {
            interval: 16 // = 60 fps because supposedly Qt hardcodes it all over the place (this claim is very old and it's unclear if still true)
            running: parent.visible
            repeat: true
            onTriggered: {
                const files = ScanManager.files();
                const size = ScanManager.totalSize()
                scanPlaceholder.text = i18ncp("Scanned number of files and size so far", "%1 File, %2", "%1 Files, %2", String(files), KCoreAddons.Format.formatByteSize(size));
            }
        }
    }

    Kirigami.PlaceholderMessage {
        visible: page.state === "noData"
        anchors.centerIn: parent
        width: parent.width - (Kirigami.Units.largeSpacing * 4)
        text: i18n("No data available")
    }

    Connections {
        target: ScanManager
        onAboutToEmptyCache: RadialMap.invalidate()
    }

    Connections {
        target: MainContext
        onCanvasIsDirty: (filth) => {
            RadialMap.refresh(filth)
        }
    }

    Component.onCompleted: {
        appWindow.mapPage = this
    }

    states: [
        State {
            name: "scanning"
            when: ScanManager.running
        },
        State {
            name: "noData"
            // FIXME this toggles too soon causing incomplete shapes to show wtf - but only when instaniatior is no async
            when: !RadialMap.valid && shapeItem.hasShapes
        },
        State {
            name: "" // default state
        }
    ]
}

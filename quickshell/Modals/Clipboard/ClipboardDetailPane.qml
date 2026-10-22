pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import qs.Common
import qs.Services
import "../../Services/ClipboardImageSizing.js" as ImageSizing
import qs.DCommon.Widgets
import "../../Common/Format.js" as Format

Item {
    id: root

    required property var modal
    readonly property var entry: modal.currentEntry
    property string imageSource: ""
    property string fullText: ""
    property bool textTruncated: false
    readonly property int previewCharacterLimit: 64 * 1024
    property bool loading: false
    property bool failed: false
    property var pendingRequest: null
    property bool ready: false
    readonly property bool isImage: ClipboardService.canPreviewEntry(entry)
    readonly property var metadata: entry ? [
        {
            label: I18n.tr("Content Type"),
            value: entry.mimeType ?? ""
        },
        {
            label: I18n.tr("Size"),
            value: Format.formatBytes(entry.size ?? 0)
        },
        {
            label: I18n.tr("Copied"),
            value: Qt.formatDateTime(new Date(entry.timestamp), Qt.DefaultLocaleShortDate)
        }
    ] : []

    function loadEntry() {
        if (pendingRequest)
            pendingRequest.cancelled = true;
        pendingRequest = null;
        imageSource = "";
        fullText = "";
        textTruncated = false;
        failed = false;
        loading = false;
        textScroll.contentY = 0;
        if (!entry)
            return;

        const request = {
            cancelled: false
        };
        const entryId = entry.id;
        pendingRequest = request;
        loading = true;
        DMSService.sendRequest("clipboard.getEntry", {
            "id": entryId
        }, response => {
            // Callbacks may arrive after selection changes or the pane is destroyed.
            if (request.cancelled)
                return;
            root.loading = false;
            root.pendingRequest = null;
            if (response.error || !response.result) {
                root.failed = true;
                return;
            }
            const result = response.result;
            if (root.isImage) {
                root.imageSource = ClipboardService.imageDataUrl(result.data ?? "", result.mimeType ?? "");
                root.failed = !root.imageSource;
                return;
            }
            const text = result.data ? root.modal.editorView.decodeEntryData(result.data) : (result.preview ?? "");
            root.textTruncated = text.length > root.previewCharacterLimit;
            root.fullText = text.slice(0, root.previewCharacterLimit);
        });
    }

    onEntryChanged: {
        if (ready)
            loadEntry();
    }
    Component.onCompleted: {
        ready = true;
        loadEntry();
    }
    Component.onDestruction: {
        if (pendingRequest)
            pendingRequest.cancelled = true;
    }

    Rectangle {
        anchors.left: parent.left
        height: parent.height
        width: Theme.outlineWidth
        color: Theme.outlineMedium
    }

    Item {
        id: preview
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: information.top
        anchors.margins: Theme.spacingM
        clip: true

        Image {
            id: image
            anchors.fill: parent
            source: root.imageSource
            asynchronous: true
            cache: false
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: false
            readonly property real renderPixelRatio: Window.window?.devicePixelRatio ?? Screen.devicePixelRatio
            readonly property var decodeSize: ImageSizing.sourceSize(root.entry?.preview, width, height, renderPixelRatio)
            sourceSize: Qt.size(decodeSize.width, decodeSize.height)
            visible: root.isImage && status === Image.Ready

        }

        DFlickable {
            id: textScroll
            anchors.fill: parent
            contentHeight: previewText.implicitHeight
            visible: !!root.entry && !root.isImage && !root.loading && !root.failed
            clip: true

            StyledText {
                id: previewText
                width: textScroll.width - Theme.spacingM
                text: root.fullText + (root.textTruncated ? "\n\n" + I18n.tr("Preview truncated") : "")
                textFormat: Text.PlainText
                wrapMode: Text.WrapAnywhere
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceText
            }
        }

        StyledText {
            anchors.centerIn: parent
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: root.loading ? I18n.tr("Loading...") : root.failed || (root.isImage && image.status === Image.Error) ? I18n.tr("Failed to load clipboard entry", "clipboard editor: fetching the entry's full text failed") : I18n.tr("No recent clipboard entries found")
            color: Theme.surfaceVariantText
            visible: root.loading || root.failed || !root.entry || (root.isImage && image.status === Image.Error)
        }
    }

    Column {
        id: information
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingS
        visible: !!root.entry

        Rectangle {
            width: parent.width
            height: Theme.outlineWidth
            color: Theme.outlineMedium
        }

        StyledText {
            text: I18n.tr("Information")
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Theme.fontWeightMedium
            color: Theme.surfaceVariantText
        }

        Repeater {
            model: root.metadata
            delegate: Row {
                required property var modelData
                width: information.width
                spacing: Theme.spacingM

                StyledText {
                    width: parent.width / 3
                    text: modelData.label
                    color: Theme.surfaceVariantText
                    font.pixelSize: Theme.fontSizeSmall
                    elide: Text.ElideRight
                }
                StyledText {
                    width: parent.width - parent.spacing - parent.width / 3
                    text: modelData.value
                    textFormat: Text.PlainText
                    horizontalAlignment: Text.AlignRight
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeSmall
                    elide: Text.ElideMiddle
                }
            }
        }
    }
}

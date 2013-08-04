import QtQuick 1.1
import tomahawk 1.0
import "tomahawkimports"
import "stations"

Rectangle {
    id: scene
    color: "black"
    anchors.fill: parent
    state: "list"

    FlexibleHeader {
        id: header
        anchors {
            left: parent.left
            top: parent.top
            right: parent.right
        }
        height: defaultFontHeight * 4
        width: parent.width
        icon: "../images/station.svg"
        title: mainView.title
        subtitle: generator.summary
        showSearchField: false
        showBackButton: stationListView.currentIndex > 0
        showNextButton: mainView.configured && stationListView.currentIndex == 2
        nextButtonText: "Save"
        backButtonText: "Back"

        z: 1 //cover albumcovers that may leave their area

        onBackPressed: {
            inputBubble.opacity = 0
            stationListView.decrementCurrentIndex()
            switch (stationListView.currentIndex) {
            case 0:
                subtitle = ""
                break;
            case 1:
                subtitle = modeModel.get(stationCreator.modeIndex).headerSubtitle + "..."
                break;
            }
        }
        // In our case the next button is the save button
        onNextPressed: {
            inputBubble.opacity = 1
            inputBubble.forceActiveFocus();
        }
    }


    ListModel {
        id: modeModel
        ListElement { label: "By Artist"; image: "../../images/station-artist.svg"; creatorContent: "stations/CreateByArtist.qml"; headerSubtitle: "Songs from" }
        ListElement { label: "By Genre"; image: "../../images/station-genre.svg"; creatorContent: "stations/CreateByGenre.qml"; headerSubtitle: "Songs of genre" }
        ListElement { label: "By Year"; image: "../../images/station-year.svg"; creatorContent: "stations/CreateByYear.qml"; headerSubtitle: "Songs from" }
    }

    VisualItemModel {
        id: stationVisualModel

        StationCreatorPage1 {
            height: scene.height - header.height
            width: scene.width
            model: modeModel

            onItemClicked: {
                stationCreator.modeIndex = index

                // FIXME: This is a workaround for the ListView scrolling too slow on the first time
                // Lets reinitialize the current index to something invalid and back to 0 (what it already is) before scrolling over to page 1
                stationListView.currentIndex = -1
                stationListView.currentIndex = 0

                stationListView.incrementCurrentIndex()
                header.subtitle = modeModel.get(index).headerSubtitle + "..."
            }
        }

        StationCreatorPage2 {
            id: stationCreator
            height: stationListView.height
            width: stationListView.width

            property int modeIndex

            content: modeModel.get(modeIndex).creatorContent

            onNext: {
                stationListView.incrementCurrentIndex()
                header.subtitle = modeModel.get(modeIndex).headerSubtitle + " " + text
            }
        }

        StationItem {
            id: stationItem
            height: stationListView.height
            width: stationListView.width
        }
    }


    VisualItemModel {
        id: configuredStationVisualModel


        StationItem {
            id: cfgstationItem
            height: stationListView.height
            width: stationListView.width
        }
    }

    ListView {
        id: stationListView
        anchors {
            left: parent.left
            top: header.bottom
            right: parent.right
            bottom: parent.bottom
        }

        contentHeight: height
        contentWidth: width
        orientation: ListView.Horizontal
        //model: mainView.configured ? configuredStationVisualModel : stationVisualModel
        interactive: false
        highlightMoveDuration: 300

        onHeightChanged: {
            contentHeight = scene.height
        }
        onWidthChanged: {
            contentWidth = scene.width
        }

        Component.onCompleted: {
            model = mainView.configured ? configuredStationVisualModel : stationVisualModel
        }
        onModelChanged: print("ccccccccccccc", mainView.configured)
    }

    InputBubble {
        id: inputBubble
        text: "Station name:"
        width: defaultFontHeight * 18
        anchors.top: header.bottom
        anchors.right: parent.right
        anchors.rightMargin: defaultFontHeight / 2
        anchors.topMargin: -defaultFontHeight / 2
        z: 2
        opacity: 0
        arrowPosition: 0.95

        onAccepted: {
            mainView.title = inputBubble.inputText
            inputBubble.opacity = 0
            header.showNextButton = false
            header.showBackButton = false
            inputBubble.opacity = 0
        }

        onRejected: inputBubble.opacity = 0
    }
}

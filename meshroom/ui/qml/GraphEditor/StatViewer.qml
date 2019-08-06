import QtQuick 2.7
import QtQuick.Controls 2.3
import QtCharts 2.2
import QtQuick.Layouts 1.11
import Utils 1.0
import MaterialIcons 2.2

Item {
    id: root

    implicitWidth: 500
    implicitHeight: 500

    property url source
    property var sourceModified: undefined
    property var jsonObject
    property int nbReads: 1
    property real deltaTime: 1

    property var cpuLineSeries: []
    property int nbCores: 0
    property int cpuFrequency: 0

    property int ramTotal

    property int gpuTotalMemory
    property int gpuMaxAxis: 100
    property string gpuName

    property color textColor: Colors.sysPalette.text

    readonly property  var colors: [
        "#f44336",
        "#e91e63",
        "#9c27b0",
        "#673ab7",
        "#3f51b5",
        "#2196f3",
        "#03a9f4",
        "#00bcd4",
        "#009688",
        "#4caf50",
        "#8bc34a",
        "#cddc39",
        "#ffeb3b",
        "#ffc107",
        "#ff9800",
        "#ff5722",
        "#b71c1c",
        "#880E4F",
        "#4A148C",
        "#311B92",
        "#1A237E",
        "#0D47A1",
        "#01579B",
        "#006064",
        "#004D40",
        "#1B5E20",
        "#33691E",
        "#827717",
        "#F57F17",
        "#FF6F00",
        "#E65100",
        "#BF360C"
    ]

    onSourceChanged: {
        sourceModified = undefined;
        resetCharts()
        readSourceFile()
    }

    Timer {
        id: reloadTimer
        interval: root.deltaTime * 60000; running: true; repeat: false
        onTriggered: readSourceFile()

    }

    function readSourceFile() {
        if(!Filepath.urlToString(source).endsWith("statistics"))
            return;

        var xhr = new XMLHttpRequest;
        xhr.open("GET", source);

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status == 200) {

                if(sourceModified === undefined || sourceModified < xhr.getResponseHeader('Last-Modified')) {
                    var jsonObject;

                    try {
                        jsonObject = JSON.parse(xhr.responseText);
                    }
                    catch(exc)
                    {
                        console.warning("Failed to parse statistics file: " + source)
                        root.jsonObject = {};
                        return;
                    }
                    root.jsonObject = jsonObject;
                    resetCharts();
                    sourceModified = xhr.getResponseHeader('Last-Modified')
                    root.createCharts();
                    reloadTimer.restart();
                }
            }
        };
        xhr.send();
    }

    function resetCharts() {
        cpuLineSeries = []
        cpuChart.removeAllSeries()
        cpuCheckboxModel.clear()
        ramChart.removeAllSeries()
        gpuChart.removeAllSeries()
    }

    function createCharts() {
        root.deltaTime = jsonObject.interval / 60.0;
        initCpuChart()
        initRamChart()
        initGpuChart()
    }


/**************************
***         CPU         ***
**************************/

    function initCpuChart() {
        var categories = []
        var categoryCount = 0
        var category
        do {
            category = jsonObject.computer.curves["cpuUsage." + categoryCount]
            if(category !== undefined) {
                categories.push(category)
                categoryCount++
            }
        } while(category !== undefined)

        var nbCores = categories.length
        root.nbCores = nbCores

        root.cpuFrequency = jsonObject.computer.cpuFreq

        root.nbReads = categories[0].length-1

        for(var j = 0; j < nbCores; j++) {
            cpuCheckboxModel.append({ name: "CPU" + j, index: j, indicColor: colors[j % colors.length] })
            var lineSerie = cpuChart.createSeries(ChartView.SeriesTypeLine, "CPU" + j, valueAxisX, valueAxisY)

            if(categories[j].length === 1) {
                lineSerie.append(0, categories[j][0])
                lineSerie.append(root.deltaTime, categories[j][0])
            } else {
                for(var k = 0; k < categories[j].length; k++) {
                    lineSerie.append(k * root.deltaTime, categories[j][k])
                }
            }
            lineSerie.color = colors[j % colors.length]

            root.cpuLineSeries.push(lineSerie)
        }

        cpuCheckboxModel.append({ name: "AVERAGE", index: nbCores, indicColor: colors[0] })
        var averageLine = cpuChart.createSeries(ChartView.SeriesTypeLine, "AVERAGE", valueAxisX, valueAxisY)
        var average = []

        for(var l = 0; l < categories[0].length; l++) {
            average.push(0)
        }

        for(var m = 0; m < categories.length; m++) {
            for(var n = 0; n < categories[m].length; n++) {
                average[n] += categories[m][n]
            }
        }

        for(var q = 0; q < average.length; q++) {
            average[q] = average[q] / (categories.length)

            averageLine.append(q * root.deltaTime, average[q])
        }

        averageLine.color = colors[0]

        root.cpuLineSeries.push(averageLine)
    }

    function showCpu(index) {
        let serie = cpuLineSeries[index]
        if(!serie.visible) {
            serie.visible = true
        }
    }

    function hideCpu(index) {
        let serie = cpuLineSeries[index]
        if(serie.visible) {
            serie.visible = false
        }
    }

    function hideOtherCpu(index) {
        for(var i = 0; i < cpuLineSeries.length; i++) {
            cpuLineSeries[i].visible = false
        }

        cpuLineSeries[i].visible = true
    }

    function higlightCpu(index) {
        for(var i = 0; i < cpuLineSeries.length; i++) {
            if(i === index) {
                cpuLineSeries[i].width = 5.0
            } else {
                cpuLineSeries[i].width = 0.2
            }
        }
    }

    function stopHighlightCpu(index) {
        for(var i = 0; i < cpuLineSeries.length; i++) {
            cpuLineSeries[i].width = 2.0
        }
    }




/**************************
***         RAM         ***
**************************/

    function initRamChart() {
        root.ramTotal = jsonObject.computer.ramTotal

        var ram = jsonObject.computer.curves.ramUsage

        var ramSerie = ramChart.createSeries(ChartView.SeriesTypeLine, "RAM", valueAxisX2, valueAxisRam)

        if(ram.length === 1) {
            ramSerie.append(0, ram[0] / 100 * root.ramTotal)
            ramSerie.append(root.deltaTime, ram[0] / 100 * root.ramTotal)
        } else {
            for(var i = 0; i < ram.length; i++) {
                ramSerie.append(i * root.deltaTime, ram[i] / 100 * root.ramTotal)
            }
        }

        ramSerie.color = colors[10]
    }



/**************************
***         GPU         ***
**************************/

    function initGpuChart() {
        root.gpuTotalMemory = jsonObject.computer.gpuMemoryTotal
        root.gpuName = jsonObject.computer.gpuName

        var gpuUsedMemory = jsonObject.computer.curves.gpuMemoryUsed
        var gpuUsed = jsonObject.computer.curves.gpuUsed
        var gpuTemperature = jsonObject.computer.curves.gpuTemperature

        var gpuUsedSerie = gpuChart.createSeries(ChartView.SeriesTypeLine, "GPU", valueAxisX3, valueAxisY3)
        var gpuUsedMemorySerie = gpuChart.createSeries(ChartView.SeriesTypeLine, "Memory", valueAxisX3, valueAxisY3)
        var gpuTemperatureSerie = gpuChart.createSeries(ChartView.SeriesTypeLine, "Temperature", valueAxisX3, valueAxisY3)

        if(gpuUsedMemory.length === 1) {
            gpuUsedSerie.append(0, gpuUsed[0])
            gpuUsedSerie.append(1 * root.deltaTime, gpuUsed[0])

            gpuUsedMemorySerie.append(0, gpuUsedMemory[0] / root.gpuTotalMemory * 100)
            gpuUsedMemorySerie.append(1 * root.deltaTime, gpuUsedMemory[0] / root.gpuTotalMemory * 100)

            gpuTemperatureSerie.append(0, gpuTemperature[0])
            gpuTemperatureSerie.append(1 * root.deltaTime, gpuTemperature[0])
            root.gpuMaxAxis = Math.max(gpuMaxAxis, gpuTemperature[0])
        } else {
            for(var i = 0; i < gpuUsedMemory.length; i++) {
                gpuUsedSerie.append(i * root.deltaTime, gpuUsed[i])

                gpuUsedMemorySerie.append(i * root.deltaTime, gpuUsedMemory[i] / root.gpuTotalMemory * 100)

                gpuTemperatureSerie.append(i * root.deltaTime, gpuTemperature[i])
                root.gpuMaxAxis = Math.max(gpuMaxAxis, gpuTemperature[i])
            }
        }
    }



/**************************
***          UI         ***
**************************/

    ScrollView {
        height: root.height
        width: root.width
        ScrollBar.vertical.policy: ScrollBar.AlwaysOn

        ColumnLayout {
            width: root.width


/**************************
***       CPU UI        ***
**************************/

            ColumnLayout {
                Layout.fillWidth: true

                Button {
                    id: toggleCpuBtn
                    Layout.fillWidth: true
                    text: "Toggle CPU's"
                    state: "closed"

                    onClicked: state === "opened" ? state = "closed" : state = "opened"

                    MaterialLabel {
                        text: MaterialIcons.arrow_drop_down
                        font.pointSize: 14
                        anchors.right: parent.right
                    }

                    states: [
                        State {
                            name: "opened"
                            PropertyChanges { target: cpuBtnContainer; visible: true }
                            PropertyChanges { target: toggleCpuBtn; down: true }
                        },
                        State {
                            name: "closed"
                            PropertyChanges { target: cpuBtnContainer; visible: false }
                            PropertyChanges { target: toggleCpuBtn; down: false }
                        }
                    ]
                }

                Item {
                    id: cpuBtnContainer

                    Layout.fillWidth: true
                    implicitHeight: childrenRect.height
                    Layout.leftMargin: 25

                    RowLayout {
                        width: parent.width
                        anchors.horizontalCenter: parent.horizontalCenter

                        ButtonGroup {
                            id: cpuGroup
                            exclusive: false
                            checkState: allCPU.checkState
                        }

                        CheckBox {
                            width: 80
                            checked: true
                            id: allCPU
                            text: "ALL"
                            checkState: cpuGroup.checkState

                            indicator: Rectangle {
                                width: 20
                                height: 20
                                border.color: textColor
                                border.width: 2
                                color: "transparent"
                                anchors.verticalCenter: parent.verticalCenter

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 10
                                    height: allCPU.checkState === 1 ? 4 : 10
                                    color: allCPU.checkState === 0 ? "transparent" : textColor
                                }
                            }

                            leftPadding: indicator.width + 5

                            contentItem: Label {
                                text: allCPU.text
                                font: allCPU.font
                                verticalAlignment: Text.AlignVCenter
                            }

                            Layout.fillHeight: true
                        }

                        ListModel {
                            id: cpuCheckboxModel
                        }

                        Flow {
                            Layout.fillWidth: true

                            Repeater {
                                model: cpuCheckboxModel

                                CheckBox {
                                    width: 80
                                    checked: true
                                    text: name
                                    ButtonGroup.group: cpuGroup

                                    indicator: Rectangle {
                                        width: 20
                                        height: 20
                                        border.color: indicColor
                                        border.width: 2
                                        color: "transparent"
                                        anchors.verticalCenter: parent.verticalCenter

                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: 10
                                            height: parent.parent.checkState === 1 ? 4 : 10
                                            color: parent.parent.checkState === 0 ? "transparent" : indicColor
                                        }
                                    }

                                    leftPadding: indicator.width + 5

                                    contentItem: Label {
                                        text: name
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    onCheckStateChanged: function() {
                                        if(checkState === 2) {
                                            root.showCpu(index)
                                        } else {
                                            root.hideCpu(index)
                                        }
                                    }

                                    onHoveredChanged: function() {
                                        if(hovered) {
                                            root.higlightCpu(index)
                                        } else {
                                            root.stopHighlightCpu(index)
                                        }
                                    }

                                    onDoubleClicked: function() {
                                        name.checked = false
                                        root.hideOtherCpu(index)
                                    }
                                }
                            }
                        }
                    }


                }

                ChartView {
                    id: cpuChart

                    Layout.fillWidth: true
                    Layout.preferredHeight: width/2
                    antialiasing: true
                    legend.visible: false
                    theme: ChartView.ChartThemeLight
                    backgroundColor: "transparent"
                    plotAreaColor: "transparent"
                    titleColor: textColor

                    title: "CPU: " + root.nbCores + " cores, " + root.cpuFrequency + "Hz"

                    ValueAxis {
                        id: valueAxisY
                        min: 0
                        max: 100
                        titleText: "<span style='color: " + textColor + "'>%</span>"
                        color: textColor
                        gridLineColor: textColor
                        minorGridLineColor: textColor
                        shadesColor: textColor
                        shadesBorderColor: textColor
                        labelsColor: textColor
                    }

                    ValueAxis {
                        id: valueAxisX
                        min: 0
                        max: root.deltaTime * Math.max(1, root.nbReads)
                        titleText: "<span style='color: " + textColor + "'>Minutes</span>"
                        color: textColor
                        gridLineColor: textColor
                        minorGridLineColor: textColor
                        shadesColor: textColor
                        shadesBorderColor: textColor
                        labelsColor: textColor
                    }

                }
            }



/**************************
***       RAM UI        ***
**************************/

            ColumnLayout {


                ChartView {
                    id: ramChart

                    Layout.fillWidth: true
                    Layout.preferredHeight: width/2
                    antialiasing: true
                    legend.color: textColor
                    legend.labelColor: textColor
                    theme: ChartView.ChartThemeLight
                    backgroundColor: "transparent"
                    plotAreaColor: "transparent"
                    titleColor: textColor

                    title: "RAM: " + root.ramTotal + "GB"

                    ValueAxis {
                        id: valueAxisY2
                        min: 0
                        max: 100
                        titleText: "<span style='color: " + textColor + "'>%</span>"
                        color: textColor
                        gridLineColor: textColor
                        minorGridLineColor: textColor
                        shadesColor: textColor
                        shadesBorderColor: textColor
                        labelsColor: textColor
                    }

                    ValueAxis {
                        id: valueAxisRam
                        min: 0
                        max: root.ramTotal
                        titleText: "<span style='color: " + textColor + "'>GB</span>"
                        color: textColor
                        gridLineColor: textColor
                        minorGridLineColor: textColor
                        shadesColor: textColor
                        shadesBorderColor: textColor
                        labelsColor: textColor
                    }

                    ValueAxis {
                        id: valueAxisX2
                        min: 0
                        max: root.deltaTime * Math.max(1, root.nbReads)
                        titleText: "<span style='color: " + textColor + "'>Minutes</span>"
                        color: textColor
                        gridLineColor: textColor
                        minorGridLineColor: textColor
                        shadesColor: textColor
                        shadesBorderColor: textColor
                        labelsColor: textColor
                    }
                }
            }



/**************************
***       GPU UI        ***
**************************/

            ColumnLayout {


                ChartView {
                    id: gpuChart

                    Layout.fillWidth: true
                    Layout.preferredHeight: width/2
                    antialiasing: true
                    legend.color: textColor
                    legend.labelColor: textColor
                    theme: ChartView.ChartThemeLight
                    backgroundColor: "transparent"
                    plotAreaColor: "transparent"
                    titleColor: textColor

                    title: "GPU: " + root.gpuName + ", " + root.gpuTotalMemory + "MB"

                    ValueAxis {
                        id: valueAxisY3
                        min: 0
                        max: root.gpuMaxAxis
                        titleText: "<span style='color: " + textColor + "'>%, °C</span>"
                        color: textColor
                        gridLineColor: textColor
                        minorGridLineColor: textColor
                        shadesColor: textColor
                        shadesBorderColor: textColor
                        labelsColor: textColor
                    }

                    ValueAxis {
                        id: valueAxisX3
                        min: 0
                        max: root.deltaTime * Math.max(1, root.nbReads)
                        titleText: "<span style='color: " + textColor + "'>Minutes</span>"
                        color: textColor
                        gridLineColor: textColor
                        minorGridLineColor: textColor
                        shadesColor: textColor
                        shadesBorderColor: textColor
                        labelsColor: textColor
                    }
                }
            }

        }
    }

}
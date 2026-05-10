import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    // Token UI state
    property bool tokenSaved: false
    property bool tokenLoaded: false
    property bool tokenExists: false
    property bool showToken: false
    property string pendingToken: ""

    Component.onCompleted: tokenReader.running = true

    // Read existing token on open (just to know if one exists)
    Process {
        id: tokenReader
        command: ["secret-tool", "lookup", "application", "illogical-impulse", "key", "githubToken"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim()
                tokenExists   = t.length > 0
                pendingToken  = t
                tokenLoaded   = true
            }
        }
        onExited: (code) => { if (code !== 0) tokenLoaded = true }
    }

    // Save token to keyring
    Process {
        id: tokenWriter
        command: ["secret-tool", "store", "--label=GitHub Token",
                  "application", "illogical-impulse", "key", "githubToken"]
        stdinEnabled: true
        onRunningChanged: {
            if (running) {
                tokenWriter.write(pendingToken + "\n")
                stdinEnabled = false
            }
        }
        onExited: (code) => {
            if (code === 0) {
                tokenSaved   = true
                tokenExists  = pendingToken.length > 0
                // Re-load the token in the background service
                GithubCommits.token = pendingToken
                GithubCommits.fetchCommits()
                saveConfirmTimer.restart()
            }
        }
    }

    Timer {
        id: saveConfirmTimer
        interval: 2500
        onTriggered: tokenSaved = false
    }

    // ── Widget toggle ───────────────────────────────────────────────────────
    ContentSection {
        icon: "commit"
        title: Translation.tr("GitHub Contributions")

        ConfigSwitch {
            buttonIcon: "visibility"
            text: Translation.tr("Show on desktop")
            checked: Config.options.background.widgets.githubCommits.enable
            onCheckedChanged: {
                Config.options.background.widgets.githubCommits.enable = checked
            }
        }
    }

    // ── Account ─────────────────────────────────────────────────────────────
    ContentSection {
        icon: "manage_accounts"
        title: Translation.tr("Account")

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("GitHub username")
            text: Config.options.background.widgets.githubCommits.username
            wrapMode: TextEdit.NoWrap
            onTextChanged: {
                Qt.callLater(() => {
                    Config.options.background.widgets.githubCommits.username = text
                })
            }
        }

        // Token row
        ContentSubsection {
            title: Translation.tr("Personal access token")
            tooltip: Translation.tr("Required to read private contributions.\nCreate one at github.com/settings/tokens with the read:user scope.\nThe token is stored in the system keyring, not in the config file.")

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                MaterialTextField {
                    id: tokenField
                    Layout.fillWidth: true
                    placeholderText: tokenLoaded
                        ? (tokenExists ? Translation.tr("Token saved — enter a new one to replace") : Translation.tr("Paste token here"))
                        : Translation.tr("Loading…")
                    echoMode: showToken ? TextInput.Normal : TextInput.Password
                    text: pendingToken
                    onTextEdited: pendingToken = text
                }

                // Show / hide toggle
                RippleButton {
                    implicitWidth: 40
                    implicitHeight: 40
                    buttonRadius: height / 2
                    padding: 0
                    onClicked: showToken = !showToken
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: showToken ? "visibility_off" : "visibility"
                        iconSize: 20
                    }
                    StyledToolTip { text: showToken ? Translation.tr("Hide") : Translation.tr("Show") }
                }

                // Save button
                RippleButton {
                    implicitWidth: 40
                    implicitHeight: 40
                    buttonRadius: height / 2
                    padding: 0
                    enabled: pendingToken.length > 0 && !tokenWriter.running
                    onClicked: {
                        tokenSaved = false
                        tokenWriter.running = true
                    }
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: tokenSaved ? "check" : "save"
                        iconSize: 20
                        color: tokenSaved ? Appearance.colors.colPrimary : Appearance.colors.colOnSurface
                    }
                    StyledToolTip { text: tokenSaved ? Translation.tr("Saved!") : Translation.tr("Save to keyring") }
                }
            }
        }
    }

    // ── Refresh ─────────────────────────────────────────────────────────────
    ContentSection {
        icon: "refresh"
        title: Translation.tr("Refresh")

        ConfigRow {
            ConfigSpinBox {
                icon: "av_timer"
                text: Translation.tr("Auto-refresh interval (min)")
                value: Config.options.background.widgets.githubCommits.fetchInterval
                from: 5
                to: 120
                stepSize: 5
                onValueChanged: {
                    Config.options.background.widgets.githubCommits.fetchInterval = value
                }
            }

            ConfigSwitch {
                buttonIcon: "sync"
                text: Translation.tr("Refresh now")
                checked: false
                onCheckedChanged: {
                    if (checked) {
                        GithubCommits.fetchCommits()
                        checked = false
                    }
                }
            }
        }
    }

    // ── Status ───────────────────────────────────────────────────────────────
    ContentSection {
        icon: "bar_chart"
        title: Translation.tr("Status")

        NoticeBox {
            Layout.fillWidth: true
            materialIcon: GithubCommits.hasError ? "error" : "check_circle"
            text: {
                if (GithubCommits.hasError)
                    return Translation.tr("Error: %1").arg(GithubCommits.errorMessage)
                if (GithubCommits.loading)
                    return Translation.tr("Fetching…")
                if (GithubCommits.dailyCommits.length === 0)
                    return Translation.tr("No data yet. Make sure your username and token are set.")
                return Translation.tr("%1 commits this month").arg(GithubCommits.totalCommits)
            }
        }
    }
}

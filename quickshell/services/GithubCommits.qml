pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

import qs.modules.common

Singleton {
    id: root

    // Config
    readonly property string username:        Config.options.background.widgets.githubCommits.username
    readonly property int    fetchIntervalMs: Config.options.background.widgets.githubCommits.fetchInterval * 60 * 1000

    // Token — loaded once from the keyring on startup
    property string token: ""

    // Current month string "YYYY-MM"
    readonly property string currentMonth: {
        const d = new Date();
        return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
    }

    // Days in the current month
    readonly property int daysInMonth: {
        const d = new Date();
        return new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate();
    }

    // State
    property bool   loading:      false
    property bool   hasError:     false
    property string errorMessage: ""
    property int    totalCommits: 0
    property int    maxDayCount:  0

    // dailyCommits: [{day: int, count: int}] for every day 1..daysInMonth
    property list<var> dailyCommits: []

    function fetchCommits() {
        if (root.username === "" || root.token === "") return;
        root.loading  = true;
        root.hasError = false;
        fetcher.running = false;
        fetcher.running = true;
    }

    Process {
        id: fetcher
        command: [
            "python3",
            Quickshell.shellPath("scripts/github-commits.py"),
            root.token,
            root.username,
            root.currentMonth
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false;
                const raw = text.trim();
                if (raw.length === 0) {
                    root.hasError     = true;
                    root.errorMessage = "No response from script";
                    return;
                }
                try {
                    const parsed = JSON.parse(raw);
                    if (parsed.error) {
                        root.hasError     = true;
                        root.errorMessage = parsed.error;
                        return;
                    }
                    if (!Array.isArray(parsed)) {
                        root.hasError     = true;
                        root.errorMessage = "Unexpected response";
                        return;
                    }

                    // Build full daily array (every day 1..daysInMonth, defaulting to 0)
                    const map = {};
                    for (const item of parsed) map[item.day] = item.count;

                    let daily = [];
                    let total = 0, max = 0;
                    for (let d = 1; d <= root.daysInMonth; d++) {
                        const count = map[d] ?? 0;
                        daily.push({ day: d, count: count });
                        total += count;
                        if (count > max) max = count;
                    }
                    root.dailyCommits = daily;
                    root.totalCommits = total;
                    root.maxDayCount  = max;
                    root.hasError     = false;
                } catch (e) {
                    root.hasError     = true;
                    root.errorMessage = "Parse error: " + e.message;
                }
            }
        }
    }

    Timer {
        interval:         root.fetchIntervalMs
        repeat:           true
        running:          root.username !== "" && root.token !== ""
        triggeredOnStart: true
        onTriggered:      root.fetchCommits()
    }

    Process {
        id: tokenLoader
        command: ["secret-tool", "lookup", "application", "illogical-impulse", "key", "githubToken"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim()
                if (t.length > 0) root.token = t
            }
        }
    }

    Component.onCompleted: tokenLoader.running = true

    onUsernameChanged: if (root.username !== "" && root.token !== "") root.fetchCommits()
    onTokenChanged:    if (root.username !== "" && root.token !== "") root.fetchCommits()
}

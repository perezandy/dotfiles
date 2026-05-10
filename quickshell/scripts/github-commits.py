#!/usr/bin/env python3
"""
Fetches the GitHub contribution calendar for a given user and month via GraphQL.
Usage: github-commits.py <token> <username> <YYYY-MM>
Prints a JSON array: [{"day": 1, "count": 3}, ...]
"""
import sys
import json
import calendar
import urllib.request
import urllib.error

def main():
    if len(sys.argv) != 4:
        print(json.dumps({"error": "Usage: github-commits.py <token> <username> <YYYY-MM>"}))
        sys.exit(1)

    token, username, month = sys.argv[1], sys.argv[2], sys.argv[3]

    try:
        year, mon = int(month[:4]), int(month[5:7])
    except (ValueError, IndexError):
        print(json.dumps({"error": f"Invalid month format: {month}"}))
        sys.exit(1)

    last_day = calendar.monthrange(year, mon)[1]
    from_date = f"{month}-01T00:00:00Z"
    to_date   = f"{month}-{last_day:02d}T23:59:59Z"

    query = """
query($login: String!, $from: DateTime!, $to: DateTime!) {
  user(login: $login) {
    contributionsCollection(from: $from, to: $to) {
      contributionCalendar {
        weeks {
          contributionDays {
            date
            contributionCount
          }
        }
      }
    }
  }
}
"""

    payload = json.dumps({
        "query": query,
        "variables": {"login": username, "from": from_date, "to": to_date}
    }).encode()

    req = urllib.request.Request(
        "https://api.github.com/graphql",
        data=payload,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        }
    )

    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            data = json.loads(resp.read())
    except urllib.error.HTTPError as e:
        print(json.dumps({"error": f"HTTP {e.code}: {e.reason}"}))
        sys.exit(1)
    except Exception as e:
        print(json.dumps({"error": str(e)}))
        sys.exit(1)

    if "errors" in data:
        print(json.dumps({"error": data["errors"][0].get("message", "GraphQL error")}))
        sys.exit(1)

    try:
        weeks = data["data"]["user"]["contributionsCollection"]["contributionCalendar"]["weeks"]
    except (KeyError, TypeError):
        print(json.dumps({"error": "Unexpected response shape"}))
        sys.exit(1)

    days = []
    for week in weeks:
        for day in week.get("contributionDays", []):
            if day["date"].startswith(month):
                days.append({
                    "day":   int(day["date"][8:10]),
                    "count": day["contributionCount"]
                })

    days.sort(key=lambda d: d["day"])
    print(json.dumps(days))

if __name__ == "__main__":
    main()

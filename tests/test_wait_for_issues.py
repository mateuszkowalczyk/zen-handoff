"""Offline polling tests: python3 -m unittest discover -s tests -v."""

import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "template/.agents/scripts/wait-for-issues.sh"


def issue(number=1, role="coordinator", status="ready", **changes):
    result = {
        "number": number,
        "title": "Task",
        "html_url": f"https://github.com/example/project/issues/{number}",
        "updated_at": "2026-10-09T12:00:00Z",
        "comments": 0,
        "labels": [{"name": f"role:{role}"}, {"name": f"status:{status}"}],
    }
    result.update(changes)
    return result


class PollingTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.snapshot = self.root / "snapshot.json"
        self.env = dict(os.environ, PATH=f"{self.root}:{os.environ['PATH']}", MOCK_ROOT=str(self.root))
        self.env.pop("ZEN_HANDOFF_POLL_SECONDS", None)
        gh = self.root / "gh"
        gh.write_text(f"#!{sys.executable}\n" + '''
import json, os, pathlib, sys
root = pathlib.Path(os.environ["MOCK_ROOT"])
args = sys.argv[1:]
if args[:2] == ["repo", "view"]:
    print("example/project")
    sys.exit(0)
if args[0] != "api" or "--paginate" not in args or "--slurp" not in args:
    sys.exit("Unexpected gh invocation")
if (root / "fail").exists():
    sys.exit("Mock GitHub API failure")
fixtures = json.loads((root / "fixtures.json").read_text())
counter = root / "counter"
if "/dependencies/blocked_by" in args[-1]:
    index = int(counter.read_text()) - 1
    print(json.dumps(fixtures[min(index, len(fixtures) - 1)].get("blockers", [[]])))
else:
    index = int(counter.read_text()) if counter.exists() else 0
    counter.write_text(str(index + 1))
    print(json.dumps(fixtures[min(index, len(fixtures) - 1)]["pages"]))
''')
        gh.chmod(0o755)
        sleep = self.root / "sleep"
        sleep.write_text('''#!/usr/bin/env bash
printf '%s\n' "$1" >> "$MOCK_ROOT/sleeps"
if [[ $(wc -l < "$MOCK_ROOT/sleeps") -gt 10 ]]; then
    echo 'Test exceeded expected polling iterations' >&2
    exit 97
fi
''')
        sleep.chmod(0o755)

    def run_poll(self, fixtures, role="coordinator", interval=None):
        (self.root / "fixtures.json").write_text(json.dumps(fixtures))
        if interval is not None:
            self.env["ZEN_HANDOFF_POLL_SECONDS"] = interval
        return subprocess.run(
            ["bash", str(SCRIPT), role, str(self.snapshot)],
            env=self.env, capture_output=True, text=True, timeout=5,
        )

    def output(self, result):
        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads(result.stdout)

    def test_existing_ready_task_returns_immediately(self):
        output = self.output(self.run_poll([{"pages": [[issue()]]}]))
        self.assertEqual(output["queue"][0]["number"], 1)
        self.assertEqual(json.loads(self.snapshot.read_text()), output)
        self.assertFalse((self.root / "sleeps").exists())

    def test_empty_queue_waits_sixty_seconds_until_work(self):
        output = self.output(self.run_poll([{"pages": [[]]}, {"pages": [[issue()]]}]))
        self.assertEqual(output["queue"][0]["number"], 1)
        self.assertEqual((self.root / "sleeps").read_text(), "60\n")

    def test_triage_wins_over_ready_and_pagination_is_preserved(self):
        triaged = issue()
        triaged["labels"].append({"name": "status:triage"})
        output = self.output(self.run_poll([
            {"pages": [[triaged, issue(2, status="triage")]]},
            {"pages": [[triaged], [issue(3)]]},
        ]))
        self.assertEqual([item["number"] for item in output["queue"]], [3])
        self.assertEqual((self.root / "sleeps").read_text(), "60\n")

    def test_unchanged_snapshot_waits_until_new_comment(self):
        baseline = self.output(self.run_poll([{"pages": [[issue()]]}]))
        self.assertEqual(baseline["queue"][0]["comments"], 0)
        (self.root / "counter").unlink()
        output = self.output(self.run_poll([
            {"pages": [[issue()]]},
            {"pages": [[issue(comments=1, updated_at="2026-10-09T12:01:00Z")]]},
        ]))
        self.assertEqual(output["queue"][0]["comments"], 1)
        self.assertEqual((self.root / "sleeps").read_text(), "60\n")

    def test_blocker_completion_wakes_coordinator_without_issue_update(self):
        blocked = issue(status="blocked")
        blocker = issue(17, state="open", state_reason=None)
        first = {"pages": [[blocked]], "blockers": [[blocker]]}
        self.output(self.run_poll([first]))
        (self.root / "counter").unlink()
        completed = dict(blocker, state="closed", state_reason="completed")
        output = self.output(self.run_poll([
            first, {"pages": [[blocked]], "blockers": [[completed]]},
        ]))
        self.assertEqual(output["dependencies"][0]["blockedBy"][0]["state_reason"], "completed")
        self.assertEqual((self.root / "sleeps").read_text(), "60\n")

    def test_builder_and_reviewer_queues(self):
        for role, status in [("builder-simple", "ready"), ("builder-complex", "ready"), ("reviewer", "review")]:
            with self.subTest(role=role):
                output = self.output(self.run_poll([{"pages": [[
                    issue(1, role, status), issue(2, role, "blocked"),
                    issue(3, role, "triage"), issue(4, "coordinator", "ready"),
                ]]}], role=role))
                self.assertEqual([item["number"] for item in output["queue"]], [1])
                self.assertEqual(output["dependencies"], [])

    def test_prs_and_conflicting_labels_are_excluded(self):
        conflicting = issue(2)
        conflicting["labels"].append({"name": "role:reviewer"})
        output = self.output(self.run_poll([{"pages": [[
            issue(1, pull_request={"url": "example"}), conflicting, issue(3),
        ]]}]))
        self.assertEqual([item["number"] for item in output["queue"]], [3])

    def test_api_failure_is_visible_and_does_not_replace_snapshot(self):
        self.snapshot.write_text("previous snapshot")
        (self.root / "fail").touch()
        result = self.run_poll([])
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Mock GitHub API failure", result.stderr)
        self.assertEqual(result.stdout, "")
        self.assertEqual(self.snapshot.read_text(), "previous snapshot")

    def test_invalid_role_and_interval_fail_before_github(self):
        for role, interval in [("unknown", "60"), ("coordinator", "0"), ("coordinator", "oops")]:
            with self.subTest(role=role, interval=interval):
                result = self.run_poll([], role=role, interval=interval)
                self.assertNotEqual(result.returncode, 0)
                self.assertFalse((self.root / "counter").exists())

    def test_explicit_interval_override(self):
        self.output(self.run_poll([{"pages": [[]]}, {"pages": [[issue()]]}], interval="30"))
        self.assertEqual((self.root / "sleeps").read_text(), "30\n")

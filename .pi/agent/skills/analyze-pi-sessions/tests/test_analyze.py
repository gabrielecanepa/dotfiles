from contextlib import redirect_stderr, redirect_stdout
import importlib.util
import io
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "analyze.py"
spec = importlib.util.spec_from_file_location("analyze", SCRIPT)
A = importlib.util.module_from_spec(spec)
spec.loader.exec_module(A)


class AnalysisTests(unittest.TestCase):
  def setUp(self):
    self.temporary = tempfile.TemporaryDirectory()
    self.addCleanup(self.temporary.cleanup)
    self.root = Path(self.temporary.name).resolve()
    self.project = self.root / "project"
    self.other = self.root / "other"
    self.project.mkdir()
    self.other.mkdir()
    self.sessions = self.root / "sessions"
    self.sessions.mkdir()
    self.environment = patch.dict(os.environ, {"PI_CODING_AGENT_DIR": str(self.root / "agent"), "PI_CODING_AGENT_SESSION_DIR": str(self.sessions)})
    self.environment.start()
    self.addCleanup(self.environment.stop)
    self.cwd = Path.cwd()
    os.chdir(self.project)
    self.addCleanup(os.chdir, self.cwd)

  def write_session(self, session_id, records, project=None, parent=None):
    project = project or self.project
    directory = self.sessions / A.encoded_cwd(project)
    if parent:
      directory = directory / parent / "worker" / "run-1"
    directory.mkdir(parents=True, exist_ok=True)
    path = directory / (session_id + ".jsonl")
    header = {"type": "session", "version": 3, "id": session_id, "cwd": str(project), "timestamp": "2026-01-01T10:00:00Z"}
    path.write_text("\n".join(json.dumps(record) for record in [header, *records]) + "\n")
    return path

  def run_report(self, *arguments):
    stdout = io.StringIO()
    stderr = io.StringIO()
    with redirect_stdout(stdout), redirect_stderr(stderr):
      self.assertEqual(A.main(list(arguments)), 0)
    return json.loads(stdout.getvalue()), stderr.getvalue()

  def test_all_current_usage_entry_types_and_provider_models(self):
    records = [
      {"type": "message", "id": "a", "timestamp": "2026-01-01T10:01:00Z", "message": {"role": "assistant", "provider": "one", "model": "shared", "usage": {"input": 10, "output": 5, "cost": {"total": 1}}}},
      {"type": "usage", "id": "b", "provider": "two", "model": "shared", "kind": "cache_warm", "usage": {"cacheRead": 7, "cost": {"total": 2}}},
      {"type": "compaction", "id": "c", "usage": {"cost": {"input": 0.25, "output": 0.25}}},
      {"type": "branch_summary", "id": "d", "usage": {"cost": {"total": 0.5}}},
      {"type": "message", "id": "e", "message": {"role": "assistant", "provider": "one", "model": "unpriced", "usage": {"input": 3}}},
    ]
    self.write_session("primary", records)
    report, _ = self.run_report("cost", "--by", "model")
    self.assertEqual(report["recorded_cost"], 4)
    self.assertEqual(report["groups"]["one/shared"]["input"], 10)
    self.assertEqual(report["groups"]["two/shared"]["cacheRead"], 7)
    self.assertEqual(report["groups"]["one/unpriced"]["unpriced_entries"], 1)
    self.assertIn("not invoices", report["label"])

  def test_scope_filters_before_reading_other_transcripts(self):
    self.write_session("local", [])
    foreign = self.write_session("foreign", [], project=self.other)
    with foreign.open("ab") as stream:
      stream.write(b"BROKEN PRIVATE BODY\n")
    report, warnings = self.run_report("cost")
    self.assertEqual(report["sessions"], 1)
    self.assertEqual(report["skipped_records_or_sessions"], 0)
    self.assertNotIn("foreign", warnings)
    report, warnings = self.run_report("cost", "--all-projects")
    self.assertEqual(report["sessions"], 2)
    self.assertEqual(report["skipped_records_or_sessions"], 1)
    self.assertNotIn("PRIVATE BODY", warnings)

  def test_default_root_limits_discovery_to_encoded_project(self):
    self.write_session("local", [])
    self.write_session("foreign", [], project=self.other)
    target = self.root / "agent" / "sessions"
    target.parent.mkdir()
    self.sessions.rename(target)
    with patch.dict(os.environ, {"PI_CODING_AGENT_SESSION_DIR": ""}):
      report, _ = self.run_report("cost")
    self.assertEqual(report["sessions"], 1)

  def test_subagents_and_symlinks_are_excluded_by_default(self):
    self.write_session("main", [])
    self.write_session("worker", [], parent="main")
    foreign = self.write_session("foreign", [], project=self.other)
    (self.sessions / A.encoded_cwd(self.project) / "linked.jsonl").symlink_to(foreign)
    report, _ = self.run_report("cost")
    self.assertEqual(report["sessions"], 1)
    report, _ = self.run_report("cost", "--include-subagents")
    self.assertEqual(report["sessions"], 2)

  def test_copied_fork_usage_is_not_charged_twice(self):
    entry = {"type": "usage", "id": "same", "timestamp": "2026-01-01T10:02:00Z", "provider": "p", "model": "m", "usage": {"cost": {"total": 2}}}
    self.write_session("one", [entry])
    self.write_session("two", [entry])
    report, _ = self.run_report("cost")
    self.assertEqual(report["recorded_cost"], 2)
    self.assertEqual(report["duplicate_usage_entries"], 1)

  def test_invalid_tail_is_reported_and_empty_content_is_safe(self):
    path = self.write_session("valid", [{"type": "message", "message": {"role": "assistant", "content": None, "usage": {"cost": {"total": "bad"}}}}])
    with path.open("ab") as stream:
      stream.write(b'{"partial":')
    report, warnings = self.run_report("cost")
    self.assertEqual(report["recorded_cost"], 0)
    self.assertEqual(report["skipped_records_or_sessions"], 1)
    self.assertIn("invalid", warnings)

  def test_show_follows_active_branch_and_omits_thinking_and_tools(self):
    self.write_session("tree", [
      {"type": "message", "id": "root", "parentId": None, "message": {"role": "user", "content": "Start"}},
      {"type": "message", "id": "old", "parentId": "root", "message": {"role": "assistant", "content": [{"type": "text", "text": "Inactive branch"}]}},
      {"type": "message", "id": "new", "parentId": "root", "message": {"role": "assistant", "content": [{"type": "thinking", "thinking": "Private reasoning"}, {"type": "text", "text": "Active branch"}]}},
      {"type": "message", "id": "tool", "parentId": "new", "message": {"role": "toolResult", "content": [{"type": "text", "text": "Tool data"}]}},
    ])
    report, _ = self.run_report("show", "--session", "tree")
    self.assertEqual([row["text"] for row in report["rows"]], ["Start", "Active branch"])
    report, _ = self.run_report("show", "--include-tools")
    self.assertEqual(report["rows"][-1]["text"], "Tool data")
    self.assertNotIn("Private reasoning", json.dumps(report))

  def test_prompt_search_bounds_and_legacy_string_content(self):
    self.write_session("text", [{"type": "message", "id": str(index), "message": {"role": "user", "content": "Needle " + "x" * 100}} for index in range(5)])
    report, _ = self.run_report("prompts", "--limit", "2", "--max-chars", "20")
    self.assertEqual(len(report["rows"]), 2)
    self.assertTrue(all(len(row["text"]) == 20 and row["truncated"] for row in report["rows"]))
    report, _ = self.run_report("search", "NEEDLE", "--role", "user", "--limit", "1")
    self.assertEqual(len(report["rows"]), 1)

  def test_ambiguous_prefix_and_invalid_arguments_fail_closed(self):
    self.write_session("prefix-one", [])
    self.write_session("prefix-two", [])
    for arguments in [("show", "--session", "prefix"), ("cost", "--limit", "0"), ("cost", "--since", "2026-02-01", "--until", "2026-01-01")]:
      with redirect_stderr(io.StringIO()), self.assertRaises(SystemExit) as error:
        A.main(list(arguments))
      self.assertEqual(error.exception.code, 2)


if __name__ == "__main__":
  unittest.main()

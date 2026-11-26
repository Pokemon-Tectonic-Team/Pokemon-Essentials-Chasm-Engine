# Builds the report CI posts on a PR: coverage of the changed lines (whitespace-only changes aside),
# the whole-codebase figure and RuboCop on the changed Ruby files. Run from the repository root
# after the suite has written coverage/coverage.json, with SYNTAX_OUTCOME, TESTS_OUTCOME, RUN_URL
# and PR_NUMBER set:
#
#     ruby .github/scripts/pr_report.rb <output directory>
#
# Writes <output directory>/body.md and pr-number, and appends the report to the file
# GITHUB_STEP_SUMMARY names, when it is set.
require "fileutils"
require "json"
require "open3"
require "stringio"
require_relative "pr_report/simplecov_diff_path"
require_relative "pr_report/simplecov_ignore_whitespace"
require_relative "pr_report/offense_counts"
require_relative "pr_report/lint_report"
require_relative "pr_report/comment_body"

# The PR's merge base: the first parent of the merge commit CI checks out.
BASE = "HEAD^1".freeze
# Characters kept of the job summary, which GitHub caps at 1 MiB, allowing four bytes each.
SUMMARY_LIMIT = 250_000

def simplecov(*args)
    stdout = StringIO.new
    stderr = StringIO.new
    exit_code = SimpleCov::CLI.run(args, stdout: stdout, stderr: stderr)
    [stdout.string, stderr.string, exit_code]
end

def totals
    stdout, _stderr, exit_code = simplecov("status", "--json")
    exit_code.zero? ? JSON.parse(stdout)["totals"] : nil
rescue JSON::ParserError
    nil
end

def changed_ruby_files
    list, status = Open3.capture2("git", "diff", "--name-only", "-z", "--diff-filter=d", "--merge-base", BASE, "--", "*.rb")
    raise PrReport::Error, "git diff against #{BASE} failed" unless status.success?

    list.split("\0")
end

# RuboCop's stdout; exits 0 and 1 mean it ran, with or without offenses.
def rubocop(files, *args)
    stdout, stderr, status = Open3.capture3("bundle", "exec", "rubocop", "--force-exclusion", *args, "--", *files)
    raise PrReport::Error, (stderr.empty? ? "RuboCop exited #{status.exitstatus}" : stderr) if status.exitstatus > 1

    stdout
end

# The lint section and, when it is a summary, the full report it summarises.
def lint
    files = changed_ruby_files
    return [PrReport::LintReport.none_changed, nil] if files.empty?

    full = rubocop(files, "--format", "markdown")
    return [PrReport::LintReport.full_section(full), nil] unless PrReport::LintReport.summarise?(full)

    counts = rubocop(files, "--format", "offenses")
    rows = PrReport::OffenseCounts.parse(counts)
    detailed = PrReport::OffenseCounts.detailed(rows)
    unique = detailed.empty? ? nil : rubocop(files, "--format", "markdown", "--only", detailed.join(","))
    safe = PrReport::OffenseCounts.safe_correctable(rows)
    [PrReport::LintReport.summary(counts: counts, safe: safe, unique: unique), full]
rescue PrReport::Error => e
    # A workflow command's data escapes "%" as "%25".
    puts "::error title=RuboCop::#{PrReport::LintReport.headline(e.message).gsub('%', '%25')}"
    [PrReport::LintReport.error(e.message), nil]
end

out = ARGV.fetch(0)
FileUtils.mkdir_p(out)
File.write(File.join(out, "pr-number"), ENV.fetch("PR_NUMBER"))

patch_stdout, patch_stderr, patch_exit = simplecov("patch", "--base", BASE, "--no-color")
lint_section, full_lint = lint
body = PrReport::CommentBody.build(
    syntax: ENV.fetch("SYNTAX_OUTCOME"),
    tests: ENV.fetch("TESTS_OUTCOME"),
    run_url: ENV.fetch("RUN_URL"),
    patch: { text: patch_stdout + patch_stderr, exit: patch_exit },
    totals: totals,
    lint: lint_section
)
File.write(File.join(out, "body.md"), body)

summary_file = ENV.fetch("GITHUB_STEP_SUMMARY", nil)
if summary_file
    summary = full_lint ? "#{body}\n## Full RuboCop report\n\n#{full_lint}" : body
    note = "_Cut to fit GitHub's job summary limit._"
    File.write(summary_file, PrReport::Markdown.cut_chars(summary, limit: SUMMARY_LIMIT, note: note), mode: "a")
end

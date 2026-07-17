#!/usr/bin/env bash
#
# coverage.sh — run the test suite with code coverage, export an LCOV report,
# and enforce a minimum line-coverage threshold for the library sources.
#
# Only the CoreModelSQLite target sources are counted toward the threshold;
# dependencies, generated sources and the test target are excluded so the
# number reflects the coverage of this package's own code.
#
# Usage:
#   Scripts/coverage.sh [threshold]
#
# Environment variables:
#   COVERAGE_THRESHOLD   Minimum line coverage percentage (default: 80).
#                        Overridden by the optional [threshold] argument.
#   COVERAGE_OUTPUT      LCOV output file (default: .build/coverage/coverage.lcov).
#   SKIP_TEST            If set to 1, reuse existing coverage data instead of
#                        re-running `swift test`.

set -euo pipefail

# Directory that holds the sources counted toward the coverage threshold.
SOURCE_FILTER="/Sources/CoreModelSQLite/"

THRESHOLD="${1:-${COVERAGE_THRESHOLD:-80}}"
OUTPUT="${COVERAGE_OUTPUT:-.build/coverage/coverage.lcov}"

# Resolve the correct llvm-cov / llvm-profdata (xcrun on Apple platforms).
if command -v xcrun >/dev/null 2>&1; then
    LLVM_COV="xcrun llvm-cov"
else
    LLVM_COV="llvm-cov"
fi

# 1. Run the tests with coverage instrumentation.
if [ "${SKIP_TEST:-0}" != "1" ]; then
    echo "==> Running tests with code coverage"
    swift test --enable-code-coverage
fi

# 2. Locate the coverage artifacts SwiftPM produced.
CODECOV_JSON="$(swift test --enable-code-coverage --show-codecov-path)"
COV_DIR="$(dirname "$CODECOV_JSON")"
PROFDATA="$COV_DIR/default.profdata"

if [ ! -f "$CODECOV_JSON" ]; then
    echo "error: coverage report not found at $CODECOV_JSON" >&2
    exit 1
fi

# 3. Locate the instrumented test binary (differs by platform).
BIN_PATH="$(swift build --show-bin-path)"
TEST_BINARY=""
for candidate in \
    "$BIN_PATH"/*PackageTests.xctest/Contents/MacOS/*PackageTests \
    "$BIN_PATH"/*PackageTests.xctest; do
    if [ -f "$candidate" ]; then
        TEST_BINARY="$candidate"
        break
    fi
done

# 4. Export an LCOV report (for artifact upload / external tooling).
mkdir -p "$(dirname "$OUTPUT")"
if [ -n "$TEST_BINARY" ] && [ -f "$PROFDATA" ]; then
    echo "==> Exporting LCOV report to $OUTPUT"
    $LLVM_COV export \
        -format=lcov \
        -instr-profile "$PROFDATA" \
        "$TEST_BINARY" \
        -ignore-filename-regex='.build/(checkouts|.*\.build)/|Tests/|\.derived/|DerivedSources/' \
        > "$OUTPUT"
else
    echo "warning: could not locate test binary or profdata; skipping LCOV export" >&2
fi

# 5. Compute line coverage for the library sources and enforce the threshold.
echo "==> Computing coverage for ${SOURCE_FILTER}"
python3 - "$CODECOV_JSON" "$SOURCE_FILTER" "$THRESHOLD" <<'PY'
import json, sys

report_path, source_filter, threshold = sys.argv[1], sys.argv[2], float(sys.argv[3])

with open(report_path) as f:
    report = json.load(f)

covered = total = 0
rows = []
for file in report["data"][0]["files"]:
    name = file["filename"]
    if source_filter not in name:
        continue
    lines = file["summary"]["lines"]
    covered += lines["covered"]
    total += lines["count"]
    rows.append((lines["percent"], name.split(source_filter, 1)[1]))

if total == 0:
    print("error: no source files matched %r" % source_filter, file=sys.stderr)
    sys.exit(1)

percent = 100.0 * covered / total

for pct, name in sorted(rows):
    print("  %6.2f%%  %s" % (pct, name))

print("-" * 40)
print("Total line coverage: %.2f%% (%d/%d lines)" % (percent, covered, total))
print("Required threshold:  %.2f%%" % threshold)

if percent < threshold:
    print("FAILED: coverage %.2f%% is below the %.2f%% threshold" % (percent, threshold), file=sys.stderr)
    sys.exit(1)

print("PASSED: coverage meets the threshold")
PY

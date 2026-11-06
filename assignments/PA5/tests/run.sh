#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
root=$(cd ../.. && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
make cgen LIB= >/dev/null
# The course binaries are 32-bit; qemu-i386 also works on hosts that block
# native 32-bit execution. Set RUN32='' to run them directly.
run32=${RUN32-qemu-i386}
compile() {
  local source=$1; shift
  $run32 "$root/bin/.i686/lexer" "$source" | $run32 "$root/bin/.i686/parser" | \
    $run32 "$root/bin/.i686/semant" | ./cgen "$@" > "$tmp/program.s"
}
run() { (cd "$root/bin" && $run32 .i686/spim -file "$tmp/program.s"); }
check() {
  local source=$1 expected=$2; shift 2
  compile "$source" "$@"
  run > "$tmp/output"
  sed -i "s/Garbage collecting \.\.\.//g" "$tmp/output"
  tr -d "\n" < "$tmp/output" > "$tmp/normalized"
  if ! grep -Fq "$expected" "$tmp/normalized"; then cat "$tmp/output"; exit 1; fi
  echo "PASS $source $*"
}
check example.cl '10 9 B B 6 12 -5 ok equal'
check tests/semantics.cl '123 15 0 live distinct equal leq'
check tests/semantics.cl 'live distinct equal leq' -g -t
check tests/dispatch_void.cl 'Dispatch to void.'
check tests/case_void.cl 'Match on void in case statement.'
check tests/case_nomatch.cl 'No match in case statement'

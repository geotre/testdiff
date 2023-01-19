
# an example of how you might use testdiff with unit tests

import
  std/unittest,
  pkg/testdiff

# example code from your library

type
  ProducedObj = object
    a, b, c: int

proc someProcToTest: ProducedObj =
  ProducedObj(a: 5, b: 6, c: 7)

# simple proc to wrap diff and print errors if it fails

proc objectsShouldMatch[T](a, b: T): bool =
  let diff = diff(a, b)
  if not diff.same:
    # print the difference for easy debugging
    echo $diff
  diff.same

# simple proc to check that expected paths are different

proc objectsShouldNotMatch[T](a, b: T, paths: seq[string]): bool =
  let diff = diff(a, b)
  if paths != diff.errorPaths:
    # print the difference for easy debugging
    echo $diff
    false
  else:
    true

test "example1":
  check objectsShouldMatch(someProcToTest(), ProducedObj(a: 5, b: 6, c: 7))

test "example2":
  check objectsShouldNotMatch(someProcToTest(), ProducedObj(a: 5, b: 0, c: 7), @["b"])

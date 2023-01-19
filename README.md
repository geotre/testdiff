
# testdiff

A simple utility for diffing in tests.

`nimble install testdiff`

![Github Actions](https://github.com/geotre/testdiff/workflows/Github%20Actions/badge.svg)

## Usage

See [example](/examples/example.nim) for basic usage, [test example](/examples/exampletest.nim) for a simple test structure.

```nim
import pkg/testdiff

type
  Node = ref object
    val: int
    children: seq[Node]

let
  treeA = Node(val: 3, children: @[Node(val: 5)])
  treeB = Node(val: 3, children: @[Node(val: 7)])

echo $diffObjects(treeA, treeB)
```
```difference at path children[0].val: 5 != 7 (int)```

## Motivation

I recently found myself writing tests that compare the result object of a library procedure with a manually-instantiated object. It is easy for a test to say _these objects don't match_ but you don't get more details than that, which can be challenging if the difference is a single field in a large (potentially nested) object. This library allows you to easily show where the mismatch is found.

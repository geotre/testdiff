
import pkg/testdiff

type
  Node = ref object
    val: int
    children: seq[Node]

let
  treeA = Node(val: 3, children: @[Node(val: 5)])
  treeB = Node(val: 3, children: @[Node(val: 7)])

echo $diff(treeA, treeB)

# difference at path children[0].val: 5 != 7 (int)

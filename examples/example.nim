
import pkg/testdiff

type
  TestEnum = enum
    A, B, C

  TestObj = object
    intVal: int
    seqVal: seq[int]
    enumVal: TestEnum
    floatVal: float
    strVal: string
    sub: TestObjRef

  TestObjRef = ref TestObj

let d = diff(
  TestObj(
    intVal: 5,
    seqVal: @[1, 2, 3],
    enumVal: B, # this value is different in the second object
    floatVal: 5.5,
    strVal: "Hello world",
    sub: TestObjRef(
      intVal: 3,
      enumVal: C, # this value is missing in the second object, so defaults to A
      floatVal: 5.5,
      strVal: "Hello world"
    )
  ),
  TestObj(
    intVal: 5,
    seqVal: @[1, 2],  # this value is different
    floatVal: 5.5,
    strVal: "Hello world",
    sub: TestObjRef(
      intVal: 3,
      floatVal: 5.6, # this value is different
      strVal: "Hello world"
    )
  )
)

# stringify diff to get a list of differences
doAssert $d == """difference at path seqVal: 3 != 2 (seq[int].len)
difference at path enumVal: B != A (TestEnum)
difference at path sub.enumVal: C != A (TestEnum)
difference at path sub.floatVal: 5.5 != 5.6 (float)
"""

# check amount of errors
doAssert d.errorCount == 4

# check exact error paths
doAssert d.errorPaths == @[
  "seqVal",
  "enumVal",
  "sub.enumVal",
  "sub.floatVal"
]

# check if the two values are the same
doAssert not d.same

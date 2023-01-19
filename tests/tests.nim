
import
  std/unittest,
  pkg/testdiff

test "basic":
  type
    SimpleObj = object
      a: int

  check diff(SimpleObj(a: 5), SimpleObj(a: 5)).same
  check diff(SimpleObj(a: 5), SimpleObj(a: 6)).differ

test "refs":
  type
    SimpleObj = object
      a: int
    SimpleObjRef = ref SimpleObj

  check diff(SimpleObjRef(a: 5), SimpleObjRef(a: 5)).same
  var n: SimpleObjRef
  check diff(SimpleObjRef(a: 5), n).differ

test "basic types":
  type
    Kind = enum
      A, B, C

    Obj = object
      intVal: int
      seqVal: seq[int]
      enumVal: Kind
      floatVal: float
      strVal: string

  check diff(Obj(
    intVal: 7,
    seqVal: @[4, 5, 6],
    enumVal: C,
    floatVal: 3.3,
    strVal: "Hello world"
  ),
  Obj(
    intVal: 7,
    seqVal: @[4, 5, 6],
    enumVal: C,
    floatVal: 3.3,
    strVal: "Hello world"
  )).same

  check diff(Obj(
    intVal: 8,
    seqVal: @[0, 5, 6],
    enumVal: B,
    floatVal: 4.3,
    strVal: ""
  ),
  Obj(
    intVal: 7,
    seqVal: @[4, 5, 6],
    enumVal: C,
    floatVal: 3.3,
    strVal: "Hello world"
  )).errorCount == 5

test "nesting":
  type
    SubObj = object
      a: int

    Obj = object
      sub: SubObj

  check diff(Obj(
    sub: SubObj(a: 3)
  ),
  Obj(
    sub: SubObj(a: 3)
  )).same

  check diff(Obj(
    sub: SubObj(a: 3)
  ),
  Obj(
    sub: SubObj(a: 4)
  )).differ

test "obj variant":
  type
    Kind = enum
      Int,
      Str,
      Float

    Obj = object
      case kind: Kind
      of Int:
        intVal: int
      of Str:
        strVal: string
      of Float:
        floatVal: float

  check diff(Obj(
    kind: Int,
    intVal: 7
  ),
  Obj(
    kind: Int,
    intVal: 7
  )).same

  check diff(Obj(
    kind: Int,
    intVal: 7
  ),
  Obj(
    kind: Int,
    intVal: 8
  )).differ

  check diff(Obj(
    kind: Int,
    intVal: 7
  ),
  Obj(
    kind: Float,
    floatVal: 5.0
  )).differ

  check diff(Obj(
    kind: Int,
    intVal: 7
  ),
  Obj()).differ

test "ptr":
  # note that pointer types are compared on their target values
  type
    Obj = object
      a: ptr int

    Obj2 = object
      a: pointer

  var
    a = 5
    b = 5
    c = 6

  let
    pa = addr a
    pb = addr b
    pc = addr c

  check diff(Obj(
    a: pa
  ),
  Obj(
    a: pb
  )).same

  check diff(Obj(
    a: pa
  ),
  Obj(
    a: pc
  )).differ

  check diff(Obj2(
    a: pa
  ),
  Obj2(
    a: pa
  )).same

  check diff(Obj2(
    a: pa
  ),
  Obj2(
    a: pb
  )).differ

  check diff(Obj(
    a: pa
  ),
  Obj(
    a: nil
  )).differ

  check diff(Obj(
    a: nil
  ),
  Obj(
    a: nil
  )).same

  check diff(Obj2(
    a: pa
  ),
  Obj2(
    a: nil
  )).differ

  check diff(Obj2(
    a: nil
  ),
  Obj2(
    a: nil
  )).same

test "big":
  # the test from example.nim
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

  let diff = diff(
    TestObj(
      intVal: 5,
      seqVal: @[1, 2, 3],
      enumVal: B,
      floatVal: 5.5,
      strVal: "Hello world",
      sub: TestObjRef(
        intVal: 3,
        enumVal: C,
        floatVal: 5.5,
        strVal: "Hello world"
      )
    ),
    TestObj(
      intVal: 5,
      seqVal: @[1, 2],
      floatVal: 5.5,
      strVal: "Hello world",
      sub: TestObjRef(
        intVal: 3,
        floatVal: 5.6,
        strVal: "Hello world"
      )
    )
  )

  # stringify diff to get a list of differences
  check $diff == """difference at path seqVal: 3 != 2 (seq[int].len)
difference at path enumVal: B != A (TestEnum)
difference at path sub.enumVal: C != A (TestEnum)
difference at path sub.floatVal: 5.5 != 5.6 (float)
"""

test "tuples":
  check diff((a: 5), (a: 5)).same
  check diff((a: 5), (a: 6)).differ


import std/[macros, strformat]

type
  Err = object
    path: string
    valA, valB: string
    origType: string

  Diff = object
    errors: seq[Err]

macro getField[T: object | ref object](obj: T, fieldName: static string): untyped =
  nnkDotExpr.newTree(obj, ident(fieldName))

proc valToString[T](v: T): string =
  when T is ref:
    if v.isNil:
      "nil"
    else:
      $typeof(v)
  elif T is ptr:
    if v.isNil:
      "nil"
    else:
      valToString(v[])
  elif compiles($v):
    $v
  else:
    $typeof(v)

proc diff[T: object | ref object](a, b: T, path: string, d: var Diff)

proc diff[T: not(object | ref object | seq | array | ptr)](a, b: T, path: string, d: var Diff) =
  # catch everything that's not done by an overload below
  if a != b:
    d.errors.add Err(
      path: path,
      valA: valToString(a),
      valB: valToString(b),
      origType: $typeof(a)
    )

proc diff[T: ptr](a, b: T, path: string, d: var Diff) =
  if a.isNil and b.isNil:
    return
  elif a.isNil or b.isNil:
    d.errors.add Err(
      path: path,
      valA: valToString(a),
      valB: valToString(b),
      origType: $typeof(a)
    )
  elif a[] != b[]:
    d.errors.add Err(
      path: path,
      valA: valToString(a),
      valB: valToString(b),
      origType: $typeof(a)
    )

proc diff[T: seq | array](a, b: T, path: string, d: var Diff) =
  if a.len != b.len:
    d.errors.add Err(
      path: path,
      valA: valToString(a.len),
      valB: valToString(b.len),
      origType: $typeof(a) & ".len"
    )

  for i in 0..<min(a.len, b.len):
    diff(a[i], b[i], &"{path}[{i}]", d)

proc diff[T: object | ref object](a, b: T, path: string, d: var Diff) =
  when T is ref object:
    if a.isNil and b.isNil:
      return
    elif a.isNil or b.isNil:
      d.errors.add Err(
        path: path,
        valA: valToString(a),
        valB: valToString(b),
        origType: $typeof(a)
      )
      return

  for name, field in (when T is object: a.fieldPairs else: a[].fieldPairs):
    block checkField:
      let subpath = if path.len > 0: path & "." & name else: name
      var fa, fb: typeof(field)

      try:
        fa = getField(a, name)
        fb = getField(b, name)
      except FieldDefect:
        # this happens in object variants where the two objects have different kinds
        d.errors.add Err(
          path: subpath,
          valA: valToString(fa),
          valB: valToString(fb),
          origType: $typeof(fa)
        )
        break checkField

      diff(fa, fb, subpath, d)

# public api

proc same*(d: Diff): bool =
  ## true if no differences were found
  d.errors.len == 0

proc differ*(d: Diff): bool =
  ## opposite of Diff.same, true if differences were found
  not d.same

proc errorCount*(d: Diff): int =
  ## amount of differences found when comparing. Note that this is not
  ## necessarily the amount of differing _fields_, as a seq may have, for
  ## example, one less item, corresponding to one difference but multiple
  ## fields missing on one side
  d.errors.len

proc errorPaths*(d: Diff): seq[string] =
  ## the paths to differing fields/items. Useful for testing that the exact
  ## expected differences are present
  for e in d.errors:
    result.add e.path

proc diff*[T](a, b: T): Diff =
  ## diff two values and produce a list of differences for testing
  diff(a, b, "", result)

proc `$`*(d: Diff): string =
  ## useful for echoing the list of differences back to the developer running
  ## the test
  if d.same:
    result = "values are equal"
  else:
    for e in d.errors:
      result &= &"difference at path {e.path}: {e.valA} != {e.valB} ({e.origType})\n"

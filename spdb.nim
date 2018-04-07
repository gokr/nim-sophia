import sophia,
  strutils, unicode,
  options

type
  cfgatom = int64|string
  # Allows {key: val} associative array notation
  cfgaarray*[K, V] = openarray[tuple[key: K, val: cfgatom]]
  SophiaDb* = object
    env: pointer
    driver: pointer

  TxnError = Exception
  InsError = TxnError
  GetError = TxnError
  CfgError = Exception

proc ckErrno(exn: ref object, e: cint, what: Option[string]) =
  if e != 0:
    exn.msg = if not what.isNone: what.get() else: ""
    raise exn

proc ckErrNil(exn: ref object, e: pointer, what: Option[string]) =
  if e != nil:
    exn.msg =
      if what.isNone: ""
      else: ": " & what.get()
    raise exn

proc ckedSetV[K](o: pointer, k: K, v: cfgatom) =
  let (kstr, vstr) = (cstring k, cstring v)
  let errck =
    if v is string: ckErrNil
    else: ckErrno
  let err =
    if v is string: setstring(o, kstr, vstr, 0)
    else: setint(o, cstring k, v)

  let exn = new CfgError
  let vp = validateUtf8 string kstr and
           validateUtf8 string vstr
  let f =
    if vp: (func(x: cstring): cstring = x)
    else: (func(cstr: cstring): cstring =
             cstring toHex string cstr)
  let causemsg =
    if err is cstring: ": " & string err
    else: ""
  exn.errck err, "INS `$#@$#`" % [f kstr, f vstr] & causemsg

proc ckedGetStr[K](o: pointer, k: K): string =
  let kstr = cstring k
  var
    errstr: cstring
    errlen: cint
  result = string getstring(o, kstr, errlen.addr)
  # if nil, either unset or failure to retrieve
  new(GetError).ckErrNil(errstr, some "GET `@" & kstr & "` failed: Not set")

proc ckedGetInt[K](o: pointer, path: K): string =
  let pstr = cstring path
  result = getint(o, pstr)
  if result < 0:
    var exn = new GetError
    exn.msg = "GET `@" & pstr & "` failed: Invalid configuration path"
    raise exn


# Main DB constructor. Sets up and accounts for alloc/free of DB environment.
# Must be configured in initial argument list with `{key: val}` Associatve Array
# syntax tuple, using the legal values detailed online at
# http://sophia.systems/v2.2/conf/sophia.html.
proc newSpDb*[K](cfg: cfgaarray): SophiaDb =
  result = new SophiaDb
  result.env = env()
  var exn = new CfgError
  exn.ckErrNil(result.env, "failure to allocate configuration")
  for k, v in cfg:
    result.env.ckedSetV(k, v)
  exn.ckErrNil(result.env.open(), some "failure to open DB w/ configuration")
  let driver = result.env.getobject(some "db." & result.env.ckedGetStr "db")
  new(InsError).ckErrNil(driver, some "DB initialization failed: was `db` configured?")
  result.driver = driver



type
  # `Document` represents either an association or deletion from a given
  # transaction.
  Document* = pointer
  # `Transaction` represents a set of mutations to be applied to a given
  # datastore.
  Transaction* = object
    txn: pointer
    db: SophiaDb

# `Document` constructor. Intended to be used primarily for associations.
proc newDoc[K, V](spdb: SophiaDb, k: K, v: V): Document =
  result.ckedSetV(cstring"key", cstring k, 0)
  result.ckedSetV(cstring"value", cstring v, 0)

# `Document` constructor. Intended to be used primarily for deletions.
proc newDoc[K](spdb: SophiaDb, k: K): Document =
  result.ckedSetV(cstring"key", cstring k, 0)

# Transaction constructor.
proc newTxn*(spdb: SophiaDb): Transaction =
  result = Transaction(txn: begin(spdb.env), db: spdb)
  new(TxnError).ckErrNil(result.txn, none string)

# Pushes a motion to associate the given key with the given value in the
# datastore to the transaction.
proc assoc*(txn: Transaction, doc: Document): Transaction =
  new(TxnError).ckErrno(txn.txn.set(doc), none string)
  result = txn

# Pushes a motion to delete the given key from the datastore to the transaction.
proc delete*[K](txn: Transaction, k: K): Transaction =
  let del = newDoc[K](k)
  let exn = new TxnError
  exn.ckErrNil(del, none string)
  exn.delete(del).ckErrno(none string)
  result = txn

# Attempts to persist the transaction to the datastore. Returns whether the
# database was forced to roll it back.
proc commit*(txn: Transaction): bool =
  let n = txn.txn.commit()
  new(TxnError).ckErrno(n, none string)
  n == 2

proc `=destroy`(doc: Document) =
  discard destroy(doc)
  
proc `=destroy`(spdb: SophiaDb) =
  discard spdb.driver.destroy()
  discard spdb.env.destroy()

import sophia

proc free(obj: pointer) {.importc: "free", header: "<stdio.h>"}

proc errorExit() =
  var size: cint
  var error = env.getstring("sophia.error", addr size);
  var msg = $(cast[ptr cstring](error)[])
  echo("Error: " & msg)
  free(error)
  discard env.destroy()

# Create a Sophia environment
var env = env()

# Set directory and add a db named test
discard env.setstring("sophia.path", "_test".cstring, 0)
discard env.setstring("db", "test".cstring, 0)

# Get the db
var db = env.getobject("db.test")

# Open the environment
var rc = env.open()
if (rc == -1):  errorExit()
echo "Opened Sophia env"

# Store 1 -> 42
var key = 1
var value = 42
var o = document(db)
discard o.setstring("key".cstring, addr key, sizeof(key).cint)
discard o.setstring("value".cstring, addr value, sizeof(value).cint)
rc = db.set(o);
if (rc == -1): errorExit()
echo "Stored value 42 at key 1"

# Get it back
o = document(db)
discard o.setstring("key".cstring, addr key, sizeof(key).cint)
o = db.get(o)
if (o != nil):
  # Ensure key and value are correct
  var size: cint
  var keyPointer = o.getstring("key".cstring, addr size)
  assert(size == sizeof(int))
  assert(cast[ptr int](keyPointer)[] == key)
  echo "Getting value at key " & $cast[ptr int](keyPointer)[]
  var valuePointer = o.getstring("value".cstring, addr size)
  assert(size == sizeof(int))
  assert(cast[ptr int](valuePointer)[] == value)
  echo "Yes, got " & $value & " back"
  # The following makes sure keyPointer/valuePointer are freed. I think. :)
  discard o.destroy()

# Delete it
o = document(db)
discard o.setstring("key".cstring, addr key, sizeof(key).cint)
rc = db.delete(o)
if (rc == -1): errorExit()
echo "Deleted key 1"

# Make sure its gone
o = document(db)
discard o.setstring("key".cstring, addr key, sizeof(key).cint)
o = db.get(o)
if (o != nil):
  # Ensure key and value are correct
  echo "Ehrm, it was supposed to be gone!"
  errorExit()

echo "Yup, it's gone, all good"

# Clean up
discard destroy(env)

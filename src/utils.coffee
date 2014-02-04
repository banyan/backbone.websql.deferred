# Generate four random hex digits.
S4 = ->
  (((1 + Math.random()) * 0x10000) | 0).toString(16).substring 1

# Generate a pseudo-GUID by concatenating random hexadecimal.
guid = ->
  "#{S4()}#{S4()}-#{S4()}-#{S4()}-#{S4()}-#{S4()}#{S4()}#{S4()}"

typeMap =
  number:   "INTEGER"
  string:   "TEXT"
  boolean:  "BOOLEAN"
  array:    "LIST"
  datetime: "TEXT"
  date:     "TEXT"
  object:   "TEXT"

createColDefn = (col) ->
  if col.type and (col.type not of typeMap)
    throw new Error("Unsupported type: #{col.type}")
  defn = "`#{col.name}`"
  if col.type
    if col.scale
      defn += " REAL"
    else
      defn += " #{typeMap[col.type]}"
  defn

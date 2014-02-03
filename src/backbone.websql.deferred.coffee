((root, factory) ->
  if typeof exports is "object" and typeof require is "function"
    # CommonJS
    module.exports = factory(require("underscore"), require("backbone"))
  else if typeof define is "function" and define.amd
    # AMD
    define [
      "underscore"
      "backbone"
    ], (_, Backbone) ->
      factory _ or root._, Backbone or root.Backbone
  else
    # Browser globals
    factory _, Backbone
) @, (_, Backbone) ->

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

  Backbone.WebSQL = (@db, @tableName, @columns = []) ->
    throw "Backbone.websql.deferred: Environment does not support WebSQL." unless @_isWebSQLSupported()
    colDefns = [
      "`id` unique"
      "`value`"
    ]
    colDefns = colDefns.concat @columns.map(createColDefn)
    @_executeSql "CREATE TABLE IF NOT EXISTS `#{tableName}` (#{colDefns.join(", ")});"

  Backbone.WebSQL.insertOrReplace = false

  _.extend Backbone.WebSQL.prototype,
    create: (model, doneCallback, failCallback) ->
      unless model.id
        model.id = guid()
        model.set model.idAttribute, model.id

      colNames = ["`id`", "`value`"]
      placeholders = ["?", "?"]

      params = [
        model.id.toString()
        JSON.stringify model.toJSON()
      ]

      for col in @columns
        colNames.push "`#{col.name}`"
        placeholders.push ["?"]
        params.push model.attributes[col.name]

      orReplace = if Backbone.WebSQL.insertOrReplace then "OR REPLACE" else ""
      @_executeSql "INSERT #{orReplace} INTO `#{@tableName}`(#{colNames.join(",")}) VALUES (#{placeholders.join(",")});", params

    find: (model, doneCallback, failCallback, options) ->
      @_executeSql "SELECT `id`, `value` FROM `#{@tableName}` WHERE (`id` = ?);",
        [model.id.toString()], doneCallback, failCallback, options

    findAll: (model, doneCallback, failCallback, options) ->
      params = []
      sql = "SELECT `id`, `value` FROM `#{@tableName}`"
      if options.where
        if typeof options.where is "string"
          sql += " WHERE " + options.where
        else if typeof options.where is "object"
          sql += " WHERE " + Object.keys(options.where).map((col) ->
            if _.isArray options.where[col]
              params.push options.where[col]...
              placeholders = []
              _(options.where[col].length).times -> placeholders.push '?'
              "`#{col}` IN (#{placeholders.join()})"
            else
              params.push options.where[col]
              "`#{col}` = ?"
          ).join(" AND ")
        else
          throw new Error "Unsupported where type: #{typeof options.where}"
      @_executeSql sql, params, doneCallback, failCallback, options

    update: (model, doneCallback, failCallback, options) ->
      return @create(model, doneCallback, failCallback) if Backbone.WebSQL.insertOrReplace
      stmts = ["`value` = ?"]
      params = [JSON.stringify(model.toJSON())]
      @columns.forEach (col) ->
        stmts.push "`#{col.name}` = ?"
        params.push model.attributes[col.name]
      params.push model.id.toString()

      @_executeSql "UPDATE `#{@tableName}` SET #{stmts.join(", ")} WHERE(`id` = ?);", params, ((tx, result) ->
        if result.rowsAffected is 1
          doneCallback tx, result
        else
          failCallback tx, new Error("UPDATE affected #{result.rowsAffected} rows")
      ), error, options

    destroy: (model, doneCallback, failCallback, options) ->
      @_executeSql "DELETE FROM `#{@tableName}` WHERE (`id` = ?);", [model.id.toString()], doneCallback, failCallback, options

    _isWebSQLSupported: -> !!window.openDatabase

    _executeSql: (sql, params = [], doneCallback, failCallback, options) ->
      @db.transaction (tx) ->
        tx.executeSql sql, params, doneCallback, failCallback

  Backbone.WebSQL.sync = (method, model, options) ->
    store = model.store or model.collection.store
    isSingleResult = false

    df = Backbone.$?.Deferred?()

    doneCallback = (tx, res) ->
      length = res.rows.length
      result = []
      _.times length, (i) ->
        result.push JSON.parse(res.rows.item(i).value)
      result = result[0] if isSingleResult and result.length isnt 0
      if options?.success
        if Backbone.VERSION is '0.9.10'
          options.success model, result, options
        else
          options.success result
      df?.resolve result

    failCallback = (tx, error) ->
      console.error "Backbone.websql.deferred failed: ", error, tx
      if options?.error
        if Backbone.VERSION is "0.9.10"
          options.error model, error, options
        else
          options.error error
      df?.reject error

    switch method
      when "read"
        if model.id is undefined
          store.findAll(model, doneCallback, failCallback, options)
        else
          isSingleResult = true
          store.find(model, doneCallback, failCallback, options)
      when "create"
        store.create(model, doneCallback, failCallback, options)
      when "update"
        store.update(model, doneCallback, failCallback, options)
      when "delete"
        store.destroy(model, doneCallback, failCallback, options)
      else
        throw new Error "Unsupported method: #{method}"

    df?.promise()

  Backbone.ajaxSync = Backbone.sync
  Backbone.getSyncMethod = (model) ->
    return Backbone.WebSQL.sync if model.store or (model.collection?.store)
    Backbone.ajaxSync

  Backbone.sync = (method, model, options) ->
    Backbone.getSyncMethod(model).apply @, [method, model, options]

  Backbone.WebSQL

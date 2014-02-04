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
    params = [JSON.stringify model.toJSON()]
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

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

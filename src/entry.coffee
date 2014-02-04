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

(function() {
  (function(root, factory) {
    if (typeof exports === "object" && typeof require === "function") {
      return module.exports = factory(require("underscore"), require("backbone"));
    } else if (typeof define === "function" && define.amd) {
      return define(["underscore", "backbone"], function(_, Backbone) {
        return factory(_ || root._, Backbone || root.Backbone);
      });
    } else {
      return factory(_, Backbone);
    }
  })(this, function(_, Backbone) {
    var S4, createColDefn, guid, typeMap;
    S4 = function() {
      return (((1 + Math.random()) * 0x10000) | 0).toString(16).substring(1);
    };
    guid = function() {
      return "" + (S4()) + (S4()) + "-" + (S4()) + "-" + (S4()) + "-" + (S4()) + "-" + (S4()) + (S4()) + (S4());
    };
    typeMap = {
      number: "INTEGER",
      string: "TEXT",
      boolean: "BOOLEAN",
      array: "LIST",
      datetime: "TEXT",
      date: "TEXT",
      object: "TEXT"
    };
    createColDefn = function(col) {
      var defn;
      if (col.type && (!(col.type in typeMap))) {
        throw new Error("Unsupported type: " + col.type);
      }
      defn = "`" + col.name + "`";
      if (col.type) {
        if (col.scale) {
          defn += " REAL";
        } else {
          defn += " " + typeMap[col.type];
        }
      }
      return defn;
    };
    Backbone.WebSQL = function(db, tableName, columns) {
      var colDefns;
      this.db = db;
      this.tableName = tableName;
      this.columns = columns != null ? columns : [];
      if (!this._isWebSQLSupported()) {
        throw "Backbone.websql.deferred: Environment does not support WebSQL.";
      }
      colDefns = ["`id` unique", "`value`"];
      colDefns = colDefns.concat(this.columns.map(createColDefn));
      return this._executeSql("CREATE TABLE IF NOT EXISTS `" + tableName + "` (" + (colDefns.join(", ")) + ");");
    };
    Backbone.WebSQL.insertOrReplace = false;
    _.extend(Backbone.WebSQL.prototype, {
      create: function(model, doneCallback, failCallback) {
        var col, colNames, orReplace, params, placeholders, _i, _len, _ref;
        if (!model.id) {
          model.id = guid();
          model.set(model.idAttribute, model.id);
        }
        colNames = ["`id`", "`value`"];
        placeholders = ["?", "?"];
        params = [model.id.toString(), JSON.stringify(model.toJSON())];
        _ref = this.columns;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          col = _ref[_i];
          colNames.push("`" + col.name + "`");
          placeholders.push(["?"]);
          params.push(model.attributes[col.name]);
        }
        orReplace = Backbone.WebSQL.insertOrReplace ? "OR REPLACE" : "";
        return this._executeSql("INSERT " + orReplace + " INTO `" + this.tableName + "`(" + (colNames.join(",")) + ") VALUES (" + (placeholders.join(",")) + ");", params);
      },
      find: function(model, doneCallback, failCallback, options) {
        return this._executeSql("SELECT `id`, `value` FROM `" + this.tableName + "` WHERE (`id` = ?);", [model.id.toString()], doneCallback, failCallback, options);
      },
      findAll: function(model, doneCallback, failCallback, options) {
        var params, sql;
        params = [];
        sql = "SELECT `id`, `value` FROM `" + this.tableName + "`";
        if (options.filters) {
          if (typeof options.filters === "string") {
            sql += " WHERE " + options.filters;
          } else if (typeof options.filters === "object") {
            sql += " WHERE " + Object.keys(options.filters).map(function(col) {
              var placeholders;
              if (_.isArray(options.filters[col])) {
                params.push.apply(params, options.filters[col]);
                placeholders = [];
                _(options.filters[col].length).times(function() {
                  return placeholders.push('?');
                });
                return "`" + col + "` IN (" + (placeholders.join()) + ")";
              } else {
                params.push(options.filters[col]);
                return "`" + col + "` = ?";
              }
            }).join(" AND ");
          } else {
            throw new Error("Unsupported filters type: " + (typeof options.filters));
          }
        }
        return this._executeSql(sql, params, doneCallback, failCallback, options);
      },
      update: function(model, doneCallback, failCallback, options) {
        var params, stmts;
        if (Backbone.WebSQL.insertOrReplace) {
          return this.create(model, doneCallback, failCallback);
        }
        stmts = ["`value` = ?"];
        params = [JSON.stringify(model.toJSON())];
        this.columns.forEach(function(col) {
          stmts.push("`" + col.name + "` = ?");
          return params.push(model.attributes[col.name]);
        });
        params.push(model.id.toString());
        return this._executeSql("UPDATE `" + this.tableName + "` SET " + (stmts.join(", ")) + " WHERE(`id` = ?);", params, (function(tx, result) {
          if (result.rowsAffected === 1) {
            return doneCallback(tx, result);
          } else {
            return failCallback(tx, new Error("UPDATE affected " + result.rowsAffected + " rows"));
          }
        }), error, options);
      },
      destroy: function(model, doneCallback, failCallback, options) {
        return this._executeSql("DELETE FROM `" + this.tableName + "` WHERE (`id` = ?);", [model.id.toString()], doneCallback, failCallback, options);
      },
      _isWebSQLSupported: function() {
        return !!window.openDatabase;
      },
      _executeSql: function(sql, params, doneCallback, failCallback, options) {
        if (params == null) {
          params = [];
        }
        return this.db.transaction(function(tx) {
          return tx.executeSql(sql, params, doneCallback, failCallback);
        });
      },
      _getValueFromHash: function(hash) {
        var key;
        key = _.first(_.keys(hash));
        return hash[key];
      }
    });
    Backbone.WebSQL.sync = function(method, model, options) {
      var df, doneCallback, failCallback, isSingleResult, store, _ref;
      store = model.store || model.collection.store;
      isSingleResult = false;
      df = (_ref = Backbone.$) != null ? typeof _ref.Deferred === "function" ? _ref.Deferred() : void 0 : void 0;
      doneCallback = function(tx, res) {
        var length, result;
        length = res.rows.length;
        result = [];
        _.times(length, function(i) {
          return result.push(JSON.parse(res.rows.item(i).value));
        });
        if (isSingleResult && result.length !== 0) {
          result = result[0];
        }
        if (options != null ? options.success : void 0) {
          if (Backbone.VERSION === '0.9.10') {
            options.success(model, result, options);
          } else {
            options.success(result);
          }
        }
        return df != null ? df.resolve(result) : void 0;
      };
      failCallback = function(tx, error) {
        console.error("Backbone.websql.deferred failed: ", error, tx);
        if (options != null ? options.error : void 0) {
          if (Backbone.VERSION === "0.9.10") {
            options.error(model, error, options);
          } else {
            options.error(error);
          }
        }
        return df != null ? df.reject(error) : void 0;
      };
      switch (method) {
        case "read":
          if (model.id === void 0) {
            store.findAll(model, doneCallback, failCallback, options);
          } else {
            isSingleResult = true;
            store.find(model, doneCallback, failCallback, options);
          }
          break;
        case "create":
          store.create(model, doneCallback, failCallback, options);
          break;
        case "update":
          store.update(model, doneCallback, failCallback, options);
          break;
        case "delete":
          store.destroy(model, doneCallback, failCallback, options);
          break;
        default:
          throw new Error("Unsupported method: " + method);
      }
      return df != null ? df.promise() : void 0;
    };
    Backbone.ajaxSync = Backbone.sync;
    Backbone.getSyncMethod = function(model) {
      var _ref;
      if (model.store || ((_ref = model.collection) != null ? _ref.store : void 0)) {
        return Backbone.WebSQL.sync;
      }
      return Backbone.ajaxSync;
    };
    Backbone.sync = function(method, model, options) {
      return Backbone.getSyncMethod(model).apply(this, [method, model, options]);
    };
    return Backbone.WebSQL;
  });

}).call(this);

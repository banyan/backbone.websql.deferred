# Backbone.WebSQL.Deferred

> [WebSQL](http://www.w3.org/TR/webdatabase/) adapter for Backbone with promise support

[![Build Status](https://secure.travis-ci.org/banyan/backbone.websql.deferred.png?branch=master)](http://travis-ci.org/banyan/backbone.websql.deferred)

This is a rewrite and extension of the awesome [MarrLiss/backbone-websql](https://github.com/MarrLiss/backbone-websql) plugin by @MarrLiss.

Backbone.WebSQL.Deferred is different in a way,

1. Support promise implementation ([jQuery deferred](http://api.jquery.com/category/deferred-object/) and [Q](https://github.com/kriskowal/q))
1. Don't override `Backbone.sync` totally, can be selectable as a function of each model.
1. No global pollution
1. Support Index

## Install

Download [manually](https://github.com/banyan/backbone.websql.deferred/releases) or with a package-manager.

#### [Bower](http://bower.io)

```
$ bower install --save-dev backbone.websql.deferred
```

## Usage

```coffeescript
db = openDatabase 'bb-websql', '', 'Backbone Websql Tests', 1024 * 1024

User = Backbone.Model.extend
  store: new Backbone.WebSQL(db, 'users')

Users = Backbone.Collection.extend
  model: User
  store: User::store

user = new User
  name: 'foo'

user.save().done =>
  loadUser = User.find user.get 'id'
  loadUser.fetch().done ->
    console.log loadUser.get 'name' # => 'foo'
```

## API

## Requirements

* backbone.js
* underscore.js

## Why WebSQL?

WebSQL is deprecated in 2010 by W3C, don't we use WebSQL?
First consider if you can use IndexedDB ([caniuse.com/indexeddb](http://caniuse.com/indexeddb)).
Even W3C supports IndexedDB, it's not matured yet as you see.
WebSQL is better than localStorage in terms of performance and capacity if your content is big.
WebSQL is supported by many browsers ([caniuse.com/sql-storage](http://caniuse.com/sql-storage)).
It is said that [Safari, Opera, iOS, Opera Mobile, Android Browser favour WebSQL](https://hacks.mozilla.org/2012/03/there-is-no-simple-solution-for-local-storage/).
At least Chromium team does not plan to remove WebSQL. There's no silver bullet for web storage but it's up to the environment and what makes.

## Running tests

Make sure dependencies are installed:

```
$ npm install
```

Then run:

```
$ grunt test
```

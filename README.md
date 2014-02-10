# Backbone.WebSQL.Deferred
[![Build Status](https://secure.travis-ci.org/banyan/backbone.websql.deferred.png?branch=master)](http://travis-ci.org/banyan/backbone.websql.deferred)

[WebSQL](http://www.w3.org/TR/webdatabase/) adapter for Backbone.<br />
This is a rewrite and extension of the awesome [MarrLiss/backbone-websql](https://github.com/MarrLiss/backbone-websql) plugin by @MarrLiss.

backbone.websql.deferred is different in a way,

1. Has deferred pattern support (currently only [jQuery deferred](http://api.jquery.com/category/deferred-object/))
1. Doesn't override `Backbone.sync` completely, can be selectable as a function of each model.
1. No global pollution
1. Support Index.

## Install

* via Bower

```
$ bower install backbone.websql.deferred --save-dev
```

* Just copy the `lib/backbone.websql.deferred.js` file in your project and include it in your html:

```html
<script type="text/javascript" src="backbone.js"></script>
<script type="text/javascript" src="backbone.websql.deferred.js"></script>
```

## Usage

```
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
  loaduser.fetch().done ->
    console.log loaduser.get 'name' # => 'foo'
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
[It is said that Safari, Opera, iOS, Opera Mobile, Android Browser favour WebSQL](https://hacks.mozilla.org/2012/03/there-is-no-simple-solution-for-local-storage/)).
At least Chromium team does not plan to remove WebSQL. There's no one answer but it's up to the environment and what makes.

## Development

```
$ npm install
$ grunt test
```

db = openDatabase 'bb-websql-tests', '', 'Backbone Websql Tests', 1024 * 1024

User = Backbone.Model.extend
  store: new Backbone.WebSQL db, 'users'

Users = Backbone.Collection.extend
  model: User
  store: User::store

describe 'Backbone.WebSQL', ->
  beforeEach ->
    @user = new User
      name: 'foobar'

  describe '.create', ->
    it 'should create a user and can fetch', (done) ->
      @user.save().done (=>
        fetchedUser = new User id: @user.id
        fetchedUser.fetch().done =>
          expect(fetchedUser.id).to.eq @user.id
          expect(fetchedUser.name).to.eq @user.name
        done()
      )(done)

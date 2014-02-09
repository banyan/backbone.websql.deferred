db = openDatabase 'bb-websql-tests', '', 'Backbone Websql Tests', 1024 * 1024

User = Backbone.Model.extend
  store: new Backbone.WebSQL(db, 'users')

Users = Backbone.Collection.extend
  model: User
  store: User::store

Post = Backbone.Model.extend
  store: new Backbone.WebSQL(db, 'posts', [{name: 'user_id'}])

Posts = Backbone.Collection.extend
  model: Post
  store: Post::store

KlassNoWebSQL = Backbone.Model.extend
  url: 'foo'

describe 'Backbone.WebSQL', ->
  after (done) ->
    # TODO Create drop table API?
    db.transaction (tx) =>
      for table in ['users', 'posts']
        tx.executeSql "DROP TABLE IF EXISTS #{table}"
    , (err)  -> console.error "FAIL: drop tables"
    , (resp) -> console.info  "SUCESS: drop tables"
    done()

  context 'when window.openDatabase doesnt exist', ->
    beforeEach ->
      @stub = sinon.stub(Backbone.WebSQL.prototype, '_isWebSQLSupported').returns false

    afterEach ->
      @stub.restore()

    it 'should throw an error', ->
      fn = ->
        User = Backbone.Model.extend
          store: new Backbone.WebSQL(db, 'users')

      expect(fn).to.throw('Backbone.websql.deferred: Environment does not support WebSQL.')

  describe '.create', ->
    context 'when optional column doesnt exist', ->
      beforeEach (done) ->
        @user = new User
          name: 'foobar'

        @user.save().done do (done) =>
          done()

      afterEach ->
        @user.destroy()

      it 'should create a user and can fetch', (done) ->
        fetchedUser = new User id: @user.id
        fetchedUser.fetch().done =>
          expect(fetchedUser.get 'id').to.eq @user.get 'id'
          expect(fetchedUser.get 'name').to.eq @user.get 'name'
          done()

    context 'when optional column exists', ->
      beforeEach (done) ->
        @post = new Post
          title: 'foo'
          user_id: 'bar'

        @post.save().done do (done) =>
          done()

      afterEach ->
        @post.destroy()

      it 'should create a post and can fetch by user_id (not default key)', (done) ->
        posts = new Posts
        posts.fetch(where: { user_id: @post.get('user_id') }).done (rows) =>
          expect(rows[0]['id']).to.eq @post.get 'id'
          expect(rows[0]['title']).to.eq @post.get 'title'
          expect(rows[0]['user_id']).to.eq @post.get 'user_id'
          done()

  describe '.findAll', ->
    beforeEach (done) =>
      @user1 = new User name: 'user1'
      @user2 = new User name: 'user2'
      @user3 = new User name: 'user3'

      $.when(
        _.invoke [@user1, @user2, @user3], 'save'
      ).done do (done) => done()

    afterEach (done) =>
      $.when(
        _.invoke [@user1, @user2, @user3], 'destroy'
      ).done do (done) => done()

    it 'should fetch all records', (done) =>
      users = new Users
      users.fetch().done (rows) =>
        expect(rows.length).to.eq 3
        done()

    it 'should fetch with where clawse of string', (done) =>
      users = new Users
      users.fetch(where: "id = \"#{@user1.get 'id'}\"").done (rows) =>
        expect(rows.length).to.eq 1
        expect(rows[0]['name']).to.eq 'user1'
        done()

    it 'should fetch with where in clawse by array', (done) =>
      users = new Users
      users.fetch(where: { id: [@user2.get('id'), @user3.get('id')] }).done (rows) =>
        expect(rows.length).to.eq 2
        done()

    it 'should fetch with where clawse by hash', (done) =>
      users = new Users
      users.fetch(where: { id: @user2.get('id') }).done (rows) =>
        expect(rows.length).to.eq 1
        expect(rows[0]['name']).to.eq 'user2'
        done()

  describe '.update', ->
    context 'when optional column doesnt exist', ->
      beforeEach (done) ->
        @user = new User
          name: 'foo'

        @user.save().done do (done) =>
          done()

      afterEach ->
        @user.destroy()

      it 'should update and can be fetched', (done) ->
        @user.set 'name', 'bar'
        @user.save().done =>
          fetchedUser = new User id: @user.id
          fetchedUser.fetch().done =>
            expect(fetchedUser.get 'name').to.eq 'bar'
            done()

    context 'when optional column exists', ->
      beforeEach (done) ->
        @post = new Post
          title: 'foo'
          user_id: 'bar'

        @post.save().done do (done) =>
          done()

      afterEach ->
        @post.destroy()

      it 'should update and can be fetched by optional key', (done) ->
        @post.set 'title', 'baz'
        @post.set 'user_id', 'qux'
        @post.save().done =>
          posts = new Posts
          posts.fetch(where: { user_id: @post.get('user_id') }).done (rows) =>
            expect(rows[0].title).to.eq 'baz'
            expect(rows[0].user_id).to.eq 'qux'
            done()

  describe '.destroy', ->
    beforeEach (done) =>
      @user = new User name: 'bob'
      @user.save().done do (done) =>
        done()

    it 'should be destroyed', (done) =>
      @user.destroy().done do (done) =>
        users = new Users id: @user.get 'id'
        users.fetch().done (rows) =>
          expect(rows.length).to.eq 0
          done()

  describe 'Backbone.sync', ->
    beforeEach =>
      sinon.spy(Backbone.WebSQL, "sync")
      sinon.spy(Backbone.WebSQL, "ajaxSync")

    afterEach ->
      Backbone.WebSQL.sync.restore()
      Backbone.WebSQL.ajaxSync.restore()

    context 'when store is defined in model', ->
      it 'should Backbone.WebSQL.sync is called', (done) ->
        @user = new User
          name: 'foo'

        @user.save().done do (done) =>
          expect(Backbone.WebSQL.sync.calledOnce).to.be.true
          expect(Backbone.WebSQL.ajaxSync.called).to.be.false
          done()

    context 'when store isnt defined in model', ->
      it 'should Backbone.WebSQL.ajaxSync is called', (done) ->
        foo = new KlassNoWebSQL
          name: 'foo'

        foo.save()
        expect(Backbone.WebSQL.sync.called).to.be.false
        expect(Backbone.WebSQL.ajaxSync.calledOnce).to.be.true
        done()

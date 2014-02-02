db = openDatabase 'bb-websql-tests', '', 'Backbone Websql Tests', 1024 * 1024

User = Backbone.Model.extend
  store: new Backbone.WebSQL db, 'users'

Users = Backbone.Collection.extend
  model: User
  store: User::store

Post = Backbone.Model.extend
  store: new Backbone.WebSQL db, 'posts', ['user_id']

Posts = Backbone.Collection.extend
  model: Post
  store: Post::store

describe 'Backbone.WebSQL', ->

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

      it 'should create a post and can fetch', (done) ->
        fetchedPost = new Post id: @post.id
        fetchedPost.fetch().done =>
          expect(fetchedPost.get 'id').to.eq @post.get 'id'
          expect(fetchedPost.get 'title').to.eq @post.get 'title'
          expect(fetchedPost.get 'user_id').to.eq @post.get 'user_id'
          done()

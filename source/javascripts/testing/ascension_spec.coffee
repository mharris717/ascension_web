mocha.setup('bdd')

window.onload = ->
  runner = mocha.run()

assert = chai.assert


describe "Ascension", ->
  t = setupTesting()

  describe "Game List", ->
    t.startAtRoute("games.index")

    it 'smoke', ->
      assert.equal 4,2+2

    it "has app div", ->
      assert.equal t.$("#app-div").length,1

    it "shows 1 game", ->
      assert.equal t.$("#games .game").length,2

  describe "Game Show", ->
    t.startAtRoute "game.index", App.Game.find().get('firstObject')

    it "smoke", ->
      assert.equal 4,2+2

  describe "Side", ->
    game = App.Game.find().get('firstObject')
    side = App.DynamicSide.create(rawSideNum: 1, game: game)
    t.startAtRoute "side",game,side

    it 'smoke', ->
      assert.equal 4,2+2

    it 'has hand', ->
      assert.equal t.$(".hand").length,1
      assert.equal t.$(".hand img").length,3

    it 'center cards', ->
      assert.equal t.$("#center-row img").length,6
      assert.equal t.$("#center-row .center-card").length,6
      assert.equal t.$("#center-row .engageable").length,3
      assert.equal t.$("#center-row a").length,3

    it 'acquire cards', ->
      t.$("#center-row a").eq(0).click()
      assert.equal window.lastJsonCall, "http://localhost:5100/games/undefined/acquire_card/Seer of the Forked Path"

  describe "Side with choice", ->
    game = App.Game.find().get('lastObject')
    side = App.DynamicSide.create(rawSideNum: 1, game: game)
    t.startAtRoute "side",game,side

    it 'smoke', ->
      assert.equal 4,2+2


console.debug "end of spec file"
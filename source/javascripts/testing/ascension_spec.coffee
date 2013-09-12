mocha.setup('bdd')

window.onload = ->
  runner = mocha.run()

assert = chai.assert


describe "Ascension", ->
  t = setupTesting()

  describe "Game List", ->
    beforeEach ->
      App.set "rawGames",[getGameJson()]

    t.startAtRoute("games.index")
    

    it 'smoke', ->
      assert.equal 4,2+2

    it "has app div", ->
      assert.equal t.$("#app-div").length,1

    it "shows 1 game", ->
      assert.equal t.$("#games .game").length,1

  describe "Game Show", ->
    beforeEach ->
      App.set "rawGames",[getGameJson()]

    t.startAtRoute "game.index", -> App.Game.find().get('firstObject')

    it "smoke", ->
      assert.equal 4,2+2

  describe "Side", ->
    beforeEach ->
      App.set "rawGames",[getGameJson()]

    game = -> App.Game.find().get('firstObject')
    side = -> App.DynamicSide.create(rawSideNum: 1, game: game())
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
    beforeEach ->
      App.set "rawGames",[gameJsonWithChoice()]

    game = -> App.Game.find().get('lastObject')
    side = -> App.DynamicSide.create(rawSideNum: 1, game: game())
    t.startAtRoute "side",game,side

    it 'smoke', ->
      assert.equal 4,2+2

    it 'hand cards are choosable', ->
      assert.equal t.$(".hand .choosable").length,3
      assert.equal t.$(".hand .choosable a").length,3
      assert.equal t.$(".played img").length,3

    it 'discard cards are choosable', ->
      assert.equal t.$(".my-side .discard").length,1
      assert.equal t.$(".my-side .discard a.togglex").length,1
      assert.equal t.$(".my-side .discard .card").length,1
      assert.equal t.$(".my-side .discard .card a").length,1


    it 'choose militia', ->
      t.$(".hand .choosable a").eq(0).click()
      assert.equal window.lastJsonCall,"http://localhost:5100/games/undefined/choose_option/58011415235896/5186857077315"
      #assert.equal t.$(".hand .choosable").length,0
      #assert.equal t.$(".hand img").length,2
      #assert.equal t.$(".played img").length,3

  describe "Side with center choice", ->
    beforeEach ->
      App.set "rawGames",[gameJsonAfterSeer()]

    game = -> App.Game.find().get('firstObject')
    side = -> App.DynamicSide.create(rawSideNum: 1, game: game())
    t.startAtRoute "side",game,side

    it 'smoke', ->
      assert.equal 4,2+2

    it 'center choosable', ->
      assert.equal t.$("#center-row .center-card").length,6
      assert.equal t.$("#center-row .choosable").length,6
      assert.equal t.$("#center-row .choosable a").length,6

    it "choose", ->
      t.$("#center-row .choosable a").eq(0).click()
      assert.equal window.lastJsonCall,'http://localhost:5100/games/undefined/choose_option/24537037068370/7590657689376'
      
  describe "Side with askara choice", ->
    beforeEach ->
      App.set "rawGames",[gameJsonAfterAskara()]

    game = -> App.Game.find().get('firstObject')
    side = -> App.DynamicSide.create(rawSideNum: 1, game: game())
    t.startAtRoute "side",game,side

    it 'played choosable', ->
      assert.equal t.$(".played img").length,4
      assert.equal t.$(".played .choosable").length,4

    it "choose", ->
      t.$(".played .choosable a").eq(0).click()
      assert.equal window.lastJsonCall,'http://localhost:5100/games/undefined/choose_option/33495610662945/8195553671109'

  describe "Side with hoarding tyrant", ->
    beforeEach ->
      App.set "rawGames",[gameJsonWithHoardingTyrantTrophy()]

    game = -> App.Game.find().get('firstObject')
    side = -> App.DynamicSide.create(rawSideNum: 1, game: game())
    t.startAtRoute "side",game,side

    it 'has trophy', ->
      assert.equal t.$(".trophies .card").length,1
      assert.equal t.$(".trophies .card a").length,1

    it "play trophy", ->
      t.$(".trophies .card a").eq(0).click()
      id = App.get("rawGames")[0].sides[0].trophies.cards[0].card_id
      assert.equal window.lastJsonCall,"http://localhost:5100/games/undefined/play_trophy/#{id}"



console.debug "end of spec file"
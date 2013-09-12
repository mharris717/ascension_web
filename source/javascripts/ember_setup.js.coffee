window.setupApp = ->
  Pusher.logxx = (message) ->
    if window.console && window.console.log 
      window.console.log(message)

  window.App = Em.Application.create
    shouldReload: true
    #LOG_TRANSITIONS: true
    getJSON: (a,b,c,d,e) ->
      $.getJSON(a,b,c,d,e)

  setupPusher = ->
    App.set "pusher",new Pusher('28c727618e7719053306')
  setupPusher()

  #wsUrl = "http://4uec.localtunnel.com"
  #wsUrl = "http://localhost:5150/ascension_ws"
  #wsUrl = "http://godfucker.herokuapp.com"
  wsUrl = "http://mharrisdev.com/ascension_ws"

  getRootModel = (obj) ->
    while obj && obj.get && obj.get("model")
      obj = obj.get("model")
    stillController() if obj && obj.get && obj.get("isGameController")
    obj

  App.Router.map ->
    @resource "games", ->
      @resource "foo"
    @resource "game", {path: "game/:game_id"}, ->
      @resource "side", {path: ":side_id"}

  App.IndexRodute = Em.Route.extend
    redirect: ->
      @transitionTo 'games'

  App.Game = Em.Object.extend
    setFromRaw: (resp) ->
      resp = getRootModel(resp)
      App.Game.fixRawId(resp)
      for k,v of resp
        @set k,v
      console.debug "setFromRaw initial finished"
      @hydrateCards()

    reload: ->
      console.debug "Reloading"
      App.Game.findOne(@get("id"),true).then (resp) =>
        console.debug "got resp"
        @setFromRaw(resp)
        console.debug "game#reload finished"

    hydratePlace: (place,obj) ->
      getCardsArr = (cards) ->
        if !cards
          []
        else if cards.cards
          cards.cards
        else if cards.length
          cards
        else
          []

      cards = Ember.get obj,place
      cards = getCardsArr(cards)
      if cards
        for card in cards
          base = App.cards.getCard(card.name)
          for k,v of base
            card[k] = v unless k == 'card_id'

    hydrateCards: ->
      for place in App.get("cards.gamePlaces.content")
        @hydratePlace place,this

      for place in App.get("cards.sidePlaces.content")
        for side in @get('sides')
          @hydratePlace place,side


  App.Game.reopenClass
    fixRawId: (g) ->
      id = (g["_id"] || g["mongo_id"])
      console.debug g unless id
      g["id"] = id["$oid"]

    fromRaw: (resp) ->
      @fixRawId(resp)
      res = App.Game.create(resp)
      res.hydrateCards()
      res

    find: ->
      console.debug "in game find"
      res = Em.ArrayController.create(model: [])
      $.getJSON("#{wsUrl}/games").then (resp) => 
        for g in resp
          res.pushObject(@fromRaw(g))

    findOneOld: (id,raw=false) ->
      console.debug "in game findOne"
      res = Em.ObjectController.create(model: null)
      $.getJSON("#{wsUrl}/games/#{id}").then (resp) => 
        @fixRawId(resp)
        if raw
          res.set "model",resp
        else
          g = @fromRaw(resp)
          res.set "model",g

    findOne: (id,raw=false) ->
      $.getJSON("#{wsUrl}/games/#{id}").then (resp) => 
        @fixRawId(resp)
        if raw
          resp
        else
          @fromRaw(resp)
          


  App.GamesRoute = Em.Route.extend
    model: ->
      console.debug "GamesRoute model"
      res = App.Game.find()
      #console.debug "returning from GamesRoute#model, size #{res.get('length')}"
      res

  App.GameRoute = Em.Route.extend
    model: (params) ->
      console.debug "GameRoute model"
      App.Game.findOne(params.game_id)

  App.SideRoute = Em.Route.extend
    model: (params) ->
      console.debug "SideRoute model call"
      sideNum = params.side_id
      game = @controllerFor("game")
      res = App.DynamicSide.create(rawSideNum: sideNum, gameController: game)

      if false
        setTimeout ->
          setInterval ->
            getRootModel(game).reload() if App.get('shouldReload')
          ,2000
        ,1500

      setTimeout ->
        res.setupForPusher()
      ,1000

      res

    setupController: (controller, model) ->
      console.debug "side setupController"
      @controllerFor('otherSide').set "content", model.get('otherSide')
      @controllerFor("center").set "isCurrent", true

    renderTemplate: ->
      @render 'mySide', {outlet: "mySide", controller: @get("controller")}
      #other_side = @get("controller").get('otherSide')
      #other_controller = App.SideController.create(content: other_side)
      c = @controllerFor("otherSide")
      console.debug c
      @render 'otherSide', {outlet: "otherSide", controller: c}


  App.DynamicSide = Em.ObjectController.extend
    game: (-> 
      #console.debug "Getting game, gameController is #{!!@get('gameController')}"
      @get("gameController.model")).property("gameController.model")
    sideNum: (->
      raw = @get("rawSideNum")
      if raw == 'current'
        parseInt(@get("game.current_side_index")) + 1
      else
        parseInt(raw)).property("rawSideNum","game.current_side_index")

    content: (-> 
      game = @get("game")
      return undefined unless game
      sides = game.get("sides")
      #debugger
      sides[@get("sideNum")-1]).property("game","sideNum","game.sides.@each")

    otherSide: (->
      #console.debug "otherSide call"
      other = 3 - @get("sideNum")
      res = if @get('gameController')
        App.DynamicSide.create(rawSideNum: other, gameController: @get("gameController"))
      else
        App.DynamicSide.create(rawSideNum: other, game: @get("game"))

      console.debug res
      res).property("content","game.sides.@each","sideNum","gameController","game.sides.@each.pool.runes","game.last_update_dt")


    setupForPusher: ->
      game = @get("game")
      channel = App.get('pusher').subscribe(game.get("id"))
      channel.bind "reload", (data) =>
        console.debug "got reload signal"
        if data.sideNum == @get('sideNum')
          console.debug "ignoring reload signal"
        else
          console.debug "triggering reload"
          getRootModel(game).reload()

  App.GamesController = Em.ArrayController.extend
    resetGame: ->
      $.getJSON("#{wsUrl}/reset")

    showGames: (-> true).property()

  App.GameController = Em.ObjectController.extend
    needs: "side"

    isCurrent: (->
      a = @get("controllers.side.sideNum")
      b = @get("turn_manager.current_side_index")+1
      a == b).property("controllers.side.sideNum","turn_manager.current_side_index")

    centerCards: (->
      engageableNames = _.pluck @get("engageable_cards"),"name"
      choosableCardHash = @get("controllers.side.choosableCardHash")

      _.map @get("center.cards"), (card) ->
        card.engageable = _.include engageableNames, card.name
        Ember.set card, "choosable", !!choosableCardHash[card.card_id]
        card).property("engageable_cards.@each","center.cards","controllers.side.choosableCardHash")

    constantCards: (->
      engageableNames = _.pluck @get("engageable_cards"),"name"
      _.map @get("constant_cards"), (card) ->
        card.engageable = _.include engageableNames, card.name
        card).property("engageable_cards.@each","constant_cards")

    acquireCard: (card) ->
      game = @get("model")
      id = game.get("id")

      #App.removeCard this, "centerCards", card,true
      App.getJSON("#{wsUrl}/games/#{id}/acquire_card/#{card.name}").then (resp) ->
        getRootModel(game).setFromRaw(resp)

    chooseCard: (card) ->
      side = @get("controllers.side")
      side.chooseCard card

    setFromRaw: (raw) ->
      triedToSetFromRawOnController()

    isGameController: (-> true).property()

    addCard: ->
      game = @get("model")
      id = game.get("id")
      card = @get("cardToAdd")
      sideNum = 1
      $.getJSON("#{wsUrl}/games/#{id}/#{sideNum}/add_card/#{card}").then (resp) =>
        getRootModel(game).setFromRaw(resp)
        @set "cardToAdd",""

    makeFirstSide: (->
      console.debug "in make first side"
      #App.DynamicSide.create(rawSideNum: 1, gameController: this)
      g = ->
        console.debug "in get"
        console.debug arguments
        1
      {get: g, id: 1, side_id: 1}).property()

    hasSide: (-> true).property()

  App.removeCard = (obj,cardsName,card,rep) ->
    hand = obj.get(cardsName)
    if rep
      a = _.map hand, (c) ->
        if c == card then {name: null, image_url: null} else c
    else
      a = _.filter hand, (c) -> c != card
    obj.set cardsName,a


  App.SideController = Em.ObjectController.extend
    hasSide: (-> true).property()
    isCurrent: (->
      game = @get("game")
      currentSideNum = game.get("current_side_index") + 1
      res = currentSideNum == @get("sideNum")
      res).property("game.current_side_index","sideNum")

    hasChoice: (->
      @get("choices") && @get("choices").length > 0 && @get("isCurrent")).property("choices.@each","isCurrent")


    playCard: (card) ->
      console.debug "playing #{card.name}"
      game = @get("game")
      id = game.get("id")

      App.removeCard this,"hand.cards",card

      played = @get('played')
      played.cards.pushObject(card)

      console.debug "getting fresh"
      App.getJSON("#{wsUrl}/games/#{id}/play_card/#{card.name}").then (resp) ->
        console.debug "got resp"
        getRootModel(game).setFromRaw(resp)
        console.debug "done"

    endTurn: ->
      game = @get("game")
      id = game.get("id")
      $.getJSON("#{wsUrl}/games/#{id}/advance").then (resp) ->
        getRootModel(game).setFromRaw(resp)

    showPlayAll: (->
      @get("isCurrent") && @get("hand.cards").length > 1).property("isCurrent","hand.cards.@each")

    playAll: ->
      @playCard {name: "All"}


    engageableCardNames: (->
      _.map this.engageable_cards, (c) -> c.name).property("engageable_cards","pool.runes","pool.power")

    chooseOption: (choice, card) ->
      card = {card_id: "null"} unless card
      game = @get("game")
      id = game.get("id")
      App.getJSON("#{wsUrl}/games/#{id}/choose_option/#{choice.choice_id}/#{card.card_id}").then (resp) ->
        getRootModel(game).setFromRaw(resp)

    chooseCard: (card) ->
      choice = @get('choices')[0]
      @chooseOption choice, card

    invokeAbility: (card) ->
      game = @get("game")
      id = game.get("id")
      $.getJSON("#{wsUrl}/games/#{id}/invoke_ability/#{card.card_id}").then (resp) ->
        getRootModel(game).setFromRaw(resp)

    choosableCardHash: (->
      res = {}
      if @get("choices")
        for choice in @get("choices")
          for card in choice.choosable_cards
            res[card.card_id] = true
      res).property("choices.@each.choosable_cards.@each")

    handCards: (->
      choosableCardHash = @get("choosableCardHash")
  
      _.map @get("hand.cards"), (card) ->
        if choosableCardHash[card.card_id]
          Ember.set card, "choosable", true
        card).property("hand.cards.@each","choosableCardHash")

    playedCards: (->
      choosableCardHash = @get("choosableCardHash")
    
      _.map @get("played.cards"), (card) ->
        if choosableCardHash[card.card_id]
          Ember.set card, "choosable", true
        card).property("played.cards.@each","choosableCardHash")

  App.OtherSideController = App.SideController.extend()

  App.CardController = Em.ObjectController.extend
    needs: "game"
    engageableClass: (-> "thing").property("engageable")

    isCurrent: (->
      @get('controllers.game.isCurrent')).property('controllers.game.isCurrent')

  App.DiscardController = Em.ObjectController.extend
    needs: "side"
    shouldDisplay: (-> App.get("defaultDiscardDisplay")).property()
    toggleDisplay: ->
      console.debug "toggle display"
      val = !@get('shouldDisplay')
      @set "shouldDisplay",val

    fixedCards: (->
      choosableCardHash = @get("controllers.side.choosableCardHash")

      _.map @get("cards"), (card) ->
        if choosableCardHash[card.card_id]
          Ember.set card, "choosable", true
        card).property("cards.@each","controllers.side.choosableCardHash")

  App.TrophiesController = Em.ObjectController.extend
    needs: "side"
    shouldDisplay: (-> App.get("defaultDiscardDisplay")).property()
    toggleDisplay: ->
      console.debug "toggle display"
      val = !@get('shouldDisplay')
      @set "shouldDisplay",val

    playCard: (card) ->
      game = @get("controllers.side.game")
      id = @get("controllers.side.game.id")
      App.getJSON("#{wsUrl}/games/#{id}/play_trophy/#{card.card_id}").then (resp) ->
        getRootModel(game).setFromRaw(resp)

  App.ConstructsController = Em.ObjectController.extend
    shouldDisplay: false
    toggleDisplay: ->
      val = !@get('shouldDisplay')
      @set "shouldDisplay",val

  App.CenterController = Em.ObjectController.extend
    isCurrent: true

  App.Cards = Em.Object.extend
    cards: (->
      res = {}
      App.getJSON("#{wsUrl}/cards").then (data) ->
        for card in data.cards
          res[card.name] = card
      res).property()

    getCard: (name) ->
      @get('cards')[name]

    gamePlaces: (->
      console.debug "getting gamePlaces"
      res = Em.ArrayController.create(content: ["constant_cards"])
      App.getJSON("#{wsUrl}/cards").then (data) ->
        res.pushObjects(data.places.game)
      res).property()

    sidePlaces: (->
      res = Em.ArrayController.create(content: [])
      App.getJSON("#{wsUrl}/cards").then (data) ->
        res.pushObjects(data.places.side)
      res).property()

    all: (-> 
      @get('cards')
      @get('gamePlaces')
      @get('sidePlaces')).property("cards","gamePlaces","sidePlaces")

  c = App.Cards.create()
  c.get('all')
  App.set "cards",c


  Ember.Handlebars.registerBoundHelper "displayCard", (card,options) ->
    if card.image_url != 'none'
      new Handlebars.SafeString("<img src=\"#{card.image_url}\" height=168px width=121></img>")
    else
      new Handlebars.SafeString(card.name)

setupApp()

Pusher.log = (message) ->
  if window.console && window.console.log 
    window.console.log(message)

window.App = Em.Application.create(shouldReload: true)

setupPusher = ->
  App.set "pusher",new Pusher('28c727618e7719053306')
setupPusher()

#wsUrl = "http://4uec.localtunnel.com"
wsUrl = "http://localhost:5100"
#wsUrl = "http://godfucker.herokuapp.com"

getRootModel = (obj) ->
  while obj && obj.get && obj.get("model")
    obj = obj.get("model")
  stillController() if obj && obj.get && obj.get("isGameController")
  obj

App.Router.map ->
  @resource "games", ->
    @resource "game", {path: ":game_id"}, ->
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

  reload: ->
    console.debug "Reloading"
    App.Game.findOne(@get("id"),true).then (resp) =>
      @setFromRaw(resp)


App.Game.reopenClass
  fixRawId: (g) ->
    id = (g["_id"] || g["mongo_id"])
    console.debug g unless id
    g["id"] = id["$oid"]

  fromRaw: (resp) ->
    @fixRawId(resp)
    App.Game.create(resp)

  find: ->
    res = Em.ArrayController.create(model: [])
    $.getJSON("#{wsUrl}/games").then (resp) => 
      for g in resp
        res.pushObject(@fromRaw(g))

  findOne: (id,raw=false) ->
    res = Em.ObjectController.create(model: null)
    $.getJSON("#{wsUrl}/games/#{id}").then (resp) => 
      @fixRawId(resp)
      if raw
        res.set "model",resp
      else
        g = @fromRaw(resp)
        res.set "model",g

App.GamesRoute = Em.Route.extend
  model: ->
    App.Game.find()

App.GameRoute = Em.Route.extend
  model: (params) ->
    App.Game.findOne(params.game_id)

App.SideRoute = Em.Route.extend
  model: (params) ->
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


App.DynamicSide = Em.ObjectController.extend
  game: (-> @get("gameController.model")).property("gameController.model")
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
    sides[@get("sideNum")-1]).property("game","sideNum","game.sides.@each")

  setupForPusher: ->
    game = @get("game")
    channel = App.get('pusher').subscribe(game.get("id"))
    channel.bind "reload", (data) =>
      getRootModel(game).reload() unless data.sideNum == @get('sideNum')

App.GamesController = Em.ArrayController.extend
  resetGame: ->
    $.getJSON("#{wsUrl}/reset")

  showGames: (-> true).property()

App.GameController = Em.ObjectController.extend
  centerCards: (->
    engageableNames = _.pluck @get("engageable_cards"),"name"
    _.map @get("center.cards"), (card) ->
      card.engageable = _.include engageableNames, card.name
      card).property("engageable_cards.@each","center.cards")

  constantCards: (->
    engageableNames = _.pluck @get("engageable_cards"),"name"
    _.map @get("constant_cards"), (card) ->
      card.engageable = _.include engageableNames, card.name
      card).property("engageable_cards.@each","constant_cards")

  acquireCard: (card) ->
    game = @get("model")
    id = game.get("id")
    $.getJSON("#{wsUrl}/games/#{id}/acquire_card/#{card.name}").then (resp) ->
      getRootModel(game).setFromRaw(resp)

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

App.SideController = Em.ObjectController.extend
  isCurrent: (->
    game = @get("game")
    currentSideNum = game.get("current_side_index") + 1
    res = currentSideNum == @get("sideNum")
    res).property("game.current_side_index","sideNum")

  hasChoice: (->
    @get("choices") && @get("choices").length > 0 && @get("isCurrent")).property("choices.@each","isCurrent")

  otherSide: (->
    other = 3 - @get("sideNum")
    App.DynamicSide.create(rawSideNum: other, gameController: @get("gameController"))).property("model","game.sides.@each","sideNum","gameController","game.sides.@each.pool.runes","game.last_update_dt")

  playCard: (card) ->
    console.debug "playing #{card.name}"
    game = @get("game")
    id = game.get("id")
    $.getJSON("#{wsUrl}/games/#{id}/play_card/#{card.name}").then (resp) ->
      getRootModel(game).setFromRaw(resp)

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
    $.getJSON("#{wsUrl}/games/#{id}/choose_option/#{choice.choice_id}/#{card.card_id}").then (resp) ->
      getRootModel(game).setFromRaw(resp)

  invokeAbility: (card) ->
    game = @get("game")
    id = game.get("id")
    $.getJSON("#{wsUrl}/games/#{id}/invoke_ability/#{card.card_id}").then (resp) ->
      getRootModel(game).setFromRaw(resp)

App.CardController = Em.ObjectController.extend
  engageableClass: (-> "thing").property("engageable")

App.DiscardController = Em.ObjectController.extend
  displayDiscard: false
  toggleDiscard: ->
    val = !@get('displayDiscard')
    @set "displayDiscard",val

Ember.Handlebars.registerBoundHelper "displayCard", (card,options) ->
  if card.image_url != 'none'
    new Handlebars.SafeString("<img src=\"#{card.image_url}\" height=168px width=121></img>")
  else
    new Handlebars.SafeString(card.name)

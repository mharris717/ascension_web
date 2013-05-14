setupTestingSpecific = ->
  App.Game.reopenClass
    find: ->
      #console.debug "in testing find"
      res = Em.ArrayController.create(content: [])

      game = App.Game.create(getGameJson())
      res.pushObject game

      game = App.Game.create(gameJsonWithChoice())
      res.pushObject game
      #console.debug "size #{res.get('length')}"
      res


  window.lastJsonCall = null
  App.set "getJSON", ->
    window.lastJsonCall = arguments[0]
    console.debug "json call"
    {then: ->}

window.setupTesting = ->
  res = setupTestingGeneric()
  setupTestingSpecific()
  res

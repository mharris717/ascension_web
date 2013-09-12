setupTestingSpecific = ->
  App.Game.reopenClass
    find: ->
      res = Em.ArrayController.create(content: [])

      for raw in App.get('rawGames')
        game = App.Game.create(raw)
        res.pushObject(game)

      res


  window.lastJsonCall = null
  App.set "getJSON", ->
    window.lastJsonCall = arguments[0]
    console.debug "json call"
    {then: ->}

  App.set("defaultDiscardDisplay",true)

window.setupTesting = ->
  res = setupTestingGeneric()
  setupTestingSpecific()
  res

window.gameJsonWithHoardingTyrantTrophy = ->
  res = getGameJson()
  res.sides[0].trophies = 
    cards: [{name: "Hoarding Tyrant", card_id: 12345}]
  res.sides[1].trophies = {cards: []}
  res
  
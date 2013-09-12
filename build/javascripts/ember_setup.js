(function() {

  window.setupApp = function() {
    var c, getRootModel, setupPusher, wsUrl;
    Pusher.logxx = function(message) {
      if (window.console && window.console.log) {
        return window.console.log(message);
      }
    };
    window.App = Em.Application.create({
      shouldReload: true,
      getJSON: function(a, b, c, d, e) {
        return $.getJSON(a, b, c, d, e);
      }
    });
    setupPusher = function() {
      return App.set("pusher", new Pusher('28c727618e7719053306'));
    };
    setupPusher();
    wsUrl = "http://localhost:5150/ascension_ws";
    getRootModel = function(obj) {
      while (obj && obj.get && obj.get("model")) {
        obj = obj.get("model");
      }
      if (obj && obj.get && obj.get("isGameController")) {
        stillController();
      }
      return obj;
    };
    App.Router.map(function() {
      this.resource("games", function() {
        return this.resource("foo");
      });
      return this.resource("game", {
        path: "game/:game_id"
      }, function() {
        return this.resource("side", {
          path: ":side_id"
        });
      });
    });
    App.IndexRodute = Em.Route.extend({
      redirect: function() {
        return this.transitionTo('games');
      }
    });
    App.Game = Em.Object.extend({
      setFromRaw: function(resp) {
        var k, v;
        resp = getRootModel(resp);
        App.Game.fixRawId(resp);
        for (k in resp) {
          v = resp[k];
          this.set(k, v);
        }
        console.debug("setFromRaw initial finished");
        return this.hydrateCards();
      },
      reload: function() {
        var _this = this;
        console.debug("Reloading");
        return App.Game.findOne(this.get("id"), true).then(function(resp) {
          console.debug("got resp");
          _this.setFromRaw(resp);
          return console.debug("game#reload finished");
        });
      },
      hydratePlace: function(place, obj) {
        var base, card, cards, getCardsArr, k, v, _i, _len, _results;
        getCardsArr = function(cards) {
          if (!cards) {
            return [];
          } else if (cards.cards) {
            return cards.cards;
          } else if (cards.length) {
            return cards;
          } else {
            return [];
          }
        };
        cards = Ember.get(obj, place);
        cards = getCardsArr(cards);
        if (cards) {
          _results = [];
          for (_i = 0, _len = cards.length; _i < _len; _i++) {
            card = cards[_i];
            base = App.cards.getCard(card.name);
            _results.push((function() {
              var _results1;
              _results1 = [];
              for (k in base) {
                v = base[k];
                if (k !== 'card_id') {
                  _results1.push(card[k] = v);
                } else {
                  _results1.push(void 0);
                }
              }
              return _results1;
            })());
          }
          return _results;
        }
      },
      hydrateCards: function() {
        var place, side, _i, _j, _len, _len1, _ref, _ref1, _results;
        _ref = App.get("cards.gamePlaces.content");
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          place = _ref[_i];
          this.hydratePlace(place, this);
        }
        _ref1 = App.get("cards.sidePlaces.content");
        _results = [];
        for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
          place = _ref1[_j];
          _results.push((function() {
            var _k, _len2, _ref2, _results1;
            _ref2 = this.get('sides');
            _results1 = [];
            for (_k = 0, _len2 = _ref2.length; _k < _len2; _k++) {
              side = _ref2[_k];
              _results1.push(this.hydratePlace(place, side));
            }
            return _results1;
          }).call(this));
        }
        return _results;
      }
    });
    App.Game.reopenClass({
      fixRawId: function(g) {
        var id;
        id = g["_id"] || g["mongo_id"];
        if (!id) {
          console.debug(g);
        }
        return g["id"] = id["$oid"];
      },
      fromRaw: function(resp) {
        var res;
        this.fixRawId(resp);
        res = App.Game.create(resp);
        res.hydrateCards();
        return res;
      },
      find: function() {
        var res,
          _this = this;
        console.debug("in game find");
        res = Em.ArrayController.create({
          model: []
        });
        return $.getJSON("" + wsUrl + "/games").then(function(resp) {
          var g, _i, _len, _results;
          _results = [];
          for (_i = 0, _len = resp.length; _i < _len; _i++) {
            g = resp[_i];
            _results.push(res.pushObject(_this.fromRaw(g)));
          }
          return _results;
        });
      },
      findOneOld: function(id, raw) {
        var res,
          _this = this;
        if (raw == null) {
          raw = false;
        }
        console.debug("in game findOne");
        res = Em.ObjectController.create({
          model: null
        });
        return $.getJSON("" + wsUrl + "/games/" + id).then(function(resp) {
          var g;
          _this.fixRawId(resp);
          if (raw) {
            return res.set("model", resp);
          } else {
            g = _this.fromRaw(resp);
            return res.set("model", g);
          }
        });
      },
      findOne: function(id, raw) {
        var _this = this;
        if (raw == null) {
          raw = false;
        }
        return $.getJSON("" + wsUrl + "/games/" + id).then(function(resp) {
          _this.fixRawId(resp);
          if (raw) {
            return resp;
          } else {
            return _this.fromRaw(resp);
          }
        });
      }
    });
    App.GamesRoute = Em.Route.extend({
      model: function() {
        var res;
        console.debug("GamesRoute model");
        res = App.Game.find();
        return res;
      }
    });
    App.GameRoute = Em.Route.extend({
      model: function(params) {
        console.debug("GameRoute model");
        return App.Game.findOne(params.game_id);
      }
    });
    App.SideRoute = Em.Route.extend({
      model: function(params) {
        var game, res, sideNum;
        console.debug("SideRoute model call");
        sideNum = params.side_id;
        game = this.controllerFor("game");
        res = App.DynamicSide.create({
          rawSideNum: sideNum,
          gameController: game
        });
        if (false) {
          setTimeout(function() {
            return setInterval(function() {
              if (App.get('shouldReload')) {
                return getRootModel(game).reload();
              }
            }, 2000);
          }, 1500);
        }
        setTimeout(function() {
          return res.setupForPusher();
        }, 1000);
        return res;
      },
      setupController: function(controller, model) {
        console.debug("side setupController");
        this.controllerFor('otherSide').set("content", model.get('otherSide'));
        return this.controllerFor("center").set("isCurrent", true);
      },
      renderTemplate: function() {
        var c;
        this.render('mySide', {
          outlet: "mySide",
          controller: this.get("controller")
        });
        c = this.controllerFor("otherSide");
        console.debug(c);
        return this.render('otherSide', {
          outlet: "otherSide",
          controller: c
        });
      }
    });
    App.DynamicSide = Em.ObjectController.extend({
      game: (function() {
        return this.get("gameController.model");
      }).property("gameController.model"),
      sideNum: (function() {
        var raw;
        raw = this.get("rawSideNum");
        if (raw === 'current') {
          return parseInt(this.get("game.current_side_index")) + 1;
        } else {
          return parseInt(raw);
        }
      }).property("rawSideNum", "game.current_side_index"),
      content: (function() {
        var game, sides;
        game = this.get("game");
        if (!game) {
          return void 0;
        }
        sides = game.get("sides");
        return sides[this.get("sideNum") - 1];
      }).property("game", "sideNum", "game.sides.@each"),
      otherSide: (function() {
        var other, res;
        other = 3 - this.get("sideNum");
        res = this.get('gameController') ? App.DynamicSide.create({
          rawSideNum: other,
          gameController: this.get("gameController")
        }) : App.DynamicSide.create({
          rawSideNum: other,
          game: this.get("game")
        });
        console.debug(res);
        return res;
      }).property("content", "game.sides.@each", "sideNum", "gameController", "game.sides.@each.pool.runes", "game.last_update_dt"),
      setupForPusher: function() {
        var channel, game,
          _this = this;
        game = this.get("game");
        channel = App.get('pusher').subscribe(game.get("id"));
        return channel.bind("reload", function(data) {
          console.debug("got reload signal");
          if (data.sideNum === _this.get('sideNum')) {
            return console.debug("ignoring reload signal");
          } else {
            console.debug("triggering reload");
            return getRootModel(game).reload();
          }
        });
      }
    });
    App.GamesController = Em.ArrayController.extend({
      resetGame: function() {
        return $.getJSON("" + wsUrl + "/reset");
      },
      showGames: (function() {
        return true;
      }).property()
    });
    App.GameController = Em.ObjectController.extend({
      needs: "side",
      isCurrent: (function() {
        var a, b;
        a = this.get("controllers.side.sideNum");
        b = this.get("turn_manager.current_side_index") + 1;
        return a === b;
      }).property("controllers.side.sideNum", "turn_manager.current_side_index"),
      centerCards: (function() {
        var choosableCardHash, engageableNames;
        engageableNames = _.pluck(this.get("engageable_cards"), "name");
        choosableCardHash = this.get("controllers.side.choosableCardHash");
        return _.map(this.get("center.cards"), function(card) {
          card.engageable = _.include(engageableNames, card.name);
          Ember.set(card, "choosable", !!choosableCardHash[card.card_id]);
          return card;
        });
      }).property("engageable_cards.@each", "center.cards", "controllers.side.choosableCardHash"),
      constantCards: (function() {
        var engageableNames;
        engageableNames = _.pluck(this.get("engageable_cards"), "name");
        return _.map(this.get("constant_cards"), function(card) {
          card.engageable = _.include(engageableNames, card.name);
          return card;
        });
      }).property("engageable_cards.@each", "constant_cards"),
      acquireCard: function(card) {
        var game, id;
        game = this.get("model");
        id = game.get("id");
        return App.getJSON("" + wsUrl + "/games/" + id + "/acquire_card/" + card.name).then(function(resp) {
          return getRootModel(game).setFromRaw(resp);
        });
      },
      chooseCard: function(card) {
        var side;
        side = this.get("controllers.side");
        return side.chooseCard(card);
      },
      setFromRaw: function(raw) {
        return triedToSetFromRawOnController();
      },
      isGameController: (function() {
        return true;
      }).property(),
      addCard: function() {
        var card, game, id, sideNum,
          _this = this;
        game = this.get("model");
        id = game.get("id");
        card = this.get("cardToAdd");
        sideNum = 1;
        return $.getJSON("" + wsUrl + "/games/" + id + "/" + sideNum + "/add_card/" + card).then(function(resp) {
          getRootModel(game).setFromRaw(resp);
          return _this.set("cardToAdd", "");
        });
      },
      makeFirstSide: (function() {
        var g;
        console.debug("in make first side");
        g = function() {
          console.debug("in get");
          console.debug(arguments);
          return 1;
        };
        return {
          get: g,
          id: 1,
          side_id: 1
        };
      }).property(),
      hasSide: (function() {
        return true;
      }).property()
    });
    App.removeCard = function(obj, cardsName, card, rep) {
      var a, hand;
      hand = obj.get(cardsName);
      if (rep) {
        a = _.map(hand, function(c) {
          if (c === card) {
            return {
              name: null,
              image_url: null
            };
          } else {
            return c;
          }
        });
      } else {
        a = _.filter(hand, function(c) {
          return c !== card;
        });
      }
      return obj.set(cardsName, a);
    };
    App.SideController = Em.ObjectController.extend({
      hasSide: (function() {
        return true;
      }).property(),
      isCurrent: (function() {
        var currentSideNum, game, res;
        game = this.get("game");
        currentSideNum = game.get("current_side_index") + 1;
        res = currentSideNum === this.get("sideNum");
        return res;
      }).property("game.current_side_index", "sideNum"),
      hasChoice: (function() {
        return this.get("choices") && this.get("choices").length > 0 && this.get("isCurrent");
      }).property("choices.@each", "isCurrent"),
      playCard: function(card) {
        var game, id, played;
        console.debug("playing " + card.name);
        game = this.get("game");
        id = game.get("id");
        App.removeCard(this, "hand.cards", card);
        played = this.get('played');
        played.cards.pushObject(card);
        console.debug("getting fresh");
        return App.getJSON("" + wsUrl + "/games/" + id + "/play_card/" + card.name).then(function(resp) {
          console.debug("got resp");
          getRootModel(game).setFromRaw(resp);
          return console.debug("done");
        });
      },
      endTurn: function() {
        var game, id;
        game = this.get("game");
        id = game.get("id");
        return $.getJSON("" + wsUrl + "/games/" + id + "/advance").then(function(resp) {
          return getRootModel(game).setFromRaw(resp);
        });
      },
      showPlayAll: (function() {
        return this.get("isCurrent") && this.get("hand.cards").length > 1;
      }).property("isCurrent", "hand.cards.@each"),
      playAll: function() {
        return this.playCard({
          name: "All"
        });
      },
      engageableCardNames: (function() {
        return _.map(this.engageable_cards, function(c) {
          return c.name;
        });
      }).property("engageable_cards", "pool.runes", "pool.power"),
      chooseOption: function(choice, card) {
        var game, id;
        if (!card) {
          card = {
            card_id: "null"
          };
        }
        game = this.get("game");
        id = game.get("id");
        return App.getJSON("" + wsUrl + "/games/" + id + "/choose_option/" + choice.choice_id + "/" + card.card_id).then(function(resp) {
          return getRootModel(game).setFromRaw(resp);
        });
      },
      chooseCard: function(card) {
        var choice;
        choice = this.get('choices')[0];
        return this.chooseOption(choice, card);
      },
      invokeAbility: function(card) {
        var game, id;
        game = this.get("game");
        id = game.get("id");
        return $.getJSON("" + wsUrl + "/games/" + id + "/invoke_ability/" + card.card_id).then(function(resp) {
          return getRootModel(game).setFromRaw(resp);
        });
      },
      choosableCardHash: (function() {
        var card, choice, res, _i, _j, _len, _len1, _ref, _ref1;
        res = {};
        if (this.get("choices")) {
          _ref = this.get("choices");
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            choice = _ref[_i];
            _ref1 = choice.choosable_cards;
            for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
              card = _ref1[_j];
              res[card.card_id] = true;
            }
          }
        }
        return res;
      }).property("choices.@each.choosable_cards.@each"),
      handCards: (function() {
        var choosableCardHash;
        choosableCardHash = this.get("choosableCardHash");
        return _.map(this.get("hand.cards"), function(card) {
          if (choosableCardHash[card.card_id]) {
            Ember.set(card, "choosable", true);
          }
          return card;
        });
      }).property("hand.cards.@each", "choosableCardHash"),
      playedCards: (function() {
        var choosableCardHash;
        choosableCardHash = this.get("choosableCardHash");
        return _.map(this.get("played.cards"), function(card) {
          if (choosableCardHash[card.card_id]) {
            Ember.set(card, "choosable", true);
          }
          return card;
        });
      }).property("played.cards.@each", "choosableCardHash")
    });
    App.OtherSideController = App.SideController.extend();
    App.CardController = Em.ObjectController.extend({
      needs: "game",
      engageableClass: (function() {
        return "thing";
      }).property("engageable"),
      isCurrent: (function() {
        return this.get('controllers.game.isCurrent');
      }).property('controllers.game.isCurrent')
    });
    App.DiscardController = Em.ObjectController.extend({
      needs: "side",
      shouldDisplay: (function() {
        return App.get("defaultDiscardDisplay");
      }).property(),
      toggleDisplay: function() {
        var val;
        console.debug("toggle display");
        val = !this.get('shouldDisplay');
        return this.set("shouldDisplay", val);
      },
      fixedCards: (function() {
        var choosableCardHash;
        choosableCardHash = this.get("controllers.side.choosableCardHash");
        return _.map(this.get("cards"), function(card) {
          if (choosableCardHash[card.card_id]) {
            Ember.set(card, "choosable", true);
          }
          return card;
        });
      }).property("cards.@each", "controllers.side.choosableCardHash")
    });
    App.TrophiesController = Em.ObjectController.extend({
      needs: "side",
      shouldDisplay: (function() {
        return App.get("defaultDiscardDisplay");
      }).property(),
      toggleDisplay: function() {
        var val;
        console.debug("toggle display");
        val = !this.get('shouldDisplay');
        return this.set("shouldDisplay", val);
      },
      playCard: function(card) {
        var game, id;
        game = this.get("controllers.side.game");
        id = this.get("controllers.side.game.id");
        return App.getJSON("" + wsUrl + "/games/" + id + "/play_trophy/" + card.card_id).then(function(resp) {
          return getRootModel(game).setFromRaw(resp);
        });
      }
    });
    App.ConstructsController = Em.ObjectController.extend({
      shouldDisplay: false,
      toggleDisplay: function() {
        var val;
        val = !this.get('shouldDisplay');
        return this.set("shouldDisplay", val);
      }
    });
    App.CenterController = Em.ObjectController.extend({
      isCurrent: true
    });
    App.Cards = Em.Object.extend({
      cards: (function() {
        var res;
        res = {};
        App.getJSON("" + wsUrl + "/cards").then(function(data) {
          var card, _i, _len, _ref, _results;
          _ref = data.cards;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            card = _ref[_i];
            _results.push(res[card.name] = card);
          }
          return _results;
        });
        return res;
      }).property(),
      getCard: function(name) {
        return this.get('cards')[name];
      },
      gamePlaces: (function() {
        var res;
        console.debug("getting gamePlaces");
        res = Em.ArrayController.create({
          content: ["constant_cards"]
        });
        App.getJSON("" + wsUrl + "/cards").then(function(data) {
          return res.pushObjects(data.places.game);
        });
        return res;
      }).property(),
      sidePlaces: (function() {
        var res;
        res = Em.ArrayController.create({
          content: []
        });
        App.getJSON("" + wsUrl + "/cards").then(function(data) {
          return res.pushObjects(data.places.side);
        });
        return res;
      }).property(),
      all: (function() {
        this.get('cards');
        this.get('gamePlaces');
        return this.get('sidePlaces');
      }).property("cards", "gamePlaces", "sidePlaces")
    });
    c = App.Cards.create();
    c.get('all');
    App.set("cards", c);
    return Ember.Handlebars.registerBoundHelper("displayCard", function(card, options) {
      if (card.image_url !== 'none') {
        return new Handlebars.SafeString("<img src=\"" + card.image_url + "\" height=168px width=121></img>");
      } else {
        return new Handlebars.SafeString(card.name);
      }
    });
  };

  setupApp();

}).call(this);

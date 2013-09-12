(function() {
  var assert;

  mocha.setup('bdd');

  window.onload = function() {
    var runner;
    return runner = mocha.run();
  };

  assert = chai.assert;

  describe("Ascension", function() {
    var t;
    t = setupTesting();
    describe("Game List", function() {
      beforeEach(function() {
        return App.set("rawGames", [getGameJson()]);
      });
      t.startAtRoute("games.index");
      it('smoke', function() {
        return assert.equal(4, 2 + 2);
      });
      it("has app div", function() {
        return assert.equal(t.$("#app-div").length, 1);
      });
      return it("shows 1 game", function() {
        return assert.equal(t.$("#games .game").length, 1);
      });
    });
    describe("Game Show", function() {
      beforeEach(function() {
        return App.set("rawGames", [getGameJson()]);
      });
      t.startAtRoute("game.index", function() {
        return App.Game.find().get('firstObject');
      });
      return it("smoke", function() {
        return assert.equal(4, 2 + 2);
      });
    });
    describe("Side", function() {
      var game, side;
      beforeEach(function() {
        return App.set("rawGames", [getGameJson()]);
      });
      game = function() {
        return App.Game.find().get('firstObject');
      };
      side = function() {
        return App.DynamicSide.create({
          rawSideNum: 1,
          game: game()
        });
      };
      t.startAtRoute("side", game, side);
      it('smoke', function() {
        return assert.equal(4, 2 + 2);
      });
      it('has hand', function() {
        assert.equal(t.$(".hand").length, 1);
        return assert.equal(t.$(".hand img").length, 3);
      });
      it('center cards', function() {
        assert.equal(t.$("#center-row img").length, 6);
        assert.equal(t.$("#center-row .center-card").length, 6);
        assert.equal(t.$("#center-row .engageable").length, 3);
        return assert.equal(t.$("#center-row a").length, 3);
      });
      return it('acquire cards', function() {
        t.$("#center-row a").eq(0).click();
        return assert.equal(window.lastJsonCall, "http://localhost:5100/games/undefined/acquire_card/Seer of the Forked Path");
      });
    });
    describe("Side with choice", function() {
      var game, side;
      beforeEach(function() {
        return App.set("rawGames", [gameJsonWithChoice()]);
      });
      game = function() {
        return App.Game.find().get('lastObject');
      };
      side = function() {
        return App.DynamicSide.create({
          rawSideNum: 1,
          game: game()
        });
      };
      t.startAtRoute("side", game, side);
      it('smoke', function() {
        return assert.equal(4, 2 + 2);
      });
      it('hand cards are choosable', function() {
        assert.equal(t.$(".hand .choosable").length, 3);
        assert.equal(t.$(".hand .choosable a").length, 3);
        return assert.equal(t.$(".played img").length, 3);
      });
      it('discard cards are choosable', function() {
        assert.equal(t.$(".my-side .discard").length, 1);
        assert.equal(t.$(".my-side .discard a.togglex").length, 1);
        assert.equal(t.$(".my-side .discard .card").length, 1);
        return assert.equal(t.$(".my-side .discard .card a").length, 1);
      });
      return it('choose militia', function() {
        t.$(".hand .choosable a").eq(0).click();
        return assert.equal(window.lastJsonCall, "http://localhost:5100/games/undefined/choose_option/58011415235896/5186857077315");
      });
    });
    describe("Side with center choice", function() {
      var game, side;
      beforeEach(function() {
        return App.set("rawGames", [gameJsonAfterSeer()]);
      });
      game = function() {
        return App.Game.find().get('firstObject');
      };
      side = function() {
        return App.DynamicSide.create({
          rawSideNum: 1,
          game: game()
        });
      };
      t.startAtRoute("side", game, side);
      it('smoke', function() {
        return assert.equal(4, 2 + 2);
      });
      it('center choosable', function() {
        assert.equal(t.$("#center-row .center-card").length, 6);
        assert.equal(t.$("#center-row .choosable").length, 6);
        return assert.equal(t.$("#center-row .choosable a").length, 6);
      });
      return it("choose", function() {
        t.$("#center-row .choosable a").eq(0).click();
        return assert.equal(window.lastJsonCall, 'http://localhost:5100/games/undefined/choose_option/24537037068370/7590657689376');
      });
    });
    describe("Side with askara choice", function() {
      var game, side;
      beforeEach(function() {
        return App.set("rawGames", [gameJsonAfterAskara()]);
      });
      game = function() {
        return App.Game.find().get('firstObject');
      };
      side = function() {
        return App.DynamicSide.create({
          rawSideNum: 1,
          game: game()
        });
      };
      t.startAtRoute("side", game, side);
      it('played choosable', function() {
        assert.equal(t.$(".played img").length, 4);
        return assert.equal(t.$(".played .choosable").length, 4);
      });
      return it("choose", function() {
        t.$(".played .choosable a").eq(0).click();
        return assert.equal(window.lastJsonCall, 'http://localhost:5100/games/undefined/choose_option/33495610662945/8195553671109');
      });
    });
    return describe("Side with hoarding tyrant", function() {
      var game, side;
      beforeEach(function() {
        return App.set("rawGames", [gameJsonWithHoardingTyrantTrophy()]);
      });
      game = function() {
        return App.Game.find().get('firstObject');
      };
      side = function() {
        return App.DynamicSide.create({
          rawSideNum: 1,
          game: game()
        });
      };
      t.startAtRoute("side", game, side);
      it('has trophy', function() {
        assert.equal(t.$(".trophies .card").length, 1);
        return assert.equal(t.$(".trophies .card a").length, 1);
      });
      return it("play trophy", function() {
        var id;
        t.$(".trophies .card a").eq(0).click();
        id = App.get("rawGames")[0].sides[0].trophies.cards[0].card_id;
        return assert.equal(window.lastJsonCall, "http://localhost:5100/games/undefined/play_trophy/" + id);
      });
    });
  });

  console.debug("end of spec file");

}).call(this);

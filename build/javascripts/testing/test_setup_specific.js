(function() {
  var setupTestingSpecific;

  setupTestingSpecific = function() {
    App.Game.reopenClass({
      find: function() {
        var game, raw, res, _i, _len, _ref;
        res = Em.ArrayController.create({
          content: []
        });
        _ref = App.get('rawGames');
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          raw = _ref[_i];
          game = App.Game.create(raw);
          res.pushObject(game);
        }
        return res;
      }
    });
    window.lastJsonCall = null;
    App.set("getJSON", function() {
      window.lastJsonCall = arguments[0];
      console.debug("json call");
      return {
        then: function() {}
      };
    });
    return App.set("defaultDiscardDisplay", true);
  };

  window.setupTesting = function() {
    var res;
    res = setupTestingGeneric();
    setupTestingSpecific();
    return res;
  };

}).call(this);

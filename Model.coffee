'use strict'
UtilityBelt = require './UtilityBelt'

class Model extends UtilityBelt

  @::defineProperties
    attributes:
      get: ->
        hash = {}
        hash[key] = @[key] for key in Object.keys(@)
        hash

  constructor: (atts) ->
    allAtts = {}
    allAtts[att] = ( if atts[att]? then {value: atts[att]} else {} ) for att in @attributeNames
    @defineAttributes allAtts

  @tests: (suite, assert) ->
    suite.addBatch
      '@attributes':
        topic: new class Puzzle extends Model
          constructor: ->
            @defineProperties
              nonEnumVar: {}
            @defineAttributes
              oak: {}
              fir: {}
        'should be the enumerable attributes only': (puzzle) ->
          assert.deepEqual Object.keys(puzzle.attributes).sort(), ['fir', 'oak']




module.exports = Model

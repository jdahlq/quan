'use strict'
class UtilityBelt

  defineProperty: (prop, descriptor={}) ->
    Object.defineProperty @, prop, descriptor

  defineProperties: (propHash) ->
    @defineProperty(p, d) for p, d of propHash

  defineAttribute: (prop, descriptor={}) ->
    throw "Attributes MUST be enumerable!" if descriptor.enumerable == false
    descriptor.enumerable = true
    descriptor.writable = true unless descriptor.get? || descriptor.set? || descriptor.writable?
    @defineProperty prop, descriptor

  defineAttributes: (attHash) ->
    @defineAttribute(a, d) for a, d of attHash

  writeProtect: (propOrProps) ->
    if typeof propOrProps is Array
      @defineProperty(prop, writable: false) for prop in propOrProps
    else
      @defineProperty propOrProps, writable: false


  @tests: (suite, assert) ->
    suite.addBatch
      '@definePropert(y|ies)':
        topic: new class Roo extends UtilityBelt
          @::defineProperty 'schmoo', value: 22
          @::defineProperty 'octopus', get: -> @octopusDescription
          @::defineProperties
            breakfast1:
              value: 'eggies'
              enumerable: true
            breakfast2:
              value: 'bacons'

          constructor: ->
            @octopusDescription = 'it squirts le black ink'
            @defineProperty 'pills',
              value: 'your pills, Garth'
              enumerable: true

        'should work for two args: @define(prop, descriptor)': (roo) ->
          assert.equal roo.schmoo, 22

        'should work for {prop*: {descriptor} hashes': (roo) ->
          assert.equal 'eggies', roo.breakfast1
          assert.equal 'bacons', roo.breakfast2

        'should support getters': (roo) ->
          assert.equal roo.octopusDescription, 'it squirts le black ink'
          assert.equal roo.octopus, roo.octopusDescription

        'should throw on set when set is not defined': (roo) ->
          assert.throws (-> roo.octopus = 'ostrich'), Error

        'should work for instances of the subclass (in the constructor)': (roo) ->
          assert.equal roo.pills, 'your pills, Garth'

        'should have instance enumerables': (roo) ->
          assert.deepEqual Object.keys(roo), ['octopusDescription', 'pills']

      '@defineAttribute(s)':
        topic: new class Roo extends UtilityBelt
          constructor: ->
            _width = 0
            @defineAttribute 'id', value: 5, writable: false
            @defineAttributes
              width:
                get: -> _width
                set: (val) -> _width = val
              height: {}

        'should define properties': (roo) ->
          assert.equal roo.id, 5

        'should define enumerable attributes': (roo) ->
          assert.deepEqual Object.keys(roo), ['id', 'width', 'height']

        'should work with get/set variable hiding': (roo) ->
          assert.equal roo.width, 0
          roo.width = 5
          assert.equal roo.width, 5

        'should work with @writeProtect': (roo) ->
          roo.height = 10
          roo.writeProtect 'height'

          assert.throws (-> roo.height = 15), Error
          assert.equal roo.height, 10


module.exports = UtilityBelt

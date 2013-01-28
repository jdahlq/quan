'use strict'
Model = require './Model'
sql = require 'js-sql'

# Match chars that should be followed by an underscore
CAMEL_TO_UNDERSCORE_REGEX = ///
  (
      [^A-Z0-9]               # Match lowercase/non-num...
      (?=[A-Z0-9])            # ... only if it is followed by uppercase/num
    |                       # OR
      [A-Z0-9]                # Match uppercase/num...
      (?=[A-Z0-9][^A-Z0-9])   # ... only if it is followed by uppercase/num then lowercase/non-num
  )
///g

class PersistedModel extends Model

# Prototype properties
  @::defineProperties
    tableName:
      get: ->
        @constructor.name
          .replace(CAMEL_TO_UNDERSCORE_REGEX, (m) -> "#{m}_")
          .toLowerCase() + 's'
    db:
      writable: true

  # Prototype methodss
  # ------------------

  constructor: (atts={}) ->
    return unless @attributeNames?

    vals = {}
    descriptors = {}
    changed = []
    for key in @attributeNames
      vals[key] = atts[key]
      descriptors[key] = do (key) ->
        get: -> vals[key]
        set: (val) ->
          vals[key] = val
          changed.push key

    @defineAttributes descriptors

    @defineProperties
      changedAttributes:
        get: ->
          atts = {}
          atts[key] = @[key] for key in changed
          atts
      resetChangedAttributeTracking:
        value: -> changed = []


  save: (cb) ->

    onResult = (err, res) =>
      if err?
        console.error("Oh jesus god no:", err)
        return cb(err, null)

      @id = res.rows[0].id
      console.log "Saved #{@constructor.name}##{@id}:", res
      cb(null, res)

    # If @id is present, assume the record exists in the db
    if @id?
      @db.query new sql.Query()
        .update(@tableName)
        .set(@changedAttributes)
        .where(id: @id)
        .toString()
      , onResult
      # else assume the record is new
    else
      @db.query new sql.Query()
        .insertInto(@tableName)
        .values(@attributes)
        .returning('id')
        .toString()
      , onResult

  # Class methods
  @load: (where...) ->
    @db.load @::tableName, where

  @tests: (suite, assert) ->
    suite.addBatch
      '@tableName':
        topic: new class ABCPuzzleB23ClassCd3D extends PersistedModel
        'shound be the class name, lowercase, with underscores, plural': (puzzle) ->
          assert.equal puzzle.tableName, 'abc_puzzle_b23_class_cd_3ds'

      'Attributes':
        topic: new class Puzzle extends PersistedModel
          attributeNames: ['id', 'difficulty', 'solutions']

        'should be present': (puzzle) ->
          assert.deepEqual Object.keys(puzzle.attributes), ['id', 'difficulty', 'solutions']

        'should start out unchanged (@changedAttributes should be empty)': (puzzle) ->
          assert.isEmpty puzzle.changedAttributes

        'should be reported as changed': (puzzle) ->
          puzzle.difficulty = 5
          puzzle.solutions = 'asdfweg+eoigjwe'
          assert.deepEqual puzzle.changedAttributes, {difficulty: 5, solutions: 'asdfweg+eoigjwe'}

        'should report none changed after calling resetChangedAttributeTracking()': (puzzle) ->
          puzzle.resetChangedAttributeTracking()
          assert.isEmpty puzzle.changedAttributes

module.exports = PersistedModel

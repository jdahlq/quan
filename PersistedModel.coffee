'use strict'
Model = require './Model'
sql = require 'js-sql'

class PersistedModel extends Model

# Prototype properties
  @::defineProperties
    tableName:
      get: -> camelToSnake(@constructor.name) + 's'
    db:
      writable: true

  # Prototype methodss
  # ------------------

  constructor: (atts={}) ->
    return unless @attributeNames?

    vals = {}
    descriptors = {}
    changed = []
    isNewRecord = !atts.id? # If id isn't present, assume it is a new record
    for key in @attributeNames
      if val = atts[key]
        vals[key] = val
        changed.push key if isNewRecord
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

    Object.preventExtensions @

  save: (cb) ->

    onResult = (err, res) =>
      if err?
        console.error("Oh jesus god no:", err)
        return cb(err, null)

      dbRecord = camelifyKeys res.rows[0]
      @[key] = val for key, val of dbRecord
      @resetChangedAttributeTracking()
      console.log "Saved #{@constructor.name}##{@id}:", res
      cb? null, dbRecord

    # If @id is present, assume the record exists in the db
    if @id?
      @db.query new sql.Query()
        .update(@tableName)
        .set(@changedAttributes)
        .where(id: @id)
        .returning('*')
        .toString()
      , onResult
      # else assume the record is new
    else
      @db.query new sql.Query()
        .insertInto(@tableName)
        .values(@attributes)
        .returning('*')
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
          puzzle.solutions = 'fifty'
          assert.deepEqual puzzle.changedAttributes, {difficulty: 5, solutions: 'fifty'}

        'should report none changed after calling resetChangedAttributeTracking()': (puzzle) ->
          puzzle.resetChangedAttributeTracking()
          assert.isEmpty puzzle.changedAttributes

        'should prevent extensions after construction': (puzzle) ->
          assert.throws (-> puzzle.badWolf = 'nope!'), Error

      'When Quan is configured with a db, PersistedModel':
        topic: ->
          quan = require './index'
          EventEmitter = (require 'events').EventEmitter

          queryEmitter = new class QueryEmitter extends EventEmitter
            query: (q, cb) -> @emit 'call', q, cb
          quan.configure null, queryEmitter

          class Eccentric extends PersistedModel
            attributeNames: ['id', 'name', 'lintCollection', 'smelliness']

          [
            new Eccentric name: 'Boregard', lintCollection: ['flannel', 'fleece', 'flax'], smelliness: 7/10
            queryEmitter
          ]

        'should save to @db':
          topic: ([model, queryEmitter]) ->
            queryEmitter.on 'call', (q, cb) =>
              cb null, {rows:[id:123]}
              @callback model, q
            model.save()
            return
          'with the correct query': (model, q) ->
            assert.equal q, """INSERT INTO eccentrics (id, name, lint_collection, smelliness) VALUES (DEFAULT, 'Boregard', '{"flannel", "fleece", "flax"}', 0.7) RETURNING *;"""
          'should set the returned id': (model, q) ->
            assert.equal model.id, 123

module.exports = PersistedModel

# Match chars that should be followed by an underscore
CAMEL_TO_SNAKE_REGEX = ///
  (
      [^A-Z0-9]               # Match lowercase/non-num...
      (?=[A-Z0-9])            # ... only if it is followed by uppercase/num
    |                       # OR
      [A-Z0-9]                # Match uppercase/num...
      (?=[A-Z0-9][^A-Z0-9])   # ... only if it is followed by uppercase/num then lowercase/non-num
  )
///g

SNAKE_TO_CAMEL_REGEX = /_[a-z]/gi

camelToSnake = (camelStr) ->
  camelStr
    .replace(CAMEL_TO_SNAKE_REGEX, (m) -> "#{m}_")
    .toLowerCase()

snakeToCamel = (snake_str) ->
  snake_str.toLowerCase().replace(SNAKE_TO_CAMEL_REGEX, (m) -> m[1].toUpperCase())

camelifyKeys = (snake_key_hash) ->
  camelKeyHash = {}
  camelKeyHash[snakeToCamel key] = val for key, val of snake_key_hash
  camelKeyHash

snakifyKeys = (camelKeyHash) ->
  snake_key_hash = {}
  snake_key_hash[camelToSnake key] = val for key, val of camelKeyHash
  snake_key_hash
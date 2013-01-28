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

  # Prototype methods
  save: (cb) ->

    onResult = (err, res) =>
      cb(err, res)
      return console.error("Oh jesus god no:", err) if err?

      @id = res.rows[0].id
      console.log "Saved #{@constructor.name}##{@id}:", res

    # If @id is present, assume the record exists in the db
    if @id?
      @db.query new sql.Query()
        .update(@tableName)
        .set(@attributes)
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
        'shound be the class name, lowercase, with underscores': (puzzle) ->
          assert.equal puzzle.tableName, 'abc_puzzle_b23_class_cd_3d'

module.exports = PersistedModel

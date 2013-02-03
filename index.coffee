'use strict'

quan =
  UtilityBelt:    require './UtilityBelt'
  Model:          require './Model'
  PersistedModel: require './PersistedModel'

  configure: (appConfig, db) ->
    @appConfig = appConfig
    if db?
      @PersistedModel::db = db
      @PersistedModel::writeProtect 'db'

module.exports = quan

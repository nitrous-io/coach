module.exports = (id, runtimes, lastUpdatedAt) ->
  boxer = new Object

  boxer.id = id
  boxer.runtimes = runtimes
  boxer.lastUpdatedAt = lastUpdatedAt

  boxer

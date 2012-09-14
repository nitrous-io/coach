module.exports = (id, runtimes, freeMemory, lastUpdatedAt) ->
  boxer = new Object

  boxer.id = id
  boxer.runtimes = runtimes
  boxer.freeMemory = freeMemory
  boxer.lastUpdatedAt = lastUpdatedAt

  boxer

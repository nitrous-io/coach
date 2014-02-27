module.exports = (id, runtimes, lastUpdatedAt, boxStats) ->
  boxer = new Object

  boxer.id = id
  boxer.runtimes = runtimes
  boxer.lastUpdatedAt = lastUpdatedAt
  boxer.boxStats = boxStats

  boxer

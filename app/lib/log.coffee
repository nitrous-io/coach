pad = (n) -> if n < 10 then "0" + n.toString(10) else n.toString(10)

timestamp = ->
  d = new Date()
  time = [pad(d.getHours()), pad(d.getMinutes()), pad(d.getSeconds())].join(":")
  day = [d.getFullYear(), pad(d.getMonth()+1), pad(d.getDate())].join("/")
  return [day, time].join(" ")

module.exports = () ->
  args = Array.prototype.slice.call arguments
  args.unshift timestamp()
  console.log args...



request = require 'request'

decode = require('./decoder').decode

request.get \
  {url: "http://weather.noaa.gov/pub/data/observations/metar/stations/UIII.TXT"},
  (err, resp, body) ->
    console.log body
    console.log decode(body)

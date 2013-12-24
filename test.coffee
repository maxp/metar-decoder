

async = require 'async'
request = require 'request'

decode = require('./decoder').decode

APS = [
    ["UIII", "Irkutsk"]
    ["UNBB", "Barnaul"]
    ["UIBB", "Bratsk"]
    ["UIUU", "Ulan-Ude"]
    ["ZMUB", "Ulan-Bator"]
    ["UERR", "Mirniy"]
    ["UIAA", "Chita"]
    ["UEEE", "Yakutsk"]
    ["URMM", "Minvody"]
]

async.forEachSeries APS, (ap, next) ->
    console.log ap
    request.get \
        {url: "http://weather.noaa.gov/pub/data/observations/metar/stations/"+ap[0]+".TXT"},
            (err, resp, body) ->
                console.log body
                console.log decode(body)
                console.log ""
                next()
#.
// Generated by CoffeeScript 1.4.0
(function() {
  var APS, async, decode, request;

  async = require('async');

  request = require('request');

  decode = require('./decoder').decode;

  APS = [["UIII", "Irkutsk"], ["UNBB", "Barnaul"], ["UIBB", "Bratsk"], ["UIUU", "Ulan-Ude"], ["ZMUB", "Ulan-Bator"]];

  async.forEachSeries(APS, function(ap, next) {
    console.log(ap);
    return request.get({
      url: "http://weather.noaa.gov/pub/data/observations/metar/stations/" + ap[0] + ".TXT"
    }, function(err, resp, body) {
      console.log(body);
      console.log(decode(body));
      console.log("");
      return next();
    });
  });

}).call(this);

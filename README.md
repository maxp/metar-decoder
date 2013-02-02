metar-decoder
=============

[github.com/maxp/metar-decoder](http://github.com/maxp/metar-decoder) -
CoffeeScript routine to decode METAR weather data.


Function decode(metar_string) parses METAR data
and returns following structure:

    ts: timestamp :date
    t: temperature Celsius degrees :int
    d: dew point :int (t - xx)
    p: pressure hPa (about 700-1400) :int
    q: pressure (altimeter) hPa at sea level :int
    w: wind m/s (0-100) :int
    g: wind gust m/s (0-100) :int
    b: wind bearing (0-359, VBR: 360) :int
    vis: visibility m (0-9999) :int
    cl: [clouds, vertical visibility, type]
      clouds in octas (SKC/CLR/NSC - 0, FEW - 2, SCT - 4, BKN - 7, OVC - 8) :int
      vertical visibility (m) :int
      type: CU = cumulus, CB = cumulonumbus, CI = cirrus, TCU = towering cumulus
    prw: [intencity, descriptor, precipitation, obscuration, other]
       present weather -
       http://www.ivao.aero/training/tutorials/metar/metar.htm
       http://www.wunderground.com/metarFAQ.asp
       http://ru.wikipedia.org/wiki/METAR
    icao: ICAO aeroport id
    unk: [unknown METAR token list]
    err: error message

Momentjs used for UTC date handling.
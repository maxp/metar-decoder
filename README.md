metar-decoder
=============

[github.com/maxp/metar-decoder](http://github.com/maxp/metar-decoder) -
CoffeeScript routine to decode METAR data.


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
    vid: visibility direction [N,NE,E,SE,S,SW,W,NW]
    vv: vertical visibility :int (in 30 m steps)
    cl: [clouds, vertical visibility, type]
      clouds in octas (SKC/CLR/NSC - 0, FEW - 2, SCT - 4, BKN - 7, OVC - 8) :int
      vertical visibility (m) :int
      type: CU = cumulus, CB = cumulonumbus, CI = cirrus, TCU = towering cumulus
      # ?not supported: SC - stratocumuls, AC - altocumulus
    clb: cloud base (m) :int
    prw: [intencity, descriptor, precipitation, obscuration, other]
       present weather -
       http://www.ivao.aero/training/tutorials/metar/metar.htm
       http://www.wunderground.com/metarFAQ.asp
       http://ru.wikipedia.org/wiki/METAR
    rwy: {NN: {dep:"XXXX", fc:"DD"}} - deposit and friction on each runway NN
    flg: [list of flags]
    icao: ICAO aeroport code
    unk: [unknown METAR token list]
    err: error message

Momentjs used for UTC date handling.


Additional flags (not handled yet):
    Thunderstorm RETS
    Freezing rain REFZRA
    Freezing drizzle REFZDZ
    Moderate or heavy rain RERA
    Moderate or heavy snow RESN
    Moderate or heavy drizzle REDZ
    Moderate or heavy ice pellets REPL
    Moderate or heavy snow grains RESG
    Moderate or heavy showers of rain RESHRA
    Moderate or heavy showers of snow RESHSN
    Moderate or heavy shower of small hail RESHGS
    Moderate or heavy showers of snow pellets RESHGS
    Moderate or heavy showers of hail RESHGR
    Moderate or heavy blowing snow REBLSN
    Sandstorm RESS
    Dust storm REDS
    Funnel cloud REFC
    Volcanic ash REVA

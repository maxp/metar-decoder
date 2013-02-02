#
#   metar decoder: github.com/maxp/metar-decoder
#

x = exports ? this

moment = require 'moment'

int = (s) -> parseInt(s, 10)

x.decode = (s) ->

  s = s.replace(/\n/g, " ")
  t = s.indexOf("=")
  s = s.substr(0, t) if t > -1
  tokens = s.split(" ")
  tokens.pop() if tokens[tokens.length-1] is ""

  if tokens.length < 5
    return {err: "no_data"}

  ct = 0
  ct += 1 if /^\d\d\d\d\/\d\d\/\d\d/.test tokens[ct]
  ct += 1 if /^\d\d:\d\d/.test tokens[ct]
  ct += 1 if tokens[ct] is "METAR"
  ct += 1 if tokens[ct] is "SPECI"

  icao = tokens[ct]
  if icao.length isnt 4
    return {err: "bad icao"}
  else
    ct += 1

  res = {icao: icao}

  t = tokens[ct].match /^(\d\d)(\d\d)(\d\d)Z$/
  if not t
    res.err = "invalid time"
    return res

  res.ts = moment.utc().date(t[1]).hours(t[2]).minutes(t[3])\
                    .seconds(0).milliseconds(0).toDate()
  ct += 1

  ct += 1 if tokens[ct] is "AUTO"
  ct += 1 if tokens[ct] is "COR"

  res.unk = []
  while ct < tokens.length
    if decode_std(tokens[ct], res) is "RMK"
      ct += 1
      break
    else
      ct += 1

  while ct < tokens.length
    decode_rmk(tokens[ct], res)
    ct += 1

  delete res.unk if res.unk.length is 0
  return res
#-

decode_std = (tok, res) ->

  if tok is "CAVOK"
    res.c = [0]
    res.v = 9999
    return

  if tok is "NOSIG"
    # no significant changes
    return

  if tok is "NSW"
    # no significant weather
    return

  if tok is "TEMPO" or tok is "BECMG"
    # temporary (2 hrs) data or trend
    res.flg ?= []
    res.flg.push tok
    return

  if tok is "SNOCLO"
    # aeroport closed
    res.flg ?= []
    res.flg.push tok
    return

  if tok is "RMK"
    # continue to remarks
    return "RMK"

  # Q barometer hPa
  t = tok.match /^Q(\d{3,4})$/
  if t
    res.q = int(t[1])
    return

  # temperature / dew point
  t = tok.match /^(M?\d\d)\/(M?\d\d)$/
  if t
    res.t = if t[1].charAt(0) is 'M' then -int(t[1].substring(1)) else int(t[1])
    res.d = if t[2].charAt(0) is 'M' then -int(t[2].substring(1)) else int(t[2])
    return

  # wind
  t = tok.match /^(\d{3}|VRB)(\d{2,3})(G\d{2,3})?(KT|MPS|KMH)$/
  if t
    if t[4] isnt "MPS"    # only MPS accepted, KT/KMH not handled
      res.unk.push tok
      return
    res.b = if t[1] is "VRB" then 360 else int(t[1])
    res.w = int(t[2])
    res.g = int(t[3].substring(1)) if t[3]
    return
  #

  # visibility
  t = tok.match /^(\d\d\d\d)(N|NE|E|SE|S|SW|W|NW)?$/
  if t
    res.vis = int(t[1])
    res.vid = t[2] if t[2]
    return

  # vertical visibility
  t = tok.match /^VV(\d{3}|\/{3})$/
  if t
    vv = int(t[1])
    res.vv = 30*vv if vv
    return

  t = tok.match /^(SKC|CLR|NSC|NCD|FEW|SCT|BKN|OVC)(\d{3})(CB|CI|CU|TCU)?$/
  if t
    res.c = [ switch t[1]
      when "SKC", "CLR", "NSC", "NCD" then 0
      when "FEW" then 2
      when "SCT" then 4
      when "BKN" then 7
      when "OVC" then 8
    ]
    res.c.push 30*int(t[2])
    res.c.push t[3] if t[3]
    return

  t = tok.match ///^ (\-|\+|VC)?
                  (BC|BL|DR|FZ|MI|PR|SH|TS)?
                  (DZ|RA|SN|SG|IC|PL|GR|GS|UP)?
                  (BR|FG|FU|VA|DU|SA|HZ|PY)?
                  (PO|SQ|FC|SS|DS)? $///
  if t
    res.prw = [t[1] ? '', t[2] ? '', t[3] ? '', t[4] ? '', t[5] ? '']
    return

  # not implemented:
  #
  # variable wind direction - /^(\d{3})V(\d{3})$/;
  # statute-miles visibility - /^((\d{1,2})|(\d\/\d))SM$/;
  # QNH inHg - /^A(\d{4})$/
  # runway visual range - /^R(\d\d)(R|C|L)?\/(M|P)?(\d{4})(V\d{4})?(U|D|N)?$/
  #
  # wind-shear: (WS|ALL|RWY) /^RWY(\d{2})(L|C|R)?$/;
  # runway number, left/right/center
  #
  # from:  /^FM(\d{2})(\d{2})Z?$/
  # until: /^TL(\d{2})(\d{2})Z?$/
  # at:    /^AT(\d{2})(\d{2})Z?$/
  #
  # sea: /^W(M?(\d\d))\/S(\d)/
  #   surface temperature (celsius)
  #   weaves height (m):
  #     0 - 0, 1 - 0.1, 2 - 0.5, 3 - 1.25, 4 - 2.5,
  #     5 - 4, 6 - 6, 7 - 9, 8 - 14, 9 - huge

  res.unk.push tok
  return
#-

decode_rmk = (tok, res) ->

  t = tok.match /^QBB(\d{3})$/
  if t
    # cloud base (m)
    res.clb = int(t[1])
    return

  t = tok.match /^QFE(\d\d\d(\.\d+)?)(\/\d\d\d\d)?$/
  if t
    if t[3]
      res.p = int(t[3].substring(1))
    else
      res.p = Math.round(parseFloat(t[1])*1.3332239)
    return

  t = tok.match ///^ (\d\d) (([\d/]{4}) | (CLRD)) ([\d/]{2}) $///
  if t
    res.rwy ?= {}
    res.rwy[t[1]] = if t[2] isnt "////" then {dep:t[2], fc:t[5]} else {fc:t[5]}
    return

  # RR D C DD FC
  # runway num [0..49] - left, [50..87] - right, 88 - all, 99 - repeated
  # CLRD - clear, "/" or "//" means 'not reported'
  # deposit:
  #   0 - clear, 1 - damp, 2 - wet, 3 - frost, 4 - dry snow, 5 - wet now,
  #   6 - slush, 7 - ice, 8 - rolled snow, 9 - frozen ruts
  # contamination:
  #   1 - up to 10%, 2 - 25%, 5 - 50%, 9 - 100%
  # depth of deposit:
  #   [0..90] - depth in mm,
  #   92 - 10cm, 93 - 15cm, 94 - 20cm, 95 - 25cm, 96 - 30cm, 97 - 35cm, 98 - 40cm or more,
  #   99 - non operational
  # friction coefficient:
  #   [0..90] - 0.xx,
  #   91 - poor, 92 - medim/poor, 93 - medium, 94 - medium/good, 95 - good
  #   99 - unreliable

  res.unk.push tok
  return
#-


# present weather codes (more commonly used)

x.PRW_RUS =
  VCFG: "туман на расстоянии"
  FZFG: "переохлаждённый туман"
  MIFG: "туман поземный"
  PRFG: "туман просвечивающий"
  FG:   "туман"
  BR:   "дымка"
  HZ:   "мгла"
  FU:   "дым"
  DS:   "пыльная буря"
  SS:   "песчаная буря"
  DRSA: "песчаный позёмок"
  DRDU: "пыльный позёмок"
  DU:   "пыль в воздухе (пыльная мгла)"
  DRSN: "снежный позёмок"
  BLSN: "метель"
  RASN: "дождь со снегом"
  SNRA: "снег с дождём"
  SHSN: "ливневой снег"
  SHRA: "ливневой дождь"
  DZ:   "морось"
  SG:   "снежные зёрна"
  RA:   "дождь"
  SN:   "снег"
  IC:   "ледяные иглы"
  PL:   "ледяной дождь (гололёд)"
  GS:   "ледяная крупа (гололёд)"
  FZRA: "переохлаждённый дождь (гололёд)"
  FZDZ: "переохлаждённая морось (гололёд)"
  TSRA: "гроза с дождём"
  TSGR: "гроза с градом"
  TSGS: "гроза, слабый град"
  TSSN: "гроза со снегом"
  TS:   "гроза без осадков"
  SQ:   "шквал"
  GR:   "град"
#-

#.

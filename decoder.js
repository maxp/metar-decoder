//   metar decoder: github.com/maxp/metar-decoder

(function() {
  var RWY_STATE, decode_rmk, decode_std, int, kmh_mps, kt_mps, moment, x;

  x = typeof exports !== "undefined" && exports !== null ? exports : this;

  moment = require('moment');

  int = function(s) {
    return parseInt(s, 10);
  };

  kt_mps = function(w) {
    return Math.round(w * 0.514444);
  };

  kmh_mps = function(w) {
    return Math.round(w * 0.277778);
  };

  x.decode = function(s) {
    var ct, icao, res, t, tokens, ts, ts_date, ts_time;
    s = s.replace(/\n/g, " ");
    t = s.indexOf("=");
    if (t > -1) {
      s = s.substr(0, t);
    }
    tokens = s.split(" ");
    if (tokens[tokens.length - 1] === "") {
      tokens.pop();
    }
    if (tokens.length < 5) {
      return {
        err: "no_data"
      };
    }
    ct = 0;
    ts_date = tokens[ct].match(/^(\d\d\d\d)\/(\d\d)\/(\d\d)/);
    if (!ts_date) {
      return {
        err: "no_ts"
      };
    }
    ct += 1;
    ts_time = tokens[ct].match(/^(\d\d):(\d\d)/);
    if (!ts_time) {
      return {
        err: "no_ts"
      };
    }
    ct += 1;
    ts = moment.utc(ts_date[0] + " " + ts_time[0], "YYYY/MM/DD HH:mm", true);
    if (!ts.isValid()) {
      return {
        err: "no_ts"
      };
    }
    if (tokens[ct] === "METAR") {
      ct += 1;
    }
    if (tokens[ct] === "SPECI") {
      ct += 1;
    }
    icao = tokens[ct];
    if (icao.length !== 4) {
      return {
        err: "bad icao"
      };
    } else {
      ct += 1;
    }
    res = {
      icao: icao,
      ts: ts.toDate()
    };
    t = tokens[ct].match(/^(\d\d)(\d\d)(\d\d)Z$/);
    if (!t) {
      res.err = "invalid time";
      return res;
    }
    // NOTE: compare timestamps
    // = moment.utc().date(t[1]).hours(t[2]).minutes(t[3])\
    //                  .seconds(0).milliseconds(0).toDate()
    ct += 1;
    if (tokens[ct] === "AUTO") {
      ct += 1;
    }
    if (tokens[ct] === "COR") {
      ct += 1;
    }
    res.unk = [];
    while (ct < tokens.length) {
      if (decode_std(tokens[ct], res) === "RMK") {
        ct += 1;
        break;
      } else {
        ct += 1;
      }
    }
    while (ct < tokens.length) {
      decode_rmk(tokens[ct], res);
      ct += 1;
    }
    if (res.unk.length === 0) {
      delete res.unk;
    }
    return res;
  };

  decode_std = function(tok, res) {
    var ref, ref1, ref2, ref3, ref4, t, vv, wind_conv;
    if (tok === "CAVOK") {
      res.cl = [0];
      res.vis = 9999;
      return;
    }
    if (tok === "NOSIG") {
      return;
    }
    // no significant changes
    if (tok === "NSW") {
      return;
    }
    // no significant weather
    if (RWY_STATE[tok]) {
      // runway state
      (res.flg != null ? res.flg : res.flg = []).push(tok);
      return;
    }
    if (tok === "TEMPO" || tok === "BECMG") {
      // temporary (2 hrs) data or trend
      (res.flg != null ? res.flg : res.flg = []).push(tok);
      return;
    }
    if (tok === "SNOCLO") {
      // aeroport closed
      (res.flg != null ? res.flg : res.flg = []).push(tok);
      return;
    }
    if (tok === "RMK") {
      // continue to remarks
      return "RMK";
    }
    // Q barometer hPa
    t = tok.match(/^Q(\d{3,4})$/);
    if (t) {
      res.q = int(t[1]);
      return;
    }
    // temperature / dew point
    t = tok.match(/^(M?\d\d)\/(M?\d\d)$/);
    if (t) {
      res.t = t[1].charAt(0) === 'M' ? -int(t[1].substring(1)) : int(t[1]);
      res.d = t[2].charAt(0) === 'M' ? -int(t[2].substring(1)) : int(t[2]);
      return;
    }
    // wind
    t = tok.match(/^(\d{3}|VRB)(\d{2,3})(G\d{2,3})?(KT|MPS|KMH)$/);
    if (t) {
      if (t[4] === "MPS") {
        wind_conv = int;
      }
      if (t[4] === "KT") {
        wind_conv = kt_mps;
      }
      if (t[4] === "KMH") {
        wind_conv = kmh_mps;
      }
      if (!wind_conv) {
        res.unk.push(tok);
        return;
      }
      
      res.b = t[1] === "VRB" ? 360 : int(t[1]);
      res.w = wind_conv(t[2]);
      if (t[3]) {
        res.g = wind_conv(t[3].substring(1));
      }
      return;
    }
    
    // visibility
    t = tok.match(/^(\d\d\d\d)(N|NE|E|SE|S|SW|W|NW)?$/);
    if (t) {
      res.vis = int(t[1]);
      if (t[2]) {
        res.vid = t[2];
      }
      return;
    }
    // vertical visibility
    t = tok.match(/^VV(\d{3}|\/{3})$/);
    if (t) {
      vv = int(t[1]);
      if (vv) {
        res.vv = 30 * vv;
      }
      return;
    }
    t = tok.match(/^(SKC|CLR|NSC|NCD|FEW|SCT|BKN|OVC)(\d{3})(CB|CI|CU|TCU)?$/);
    if (t) {
      res.cl = [
        (function() {
          switch (t[1]) {
          case "SKC":
          case "CLR":
          case "NSC":
          case "NCD":
            return 0;
          case "FEW":
            return 2;
          case "SCT":
            return 4;
          case "BKN":
            return 7;
          case "OVC":
            return 8;
          }
        })()
      ];
      res.cl.push(30 * int(t[2]));
      if (t[3]) {
        res.cl.push(t[3]);
      }
      return;
    }
    t = tok.match(
      /^(-|\+|VC)?(BC|BL|DR|FZ|MI|PR|SH|TS)?(DZ|RA|SN|SG|IC|PL|GR|GS|UP)?(BR|FG|FU|VA|DU|SA|HZ|PY)?(PO|SQ|FC|SS|DS)?$/
    );
    if (t) {
      res.prw = [
        (ref  = t[1]) != null ? ref  : '', 
        (ref1 = t[2]) != null ? ref1 : '', 
        (ref2 = t[3]) != null ? ref2 : '', 
        (ref3 = t[4]) != null ? ref3 : '', 
        (ref4 = t[5]) != null ? ref4 : ''
      ];
      return;
    }
    // not implemented:

    // variable wind direction - /^(\d{3})V(\d{3})$/;
    // statute-miles visibility - /^((\d{1,2})|(\d\/\d))SM$/;
    // QNH inHg - /^A(\d{4})$/
    // runway visual range - /^R(\d\d)(R|C|L)?\/(M|P)?(\d{4})(V\d{4})?(U|D|N)?$/

    // wind-shear: (WS|ALL|RWY) /^RWY(\d{2})(L|C|R)?$/;
    // runway number, left/right/center

    // from:  /^FM(\d{2})(\d{2})Z?$/
    // until: /^TL(\d{2})(\d{2})Z?$/
    // at:    /^AT(\d{2})(\d{2})Z?$/

    // sea: /^W(M?(\d\d))\/S(\d)/
    //   surface temperature (celsius)
    //   weaves height (m):
    //     0 - 0, 1 - 0.1, 2 - 0.5, 3 - 1.25, 4 - 2.5,
    //     5 - 4, 6 - 6, 7 - 9, 8 - 14, 9 - huge
    res.unk.push(tok);
  };

  //-
  decode_rmk = function(tok, res) {
    var t;
    t = tok.match(/^QBB(\d{3})$/);
    if (t) {
      // cloud base (m)
      res.clb = int(t[1]);
      return;
    }
    t = tok.match(/^QFE(\d\d\d(\.\d+)?)(\/\d\d\d\d)?$/);
    if (t) {
      if (t[3]) {
        res.p = int(t[3].substring(1));
      } else {
        res.p = Math.round(parseFloat(t[1]) * 1.3332239);
      }
      return;
    }
    t = tok.match(/^(\d\d)(([0-9/]{4})|(CLRD))([0-9/]{2})$/);
    if (t) {
      (res.rwy != null ? res.rwy : res.rwy = {})[t[1]] = t[2] !== "////" ? {
        dep: t[2],
        fc: t[5]
      } : {
        fc: t[5]
      };
      return;
    }
    // RR D C DD FC
    // runway num [0..49] - left, [50..87] - right, 88 - all, 99 - repeated
    // CLRD - clear, "/" or "//" means 'not reported'
    // deposit:
    //   0 - clear, 1 - damp, 2 - wet, 3 - frost, 4 - dry snow, 5 - wet now,
    //   6 - slush, 7 - ice, 8 - rolled snow, 9 - frozen ruts
    // contamination:
    //   1 - up to 10%, 2 - 25%, 5 - 50%, 9 - 100%
    // depth of deposit:
    //   [0..90] - depth in mm,
    //   92 - 10cm, 93 - 15cm, 94 - 20cm, 95 - 25cm, 96 - 30cm, 97 - 35cm, 98 - 40cm or more,
    //   99 - non operational
    // friction coefficient:
    //   [0..90] - 0.xx,
    //   91 - poor, 92 - medim/poor, 93 - medium, 94 - medium/good, 95 - good
    //   99 - unreliable
    res.unk.push(tok);
  };

  //-

  // present weather codes (more commonly used)
  x.PRW_RUS = {
    VCFG: "туман на расстоянии",
    FZFG: "переохлаждённый туман",
    MIFG: "туман поземный",
    PRFG: "туман просвечивающий",
    FG: "туман",
    BR: "дымка",
    HZ: "мгла",
    FU: "дым",
    DS: "пыльная буря",
    SS: "песчаная буря",
    DRSA: "песчаный позёмок",
    DRDU: "пыльный позёмок",
    DU: "пыль в воздухе (пыльная мгла)",
    DRSN: "снежный позёмок",
    BLSN: "метель",
    RASN: "дождь со снегом",
    SNRA: "снег с дождём",
    SHSN: "ливневой снег",
    SHRA: "ливневой дождь",
    DZ: "морось",
    SG: "снежные зёрна",
    RA: "дождь",
    SN: "снег",
    IC: "ледяные иглы",
    PL: "ледяной дождь (гололёд)",
    GS: "ледяная крупа (гололёд)",
    FZRA: "переохлаждённый дождь (гололёд)",
    FZDZ: "переохлаждённая морось (гололёд)",
    TSRA: "гроза с дождём",
    TSGR: "гроза с градом",
    TSGS: "гроза, слабый град",
    TSSN: "гроза со снегом",
    TS: "гроза без осадков",
    SQ: "шквал",
    GR: "град"
  };

  RWY_STATE = {
    RETS: "Thunderstorm",
    REFZRA: "Freezing rain",
    REFZDZ: "Freezing drizzle",
    RERA: "Moderate or heavy rain",
    RESN: "Moderate or heavy snow",
    REDZ: "Moderate or heavy drizzle",
    REPL: "Moderate or heavy ice pellets",
    RESG: "Moderate or heavy snow grains",
    RESHRA: "Moderate or heavy showers of rain",
    RESHSN: "Moderate or heavy showers of snow",
    RESHGS: "Moderate or heavy shower of small hail",
    // ?? RESHGS: "Moderate or heavy showers of snow pellets",
    RESHGR: "Moderate or heavy showers of hail",
    REBLSN: "Moderate or heavy blowing snow",
    RESS: "Sandstorm",
    REDS: "Dust storm",
    REFC: "Funnel cloud",
    REVA: "Volcanic ash"
  };

  x.RWY_STATE = RWY_STATE;

}).call(this);

//.

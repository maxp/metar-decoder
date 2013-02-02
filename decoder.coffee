#
#   metar/taf decoder: github.com/maxp/metar-decoder
#

x = exports ? this

moment = require 'moment'


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

int = (s) -> parseInt(s, 10)


decode_std = (tok, res) ->

  if tok is "CAVOK"
    res.c = [0]
    res.v = 9999
    return

  if tok is "NOSIG"
    # do nothing
    return

  if tok is "TEMPO"
    # do nothing
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

  t = tok.match /^(\d\d\d\d)(N|NE|E|SE|S|SW|W|NW)?$/
  if t
    res.v = int(t[1])
    # t[2] - direction not used
    return

  t = tok.match /^(SKC|CLR|NSC|FEW|SCT|BKN|OVC)(\d{3})(CB|CI|CU|TCU)?$/
  if t
    res.c = [ switch t[1]
                when "SKC", "CLR", "NSC" then 0
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

  res.unk.push tok
  return
#-

decode_rmk = (tok, res) ->
  t = tok.match /^QFE(\d\d\d)\/(\d\d\d\d)$/
  if t
    res.p = int(t[2])
    return

  t = tok.match /^(\d{8}$)/
  if t
    # runway state not handled
    return

  res.unk.push tok
  return
#-

#    // Check if token is a present weather code - The regular expression is a bit
#    // long, because several precipitation types can be joined in a token, and I
#    // don't see a better way to get all the codes.
#    var reWX =
#    if(reWX.test(token))
#    {
#        add_output("Weather............: ");
#        var myArray = reWX.exec(token);
#        for(var i=1;i<myArray.length; i++)
#        {
#            if(myArray[i] == "-") add_output("light ");
#            if(myArray[i] == "+") add_output("heavy ");
#            if(myArray[i] == "VC") add_output("in the vicinity ");
#            if(myArray[i] == "MI") add_output("shallow ");
#            if(myArray[i] == "BC") add_output("patches of ");
#            if(myArray[i] == "SH") add_output("shower(s) of ");
#            if(myArray[i] == "TS") add_output("thunderstorm ");
#            if(myArray[i] == "FZ") add_output("freezing ");
#            if(myArray[i] == "PR") add_output("partial ");
#            if(myArray[i] == "DZ") add_output("drizzle ");
#            if(myArray[i] == "RA") add_output("rain ");
#            if(myArray[i] == "SN") add_output("snow ");
#            if(myArray[i] == "SG") add_output("snow grains ");
#            if(myArray[i] == "IC") add_output("ice crystals ");
#            if(myArray[i] == "PL") add_output("ice pellets ");
#            if(myArray[i] == "GR") add_output("hail ");
#            if(myArray[i] == "GS") add_output("small hail and/or snow pellets ");
#            if(myArray[i] == "BR") add_output("mist ");
#            if(myArray[i] == "FG") add_output("fog ");
#            if(myArray[i] == "FU") add_output("smoke ");
#            if(myArray[i] == "VA") add_output("volcanic ash ");
#            if(myArray[i] == "DU") add_output("widespread dust ");
#            if(myArray[i] == "SA") add_output("sand ");
#            if(myArray[i] == "HZ") add_output("haze ");
#            if(myArray[i] == "PO") add_output("dust/sand whirls (dust devils)");
#            if(myArray[i] == "SQ") add_output("squall ");
#            if(myArray[i] == "FC") add_output("funnel cloud(s) (tornado or waterspout) ");
#            if(myArray[i] == "SS") add_output("sandstorm ");
#            if(myArray[i] == "DS") add_output("duststorm ");
#            if(myArray[i] == "DR") add_output("low drifting ");
#            if(myArray[i] == "BL") add_output("blowing ");
#        }
#        add_output("\n");  return;
#    }


#    // Check if token is "vertical visibility" indication
#    var reVV = /^VV(\d{3}|\/{3})$/;
#    if(reVV.test(token))
#    {
#        // VVddd -- ddd is vertical distance, or /// if unspecified
#        var myArray = reVV.exec(token);
#        add_output("Vertical visibility");
#        if(myArray[1] == "///")
#          add_output(" has indefinite ceiling\n");
#        else
#          add_output(": " + (100*parseInt(myArray[1],10)) + " feet\n");
#
#        return;
#    }
#
#
#    // Check if token is cloud indication
#    var reCloud = /^(FEW|SCT|BKN|OVC)(\d{3})(CB|TCU)?$/;
#    if(reCloud.test(token))
#    {
#        // Clouds: aaadddkk -- aaa indicates amount of sky covered, ddd distance over
#        //                     aerodrome level, and kk the type of cloud.
#        var myArray = reCloud.exec(token);
#        add_output("Cloud coverage.....: ");
#        if(myArray[1] == "FEW") add_output("few (1 to 2 oktas)");
#        else if(myArray[1] == "SCT") add_output("scattered (3 to 4 oktas)");
#        else if(myArray[1] == "BKN") add_output("broken (5 to 7 oktas)");
#        else if(myArray[1] == "OVC") add_output("overcast (8 oktas)");
#
#        add_output(" at " + (100*parseInt(myArray[2],10)) + " feet above aerodrome level");
#        if (myArray[3] == "CB") add_output(" cumulonimbus");
#        else if(myArray[3] == "TCU") add_output(" towering cumulus");
#
#        add_output("\n"); return;
#    }
#
#
#    // Check if token is part of a wind-shear indication
#    var reRWY = /^RWY(\d{2})(L|C|R)?$/;
#    if(token=="WS")       { add_output("there is wind-shear in "); return; }
#    else if(token=="ALL") { add_output("all "); return; }
#    else if(token=="RWY") { add_output("runways\n"); return; }
#    else if (reRWY.test(token))
#    {
#        var myArray = reRWY.exec(token);
#        add_output("runway "+myArray[1]);
#        if(myArray[2]=="L")      add_output(" Left");
#        else if(myArray[2]=="C") add_output(" Central");
#        else if(myArray[2]=="R") add_output(" Right");
#        add_output("\n");
#        return;
#    }
#
#
#    // Check if token is no-significant-weather indication
#    if(token=="NSW")
#    {
#        add_output("no significant weather\n");
#        return;
#    }
#
#
#    // Check if token is no-significant-clouds indication
#    if(token=="NSC")
#    {
#        add_output("Clouds.............: no significant clouds are observed below 5000 feet or below the minimum sector altitude (whichever is higher)\n");
#        return;
#    }
#
#
#// Check if token is part of trend indication
#    if(token=="BECMG")
#    {
#        add_output("Next 2hrs gradually:\n");
#        return;
#    }
#    if(token=="TEMPO")
#    {
#        add_output("Next 2hrs temporary:\n");
#        return;
#    }
#    var reFM = /^FM(\d{2})(\d{2})Z?$/;
#    if(reFM.test(token))
#    {
#        var myArray = reFM.exec(token);
#        add_output("From "+myArray[1]+":"+myArray[2]+" UTC.....:\n");
#        return;
#    }
#    var reTL = /^TL(\d{2})(\d{2})Z?$/;
#    if(reTL.test(token))
#    {
#        var myArray = reTL.exec(token);
#        add_output("Until "+myArray[1]+":"+myArray[2]+" UTC....:\n");
#        return;
#    }
#    var reAT = /^AT(\d{2})(\d{2})Z?$/;
#    if(reAT.test(token))
#    {
#        var myArray = reAT.exec(token);
#        add_output("At "+myArray[1]+":"+myArray[2]+" UTC.......:\n");
#        return;
#    }
#
#
#
#    // Check if item is runway state group
#    var reRSG = /^(\d\d)(\d|C|\/)(\d|L|\/)(\d\d|RD|\/)(\d\d)$/;
#    if(reRSG.test(token))
#    {
#        var myArray = reRSG.exec(token);
#        add_output("Runway state.......:");
#
#        // Runway designator (first 2 digits)
#        var r = parseInt(myArray[1],10);
#        if(r < 50) add_output(" Runway " + myArray[1] + " (or "+myArray[1]+" Left): ");
#        else if(r < 88) add_output(" Runway " + (r-50) + " Right: ");
#        else if(r == 88) add_output(" All runways: ");
#
#        // Check if "CLRD" occurs in digits 3-6
#        if(token.substr(2,4)=="CLRD") add_output("clear, ");
#        else
#        {
#          // Runway deposits (third digit)
#          if(myArray[2]=="0") add_output("clear and dry, ");
#          else if(myArray[2]=="1") add_output("damp, ");
#          else if(myArray[2]=="2") add_output("wet or water patches, ");
#          else if(myArray[2]=="3") add_output("rime or frost covered, ");
#          else if(myArray[2]=="4") add_output("dry snow, ");
#          else if(myArray[2]=="5") add_output("wet snow, ");
#          else if(myArray[2]=="6") add_output("slush, ");
#          else if(myArray[2]=="7") add_output("ice, ");
#          else if(myArray[2]=="8") add_output("compacted or rolled snow, ");
#          else if(myArray[2]=="9") add_output("frozen ruts or ridges, ");
#          else if(myArray[2]=="/") add_output("deposit not reported, ");
#
#          // Extent of runway contamination (fourth digit)
#          if(myArray[3]=="1") add_output("contamination 10% or less, ");
#          else if(myArray[3]=="2") add_output("contamination 11% to 25%, ");
#          else if(myArray[3]=="5") add_output("contamination 26% to 50%, ");
#          else if(myArray[3]=="9") add_output("contamination 51% to 100%, ");
#          else if(myArray[3]=="/") add_output("contamination not reported, ");
#
#          // Depth of deposit (fifth and sixth digits)
#          if(myArray[4]=="//") add_output("depth of deposit not reported, ");
#          else
#          {
#              var d = parseInt(myArray[4],10);
#              if(d == 0) add_output("deposit less than 1 mm deep, ");
#              else if ((d >  0) && (d < 91)) add_output("deposit is "+d+" mm deep, ");
#              else if (d == 92) add_output("deposit is 10 cm deep, ");
#              else if (d == 93) add_output("deposit is 15 cm deep, ");
#              else if (d == 94) add_output("deposit is 20 cm deep, ");
#              else if (d == 95) add_output("deposit is 25 cm deep, ");
#              else if (d == 96) add_output("deposit is 30 cm deep, ");
#              else if (d == 97) add_output("deposit is 35 cm deep, ");
#              else if (d == 98) add_output("deposit is 40 cm or more deep, ");
#              else if (d == 99) add_output("runway(s) is/are non-operational due to snow, slush, ice, large drifts or runway clearance, but depth of deposit is not reported, ");
#          }
#        }
#
#        // Friction coefficient or braking action (seventh and eighth digit)
#        if(myArray[5]=="//") add_output("braking action not reported");
#        else
#        {
#            var b = parseInt(myArray[5],10);
#            if(b<91) add_output("friction coefficient 0."+myArray[5]);
#            else
#            {
#                 if(b == 91) add_output("braking action is poor");
#                 else if(b == 92) add_output("braking action is medium/poor");
#                 else if(b == 93) add_output("braking action is medium");
#                 else if(b == 94) add_output("braking action is medium/good");
#                 else if(b == 95) add_output("braking action is good");
#                 else if(b == 99) add_output("braking action figures are unreliable");
#            }
#        }
#        add_output("\n"); return;
#    }
#
#    if(token=="SNOCLO")
#    {
#        add_output("Aerodrome is closed due to snow on runways\n");
#        return;
#    }
#
#    // Check if item is sea status indication
#    reSea = /^W(M)?(\d\d)\/S(\d)/;
#    if(reSea.test(token))
#    {
#        var myArray = reSea.exec(token);
#        add_output("Sea surface temperature: ");
#        if(myArray[1]=="M")
#            add_output("-");
#        add_output(parseInt(myArray[2],10) + " degrees Celsius\n");
#
#        add_output("Sea waves have height: ");
#        if(myArray[3]=="0") add_output("0 m (calm)\n");
#        else if(myArray[3]=="1") add_output("0-0,1 m\n");
#        else if(myArray[3]=="2") add_output("0,1-0,5 m\n");
#        else if(myArray[3]=="3") add_output("0,5-1,25 m\n");
#        else if(myArray[3]=="4") add_output("1,25-2,5 m\n");
#        else if(myArray[3]=="5") add_output("2,5-4 m\n");
#        else if(myArray[3]=="6") add_output("4-6 m\n");
#        else if(myArray[3]=="7") add_output("6-9 m\n");
#        else if(myArray[3]=="8") add_output("9-14 m\n");
#        else if(myArray[3]=="9") add_output("more than 14 m (huge!)\n");
#        return;
#    }
#}
#

#.

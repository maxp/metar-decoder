#
#   metar/taf decoder: github.com/maxp/metar-decoder
#

x = exports ? this

moment = require 'moment'

#_ = require 'underscore'
#_.str = require 'underscore.string'
#_.mixin _.str.exports()


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

  console.log ct, tokens

  icao = tokens[ct]
  if icao.length isnt 4
    return {err: "bad icao"}
  else
    ct += 1

  res = icao: icao

  t = tokens[ct].match /^(\d\d)(\d\d)(\d\d)Z$/
  if not t
    res.err = "invalid time"
    return res

  res.ts = moment.utc().date(t[1]).hours(t[2]).minutes(t[3]).toDate()
  ct += 1

  ct += 1 if tokens[ct] is "AUTO"
  ct += 1 if tokens[ct] is "COR"

  res.unk = []
  while ct < tokens.length
    if decode_token(tokens[ct], res) is "RMK"
      break
    ct += 1

  # TODO: process RMK

  delete res.unk if res.unk.length is 0
  return res
#-

decode_token = (tok, res) ->

  # wind
  t = tok.match /^(\d{3}|VRB)(\d{2,3})(G\d{2,3})?(KT|MPS|KMH)$/
  if t
    if t[4] isnt "MPS"    # only MPS accepted, KT/KMH not handled
      res.unk.push tok
      return
    res.b = if t[1] is "VRB" then 360 else parseInt(t[1])
    res.w = parseInt(t[2])
    res.g = parseInt(t[3].substring(1)) if t[3]
    return
  #

  # Q barometer hPa
  t = tok.match /^Q(\d{3,4})$/
  if t
    res.q = parseInt(t[1])
    return

  if tok is "CAVOK" or tok is "SKC"
    res.c = 0
    return

  # ? OVC
  # ? clouds

  if tok is "NOSIG"
    # do nothing ?
    return

  t = tok.match /^(M?\d\d)\/(M?\d\d)$/
  if t
    res.t = if t[1].charAt(0) is 'M' then -parseInt(t[1].substring(1)) else parseInt(t[1])
    res.d = if t[2].charAt(0) is 'M' then -parseInt(t[2].substring(1)) else parseInt(t[2])
    return

  if tok is "RMK"
    return "RMK"

  res.unk.push tok
  return
#-


#    // Check if token is "variable wind direction"
#    var reVariableWind = /^(\d{3})V(\d{3})$/;
#    if(reVariableWind.test(token))
#    {
#        // Variable wind direction: aaaVbbb, aaa and bbb are directions in clockwise order
#        add_output("Wind direction.....: variable between "+token.substr(0,3)+" and "+token.substr(4,3)+" degrees \n");
#        return;
#    }
#
#
#    // Check if token is visibility
#    var reVis = /^(\d{4})(N|S)?(E|W)?$/;
#    if(reVis.test(token))
#    {
#        var myArray = reVis.exec(token);
#        add_output("Visibility.........: ");
#        if(myArray[1]=="9999")
#          add_output("10 km or more");
#        else if (myArray[1]=="0000")
#          add_output("less than 50 m");
#        else
#          add_output(parseInt(myArray[1],10) + " m");
#
#	var dir = "";
#        if(typeof myArray[2] != "undefined")
#        {
#          dir=dir + myArray[2];
#        }
#        if(typeof myArray[3] != "undefined")
#        {
#          dir=dir + myArray[3];
#        }
#        if(dir != "")
#        {
#          add_output(" direction ");
#          if(dir=="N") add_output("North");
#          else if(dir=="NE") add_output("North East");
#          else if(dir=="E") add_output("East");
#          else if(dir=="SE") add_output("South East");
#          else if(dir=="S") add_output("South");
#          else if(dir=="SW") add_output("South West");
#          else if(dir=="W") add_output("West");
#          else if(dir=="NW") add_output("North West");
#        }
#        add_output("\n"); return;
#    }
#
#    // Check if token is Statute-Miles visibility
#     var reVisUS = /(SM)$/;
#     if(reVisUS.test(token))
#     {
#      add_output("Visibility: ");
#      var myVisArray = token.split("S");
#      add_output(myVisArray[0]);
#      add_output(" Statute Miles\n");
#    }
#
#
#    // Check if token is QNH indication in mmHg: Annnn
#    var reINHg = /A\d{4}/;
#    if(reINHg.test(token))
#    {
#        add_output("QNH: ");
#        add_output(token.substr(1,2) + "." + token.substr(3,4) + " inHg");
#        add_output("\n");  return;
#    }
#
#
#    // Check if token is runway visual range (RVR) indication
#    var reRVR = /^R(\d{2})(R|C|L)?\/(M|P)?(\d{4})(V\d{4})?(U|D|N)?$/;
#    if(reRVR.test(token))
#    {
#        var myArray = reRVR.exec(token);
#        add_output("Runway visibilty...: on runway ");
#        add_output(myArray[1]);
#        if(typeof myArray[2] != "undefined")
#        {
#          if(myArray[2]=="L") add_output(" Left");
#          else if(myArray[2]=="R") add_output(" Right");
#          else if(myArray[2]=="C") add_output(" Central");
#        }
#        add_output(", touchdown zone visual range is ");
#        if(typeof myArray[5] != "undefined")
#        {
#                 // Variable range
#            add_output("variable from a minimum of ");
#            if(myArray[3]=="P") add_output("more than ");
#            else if(myArray[3]=="M") add_output("less than ");
#            add_output(myArray[4]);
#            add_output(" meters");
#            add_output(" until a maximum of "+myArray[5].substr(1,myArray[5].length)+" meters");
#            if(myArray[5]=="P") add_output("more than ");
#
#
#        }
#        else
#        {
#          // Single value
#          if( (typeof myArray[3] != "undefined") &&
#              (typeof myArray[4] != "undefined")    )
#          {
#            if(myArray[3]=="P") add_output("more than ");
#            else if(myArray[3]=="M") add_output("less than ");
#            add_output(myArray[4]);
#            add_output(" meters");
#          }
#
#        }
#        if( (myArray.length > 5) && (typeof myArray[6] != "undefined") )
#        {
#          if(myArray[6]=="U") add_output(", and increasing");
#          else if(myArray[6]=="D") add_output(", and decreasing");
#        }
#        add_output("\n");
#        return;
#    }
#

#
#    // Check if token is a present weather code - The regular expression is a bit
#    // long, because several precipitation types can be joined in a token, and I
#    // don't see a better way to get all the codes.
#    var reWX = /^(\-|\+|)?(VC)?(MI|BC|DR|BL|SH|TS|FZ|PR)?(DZ|RA|SN|SG|IC|PL|GR|GS)?(DZ|RA|SN|SG|IC|PL|GR|GS)?(DZ|RA|SN|SG|IC|PL|GR|GS)?(DZ|RA|SN|SG|IC|PL|GR|GS)?(SH|TS|DZ|RA|SN|SG|IC|PL|GR|GS|BR|FG|FU|VA|DU|SA|HZ|PO|SQ|FC|SS|DS)$/;
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
#
#
#    // Check if token is recent weather observation
#    var reREWX = /^RE(\-|\+)?(VC)?(MI|BC|BL|DR|SH|TS|FZ|PR)?(DZ|RA|SN|SG|IC|PL|GR|GS)?(DZ|RA|SN|SG|IC|PL|GR|GS)?(DZ|RA|SN|SG|IC|PL|GR|GS)?(DZ|RA|SN|SG|IC|PL|GR|GS)?(DZ|RA|SN|SG|IC|PL|GR|GS|BR|FG|FU|VA|DU|SA|HZ|PO|SQ|FC|SS|DS)?$/;
#    if(reREWX.test(token))
#    {
#        add_output("Since the previous observation (but not at present), the following\nmeteorological phenomena were observed: ");
#        var myArray = reREWX.exec(token);
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
#            if(myArray[i] == "PO") add_output("dust/Sand whirls (dust devils) ");
#            if(myArray[i] == "SQ") add_output("squall ");
#            if(myArray[i] == "FC") add_output("funnel cloud(s) (tornado or waterspout) ");
#            if(myArray[i] == "SS") add_output("sandstorm ");
#            if(myArray[i] == "DS") add_output("duststorm ");
#            if(myArray[i] == "DR") add_output("low drifting ");
#            if(myArray[i] == "BL") add_output("blowing ");
#
#        }
#        add_output("\n"); return;
#    }
#


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

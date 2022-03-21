import jsffi

let win {.importjs: "window".}: JsObject

proc defProtoType(
  obj: auto,
  methodName: cstring,
  functionBody: auto) {.importjs: "#.prototype[#] = #".}

#-- TEST --#

#js : function testObj(){}
proc testObj() = discard

#js: testObj.say = function(){alert("I say OK ?")}
#or: testObj["say"] = function(){alert("I say OK ?")}
defProtoType(testObj, "say", proc() = win.alert("I say OK ?"))

#js: var o = new testObj()
var o = jsNew(testObj)

#js: o.say()
o.say()

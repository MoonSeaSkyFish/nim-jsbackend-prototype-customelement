import jsffi

let win {.importjs: "window".}: JsObject
let HTMLElement {.importjs: "window.HTMLElement".}: JsObject

proc defProtoType(obj: auto, methodName: cstring,
    function: auto) {.importjs: "#.prototype[#] = #".}

proc setProp(obj: auto, key, val: cstring) {.importjs: "#[#] = #".}
proc setProp(obj: auto, key: cstring,
             val: seq[cstring]) {.importjs: "#[#] = #".}

proc setPrototypeOf(objchild, objParent: auto) {.importjs: "Object.setPrototypeOf(#.prototype, #.prototype)".}

proc jsSuper(objParent: JsObject): JsObject {.importjs: "window.Reflect.construct(#, [], new.target)".}

proc setThisProp(key, val: cstring) {.importjs: "this[#] = #".}

proc getThisProp(key: cstring): cstring {.importjs: "this[#]".}

proc callThis(callKey: cstring) {.importjs: "this[#]()".}

#js: function testTag () { Reflect.construct(HTMLElement, [], new.target) }
proc testTag(): JsObject =
  jsSuper(HTMLElement)


#js: Ojbect.setPrototypeOf(testTag.prototype, HTMLElement.prototype)
setPrototypeOf(testTag, HTMLElement)

#js: testTag.prototype.connectedCallback = function(){ this.textContent = "Hello, test tag " + this.name + " " + this.age}
#or: testTag.prototype["connectedCallback"] = function(){ this["textContent"] = "Hello, test tag " + this["name"] + " " + this["age"] }
defProtoType(testTag, "connectedCallback", proc() =
  setThisProp("textContent", "Hello, test tag " &
    getThisProp("name") & " " &
    getThisProp("age")))

#js:
#testTag.prototype.attributeChangedCallback = function(name, oldValue, newValue){
#  this[name] = newValue
#  this.connectedCallback()
#}
defProtoType(testTag, "attributeChangedCallback",
             proc(name, oldValue, newValue: cstring) =
  setThisProp(name, newValue)
  callThis("connectedCallback")
)

#js:testTag["observedAttributes"] =  ["name", "age"]
setProp(testTag, "observedAttributes", @[cstring"name", cstring"age"])

#js: customElements.define("test-tag", testTag)
win.customElements.define("test-tag", testTag)




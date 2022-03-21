import jsffi

let win {.importjs: "window".}: JsObject
let HTMLElement {.importjs: "window.HTMLElement".}: JsObject

proc defProtoType(obj: auto, methodName: cstring,
    function: auto) {.importjs: "#.prototype[#] = #".}

proc setPrototypeOf(objchild, objParent: auto) {.importjs: "Object.setPrototypeOf(#.prototype, #.prototype)".}

proc jsSuper(objParent: JsObject): JsObject {.importjs: "window.Reflect.construct(#, [], new.target)".}

proc setThisProp(key, val: cstring) {.importjs: "this[#] = #".}

proc getThisProp(key: cstring): cstring {.importjs: "this[#]".}

#js: function testTag () { Reflect.construct(HTMLElement, [], new.target) }
proc testTag(): JsObject =
  jsSuper(HTMLElement)

#js: testTag.prototype.connectedCallback = function(){ this.textContent = "Hello, test tag"}
#or: testTag.prototype["connectedCallback"] = function(){ this["textContent"] = "Hello, test tag"}
defProtoType(testTag, "connectedCallback", proc() =
  setThisProp("textContent", "Hello, test tag"))

#js: Ojbect.setPrototypeOf(testTag.prototype, HTMLElement.prototype)
setPrototypeOf(testTag, HTMLElement)

#js: customElements.define("test-tag", testTag)
win.customElements.define("test-tag", testTag)


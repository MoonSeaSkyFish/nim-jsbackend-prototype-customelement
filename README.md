# Function.prototype and Custom elements on nim's jsbackend

## Function.prototype

```html
<script src="prototype.js"></script>
```

```cmd
% nim js prototype.js
```
open html.

### Guid?

```javascript
function testObj(){}
testObj.prototype.say = function(){alert("I say ok?")}
var o = new testObj()
o.say()
```

From this js sample to nim. 

```nim
import jsffi

let win {.importjs: "window".}: JsObject

proc defProtoType(
  obj: auto,
  methodName: cstring,
  functionBody: auto) {.importjs: "#.prototype[#] = #".}

proc testObj() = discard

defProtoType(testObj, "say", proc() = win.alert("I say OK ?"))

var o = jsNew(testObj)

o.say()
```

## Custom Elements

```javascript
class testTag extends HTMLElement{
  constructor(){
    super()
  }
  connectedCallback(){
    this.textContent = "Hello, test tag"
  }
}
customElements.define("test-tag", testTag)
```

```html
<script src="FILENAME.js"></script>
<test-tag></test-tag>
```

Open html, printed "Hello, test tag".

No use class semantic on js. This used prototype.

```javascript
function testTag(){
  // This is same super()
  return  Reflect.construct(HTMLElement, [], new.target)
}
Object.setPrototypeOf(testTag.prototype, HTMLElement.prototype)
testTag.prototype.connectedCallback = function(){ this.textContent = "Hello, test tag"}
customElements.define("test-tag", testTag)
```

From this js sample to nim. 

```nim
import jsffi

let win {.importjs: "window".}:JsObject
let HTMLElement {.importjs: "window.HTMLElement".}: JsObject

proc defProtoType(obj: auto, methodName: cstring,
    function: auto) {.importjs: "#.prototype[#] = #".}

proc setPrototypeOf(objchild, objParent: auto) {.importjs: "Object.setPrototypeOf(#.prototype, #.prototype)".}

proc jsSuper(objParent: JsObject): JsObject {.importjs: "window.Reflect.construct(#, [], new.target)".}

proc setThisProp(key, val: cstring) {.importjs: "this[#] = #".}

proc getThisProp(key: cstring): cstring {.importjs: "this[#]".}

proc testTag():JsObject = 
  jsSuper(HTMLElement)

defProtoType(testTag, "connectedCallback", proc() =
  setThisProp("textContent", "Hello, test tag"))

setPrototypeOf(testTag, HTMLElement)

win.customElements.define("test-tag", testTag)
```

```cmd
% nim js ...
```

Open html, printed "Hello, test tag".



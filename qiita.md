# Function.prototype and Custom elements on nim's jsbackend

## Function.prototype

document.registerElementは廃止になったので注意。変わりにwindow.customElements.defineを使う。


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
  // super()
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


## 参考サイト
- https://www.tohoho-web.com/ex/custom-elements.html

簡単なカスタムエレメントの説明が書かれている。

- https://github.com/zacharycarter/litz
- https://github.com/zacharycarter/nes

実際に使うのは、下のnesなのですが、nesからlitzをimport しているため注意が必要。
また、下記の ast_pattern_matching を利用しているのでインストールが必要。ASTをパターン検索してくれるので、macro作るならあると便利そう。

- https://github.com/krux02/ast-pattern-matching


- https://gist.github.com/bketelsen/69a2344fcb9807e22c5dac2e5182bc52

「Karax + Litz = Web Components in Nim」とあるとおり、litzとnesとkaraxの簡単なサンプル。

- https://github.com/WICG/webcomponents/issues/587

classを使わないで、prototypeのみで、カスタムエレメントを作る方法についてのgithubのissue。


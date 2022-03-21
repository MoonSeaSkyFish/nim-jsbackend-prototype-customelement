# nimでカスタムエレメントを作れるかがんばってみた、疲れた

## まず、1.5までなんだって

nim の javascriptの対応バージョンは、1.5まででそれ以降は対応予定はないそうです。
なのでES6で登場したclass構文には、対応することはないようです。

まずは、nimでjavascriptのprototypeでのオブジェクトの作成の方法を紹介します。

javascriptで書くと以下のものです。

```javascript
function testObj(){}
testObj.prototype.say = function(){alert("I say ok?")}
var o = new testObj()
o.say()
```

で……これをnimで記述するのに悩みました。
クラスじゃん？ type xxx = object of JsObject とかで書くと思ったわけですよ。
で、うまくいかず悩んでいたら、ふと、functionなんだから、procでいけるんじゃね？
と思ったらうまくいきました、という話です。

さて、nimに上のコードを置き換えたものが下記のものです。

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

いやあ、importjs 便利すぎです。

{.importjs: "#.prototype[#] = #".}

こんな、= で結んだ構文にまで利用可能とは驚きでした。

ここも悩んだ末、たどり着きました。

aaa.prototype.bbb = function(){}

これのaaaはprocの名前わたすからいけるけれど、bbbの部分はどうやって渡すのよ？ で、javascriptのこれって、["bbb"]と同じだって思い出したわけです。それでbbbの部分には文字列を渡すことにしました。

↓ここね。

```nim
proc defProtoType(
  obj: auto,
  methodName: cstring,
  functionBody: auto) {.importjs: "#.prototype[#] = #".}
```

あとは、特に説明はいらないはず！

では、次にカスタムエレメント！

## カスタムエレメント - custome element

よくあるサンプルは下のようなものでしょうか。

```javascript
class testTag extends HTMLElement{
  constructor(){
    super() // カスタムエレメントでは必須!
  }
  connectedCallback(){
    this.textContent = "Hello, test tag"
  }
}
customElements.define("test-tag", testTag)
```

これをhtmlで、下のようにかけば、「Hello, test tag」と表示されるという仕組みですね。

```html
<test-tag></test-tag>
```
でも、nimでclass構文に置換する方法は……emitプラグマを使えば可能ですが、まあ、それはやりたくない。

javascriptですから、class構文ではなく、prototypeで作る方法があるのでは？ と調査した結果、下記の方法でいけることがわかりました。

```javascript
function testTag(){
  // ↓これは class構文のコンストラクタ内のsuper()と同じもの
  return  Reflect.construct(HTMLElement, [], new.target)
}
Object.setPrototypeOf(testTag.prototype, HTMLElement.prototype)
testTag.prototype.connectedCallback = function(){ this.textContent = "Hello, test tag"}
customElements.define("test-tag", testTag)
```

そう、これを、上のprototypeで行った方法でnimに置き換えてあげればいい！ その結果が下記のコードです。

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

とりあえず、thisの呼び方がわからないので、setThisPropとかしてます。

こんなところでしょうか。

かなり基本的な部分ですが、ここからは、さほど難しくない…と思いますが、プロパティとかの実現方法は調査中です。わかったら追記しますね。

## おまけ

標準の htmlgenのコードをみると……

```nim
macro abbr*(e: varargs[untyped]): untyped =
  ## Generates the HTML `abbr` element.
  result = xmlCheckedTag(e, "abbr", commonAttr)
```

とあります。これを真似れば独自タグをhtmlgenと同じように扱えるじゃありませんか。xmlCheckedTagには、*がついていますし。

```nim
macro testTag*(e: varargs[untyped]): untyped =
  result = xmlCheckedTag(e, "test-tag", commonAttr)
```

これで、

```nim
body(testTag("おはー"), p("おはじゃねーよ"))
```

とか書くことが可能になります。追加のattributeは、aタグを参考にしましょう。

```nim
macro a*(e: varargs[untyped]): untyped =
  ## Generates the HTML `a` element.
  result = xmlCheckedTag(e, "a", "href target download rel hreflang type " &
    commonAttr)
```

え？ karax ? karaxは今勉強中です。

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


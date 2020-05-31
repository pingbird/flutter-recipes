---
title: IntelliJ Observatory
parent: FAQ
---

# IntelliJ Observatory

The Flutter plugin removed the ability to open the observatory, this is quite annoying.

Here is a tampermonkey script that puts an observatory button on the top right of DevTools:

```js
// ==UserScript==
// @name         DevTools Observatory button
// @namespace    https://me.tst.sh/
// @version      0.1
// @description  try to take over the world!
// @author       ping
// @match        http://127.0.0.1:*/?ide=*
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    function getQueryVariable(variable) {
        var query = window.location.search.substring(1);
        var vars = query.split('&');
        for (var i = 0; i < vars.length; i++) {
            var pair = vars[i].split('=');
            if (decodeURIComponent(pair[0]) == variable) {
                return decodeURIComponent(pair[1]);
            }
        }
        console.log('Query variable %s not found', variable);
    }

    var uri = getQueryVariable("uri");

    console.log("Observatory url: " + uri);

    document.querySelector("#try-flutter-web-devtools").parentElement.insertAdjacentHTML(
        'beforeend',
        '<div class="masthead-item action-button active" id="open-observatory" title="Open Observatory"><span class="octicon octicon-clock"></span></div>'
    );

    var openObservatory = document.querySelector("#open-observatory");

    openObservatory.onclick = function () {
        location.href = uri;
    }
})();
```
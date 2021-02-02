---
title: IntelliJ Observatory
parent: FAQ
---

# IntelliJ Observatory

The Flutter plugin removed the ability to open the observatory, this is quite annoying.

Here is a tampermonkey script that puts an observatory button on the top left of DevTools:

```js
// ==UserScript==
// @name         DevTools Observatory button
// @namespace    https://me.tst.sh/
// @version      0.2
// @description  try to take over the world!
// @author       ping
// @include      /^http:\/\/127\.0\.0\.1:\d+.*$/
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    if (document.title != "Dart DevTools") {
        return;
    }

    var pattern = /[&\?]uri=(http[^&]+)/;

    var uri = decodeURIComponent(decodeURIComponent(pattern.exec(window.location.href)[1])) + "/#/vm";

    console.log("Observatory url: " + uri);

    var observatoryButton = document.createElement("div");

    observatoryButton.style.cssText = "position: absolute; left: 160px; top: 8px; background-color: #505050; padding: 10px; border-radius: 4px; cursor: pointer";
    observatoryButton.innerText = "⏱️";

    document.body.appendChild(observatoryButton);

    observatoryButton.onclick = function () {
        location.href = uri;
    }
})();
```
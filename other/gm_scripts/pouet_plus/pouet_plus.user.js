// ==UserScript==
// @name           Pouet Plus
// @namespace      PP
// @description    Preview screenshots straight from the prods search by hovering over links.
// @include        http://pouet.net/*
// @include        http://www.pouet.net/*
// ==/UserScript==

var bg_color = "#EAEAEA";
var border_color = "#D5D5D5";

function locate(event) {
	var posx, posy;
	var d = find_div();
	if (d) {
		posx = event.clientX + window.pageXOffset;
		posy = event.clientY + window.pageYOffset;
		d.style.top = (posy - 23) + "px";
		d.style.left = (posx + 15) + "px";
	}
}

function find_div() {
	return document.getElementById("link_tt");
}

function create_div(event,elem) {
	var tt_div = document.createElement("div");
	tt_div.setAttribute("id", "link_tt");
	tt_div.setAttribute("style", "background:" + bg_color + ";border:1px solid " + border_color + ";padding:2px;position:absolute;z-index:1000;");
	var tt_image = new Image();
	var demo_num = elem.href.replace(/.*?which=([0-9]*).*/,'$1');
	tt_image.src = "screenshots/"+demo_num+".jpg";
	tryOtherExtensionsIfNeeded(tt_image,demo_num,["gif","png"]);
	tt_div.appendChild(tt_image);
	tt_image.parentNode.style.display = 'none';
	document.body.appendChild(tt_div);
	locate(event);
}

function tryOtherExtensionsIfNeeded(tt_image,demo_num,imageTypes) {
	tt_image.addEventListener("error",function(){
		if (imageTypes.length == 0) {
			GM_log("We have run out of image types to try!");
		} else {
			var ext = imageTypes.pop();
			GM_log("Trying: screenshots/"+demo_num+"."+ext);
			tt_image.src = "screenshots/"+demo_num+"."+ext;
		}
	},false);
	tt_image.addEventListener("load",function(){
		tt_image.parentNode.style.display = '';
	},false);
}

function kill_window() {
	if (find_div())
		find_div().parentNode.removeChild(find_div());
}

var timer = null;
function resetTimeout(fn) {
	if (timer)
		clearTimeout(timer);
		timer = null;
	if (fn)
		timer = setTimeout(fn,300);
}

function create_event(elem) {
	elem.addEventListener("mouseover", function(event) { resetTimeout(function(){ create_div(event,elem); }); }, false);
	elem.addEventListener("mouseout", function() { resetTimeout(null); kill_window(); }, false);
	elem.addEventListener("mousemove", function(event) { locate(event); }, true);
}

var links = document.getElementsByTagName("a");
for (i = 0; i < links.length; i++) {
	if (
			links[i].href.indexOf("/prod.php?which=")>=0     // Yes if this links points to a prod.
		&& links[i].href.indexOf("&howmanycomments=")==-1   // But not if it's pointing to a specific comments page.
	) {
		create_event(links[i]);
	}
}


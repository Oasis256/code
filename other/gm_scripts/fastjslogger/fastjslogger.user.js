// ==UserScript==
// @name           FastJSLogger
// @namespace      FastJSLogger
// @description    Intercepts console.log calls to display log messages in a div floating on the page.  Tries to be a replacement for normal browser Error Consoles (which can be a little slow to open).
// @include        *
// ==/UserScript==



// Options (may or may not be exposed as global).
var FJSL = {
	autoHide:    true,
	logTimeouts: false,
	logEvents:   true,            // Log any activity over the wrapped listeners.
	logCommonMouseEvents: false,  // These can be triggered a lot!
	logChangesToGlobal:   true,   // Logs any new properties which are added to window

	watchWindowForErrors: true,   // Catches and reports DOM error events, including syntax errors from scripts loaded later, and missing images.  BUG: It can hide the line number from Chrome's console - sometimes worth disabling to get that back.
	interceptTimeouts:    true,   // Wraps calls to setTimeout, so any errors thrown may be reported.
	interceptEvents:      true,   // Wraps any listeners registered later, so errors can be caught and reported.

	displaySearchFilter:  false,  // This messes up the size of the textbox on Firefox and Konqueror but not Chrome.

	// Hack to avoid infinite loops.  Disabled since they have stopped!  :)
	// Mute console.log messages repeated to the browser console.
	// (Display them only in the fastlogger, keep the browser log clear for
	// warnings, errors and info messages.)
	// TODO: Similarly, we may want to mute log messages in the FJSL, and only
	// show info/warn/errors.
	muteLogRepeater: 0,

	logNodeInsertions:     false, // Watch for and report DOMNodeInserted events.

	bringBackTheStatusBar: true   // TODO: add fake statusbar div, watch window.status for change?

};
window.FJSL = FJSL;

if (this.localStorage) {
	// TODO: Recall and store FJSL preferences in localStorage.
	// UNWANTED: During testing, I am toggling this setting.
	// FJSL.interceptTimeouts = !Boolean(localStorage['fastjslogger_interceptTimeouts']);
	localStorage['fastjslogger_interceptTimeouts'] = FJSL.interceptTimeouts;
}



// This fails to intercept GM_log calls from other userscripts.
// However it intercepts everything when we run bookmarklets.

// Partly DONE: We may be able to capture errors by overriding setTimeout,
// setInterval, XMLHttpRequest and any other functions which use callbacks,
// with our own versions which attempt the callback within a try-catch which
// logs and throws any intercepted exceptions.
// Unfortunately wrapping a try-catch around the main scripts in the document
// (which have alread run) is a bit harder from here.  ;)
// Aha!  Turns out we can catch those errors with window.onerror!

// TODO: No thanks to Wikipedia's pre styling(?) I can't set a good default, so we need font zoom buttons!
// TODO: Add ability to minimize but popup again on new log message.
// TODO: Report file/line-numbers where possible.  (Split output into table? :E)
// TODO: Option to watch for new globals.
// TODO: Options to toggle logging of any intercepted setTimeouts, XMLHttpRequest's etc, in case the reader is interested.

// TESTING: all DOM events!  TODO: XHR.
// TESTING: We could even put intercepts on generic functions, in case an error occurs inside them, in a context which we had otherwise failed to intercept.

// TODO: If the FJSL is wanted for custom logging, not normal console.log
// logging, we will need to expose a function (FJSL.log()?), and *not*
// intercept console.log.

// TODO: Perhaps instead of creating a new console, we should just replace
// functions in the existing one (and leave anything we haven't altered
// intact).

// TODO: See https://github.com/h5bp/html5-boilerplate/blob/master/js/plugins.js
// for more log actions.

var loadFJSL = function(){



// I did have two running happily in parallel (Chrome userscript and page
// script) but it is rarely useful.  Perhaps we should close the older one?
if (document.getElementById("fastJSLogger") != null) {
	return;
}



// GUI creation library functions

function addStyle(css) {
	// Konqueror 3.5 does not act on textValue, it requires textContent.
	// innerHTML doesn't work for selectors containing '>'
	var st = newNode("style", { type: "text/css", innerHTML: css } );
	document.getElementsByTagName('head')[0].appendChild(st);
}

function newNode(tag,data) {
	var elem = document.createElement(tag);
	if (data) {
		for (var prop in data) {
			elem[prop] = data[prop];
		}
	}
	return elem;
}

function newSpan(text) {
	return newNode("span",{textContent:text});
}

function addCloseButtonTo(elem) {

	var b = document.createElement("button");
	b.textContent = "X";
	b.style.zIndex = 2000;

	b.onclick = function() {
		GM_log("[",b,"] Destroying:",elem);
		elem.style.display = 'none';
		elem.parentNode.removeChild(elem);
	};

	b.style.float = 'right';   // BUG: not working in FF4!
	elem.appendChild(b);

}



// == Main Feature - Present floating popup for log messages ==

// Cleaner to expose the div via id?  It may have been removed from DOM!
// We could fetch logDiv from FJSL when needed?
var logDiv = null;
var logContainer = null;

var autoHideTimer = null;

var oldSetTimeout = window.setTimeout;

function createGUI() {

	var css = "";
	css += " .fastJSLogger { position: fixed; right: 8px; top: 8px; width: 40%; /*max-height: 90%; height: 320px;*/ background-color: #ffffcc; color: black; border: 1px solid black; z-index: 10000; } ";
	css += " .fastJSLogger > span { max-height: 10%; }";
	// css += " .fastJSLogger > pre  { max-height: 90%; overflow: auto; }";
	//// On the pre, max-height: 90% is not working, but specifying px does.
	var maxHeight = window.innerHeight * 0.8 | 0;
	css += " .fastJSLogger > pre  { max-height: "+maxHeight+"px; overflow: auto; word-wrap: break-word; }";
	css += " .fastJSLogger > pre  { padding: 0.4em; }";
	// Must set the colors again, in case the page defined its own bg or fg color for pres that conflicts ours.
	css += " .fastJSLogger > pre  { background-color: #ffffcc; color: black; }";
	// css += " .fastJSLogger > pre > input { width: 100%, background-color: #888888; }";
	css += " .fastJSLogger        { opacity: 0.8; } ";
	css += " .fastJSLogger:hover  { opacity: 1.0; } ";
	if (document.location.host.match(/wikipedia/))
		css += " .fastJSLogger > pre  { font-size: 60%; }";
	else
		css += " .fastJSLogger > pre { font-size: 85%; } ";
	addStyle(css);

	var logDiv = newNode("div",{ id: 'fastJSLogger', className: 'fastJSLogger' });
	hideLogger();
	document.body.appendChild(logDiv);

	// logDiv.style.position = 'fixed';
	// logDiv.style.top = '20px';
	// logDiv.style.right = '20px';

	// @todo refactor
	// I/O: logDiv, logContainer

	var heading = newSpan("FastJSLogger");
	logDiv.appendChild(heading);

	// addCloseButtonTo(logDiv);

	var closeButton = newSpan("[X]");
	closeButton.style.float = 'right';
	closeButton.style.cursor = 'pointer';
	closeButton.style.paddingLeft = '5px';
	closeButton.onclick = function() { logDiv.parentNode.removeChild(logDiv); };
	logDiv.appendChild(closeButton);

	var logContainer = newNode("pre");

	var rollupButton = newSpan("[-]");
	rollupButton.style.float = 'right';
	rollupButton.style.cursor = 'pointer';
	rollupButton.style.paddingLeft = '10px';
	rollupButton.onclick = function() {
		if (logContainer.style.display == 'none') {
			logContainer.style.display = '';
			rollupButton.textContent = "[-]";
		} else {
			logContainer.style.display = 'none';
			rollupButton.textContent = "[+]";
		}
	};
	logDiv.appendChild(rollupButton);

	if (FJSL.displaySearchFilter) {
		function createSearchFilter(logDiv,logContainer) {
			var searchFilter = document.createElement("input");
			searchFilter.type = 'text';
			searchFilter.style.float = 'right';
			searchFilter.style.paddingLeft = '5px';
			searchFilter.onchange = function(evt) {
				var searchText = this.value;
				// console.log("Searching for "+searchText);
				var logLines = logContainer.childNodes;
				for (var i=0;i<logLines.length;i++) {
					if (logLines[i].textContent.indexOf(searchText) >= 0) {
						logLines[i].style.display = '';
					} else {
						logLines[i].style.display = 'none';
					}
				}
			};
			return searchFilter;
		}
		var searchFilter = createSearchFilter(logDiv,logContainer);
		// logDiv.appendChild(document.createElement("br"));
		logDiv.appendChild(searchFilter);
	}

	logDiv.appendChild(logContainer);

	return [logDiv,logContainer];

}

function addToFastJSLog(a,b,c) {

	// Make FJSL visible if hidden
	showLogger();

	if (logContainer) {

		// We cannot do arguments.join (FF4)
		var out = "";
		for (var i=0;i<arguments.length;i++) {
			var obj = arguments[i];
			var str = ""+obj;
			// Non-standard: inform type if toString() is dull.
			if (str === "[object Object]" && typeof obj === 'object' /*&& obj!==null*/) {
				if (obj.constructor) {
					str = "[object "+obj.constructor.name+"]";
				} else {
					// str += " [no type]";
				}
			}
			if (str.length > 77) {
				str = shortenString(str);
			}
			var gap = (i>0?' ':'');
			out += gap + str;
		}

		// logContainer.appendChild(document.createElement("br"));
		// logContainer.appendChild(document.createTextNode(out));
		// logContainer.appendChild(document.createTextNode("div")).textContent = out;
		// var d = document.createElement("div");
		// d.style.fontStyle = 'Monospaced';
		var d = document.createElement("div");
		d.textContent = out;
		logContainer.appendChild(d);

		// Scroll to bottom
		// TODO: This is undesirable if the scrollbar was not already at the bottom, i.e. the user has scrolled up manually and is trying to read earlier log entries!
		logContainer.scrollTop = logContainer.scrollHeight;

	}

	if (autoHideTimer !== null) {
		clearTimeout(autoHideTimer);
		autoHideTimer = null;
	}
	if (FJSL.autoHide) {
		// Never log this setTimeout!  That produces an infinite loop!
		autoHideTimer = oldSetTimeout(hideLogger,15 * 1000);
	}

	return d;

}

function showLogger() {
	if (logDiv) {
		logDiv.style.display = '';
		//// BUG: Transition is not working!  Perhaps it only works when switching between CSS classes.
		// logDiv.style._webkit_transition_property = 'opacity';
		// logDiv.style._webkit_transition_duration = '2s';
		logDiv.style.opacity = 1.0;
	}
}

function hideLogger() {
	if (logDiv) {
		logDiv.style.display = 'none';
		// logDiv.style._webkit_transition_property = 'opacity';
		// logDiv.style._webkit_transition_duration = '2s';
		// logDiv.style.opacity = 0.0;
	}
}

var k = createGUI();
logDiv = k[0];
logContainer = k[1];

// target.console.log("FastJSLogger loaded this="+this+" GM_log="+typeof this.GM_log);
// console.log("interceptTimeouts is "+(FJSL.interceptTimeouts?"ENABLED":"DISABLED"));

// Intercept messages for console.log if it exists.
// Create console.log if it does not exist.

var oldConsole = this.console; // When running as a userscript in Chrome, cannot see this.console!
var oldGM_log = this.GM_log;

var target = ( this.unsafeWindow ? this.unsafeWindow : window );

// Replace the old console
target.console = {};

var preventInfLoop = null;

target.console.log = function(a,b,c) {

	// I tried disabling this and regretted it!
	// My Console bookmarklet can cause an infloop with FJSL if you want to test it.
	if (a+b+c === preventInfLoop) {
		return;
	}
	preventInfLoop = a+b+c;

	// Replicate to the old loggers we intercepted (overrode)

	if (oldConsole && oldConsole.log && !FJSL.muteLogRepeater) {
		// Some browsers dislike use of .call and .apply here, e.g. GM in FF4.
		// So to avoid "oldConsole.log is not a function":
		try {
			oldConsole.log.apply(oldConsole,arguments);
		} catch (e) {
			// Ugly chars to signify that sucky fallback is being used
			oldConsole.log("[noapply]",a,b,c);
		}
	}

	/*
	//// WARNING: *This* is the cause of infinite console.logging, if it has been implemented by FallbackGMAPI.
	//// Solution: FBGMAPI should take a reference to console when creating it's GM_log, not waiting until later to look for the console.
	if (oldGM_log) {
		oldGM_log(a,b,c);
	}
	*/

	return addToFastJSLog.apply(this,arguments);

};

//// NOT TESTED.  Intercept Greasemonkey log messages.  (Worth noting we have disabled calls *to* GM_log above.)
// this.GM_log = target.console.log;

// == MAIN SCRIPT ENDS ==
// The rest is all optional so may be stripped for minification.



/* Provide/intercept console.info/warn/error(). */

target.console.error = function(a,b,c) {
	// We can get away with this in Chrome!

	var args = Array.prototype.slice.call(arguments,0);
	args.unshift("[ERROR]");

	if (oldConsole) {
		if (oldConsole.error) {
			oldConsole.error.apply(oldConsole,arguments);
		} else {
			oldConsole.log.apply(oldConsole,args);
		}
	}

	// TODO CONSIDER: if (a instanceof Error) { ... report stack?
	if (a instanceof Error) {
		addToFastJSLog.apply(this,args); // ,'\n'+getStack(2,20).join("\n"));
		return target.console.error(""+a.stack);
	}

	return addToFastJSLog.apply(this,args); // ,'\n'+getStack(2,20).join("\n"));
};

// Could generalise the two functions below:
//interceptLogLevel("warn");
//interceptLogLevel("info");

target.console.warn = function(a,b,c) {
	var args = Array.prototype.slice.call(arguments,0);
	args.unshift("[WARN]");
	// args.push(""+getCallerFromStack());
	if (oldConsole) {
		if (oldConsole.warn) {
			oldConsole.warn.apply(oldConsole,arguments);
		} else {
			oldConsole.log.apply(oldConsole,args);
		}
	}
	//// This was quite useful on one occasion.  But not in the presence of lots of warnings!
	// logStack(getStackFromCaller());
	//// It appeared before the warn line in FJSL, although in the correct order in Chrome's console.

	// CONSIDER: I guess we should forward the log-level as an argument to
	// addToFastJSLog, so it can decide whether to mark or color entries.
	// OTOH we are marking here, which is kind of a good place!
	// So perhaps we should forward level marker and color, like cool_logger does.
	// addToFastJSLog can decide whether to ignore them based on options (bare/mono).
	return addToFastJSLog.apply(this,args);
};

target.console.info = function(a,b,c) {
	var args = Array.prototype.slice.call(arguments,0);
	args.unshift("[INFO]");
	if (oldConsole) {
		if (oldConsole.info) {
			oldConsole.info.apply(oldConsole,arguments);
		} else {
			oldConsole.log.apply(oldConsole,args);
		}
	}
	return addToFastJSLog.apply(this,args);
};

/*
target.console.error = function(e) {
	// target.console.log("[ERROR]",e,e.stack);
	var newArgs = [];
	newArgs.push("[ERROR]");
	for (var i=0;i<arguments.length;i++) {
		newArgs.push(arguments[i]);
	}
	try {
		newArgs.push("(reported from function "+arguments.callee.caller.name+")");
		// console.error("caller = "+arguments.callee.caller);
		// console.error("stack = "+e.stack);
	} catch (e) {
	}
	target.console.log.apply(target.console,newArgs);
	target.console.log.apply(target.console,["Stacktrace:\n",e.stack]);
};
*/



// Some more library functions:

function tryToDo(fn,target,args) {

	try {

		fn.apply(target,args);
		return true;

	} catch (e) {
		// Actually hard to read!
		// var prettyFn = fn; // (""+fn) .replace(/\n/g,'\\n');
		var fnName = fn && fn.name;
		if (!fnName) {
			fnName = "<anonymous>";
		}
		// console.log("[ERR]",e,prettyFn);
		// console.log("[Exception]",e,"from "+fnName+"()");
		console.error("!! "+e.stack);
		// var prettyFn = (""+fn).replace(/\n/,/ /,'g');
		var prettyFn = shortenString(fn);
		console.error("occurred when calling: "+prettyFn);
		// throw e;
		// Unfortunately even Chrome dev shows the throw as coming from here!
		// So it is better if we leave it alone.
		return false;
	}

}

function showObject(obj) {
	return "{ " + Object.keys(obj).map(function(prop) {
		return prop+": "+shortenString(obj[prop]);
	}).join(", ") + " }";
}

function getXPath(node) {
	var parent = node.parentNode;
	if (!parent) {
		return '';
	}
	var siblings = parent.childNodes;
	var totalCount = 0;
	var thisCount = -1;
	for (var i=0;i<siblings.length;i++) {
		var sibling = siblings[i];
		if (sibling.nodeType == node.nodeType) {
			totalCount++;
		}
		if (sibling == node) {
			thisCount = totalCount;
			break;
		}
	}
	return getXPath(parent) + '/' + node.nodeName.toLowerCase() + (totalCount>1 ? '[' + thisCount + ']' : '' );
}

function getStack(drop,max) {
	var stack;
	try {
		throw new Error("Dummy for getStack");
	} catch (e) {
		stack = e.stack.split('\n').slice(drop).slice(0,max);
	}
	return stack;
}

// What frame/function called the function which called us?
function getCallerFromStack() {
	return getStack(4,1);
}

// The frame/function which called our caller, and all above it.
function getStackFromCaller() {
	return getStack(4,-1);
}

function logStack(stack) {
	for (var i=0;i<stack.length;i++) {
		console.log(""+stack[i]);
	}
}



// == Error Interceptors ==

// Whenever a callback is placed, we should wrap it!
// DONE:
//   event listeners (added after we run)
//   setTimeout
// TODO:
//   setInterval
//   XMLHttpRequest

// We could even wrap any standard functions which are common sources of
// Errors, in case we fail to catch them any other way.

if (FJSL.watchWindowForErrors) {
	// Registers a window.onerror event handler, which catches DOM Errors like
	// img elements which failed to load their src resource.
	function handleError(evt) {

		if (!FJSL.firstWindowErrorEvent) {
			FJSL.firstWindowErrorEvent = evt;
		}
		//// Expose this event for inspection
		FJSL.lastWindowErrorEvent = evt;
		// console.log("Error caught by FJSL:");
		// console.log(evt);
		// console.log(Object.keys(evt));
		// target.console.error(evt.filename+":"+evt.lineno+" "+evt.message+" ["+evt.srcElement+"]",evt);

		// In fact repeating these to the browser log is redundant, since the
		// browser is likely to report these errors anyway.
		// Therefore, we could use addToFastJSLog instead of console.log below.

		// Chrome sometimes gives us a message, sometimes doesn't.
		if (evt.message) {
			// This is what Chrome provides for an error thrown by a page script.
			// In Chrome this event object contains neither an Error nor a stack-trace.
			// Also the current stack-trace is uninformative (see nothing about the call to handleError.)
			// So we don't use the following: , evt, getStack(0,99).join('\n')
			console.error("[Caught Error] "+evt.message+" "+evt.filename+":"+evt.lineno);
		} else {
			var report = '[Caught Unknown Error] ';
			report += "type="+evt.type+" ";

			// For some errors neither Firefox nor Chrome give us a message.
			// But sometimes we can peek into the element that fired the error.
			// If it was an image, then its src attribute may be useful.
			var elem = evt.srcElement || evt.target;
			if (elem) {
				report += "From element "+elem+" ";
				try {
					report += "with src="+elem.src+" ";
				} catch (e) { }
			}

			/*
			if (elem == window) {
				FJSL.lastEE = evt;
			}
			*/

			/*
			if (!elem) {
				// Firefox 14 was providing only a constructor function in the event,
				// so I wonder if calling it will reproduce the error for us.  Either
				// that, or it will try to construct an event object.  :P
				// I will probably remove this if I see it again and confirm that it's useless.
				// I did get a HUGE string from Firefox which was pretty interesting.
				// But it's not what we were looking for.
				if (typeof evt.constructor == "function") {
					try {
						var result = evt.constructor();
						if (result) {
							console.error(report + "Constructor result: "+result);
						}
					} catch (e) {
						// I think in Firefox this gives us useful information.
						// TODO: But I have seen us reach here in Chrome, with an error "cannot call DOM Object constructor" presumably meaning out evt.constructor() call was forbidden, and we should look elsewhere for information.
						report += "(Constructor error: \""+e+"\") ";
						// Dirty cheat expose it for dev/debugger:
						evt.FJSLconstructorError = e;
						// I have come to the conclusion that although they are different, the errors I get in both Firefox and Chrome are errors about the way I have called the constructor, and not any useful error I was after :P
						// FF: Timestamp: 29/07/12 18:10:14
						// Error: NS_ERROR_XPC_NOT_ENOUGH_ARGS: Not enough arguments
						console.log("[Constructor Error]",e);
						throw e;
					}
				}
			}
			*/

			console.error(report,evt);
		}
	}
	window.addEventListener("error",handleError,true);
	// document.body.addEventListener("error",handleError,true);
}

function shortenString(s) {
	s = ""+s;
	s = s.replace(/\n[ \t]+/,'\\n ','g');
	s = s.replace(/\n/,'\\n','g');
	s = s.replace(/\t/,'  ','g');
	if (s.length>77) {
		s = s.substring(0,77)+"...";
	}
	return s;
}

if (FJSL.interceptTimeouts) {

	window.setTimeout = function(fn,ms) {
		if (FJSL.logTimeouts) {
			// TODO: We used to pass ,fn to log here.  That was nice in Chrome, because we can fold it open or closed, but too spammy for plain FJSL.  Recommendation: Refactor out prettyShow() fn which will determine browser and provide raw object for chrome or shortened string for noob browsers?
			console.info("[EVENT] setTimeout() called: "+ms+", "+shortenString(fn));
		}
		var wrappedFn = function(){

			// We can catch the error here, but if we do, even if we throw it again, the Chrome debugger shows this function as the source.
			// It is preferable to let the error fall up to Chrome, so we can easily jump to the line number.
			// Unfortunately, if we don't catch the error, we can't report it to FJSL!

			if (typeof fn === 'string') {
				var str = fn;
				fn = function(){ eval(str); };
			}
			if (!typeof fn === 'function') {
				throw new Error("[FJSL] setTimeout was not given a function!",fn);
			}

			var passed = tryToDo(fn);

			if (!passed) {

				// tryToDo has caught and reported the Error, but it is nice to let
				// it fall out to the browser, since browsers often have nifty features.

				console.log("Re-running to reproduce stack-trace (may fail)");
				fn();
				throw new Error("Re-run failed to produce any error!",fn);

			}

		};

		return oldSetTimeout(wrappedFn,ms);
	};

}



// == General Info Logging Utilities ==

if (FJSL.logNodeInsertions) {
	document.body.addEventListener('DOMNodeInserted', function(evt) {
		if (evt.target === logContainer || evt.target.parentNode === logContainer) {
			return;
		}
		// console.log("[DOMNodeInserted]: target=",evt.target," event=",evt);
		// console.log("[DOMNodeInserted]:",evt,evt.target,"path="+getXPath(evt.target),"html="+evt.target.outerHTML);
		console.log("[DOMNodeInserted]: path="+getXPath(evt.target)+" html="+evt.target.outerHTML,evt);
	}, true);
}

if (FJSL.interceptEvents) {

	var realAddEventListener = HTMLElement.prototype.addEventListener;
	// HTMLElement.prototype.oldAddEventListener = realAddEventListener;
	HTMLElement.prototype.addEventListener = function(type,handler,capture,other){
		if (FJSL.logEvents) {
			// Note niceFunc is re-used later, so don't remove this!
			var niceFunc = handler.name || (""+handler).substring(0,80).replace(/\n/," ",'g').replace(/[ \t]*/," ",'g')+"...";
			/*
			console.info("[EVENTS] Listening for "+type+" events on "+getXPath(this)+" with handler "+niceFunc);
			console.info(getStack(3,3).join("\n"));
			*/
		}
		var newHandler = function(evt) {
			if (FJSL.logEvents) {
				var isNastyMouseEvent = ["mousemove","mouseover","mouseout"].indexOf(evt.type) >= 0;
				if (!isNastyMouseEvent || FJSL.logCommonMouseEvents) {
					if (evt.target.parentNode == logContainer) {
						// Do not log events in the console's log area, such as DOMNodeInserted!
					} else {
						// console.log("("+type+") on "+evt.target);
						// console.info("[EVENT] "+type+" on "+getXPath(evt.target));
						// console.log("[EVENT] "+type+" on "+getXPath(evt.target)+" evt="+showObject(evt));
						console.info("[EVENT] "+type+" on "+getXPath(evt.target)+" being handled by "+niceFunc);
					}
				}
			}
			// handler.call(this,evt);
			tryToDo(handler,this,[evt]);
		};
		// tryToDo(realAddEventListener,this,type,handler,capture,other);
		/*
		var that = this;
		tryToDo(function(){
			realAddEventListener.call(that,type,newHandler,capture,other);
			//realAddEventListener.apply(that,[type,handler,capture,other]);
			//that.oldAddEventListener(type,handler,capture,other);
		});
		*/
		/*
		tryToDo(realAddEventListener,this,[type,newHandler,capture,other]);
		*/
		realAddEventListener.call(this,type,newHandler,capture,other);
	};

}

if (FJSL.logChangesToGlobal) {
	function newChangeWatcher() {
		var checkSpeed = 4000;
		var watcher = {};
		var global = window;
		var knownKeys = {};
		var firstCheck = true;
		function checkGlobal() {
			if (FJSL.logChangesToGlobal) {
				for (var key in global) {
					if (knownKeys[key] === undefined) {
						if (!firstCheck) {
							var obj = global[key];
							console.log("[GLOBAL] "+key+" =",obj);
						}
						knownKeys[key] = 1;
					}
				}
				firstCheck = false;
			}
			oldSetTimeout(checkGlobal,checkSpeed);
		}
		oldSetTimeout(checkGlobal,checkSpeed);
		return watcher;
	};
	var changeWatcher = newChangeWatcher();
}



};

if (document.body) {
	loadFJSL();
} else {
	// doc bod may not exist if we are loaded in the HEAD!  Better wait till later...
	setTimeout(loadFJSL,1000);
	// But we would quite like to start doing stuff now anyway!
	// TODO: Load what we can immediately, delay only things we must.
	// E.g. start capturing text, even if we can't display it yet.
}


.pragma library

var LANG = "es"
var LOCALE = "es_ES"
var M = {}

function t(s) {
    var v = M[s]
    return v === undefined ? s : v
}

function f(s) {
    var r = t(s)
    for (var i = 1; i < arguments.length; i++)
        r = r.split("%" + i).join(String(arguments[i]))
    return r
}

// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.css"

// Import jQuery
window.$ = window.jQuery = require("jquery");

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies

import "phoenix_html"
import "./navbar_burger"

// Import local files
//
// Local files can be imported directly using relative paths, for example:
// import socket from "./socket"

import Turbolinks from 'turbolinks'
Turbolinks.start()

import {Socket} from "phoenix"
import LiveSocket from "phoenix_live_view"

let Hooks = {}

let serializeForm = (form) => {
  let formData = new FormData(form)
  let params = new URLSearchParams()
  for(let [key, val] of formData.entries()){ params.append(key, val) }

  return params.toString()
}


Hooks.SavedForm = {
  mounted(){
    this.el.addEventListener("input", e => {
      Params.set(this.viewName, "stashed_form", serializeForm(this.el))
    })
  }
}


let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {hooks: Hooks, params: {_csrf_token: csrfToken}})

document.addEventListener('turbolinks:load', function() { liveSocket.connect() });
document.addEventListener('turbolinks:request-start', function() { liveSocket.disconnect() });

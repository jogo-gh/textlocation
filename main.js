import { Elm } from "./src/Main.elm";
import { registerSW } from 'virtual:pwa-register'

import "material-components-web-elm/dist/material-components-web-elm.js";
import "material-components-web-elm/dist/material-components-web-elm.css";

const updateSW = registerSW({
  onNeedRefresh() { updateSW(); },
  onOfflineReady() { },
})


var db = new PouchDB('textlocation');

const root = document.querySelector("#app div");
const app = Elm.Main.init({
  node: root,
  flags: Math.floor(Math.random() * 0x0FFFFFFF),
});

// Initialize ports below this line
app.ports.infoForOutside.subscribe(msg => {
  if (msg.tag == "CreateContact") {
    db.put(msg.data).then(function (doc) {
      return getAllDocs(app, db)
    }).catch(function (error) {
      console.log(error)
    })
  } else if (msg.tag == "ModifyContact") {
    db.get(msg.data._id).then(function (doc) {
      msg.data._rev = doc._rev
      return db.put(msg.data)
    }).then(function (doc) {
      return getAllDocs(app, db)
    }).catch(function (error) {
      console.log(error)
    })
  } else if (msg.tag == "DeleteContact") {
    db.get(msg.data._id).then(function (doc) {
      return db.remove(doc)
    }).then(function (doc) {
      return getAllDocs(app, db)
    }).catch(function (error) {
      console.log(error)
    })
  } else if (msg.tag == "GetAllContacts") {
    getAllDocs(app, db)
  }
});

function getAllDocs(app, db) {
  db.allDocs({ include_docs: true, attachments: true }).then(function (result) {
    var docs = result.rows.map(function (row) { return row.doc })
    app.ports.infoForElm.send({ tag: "ContactsChanged", data: docs });
  }
  )
}

function positionSuccess(pos) {
  var crd = pos.coords;

  app.ports.infoForElm.send({
    tag: "PositionUpdated",
    data: { longitude: crd.longitude, latitude: crd.latitude, accuracy: crd.accuracy }
  });
}

function positionError(err) {
  switch (err.code) {
    case 1:
      // permission denied 
      app.ports.infoForElm.send({
        tag: "PositionUpdated",
        data: { error: "permission_denied" }
      });
      break;
    case 2:
      // position unavailable  
      app.ports.infoForElm.send({
        tag: "PositionUpdated",
        data: { error: "position_unavailable" }
      });
      break;
    case 3:
      // timeout 
      app.ports.infoForElm.send({
        tag: "PositionUpdated",
        data: { error: "timeout" }
      });
      break;
    default:
      app.ports.infoForElm.send({
        tag: "PositionUpdated",
        data: { error: "unknown" }
      });
      break;
  }
}

var positionOptions = {
  timeout: 5000
};

navigator.geolocation.getCurrentPosition(positionSuccess, positionError, positionOptions);
navigator.geolocation.watchPosition(positionSuccess, positionError, positionOptions);

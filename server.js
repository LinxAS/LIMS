'use strict';
const cds     = require('@sap/cds');
const express = require('express');

// Static files + root redirect — works for both cds watch and node server.js
cds.on('bootstrap', (app) => {
  app.use(express.static(__dirname + '/app'));
  app.get('/', (_req, res) => res.redirect('/launchpad.html'));
});

// When run directly: node server.js
if (require.main === module) {
  const PORT = process.env.PORT || 4004;
  // cds.serve() fires bootstrap on cds.app, then we listen on cds.app
  cds.serve('all').then(() => {
    cds.app.listen(PORT, () => {
      console.log(`LIMS server listening on http://localhost:${PORT}`);
      console.log(`Launchpad: http://localhost:${PORT}/launchpad.html`);
    });
  });
}

module.exports = cds.server;

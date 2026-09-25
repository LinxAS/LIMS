'use strict';
const cds = require('@sap/cds');

// Serve static files from /app when CDS bootstraps
cds.on('bootstrap', (app) => {
  const express = require('express');
  app.use(express.static(__dirname + '/app'));
  app.get('/', (_req, res) => res.redirect('/launchpad.html'));
});

// When run directly (node server.js) start the server ourselves
if (require.main === module) {
  const PORT = process.env.PORT || 4004;
  cds.serve('all').in(require('express')()).then((app) => {
    app.listen(PORT, () => {
      console.log(`LIMS server listening on http://localhost:${PORT}`);
      console.log(`Launchpad: http://localhost:${PORT}/launchpad.html`);
    });
  });
}

module.exports = cds.server;

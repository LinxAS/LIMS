'use strict';
const cds     = require('@sap/cds');
const express = require('express');

// For 'cds serve' / 'cds watch': CDS calls cds_server() which fires bootstrap
cds.on('bootstrap', (app) => {
  app.use(express.static(__dirname + '/app'));
  app.get('/', (_req, res) => res.redirect('/launchpad.html'));
});

// For 'node server.js' / PM2 direct execution
if (require.main === module) {
  const PORT = process.env.PORT || 4004;

  // Replicate what cds_server() does: create app, set cds.app, fire bootstrap,
  // connect to db, then serve all services
  (async () => {
    const app = cds.app = express();
    cds.emit('bootstrap', app);  // triggers our listener above

    if (cds.requires.db) await cds.connect.to('db');

    await cds.serve('all').in(app);

    app.listen(PORT, () => {
      console.log(`LIMS server listening on http://localhost:${PORT}`);
      console.log(`Launchpad: http://localhost:${PORT}/launchpad.html`);
    });
  })();
}

module.exports = cds.server;

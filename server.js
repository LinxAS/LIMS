'use strict';
const cds     = require('@sap/cds');
const express = require('express');

// Register static-file serving + root redirect into the CDS bootstrap.
// This is called by both `cds serve` and `cds watch` via cds_server().
cds.on('bootstrap', (app) => {
  app.use(express.static(__dirname + '/app'));
  app.get('/', (_req, res) => res.redirect('/launchpad.html'));
});

// Export cds.server so that `cds-serve` (npm start) uses the full
// CDS bootstrap (middleware, transactions, context) — not our own.
module.exports = cds.server;

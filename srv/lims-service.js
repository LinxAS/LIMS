'use strict';

const cds = require('@sap/cds');

module.exports = cds.service.impl(async function () {
  const { Containers, DispensingRecords, Inventory, StockOrders, RequisitionItems } = this.entities;

  // ── dispense action ──────────────────────────────────────────────────────────
  this.on('dispense', async (req) => {
    const { containerID, reqItemID, quantity, uom } = req.data;

    // Fetch container
    const container = await SELECT.one.from(Containers).where({ ContainerID: containerID });
    if (!container) return req.error(404, `Container ${containerID} not found`);
    if (container.RemainingQuantity < quantity) {
      return req.error(400, `Insufficient quantity: ${container.RemainingQuantity} ${container.UoM} available`);
    }

    const childID = `CONT-C-${Date.now()}`;
    const record = {
      ID               : cds.utils.uuid(),
      container_ContainerID : containerID,
      reqItem_ID       : reqItemID,
      ChildContainerID : childID,
      DispensingDate   : new Date().toISOString().slice(0, 10),
      QtyIssued        : quantity,
      UoM              : uom || container.UoM,
      DispensedBy      : req.user?.id || 'SYSTEM'
    };

    await INSERT.into(DispensingRecords).entries(record);
    await UPDATE(Containers)
      .set({ RemainingQuantity: container.RemainingQuantity - quantity })
      .where({ ContainerID: containerID });

    // Mark the requisition item Completed when total dispensed >= requested qty
    if (reqItemID) {
      const reqItem = await SELECT.one.from(RequisitionItems).where({ ID: reqItemID });
      if (reqItem) {
        const allDisps = await SELECT.from(DispensingRecords).where({ reqItem_ID: reqItemID });
        const totalDispensed = allDisps.reduce((sum, d) => sum + (d.QtyIssued || 0), 0);
        if (totalDispensed >= reqItem.Quantity) {
          await UPDATE(RequisitionItems).set({ Criticality: 5 }).where({ ID: reqItemID });
        }
      }
    }

    return record;
  });

  // ── requestStock action ──────────────────────────────────────────────────────
  this.on('requestStock', async (req) => {
    const { inventoryID, orderType, orderNumber, qty } = req.data;

    const inv = await SELECT.one.from(Inventory).where({ ID: inventoryID });
    if (!inv) return req.error(404, `Inventory record ${inventoryID} not found`);

    const order = {
      ID           : cds.utils.uuid(),
      inventory_ID : inventoryID,
      OrderType    : orderType || 'PO',
      OrderNumber  : orderNumber || `PO-AUTO-${Date.now()}`,
      RequestedQty : qty,
      UoM          : inv.UoM,
      Status       : 'Pending'
    };

    await INSERT.into(StockOrders).entries(order);
    await UPDATE(Inventory)
      .set({ TotalOnOrder: (inv.TotalOnOrder || 0) + qty })
      .where({ ID: inventoryID });

    return order;
  });

  // ── Inventory READ — enrich Criticality ─────────────────────────────────────
  this.after('READ', Inventory, (results) => {
    const rows = Array.isArray(results) ? results : [results];
    for (const row of rows) {
      if (!row) continue;
      if (row.TotalAvailable <= 0) {
        row.Criticality = 1;   // red — Critical / out of stock
        row.StockFlag   = 'Critical';
      } else if (row.TotalAvailable < row.TotalRequisitioned) {
        row.Criticality = 2;   // yellow — Low
        row.StockFlag   = 'Low';
      } else {
        row.Criticality = 5;   // green — OK
        row.StockFlag   = 'OK';
      }
    }
  });

  // ── RequisitionItems READ — enrich Criticality ───────────────────────────────
  // Criticality 5 = Completed (fully dispensed — set only by dispense action).
  // Never overwrite a Completed item here; only set stock-availability indicators.
  this.after('READ', RequisitionItems, (results) => {
    const rows = Array.isArray(results) ? results : [results];
    for (const row of rows) {
      if (!row) continue;
      if (row.Criticality === 5) continue;  // already Completed — leave it
      if (row.AvailableQty <= 0) {
        row.Criticality = 1;   // red  — no stock available
      } else if (row.AvailableQty < row.Quantity) {
        row.Criticality = 2;   // yellow — partial stock
      } else {
        row.Criticality = 3;   // green — sufficient stock, but not yet dispensed
      }
    }
  });
});

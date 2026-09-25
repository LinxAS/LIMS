using lims from '../db/schema';

service LIMSService @(path: '/odata/v4/lims') {

  // ── US Apps ───────────────────────────────────────────────
  entity Requisitions      as projection on lims.Requisitions;
  entity RequisitionItems  as projection on lims.RequisitionItems;

  // ── Shared Apps ───────────────────────────────────────────
  entity Containers        as projection on lims.Containers;
  entity DispensingRecords as projection on lims.DispensingRecords;
  entity Inventory         as projection on lims.Inventory;
  entity StockOrders       as projection on lims.StockOrders;

  // ── Monaco Apps ───────────────────────────────────────────
  entity Forecasts         as projection on lims.Forecasts;
  entity ForecastItems     as projection on lims.ForecastItems;

  // ── Master Data ───────────────────────────────────────────
  @readonly entity Plants          as projection on lims.Plants;
  @readonly entity Laboratories    as projection on lims.Laboratories;
  @readonly entity Materials       as projection on lims.Materials;
  @readonly entity Specifications  as projection on lims.Specifications;

  // ── Actions ───────────────────────────────────────────────
  action dispense(containerID: String, reqItemID: UUID,
                  quantity: Decimal, uom: String) returns DispensingRecords;
  action requestStock(inventoryID: UUID, orderType: String,
                      orderNumber: String, qty: Decimal) returns StockOrders;
}

// ─────────────────────────────────────────────────────────────
// REQUISITIONS — List Report
// ─────────────────────────────────────────────────────────────
annotate LIMSService.Requisitions with @(
  UI.HeaderInfo: {
    TypeName       : 'Requisition',
    TypeNamePlural : 'Requisitions',
    Title          : { Value: RequisitionID },
    Description    : { Value: RequisitionName }
  },
  UI.SelectionFields: [ RequisitionID, RequestedFor, plant_PlantCode, lab_LabCode, Status ],
  UI.LineItem: [
    { Value: RequisitionID,       Label: 'Requisition ID' },
    { Value: RequisitionName,     Label: 'Name' },
    { Value: plant_PlantCode,     Label: 'Plant' },
    { Value: lab_LabCode,         Label: 'Lab' },
    { Value: Status,              Label: 'Status',
      Criticality: { $edmJson: { $If: [
        { $Eq: [{ $Path: 'Status' }, 'Approved'] }, 5,
        { $If: [{ $Eq: [{ $Path: 'Status' }, 'Submitted'] }, 2, 0] }
      ]}}
    },
    { Value: NeededBy,            Label: 'Needed By' },
    { Value: CreatedBy,           Label: 'Created By' }
  ],
  UI.Facets: [
    {
      $Type  : 'UI.ReferenceFacet',
      Label  : 'Overview',
      Target : '@UI.FieldGroup#Overview'
    },
    {
      $Type  : 'UI.ReferenceFacet',
      Label  : 'Stock Details',
      Target : 'items/@UI.LineItem'
    },
    {
      $Type  : 'UI.ReferenceFacet',
      Label  : 'Dispensing Details',
      Target : 'items/dispensingDetails/@UI.LineItem'  // via items navigation
    }
  ],
  UI.FieldGroup#Overview: {
    Label : 'Overview',
    Data  : [
      { Value: Status,        Label: 'Status' },
      { Value: CreatedBy,     Label: 'Created By' },
      { Value: NeededBy,      Label: 'Needed By' },
      { Value: RequestedFor,  Label: 'Requested For' },
      { Value: Category,      Label: 'Category' },
      { Value: CreatedOn,     Label: 'Created On' }
    ]
  }
);

// ─────────────────────────────────────────────────────────────
// REQUISITION ITEMS — Facet table
// ─────────────────────────────────────────────────────────────
annotate LIMSService.RequisitionItems with @(
  UI.LineItem: [
    { Value: ItemNumber,    Label: 'Item' },
    { Value: spec_SpecNumber,  Label: 'Spec Number' },
    { Value: spec_Description, Label: 'Spec Description' },
    { Value: material_Description, Label: 'Material' },
    { Value: Quantity,      Label: 'Requested Qty' },
    { Value: UoM,           Label: 'UoM' },
    { Value: AvailableQty,  Label: 'Available Qty', Criticality: Criticality }
  ]
);

// ─────────────────────────────────────────────────────────────
// DISPENSING RECORDS — Facet table
// ─────────────────────────────────────────────────────────────
annotate LIMSService.DispensingRecords with @(
  UI.LineItem: [
    { Value: ChildContainerID, Label: 'Child Container' },
    { Value: DispensingDate,   Label: 'Date' },
    { Value: QtyIssued,        Label: 'Qty Issued' },
    { Value: UoM,              Label: 'UoM' },
    { Value: DispensedBy,      Label: 'Dispensed By' }
  ]
);

// ─────────────────────────────────────────────────────────────
// CONTAINERS — List Report
// ─────────────────────────────────────────────────────────────
annotate LIMSService.Containers with @(
  UI.HeaderInfo: {
    TypeName       : 'Container',
    TypeNamePlural : 'Containers',
    Title          : { Value: ContainerID },
    Description    : { Value: spec_Description }
  },
  UI.SelectionFields: [
    ContainerID, spec_SpecNumber, material_MaterialNumber,
    plant_PlantCode, lab_LabCode, MfgLotNo, Status
  ],
  UI.LineItem: [
    { Value: ContainerID,              Label: 'Container ID' },
    { Value: spec_SpecNumber,          Label: 'Spec Number' },
    { Value: spec_Description,         Label: 'Spec Description' },
    { Value: material_MaterialNumber,  Label: 'Material' },
    { Value: plant_PlantCode,          Label: 'Plant' },
    { Value: lab_LabCode,              Label: 'Lab' },
    { Value: MfgLotNo,                 Label: 'Mfg Lot No' },
    { Value: InitialQuantity,          Label: 'Initial Qty' },
    { Value: RemainingQuantity,        Label: 'Remaining Qty' },
    { Value: UoM,                      Label: 'UoM' },
    { Value: ExpirationDate,           Label: 'Expiration Date' },
    { Value: Status,                   Label: 'Status' }
  ],
  UI.Facets: [
    {
      $Type  : 'UI.ReferenceFacet',
      Label  : 'Overview',
      Target : '@UI.FieldGroup#Overview'
    },
    {
      $Type  : 'UI.ReferenceFacet',
      Label  : 'Dispensing Details',
      Target : 'dispensingDetails/@UI.LineItem'
    },
    {
      $Type  : 'UI.ReferenceFacet',
      Label  : 'Additional Information',
      Target : '@UI.FieldGroup#AdditionalInfo'
    }
  ],
  UI.FieldGroup#Overview: {
    Label : 'Overview',
    Data  : [
      { Value: Status,            Label: 'Status' },
      { Value: ExpirationDate,    Label: 'Expiration Date' },
      { Value: InitialQuantity,   Label: 'Initial Quantity' },
      { Value: RemainingQuantity, Label: 'Remaining Quantity' },
      { Value: UoM,               Label: 'UoM' },
      { Value: MfgLotNo,          Label: 'Mfg Lot No' }
    ]
  },
  UI.FieldGroup#AdditionalInfo: {
    Label : 'Additional Information',
    Data  : [
      { Value: SafetyH,        Label: 'Safety H' },
      { Value: SafetyS,        Label: 'Safety S' },
      { Value: SafetyR,        Label: 'Safety R' },
      { Value: GHSHazardClass, Label: 'GHS Hazard Class' },
      { Value: Owner,          Label: 'Owner' },
      { Value: Comments,       Label: 'Comments' }
    ]
  }
);

// ─────────────────────────────────────────────────────────────
// INVENTORY — List Report
// ─────────────────────────────────────────────────────────────
annotate LIMSService.Inventory with @(
  UI.HeaderInfo: {
    TypeName       : 'Inventory Item',
    TypeNamePlural : 'Inventory',
    Title          : { Value: spec_SpecNumber },
    Description    : { Value: spec_Description }
  },
  UI.SelectionFields: [
    spec_SpecNumber, material_MaterialNumber, plant_PlantCode
  ],
  UI.LineItem: [
    { Value: spec_SpecNumber,         Label: 'Spec Number',   Criticality: Criticality },
    { Value: spec_Description,        Label: 'Description',   Criticality: Criticality },
    { Value: material_MaterialNumber, Label: 'Material',      Criticality: Criticality },
    { Value: plant_PlantCode,         Label: 'Plant',         Criticality: Criticality },
    { Value: TotalQuantity,           Label: 'Total Qty',     Criticality: Criticality },
    { Value: TotalRequisitioned,      Label: 'Requisitioned', Criticality: Criticality },
    { Value: TotalAvailable,          Label: 'Available',     Criticality: Criticality },
    { Value: TotalOnOrder,            Label: 'On Order',      Criticality: Criticality },
    { Value: UoM,                     Label: 'UoM' },
    { Value: StockFlag,               Label: 'Stock Status',  Criticality: Criticality }
  ],
  UI.Facets: [
    {
      $Type  : 'UI.ReferenceFacet',
      Label  : 'Overview',
      Target : '@UI.FieldGroup#Overview'
    },
    {
      $Type  : 'UI.ReferenceFacet',
      Label  : 'Stock Orders',
      Target : 'stockOrders/@UI.LineItem'
    }
  ],
  UI.FieldGroup#Overview: {
    Label : 'Overview',
    Data  : [
      { Value: spec_SpecNumber,         Label: 'Spec Number' },
      { Value: spec_Description,        Label: 'Description' },
      { Value: material_MaterialNumber, Label: 'Material' },
      { Value: plant_PlantCode,         Label: 'Plant' },
      { Value: TotalQuantity,           Label: 'Total Quantity' },
      { Value: TotalRequisitioned,      Label: 'Requisitioned' },
      { Value: TotalAvailable,          Label: 'Available' },
      { Value: TotalOnOrder,            Label: 'On Order' },
      { Value: StockFlag,               Label: 'Stock Status' }
    ]
  }
);

// ─────────────────────────────────────────────────────────────
// STOCK ORDERS — Facet table
// ─────────────────────────────────────────────────────────────
annotate LIMSService.StockOrders with @(
  UI.LineItem: [
    { Value: OrderType,    Label: 'Type' },
    { Value: OrderNumber,  Label: 'Order Number' },
    { Value: RequestedQty, Label: 'Requested Qty' },
    { Value: UoM,          Label: 'UoM' },
    { Value: Status,       Label: 'Status' }
  ]
);

// ─────────────────────────────────────────────────────────────
// FORECASTS — List Report
// ─────────────────────────────────────────────────────────────
annotate LIMSService.Forecasts with @(
  UI.HeaderInfo: {
    TypeName       : 'Forecast',
    TypeNamePlural : 'Forecasts',
    Title          : { Value: ForecastID },
    Description    : { Value: ForecastName }
  },
  UI.SelectionFields: [ ForecastID, RequestedFor, plant_PlantCode, lab_LabCode, Status ],
  UI.LineItem: [
    { Value: ForecastID,      Label: 'Forecast ID' },
    { Value: ForecastName,    Label: 'Name' },
    { Value: plant_PlantCode, Label: 'Plant' },
    { Value: lab_LabCode,     Label: 'Lab' },
    { Value: Status,          Label: 'Status' },
    { Value: NeededBy,        Label: 'Needed By' },
    { Value: DateSubmitted,   Label: 'Date Submitted' },
    { Value: CreatedBy,       Label: 'Created By' }
  ],
  UI.Facets: [
    {
      $Type  : 'UI.ReferenceFacet',
      Label  : 'Overview',
      Target : '@UI.FieldGroup#Overview'
    },
    {
      $Type  : 'UI.ReferenceFacet',
      Label  : 'Forecast Items',
      Target : 'items/@UI.LineItem'
    }
  ],
  UI.FieldGroup#Overview: {
    Label : 'Overview',
    Data  : [
      { Value: Status,       Label: 'Status' },
      { Value: CreatedBy,    Label: 'Created By' },
      { Value: NeededBy,     Label: 'Needed By' },
      { Value: RequestedFor, Label: 'Requested For' },
      { Value: Category,     Label: 'Category' },
      { Value: DateSubmitted, Label: 'Date Submitted' }
    ]
  }
);

// ─────────────────────────────────────────────────────────────
// FORECAST ITEMS — Facet table
// ─────────────────────────────────────────────────────────────
annotate LIMSService.ForecastItems with @(
  UI.LineItem: [
    { Value: ItemNumber,           Label: 'Item' },
    { Value: spec_SpecNumber,      Label: 'Spec Number' },
    { Value: spec_Description,     Label: 'Description' },
    { Value: Quantity,             Label: 'Quantity' },
    { Value: UoM,                  Label: 'UoM' },
    { Value: AvailableQtyInPlant,  Label: 'Available In Plant' },
    { Value: ItemStatus,           Label: 'Status' },
    { Value: RequestedFor,         Label: 'Requested For' },
    { Value: NeededBy,             Label: 'Needed By' }
  ]
);

// ─────────────────────────────────────────────────────────────
// VALUE HELPS
// ─────────────────────────────────────────────────────────────
annotate LIMSService.Requisitions with {
  plant @(Common.ValueList: {
    CollectionPath : 'Plants',
    Parameters     : [{ $Type: 'Common.ValueListParameterOut', LocalDataProperty: plant_PlantCode, ValueListProperty: 'PlantCode' }]
  });
  lab @(Common.ValueList: {
    CollectionPath : 'Laboratories',
    Parameters     : [{ $Type: 'Common.ValueListParameterOut', LocalDataProperty: lab_LabCode, ValueListProperty: 'LabCode' }]
  });
};

annotate LIMSService.Forecasts with {
  plant @(Common.ValueList: {
    CollectionPath : 'Plants',
    Parameters     : [{ $Type: 'Common.ValueListParameterOut', LocalDataProperty: plant_PlantCode, ValueListProperty: 'PlantCode' }]
  });
  lab @(Common.ValueList: {
    CollectionPath : 'Laboratories',
    Parameters     : [{ $Type: 'Common.ValueListParameterOut', LocalDataProperty: lab_LabCode, ValueListProperty: 'LabCode' }]
  });
};

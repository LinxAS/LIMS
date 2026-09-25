namespace lims;

entity Plants {
  key PlantCode : String(4);
  PlantName     : String(50);
}

entity Laboratories {
  key LabCode : String(20);
  LabName     : String(50);
  plant       : Association to Plants;
}

entity Materials {
  key MaterialNumber : String(18);
  Description        : String(100);
  BaseUoM            : String(3) default 'KG';
}

entity Specifications {
  key SpecNumber  : String(18);
  Description     : String(100);
  material        : Association to Materials;
  IsZRawMat       : Boolean default false;
  IsZFrag         : Boolean default false;
}

entity Requisitions {
  key RequisitionID  : String(10);
  RequisitionName    : String(100);
  RequestedFor       : String(50);
  NeededBy           : Date;
  plant              : Association to Plants;
  lab                : Association to Laboratories;
  Category           : String(30);
  Status             : String(20) default 'Draft';
  CreatedBy          : String(30);
  CreatedOn          : Date;
  items              : Composition of many RequisitionItems on items.requisition = $self;
}

entity RequisitionItems {
  key ID          : UUID;
  requisition     : Association to Requisitions;
  ItemNumber      : Integer;
  spec            : Association to Specifications;
  material        : Association to Materials;
  Quantity        : Decimal(10,3);
  UoM             : String(3) default 'KG';
  AvailableQty    : Decimal(10,3);
  Criticality     : Integer;
}

entity Containers {
  key ContainerID   : String(15);
  spec              : Association to Specifications;
  material          : Association to Materials;
  plant             : Association to Plants;
  lab               : Association to Laboratories;
  MfgLotNo          : String(20);
  InitialQuantity   : Decimal(10,3);
  RemainingQuantity : Decimal(10,3);
  UoM               : String(3) default 'KG';
  ExpirationDate    : Date;
  Status            : String(10) default 'Available';
  SafetyH           : String(10);
  SafetyS           : String(10);
  SafetyR           : String(10);
  GHSHazardClass    : String(50);
  Owner             : String(30);
  Comments          : String(500);
  dispensingDetails : Composition of many DispensingRecords
                        on dispensingDetails.container = $self;
}

entity DispensingRecords {
  key ID            : UUID;
  container         : Association to Containers;
  reqItem           : Association to RequisitionItems;
  ChildContainerID  : String(15);
  DispensingDate    : Date;
  QtyIssued         : Decimal(10,3);
  UoM               : String(3);
  DispensedBy       : String(30);
}

entity Inventory {
  key ID               : UUID;
  spec                 : Association to Specifications;
  material             : Association to Materials;
  plant                : Association to Plants;
  TotalQuantity        : Decimal(10,3);
  TotalRequisitioned   : Decimal(10,3);
  TotalAvailable       : Decimal(10,3);
  TotalOnOrder         : Decimal(10,3);
  UoM                  : String(3) default 'KG';
  StockFlag            : String(10) default 'OK';
  Criticality          : Integer;
  stockOrders          : Composition of many StockOrders on stockOrders.inventory = $self;
}

entity StockOrders {
  key ID          : UUID;
  inventory       : Association to Inventory;
  OrderType       : String(5);
  OrderNumber     : String(15);
  RequestedQty    : Decimal(10,3);
  UoM             : String(3);
  Status          : String(20);
}

entity Forecasts {
  key ForecastID  : String(10);
  ForecastName    : String(100);
  RequestedFor    : String(50);
  NeededBy        : Date;
  plant           : Association to Plants;
  lab             : Association to Laboratories;
  Category        : String(30);
  Status          : String(20) default 'Draft';
  CreatedBy       : String(30);
  DateSubmitted   : Date;
  items           : Composition of many ForecastItems on items.forecast = $self;
}

entity ForecastItems {
  key ID                : UUID;
  forecast              : Association to Forecasts;
  ItemNumber            : Integer;
  spec                  : Association to Specifications;
  material              : Association to Materials;
  Quantity              : Decimal(10,3);
  UoM                   : String(3) default 'KG';
  AvailableQtyInPlant   : Decimal(10,3);
  ItemStatus            : String(20);
  RequestedFor          : String(30);
  NeededBy              : Date;
}

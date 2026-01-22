@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CDS FOR LOT CARD PRINT'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZLOT_CARD_CDS
  as select distinct from zbeam_creat_tab          as a
    left outer join       I_MaterialDocumentItem_2 as b on  b.MaterialDocument               = a.mat_doc311
                                                        and b.MaterialDocumentYear           = a.mat_doc_year
                                                        and b.SpecialStockIdfgSalesOrder     = a.salesdoc
                                                        and b.SpecialStockIdfgSalesOrderItem = a.soitem
   left outer join I_ManufacturingOrder as c on a.productionorder = c.ManufacturingOrder                                                     and b.GoodsMovementIsCancelled       = 'X'
                                                        
{
  key a.beamno          as LOTno,
  key a.productionorder as ProductionOrder
}
where
  a.productionorder is not initial and c.MfgOrderActualCompletionDate is null

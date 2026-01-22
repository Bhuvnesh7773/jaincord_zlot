class ZCL_LOT_CARD_HTTP definition
  public
  create public .

public section.

  interfaces IF_HTTP_SERVICE_EXTENSION .
protected section.
private section.
ENDCLASS.



CLASS ZCL_LOT_CARD_HTTP IMPLEMENTATION.


  method IF_HTTP_SERVICE_EXTENSION~HANDLE_REQUEST.

  DATA(req) = request->get_form_fields(  ).
    response->set_header_field( i_name = 'Access-Control-Allow-Origin' i_value = '*' ).
    response->set_header_field( i_name = 'Access-Control-Allow-Credentials' i_value = 'true' ).

data :  prodorder type I_MfgOrderConfirmation-ManufacturingOrder.
DATA : LOTNC8 TYPE C LENGTH 8 .

  data(LotNo) = value #( req[ name = 'lotno' ]-value optional ) .
  data(ProductionOrder) = value #( req[ name = 'productionno' ]-value optional ) .
  data(type) = value #( req[ name = 'type' ]-value optional ) .


  prodorder = |{ ProductionOrder ALPHA = in }|.
  ProductionOrder = prodorder.

  LOTNC8 = LotNo .
  LotNo = |{ LOTNC8 ALPHA = in }|.




    IF type = 'Internal' .


DATA(pdf1) = zlot_card_process_job_card=>read_posts( LotNo = LotNo prodorder = ProductionOrder ) .


      ELSEIF type = 'Production' .


  pdf1 = zlot_card_class=>read_posts( LotNo = LotNo prodorder = ProductionOrder ) .

  ENDIF.

  response->set_text( pdf1 ).
  endmethod.
ENDCLASS.

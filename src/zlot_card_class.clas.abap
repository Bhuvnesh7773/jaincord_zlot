CLASS zlot_card_class DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.



    INTERFACES if_oo_adt_classrun .
    CLASS-DATA : access_token TYPE string .
    CLASS-DATA : xml_file TYPE string .
    TYPES :
      BEGIN OF struct,
        xdp_template TYPE string,
        xml_data     TYPE string,
        form_type    TYPE string,
        form_locale  TYPE string,
        tagged_pdf   TYPE string,
        embed_font   TYPE string,
      END OF struct."

    CLASS-METHODS :
      read_posts
        IMPORTING
                  VALUE(lotno)     TYPE string
                  VALUE(prodorder) TYPE string


        RETURNING VALUE(result12)  TYPE string
        RAISING   cx_static_check .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZLOT_CARD_CLASS IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
*    DATA(test)  = read_posts( fromdate = '20240101' todate = '20250101' ProductoldID = '9000000201' ProductexternalID = 'sff00041434' Division = '11') .
  ENDMETHOD.


  METHOD read_posts.


    IF prodorder IS NOT INITIAL . " AND lotno IS INITIAL.

      SELECT manufacturingorder ,batch FROM i_manufacturingorder WHERE manufacturingorder = @prodorder
      INTO @DATA(wsdata).
      ENDSELECT.


      lotno = wsdata-batch.
    ENDIF.

    SELECT SINGLE  z~soitem,
                   z~salesdoc
                   FROM zbeam_report AS z
                    WHERE z~beamno = @lotno  INTO @DATA(it_data1).



    DATA : sorder TYPE i_salesdocumentitem-salesdocument.
    sorder = |{ it_data1-salesdoc ALPHA = IN }|.

    SELECT SINGLE
                   FROM zbeam_report AS a
                   LEFT OUTER JOIN  i_manufacturingorder AS b ON b~batch = a~beamno
*                 LEFT OUTER JOIN I_SALESORDER AS c on c~SalesOrder = a~Salesdoc
                   LEFT OUTER JOIN i_salesdocumentitem AS s ON s~salesdocument = @sorder
                    AND s~salesdocumentitem = a~soitem
                   LEFT OUTER JOIN  i_productdescription AS i ON i~product = s~material AND i~language = 'E'
                   LEFT OUTER JOIN  i_product AS greig ON greig~product = a~material

                   LEFT OUTER JOIN  i_product AS p ON p~product = a~material
                   LEFT OUTER JOIN  i_ordertypetext AS j ON j~ordertype = b~manufacturingordertype AND j~language = 'E'
                   LEFT OUTER JOIN  i_customfieldcodelisttext AS pack ON pack~code = s~yy1_packingtype_sdi
                                          AND pack~language = 'E' AND pack~customfieldid = 'YY1_PACKINGTYPE'

                   LEFT OUTER JOIN  zcustom_tab AS sub ON sub~code = greig~yy1_subcategorycode_prd
                                                         AND sub~custom_field = 'SubCategory Code'

              FIELDS

                  a~soitem,
                  a~salesdoc,
                  a~Issubatch as batch ,
                  a~beamno AS beamno,
                  a~material AS greige_mat,
                  sub~description_code AS subcategorycode, " greige

                  a~matdes,
                  a~partyname,
                  a~shadenum,
                  a~totalqty,
                  a~noofpcs,
                  a~postingdate,
                  a~finishwidth,
                  a~lotcardtype,
                  a~weaver_name,
                  a~bilno,
                  b~manufacturingorder,
                  b~mfgorderplannedtotalqty AS orderqty,
*                b~BillOfOperationsMaterial,
                  b~manufacturingordertype,
                  j~ordertypename,
*                c~SALESORDER,
                  s~yy1_color_sdi,
                  s~yy1_gsm_sdi,
                  s~yy1_lightsource_sdi,
                  s~yy1_dyeprint_sdi,
                  s~yy1_processloss_sdi AS yy1_shrinkageloss_sdi,
                  s~yy1_packingtype_sdi,
                  pack~description AS packingtype,
                  s~purchaseorderbycustomer,
                  s~material,
                  s~yy1_width_sdi,
                  i~productdescription,
                  p~yy1_greigewidth1_prd ,
                  p~yy1_fabricweightglm1_prd,

                  p~yy1_fabricweightgsm1_prd

                   WHERE a~beamno = @lotno  INTO @DATA(it_data).

    SELECT
                    FROM zbeam_report
                    FIELDS quantity,sno,
                    Issubatch as batch ,
                     baleno , storageloc ,bilno
                    WHERE beamno = @lotno
                    INTO TABLE @DATA(it_data3).

    SELECT FROM i_mfgorderoperationvh AS a
    inNER jOIN I_MfgOrderOperationWithStatus as b on b~ManufacturingOrder = a~ManufacturingOrder
                                                and  b~ManufacturingOrderOperation_2 = a~ManufacturingOrderOperation
                                                and  b~OperationIsDeleted   <> 'X'
    FIELDS
    a~manufacturingorder,
    a~manufacturingorderoperation,
    a~mfgorderoperationtext
    WHERE a~manufacturingorder = @it_data-manufacturingorder

    ORDER BY a~manufacturingorderoperation
    INTO TABLE @DATA(it_routing).


    IF it_data IS NOT INITIAL .

      DATA : printname TYPE string .

      printname = |{ it_data-lotcardtype } JOB CARD PRINT| .

      it_data-salesdoc  = |{ it_data-salesdoc ALPHA = OUT }| .



*      IF it_data-yy1_subcategorycode_prd = '0R'.
*        typename = 'Regular'.
*      ELSEIF it_data-yy1_subcategorycode_prd = '0S'.
*        typename = 'Sustainable'.
*      ELSE.
*        typename = it_data-yy1_subcategorycode_prd.
*      ENDIF.


      DATA : zbillnoo  TYPE string .

      DATA(it_bill) = it_data3 .

      SORT it_bill BY bilno .
      DELETE ADJACENT DUPLICATES FROM it_bill COMPARING bilno .
      LOOP AT it_bill INTO DATA(wa1) .
        zbillnoo = |{ zbillnoo } { wa1-bilno }, | .
      ENDLOOP.

      DATA(lv_xml) =
     |<form1>| &&
     |   <SUB_M>| &&
     |      <SUB1>| &&
     |         <CustomerName>{ it_data-partyname }</CustomerName>| &&
     |         <FGMaterialCode>{ zbillnoo }</FGMaterialCode>| &&
     |         <FGMaterialDescription>{ it_data-productdescription }</FGMaterialDescription>| &&
     |         <GreigeMaterialCode>{ it_data-greige_mat }</GreigeMaterialCode>| &&
     |         <GreigeMaterialDescription>{ it_data-matdes }</GreigeMaterialDescription>| &&
     |         <SaleOrderNo>{ it_data-salesdoc }</SaleOrderNo>| &&
     |         <COLOUR>{ it_data-yy1_color_sdi }</COLOUR>| &&
     |         <printname>{ printname }</printname>| &&
     |         <WeaverName>{ it_data-weaver_name }</WeaverName>| &&
     |      </SUB1>| &&
     |      <SUB2>| &&
     |         <LotNumber>{ it_data-beamno }</LotNumber>| &&
     |         <ProductionOrderNo>{ it_data-manufacturingorder ALPHA = OUT }</ProductionOrderNo>| &&
     |         <OrderQty>{ it_data-orderqty }</OrderQty>| &&
     |         <Dye_print>{ it_data-yy1_dyeprint_sdi }</Dye_print>| &&
     |         <LotCreationDate>{ it_data-postingdate }</LotCreationDate>| &&
     |         <GreigWidth> { it_data-yy1_greigewidth1_prd ALPHA = OUT }</GreigWidth>| &&
     |         <GreigGSM> { it_data-yy1_fabricweightgsm1_prd ALPHA = OUT }</GreigGSM>| &&
*     |         <Type> { it_data-YY1_SubCategoryCode_PRD }</Type>| &&
     |         <Type> { it_data-subcategorycode }</Type>| &&
     |         <PackingType> { it_data-packingtype }</PackingType>| &&
     |      </SUB2>| &&
     |      <SUB3>| &&
     |         <PartyPONumber>{ it_data-purchaseorderbycustomer }</PartyPONumber>| &&
     |         <FinishWidth>{ it_data-yy1_width_sdi }</FinishWidth>| &&
     |         <ReqGSM>{ it_data-yy1_gsm_sdi }</ReqGSM>| &&
     |         <LightSource>{ it_data-yy1_lightsource_sdi }</LightSource>| &&
     |         <TotalMtr>{ it_data-totalqty }</TotalMtr>| &&
     |         <NoofPcs>{ it_data-noofpcs ALPHA = OUT }</NoofPcs>| &&
     |         <GreigeGLM>{ it_data-yy1_fabricweightglm1_prd }</GreigeGLM>| &&
     |         <AllocatedShrinkage>{ it_data-yy1_shrinkageloss_sdi } %</AllocatedShrinkage>| &&
     |      </SUB3>| &&
     |         <OrderType>{ it_data-ordertypename }({ it_data-manufacturingordertype })</OrderType>| &&
     |   </SUB_M>| &&
     |   <Subform2>| &&
     |      <Table1>| .

      DATA : rout1  TYPE c LENGTH 20,
             rout2  TYPE c LENGTH 20,
             rout3  TYPE c LENGTH 20,
             rout4  TYPE c LENGTH 20,
             rout5  TYPE c LENGTH 20,
             rout6  TYPE c LENGTH 20,
             rout7  TYPE c LENGTH 20,
             rout8  TYPE c LENGTH 20,
             rout9  TYPE c LENGTH 20,
             rout10 TYPE c LENGTH 20,
             rout11 TYPE c LENGTH 20,
             rout12 TYPE c LENGTH 20,
             rout13 TYPE c LENGTH 20,
             rout14 TYPE c LENGTH 20,
             rout15 TYPE c LENGTH 20,
             rout16 TYPE c LENGTH 20.

      LOOP AT it_routing INTO DATA(wa_rout).

*        SPLIT wa_rout-mfgorderoperationtext AT ' ' INTO DATA(r1) DATA(r2).

        REPLACE ALL OCCURRENCES OF 'PROCESS' IN wa_rout-mfgorderoperationtext WITH ''.
        DATA(r1) =  wa_rout-mfgorderoperationtext .


*        rout1 = 'LOCATION' .
        rout1 = 'BATCH' .

        IF rout1 IS INITIAL .
          rout1 = r1 .

        ELSEIF rout2 IS INITIAL .
          rout2 = r1 .
        ELSEIF rout3 IS INITIAL .
          rout3 = r1 .
        ELSEIF rout4 IS INITIAL .
          rout4 = r1 .
        ELSEIF rout5 IS INITIAL .
          rout5 = r1 .
        ELSEIF rout6 IS INITIAL .
          rout6 = r1 .
        ELSEIF rout7 IS INITIAL .
          rout7 = r1 .
        ELSEIF rout8 IS INITIAL .
          rout8 = r1 .
        ELSEIF rout9 IS INITIAL .
          rout9 = r1 .
        ELSEIF rout10 IS INITIAL .
          rout10 = r1 .
        ELSEIF rout11 IS INITIAL .
          rout11 = r1 .
        ELSEIF rout12 IS INITIAL .
          rout12 = r1 .
        ELSEIF rout13 IS INITIAL .
          rout13 = r1 .
        ELSEIF rout14 IS INITIAL .
          rout14 = r1 .
        ELSEIF rout15 IS INITIAL .
          rout15 = r1 .
        ELSEIF rout16 IS INITIAL .
          rout16 = r1 .

        ENDIF.

      ENDLOOP.

      lv_xml = lv_xml  &&
      |  <Routing>| &&
      |     <Cell3>{ rout1 }</Cell3>| &&
      |     <Cell4>{ rout2 }</Cell4>| &&
      |     <Cell5>{ rout3 }</Cell5>| &&
      |     <Cell6>{ rout4 }</Cell6>| &&
      |     <Cell7>{ rout5 }</Cell7>| &&
      |     <Cell8>{ rout6 }</Cell8>| &&
      |     <Cell9>{ rout7 }</Cell9>| &&
      |     <Cell10>{ rout8 }</Cell10>| &&
      |     <Cell11>{ rout9 }</Cell11>| &&
      |     <Cell12>{ rout10 }</Cell12>| &&
      |     <Cell13>{ rout11 }</Cell13>| &&
      |     <Cell14>{ rout12 }</Cell14>| &&
      |     <Cell15>{ rout13 }</Cell15>| &&
      |     <Cell16>{ rout14 }</Cell16>| &&
      |     <Cell17>{ rout15 }</Cell17>| &&
      |     <Cell18>{ rout16 }</Cell18>| &&
      |  </Routing>| .


*         SORT it_data3 BY sno .

 data : sno type i .
*SORT it_data3 BY baleno ASCENDING Quantity DESCENDING ..
SORT it_data3 BY Batch ASCENDING .


      LOOP AT it_data3 INTO DATA(wa_data).
      sno = sno + 1.

          lv_xml = lv_xml  &&

       |         <Row4>| &&
       |            <SRNO>{ sno }</SRNO>| &&
       |            <GREIGE>{ wa_data-quantity }</GREIGE>| &&
       |            <Batch>{ wa_data-baleno }</Batch>| &&
*       |            <DRUM>{ wa_data-storageloc }</DRUM>| &&
       |            <DRUM>{ wa_data-Batch }</DRUM>| &&
       |            <SOFOLINA></SOFOLINA>| &&
       |            <SOFTLOW></SOFTLOW>| &&
       |            <JET></JET>| &&
       |            <STENTER></STENTER>| &&
       |            <FOLDING></FOLDING>| &&
       |            <XYZ></XYZ>| &&
       |            <ABC></ABC>| &&
       |            <IJK></IJK>| &&
       |            <TBH></TBH>| &&
       |         </Row4>| .

        ENDLOOP.

        lv_xml = lv_xml  &&
     |      </Table1>| &&
     |   </Subform2>| &&
     |</form1>| .



        CALL METHOD zadobe_print=>adobe(
          EXPORTING
            form_name = 'LOT_CARD_PRINT'
            xml       = lv_xml
          RECEIVING
            result    = result12 ).


      ELSE .
* result12 = 'ERROR:- Print Not Found' .
        result12 = 'RVJST1I6LSBQcmludCBOb3QgRm91bmQ=' .

      ENDIF.

    ENDMETHOD.
ENDCLASS.

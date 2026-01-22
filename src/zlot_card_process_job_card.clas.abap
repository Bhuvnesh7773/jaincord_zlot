CLASS zlot_card_process_job_card  DEFINITION
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



CLASS zlot_card_process_job_card IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
*    DATA(test)  = read_posts( lotno = ''    prodorder =   '' ) .
  ENDMETHOD.


  METHOD read_posts.

    IF prodorder IS NOT INITIAL . " AND lotno IS INITIAL.

      SELECT manufacturingorder ,batch FROM i_manufacturingorder WHERE manufacturingorder = @prodorder
      INTO @DATA(wsdata).
      ENDSELECT.

      lotno = wsdata-batch.
    ENDIF.





    SELECT SINGLE
                       FROM zbeam_report AS a
                       LEFT OUTER JOIN  i_manufacturingorder AS b ON b~batch = a~beamno
*                 LEFT OUTER JOIN I_SALESORDER AS c on c~SalesOrder = a~Salesdoc
                       LEFT OUTER JOIN i_salesdocumentitem AS s ON s~salesdocument = a~salesdoc
                        AND s~salesdocumentitem = a~soitem
                       LEFT OUTER JOIN  i_productdescription AS i ON i~product = s~material AND i~language = 'E'
                       LEFT OUTER JOIN  i_product AS p ON p~product = a~material
                       LEFT OUTER JOIN  i_ordertypetext AS j ON j~ordertype = b~manufacturingordertype AND j~language = 'E'
                       LEFT OUTER JOIN  i_customfieldcodelisttext AS pack ON pack~code = s~yy1_packingtype_sdi
                                              AND pack~language = 'E' AND pack~customfieldid = 'YY1_PACKINGTYPE'
                       LEFT OUTER JOIN  zcustom_tab AS sub ON sub~code = p~yy1_subcategorycode_prd
                                                             AND sub~custom_field = 'SubCategory Code'

                  FIELDS

                      a~soitem,
                      a~salesdoc,
                      a~remark ,
                      a~issubatch AS batch ,
                      a~beamno AS beamno,
                      a~material AS greige_mat,
                      a~matdes,
                      a~partyname,
                      s~distributionchannel ,
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
*                  p~yy1_subcategorycode_prd as SubCategoryCode,
                      sub~description_code AS subcategorycode,
                      p~yy1_fabricweightgsm1_prd
                       WHERE a~beamno = @lotno  INTO @DATA(it_data).




    SELECT FROM zbeam_report  AS a
           LEFT JOIN i_storagelocation AS b ON ( a~storageloc = b~storagelocation AND a~plant = b~plant  )
           FIELDS  a~quantity,
           a~sno,
           a~recquantity,
           a~batch AS batch1 ,
           a~issubatch AS batch ,
           a~baleno ,
           a~material ,
           a~storageloc AS storageloc1 ,
           a~bilno ,
           b~storagelocationname AS storageloc

                    WHERE a~beamno = @lotno
                    INTO TABLE @DATA(it).


    """""'
    SELECT  FROM i_materialdocumentitem_2 AS a
    FIELDS
    a~materialdocument ,
    a~materialdocumentyear ,
    a~materialdocumentitem ,
    a~material ,
    a~batch ,
    a~issgorrcvgbatch ,
    a~goodsmovementtype ,
    a~quantityinbaseunit

    FOR ALL ENTRIES IN @it
    WHERE a~material = @it-material
     AND  a~batch = @it-batch1
     AND  a~goodsmovementiscancelled <> 'X'
     AND ( a~goodsmovementtype = '101' OR a~goodsmovementtype = '561' or a~goodsmovementtype = '501' )

    INTO TABLE @DATA(initalbatch)  .

*    IF initalbatch IS INITIAL .

    SELECT  FROM i_materialdocumentitem_2 AS a

    FIELDS
    a~materialdocument ,
    a~materialdocumentyear ,
    a~materialdocumentitem ,
    a~material ,
    a~batch ,
    a~issgorrcvgbatch ,
    a~goodsmovementtype ,
    a~quantityinbaseunit

    FOR ALL ENTRIES IN @it
    WHERE a~material = @it-material
     AND  a~issgorrcvgbatch = @it-batch1
     AND  a~goodsmovementiscancelled <> 'X'
     AND  a~storagelocation    = 'TT01'
     AND  a~goodsmovementtype  = '311'

    INTO TABLE @DATA(initalbatch2)  .



*    ENDIF.



    """""'

*    SELECT * FROM ZBATCH_QTY AS a
*
*
*    FOR ALL ENTRIES IN @it
*    WHERE a~batch =  @it-Batch
*    AND a~StorageLocation =  @it-storageloc1
*    AND a~Material =  @it-material
*
*
*   INTO TABLE @DATA(IT_BATCHQTY) .
*
*
*"""""""
* LOOP AT it ASSIGNING FIELD-SYMBOL(<MS1>) .
* READ TABLE IT_BATCHQTY INTO DATA(WA11) WITH KEY batch = <MS1>-Batch
* Material = <MS1>-Material StorageLocation = <MS1>-storageloc1 .
*
* IF WA11-GoodsMovementType = '101' .
* <MS1>-Quantity = WA11-BillQuantity_MMI .
* else .
*  <MS1>-Quantity =  <MS1>-Quantity .
* ENDIF.
*
* ENDLOOP.
    """""""""


    SORT it BY baleno ASCENDING.



    DATA : sno TYPE i VALUE 0 .
    DATA(totdata) = lines( it ) .

    IF totdata > 40 .
      DATA(fstlop) =  40.
    ELSE .
      fstlop = totdata.
    ENDIF .

    IF totdata < 41 .
      DATA(seclop) =  0.
    ELSE .
      seclop = totdata - 40 .
    ENDIF .








    DATA : zbillnoo TYPE string,
           zweaver  TYPE string,
           zparty   TYPE string.

    DATA(it_bill) = it .

    SORT it_bill BY bilno .
    DELETE ADJACENT DUPLICATES FROM it_bill COMPARING bilno .
    LOOP AT it_bill INTO DATA(wa1) .
      zbillnoo = |{ zbillnoo } { wa1-bilno }, | .
    ENDLOOP.

    SELECT weaver_name
      FROM zbeam_report
      WHERE beamno = @lotno
      INTO TABLE @DATA(it_weaver).

    SORT it_weaver BY weaver_name.
    DELETE ADJACENT DUPLICATES FROM it_weaver COMPARING weaver_name.

    LOOP AT it_weaver INTO DATA(wa_weaver).
      zweaver = |{ zweaver } { wa_weaver-weaver_name },|.
    ENDLOOP.

*   it_data-weaver_name

    IF it_data-distributionchannel = '04'  .
      zparty =   it_data-partyname  .

    ENDIF .






*      SORT it BY baleno ASCENDING quantity DESCENDING ..
    SORT it BY batch ASCENDING  ..




    DATA(lv_xml) =
|<form1>| &&
|   <BODYS>| &&
|      <multiplepage>{ it_data-beamno ALPHA = OUT }</multiplepage>| &&
*      | <waver>{ it_data-weaver_name }</waver>| &&
      | <waver>{ zweaver }  { zparty }</waver>| &&
      | <date1>{ it_data-postingdate }</date1>| &&
      | <multiplepage></multiplepage>| &&
      | <bpo>{ it_data-salesdoc  ALPHA = OUT }</bpo>| &&
      | <quality>{ it_data-matdes }</quality>| &&
      | <shade>{ it_data-yy1_color_sdi }</shade>| &&
      | <lightsource>{ it_data-yy1_lightsource_sdi }</lightsource>| &&
*      | <challan>{ it_data-bilno }</challan>| &&
      | <challan>{ zbillnoo }</challan>| &&
      | <pcs>{ it_data-noofpcs }</pcs>| &&
      | <tmtr>{ it_data-totalqty }</tmtr>| &&
      | <gwidth>{ it_data-yy1_greigewidth1_prd ALPHA = OUT }</gwidth>| &&
      | <reqgsm>{ it_data-yy1_gsm_sdi }</reqgsm>| &&
      | <JOBCARD> PROCESS JOB CARD </JOBCARD>| &&
      | <REMARK>{ it_data-remark }</REMARK>| &&

|   </BODYS>| &&
|   <Subform1>| &&
|      <tab1>| &&
|         <Table1>| .


    DATA : actqty TYPE p DECIMALS 3 LENGTH 16 .
    DO fstlop TIMES .
      sno = sno + 1.
      READ TABLE it INDEX sno INTO DATA(it1) .

      READ TABLE initalbatch INTO DATA(ms1) WITH KEY material = it1-material batch = it1-batch1 .
      IF sy-subrc = 0 .
        actqty = ms1-quantityinbaseunit .
      ELSE .
        READ TABLE initalbatch2 INTO DATA(ms2) WITH KEY material = it1-material issgorrcvgbatch = it1-batch1 .
        actqty = ms2-quantityinbaseunit .
      ENDIF .


      lv_xml = lv_xml &&

    |            <Row1>| &&
    |               <SNO>{ sno }</SNO>| &&
    |               <GREIGE>{  it1-quantity }</GREIGE>| &&
    |               <BALE>{ it1-baleno  }</BALE>| &&
    |               <LOCATION>{ it1-storageloc }</LOCATION>| &&
*    |               <ACTQTY>{  it1-recquantity }</ACTQTY>| &&
    |               <ACTQTY>{ actqty }</ACTQTY>| &&
      |               <billno>{ it1-bilno }</billno>| &&
    |            </Row1>| .

      CLEAR: it1,ms1,ms2,actqty .
    ENDDO .


    lv_xml = lv_xml &&
    |         </Table1>| &&
    |         <Table2>| .
    DO seclop TIMES .
      sno = sno + 1.
      READ TABLE it INDEX sno INTO it1 .

      READ TABLE initalbatch INTO ms1 WITH KEY material = it1-material batch = it1-batch1 .
      IF sy-subrc = 0 .
        actqty = ms1-quantityinbaseunit .
      ELSE .
        READ TABLE initalbatch2 INTO ms2 WITH KEY material = it1-material issgorrcvgbatch = it1-batch1 .
        actqty = ms2-quantityinbaseunit .
      ENDIF .


      lv_xml = lv_xml &&

    |            <Row1>| &&
    |               <SNO>{ sno }</SNO>| &&
    |               <GREIGE>{  it1-quantity }</GREIGE>| &&
    |               <BALE>{ it1-baleno  }</BALE>| &&
    |               <LOCATION>{ it1-storageloc }</LOCATION>| &&
*    |               <ACTQTY>{  it1-recquantity }</ACTQTY>| &&
    |               <ACTQTY>{ actqty }</ACTQTY>| &&
    |               <billno>{ it1-bilno }</billno>| &&
    |            </Row1>| .

      CLEAR: it1,ms1,ms2,actqty .
    ENDDO .


    lv_xml = lv_xml &&
    |         </Table2>| &&
    |      </tab1>| &&
    |   </Subform1>| &&
    |</form1>| .


    CALL METHOD zadobe_print=>adobe(
      EXPORTING
        form_name = 'PROCESS_JOB_CARD_PP_SH'
        xml       = lv_xml
      RECEIVING
        result    = result12 ).

*      ELSE .
** result12 = 'ERROR:- Print Not Found' .
*        result12 = 'RVJST1I6LSBQcmludCBOb3QgRm91bmQ=' .
*
*      ENDIF.

  ENDMETHOD.
ENDCLASS.

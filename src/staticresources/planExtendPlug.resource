if (typeof(jinya)          == "undefined") jinya          = {};
if (typeof(jinya.app)      == "undefined") jinya.app      = {};
if (typeof(jinya.app.jinyaPlanExtend)      == "undefined") jinya.app.jinyaPlanExtend = {};

;(function($){
	// 定数情報
	var _CONST_PRICE_ROOM_TYPE = '室料';			// 室料のKeyWord定義する
	var _CONST_DATAKEY = 'jinyaPlanExtend';		// JsのData構造にクラス情報可能標識用変数ID
	// プランのプラン明細展開するHTML情報
	var _CONST_NOITEM_TEMPLATE = "<tr class='$appendTrClassNm$'><td colspan='$colspan$' style='margin-right: 200px;' >$msg_notfound_title$</td></tr>";
	var _CONST_ADDITEM_TEMPLATE = 
			"<tr class='$appendTrClassNm$'><td colspan='$colspan$'>" +
				"<input type='hidden' id='$groupIndex$_workHidItem' />"+
        	  	"<table style='width:$tableWidth$;' class='list' border='0' cellpadding='0' cellspacing='0'>" +
        	     	"<tHead class='rich-table-thead'>" +
        	        	"<tr class='headerRow' nowrap='nowrap'>" +
        	              "<th class='headerRow' nowrap='nowrap' style='width:70%'>$msg_productnm_title$</th>" +
        	              "<th class='headerRow' nowrap='nowrap' style='width:30%'>$msg_unitprice_title$</th></tr>" +
        	         "</tHead>" +
        	         "<tBody>" +
        	         "$tBodyContent$" +
		    		 "</tBody>" +
		    		 "<tFoot><tr><td style='text-align: right;'><span style='margin-right:3px'>$msg_summmary_title$：</span></td><td style='text-align: right;'><span id='$summaryPriceId$' style='float:right;margin-right: 3px'></span></td></tr>"+
		    		 "</tFoot> " +
		    	"</table></td>" +
		    "</tr>";
	var _CONST_ADDITEM_DTEAIL_IMG_TEMPLATE = 
		    "<img onmouseover='this.className = \"lookupIconOn\";this.className = \"lookupIconOn\";'" +
	    		"onmouseout='this.className = \"lookupIcon\";this.className = \"lookupIcon\";'" +
	    		"onfocus='this.className = \"lookupIconOn\";' onblur='this.className = \"lookupIcon\";'" +
	    		"class='lookupIcon' src='/s.gif' style='cursor: pointer;'" +
	    		//"name='$groupIndex$_productPopup_$rowidx$' onclick='javascript:jinya.app.jinyaPlanExtend.openProdutWin(\"$groupIndex$\",\"$rowidx$\",\"$syncInfItemId$\")'/>";
	    		"id='$groupIndex$_productPopup_$rowidx$' rowidx='$rowidx$' />";
	var _CONST_ADDITEM_DTEAIL_TEMPLATE = 
		    	"<tr><td style='background-color: #FFEBCD;'>" + 
		        "<input type='text'style='width:180px' value='$productName$' id='$groupIndex$_prodName_$rowidx$' rowidx='$rowidx$' $readonly$ />" +
		        "$IMG_TEMPLATE$"+
		        "<input type='hidden' value='$productId$' id='$groupIndex$_prodid_$rowidx$' />" +
		        "<input type='hidden' value='$planDetailId$' id='$groupIndex$_planid_$rowidx$' />"+
		        "<input type='hidden' id='$groupIndex$_workHidActType_$rowidx$' value='$childActionType$' /></td>" +
		        "<td style='background-color: #FFEBCD;text-align: right;'>" +
		        "<input type='text' style='text-align:right;' id='$groupIndex$_price_$rowidx$' class='$childclsItemClass$'  value='$memoryPrice$' rowidx='$rowidx$'  data-actiontype = '$childActionType$' $readonly$/></td></tr>";
	// 初期化関数BIND
	$.fn.jinyaPlanExtend = function(options){
		var defaults = {
			actionOpenImg : "/resource/AppImages/extend/jiahao.png",
			actionCloseImg : "/resource/AppImages/extend/jianhao.png",
			colspanNum : 4,												// TRの表示区間の１TDのCOLSPAN数値
			groupIndex : "",												// 該当プラン展開自身所属するINDEX
			appendTrClassNm : "_jinyaPlanExtend_appendTr_classNm",
			tableWidth : "60%",
			// 2016/08/30 英語化対応
			labels : {
				NOFOUND:'データ詳細がありません。',
				PRODUCTNM: '商品名',
				UNITPRICE: '単価',
				SUMMARY: '合計'
			}
		}
		// 設定のパラメータから上書きする
		setting = $.extend({},defaults,options);
		// 処理クラス関数を初期、MemoryにSaveする
        return this.each(function(){
            var ci = new PlanItem($(this),setting); //实例化
            $(this).data(_CONST_DATAKEY,ci); //将实例化对象缓存
        });
    }

    /**
     * 构造函数
     * @param obj
     * @param settings
     * @constructor
     */
    function PlanItem(obj,settings){
        this._obj = obj;
        this._actionOpenImg = settings.actionOpenImg;
        this._actionCloseImg = settings.actionCloseImg;
        this._colspanNum = settings.colspanNum;
        this._selectorRoot = settings.selectorRoot;
        this._planInputField = settings.planInputField;
        this._raceRateCalFun = settings.raceRateCalFunction;
        //this._raceRatePriceField = settings.raceRatePriceField;			// ラクレット設定情報：ベースプランを選べる場合、プラン総金額情報を維持する（室料も含めて金額）
        //this._planNoRoomPriceField = settings.planNoRoomPriceField;		// ベースプランのプラン総金額情報を格納する（プラン金額に、室料はなし）  室料を計算したい場合、(_raceRatePriceField - _planNoRoomPriceField)で計算が必要
        this._planSetupSyncField = settings.planSetupSyncField;
        this._remotePlanQuery = settings.remotePlanQuery;
        this._remoteProdQuery = settings.remoteProdQuery;
        this._startfun = settings.startfun;
        this._endfun = settings.endfun;
       	this._appendTrClassNm = settings.appendTrClassNm;
       	this._groupIndex = settings.groupIndex;
       	this._summaryPriceField = settings.summaryPriceField;			// プラン明細情報
       	this._isReadonlyFun = settings.isReadonlyFun;					// Breakdown明細情報表示する場合、Readonlyするがどうか判断用関数
    	this._tableWidth = settings.tableWidth;
    	this._oncompleteFun = setting.oncompleteFun;					// 全部情報は処理済み、画面表示完了から該当Funを呼出する
    	this._labels = setting.labels;
    }

    PlanItem.prototype.open = function () {
    	// プラン明細を取得、画面に表示する
    	$this = this;

    	// ステータス制御属性を設定する
		$this._obj.attr("isOpenStatus","false");
		$this._obj.attr("src",this._actionCloseImg);
		// groupIndex
		var groupIndex = $this._groupIndex;
		// プラン明細に設定する情報はMemoryにコピーする
		hashMap.Clear();		// CommJs共通クラス
		var syncInfo = $this._planSetupSyncField.val();		// 該当プランのプラン明細定義情報格納用
		if (syncInfo != "") {
			syncInfo = syncInfo.substring(0, syncInfo.length-1);
			/*
			var synInfoArr = syncInfo.split(";");
			for (i = 0; i < synInfoArr.length; i++){
				var key = $this._groupIndex + "_" + synInfoArr[i].split(":")[0];
				//hashMap.Put(synInfoArr[i].split(":")[0], synInfoArr[i].split(":")[1]);
				hashMap.Put(key, synInfoArr[i].split(":")[1]);
			}*/
			var synInfoArr = syncInfo.split(";");
			for (i = 0; i < synInfoArr.length; i++){
				var setupInfArr = synInfoArr[i].split(":");
				var sobjId = setupInfArr[0];
				var mapKey1 = groupIndex + "_p_" + sobjId;		// 設定明細の価額
				var mapKey2 = groupIndex + "_i_" + sobjId;		// 設定明細の会計商品ID
				var mapKey3 = groupIndex + "_n_" + sobjId;		// 設定明細の会計商品名
				hashMap.Put(mapKey1, setupInfArr[1]);
				if (setupInfArr.length > 2) hashMap.Put(mapKey2, setupInfArr[2]); // 会計商品ID
				if (setupInfArr.length > 3) hashMap.Put(mapKey3, setupInfArr[3]); // 会計商品名
			}
		}



    	// 検索処理開始			    	
		$this._startfun();
		
		// 検索RemoteAction呼び出し
		Visualforce.remoting.Manager.invokeAction(
			$this._remotePlanQuery,
			$this._planInputField.val(),
			function (result, event) {
				// 検索終了
				$this._endfun();
				// エラーが発生する場合
				if (event.type == 'exception') {
            		alert(event.message);
            		return;
        		}
        		// 正常取得完了、画面へ反映する
				_reponsePlanQueryResult($this, result);
			},
   			{escape: true}
   		);

		return this;
    }
    // Ajax（RemoteAction)から検索結果は画面へ反映する
    function _reponsePlanQueryResult($this, result) {
    	
		// プラン明細設定情報格納する
		var planSyncInf = '';
		// Root Element Setup
		var parentRoot = $this._selectorRoot;
    	if(result== null || result.length == 0){
    		var noItemMsg = _CONST_NOITEM_TEMPLATE.replaceAll("$colspan$", $this._colspanNum)
													.replaceAll("$appendTrClassNm$",$this._appendTrClassNm)
													.replaceAll("$msg_notfound_title$",$this._labels.NOFOUND);
        	parentRoot.after(noItemMsg);
    	} else {
    		// Plan Detail Class
    		var groupIndex = $this._groupIndex;
	    	var childcls = groupIndex + "_child";
	    	var summaryPriceId = groupIndex + "_summary";
			var syncFieldId = $this._planSetupSyncField.attr("id");
			
			var mathRoomPrice = 0;	// プラン総金額
			var isAutoSetupRoomRateFlg = false;	// 室料明細項目に室料自動設定判別フラグ
			if (typeof($this._raceRateCalFun) !== "undefined" &&
				commUtils.isFunction($this._raceRateCalFun)) {
				mathRoomPrice = $this._raceRateCalFun();// 室料計算する
				if (mathRoomPrice != null) {
					isAutoSetupRoomRateFlg = true;
				}
			}
			var isReadOnlyFlg = false;
			if (typeof($this._isReadonlyFun) !== "undefined" &&
				commUtils.isFunction($this._isReadonlyFun)) {
				isReadOnlyFlg = $this._isReadonlyFun(groupIndex);
			}
			
	    	// 検索結果は画面へ反映する
			var tabStrHead = _CONST_ADDITEM_TEMPLATE.replaceAll("$colspan$", $this._colspanNum)
													.replaceAll("$tableWidth$",$this._tableWidth)
													.replaceAll("$groupIndex$",groupIndex)
													.replaceAll("$summaryPriceId$", summaryPriceId)
													.replaceAll("$appendTrClassNm$",$this._appendTrClassNm)
													.replaceAll("$msg_productnm_title$",$this._labels.PRODUCTNM)
													.replaceAll("$msg_unitprice_title$",$this._labels.UNITPRICE)
													.replaceAll("$msg_summmary_title$",$this._labels.SUMMARY);
		    var tabStrBody = "";
			for (var i=0; i<result.length; i++) {
		    	// メモーに既存場合、メモーの設定情報から、単価を設定する
		    	//var key = $this._groupIndex + "_" + result[i].sobjId;
		        //var memoryPrice = hashMap.Contains(result[i].sobjId) ? hashMap.Get(result[i].sobjId) : result[i].prodPrice;
		        //var memoryPrice = hashMap.Contains(key) ? hashMap.Get(key) : result[i].prodPrice;
				var mapKey1 = groupIndex + "_p_" + result[i].sobjId;		// 設定明細の価額
				var mapKey2 = groupIndex + "_i_" + result[i].sobjId;		// 設定明細の会計商品ID
				var mapKey3 = groupIndex + "_n_" + result[i].sobjId;		// 設定明細の会計商品名
				
        		var memoryPrice = 1 * ((hashMap.Contains(mapKey1) ? hashMap.Get(mapKey1) : result[i].prodPrice).replaceAll(",",""));
        		var productId = hashMap.Contains(mapKey2) ? hashMap.Get(mapKey2) : result[i].prodId;
        		var productNm = hashMap.Contains(mapKey3) ? hashMap.Get(mapKey3) : result[i].prodName;
		        // 明細は室料項目　かつ　室料自動設定　かつ　該当明細の室料金額は０の場合のみ、該当から取得する室料は自動設定を行う
		        if (result[i].actionType == _CONST_PRICE_ROOM_TYPE && isAutoSetupRoomRateFlg && memoryPrice == 0) memoryPrice = mathRoomPrice;		// プラン明細項目は室料の場合、自動室料設定を行う
		        
		        tabStrBody += _CONST_ADDITEM_DTEAIL_TEMPLATE.replaceAll("$IMG_TEMPLATE$", isReadOnlyFlg ? "" : _CONST_ADDITEM_DTEAIL_IMG_TEMPLATE)	// Readonlyの場合、設定機能が無くす
		        											.replaceAll("$rowidx$",i)
		        											.replaceAll("$groupIndex$",groupIndex)
		        											.replaceAll("$productName$",commUtils.escapeQuotes(productNm))
		        											.replaceAll("$productId$",productId)
		        											.replaceAll("$planDetailId$",result[i].sobjId)
		        											.replaceAll("$childclsItemClass$",childcls)
		        											.replaceAll("$childActionType$",result[i].actionType)
		        											.replaceAll("$syncInfItemId$",$this._planSetupSyncField.attr("id"))
		        											.replaceAll("$memoryPrice$",commUtils.numFormat(memoryPrice))
		        											.replaceAll("$readonly$", isReadOnlyFlg ? "disabled" : "");
		        											
				// 画面から設定するプラン情報は
				//planSyncInf += result[i].sobjId + ':' + (""+memoryPrice).replaceAll(",","") + ':' + result[i].prodId + ';';
		    } // End For
			// 入力用項目を表示する
			parentRoot.after(tabStrHead.replaceAll("$tBodyContent$",tabStrBody));
			
			// 連携用情報、HIDDEN項目に格納する
	        //$this._planSetupSyncField.val(planSyncInf);
	        /*
			// 数字だけ入力可能の制御
		    $("input[i＾='_price_']").keyup(function(){
		        $(this).val($(this).val().replace(/[^\d.\,]/g,''));
		    }).bind("paste",function(){
		        $(this).val($(this).val().replace(/[^\d.\,]/g,''));
		    }).css("ime-mode", "disabled");
			*/
        	// 単価合計値計算して、プランの単価へ反映する
        	//old value input
        	$("[class='"+ childcls +"']").on('keydown', function(e){
        		$(this).data("olddata",$(this).val().replaceAll(",",""));
        	});
        	// Event Binding
        	$("[class='"+ childcls +"']").on('keyup', function(e){
        		var price = $(this).val().replaceAll(",","");
        		var oldValue = $(this).data("olddata");
        		if(oldValue == price)return;
        		setTimeout(function(){__reComputePrice(childcls,groupIndex,syncFieldId);},500);
        		// 手に設定する金額は項目に反映する
        		//$this._planSetupSyncField.val(planSyncInf);
        	});
        	$("[class='"+ childcls +"']").on('blur', function(e){
        		var price = $(this).val().replaceAll(",","");
        		if (!$.isNumeric(price)) price = "0";
        		$(this).val(commUtils.numFormat(price));
        	});
        	__autoGetSetupSyncInfo(groupIndex, syncFieldId,isReadOnlyFlg);
			
			// POPUPの商品選べるボタンをクリックするEVENT BIND
			$("img[id^='"+groupIndex+"_productPopup_']").click(function() {
				var rowIndex = $(this).attr("rowidx");
				var syncinfItemId = syncFieldId;//$this._planSetupSyncField.attr("id");
				
			    var dumyField = $("#"+groupIndex+"_workHidItem").get(0);
			    // 引き渡し値を設定して、選択画面を開く
			    ctrlNm = $("#"+groupIndex+"_prodName_"+rowIndex).get(0);
			    ctrlId = $("#"+groupIndex+"_prodid_" + rowIndex).get(0);
			    ctrlHidNm = dumyField;
			    ctrlPriceId = dumyField;
			    ctrlOrderNumId = dumyField;
			    ctrlTaxRate = dumyField;
			    ctrlHidTaxRate = dumyField;
			    ctrlServiceTaxRate = dumyField;
			    ctrlHidServiceTaxRate = dumyField;
			    ctrlSpecialTax = dumyField;
			    ctrlHidSpecialTax = dumyField;
			    ctrlHidActionType = $("#"+groupIndex+"_workHidActType_" + rowIndex).get(0);
			    var openUrl = "/apex/ProductSearch?np=1&npy=1";
			    // 呼び出し順番とPOPUP画面の設定順番は必ず一致するが必要
				objs = new Array(ctrlNm, ctrlId, ctrlHidNm, ctrlPriceId, ctrlOrderNumId,
					ctrlTaxRate, ctrlHidTaxRate, ctrlServiceTaxRate, ctrlHidServiceTaxRate, ctrlSpecialTax, ctrlHidSpecialTax, ctrlHidActionType);
				commUtils.popup(openUrl, "SearchProductInfo", objs, null, null, __openProdutWinCallbackFun(groupIndex,rowIndex,syncinfItemId));
			
			});

			// 作成した項目は自動商品コードのAutoComplete機能を追加する
			$("input[id^='"+groupIndex+"_prodName_']").autocomplete({
		        minLength: 1,
		        source: function (request, response) {
		            Visualforce.remoting.Manager.invokeAction(
		                $this._remoteProdQuery, 
		                request.term, 
		                
		                function(result, event){
		                if (event.type == 'exception') {
		                    alert(event.message);
		                } else {
		                    response($.map(result, function (item) {
		                    	item.id = item.productId;
		                    	item.value = item.prodcutName + "("+item.prodcutCode+")";
		                    	return item;
		                    }));
		                } // End else
		            });
		        },
		        focus: function (event, ui) {
			    	var rowidx = $(this).attr("rowidx");
			    
		    		ui.item.rowIndex = rowidx;
		    		ui.item.groupIndex = groupIndex;
		    		ui.item.syncFieldId = syncFieldId;
					__autoGetProductInfo(ui.item);
		            return false;
		        },
		        select: function (event, ui) {
			    	var rowidx = $(this).attr("rowidx");
			    	ui.item.rowIndex = rowidx;
			    	ui.item.groupIndex = groupIndex;
			    	ui.item.syncFieldId = syncFieldId;
		            __autoGetProductInfo(ui.item);
		            return false;
		        },
		    });
		    
		    // プラン総金額を自動計算を行う
		    if ($("[class='"+ childcls +"']").length > 0) $($("[class='"+ childcls +"']")[0]).trigger('blur');
			
			
		} // End if(result== null || result.length == 0){
		function __reComputePrice(childcls,groupIndex,syncFieldId){
			var sumVal = 0;
    		var planSyncInf = '';
    		// 合計値計算を行う
    		$("[class='"+ childcls +"']").each(function(idx){
    			//var hidProdId = groupIndex + "_prodid_" + $(this).attr("rowidx");
    			//var hidPlanId = groupIndex + "_planid_" + $(this).attr("rowidx");
    			var unitPrice = $(this).val().replaceAll(",","");
    			if(unitPrice == "" || !unitPrice || isNaN(parseFloat(unitPrice)) ) unitPrice = 0;
    			//sumVal += 1 * unitPrice;
    			sumVal = commUtils.mathNumAdd(sumVal,unitPrice);
    		});
    		// カスタムマイズ情報自動設定
    		__autoGetSetupSyncInfo(groupIndex, syncFieldId);
    		// 外部に合計値表示したい項目存在する場合、設定値い表示する
    		if (typeof($this._summaryPriceField) !== "undefined") {
    			$this._summaryPriceField.val(commUtils.numFormat(sumVal));
    		}
		}
 		// AutoComplete Result Setup Function
	   	function __autoGetProductInfo(result) {
			// 存在の商品情報は画面へ反映する
			var rowIndex = result.rowIndex;  
			var groupIndex = result.groupIndex;
			var syncFieldId = result.syncFieldId;
		    $j("#"+groupIndex+"_prodName_"+rowIndex).val(result.prodcutName);
		    $j("#"+groupIndex+"_prodid_" + rowIndex).val(result.productId);
		    $j("#"+groupIndex+"_workHidActType_" + rowIndex).val(result.actionType);
		    // 同期情報再設定する
		    __autoGetSetupSyncInfo(groupIndex, syncFieldId);
	   	}
	   	// 同期情報自動設定をお行う
		function __autoGetSetupSyncInfo(groupIndex, syncinfItemId,isReadOnlyFlag) {
			var planSyncInf = "";
			var sumVal = 0;
			var isHaveShituliaoFlag = false;
			$("input[id^='"+groupIndex+"_prodName_']").each(function(idx){
				var rowidx = $(this).attr("rowidx");
				var hidSojbId = groupIndex + "_planid_" + rowidx;
				var hidProdId = groupIndex + "_prodid_" + rowidx;
				var hidProdNm = groupIndex + "_prodName_" + rowidx;
				var unitPrice = groupIndex + "_price_" + rowidx;
				 
				var priceVal = $("#"+unitPrice).val().replaceAll(",","") ;
				if(priceVal == "" || !priceVal || isNaN(parseFloat(priceVal)) ) priceVal = 0;
				// プラン明細ID ： 単価 ： 会計商品ID ： 会計商品名
				planSyncInf += $("#"+hidSojbId).val() + ':' + priceVal + ':' + $("#"+hidProdId).val()+ ':' + $("#"+hidProdNm).val() +';';
				sumVal = commUtils.mathNumAdd(sumVal,priceVal);
				var actionType = $j("#"+groupIndex+"_workHidActType_" + rowidx).val();
				$(this).closest("tr").find("td>input." + groupIndex + "_child").attr("data-actiontype",actionType)
				if(actionType == _CONST_PRICE_ROOM_TYPE) 
					isHaveShituliaoFlag = true;
			});
			var summaryPriceId = groupIndex + "_summary";
			var summaryPriceInputFlag = $("#"+summaryPriceId).is('input');
        	// 合計値でプランの単価に反映する
        	if(isReadOnlyFlag){
        		$("#"+summaryPriceId).text(commUtils.numFormat(sumVal));
        	}else if(isHaveShituliaoFlag){
        		if(summaryPriceInputFlag){
        			$("#"+summaryPriceId).val(sumVal);
        		}else{
        			$("#"+summaryPriceId).replaceWith('<input type="text" id="' + summaryPriceId + '" style="text-align:right;" value="' + commUtils.numFormat(sumVal) + '" />');
					$("#"+summaryPriceId).unbind("keydown");
					$("#"+summaryPriceId).keydown(function(e){
						$(this).data("olddata",$(this).val().replaceAll(",",""));
					});
					$("#"+summaryPriceId).unbind("keyup");
					$("#"+summaryPriceId).keyup(function(e){
						//if((e.keyCode<48 || e.keyCode>57) && e.keyCode!=46 && e.keyCode != 8 ) return;
						var price = $(this).val().replaceAll(",","");
						if(price == $(this).data("olddata")) return;
						setTimeout(function(){__reComputeShitulyou(groupIndex,summaryPriceId);},100);
					});
        		}
        	}else if(summaryPriceInputFlag)
        		$("#"+summaryPriceId).replaceWith('<span id="' + summaryPriceId + '" style="float:right;margin-right: 3px">' + commUtils.numFormat(sumVal) +'</span>');
        	else
				$("#"+summaryPriceId).text(commUtils.numFormat(sumVal));
			$("#"+commUtils.escapeJqSelector(syncinfItemId)).val(planSyncInf);
			return planSyncInf;
		}
    	function __openProdutWinCallbackFun(groupIndex,rowidx,syncinfItemId) {
			return function () {
        		// カスタムマイズ情報自動設定
        		__autoGetSetupSyncInfo(groupIndex, syncinfItemId);
			}
		}
		function __reComputeShitulyou(groupIndex,summaryPriceId){
		 	var otherPrice = 0;
		 	var childcls = groupIndex + "_child";
		 	var planSyncInf = "";
		 	
		 	var summaryElement = $("#" + summaryPriceId);
		 	// 合計値計算を行う
    		$("[class='"+ childcls +"']:not([data-actiontype = '" + _CONST_PRICE_ROOM_TYPE + "'])").each(function(idx){
    			var rowidx = $(this).attr("rowidx");
				var hidSojbId = groupIndex + "_planid_" + rowidx;
				var hidProdId = groupIndex + "_prodid_" + rowidx;
				var hidProdNm = groupIndex + "_prodName_" + rowidx;
				
    			var unitPrice = $(this).val().replaceAll(",","");
    			if(unitPrice == "" || !unitPrice || isNaN(parseFloat(unitPrice)) ) unitPrice = 0;
    			// プラン明細ID ： 単価 ： 会計商品ID ： 会計商品名
				planSyncInf += $("#"+hidSojbId).val() + ':' + unitPrice + ':' + $("#"+hidProdId).val()+ ':' + $("#"+hidProdNm).val() +';';
    			otherPrice = commUtils.mathNumAdd(otherPrice,unitPrice);
    		});
    		var firstShituLyoElement;
    		$("[class='"+ childcls +"'][data-actiontype = '" + _CONST_PRICE_ROOM_TYPE + "']").each(function(idx){
    			var unitPrice = $(this).val().replaceAll(",","");
    			if(unitPrice == "" || !unitPrice || isNaN(parseFloat(unitPrice))) unitPrice = 0;
    			if(!firstShituLyoElement){ 
    				firstShituLyoElement = $(this);
    				return true;
    			}
    			var rowidx = $(this).attr("rowidx");
				var hidSojbId = groupIndex + "_planid_" + rowidx;
				var hidProdId = groupIndex + "_prodid_" + rowidx;
				var hidProdNm = groupIndex + "_prodName_" + rowidx;
				
    			// プラン明細ID ： 単価 ： 会計商品ID ： 会計商品名
				planSyncInf += $("#"+hidSojbId).val() + ':' + unitPrice + ':' + $("#"+hidProdId).val()+ ':' + $("#"+hidProdNm).val() +';';
    			otherPrice = commUtils.mathNumAdd(otherPrice,unitPrice);
    		}); 
    		var summaryPrice = summaryElement.val().replaceAll(",","");
    		if(summaryPrice == "" || !summaryPrice || isNaN(parseFloat(summaryPrice))) summaryPrice = 0;
		 	var changePrice = commUtils.mathNumSub(parseFloat(summaryPrice), otherPrice); 
		 	//var firstShituLyoElement = $("[class='"+ childcls +"'][data-actiontype = '" + _CONST_PRICE_ROOM_TYPE + "']:eq(0)");
		 	firstShituLyoElement.val(changePrice);
		 	
		 	var rowidx = firstShituLyoElement.attr("rowidx");
			var hidSojbId = groupIndex + "_planid_" + rowidx;
			var hidProdId = groupIndex + "_prodid_" + rowidx;
			var hidProdNm = groupIndex + "_prodName_" + rowidx;
			// プラン明細ID ： 単価 ： 会計商品ID ： 会計商品名
			planSyncInf += $("#"+hidSojbId).val() + ':' + changePrice + ':' + $("#"+hidProdId).val()+ ':' + $("#"+hidProdNm).val() +';';
			
			$("#"+commUtils.escapeJqSelector($this._planSetupSyncField.attr("id"))).val(planSyncInf);
		 	
		 	// 外部に合計値表示したい項目存在する場合、設定値い表示する
    		if (typeof($this._summaryPriceField) !== "undefined") {
    			$this._summaryPriceField.val(commUtils.numFormat(summaryPrice));
    		}
		 	
		}
		// 2016/08/29 処理済みから呼出関数
		if (typeof($this._oncompleteFun) !== "undefined" &&
			commUtils.isFunction($this._oncompleteFun)) {
			$this._oncompleteFun();
		}
    }
    
    
    
    // 設定情報をクリアする
    PlanItem.prototype.close = function () {
    	// ステータス制御属性定義
		this._obj.attr("isOpenStatus","true");
		this._obj.attr("src",this._actionOpenImg);
		
		// 設定のプラン情報をクリアする
		// 新規追加のSECIONをクリアする
		this._selectorRoot.next().filter("."+this._appendTrClassNm).each(function(){
			this.remove();
		});
		return this;
    }
    
    // プラン明細展開機能RESET関数呼び出し
    PlanItem.prototype.reset = function () {
    	// 前に設定するプラン商品と金額情報をクリアする
    	hashMap.Clear();
    	this._planSetupSyncField.val("");
    	this._obj.attr("isOpenStatus","false");
    	this.switchStatus("");
    }
    
    // 画面のプラン明細設定Section表示制御の切り替えする
    PlanItem.prototype.switchStatus = function () {
   		if (this._obj.attr("isOpenStatus") == "true" || 
   			this._obj.attr("isOpenStatus") == undefined) {
	       	// プラン未設定する場合、エラーを表示する
	       	// プランが未設定する場合、エラーメッセージを表示する
	    	if (typeof(this._planInputField) == "undefined" || 
	    		this._planInputField.val() == "" || 
	    		this._planInputField.val() == "000000000000000") {
	    		alert("プランを選択してください。");
	    		return false;
	    	}
    		this.open();
    	} else {
    		this.close();
    	}
    	return this;
	}
})(jQuery);

/*
// 会計商品選べる共通関数
jinya.app.jinyaPlanExtend.openProdutWin = function (groupIndex,rowIndex,syncinfItemId) {
    var dumyField = $j("#"+groupIndex+"_workHidItem").get(0);
    // 引き渡し値を設定して、選択画面を開く
    ctrlNm = $j("#"+groupIndex+"_prodName_"+rowIndex).get(0);
    ctrlId = $j("#"+groupIndex+"_prodid_" + rowIndex).get(0);
    ctrlHidNm = dumyField;
    ctrlPriceId = dumyField;
    ctrlOrderNumId = dumyField;
    ctrlTaxRate = dumyField;
    ctrlHidTaxRate = dumyField;
    ctrlServiceTaxRate = dumyField;
    ctrlHidServiceTaxRate = dumyField;
    ctrlSpecialTax = dumyField;
    ctrlHidSpecialTax = dumyField;
    ctrlHidActionType = $j("#"+groupIndex+"_workHidActType_" + rowIndex).get(0);
    var openUrl = "/apex/ProductSearch?np=1";
    // 呼び出し順番とPOPUP画面の設定順番は必ず一致するが必要
	objs = new Array(ctrlNm, ctrlId, ctrlHidNm, ctrlPriceId, ctrlOrderNumId,
		ctrlTaxRate, ctrlHidTaxRate, ctrlServiceTaxRate, ctrlHidServiceTaxRate, ctrlSpecialTax, ctrlHidSpecialTax, ctrlHidActionType);
	commUtils.popup(openUrl, "SearchProductInfo", objs, null, null, jinya.app.jinyaPlanExtend.openProdutWin.callbackFunction(groupIndex,rowIndex,syncinfItemId));
}
// 商品設定処理後、連動のプラン個別情報を再自動設定を行う
jinya.app.jinyaPlanExtend.openProdutWin.callbackFunction = function(groupIndex,rowidx,syncinfItemId) {
	return function () {
		//console.debug(syncinfItemId);
		var planSyncInf = '';
		// 合計値計算を行う
		$("input[id^='"+groupIndex+"_prodName_']").each(function(idx){
			var hidProdId = groupIndex + "_prodid_" + $(this).attr("rowidx");
			var hidPlanId = groupIndex + "_planid_" + $(this).attr("rowidx");	// プラン明細ID OR　予約インデクスSUBのID
			var inpPriceId= groupIndex + "_price_" + $(this).attr("rowidx");
			//sumVal = commUtils.mathNumAdd(sumVal,unitPrice);
			planSyncInf += $("#"+hidPlanId).val() + ':' + $("#"+inpPriceId).val()  + ':' + $("#"+hidProdId).val() +';';
		});
		//console.debug(planSyncInf);
		//$("input[id^='"+syncinfItemId+"']").val(planSyncInf);
		$("#"+commUtils.escapeJqSelector(syncinfItemId)).val(planSyncInf);
	}
}
*/
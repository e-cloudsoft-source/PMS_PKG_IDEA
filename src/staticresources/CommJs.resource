/*
(function($) {
$.commUtils = {};
$.commUtils.Dto = {};
$.commUtils.clearValue =function() {
	for (i=0; i<arguments.length; i++) {
		document.getElementById(arguments[i]).value = "";
	}
}
$.commUtils.popup = function(url,name,objs,width,height) {
	var win;
	window.receivers = objs;

    var paramAry = new Array(
        "top=0",
        "left=0",
        "toolbar=yes",
        "menubar=yes",
        "scrollbars=yes",
        "resizable=yes",
        "location=yes",
        "status=no"
    );
	if(width && height) {
		paramAry.push("height=" + height + "px");
		paramAry.push("width=" + width + "px");
	}else {
		paramAry.push("height=600px");
		paramAry.push("width=800px");
	}
	win = window.open(url, name, paramAry);
	return win;
}

$.commUtils.popupSetter = function(setter) {
	getter = window.opener.receivers;
	if(getter == null || setter	== null) {
		top.window.close();
	}
	rLen = getter.length;
	bLen = setter.length;
	len	= 0;
	if(rLen	> bLen)	{
		len	= bLen;
	}else {
		len	= rLen;
	}

	for(i =	0; i< len ;	i ++) {
        if ($(getter[i]).is("span")) {
            $(getter[i]).text(setter[i]);
        } else {
            $(getter[i]).val(setter[i]);
        }
		//getter[i].value	= setter[i];

	}
}

})(jQuery)

*/
(function(){
    var temp = document.createElement("div");
    if (temp.innerText == undefined) {
        Object.defineProperty(HTMLElement.prototype, "innerText", {
            get: function()  { return this.textContent },
            set: function(v) { this.textContent = v; }
        });
    }
})();

var commUtils = {};
commUtils.clearValue = function() {
    for (i=0; i<arguments.length; i++) {
        document.getElementById(arguments[i]).value = "";
    }
}
commUtils.popup = function(url,name,objs,width,height,callFun) {
	var win;
	window.receivers = objs;
	window.popup_callFunction=callFun;
	/* Chrome59変更に従って、toolbar=yes->no,location=yes->no変更対応 */
    var paramAry = new Array(
        "top=0",
        "left=0",
        "toolbar=no",
        "menubar=yes",
        "scrollbars=yes",
        "resizable=yes",
        "location=no",
        "status=no"
    );
	if(width && height) {
		paramAry.push("height=" + height + "px");
		paramAry.push("width=" + width + "px");
	}else {
		paramAry.push("height=600px");
		paramAry.push("width=800px");
	}
	win = window.open(url, name, paramAry);
//win = window.open(url, name);
	return win;
}

commUtils.popupSetter = function(setter) {
	getter = window.opener.receivers;
	if(getter == null || setter	== null) {
		top.window.close();
	}
	rLen = getter.length;
	bLen = setter.length;
	len	= 0;
	if(rLen	> bLen)	{
		len	= bLen;
	}else {
		len	= rLen;
	}
	for(i =	0; i< len ;	i ++) {
		if (getter[i].nodeName == "INPUT") {
			getter[i].value	= setter[i];
		} else if (getter[i].nodeName == "SPAN") {
			getter[i].innerText = setter[i];
		}
		//getter[i].value	= setter[i];
	}
	// CallFunction Callout
	if (window.opener.popup_callFunction != undefined) {
	   window.opener.popup_callFunction();
	}
}

commUtils.isFunction = function(functionToCheck) {
 var getType = {};
 return functionToCheck && getType.toString.call(functionToCheck) == '[object Function]';
}

commUtils.escapeQuotes = function(str) {
	return str.replace(/'/g,'&#39;').replace(/"/g,'&quot;');
}
commUtils.escapeJqSelector = function(str) {
	return str.replace(/([;&,\.\+\*\~':"\!\^#$%@\[\]\(\)=>\|])/g, '\\$1');
}
commUtils.getYobi = function(dt) {
	if (typeof(dt) == "undefined") return "";
	var weekday = [ "日", "月", "火", "水", "木", "金", "土" ] ;
	return weekday[ dt.getDay() ];
}
commUtils.nullToZero = function(v) {
	return (v == null ? 0 : v);
}
/**********************************
* 各機能個別利用JS　FUN
*
**********************************/
/*********************************
* 部屋選択用POPUP機能
* pageUrl: Open VF PAGE
* ctrlId:設定する部屋ID
* ctrlNm:設定する部屋名
* filterParamUrl:部屋検索用条件
*********************************/
commUtils.showRoomLookup = function showLookup(pageUrl,ctrlId,ctrlNm,filter,height,width) {
    var openUrl = pageUrl + "?lkid=" + ctrlId + "&lknm=" + ctrlNm;
    if (typeof(filter) != "undefined" && filter != "") {
        openUrl += "&" + filter;
    }
    var paramAry = new Array(
        "top=0",
        "left=0",
        "toolbar=no",
        "menubar=no",
        "scrollbars=yes",
        "resizable=no",
        "location=no",
        "status=no"
    );
    if (typeof(height) == "undefined") {
        paramAry.push("height=800");
    } else {
        paramAry.push("height="+height);
    }
    if (typeof(width) == "undefined") {
        paramAry.push("width=600");
    } else {
        paramAry.push("width="+width);
    }
    window.open(encodeURI(openUrl), "showRoomLookup", paramAry);
}

/*********************************
* 数値計算
**********************************/
/**
 * 加算演算
 * 
 * @param num1加算1 | num2加算2
 */
commUtils.mathNumAdd=function(num1, num2) {
	num1 = "" + num1;
	num2 = "" + num2;
	var baseNum, baseNum1, baseNum2;
	try {
		baseNum1 = num1.toString().split(".")[1].length;
	} catch (e) {
		baseNum1 = 0;
	}
	try {
		baseNum2 = num2.toString().split(".")[1].length;
	} catch (e) {
		baseNum2 = 0;
	}
	baseNum = Math.pow(10, Math.max(baseNum1, baseNum2));
	return (commUtils.mathNumMulti(num1 , baseNum) + commUtils.mathNumMulti(num2 , baseNum)) / baseNum;
};
/**
 * 減算演算
 * 
 * @param num1減算された  |  num2減算子
 */
commUtils.mathNumSub=function(num1, num2) {
	num1 = "" + num1;
	num2 = "" + num2;
	var baseNum, baseNum1, baseNum2;
	var precision;// 精度
	try {
		baseNum1 = num1.toString().split(".")[1].length;
	} catch (e) {
		baseNum1 = 0;
	}
	try {
		baseNum2 = num2.toString().split(".")[1].length;
	} catch (e) {
		baseNum2 = 0;
	}
	baseNum = Math.pow(10, Math.max(baseNum1, baseNum2));
	precision = (baseNum1 >= baseNum2) ? baseNum1 : baseNum2;
	return 1 * ((commUtils.mathNumMulti(num1 , baseNum) - commUtils.mathNumMulti(num2 , baseNum)) / baseNum).toFixed(precision);
};
/**
 * 乗法演算
 * 
 * @param num1乗数 | num2乗数
 */
commUtils.mathNumMulti=function(num1, num2) {
	num1 = "" + num1;
	num2 = "" + num2;
	var baseNum = 0;
	try {
		baseNum += num1.toString().split(".")[1].length;
	} catch (e) {
	}
	try {
		baseNum += num2.toString().split(".")[1].length;
	} catch (e) {
	}
	return Number(num1.toString().replace(".", "")) * Number(num2.toString().replace(".", "")) / Math.pow(10, baseNum);
};
/**
 * 除算演算
 * 
 * @param num1除算される | num2
 */
commUtils.mathNumDiv=function(num1, num2) {
	num1 = "" + num1;
	num2 = "" + num2;
	var baseNum1 = 0, baseNum2 = 0;
	var baseNum3, baseNum4;
	try {
		baseNum1 = num1.toString().split(".")[1].length;
	} catch (e) {
		baseNum1 = 0;
	}
	try {
		baseNum2 = num2.toString().split(".")[1].length;
	} catch (e) {
		baseNum2 = 0;
	}
	with (Math) {
		baseNum3 = Number(num1.toString().replace(".", ""));
		baseNum4 = Number(num2.toString().replace(".", ""));
		//return (baseNum3 / baseNum4) * pow(10, baseNum2 - baseNum1);
		return commUtils.mathNumMulti((baseNum3 / baseNum4),pow(10, baseNum2 - baseNum1));
	}
};
/**
 * 端末小数処理
 * 
 * @param num1端末処理対象 | pointLen小数長さ | roundMode処理区分
 */
commUtils.mathRound = function(num1, pointLen, roundMode) {
	var divNum = Math.pow(10, pointLen);
	var lowRoundMode = roundMode.toLowerCase();
	//　上げる
	if (lowRoundMode == "ceil") {
		return commUtils.mathNumDiv( Math.ceil(commUtils.mathNumMulti(num1, divNum)), divNum);
	} 
	// 四捨五入
	else if (lowRoundMode == "half") {
		return commUtils.mathNumDiv( Math.round(commUtils.mathNumMulti(num1, divNum)), divNum);
	} 
	// 切り捨て
	else if (lowRoundMode == "floor") {
		return commUtils.mathNumDiv( Math.floor(commUtils.mathNumMulti(num1, divNum)), divNum);
	}
} 
/*********************************
* 数値書式処理(##,###)
**********************************/
commUtils.numFormat = function(pNum) {
    num = new String(pNum);
    while(num != (num =num.replace(/^(-?\d+)(\d{3})/,"$1,$2")));
    return num;
}
/*********************************
* 指定の小数右側に不要な.00を削除する
**********************************/
commUtils.deleteRightZero = function(pNum,pointLen) {
	// 小数桁は１以上の場合、
	if (pointLen > 0) return pNum;
    num = new String(pNum);
    // 小数部が存在する場合
    if (num.lastIndexOf(".") >= 0) {
    	num =num.replace(/0+$/,"");
    	// 最後の位置が 999.の場合、[.]を削除する
    	if (num.lastIndexOf(".") == (num.length-1)) {
    		num =num.slice(0,-1);
    	}
    }
    return num;
}
commUtils.isInteger = function(pNum) {
	return /^[0-9]*$/.test(pNum);
}
String.prototype.replaceAll = function (org, dest){  
  return this.split(org).join(dest);  
}
/*********************************
* SFのID：15桁ー＞18桁
**********************************/
commUtils.sfId15to18Byte = function(org) {
	if (org.length != 15) return org;
    var s = "";
    for (var i = 0; i < 3; i++) {
        var f = 0;
        for (var j = 0; j < 5; j++) {
            var c = org.charAt(i * 5 + j);
            if (c >= "A" && c <= "Z") f += 1 << j;
        }
        s += "ABCDEFGHIJKLMNOPQRSTUVWXYZ012345".charAt(f);
    }
    return org + s;
}

hashMap = {  
    Put : function(key,value){this[key] = value},  
    Get : function(key){return this[key]},  
    Contains : function(key){return this.Get(key) == null?false:true},  
    Remove : function(key){delete this[key]},
    KeySet : function(){
    	var keyLst = new Array();
		for (var k in this) {
			if (k == "Put" || k == "Get" || k == "Contains" || k == "Remove" || k == "KeySet" || k == "Clear" || k == "Size") continue;
		    // use hasOwnProperty to filter out keys from the Object.prototype
		    if (this.hasOwnProperty(k)) {
		        keyLst.push(k);
		    }
		}
		return keyLst;
    },
    Clear : function() {
		for (var k in this) {
			if (k == "Put" || k == "Get" || k == "Contains" || k == "Remove" || k == "KeySet" || k == "Clear" || k == "Size") continue;
		    // use hasOwnProperty to filter out keys from the Object.prototype
		    if (this.hasOwnProperty(k)) {
		        this.Remove(k);
		    }
		}
    },
    Size : function() {
    	var cnt  = 0;
		for (var k in this) {
			if (k == "Put" || k == "Get" || k == "Contains" || k == "Remove" || k == "KeySet" || k == "Clear" || k == "Size") continue;
		    // use hasOwnProperty to filter out keys from the Object.prototype
		    if (this.hasOwnProperty(k)) {
		        cnt++
		    }
		}
		return cnt;
    }
}
// 2017/076/29 SF1チェックする
function isSf1() {
    return (typeof sforce != 'undefined') && sforce && (!!sforce.one);
}
/* 2014.10.09 使わない、Salesforceのmain.jsのMap()関数を利用する
function Map() {
    this.buckets = {};
}

Map.prototype.put = function(key, value) {
    var hashCode = key.hashCode();
    var bucket = this.buckets[hashCode];
    if (!bucket) {
        bucket = new Array();
        this.buckets[hashCode] = bucket;
    }
    for (var i = 0; i < bucket.length; ++i) {
        if (bucket[i].key.equals(key)) {
            bucket[i].value = value;
            return;
        }
    }
    bucket.push({ key: key, value: value });
}

Map.prototype.get = function(key) {
    var hashCode = key.hashCode();
    var bucket = this.buckets[hashCode];
    if (!bucket) {
        return null;
    }
    for (var i = 0; i < bucket.length; ++i) {
        if (bucket[i].key.equals(key)) {
            return bucket[i].value;
        }
    }
}

Map.prototype.keys = function() {
    var keys = new Array();
    for (var hashKey in this.buckets) {
        var bucket = this.buckets[hashKey];
        for (var i = 0; i < bucket.length; ++i) {
            keys.push(bucket[i].key);
        }
    }
    return keys;
}

Map.prototype.values = function() {
    var values = new Array();
    for (var hashKey in this.buckets) {
        var bucket = this.buckets[hashKey];
        for (var i = 0; i < bucket.length; ++i) {
            values.push(bucket[i].value);
        }
    }
    return values;
}
Map.prototype.remove = function(key) {
	for (var i = 0; i < bucket.length; ++i) {
        if (bucket[i].key.equals(key)) {
            delete bucket[i];
        }
    }
}
*/
// 2018/07/27 宿泊税計算 WGCH BEGIN
commUtils.getHotelTaxFun = function(unitPrice, hotelTax){
	if(hotelTax == undefined || hotelTax.isIncHotelTaxFlg || unitPrice <= 0) return 0;
	else if(getInRangeFlgFun(hotelTax.minPriceR1, hotelTax.maxPriceR1, unitPrice)) return hotelTax.taxPriceR1;
	else if(getInRangeFlgFun(hotelTax.minPriceR2, hotelTax.maxPriceR2, unitPrice)) return hotelTax.taxPriceR2;
	else if(getInRangeFlgFun(hotelTax.minPriceR3, hotelTax.maxPriceR3, unitPrice)) return hotelTax.taxPriceR3;
	else if(getInRangeFlgFun(hotelTax.minPriceR4, hotelTax.maxPriceR4, unitPrice)) return hotelTax.taxPriceR4;
	else if(getInRangeFlgFun(hotelTax.minPriceR5, hotelTax.maxPriceR5, unitPrice)) return hotelTax.taxPriceR5;
	else return 0;
}
function getInRangeFlgFun(minPrice, maxPrice, unitPrice){
	return unitPrice >= minPrice && unitPrice < maxPrice;
}
// 2018/07/27 宿泊税計算 WGCH END
// 2019/07/30 軽減税率機能対応 WGCH BEGIN
commUtils.getPlanResInfoFun = function(_planItemLst, _row, _hotelTax, isReducedTaxFlg){
	var priceIncTaxSum = 0,
		priceExcTaxSum = 0,
		hasNumSepcTaxSum = 0,
		// 2021/04/31 #10644 bug fixed by zy BEGIN
		newNumSepcTaxSum = 0,
		itemDataArr = [];
		// 2021/04/31 #10644 bug fixed by zy END
	if(!commUtils.isUndefined(_planItemLst)){
		// 2019/10/02 PlanHeader算法切换对应 WGCH BEGIN
		if(_hotelTax.planBrkToHeaderCalFlg){
			// 遍历PLAN明细数据集
			for(var i = 0, wkLen = _planItemLst.length; i < wkLen; i++){
				var _pd = jQuery.extend(true, {}, _planItemLst[i]), // 防止地址共存
					_brkRow = _pd.isJsSetFlg ? _pd : commUtils.setData(_row.rowIndex, _pd.unitPrice, _pd.tax, _pd.serviceRate, _row.nums, _pd.specialTax, _row.unitPriceKbn, _pd.productId, _pd.actionType, true); // 获取当前行数据集
				// 軽減税率機能开启MODE
				if(isReducedTaxFlg){
					// 当前行单价计算处理
					var _brkRes = JINYACONNECT.PRODUCT.PROCESS(_brkRow.unitPrice, _brkRow.nums, _brkRow.tax, _brkRow.serviceRate, _brkRow.unitPriceKbn);
					// 2021/04/31 #10644 bug fixed by zy BEGIN
					var tax = _brkRow.tax, unitPrice = _brkRes.unitPriceTax , num = _brkRow.nums , priceTax = _brkRes.priceTax;
					// 2021/04/31 #10644 bug fixed by zy END
					// 宿泊税有效, 处理种别是室料
					if(_hotelTax.isEffectiveFlg && _brkRow.actionType == _CONST_PRICE_ROOM_TYPE){
						// 获取宿泊税计算后数据集
						var _res = commUtils.getSepcTaxInfoFun(_brkRes, _brkRow, _hotelTax.data);
						// 2021/04/31 #10644 bug fixed by zy BEGIN
						unitPrice = _res.res.unitPriceTax , 
						priceTax = _res.res.priceTax;
						// 2021/04/31 #10644 bug fixed by zy END
						priceIncTaxSum = commUtils.mathNumAdd(priceIncTaxSum, _res.res.priceIncTax); // 集计PLAN明细「合計金額」
						priceExcTaxSum = commUtils.mathNumAdd(priceExcTaxSum, _res.res.priceExcTax); // 集计PLAN明细「合計金額(税抜)」
						hasNumSepcTaxSum = commUtils.mathNumAdd(hasNumSepcTaxSum, _res.hasNumSepcTaxSum); // 合計金額(税抜) 列 含有的宿泊税「赋值」
						newNumSepcTaxSum = commUtils.mathNumAdd(newNumSepcTaxSum, _res.newNumSepcTaxSum); // 特別税        列 显示的宿泊税「赋值」
					} else {
						priceIncTaxSum = commUtils.mathNumAdd(priceIncTaxSum, _brkRes.priceIncTax); // 集计PLAN明细「合計金額」
						priceExcTaxSum = commUtils.mathNumAdd(priceExcTaxSum, _brkRes.priceExcTax); // 集计PLAN明细「合計金額(税抜)」
					}
					// 2021/04/31 #10644 bug fixed by zy BEGIN
					itemDataArr.push({
						unitPrice : unitPrice,
						quantity : num,
						// 消费税金额
						taxUnitPrice : priceTax,
						taxRate : commUtils.mathNumDiv(tax , 100),
						specialTax : 0
					});
					// 2021/04/31 #10644 bug fixed by zy END
				}
			} // for(var i = 0, wkLen = _planItemLst.length; i < wkLen; i++)「END」
		} else {
			var hasTaxUnitPrice = 0, noTaxUnitPrice = 0;
			// 遍历PLAN明细数据集
			for(var i = 0, wkLen = _planItemLst.length; i < wkLen; i++){
				var _pd = jQuery.extend(true, {}, _planItemLst[i]), // 防止地址共存
					_brkRow = _pd.isJsSetFlg ? _pd : commUtils.setData(_row.rowIndex, _pd.unitPrice, _pd.tax, _pd.serviceRate, _row.nums, _pd.specialTax, _row.unitPriceKbn, _pd.productId, _pd.actionType, true); // 获取当前行数据集
				if(_brkRow.tax > 0) hasTaxUnitPrice += _brkRow.unitPrice;
				else if(_brkRow.tax == 0) noTaxUnitPrice += _brkRow.unitPrice;
				// 宿泊税有效, 处理种别是室料
				if(_hotelTax.isEffectiveFlg && _brkRow.actionType == _CONST_PRICE_ROOM_TYPE){
					var _brkRes = JINYACONNECT.PRODUCT.PROCESS(_brkRow.unitPrice, _brkRow.nums, (_brkRow.tax > 0 ? _row.tax : 0), _row.serviceRate, _brkRow.unitPriceKbn);
					// 获取宿泊税计算后数据集
					var _res = commUtils.getSepcTaxInfoFun(_brkRes, _brkRow, _hotelTax.data);
					hasNumSepcTaxSum = commUtils.mathNumAdd(hasNumSepcTaxSum, _res.hasNumSepcTaxSum); // 合計金額(税抜) 列 含有的宿泊税「赋值」
					newNumSepcTaxSum = commUtils.mathNumAdd(newNumSepcTaxSum, _res.newNumSepcTaxSum); // 特別税        列 显示的宿泊税「赋值」
				}
			} // for(var i = 0, wkLen = _planItemLst.length; i < wkLen; i++)「END」
			// 当前行含税单价计算处理
			var _hasTaxRes = JINYACONNECT.PRODUCT.PROCESS(hasTaxUnitPrice, _row.nums, _row.tax, _row.serviceRate, _row.unitPriceKbn);
			priceIncTaxSum = _hasTaxRes.priceIncTax; // PLAN-Header「合計金額」
			priceExcTaxSum = _hasTaxRes.priceExcTax; // PLAN-Header「合計金額(税抜)」
			// 2021/04/31 #10644 bug fixed by zy BEGIN
			itemDataArr.push({
				unitPrice : _hasTaxRes.unitPriceTax,
				quantity :  _row.nums,
				// 消费税金额
				taxUnitPrice : _hasTaxRes.priceTax,
				taxRate : commUtils.mathNumDiv(_row.tax , 100),
				specialTax : 0
			});
			// 2021/04/31 #10644 bug fixed by zy END
			// 当前行不含税单价计算处理
			var _noTaxRes = JINYACONNECT.PRODUCT.PROCESS(noTaxUnitPrice, _row.nums, 0, _row.serviceRate, _row.unitPriceKbn);
			priceIncTaxSum += _noTaxRes.priceIncTax; // PLAN-Header「合計金額」
			priceExcTaxSum += _noTaxRes.priceExcTax; // PLAN-Header「合計金額(税抜)」
			// 2021/04/31 #10644 bug fixed by zy BEGIN
			itemDataArr.push({
				unitPrice : _noTaxRes.unitPriceTax,
				quantity :  _row.nums,
				// 消费税金额
				taxUnitPrice : _noTaxRes.priceTax,
				taxRate : 0,
				specialTax : 0
			});
			itemDataArr.push({
				unitPrice : 0,
				quantity :  0,
				// 消费税金额
				taxUnitPrice : 0,
				taxRate : 0,
				specialTax : newNumSepcTaxSum
			});
			// 2021/04/31 #10644 bug fixed by zy END
		}
		// 2019/10/02 PlanHeader算法切换对应 WGCH END
	} // if(!commUtils.isUndefined(_planItemLst))「END」
	// 2019/09/15 PLAN-没有明细-HEADER计算问题BUG修复 WGCH BEGIN
	else{
		// 当前行单价计算处理
		var _headerRes = JINYACONNECT.PRODUCT.PROCESS(_row.unitPrice, _row.nums, _row.tax, _row.serviceRate, _row.unitPriceKbn);
		priceIncTaxSum = _headerRes.priceIncTax; // PLAN-Header「合計金額」
		priceExcTaxSum = _headerRes.priceExcTax; // PLAN-Header「合計金額(税抜)」
	}
	// 2019/09/15 PLAN-没有明细-HEADER计算问题BUG修复 WGCH END
	return {
		priceIncTaxSum : priceIncTaxSum,
		priceExcTaxSum : priceExcTaxSum,
		hasNumSepcTaxSum : hasNumSepcTaxSum,
		newNumSepcTaxSum : newNumSepcTaxSum
		// 2021/04/31 #10644 bug fixed by zy BEGIN
		,itemDataArr :itemDataArr
		// 2021/04/31 #10644 bug fixed by zy END
	}
}
// 计算宿泊税信息处理
commUtils.getSepcTaxInfoFun = function(res, _row, _hotelTaxData){
	var hasNumSepcTaxSum = 0, // 合計金額(税抜) 列 含有的宿泊税
		newNumSepcTaxSum = 0; // 特別税        列 显示的宿泊税
	if(!commUtils.isUndefined(_row)){
		var _wkRow = jQuery.extend(true, {}, _row); // 目前ARR内只会有一笔「为以后多笔处理留个接口」
		var _data = commUtils.getHotelTaxAmountFun(_wkRow, _hotelTaxData); // 获取宿泊税
		newNumSepcTaxSum = _data.newNumSepcTaxSum; // 宿泊税合计值
		if(_hotelTaxData.isIncHotelTaxAndAccIsShowFlg){ // 単価に宿泊税含む && 表示
			// 合計金額(税抜)列内含有的宿泊税「赋值」
			hasNumSepcTaxSum = newNumSepcTaxSum;
			// 真正的单价「去掉包含的宿泊税」
			_wkRow.unitPrice = commUtils.mathNumSub(_wkRow.unitPrice, _data.newNumSepcTax);
			// 获取最终的数据集
			res = JINYACONNECT.PRODUCT.PROCESS(_wkRow.unitPrice, _wkRow.nums, _wkRow.tax, _wkRow.serviceRate, _wkRow.unitPriceKbn);
			res.priceIncTax = commUtils.mathNumAdd(res.priceIncTax, newNumSepcTaxSum); // 包含的情况下得把减掉的宿泊税加回来「合计值」
			res.priceExcTax = commUtils.mathNumAdd(res.priceExcTax, newNumSepcTaxSum); // 包含的情况下得把减掉的宿泊税加回来「合计值」
			// 置换原来的存在的宿泊税，优先级的问题。「现在是包含的Mode」
			newNumSepcTaxSum = 0; 
		}
	}
	return {
		res: res,
		hasNumSepcTaxSum : hasNumSepcTaxSum, // 合計金額(税抜)列内含有的宿泊税
		newNumSepcTaxSum : newNumSepcTaxSum // 特別税列显示的宿泊税
	};
}
// 宿泊税档位计算
commUtils.getHotelTaxAmountFun = function(_row, _hotelTaxData){
	var item = {
			_row : _row, // 行数据集
			newNumSepcTax : 0, // 单价对应的宿泊税
			newNumSepcTaxSum : 0 // 合计金额对应的宿泊税
		};
	if(commUtils.isUndefined(_row) || _row.unitPrice <= 0 || commUtils.isUndefined(_hotelTaxData)) return item;
	var wkHotelTax = 0,
		unitPrice = _row.unitPrice, // 单价
		tax = _row.tax, // 消費税率
		service = _row.serviceRate, // サビース料率
		nums = _row.nums, // 数量
		unitPriceKbn = _row.unitPriceKbn; // 单价定义区分
	for(var i = 1; i < 6; i++){ // 假设带入法反推处理
		if(i == 1){ // 第一条定义信息处理
			var wkUnitPrice = _hotelTaxData.isIncHotelTaxAndAccIsShowFlg ? unitPrice - _hotelTaxData.taxPriceR1 : unitPrice;
			var wkPriceInfo = JINYACONNECT.PRODUCT.PROCESS(wkUnitPrice, nums, tax, service, unitPriceKbn);
			// 判断反推回来的单价（无税含サビース料）是否在当天范围内
			if(wkPriceInfo.unitPriceIncServiceExcTax >= _hotelTaxData.minPriceR1 && wkPriceInfo.unitPriceIncServiceExcTax < _hotelTaxData.maxPriceR1){
				wkHotelTax = commUtils.mathNumAdd(wkHotelTax, _hotelTaxData.taxPriceR1);
				break;
			}
		}
		else if(i == 2){ // 第二条定义信息处理
			var wkUnitPrice = _hotelTaxData.isIncHotelTaxAndAccIsShowFlg ? unitPrice - _hotelTaxData.taxPriceR2 : unitPrice;
			var wkPriceInfo = JINYACONNECT.PRODUCT.PROCESS(wkUnitPrice, nums, tax, service, unitPriceKbn);
			// 判断反推回来的单价（无税含サビース料）是否在当天范围内
			if(wkPriceInfo.unitPriceIncServiceExcTax >= _hotelTaxData.minPriceR2 && wkPriceInfo.unitPriceIncServiceExcTax < _hotelTaxData.maxPriceR2){
				wkHotelTax = commUtils.mathNumAdd(wkHotelTax, _hotelTaxData.taxPriceR2);
				break;
			}
		}
		else if(i == 3){ // 第三条定义信息处理
			var wkUnitPrice = _hotelTaxData.isIncHotelTaxAndAccIsShowFlg ? unitPrice - _hotelTaxData.taxPriceR3 : unitPrice;
			var wkPriceInfo = JINYACONNECT.PRODUCT.PROCESS(wkUnitPrice, nums, tax, service, unitPriceKbn);
			// 判断反推回来的单价（无税含サビース料）是否在当天范围内
			if(wkPriceInfo.unitPriceIncServiceExcTax >= _hotelTaxData.minPriceR3 && wkPriceInfo.unitPriceIncServiceExcTax < _hotelTaxData.maxPriceR3){
				wkHotelTax = commUtils.mathNumAdd(wkHotelTax, _hotelTaxData.taxPriceR3);
				break;
			}
		}
		else if(i == 4){ // 第四条定义信息处理
			var wkUnitPrice = _hotelTaxData.isIncHotelTaxAndAccIsShowFlg ? unitPrice - _hotelTaxData.taxPriceR4 : unitPrice;
			var wkPriceInfo = JINYACONNECT.PRODUCT.PROCESS(wkUnitPrice, nums, tax, service, unitPriceKbn);
			// 判断反推回来的单价（无税含サビース料）是否在当天范围内
			if(wkPriceInfo.unitPriceIncServiceExcTax >= _hotelTaxData.minPriceR4 && wkPriceInfo.unitPriceIncServiceExcTax < _hotelTaxData.maxPriceR4){
				wkHotelTax = commUtils.mathNumAdd(wkHotelTax, _hotelTaxData.taxPriceR4);
				break;
			}
		}
		else if(i == 5){ // 第五条定义信息处理
			var wkUnitPrice = _hotelTaxData.isIncHotelTaxAndAccIsShowFlg ? unitPrice - _hotelTaxData.taxPriceR5 : unitPrice;
			var wkPriceInfo = JINYACONNECT.PRODUCT.PROCESS(wkUnitPrice, nums, tax, service, unitPriceKbn);
			// 判断反推回来的单价（无税含サビース料）是否在当天范围内
			if(wkPriceInfo.unitPriceIncServiceExcTax >= _hotelTaxData.minPriceR5 && wkPriceInfo.unitPriceIncServiceExcTax < _hotelTaxData.maxPriceR5){
				wkHotelTax = commUtils.mathNumAdd(wkHotelTax, _hotelTaxData.taxPriceR5);
				break;
			}
		}
	}
	item.newNumSepcTax = wkHotelTax; // 单价对应的宿泊税
	item.newNumSepcTaxSum = commUtils.mathNumMulti(wkHotelTax, nums); // 合计金额对应的宿泊税
	return item;
}
// 设定行数据模版「用于值引计算使用」
commUtils.setRowData = function(wkNums, wkTaxRate, wkActionType, wkAmountExcTax, wkAmountIncTax){
	var _rowData =	{
						nums : wkNums, // 数量
						taxRate : wkTaxRate, // 消费税
						actionType : actionType, // 商品処理種別
				 		amountExcTax : wkAmountExcTax, // 金額（税抜き）
				 		amountIncTax : wkAmountIncTax // // 金額（税込み）
				 	};
	return _rowData;
}
// 设置数据模版「统一变量名」
commUtils.setData = function(rowIndex, unitPrice, tax, service, nums, numSepcTax, unitPriceKbn, productId, actionType, brkFlg, payType, initPrice, amountExcTax, amountIncTax, invoiceNoShow){
	var _data = {
			rowIndex : rowIndex, // 行编号
			unitPrice : unitPrice, // 单价
			tax : tax, // 消費税率
			serviceRate : service, // サビース料率
			nums : nums, // 数量
			specialTax : numSepcTax, // 特別税
			unitPriceKbn : unitPriceKbn, // 単価定義区分
			productId : productId, // 商品Id
			actionType : actionType, // 商品処理種別
			brkFlg : brkFlg, // プラン明細 FLG
			payType : payType, // 支付种别
			initPrice : initPrice, // プラン明細課税、非課税混在合計金額
			amountExcTax : amountExcTax, // 金額（税抜き）
			amountIncTax : amountIncTax, // 金額（税込み）
			invoiceNoShow : invoiceNoShow, // 請求書に非表示制御フラグ
			isJsSetFlg : true // 脚本设定Flg
		};
	return _data;
}
// 设置PlanBrkInfo
commUtils.setPlanBrkInfo = function(productId, actionType, tax, serviceRate, unitPrice, priceExcTax, priceIncTax, newNumSepcTaxSum){
	return productId + "," + actionType + "," + tax + "," + serviceRate + "," + unitPrice + "," + priceExcTax + "," + priceIncTax + "," + newNumSepcTaxSum + ";";
}
// 判断变量是undefined函数
commUtils.isUndefined = function(_data){
	return _data == undefined;
}
// ARR有效判断函数
commUtils.isEmpty = function(_arr){
	return _arr == undefined || _arr.length == 0;
}
// 2019/07/30 軽減税率機能対応 WGCH END
// ****** 署名ヘルプJSLIB ******//
// 设备属性
var deviceTypes = '';
// 画板属性
//var canvas;
//var ctx;
var color = "#000000";
var line = 2;
// 2017/04/25 戻る / 進む BEGIN
var record_index = 0;
var recordArray = new Array();
var lineRecords = new Array();
var canvasArray = new Array();
var cav_x,cav_y;
var JS_SYS_DEVICE_MOBILE_FLG = kendo.support.mobileOS;

$(document).ready(function() {
    checkMobile();
});
function checkMobile(){
    if (deviceTypes != '') return;
    var ua = navigator.userAgent.toLowerCase(); 
    if (ua.match(/ipad/i)) deviceTypes = "ipad";
    if (ua.match(/iphone os/i)) {
        deviceTypes = "iphone";
        $("#view_id").attr('content',"width=device-width, minimum-scale=0.5, maximum-scale=0.5, initial-scale=0.5;");
    }
    if (ua.match(/android/i)) deviceTypes = "android";
}
function reSigna(that){
    // Canvas Clear
    canvasArray = [];
    // 全てCANVASのEVENTをBINDする
	$("tr.lastRow").each(function(){
		bindCanvas(this);
	});
}
function bindCanvas(curRow){
    $("#signPanel",curRow).hide();
    $("#signa_id",curRow).show();
    if (JS_SYS_DEVICE_MOBILE_FLG) {
        $("#signa_id",curRow).css({border:'1px solid #000000',height:'80px'});
    } else {
        $("#signa_id",curRow).css({border:'1px solid #000000'});
    }
    //$("#signa_id",curRow).css({border:'1px solid #000000'});
    $("#dobtn",curRow).hide();
    var canvas = $("#canvassample",curRow).get(0);
    var ctx = canvas.getContext("2d");
    canvasSize(ctx,canvas);
    // PC対応
    canvas.addEventListener("mousedown", touchStartHandler, false);
    canvas.addEventListener("mouseup", touchEndHandler, false);
    // スマホ対応
    canvas.addEventListener("touchstart", touchStartHandler, false);
    canvas.addEventListener("touchend", touchEndHandler, false);
    // 新たCANVASは配列に格納する
    canvasArray.push(canvas);
}
//Writing board


// 2017/04/25 戻る / 進む END

//Click the signature box to pop up the WordPad
function canvasSize(ctx,canvas){
    if(JS_SYS_DEVICE_MOBILE_FLG){
        drawCanvasSize(canvas);
    } else {
        canvas.width = $("#signa_id").width()-3;
        canvas.height = $("#signa_id").height()-2;
    }
	//Open the canvas to clear the content
	clearCanvas(ctx);
// 2017/04/25 戻る / 進む clear BEGIN
	record_index = 0;
	recordArray = new Array();
// 2017/04/25 戻る / 進む clear END
}

// PC対応 BEGIN
function touchStartHandler(e) {
	var curTd = $(this).closest("td");
	$("#divfoo",curTd).show();
    e.preventDefault();
    getTouchPoint(e,curTd);
    
    for (i=0;i<canvasArray.length;i++) {
        var ctx = canvasArray[i].getContext("2d");
        //var ctx = this.getContext("2d");
        ctx.beginPath();
        ctx.lineCap = "round";
        ctx.lineJoin = "round";
        ctx.moveTo(cav_x, cav_y);

        if (JS_SYS_DEVICE_MOBILE_FLG) {
            canvasArray[i].addEventListener("touchmove", touchMoveHandler, false);
        } else {
            canvasArray[i].addEventListener("mousemove", touchMoveHandler, false);
        }
    }
    // 2017/04/25 戻る / 進む BEGIN
    //座標初期化
    lineRecords = new Array();
    //座標を配列に保存              
    lineRecords.push(getLine(cav_x,cav_y));
    // 2017/04/25 戻る / 進む END
}
function getLine(x,y,color){
    return {
        x:x,
        y:y,
        color:color
    }
}
function touchMoveHandler(e) {
	var curTd = $(this).closest("td");
    e.preventDefault();
    getTouchPoint(e,curTd);
    
    for (i=0;i<canvasArray.length;i++) {
        var ctx = canvasArray[i].getContext("2d");
        ctx.lineWidth = line; //線の太さ
        ctx.strokeStyle = color; //線の色
        ctx.lineTo(cav_x, cav_y);
        ctx.stroke();
    }
    // 2017/04/25 戻る / 進む BEGIN
    //座標を配列に保存              
    lineRecords.push(getLine(cav_x, cav_y,color));
    // 2017/04/25 戻る / 進む END
}

function touchEndHandler(e) {
	
    e.preventDefault();
    for (i=0;i<canvasArray.length;i++) {
        var ctx = canvasArray[i].getContext("2d");
        ctx.closePath();
    }
    // 2017/04/25 戻る / 進む BEGIN
    //履歴を記録
    recordArray[record_index] = lineRecords;
    //座標初期化
    lineRecords = new Array();
    //履歴を更新された場合最新の
    record_index++;
    if(record_index < recordArray.length){
        recordArray.splice(record_index,recordArray.length);
    }
    
    for (i=0;i<canvasArray.length;i++) {
        if (JS_SYS_DEVICE_MOBILE_FLG) {
            canvasArray[i].removeEventListener("touchmove", touchMoveHandler, false);
        } else {
            canvasArray[i].removeEventListener("mousemove", touchMoveHandler, false);
        }
    }
    // 2017/04/25 戻る / 進む END
    
}

function getTouchPoint(e,curTd) {
    if (JS_SYS_DEVICE_MOBILE_FLG) {
        var touch = e.touches[0];
		var divTop = curTd.offset().top;
		var divleft = curTd.offset().left;
        //var divTop = $("#signa_id").offset().top;
        //var divleft = $("#signa_id").offset().left;
        cav_x = touch.clientX - divleft + document.body.scrollLeft;
        cav_y = touch.clientY - divTop + $(window).scrollTop();
    } else {
        cav_x = e.offsetX;
        cav_y = e.offsetY;
    }
}
// スマホ対応 END
//Empty the WordPad function
function clearCanvas(ctx) {  
    ctx.fillStyle="#FFFFFF";  
    ctx.beginPath();  
    ctx.fillRect(0,0,ctx.canvas.width,ctx.canvas.height);  
    ctx.closePath();
}
// クリア
function clearCanvasflg(that) { 
	// クリア
	for (i=0;i<canvasArray.length;i++) {
        var ctx = canvasArray[i].getContext("2d");
        clearCanvas(ctx);
    }
    record_index = 0;
    recordArray = [];
}

// 2017/04/25 戻る / 進む BEGIN
// 戻る
function undo(that) {
    // 戻る	
    if(record_index > 0) {
        record_index--;
        for (i=0;i<canvasArray.length;i++) {
            var ctx = canvasArray[i].getContext("2d");
            //キャンバスを初期化
            clearCanvas(ctx);
            drawCurrentArr('',ctx);
        }
    }
}
// 進む
function redo(that){
    // 進めする  
    if(record_index < recordArray.length){
        record_index++;
        for (i=0;i<canvasArray.length;i++) {
            var ctx = canvasArray[i].getContext("2d");
            //キャンバスを初期化
            clearCanvas(ctx);
            drawCurrentArr('',ctx);
        }
    }

}

//根据现有存储画图
function drawCurrentArr(scale,ctx){
    //キャンバスを初期化
   	//clearCanvas();
    for(var i=0; i < record_index; i++){
        var record = recordArray[i];
        for(var v=0; v<record.length; v++){
            if(typeof record[v] == "object"){
                var xy = record[v];
                if (scale) {
                    xy.x = xy.x*scale;
                    xy.y = xy.y*scale;
                }
                //描画処理
                draw(v,xy.x,xy.y,color,ctx);
            }
        }
    }
}
function draw(num,x,y,color,ctx){
    var mx = x;
    var my = y;
    if(num == 0){
        oldx = mx -1;
        oldy = my -1;
    }
    ctx.beginPath();
    ctx.moveTo(oldx,oldy);
    ctx.lineTo(mx,my);
    ctx.strokeStyle = color;
    ctx.stroke();
    oldx = mx;
    oldy = my;
}
function drawCanvasSize(canvas){
    checkMobile();
    //放大后缩放
    //$(window).scrollLeft(0);
    //$(window).scrollTop(0)
    //heightStr =  $(document).height() ;
    //ios侧对应
    //$("#signa_id").css({border:'1px solid #000000',height:'80px'});
    var $canvasPanel = $(canvas).parents("#signa_id");
    //画布设定
    canvas.width = $canvasPanel.width() - 5;
    canvas.height = $canvasPanel.height() - 1;
}
// 2017/04/25 戻る / 進む END
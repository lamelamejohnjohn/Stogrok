
/*
function getContentAndReplace(){
$.get("/stockdata/bidu",function(data,status){
$(".starter-template").append(data);
var myData = JSON.parse(data);
alert(myData[0].Date);
});

}
*/


function switcher(txt){
$(".nav.navbar-nav").children(".active").removeClass("active");
$(".nav.navbar-nav").children(":contains("+txt+")").addClass("active");
var stockRenderMatcher = new RegExp("Stock","i");
if(stockRenderMatcher.test(txt)) {
//   getContentAndReplace();
prepareJsonAndDraw("bidu","1y");
}
}

function naiveJson2chartJson(naiveJson){
var chartJson = [];
alert(naiveJson[0].Date);
for(var i in naiveJson){
var dateString = naiveJson[i].Date;
var dateSplitArr = dateString.split("/");
chartJson.push({date: new Date(dateSplitArr[2],dateSplitArr[0]-1,dateSplitArr[1]), value: naiveJson[i].Close});
}
return chartJson;
}


function loadChartJsSource(){
$("body").append('<script type="text/javascript" src="http://www.amcharts.com/lib/3/amcharts.js"></script>
<script type="text/javascript" src="http://www.amcharts.com/lib/3/serial.js"></script>
<script type="text/javascript" src="http://www.amcharts.com/lib/3/themes/dark.js"></script>
<script type="text/javascript" src="http://www.amcharts.com/lib/3/amstock.js"></script>');
}

/*
Given a json that contains array of {date:xxx, value:xxx}, draw the stock chart
*/
function drawStockChart(chartJson){
$(".starter-template").append("<div id="chartDiv"></div>");
loadChartJsSource();
}


/*
stockSymbol: the stock symbol used in marketplace
periodCode: 1m|3m|6m|1y|2y|3y
*/
function prepareJsonAndDraw(stockSymbol, periodCode){
$.get("/stockdata/"+stockSymbol, function(data,status){
var naiveJson = JSON.parse(data);
var chartJson = naiveJson2chartJson(naiveJson);
drawStockChart(chartJson);
});
}
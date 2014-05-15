function switcher(txt){
  $(".nav.navbar-nav").children(".active").removeClass("active");
  $(".nav.navbar-nav").children(":contains("+txt+")").addClass("active");
  var stockRenderMatcher = new RegExp("Stock","i");
  if(stockRenderMatcher.test(txt)) {
    prepareJsonAndDraw("bidu","1y");
  }
}


function naiveJson2chartJson(naiveJson){
  var chartJson = [];
  for(var i in naiveJson){
    var dateString = naiveJson[i].Date;
    var dateSplitArr = dateString.split("/");
    chartJson.push({date: new Date(dateSplitArr[2],dateSplitArr[0]-1,dateSplitArr[1]), value: naiveJson[i].Close});
  }
  return chartJson;
}

function loadChartJsSource(){
  var source = '<script type="text/javascript" src="amstockcharts/amcharts.js"></script>' + 
                     '<script type="text/javascript" src="amstockcharts/serial.js"></script>' + 
                     '<script type="text/javascript" src="amstockcharts/themes/dark.js"></script>' + 
                     '<script type="text/javascript" src="amstockcharts/amstock.js"></script>';
  $("body").append(source);
}

/*
Given a json that contains array of {date:xxx, value:xxx}, draw the stock chart
*/
function drawStockChart(chartJson){
  $(".starter-template").append('<div id="chartDiv"></div>');
  loadChartJsSource();
  fuckingCharts(chartJson);
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

function fuckingCharts(chartJson){
  AmCharts.makeChart("chartDiv", {

	type: "stock",

    "theme": "dark",
    pathToImages: "amstockcharts/images/",

	dataSets: [{
		color: "#b0de09",
		fieldMappings: [{
			fromField: "value",
			toField: "value"
		}],
		dataProvider: chartJson,
		categoryField: "date"
	}],

	panels: [{
		showCategoryAxis: true,
		title: "Value",
		eraseAll: false,
		allLabels: [{
			x: 0,
			y: 115,
			text: "Daddy is testing",
			align: "center",
			size: 16
		}],

		stockGraphs: [{
			id: "g1",
			valueField: "value",
			useDataSetColors: false
		}],


		stockLegend: {
			valueTextRegular: " ",
			markerType: "none"
		},

		drawingIconsEnabled: true
	}],

	chartScrollbarSettings: {
		graph: "g1"
	},
	chartCursorSettings: {
		valueBalloonsEnabled: true
	},
	periodSelector: {
		position: "bottom",
		periods: [{
			period: "DD",
			count: 10,
			label: "10 days"
		}, {
			period: "MM",
			count: 1,
			label: "1 month"
		}, {
			period: "YYYY",
			count: 1,
			label: "1 year"
		}, {
			period: "YTD",
			label: "YTD"
		}, {
			period: "MAX",
			label: "MAX"
		}]
	}
});
  }
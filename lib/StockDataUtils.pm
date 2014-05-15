package StockDataUtils;
use strict;
use warnings;
use LWP::UserAgent;
use Mojo::DOM;
sub new {
    my $class = shift;

    my $self = bless {@_}, $class;
    
    return $self;
};


sub nasdaqHTML2Json {
    my $html = shift;
    my $dom = Mojo::DOM->new($html);
    my $resultString = $dom->at('.table-headtag')->text;
    $dom->at('.table-headtag')->remove;
    my $stockDataItems = $dom->at('table > tbody')->children;
    # The first line is empty
    $stockDataItems = $stockDataItems->slice(1..$stockDataItems->size-1)->reverse;
    
    my $stockDataJsonArrayString ='[';	$stockDataItems->each(
        sub {
            my ($e, $count) = @_;
            my @dailyData = $e->at('tr')->children->each;
            $stockDataJsonArrayString = $stockDataJsonArrayString
                ."{\"Date\":\"".$dailyData[0]->text."\","
                ."\"Open\":\"".$dailyData[1]->text."\","
                ."\"High\":\"".$dailyData[2]->text."\","
                ."\"Low\":\"".$dailyData[3]->text."\","
                ."\"Close\":\"".$dailyData[4]->text."\","
                ."\"Volume\":\"".$dailyData[5]->text."\"},";		}	);
    chop($stockDataJsonArrayString);
    $stockDataJsonArrayString = $stockDataJsonArrayString.']';
    return $stockDataJsonArrayString;
};

sub nasdaqHTML2HashData {
	my $self = shift;
	
}

sub fetchStockDataFromNasdaq {
    my $self = shift;
    my $stockname = shift;
    my $ua = LWP::UserAgent->new;
    $ua->agent("Mozilla/5.0 (Windows NT 6.1)");

    my $req = HTTP::Request->new(POST => 'http://www.nasdaq.com/symbol/'.$stockname.'/historical');
    $req->content_type('application/json');
    $req->content('1y|false|'.$stockname);

    my $res = $ua->request($req);
    return nasdaqHTML2Json($res->content);
};

1;


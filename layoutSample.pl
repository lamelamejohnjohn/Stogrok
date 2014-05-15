use Mojolicious::Lite;

get '/' => 'starter-template';

# json Restful routes for stock data
use lib 'lib';
use StockDataUtils;
helper stockutils => sub {state $stockutils = StockDataUtils->new};
get '/stockdata/:stockname' => sub {
    my $self = shift;
    my $stockname = $self->stash('stockname');
    my $json = $self->stockutils->fetchStockDataFromNasdaq($stockname);
    $self->render(json=>$json);
  };


get '/with_layout';

get '/with_block' => 'block';

# A helper to identify visitors
helper whois => sub {
  my $self  = shift;
  my $agent = $self->req->headers->user_agent || 'Anonymous';
  my $ip    = $self->tx->remote_address;
  return "$agent ($ip)";
};

# Use helper in action and template
get '/secret' => sub {
  my $self = shift;
  my $user = $self->whois;
  $self->app->log->debug("Request from $user.");
};

get '/echo/:input' => sub{
   my $self = shift;
   my $input = $self->stash('input');
   $self->render(text => "The path :input placeholder matched $input ");
  };
  
get '/analyze/:stock' => sub{
    my $self = shift;
    my $stock = $self->stash('stock');
    $self->render('stock_plot', stock => $stock);
 
 
#    my $status = $self->render($stock);
#    unless($status) {
#      $self->render(text => "The data of $stock is not cached, now start to fetch from nasdaq... ");
#      }
};

app->start;

package TradingStrategy;
use strict;
use warnings;
use DateTime::Format::CLDR;
sub new {
    my $class = shift;

    my $self = bless {@_}, $class;
    
    return $self;
}

#
# Paras :     \%historyData: {dataTime:price,dataTime:price,...}
# 
# Return:    ($buyOrNot, $suggestedPrice) 
#       
# Simple Buy Decision decide to buy when:  
#       1. Current trend is in up direction, i.e. ,price is higher that previous 2 days.
#       2. Current price is in the bottom 20% of at least one stable period.
#       3. Latest lowest price (in 2 weeks /10 days ?) didn't go far from bottom of the stable period.
#           These parameters ( higher than previous 2 days,  bottom 20%, lowest price in 2 weeks , etc.) can be trained later use ML.
#
#
sub getSimpleBuyDecision {
    my $self = shift;
    my $historyDataRef = shift;
    
    my $buyOrNot = 0;
    my $suggestedPrice;
    my $trends = $self->recentTrendDecider($historyDataRef);
    
        # If the trend is in up direction
    return ($buyOrNot, $suggestedPrice) unless defined $trends and $trends eq "UP";
    
        # If condition 2 and 3 satisfied.     my @top3StablePeriods = $self->getTopNStablePeriod($historyDataRef, 3, 90);    # Mininal stable period as 90 days
    my %matchedStablePeriods;
    my $currentPrice = $self->getCurrentPrice($historyDataRef);
    my $lowestPrice = $self->getLatestLowPrice($historyDataRef);
    foreach my $stablePeriod(@top3StablePeriods){
        my $topPrice = ${$stablePeriod}{"PeriodTop"};
        my $bottomPrice = ${$stablePeriod}{"PeriodBottom"};
        
        if( $currentPrice > $bottomPrice 
            and $currentPrice < $bottomPrice + 0.2*($topPrice-$bottomPrice) 
            and $lowestPrice > $bottomPrice + 0.1*($topPrice-$bottomPrice)){
                $buyOrNot = 1;
                $suggestedPrice = $currentPrice +0.05*($topPrice-$bottomPrice);
                return ($buyOrNot, $suggestedPrice);
        }
    }
    return ($buyOrNot, $suggestedPrice);
}

sub getCurrentPrice {
    my $self = shift;
    my $historyDataRef = shift;
    my @dates = sort keys %{$historyDataRef};
    return ${$historyDataRef}{$dates[-1]};
}

# lowest pirce in 10 days
sub getLatestLowPrice {
    my $self = shift;
    my $historyDataRef = shift;
    my @latestPrices = [];
    my @dates = sort keys %{$historyDataRef};
    foreach my $date (@dates[-10..-1]){
            push @latestPrices, ${$historyDataRef}{$date};
    }
    @latestPrices = sort @latestPrices;
    return $latestPrices[0];
}

# Simply judge from the past 2 days trends.
sub recentTrendDecider {
    my $self = shift;
    my $historyDataRef = shift;
    my %historyData = %{$historyDataRef};
    my @dateSerial = sort keys %historyData;
    if( $historyData{$dateSerial[-3]} < $historyData{$dateSerial[-2]}  
        and  $historyData{$dateSerial[-2]} < $historyData{$dateSerial[-1]} ){
        return "UP";
     } elsif ($historyData{$dateSerial[-3]} > $historyData{$dateSerial[-2]} 
        and $historyData{$dateSerial[-2]} < $historyData{$dateSerial[-1]} ){
        return "DOWN";     }
    return undef;
     
}


# private method
#
# Paras:   \%historyDataRef , the history data hash {DateTimeString->price}
#            $n , how many stable period to return
#            $minLength , minimal length of period in days.
# Return: [StablePeriod1,StablePeriod2,...]
# 
# StablePeriod is a hash as: 
#     {StartDate->dateTime, EndDate->dateTime, PeriodTop: ceilingPrice, PeriodBottom: bottomPrice, PeriodQuality: q}
# 
# Here q = $endDate->delta_days($startDate)->in_units('days') / (ceilingPrice - bottomPrice)  
# A higher q value indicates we have a higher belief in its stable status.
#
sub getTopNStablePeriod {
    my $self = shift;
    my $historyDataRef = shift;    my $n = shift;
    my $minLength = shift;
    my %historyData = %{$historyDataRef};
    my ($startDate, $endDate) = $self->getDateRangeFromHistoryData(\%historyData);
    
    
    # Initialize stable period Array of size n
    my @topNStablePeriod;
    $minLength = 30 if not defined $minLength;
    my $maxLength;
    my $periodStartDate = $startDate->clone;
    for(my $i = 0; $i < $n; $i ++){
        $maxLength = $endDate->subtract_datetime($periodStartDate)->in_units('days');
        if($maxLength < $minLength){ return;} # this should happen rarely
        my $stablePeriod = $self->getStablePeriod($periodStartDate->clone, $minLength, $maxLength, $historyDataRef);
        push @topNStablePeriod, $stablePeriod;
        $periodStartDate->add(days => 1);    }
    
       # Iterate to get top n stable period
    $maxLength = $endDate->subtract_datetime($periodStartDate)->in_units('days');
    while($maxLength >= $minLength){
        my $stablePeriod = $self->getStablePeriod($periodStartDate->clone, $minLength, $maxLength, $historyDataRef);
        push @topNStablePeriod, $stablePeriod;
        @topNStablePeriod = sort {$b->{"PeriodQuality"} cmp $a->{"PeriodQuality"}} @topNStablePeriod;
        @topNStablePeriod = @topNStablePeriod[0..$n-1];
        $periodStartDate->add(days => 1);
        $maxLength = $endDate->subtract_datetime($periodStartDate)->in_units('days');
    }
    return @topNStablePeriod;
}

#
# Paras :  \%historyDataRef 
#            $startDate 
#            $minLength , measured in days, suggested at least 90 days
#            $maxLength , measured in days
#            
# Return:  StablePeriod  
# StablePeriod is a hash as: 
#     {StartDate->dateTime, EndDate->dateTime, PeriodTop: ceilingPrice, PeriodBottom: bottomPrice, PeriodQuality: q}
#                     
# Given a start date, we will only take the stable period with best q value.
#
sub getStablePeriod {
    my $self = shift;
    my ( $startDate, $minLength, $maxLength, $historyDataRef ) = @_;
    my %stablePeriod;
    if($maxLength < $minLength) {return ;}
    $stablePeriod{"StartDate"} = $startDate->clone;    my $qValue = 0;
    my $lengthOfDays = $minLength;
    my $myStartDate = $startDate->clone;
    while($lengthOfDays <= $maxLength){
        my $ceilingPrice = $self->getCeilingPriceInPeriod($myStartDate, $lengthOfDays, $historyDataRef);
        my $bottomPrice = $self->getBottomPriceInPeriod($myStartDate, $lengthOfDays, $historyDataRef);
        my $newQValue = $lengthOfDays / ($ceilingPrice - $bottomPrice+0.0001); #incase of they are the same
        if($newQValue > $qValue){
            $qValue = $newQValue;
            $stablePeriod{"EndDate"} = $myStartDate->add( days => $lengthOfDays);
            $stablePeriod{"PeriodTop"} = $ceilingPrice;
            $stablePeriod{"PeriodBottom"} = $bottomPrice;
            $stablePeriod{"PeriodQuality"} = $qValue;
            $myStartDate = $startDate->clone;
        }
        $lengthOfDays++;
    }
    return \%stablePeriod;
}

sub getCeilingPriceInPeriod {
    my $self = shift;
    my ($startDate, $lengthOfDays, $historyDataRef) = @_;
    my %historyData = %{$historyDataRef};
    my $ceilingPrice = $historyData{$startDate};
    my $i = 0;
    my $currentDate = $startDate->clone;    while($i < $lengthOfDays){
        $currentDate->add( days => 1);
        my $newPrice = $historyData{$currentDate};
        if($newPrice > $ceilingPrice){
            $ceilingPrice = $newPrice;        }
        $i ++;    }
    return $ceilingPrice;
}
sub getBottomPriceInPeriod {
    my $self = shift;
    my ($startDate, $lengthOfDays, $historyDataRef) = @_;
    my %historyData = %{$historyDataRef};
    my $bottomPrice = $historyData{$startDate};
    my $i = 0;
    my $currentDate = $startDate->clone;
    while($i < $lengthOfDays){
        $currentDate->add( days => 1);
        my $newPrice = $historyData{$currentDate};
        if($newPrice < $bottomPrice){
            $bottomPrice = $newPrice;
        }
        $i ++;
    }
    return $bottomPrice;
}


sub getDateRangeFromHistoryData {
    my $self = shift;
    my $historyDataRef = shift;
    my @dates = sort {$a cmp $b} keys %{$historyDataRef};
    # Might need a clone DateTime to be returned...in case the orignal data are not modified
    # Update: no need actually, the keys in perl are always string, so the DateTime object is stringified.  
    # Here we need to parse them back to DateTime object  
    
    my $cldr = DateTime::Format::CLDR->new(pattern => "yyyy-MM-dd'T'HH:mm:ss");
    return ($cldr->parse_datetime($dates[0]), $cldr->parse_datetime($dates[-1]));
}
sub isSellPoint {
    my $self = shift;
    my $historyPriceArrRef = shift;#    my $historyDataRef = shift;
#    my %historyData = %{$historyDataRef};
    my $boughtPrice = shift;
    
}

=head
=cut
1;
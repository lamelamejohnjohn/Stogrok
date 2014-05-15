use strict;
use warnings;
# Set up the plan number is just annoying.#use Test::More  tests=>13;
# This one will go until the done_testing() shows up.
use Test::More;
use lib 'lib';
use TradingStrategy;
use DateTime;

# Preparing test data
my %testData;
my $startDate = DateTime->new(
        year    => 2014,
        month  => 5,
        day     => 25,
        );
my $date = $startDate->clone;$testData{$date} = 100;
$testData{$date->add(days => 1)} = 101;
$testData{$date->add(days => 1)} = 103;
$testData{$date->add(days => 1)} = 99;
$testData{$date->add(days => 1)} = 102;
$testData{$date->add(days => 1)} = 102.4;
$testData{$date->add(days => 1)} = 102.2;
$testData{$date->add(days => 1)} = 108.1;
$testData{$date->add(days => 1)} = 102.4;
$testData{$date->add(days => 1)} = 102.2;
$testData{$date->add(days => 1)} = 102.1;
$testData{$date->add(days => 1)} = 102.2;
$testData{$date->add(days => 1)} = 102.3;
$testData{$date->add(days => 1)} = 102.5;

# Test starts
my $strategy = TradingStrategy->new;
ok(defined $strategy);
ok($strategy->isa('TradingStrategy'));

is($strategy->getCeilingPriceInPeriod($startDate, 5, \%testData), 103);
is($strategy->getBottomPriceInPeriod($startDate, 5, \%testData), 99);
my $period = $strategy->getStablePeriod($startDate, 3, 5, \%testData);
is( ${$period}{"PeriodTop"}, 103);
is( ${$period}{"PeriodBottom"}, 99);
($startDate,my $endDate) = $strategy->getDateRangeFromHistoryData(\%testData);
ok($startDate->isa('DateTime'));
is($startDate, DateTime->new(year=>2014, month=>5, day=>25));
is($endDate, DateTime->new(year=>2014, month=>6, day=>7));

my @top3StablePeriod = $strategy->getTopNStablePeriod(\%testData, 5, 5);
is(@top3StablePeriod, 5);is(${$top3StablePeriod[0]}{"StartDate"}, DateTime->new(year=>2014, month=>5, day=>31));
is(${$top3StablePeriod[0]}{"EndDate"}, DateTime->new(year=>2014, month=>6, day=>7));
is(${$top3StablePeriod[0]}{"PeriodQuality"}, 0);
is(${$top3StablePeriod[1]}{"StartDate"}, DateTime->new(year=>2014, month=>6, day=>2));
is(${$top3StablePeriod[1]}{"EndDate"}, DateTime->new(year=>2014, month=>6, day=>7));
is(${$top3StablePeriod[1]}{"PeriodQuality"}, 0);
is(${$top3StablePeriod[2]}{"StartDate"}, DateTime->new(year=>2014, month=>6, day=>1));
is(${$top3StablePeriod[2]}{"EndDate"}, DateTime->new(year=>2014, month=>6, day=>7));
is(${$top3StablePeriod[2]}{"PeriodQuality"}, 0);
is(${$top3StablePeriod[3]}{"StartDate"}, DateTime->new(year=>2014, month=>5, day=>25));
is(${$top3StablePeriod[3]}{"EndDate"}, DateTime->new(year=>2014, month=>6, day=>7));
is(${$top3StablePeriod[3]}{"PeriodQuality"}, 0);
is(${$top3StablePeriod[4]}{"StartDate"}, DateTime->new(year=>2014, month=>5, day=>26));
is(${$top3StablePeriod[4]}{"EndDate"}, DateTime->new(year=>2014, month=>6, day=>7));
is(${$top3StablePeriod[4]}{"PeriodQuality"}, 0);

my $trends = $strategy->recentTrendDecider(\%testData);
is($trends, "UP");done_testing();
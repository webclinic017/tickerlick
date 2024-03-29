#!/usr/bin/perl
use lib '/home/tthaliath/Tickermain';
use DBI;
use DMA;
use TickerDB;
my $tickid = 1;
my $tickidmax = 14448;
my $offset = 1;
my $dmaday = 12;

my ($price_date) = $ARGV[0];
if (!$price_date)
{
  print "Please enter price date as a command lin argument\n";
  exit 1;
}
print "Price date:$price_date\n";
$dbh = DBI->connect('dbi:mysql:tickmaster','root','Neha*2005')
 or die "Connection Error: $DBI::errstr\n";
my $tickerdb = new TickerDB($price_date,$dbh);
print "Calculating EMA12\n";
my $dma12 = new DMA($dmaday,$dbh);
while ($tickid <= $tickidmax)
{
#print "$tickid\t$offset\n";
$dma12->setEMA($tickid,$offset);
$tickid++;
}
print "Calculating EMA26\n";
$dmaday = 26;$tickid = 1;$offset = 1;
my $dma26 = new DMA($dmaday,$dbh);
while ($tickid <= $tickidmax)
{
 #print "$tickid\t$offset\n";
 $dma26->setEMA($tickid,$offset);
 $tickid++;
}
#update ema diff for MACD 1226
print "Calculating MACD line\n";
$tickid = 1;
$tickerdb->setMACD_12269($tickid,$tickidmax);
$dbh->disconnect; 

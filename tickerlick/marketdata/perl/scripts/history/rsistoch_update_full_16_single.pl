#!/usr/bin/perl
use lib '/home/tthaliath/Tickermain';
use DBI;
use DMASR;
my $tickidmin = $ARGV[0];
my $tickidmax = $tickidmin;

my $dmaday2 = 14;
$dbh = DBI->connect('dbi:mysql:tickmaster','root','Neha*2005')
 or die "Connection Error: $DBI::errstr\n";
print "Calculating DMA3\n";
my $dma14 = new DMASR($dmaday2,$dbh);
$query ="select distinct ticker_id from  tickerpricersi where ticker_id >= ? and ticker_id <= ? ";
 $sth = $dbh->prepare($query);
 $sth->execute($tickidmin,$tickidmax) or die "SQL Error: $DBI::errstr\n";
 #print "$query\n";
 while (@row = $sth->fetchrow_array)
 {
  $tickid = $row[0];
  print "$tickid\n";
  $dma14->setRSIStochasticHistory($tickid);
}
$sth->finish;
$dbh->disconnect; 

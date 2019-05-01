#!/usr/bin/perl
use lib '/home/tthaliath/Tickermain';
use DBI;
use DMA;
my $tickid = 11063;
my $tickidmax = 11608;
my $offset = 243;
my $dmaday = 5 
$dbh = DBI->connect('dbi:mysql:tickmaster','root','Neha*2005')
 or die "Connection Error: $DBI::errstr\n";
print "Calculating EMA10\n";
my $dma12 = new DMA($dmaday,$dbh);
while ($tickid <= $tickidmax)
{
#print "$tickid\t$offset\n";
$dma12->setEMAStart($tickid,$offset);
$tickid++;
}
print "Calculating EMA26\n";
$dmaday = 35;$tickid = 11063;$offset = 229;
my $dma26 = new DMA($dmaday,$dbh);
while ($tickid <= $tickidmax)
{
 #print "$tickid\t$offset\n";
 $dma26->setEMAStart($tickid,$offset);
 $tickid++;
}


$dbh->disconnect; 
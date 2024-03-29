#!/usr/bin/perl


use strict;
use warnings;
use lib qw(/home/tickerlick/Tickermain);
use LWP::Simple;
use DBI;
use Webcrawler;
use TickerDB;
use DMA;
use Date::Calc qw(Day_of_Week);
my ($ticker,%hash,$ret,@rest,$ticker_id,$last_price) ;
my ($avg_gain,$avg_loss,$close_price,$curr_gain,$curr_loss,$dow,$prev_avg_gain,$prev_avg_loss,$query,$rs,$rsi,$sth,@row,@row_cur_avg,@row_day,@row_diff,@row_prev_avg);
my ($dbh);
sub updatecurrentprice
{
my $ticker_id = shift;
my $last_price = shift;
my $ticker = shift;
my $webcrawler = new Webcrawler();
my ($price_date) = $webcrawler->getToday();
#print "date:$price_date\n";
$dbh = DBI->connect('dbi:mysql:tickmaster','root','Neha*2005') or die "Connection Error: $DBI::errstr\n";
my $tickerdb = new TickerDB($price_date,$dbh);
$last_price = $webcrawler->getLastPrice($ticker);
#print "last:last_price\n";

if ($last_price && $last_price > 0)
{
   $last_price =~ s/\,//g;
   $ret = $tickerdb->loadPrice($ticker_id,$price_date,$last_price);
   #$retrsi = $tickerdb->loadPricersi($ticker_id,$price_date,$last_price);
 #insert into tickerpricersi
 #if price exists for given date. if exists, delete it first.
 my $deletesql = "delete from tickerpricersi where ticker_id = $ticker_id and price_date = '$price_date'";
 my $ret = $dbh->do($deletesql);
 my $insertsql = "insert into tickerpricersi (ticker_id,price_date,close_price) values ($ticker_id,'$price_date',$last_price)";
 $ret = $dbh->do($insertsql);

#update DMA
 my $offset = 0;
 my $dmaday = 10;
 #print "Calculating DMA10 for $ticker_id\n";
 my $dma10 = new DMA($dmaday,$dbh);
 $dma10->setDMA($ticker_id,$offset);
 #print "Calculating DMA50\n";
 $dmaday = 50;
 my $dma50 = new DMA($dmaday,$dbh);
 $dma50->setDMA($ticker_id,$offset);
 #print "Calculating DMA200\n";
 $dmaday = 200;
 my $dma200 = new DMA($dmaday,$dbh);
 $dma200->setDMA($ticker_id,$offset);
 #print "Calculating DMA20\n";
 $dmaday = 20;
 my $dma20 = new DMA($dmaday,$dbh);
 $dma20->setDMA($ticker_id,$offset);
#print "Calculating bollinger band sd\n";
 setDMASD($ticker_id,$offset);
#update EMA (12,26,9)

  $offset = 1;
  $dmaday = 12;
 #print "Calculating EMA10\n";
 my $dma12 = new DMA($dmaday,$dbh);
 $dma12->setEMA($ticker_id,$offset);
 #print "Calculating EMA26\n";
 $dmaday = 26;$offset = 1;
 my $dma26 = new DMA($dmaday,$dbh);
 $dma26->setEMA($ticker_id,$offset);

#update MACD line
 #print "Calculating MACD line\n";
 $dmaday = 12; 
 #my $dmamacd = new DMA($dmaday,$dbh);
 #$dmamacd->setMACDSingle($ticker_id,$price_date);
 setMACDSingle($ticker_id,$price_date,$dbh);

#update signal line

 $dmaday = 9;
 #print "Calculating signal line\n";
 my $dma9 = new DMA($dmaday,$dbh);
 $offset = $dma9->getMACDOffset($ticker_id);
 #print "$ticker_id\t$offset\n";
 if ($offset > 0){$dma9->setEMAMACD($ticker_id,$offset)};
 
 #update EMA (5,35,5)

  $offset = 1;
  $dmaday = 5;
 #print "Calculating EMA10\n";
 my $dma5 = new DMA($dmaday,$dbh);
 $dma5->setEMA($ticker_id,$offset);
 #print "Calculating EMA26\n";
 $dmaday = 35;$offset = 1;
 my $dma35 = new DMA($dmaday,$dbh);
 $dma35->setEMA($ticker_id,$offset);

#update MACD line
 setMACD5355Single($ticker_id,$price_date,$dbh);

#update signal line

 $dmaday = 5;
 #print "Calculating signal line\n";
 $dma5 = new DMA($dmaday,$dbh);
 $offset = $dma5->getMACD535Offset($ticker_id);
 #print "$ticker_id\t$offset\n";
 if ($offset > 0){$dma5->setEMAMACD535($ticker_id,$offset)};


#update RSI

my ($prev_price_date,$prev_close_price,$gain,$loss);
my $upd_query ="update tickerpricersi set gain = ?, loss = ? where ticker_id = ? and price_date = ?";
my $sth_upd = $dbh->prepare($upd_query);
my $diff_query ="select price_date,close_price from tickerpricersi where ticker_id = $ticker_id and price_date < $price_date order by price_date desc limit 1" ;

my $sth_diff = $dbh->prepare($diff_query);
$sth_diff->execute or die "SQL Error: $DBI::errstr\n";
while (@row_diff = $sth_diff->fetchrow_array)
{
   $prev_price_date = $row_diff[0];
   $prev_close_price = $row_diff[1];
}
$sth_diff->finish();
my $day_query ="select close_price from tickerpricersi where ticker_id = $ticker_id and price_date = $price_date" ;

my $sth_day = $dbh->prepare($day_query);
$sth_day->execute or die "SQL Error: $DBI::errstr\n";
while (@row_day = $sth_day->fetchrow_array)
{
   $close_price = $row_day[0];
   $gain = 0; $loss = 0;
   if ($close_price > $prev_close_price)
         {
             $gain = $close_price - $prev_close_price;
             $loss = 0;
         }
      else
        {
            $loss = $prev_close_price - $close_price;
            $gain = 0;
        }
        $sth_upd->execute($gain,$loss,$ticker_id,$price_date) or die "SQL Error: $DBI::errstr\n";
}

$sth_day->finish();
$sth_upd->finish();

#update rsi 14
my $prev_avg_query = "select avg_gain,avg_loss from tickerpricersi where ticker_id = ? and price_date < ? order by price_date desc limit 1";
my $cur_avg_query = "select gain,loss from tickerpricersi where ticker_id = ? and price_date = ?";
my $upd_avg_query = "update tickerpricersi set avg_gain = ?, avg_loss = ? ,rsi = ?, rsi_14 = ? where ticker_id = ? and price_date = ?";
my $sth_prev_avg_query = $dbh->prepare($prev_avg_query);
my $sth_cur_avg_query = $dbh->prepare($cur_avg_query);
my $sth_upd_avg_query = $dbh->prepare($upd_avg_query);
#update gain and loss
   $sth_prev_avg_query->execute($ticker_id,$price_date) or die "SQL Error: $DBI::errstr\n";
   while (@row_prev_avg = $sth_prev_avg_query->fetchrow_array)
    {
          $prev_avg_gain = $row_prev_avg[0];
          $prev_avg_loss = $row_prev_avg[1];
    }
    $sth_prev_avg_query->finish();
   $sth_cur_avg_query->execute($ticker_id,$price_date) or die "SQL Error: $DBI::errstr\n";
   while (@row_cur_avg = $sth_cur_avg_query->fetchrow_array)
    {
       $curr_gain = $row_cur_avg[0];
       $curr_loss = $row_cur_avg[1];
       $avg_gain = (($prev_avg_gain  * 13.00) + $curr_gain) / 14.00;
       $avg_loss = (($prev_avg_loss  * 13.00) + $curr_loss) / 14.00;
       if ($avg_gain == 0){$rs = 0;$rsi = 0;}
       elsif ($avg_loss == 0){$rs = 100;$rsi = 100;}
       else
        {
          $rs = $avg_gain/$avg_loss;
          $rsi = 100.00 - (100.00/(1.00+$rs));
        }
            $sth_upd_avg_query->execute($avg_gain,$avg_loss,$rs,$rsi,$ticker_id,$price_date);
            $prev_avg_gain = $avg_gain;
            $prev_avg_loss = $avg_loss;
      #print "$price_date,$first_row_flag,$prev_avg_gain,$prev_avg_loss,$curr_gain, $curr_loss,$avg_gain ,$avg_loss\n";

   }
$sth_cur_avg_query->finish();

#update stochastic;
 $dmaday = 3;
my $dmaday2 = 14;
my $dma3 = new DMA($dmaday,$dbh);
my $dma14 = new DMA($dmaday2,$dbh);
#print "<h>starting stochastic</h>";
$dma14->setStochasticDaily($ticker_id);
$dma3->setDMAStochDaily($ticker_id);
$dma3->setDMAStochFullDaily($ticker_id);
#$dbh->disconnect; 
} #eof if price exists
} #eof function

sub getTickerID
{
  my $ticker = shift;
  my $dbh = DBI->connect('dbi:mysql:tickmaster','root','Neha*2005') or die "Connection Error: $DBI::errstr\n";
  $query = "select ticker_id from tickermaster where ticker = '$ticker'";
   #print "tom::$query\n";
  $sth = $dbh->prepare($query);
 $sth->execute or die "SQL Error: $DBI::errstr\n";
 while (@row = $sth->fetchrow_array)
 {
      $ticker_id = $row[0];
 }
  $sth->finish;
  #$dbh->disconnect;
  #if (!$row[0]){return -1;}
  return $ticker_id;
}  

sub setMACDSingle
{
  my ($tickid) = shift;
  my ($price_date) = shift;
  my ($dbh) = shift;
  my($updatemacd,$ret);
 $updatemacd = "update tickerprice set ema_diff = (ema_12 - ema_26) where  ticker_id = $tickid and price_date = '$price_date'";
 #print "$updatemacd\n";
 $ret = $dbh->do($updatemacd) or die "SQL Error: $DBI::errstr\n";
}


sub setMACD5355Single
{
  my ($tickid) = shift;
  my ($price_date) = shift;
  my ($dbh) = shift;
  my($updatemacd,$ret);
 $updatemacd = "update tickerprice set ema_diff_5_35 = (ema_5 - ema_35) where  ticker_id = $tickid and price_date = '$price_date'";
 #print "$updatemacd\n";
 $ret = $dbh->do($updatemacd) or die "SQL Error: $DBI::errstr\n";
}

sub setDMASD
{
  my ($tickid) = shift;
  my ($offset) = shift;
  my $dmadays = 20;
  my ($query,$updatedma,$sth,@row,$ret);
 #$query = "select SQRT(avg((close_price - dma_10) * (close_price - dma_10))) from tickerprice where ticker_id = 9 and price_date > '20141215';
 $query ="SELECT SQRT(avg((close_price - dma_20) * (close_price - dma_20)))  AS dma_20_sd, max(price_date) as pdate,count(1) as rec_cnt FROM (SELECT dma_20,close_price, price_date FROM tickerprice WHERE ticker_id = $tickid ORDER BY price_date DESC LIMIT $offset,20) AS abc;";
 #print "$query\n";
  $sth = $dbh->prepare($query);
  $sth->execute or die "SQL Error: $DBI::errstr\n";
    #print "$query\n";
     while (@row = $sth->fetchrow_array) {
      #print "$row[0]\t$row[1]]\t$row[2]\n";
       if ($dmadays != $row[2]){next;}
        $updatedma = "update tickerprice set dma_20_sd = $row[0] where ticker_id = $tickid and price_date = '$row[1]'";
         #print "$updatedma\n";
          $ret = $dbh->do($updatedma);
       }
       $sth->finish;
  }
sub  marketlive()
{
 my ($sec,$min,$hr,$day,$month,$yr19,@rest) =  localtime(time);
 $dow = Day_of_Week(($yr19+1900),($month+1),$day);
 #print "$dow,$hr,$min\n";
 if ($dow >= 6){return 0;}
 if ($hr >= 7){return 1;}
 if ($hr == 6 && $min >= 30){return 1;}
 return 0;	 
}
1;

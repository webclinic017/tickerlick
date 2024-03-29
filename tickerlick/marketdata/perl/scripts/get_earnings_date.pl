#!/usr/bin/perl
use LWP::Simple;
my (%tickhash,%datehash,$str,$ticker,$prev_day,$cname);
($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
$mon += 1;
$year += 1900;
$today = sprintf("%04d%02d%02d",$year,$mon,$mday);
my $todaydb = sprintf("%04d\-%02d\-%02d",$year,$mon,$mday);
open (F,"<usticker.lst");
while(<F>)
{
  chomp;
  $tickhash{$_}++;
} 
close (F);
my $file = "earnings\.csv";
open(OUT,">$file");
#first get update date
my ($updown,$upgradeurl,$downgradeurl);
use Date::Calc qw(Add_Delta_Days Day_of_Week);
my $entered_date = $todaydb;
my $days = 0;
while ($days < 2)
{
($year,$mon,$mday) = Add_Delta_Days(split(/-/,$entered_date),$days);
$dow = Day_of_Week($year,$mon,$mday);
$today = sprintf("%04d%02d%02d",$year,$mon,$mday);
$todaydb = sprintf("%04d\-%02d\-%02d",$year,$mon,$mday);
if ($dow =~ /^[1|2|3|4|5]$/)
{
$url ='http://biz.yahoo.com/research/earncal/'.$today.'.html';
$content = get ($url);
$content =~ s/\n/ /g;
if ($content =~ /^.*?Calendar<\/b><\/font>(.*?)<\/table>/)
{
$str = $1;
($year,$mon,$mday) = Add_Delta_Days(split(/-/,$todaydb),-10);
$prev_day = sprintf("%04d\-%02d\-%02d",$year,$mon,$mday);

while ($str =~ /.*?bgcolor=eeeeee><td>(.*?)<\/td><td>.*?href.*?>(.*?)<.*?<\/td>/gs)
{
$cname = $1;
$ticker = $2;
#<a href='http://www.tickerlick.com/cgi-bin/gettickermain2.cgi?q=$row[0]'>$row[0] - $row[1]: <b>$rounded</b></a><br>
if ($ticker eq 'Add'){next};
          if ($tickhash{$ticker})
            {
              $ins_query = "<a href='https://finance.yahoo.com/quote/$ticker'>$cname - $todaydb</a><br>"; 
            }
            else
            {
              $ins_query = ''; 
            }
            if ($ins_query)
            {  
             $ins_query =~ s/\&amp\;/\&/g;
             print OUT "$ins_query\n";
            }
}
}
}
$days++;
}
use MIME::Lite;
my ($d,$m,$y) = (localtime)[3,4,5];
my $str = sprintf '%04d-%02d-%02d', $y+1900,$m+1,$d;
close (OUT);
my $msg = MIME::Lite->new(
    From    => 'tthaliath@gmail.com',
    To      => 'tthaliath@gmail.com',
    Subject => 'daily earnings report (Today/Next Day)',
    Data   => $Mail_msg
);
my $Mail_msg = "<html><head></head><body>";
$Mail_msg .= "<h2>Tickerlick - Earnings Today/Next Day</h2><br><br>";
open (F,"<$file");
undef $/;
$Mail_msg .= <F>;
close (F);
$/ = 1;
$Mail_msg .= "</body></html>";
my $msg = MIME::Lite->new(
    From    => 'tthaliath@gmail.com',
    To      => 'tthaliath@gmail.com',
    Subject => 'daily earnings report (Today/Next Day)',
    Data   => $Mail_msg
);
$msg->attr("content-type" => "text/html");
$msg->send;
1;


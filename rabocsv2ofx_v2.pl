#!/usr/bin/perl

#    rabo2ofx_v2.pl
#    Version 2.0
#    HaNS1443
#    Updated for Rabobank new csv format from Q1 2018
#    Minor fixes
#
#    rabo2ofx_newformat.pl
#    Version 0.1
#    Arie Baris
#    Updated for Rabobank csv format with IBAN instead of BBAN
#    New format also has quotes around all numbers
#    Also improved description value for GNUCash
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

sub printheader
{
	($se,$mi,$ho,$d,$m,$y)=gmtime(time()); # can't assume strftime
	$nowdate=sprintf("%04d%02d%02d%02d%02d%02d",$y+1900,$m+1,$d,$ho,$mi,$se);
	print <<EOT;
<OFX>
<SIGNONMSGSRSV1>
       <SONRS>                          <!-- Begin signon -->
          <STATUS>                      <!-- Begin status aggregate -->
            <CODE>0</CODE>              <!-- OK -->
            <SEVERITY>INFO</SEVERITY>
          </STATUS>
          <DTSERVER>$nowdate</DTSERVER><!-- Oct. 29, 1999, 10:10:03 am -->
          <LANGUAGE>ENG</LANGUAGE>                <!-- Language used in response -->
          <DTPROFUP>$nowdate</DTPROFUP><!-- Last update to profile-->
          <DTACCTUP>$nowdate</DTACCTUP><!-- Last account update -->
          <FI>                          <!-- ID of receiving institution -->
            <ORG>NCH</ORG>              <!-- Name of ID owner -->
            <FID>1001</FID>             <!-- Actual ID -->
          </FI>
       </SONRS>                         <!-- End of signon -->
     </SIGNONMSGSRSV1>
     <BANKMSGSRSV1>
       <STMTTRNRS>                      <!-- Begin response -->
          <TRNUID>1001</TRNUID>         <!-- Client ID sent in request -->
          <STATUS>                      <!-- Start status aggregate -->
            <CODE>0</CODE>              <!-- OK -->
            <SEVERITY>INFO</SEVERITY>
          </STATUS>
EOT
}

sub printfooter
{
	print <<EOT;
             </STMTTRNRS>                           <!-- End of transaction -->
             </BANKMSGSRSV1>
       </OFX>
EOT
}

#
# main
#
&printheader();
$mindate=99999999;
$maxdate=0;
$tnr=0;
while (<>)
{
	#s/^\"//;	# remove starting "
	#s/\"\s*$//;	# remove trailing "
	#($t_datum, $t_name, $t_myaccount, $t_otheraccount, $t_code, $t_credit, $t_amount, $t_mu, $t_memo) = split(/\",\"/);
	#($t_van_rek, $t_muntsoort, $t_rentedatum, $t_bij_af_code, $t_bedrag, $t_naar_rek, $t_naar_naam, $t_boekdatum, $t_boekcode, $t_budgetcode, $omschr1, $omschr2, $omschr3, $omschr4, $omschr5, $omschr6) = split(/\",\"/);
	if ( /"(.{0,34})","EUR","(\w{8})","(\d{18})","(.{4})(.)(.{2})(.)(.{2})","(.{4})(.)(.{2})(.)(.{2})","(.)(\d*\,\d{2})","(.)(\d*\,\d{2})","(.{0,34})","(.{0,70})","(.{0,70})","(.{0,70})","(.{0,15})","(.{0,4})","(.{0,35})","(.{0,35})","(.{0,35})","(.{0,35})","(.{0,35})","(.{0,140})","(.{0,140})","(.{0,140})","(.{0,75})","(.{0,18})","(.{0,11})","(.{0,11})"/)
	{
		$t_van_rek = $1;
		$BIC = $2;
		$volgnr = $3;
		$t_rentedatum = "${4}${6}${8}";
		$t_boekdatum = "${9}${11}${13}";
		$t_bij_af_code = $14;
		$t_bedrag = $15;
		#$Sign_Saldo_na_trn = $16;
		#$Saldo_na_trn = $17;
		$t_naar_rek = $18;
		$t_naar_naam = $19;
		#$Naam_uiteindelijke_partij = $20;
		#$Naam_initiërende_partij = $21;
		$BIC_tegenpartij = $22;
		$t_boekcode = $23;
		#$Batch_ID = $24;
		#$Transactiereferentie = $25;
		#$Machtigingskenmerk = $26;
		#$Incassant_ID = $27;
		#$Betalingskenmerk = $28;
		$omschr1 = $29;
		$omschr2 = $30;
		$omschr3 = $31;
		#$Reden_retour = $32;
		#$Oorspr_bedrag = $33;
		#$Oorspr_munt = $34;
		#$Koers = $34;
		
#		if ($t_van_rek =~ /(\w{18})/)
		{
			if ($t_rentedatum < $mindate)
			{
				$mindate = $t_rentedatum;
			}
			if ($t_rentedatum > $maxdate)
			{
				$maxdate = $t_rentedatum;
			}
			$accounts{$1}=1;
			if ($t_boekcode eq "ma")	# Machtiging
			{
				$trntype = "DIRECTDEBIT";
			} elsif ($t_boekcode eq "tb")	# Telebankieren
			{
				$trntype = "PAYMENT";
			} elsif ($t_boekcode eq "ba")	# betaalautomaat
			{
				$trntype = "POS";
			} elsif ($t_boekcode eq "ga")	# geldautomaat (pin)
			{
				$trntype = "ATM";
			} elsif ($t_boekcode eq "ov")	# overschrijving
			{
				if ($t_bij_af_code eq "-")
				{
					$trntype = "CREDIT";
				} else {
					$trntype = "DEBIT";
				}
			} elsif ($t_boekcode eq "ck")	# Chipknip
			{
				if ($t_bij_af_code eq "-")
				{
					$trntype = "CREDIT";
				} else {
					$trntype = "DEBIT";
				}
			} elsif ($t_boekcode eq "cb")	# Creditboeking
			{
				if ($t_bij_af_code eq "-")
				{
					$trntype = "CREDIT";
				} else {
					$trntype = "DEBIT";
				}
			} elsif ($t_boekcode eq "da")	# diversen
			{
				if ($t_bij_af_code eq "-")
				{
					$trntype = "CREDIT";
				} else {
					$trntype = "DEBIT";
				}
			} else
			{
				$trntype = "OTHER";
			}
			if ($t_bij_af_code eq "+")
			{
				$amount = $t_bedrag;
			} else {
				$amount = "-".$t_bedrag;
			} 
			$transaction[$tnr]{'account'} = $t_van_rek;
			$transaction[$tnr]{'trntype'} =	$trntype;
			$transaction[$tnr]{'dtposted'} = $t_rentedatum;
			$transaction[$tnr]{'trnamt'} = $amount;
			$transaction[$tnr]{'fitid'} = $volgnr;
			$transaction[$tnr]{'payee'} = $t_naar_naam;
			$transaction[$tnr]{'bicteg'} = $BIC_tegenpartij;
			$transaction[$tnr]{'bankacctto'} = $t_naar_rek;
			$transaction[$tnr]{'name'} = "$t_naar_naam; $omschr1";						
			$transaction[$tnr]{'memo'} = "$t_naar_naam; $omschr1$omschr2$omschr3";
			#print "$transaction[$#transaction]{'account'}\n";
			$tnr++;
		}
	}
}

foreach my $rekening (keys %accounts)
{
#	print "rekening: $rekening\n";
	print <<EOT;
	<STMTRS>                      <!-- Begin statement response -->
            <CURDEF>EUR</CURDEF>
	<BANKACCTFROM>              <!-- Identify the account -->
                  <BANKID>$BIC</BANKID><!-- Routing transit or other FI ID -->
                  <ACCTID>$rekening</ACCTID><!-- Account number -->
                  <ACCTTYPE>CHECKING</ACCTTYPE><!-- Account type -->
        </BANKACCTFROM>             <!-- End of account ID -->
	<BANKTRANLIST>              <!-- Begin list of statement
                                        trans. -->
                  <DTSTART>$mindate</DTSTART>
                  <DTEND>$maxdate</DTEND>
EOT
	for ($tnr=0; $tnr <= $#transaction ; $tnr++)
	{
#		print "$transaction[$tnr]{'account'}, $transaction[$tnr]{'payee'}\n";
		if ($rekening == $transaction[$tnr]{'account'})
		{
			#print "$t_myaccount, $t_name\n";
			print "<STMTTRN>\n";
			print "\t<TRNTYPE>$transaction[$tnr]{'trntype'}</TRNTYPE>\n";
			print "\t<DTPOSTED>$transaction[$tnr]{'dtposted'}</DTPOSTED>\n";
			print "\t<TRNAMT>$transaction[$tnr]{'trnamt'}</TRNAMT>\n";
			print "\t<FITID>$transaction[$tnr]{'fitid'}</FITID>\n";
			print "\t<NAME>$transaction[$tnr]{'name'}</NAME>\n";
			print "\t<BANKACCTTO>\n\t\t<BANKID>$transaction[$tnr]{'bicteg'}</BANKID>\n\t\t<ACCTID>$transaction[$tnr]{'bankacctto'}</ACCTID>\n\t\t<ACCTTYPE>CHECKING</ACCTTYPE>\n\t</BANKACCTTO>\n";
			print "\t<MEMO>$transaction[$tnr]{'memo'}</MEMO>\n";
			print "</STMTTRN>\n";

		}
	}
	print <<EOT;
		    </BANKTRANLIST>                   <!-- End list of statement trans. -->
                    <LEDGERBAL>                       <!-- Ledger balance aggregate -->
                       <BALAMT>0</BALAMT>
                       <DTASOF>199910291120</DTASOF><!-- Bal date: 10/29/99, 11:20 am -->
                    </LEDGERBAL>                      <!-- End ledger balance -->
                 </STMTRS>  
EOT


}
&printfooter();



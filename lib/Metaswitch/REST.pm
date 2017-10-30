# --
# Copyright (C) 2016-2017 Inceptum ICT, http://inceptum.hr//
# --
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307, USA.
# --
# API for Metaswitch platform (RESTfull)
# Currently suported SOAP protocol on Metaswitch platfrom side
# --

package Metaswitch::REST;
# use OTRS perl classes
use lib '/opt/otrs';
use lib '/opt/otrs/Kernel/cpan-lib';
# use Umboss perl classes
use lib '/usr/local/umboss/lib';
use lib '/opt/otrs/Umboiss';
use warnings;
use strict;
use Encode qw(encode);
use List::Util qw(first);
# use libraries for SOAP request
use LWP::UserAgent;
use HTTP::Request;
use XML::Simple;
use JSON;
# OTRS Config and HTML Layout modules for creating XML SOAP requests
use Kernel::System::ObjectManager;
use Kernel::Config;
use Kernel::Output::HTML::Layout;
# REST request base object
use base qw/Apache2::REST::Handler/;
# exclude CGI warnings
$CGI::LIST_CONTEXT_WARN=0;
# Load object manager. Needed for OTRS Layout module.
$Kernel::OM = Kernel::System::ObjectManager->new();

=head1 NAME

Umboss::TorrusAPI - Torrus API

=head1 SYNOPSIS

All Torrus API functions.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item _Init()

Loading and initializing module parameters.

=cut

sub _Init {
	my ($self,$request) = @_;
	my $ConfigObject = new Kernel::Config();
	$self->{ConfigObject} = $ConfigObject;
	my $Home              = $ConfigObject->Get('MetaswitchRESTapiUmbossHome');
	$self->{TemplateDir}  = "$Home/templates/Metaswitch";
	$self->{LayoutObject}        = Kernel::Output::HTML::Layout->new();
	$self->{LayoutObject}->{CustomTemplateDir} = $self->{TemplateDir};
	$self->{EASon} = $request->param('EASon') || $self->{ConfigObject}->Get('MetaswitchRESTapiServiceEAS') || '';
	$self->{EASon} = "EAS" if $self->{EASon};
	
	return $self;
}

# Basic authentication configured in MetaswitchAuth.pm perl module
sub _Auth {
	my ($self, $request) = @_;
	
	my $AuthOn = $self->{ConfigObject}->Get('MetaswitchAuthOn') || 0;
	return 1 if !$AuthOn;
	
	my $username = $request->param('Username');
	my $token = $request->param('Token');
	my $password = $request->param('Password');
	
	if (! $username || ! $token) {
		$self->{AuthError} = "User has no access.";
		return 0;
	}
	
	my $Users = $self->{ConfigObject}->Get('MetaswitchAuth');
	if ($Users->{$username}) {
		if ($Users->{$username}->{token} eq $token) {
			return 1;
		} else {
			$self->{AuthError} = "Token is incorrect.";
			return 0;
		}
	} else {
		$self->{AuthError} = "User unknown.";
		return 0;
	}
	
	return $self;
}

# REST GET HTTP method.
# restclient -r "http://192.168.210.33/MetaswitchREST/" -m GET -p "UserIdentity=11010024&ServiceIndication=Meta_Subscriber_BaseInformation"
#
# JSON
#	{"UserIdentity":"11010024","ServiceIndication":"Meta_Subscriber_BaseInformation"}
#	restclient -r "http://192.168.210.33/MetaswitchREST/" -m GET -p "GetData=%7B%22UserIdentity%22%3A%2211010024%22%2C%22ServiceIndication%22%3A%22Meta_Subscriber_BaseInformation%22%7D"
#
#	{"UserIdentity":"11010024","ServiceIndication":["Meta_Subscriber_BaseInformation","Meta_Subscriber_BusyCallForwarding"]}
#	restclient -r "http://192.168.210.33/MetaswitchREST/" -m GET -p "GetData=%7B%22UserIdentity%22%3A%2211010024%22%2C%22ServiceIndication%22%3A%5B%22Meta_Subscriber_BaseInformation%22%2C%22Meta_Subscriber_BusyCallForwarding%22%5D%7D"
# Multiple object getting
# Only JSON
# [{"UserIdentity":"Metronet_Croatia_API_Test","ServiceIndication":"Meta_BusinessGroup_BaseInformation"},{"UserIdentity":"meribel/Metronet_Croatia_API_Test/11010020","ServiceIndication":"Meta_BGNumberBlock_BaseInformation"},{"UserIdentity":"11010024","ServiceIndication":["Meta_Subscriber_BaseInformation","Meta_Subscriber_BusyCallForwarding"]}]
# restclient -r "http://192.168.210.33/MetaswitchREST/" -m GET -p "GetData=%5B%7B%22UserIdentity%22%3A%22Metronet_Croatia_API_Test%22%2C%22ServiceIndication%22%3A%22Meta_BusinessGroup_BaseInformation%22%7D%2C%7B%22UserIdentity%22%3A%22meribel%2FMetronet_Croatia_API_Test%2F11010020%22%2C%22ServiceIndication%22%3A%22Meta_BGNumberBlock_BaseInformation%22%7D%2C%7B%22UserIdentity%22%3A%2211010024%22%2C%22ServiceIndication%22%3A%5B%22Meta_Subscriber_BaseInformation%22%2C%22Meta_Subscriber_BusyCallForwarding%22%5D%7D%5D"

sub GET{
    my ($self, $request, $response) = @_ ;
	$self->_Init($request);
	my $Home              = $self->{ConfigObject}->Get('MetaswitchRESTapiUmbossHome');
	my $UserIdentity = $request->param('UserIdentity');
	my $ServiceIndication = $request->param('ServiceIndication') || 'Meta_Subscriber_BaseInformation';
	my $OriginHost = $self->{ConfigObject}->Get('MetaswitchRESTapiOriginHost') || 'user@domain?clientVersion=7.3';
	my $JSONInput = $request->param('GetData');

	my @Data;
	
	if (! $self->_Auth($request)){
		$response->data()->{'MetaswitchAuthError'} = $self->{AuthError};
		return Apache2::Const::HTTP_OK ;
	}
	if ($JSONInput){
		#my $d = JSON->new->utf8;
		#my $data = $d->decode($JSONInput);
		my $data = $Kernel::OM->Get('Kernel::System::JSON')->Decode(Data => $JSONInput);
		my @Rows;
		if (ref ($data) eq "ARRAY"){
			push @Rows, @{$data};
		} else {
			push @Rows, $data;
		}
		for my $data (@Rows){
			$UserIdentity = $data->{UserIdentity};
			if (ref($data->{ServiceIndication}) eq "ARRAY"){
				for my $Tmp (@{$data->{ServiceIndication}}){
					push (@Data,{ServiceIndication=>$Tmp,UserIdentity=>$UserIdentity});
				}
			} else {
				push (@Data,{ServiceIndication=>$data->{ServiceIndication},UserIdentity=>$UserIdentity});
			}
		}
	} else {
		push (@Data,{UserIdentity=>$UserIdentity,ServiceIndication=>$ServiceIndication});
	}
	
	$request->requestedFormat($request->param('fmt') || $self->{ConfigObject}->Get('MetaswitchRESTapiWriter') || 'json') ;
	
	for my $Data (@Data){
		$UserIdentity = $Data->{UserIdentity};
		$ServiceIndication = $Data->{ServiceIndication};
		my $message = $self->{LayoutObject}->Output(
			TemplateFile => "GET",
			Data => {
				UserIdentity => $UserIdentity,
				ServiceIndication => $ServiceIndication,
				OriginHost => $OriginHost,
				EASon => $self->{EASon}
			}
		);
		
		$message=~s/\n//ig;
		$message=~s/\r//ig;
		$message=~s/\t//ig;
		#$response->data()->{'SOAPXML'} = $message;
		my $userAgent = LWP::UserAgent->new();
		my $requestLWP = HTTP::Request->new(POST => $self->{ConfigObject}->Get('MetaswitchRESTapiServiceURL' . $self->{EASon}));
		$requestLWP->header(
			%{ $self->{ConfigObject}->Get('MetaswitchRESTapiLWPrequestHeader'  . $self->{EASon}) }
		);

		$message = encode('UTF-8', $message);
		#$response->data()->{'URL'} = $self->{ConfigObject}->Get('MetaswitchRESTapiServiceURL' . $self->{EASon});
		#$response->data()->{'Header'} = $self->{ConfigObject}->Get('MetaswitchRESTapiLWPrequestHeader'  . $self->{EASon});
		$requestLWP->content($message);
		$requestLWP->content_type($self->{ConfigObject}->Get('MetaswitchRESTapiContentType') || "text/xml; charset=utf-8");
		
		my $responseLWP = $userAgent->request($requestLWP);
		if($responseLWP->code == 200) {
			my $XML = $responseLWP->decoded_content;
			$XML =~ s/\w+\://ig;
			my $xs = XML::Simple->new();
			my $ref = $xs->XMLin($XML);
			if ($ref->{"Body"}->{"ShPullResponse"}->{"ResultCode"} eq "2001") { 
				$response->data()->{$ServiceIndication} = 
					$ref->{"Body"}->{"ShPullResponse"}->{"UserData"}->{"Sh-Data"}->{"RepositoryData"}->{"ServiceData"}->{"MetaSwitchData"}->{$ServiceIndication}
					||
					$ref->{"Body"}->{"ShPullResponse"}->{"UserData"}->{"Sh-Data"}->{"RepositoryData"}->{"ServiceData"}->{"MetaSphereData"}->{$ServiceIndication};
				$response->data()->{'SequenceNumber'} = $ref->{"Body"}->{"ShPullResponse"}->{"UserData"}->{"Sh-Data"}->{"RepositoryData"}->{"SequenceNumber"};
				$response->data()->{'ResultCode'} = $ref->{"Body"}->{"ShPullResponse"}->{"ResultCode"};
			} else {
				$response->data()->{$ServiceIndication} = $ref->{"Body"}->{"ShPullResponse"};
			}
		} else {
			#print $response->error_as_HTML;
			#$response->data()->{$ServiceIndication} = $response->status_line;
			$response->data()->{$ServiceIndication} = ($responseLWP->status_line . " (" . $responseLWP->code . ")") || $responseLWP->error_as_HTML;		
		}
	}
    return Apache2::Const::HTTP_OK ;
}

### Test Method
sub GETinfoA{
    my ($self, $request, $response) = @_ ;
	return $self->GET($request, $response);
}

# REST POST HTTP method.
# restclient -r "http://192.168.210.33/MetaswitchREST/?ServiceIndication=Meta_Subscriber_BaseInformation&NetworkElementName=meribel&MetaSwitchName=meribel&BusinessGroupName=Metronet_Croatia_API_Test&SubscriberType=BusinessGroupLine&DirectoryNumber=11010024&PersistentProfile=ITG%20Default&NumberStatus=Normal&SignalingType=SIP&CallAgentSignalingType=SIP&UseDNForIdentification=True&SIPUserName=MetroNetTest01&SIPDomainName=10.221.0.21&SIPAuthenticationRequired=True&NewSIPPassword=Test00011&ConfirmNewSIPPassword=Test00011&Locale=English%20(US)&ChargeIndication.UseDefault=True&NetworkNode.UseDefault=False" -m POST -p ""
# restclient -r "http://192.168.210.33/MetaswitchREST/?ServiceIndication=Meta_Subscriber_BaseInformation&NetworkElementName=meribel&MetaSwitchName=meribel&BusinessGroupName=Metronet_Croatia_API_Test&SubscriberType=BusinessGroupLine&DirectoryNumber=11010024&PersistentProfile=ITG%20Default&NumberStatus=Normal&SignalingType=SIP&CallAgentSignalingType=SIP&UseDNForIdentification=True&SIPUserName=MetroNetTest01&SIPDomainName=10.221.0.21&SIPAuthenticationRequired=True&NewSIPPassword=Test00011&ConfirmNewSIPPassword=Test00011&Locale=English%20(US)&ChargeIndication.UseDefault=True&NetworkNode.UseDefault=False&RoutingAttributes.UseDefault=False&RoutingAttributes.Pre-paidOff-switchCallingCardSubscriber.Value=True" -m POST -p ""
#
# JSON
#
#{
#	"Meta_Subscriber_BaseInformation":{
#		"NetworkElementName":"meribel",
#		"MetaSwitchName":"meribel",
#		"BusinessGroupName":"Metronet_Croatia_API_Test",
#		"SubscriberType":"BusinessGroupLine",
#		"DirectoryNumber":"11010024",
#		"PersistentProfile":"ITG Default",
#		"NumberStatus":"Normal",
#		"SignalingType":"SIP",
#		"CallAgentSignalingType":"SIP",
#		"UseDNForIdentification":"True",
#		"SIPUserName":"MetroNetTest01",
#		"SIPDomainName":"10.221.0.21",
#		"SIPAuthenticationRequired":"True",
#		"NewSIPPassword":"Test00011",
#		"ConfirmNewSIPPassword":"Test00011",
#		"Locale":"English (US)",
#		"ChargeIndication":{"UseDefault":"True"},
#		"NetworkNode":{"UseDefault":"False"},
#		"RoutingAttributes":{
#			"UseDefault":"False",
#			"Pre-paidOff-switchCallingCardSubscriber":{"Value":"True"}
#		}
#	}
#}
#
# restclient -r "http://192.168.210.33/MetaswitchREST/?DirectoryNumber=11010024&ConfData=%7B%0D%0A%09%22Meta_Subscriber_BaseInformation%22%3A%7B%0D%0A%09%09%22NetworkElementName%22%3A%22meribel%22%2C%0D%0A%09%09%22MetaSwitchName%22%3A%22meribel%22%2C%0D%0A%09%09%22BusinessGroupName%22%3A%22Metronet_Croatia_API_Test%22%2C%0D%0A%09%09%22SubscriberType%22%3A%22BusinessGroupLine%22%2C%0D%0A%09%09%22DirectoryNumber%22%3A%2211010024%22%2C%0D%0A%09%09%22PersistentProfile%22%3A%22ITG+Default%22%2C%0D%0A%09%09%22NumberStatus%22%3A%22Normal%22%2C%0D%0A%09%09%22SignalingType%22%3A%22SIP%22%2C%0D%0A%09%09%22CallAgentSignalingType%22%3A%22SIP%22%2C%0D%0A%09%09%22UseDNForIdentification%22%3A%22True%22%2C%0D%0A%09%09%22SIPUserName%22%3A%22MetroNetTest01%22%2C%0D%0A%09%09%22SIPDomainName%22%3A%2210.221.0.21%22%2C%0D%0A%09%09%22SIPAuthenticationRequired%22%3A%22True%22%2C%0D%0A%09%09%22NewSIPPassword%22%3A%22Test00011%22%2C%0D%0A%09%09%22ConfirmNewSIPPassword%22%3A%22Test00011%22%2C%0D%0A%09%09%22Locale%22%3A%22English+%28US%29%22%2C%0D%0A%09%09%22ChargeIndication%22%3A%7B%22UseDefault%22%3A%22True%22%7D%2C%0D%0A%09%09%22NetworkNode%22%3A%7B%22UseDefault%22%3A%22False%22%7D%2C%0D%0A%09%09%22RoutingAttributes%22%3A%7B%0D%0A%09%09%09%22UseDefault%22%3A%22False%22%2C%0D%0A%09%09%09%22Pre-paidOff-switchCallingCardSubscriber%22%3A%7B%22Value%22%3A%22True%22%7D%0D%0A%09%09%7D%0D%0A%09%7D%0D%0A%7D" -m POST -p ""
#
#
#{
#	"Meta_Subscriber_BaseInformation":{
#		"NetworkElementName":"meribel",
#		"MetaSwitchName":"meribel",
#		"BusinessGroupName":"Metronet_Croatia_API_Test",
#		"SubscriberType":"BusinessGroupLine",
#		"DirectoryNumber":"11010024",
#		"PersistentProfile":"ITG Default",
#		"NumberStatus":"Normal",
#		"SignalingType":"SIP",
#		"CallAgentSignalingType":"SIP",
#		"UseDNForIdentification":"True",
#		"SIPUserName":"MetroNetTest01",
#		"SIPDomainName":"10.221.0.21",
#		"SIPAuthenticationRequired":"True",
#		"NewSIPPassword":"Test00011",
#		"ConfirmNewSIPPassword":"Test00011",
#		"Locale":"English (US)",
#		"ChargeIndication":{"UseDefault":"True"},
#		"NetworkNode":{"UseDefault":"False"},
#		"RoutingAttributes":{
#			"UseDefault":"False",
#			"Pre-paidOff-switchCallingCardSubscriber":{"Value":"True"}
#		}
#	},
#	"Meta_Subscriber_BusyCallForwarding":{
#		"Enabled":"False",
#		"Number":"38598222222"
#	}
#}
#
#restclient -r "http://192.168.210.33/MetaswitchREST/?DirectoryNumber=11010024&ConfData=%7B%0D%0A%09%22Meta_Subscriber_BaseInformation%22%3A%7B%0D%0A%09%09%22NetworkElementName%22%3A%22meribel%22%2C%0D%0A%09%09%22MetaSwitchName%22%3A%22meribel%22%2C%0D%0A%09%09%22BusinessGroupName%22%3A%22Metronet_Croatia_API_Test%22%2C%0D%0A%09%09%22SubscriberType%22%3A%22BusinessGroupLine%22%2C%0D%0A%09%09%22DirectoryNumber%22%3A%2211010024%22%2C%0D%0A%09%09%22PersistentProfile%22%3A%22ITG+Default%22%2C%0D%0A%09%09%22NumberStatus%22%3A%22Normal%22%2C%0D%0A%09%09%22SignalingType%22%3A%22SIP%22%2C%0D%0A%09%09%22CallAgentSignalingType%22%3A%22SIP%22%2C%0D%0A%09%09%22UseDNForIdentification%22%3A%22True%22%2C%0D%0A%09%09%22SIPUserName%22%3A%22MetroNetTest01%22%2C%0D%0A%09%09%22SIPDomainName%22%3A%2210.221.0.21%22%2C%0D%0A%09%09%22SIPAuthenticationRequired%22%3A%22True%22%2C%0D%0A%09%09%22NewSIPPassword%22%3A%22Test00011%22%2C%0D%0A%09%09%22ConfirmNewSIPPassword%22%3A%22Test00011%22%2C%0D%0A%09%09%22Locale%22%3A%22English+%28US%29%22%2C%0D%0A%09%09%22ChargeIndication%22%3A%7B%22UseDefault%22%3A%22True%22%7D%2C%0D%0A%09%09%22NetworkNode%22%3A%7B%22UseDefault%22%3A%22False%22%7D%2C%0D%0A%09%09%22RoutingAttributes%22%3A%7B%0D%0A%09%09%09%22UseDefault%22%3A%22False%22%2C%0D%0A%09%09%09%22Pre-paidOff-switchCallingCardSubscriber%22%3A%7B%22Value%22%3A%22True%22%7D%0D%0A%09%09%7D%0D%0A%09%7D%2C%0D%0A%09%22Meta_Subscriber_BusyCallForwarding%22%3A%7B%0D%0A%09%09%22Enabled%22%3A%22False%22%2C%0D%0A%09%09%22Number%22%3A%2238598222222%22%0D%0A%09%7D%0D%0A%7D" -m POST -p ""
# Provisioning Business group, Business group number range and provisioning one phone number
#
#{
#	"Meta_BusinessGroup_BaseInformation":{
#		"DirectoryNumber":"meribel/Metronet_Croatia_API_Test3",
#		"NetworkElementName":"meribel",
#		"MetaSwitchName":"meribel",
#		"BusinessGroupName":"Metronet_Croatia_API_Test3",
#		"DelegatedManagementGroup":"default",
#		"PersistentProfile":"ITG Default",
#		"SyncWithProfileInProgress":"False",
#		"LocalCNAMName":"Metronet",	
#		"Locale":"English (US)",
#		"SecondLocale":"None",
#		"BillingTypeIntercomCalls":"Local calls flat rate",
#		"NumberOfDirectoryNumbers":"10",
#		"RoutingAttributes":{
#			"UseDefault":"False",
#			"Pre-paidOff-switchCallingCardSubscriber":{"Value":"True"}
#		},
#		"SASHostname":"10.232.206.55"
#	},
#	"Meta_BGNumberBlock_BaseInformation":{
#		"DirectoryNumber":"meribel/Metronet_Croatia_API_Test3/11010040",
#		"NetworkElementName":"meribel",
#		"MetaSwitchName":"meribel",
#		"BusinessGroupName":"Metronet_Croatia_API_Test3",
#		"DeviceTwinning":"None",
#		"BlockSize":"10",
#		"FirstDirectoryNumber":"11010040",
#		"LastDirectoryNumber":"11010049",
#		"SubscriberGroup":"Meribel subscribers"
#	},
#	"Meta_Subscriber_BaseInformation":{
#		"DirectoryNumber":"11010041",
#		"NetworkElementName":"meribel",
#		"MetaSwitchName":"meribel",
#		"BusinessGroupName":"Metronet_Croatia_API_Test3",
#		"SubscriberType":"BusinessGroupLine",
#		"DirectoryNumber":"11010041",
#		"PersistentProfile":"ITG Default",
#		"NumberStatus":"Normal",
#		"SignalingType":"SIP",
#		"CallAgentSignalingType":"SIP",
#		"UseDNForIdentification":"True",
#		"SIPUserName":"MetroNetTest01",
#		"SIPDomainName":"10.221.0.21",
#		"SIPAuthenticationRequired":"True",
#		"NewSIPPassword":"Test00011",
#		"ConfirmNewSIPPassword":"Test00011",
#		"Locale":"English (US)",
#		"ChargeIndication":{"UseDefault":"True"},
#		"NetworkNode":{"UseDefault":"False"},
#		"RoutingAttributes":{
#			"UseDefault":"False",
#			"Pre-paidOff-switchCallingCardSubscriber":{"Value":"True"}
#		}
#	},
#	"Meta_Subscriber_BusyCallForwarding":{
#		"DirectoryNumber":"11010041",
#		"Enabled":"False",
#		"Number":"38598223333"
#	}
#}

#restclient -r "http://192.168.210.33/MetaswitchREST/?ConfData=%7B%0D%0A%09%22Meta_BusinessGroup_BaseInformation%22%3A%7B%0D%0A%09%09%22DirectoryNumber%22%3A%22meribel%2FMetronet_Croatia_API_Test3%22%2C%0D%0A%09%09%22NetworkElementName%22%3A%22meribel%22%2C%0D%0A%09%09%22MetaSwitchName%22%3A%22meribel%22%2C%0D%0A%09%09%22BusinessGroupName%22%3A%22Metronet_Croatia_API_Test3%22%2C%0D%0A%09%09%22DelegatedManagementGroup%22%3A%22default%22%2C%0D%0A%09%09%22PersistentProfile%22%3A%22ITG+Default%22%2C%0D%0A%09%09%22SyncWithProfileInProgress%22%3A%22False%22%2C%0D%0A%09%09%22LocalCNAMName%22%3A%22Metronet%22%2C%09%0D%0A%09%09%22Locale%22%3A%22English+%28US%29%22%2C%0D%0A%09%09%22SecondLocale%22%3A%22None%22%2C%0D%0A%09%09%22BillingTypeIntercomCalls%22%3A%22Local+calls+flat+rate%22%2C%0D%0A%09%09%22NumberOfDirectoryNumbers%22%3A%2210%22%2C%0D%0A%09%09%22RoutingAttributes%22%3A%7B%0D%0A%09%09%09%22UseDefault%22%3A%22False%22%2C%0D%0A%09%09%09%22Pre-paidOff-switchCallingCardSubscriber%22%3A%7B%22Value%22%3A%22True%22%7D%0D%0A%09%09%7D%2C%0D%0A%09%09%22SASHostname%22%3A%2210.232.206.55%22%0D%0A%09%7D%2C%0D%0A%09%22Meta_BGNumberBlock_BaseInformation%22%3A%7B%0D%0A%09%09%22DirectoryNumber%22%3A%22meribel%2FMetronet_Croatia_API_Test3%2F11010040%22%2C%0D%0A%09%09%22NetworkElementName%22%3A%22meribel%22%2C%0D%0A%09%09%22MetaSwitchName%22%3A%22meribel%22%2C%0D%0A%09%09%22BusinessGroupName%22%3A%22Metronet_Croatia_API_Test3%22%2C%0D%0A%09%09%22DeviceTwinning%22%3A%22None%22%2C%0D%0A%09%09%22BlockSize%22%3A%2210%22%2C%0D%0A%09%09%22FirstDirectoryNumber%22%3A%2211010040%22%2C%0D%0A%09%09%22LastDirectoryNumber%22%3A%2211010049%22%2C%0D%0A%09%09%22SubscriberGroup%22%3A%22Meribel+subscribers%22%0D%0A%09%7D%2C%0D%0A%09%22Meta_Subscriber_BaseInformation%22%3A%7B%0D%0A%09%09%22DirectoryNumber%22%3A%2211010041%22%2C%0D%0A%09%09%22NetworkElementName%22%3A%22meribel%22%2C%0D%0A%09%09%22MetaSwitchName%22%3A%22meribel%22%2C%0D%0A%09%09%22BusinessGroupName%22%3A%22Metronet_Croatia_API_Test3%22%2C%0D%0A%09%09%22SubscriberType%22%3A%22BusinessGroupLine%22%2C%0D%0A%09%09%22DirectoryNumber%22%3A%2211010041%22%2C%0D%0A%09%09%22PersistentProfile%22%3A%22ITG+Default%22%2C%0D%0A%09%09%22NumberStatus%22%3A%22Normal%22%2C%0D%0A%09%09%22SignalingType%22%3A%22SIP%22%2C%0D%0A%09%09%22CallAgentSignalingType%22%3A%22SIP%22%2C%0D%0A%09%09%22UseDNForIdentification%22%3A%22True%22%2C%0D%0A%09%09%22SIPUserName%22%3A%22MetroNetTest01%22%2C%0D%0A%09%09%22SIPDomainName%22%3A%2210.221.0.21%22%2C%0D%0A%09%09%22SIPAuthenticationRequired%22%3A%22True%22%2C%0D%0A%09%09%22NewSIPPassword%22%3A%22Test00011%22%2C%0D%0A%09%09%22ConfirmNewSIPPassword%22%3A%22Test00011%22%2C%0D%0A%09%09%22Locale%22%3A%22English+%28US%29%22%2C%0D%0A%09%09%22ChargeIndication%22%3A%7B%22UseDefault%22%3A%22True%22%7D%2C%0D%0A%09%09%22NetworkNode%22%3A%7B%22UseDefault%22%3A%22False%22%7D%2C%0D%0A%09%09%22RoutingAttributes%22%3A%7B%0D%0A%09%09%09%22UseDefault%22%3A%22False%22%2C%0D%0A%09%09%09%22Pre-paidOff-switchCallingCardSubscriber%22%3A%7B%22Value%22%3A%22True%22%7D%0D%0A%09%09%7D%0D%0A%09%7D%2C%0D%0A%09%22Meta_Subscriber_BusyCallForwarding%22%3A%7B%0D%0A%09%09%22DirectoryNumber%22%3A%2211010041%22%2C%0D%0A%09%09%22Enabled%22%3A%22False%22%2C%0D%0A%09%09%22Number%22%3A%2238598223333%22%0D%0A%09%7D%0D%0A%7D" -m POST -p ""
# Long POST url, JSON very long with activation 5 phones in business group
#
#{
#	"Meta_BusinessGroup_BaseInformation":{
#		"DirectoryNumber":"meribel/Metronet_Croatia_API_Test4",
#		"NetworkElementName":"meribel",
#		"MetaSwitchName":"meribel",
#		"BusinessGroupName":"Metronet_Croatia_API_Test4",
#		"DelegatedManagementGroup":"default",
#		"PersistentProfile":"ITG Default",
#		"SyncWithProfileInProgress":"False",
#		"LocalCNAMName":"Metronet",	
#		"Locale":"English (US)",
#		"SecondLocale":"None",
#		"BillingTypeIntercomCalls":"Local calls flat rate",
#		"NumberOfDirectoryNumbers":"10",
#		"RoutingAttributes":{
#			"UseDefault":"False",
#			"Pre-paidOff-switchCallingCardSubscriber":{"Value":"True"}
#		},
#		"SASHostname":"10.232.206.55"
#	},
#	"Meta_BGNumberBlock_BaseInformation":{
#		"DirectoryNumber":"meribel/Metronet_Croatia_API_Test4/11010050",
#		"NetworkElementName":"meribel",
#		"MetaSwitchName":"meribel",
#		"BusinessGroupName":"Metronet_Croatia_API_Test4",
#		"DeviceTwinning":"None",
#		"BlockSize":"10",
#		"FirstDirectoryNumber":"11010050",
#		"LastDirectoryNumber":"11010059",
#		"SubscriberGroup":"Meribel subscribers"
#	},
#	"Meta_Subscriber_BaseInformation":[
#		{
#			"DirectoryNumber":"11010051",
#			"NetworkElementName":"meribel",
#			"MetaSwitchName":"meribel",
#			"BusinessGroupName":"Metronet_Croatia_API_Test4",
#			"SubscriberType":"BusinessGroupLine",
#			"DirectoryNumber":"11010051",
#			"PersistentProfile":"ITG Default",
#			"NumberStatus":"Normal",
#			"SignalingType":"SIP",
#			"CallAgentSignalingType":"SIP",
#			"UseDNForIdentification":"True",
#			"SIPUserName":"MetroNetTest01",
#			"SIPDomainName":"10.221.0.21",
#			"SIPAuthenticationRequired":"True",
#			"NewSIPPassword":"Test000234",
#			"ConfirmNewSIPPassword":"Test000234",
#			"Locale":"English (US)",
#			"ChargeIndication":{"UseDefault":"True"},
#			"NetworkNode":{"UseDefault":"False"},
#			"RoutingAttributes":{
#				"UseDefault":"False",
#				"Pre-paidOff-switchCallingCardSubscriber":{"Value":"True"}
#			}
#		},
#		{
#			"DirectoryNumber":"11010052",
#			"NetworkElementName":"meribel",
#			"MetaSwitchName":"meribel",
#			"BusinessGroupName":"Metronet_Croatia_API_Test4",
#			"SubscriberType":"BusinessGroupLine",
#			"DirectoryNumber":"11010052",
#			"PersistentProfile":"ITG Default",
#			"NumberStatus":"Normal",
#			"SignalingType":"SIP",
#			"CallAgentSignalingType":"SIP",
#			"UseDNForIdentification":"True",
#			"SIPUserName":"MetroNetTest01",
#			"SIPDomainName":"10.221.0.21",
#			"SIPAuthenticationRequired":"True",
#			"NewSIPPassword":"Test00022",
#			"ConfirmNewSIPPassword":"Test00022",
#			"Locale":"English (US)",
#			"ChargeIndication":{"UseDefault":"True"},
#			"NetworkNode":{"UseDefault":"False"},
#			"RoutingAttributes":{
#				"UseDefault":"False",
#				"Pre-paidOff-switchCallingCardSubscriber":{"Value":"True"}
#			}
#		},
#		{
#			"DirectoryNumber":"11010053",
#			"NetworkElementName":"meribel",
#			"MetaSwitchName":"meribel",
#			"BusinessGroupName":"Metronet_Croatia_API_Test4",
#			"SubscriberType":"BusinessGroupLine",
#			"DirectoryNumber":"11010053",
#			"PersistentProfile":"ITG Default",
#			"NumberStatus":"Normal",
#			"SignalingType":"SIP",
#			"CallAgentSignalingType":"SIP",
#			"UseDNForIdentification":"True",
#			"SIPUserName":"MetroNetTest01",
#			"SIPDomainName":"10.221.0.21",
#			"SIPAuthenticationRequired":"True",
#			"NewSIPPassword":"Test00023",
#			"ConfirmNewSIPPassword":"Test00023",
#			"Locale":"English (US)",
#			"ChargeIndication":{"UseDefault":"True"},
#			"NetworkNode":{"UseDefault":"False"},
#			"RoutingAttributes":{
#				"UseDefault":"False",
#				"Pre-paidOff-switchCallingCardSubscriber":{"Value":"True"}
#			}
#		},
#		{
#			"DirectoryNumber":"11010054",
#			"NetworkElementName":"meribel",
#			"MetaSwitchName":"meribel",
#			"BusinessGroupName":"Metronet_Croatia_API_Test4",
#			"SubscriberType":"BusinessGroupLine",
#			"DirectoryNumber":"11010054",
#			"PersistentProfile":"ITG Default",
#			"NumberStatus":"Normal",
#			"SignalingType":"SIP",
#			"CallAgentSignalingType":"SIP",
#			"UseDNForIdentification":"True",
#			"SIPUserName":"MetroNetTest01",
#			"SIPDomainName":"10.221.0.21",
#			"SIPAuthenticationRequired":"True",
#			"NewSIPPassword":"Test00029",
#			"ConfirmNewSIPPassword":"Test00029",
#			"Locale":"English (US)",
#			"ChargeIndication":{"UseDefault":"True"},
#			"NetworkNode":{"UseDefault":"False"},
#			"RoutingAttributes":{
#				"UseDefault":"False",
#				"Pre-paidOff-switchCallingCardSubscriber":{"Value":"True"}
#			}
#		},
#		{
#			"DirectoryNumber":"11010055",
#			"NetworkElementName":"meribel",
#			"MetaSwitchName":"meribel",
#			"BusinessGroupName":"Metronet_Croatia_API_Test4",
#			"SubscriberType":"BusinessGroupLine",
#			"DirectoryNumber":"11010055",
#			"PersistentProfile":"ITG Default",
#			"NumberStatus":"Normal",
#			"SignalingType":"SIP",
#			"CallAgentSignalingType":"SIP",
#			"UseDNForIdentification":"True",
#			"SIPUserName":"MetroNetTest01",
#			"SIPDomainName":"10.221.0.21",
#			"SIPAuthenticationRequired":"True",
#			"NewSIPPassword":"Test00020",
#			"ConfirmNewSIPPassword":"Test00020",
#			"Locale":"English (US)",
#			"ChargeIndication":{"UseDefault":"True"},
#			"NetworkNode":{"UseDefault":"False"},
#			"RoutingAttributes":{
#				"UseDefault":"False",
#				"Pre-paidOff-switchCallingCardSubscriber":{"Value":"True"}
#			}
#		}
#	],
#	"Meta_Subscriber_BusyCallForwarding": [
#		{
#			"DirectoryNumber":"11010051",
#			"Enabled":"False",
#			"Number":"3859822444"
#		},
#		{
#			"DirectoryNumber":"11010052",
#			"Enabled":"False",
#			"Number":"38598225555"
#		},
#		{
#			"DirectoryNumber":"11010053",
#			"Enabled":"False",
#			"Number":"38598225557"
#		},
#		{
#			"DirectoryNumber":"11010054",
#			"Enabled":"False",
#			"Number":"38598225558"
#		},
#		{
#			"DirectoryNumber":"11010055",
#			"Enabled":"False",
#			"Number":"38598225559"
#		}
#	]
#}
#
#curl "http://192.168.210.33/MetaswitchREST/" -k -d "ConfData=%7B%0D%0A%09%22Meta_BusinessGroup_BaseInformation%22%3A%7B%0D%0A%09%09%22DirectoryNumber%22%3A%22meribel%2FMetronet_Croatia_API_Test4%22%2C%0D%0A%09%09%22NetworkElementName%22%3A%22meribel%22%2C%0D%0A%09%09%22MetaSwitchName%22%3A%22meribel%22%2C%0D%0A%09%09%22BusinessGroupName%22%3A%22Metronet_Croatia_API_Test4%22%2C%0D%0A%09%09%22DelegatedManagementGroup%22%3A%22default%22%2C%0D%0A%09%09%22PersistentProfile%22%3A%22ITG+Default%22%2C%0D%0A%09%09%22SyncWithProfileInProgress%22%3A%22False%22%2C%0D%0A%09%09%22LocalCNAMName%22%3A%22Metronet%22%2C%09%0D%0A%09%09%22Locale%22%3A%22English+%28US%29%22%2C%0D%0A%09%09%22SecondLocale%22%3A%22None%22%2C%0D%0A%09%09%22BillingTypeIntercomCalls%22%3A%22Local+calls+flat+rate%22%2C%0D%0A%09%09%22NumberOfDirectoryNumbers%22%3A%2210%22%2C%0D%0A%09%09%22RoutingAttributes%22%3A%7B%0D%0A%09%09%09%22UseDefault%22%3A%22False%22%2C%0D%0A%09%09%09%22Pre-paidOff-switchCallingCardSubscriber%22%3A%7B%22Value%22%3A%22True%22%7D%0D%0A%09%09%7D%2C%0D%0A%09%09%22SASHostname%22%3A%2210.232.206.55%22%0D%0A%09%7D%2C%0D%0A%09%22Meta_BGNumberBlock_BaseInformation%22%3A%7B%0D%0A%09%09%22DirectoryNumber%22%3A%22meribel%2FMetronet_Croatia_API_Test4%2F11010050%22%2C%0D%0A%09%09%22NetworkElementName%22%3A%22meribel%22%2C%0D%0A%09%09%22MetaSwitchName%22%3A%22meribel%22%2C%0D%0A%09%09%22BusinessGroupName%22%3A%22Metronet_Croatia_API_Test4%22%2C%0D%0A%09%09%22DeviceTwinning%22%3A%22None%22%2C%0D%0A%09%09%22BlockSize%22%3A%2210%22%2C%0D%0A%09%09%22FirstDirectoryNumber%22%3A%2211010050%22%2C%0D%0A%09%09%22LastDirectoryNumber%22%3A%2211010059%22%2C%0D%0A%09%09%22SubscriberGroup%22%3A%22Meribel+subscribers%22%0D%0A%09%7D%2C%0D%0A%09%22Meta_Subscriber_BaseInformation%22%3A%5B%0D%0A%09%09%7B%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010051%22%2C%0D%0A%09%09%09%22NetworkElementName%22%3A%22meribel%22%2C%0D%0A%09%09%09%22MetaSwitchName%22%3A%22meribel%22%2C%0D%0A%09%09%09%22BusinessGroupName%22%3A%22Metronet_Croatia_API_Test4%22%2C%0D%0A%09%09%09%22SubscriberType%22%3A%22BusinessGroupLine%22%2C%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010051%22%2C%0D%0A%09%09%09%22PersistentProfile%22%3A%22ITG+Default%22%2C%0D%0A%09%09%09%22NumberStatus%22%3A%22Normal%22%2C%0D%0A%09%09%09%22SignalingType%22%3A%22SIP%22%2C%0D%0A%09%09%09%22CallAgentSignalingType%22%3A%22SIP%22%2C%0D%0A%09%09%09%22UseDNForIdentification%22%3A%22True%22%2C%0D%0A%09%09%09%22SIPUserName%22%3A%22MetroNetTest01%22%2C%0D%0A%09%09%09%22SIPDomainName%22%3A%2210.221.0.21%22%2C%0D%0A%09%09%09%22SIPAuthenticationRequired%22%3A%22True%22%2C%0D%0A%09%09%09%22NewSIPPassword%22%3A%22Test000234%22%2C%0D%0A%09%09%09%22ConfirmNewSIPPassword%22%3A%22Test000234%22%2C%0D%0A%09%09%09%22Locale%22%3A%22English+%28US%29%22%2C%0D%0A%09%09%09%22ChargeIndication%22%3A%7B%22UseDefault%22%3A%22True%22%7D%2C%0D%0A%09%09%09%22NetworkNode%22%3A%7B%22UseDefault%22%3A%22False%22%7D%2C%0D%0A%09%09%09%22RoutingAttributes%22%3A%7B%0D%0A%09%09%09%09%22UseDefault%22%3A%22False%22%2C%0D%0A%09%09%09%09%22Pre-paidOff-switchCallingCardSubscriber%22%3A%7B%22Value%22%3A%22True%22%7D%0D%0A%09%09%09%7D%0D%0A%09%09%7D%2C%0D%0A%09%09%7B%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010052%22%2C%0D%0A%09%09%09%22NetworkElementName%22%3A%22meribel%22%2C%0D%0A%09%09%09%22MetaSwitchName%22%3A%22meribel%22%2C%0D%0A%09%09%09%22BusinessGroupName%22%3A%22Metronet_Croatia_API_Test4%22%2C%0D%0A%09%09%09%22SubscriberType%22%3A%22BusinessGroupLine%22%2C%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010052%22%2C%0D%0A%09%09%09%22PersistentProfile%22%3A%22ITG+Default%22%2C%0D%0A%09%09%09%22NumberStatus%22%3A%22Normal%22%2C%0D%0A%09%09%09%22SignalingType%22%3A%22SIP%22%2C%0D%0A%09%09%09%22CallAgentSignalingType%22%3A%22SIP%22%2C%0D%0A%09%09%09%22UseDNForIdentification%22%3A%22True%22%2C%0D%0A%09%09%09%22SIPUserName%22%3A%22MetroNetTest01%22%2C%0D%0A%09%09%09%22SIPDomainName%22%3A%2210.221.0.21%22%2C%0D%0A%09%09%09%22SIPAuthenticationRequired%22%3A%22True%22%2C%0D%0A%09%09%09%22NewSIPPassword%22%3A%22Test00022%22%2C%0D%0A%09%09%09%22ConfirmNewSIPPassword%22%3A%22Test00022%22%2C%0D%0A%09%09%09%22Locale%22%3A%22English+%28US%29%22%2C%0D%0A%09%09%09%22ChargeIndication%22%3A%7B%22UseDefault%22%3A%22True%22%7D%2C%0D%0A%09%09%09%22NetworkNode%22%3A%7B%22UseDefault%22%3A%22False%22%7D%2C%0D%0A%09%09%09%22RoutingAttributes%22%3A%7B%0D%0A%09%09%09%09%22UseDefault%22%3A%22False%22%2C%0D%0A%09%09%09%09%22Pre-paidOff-switchCallingCardSubscriber%22%3A%7B%22Value%22%3A%22True%22%7D%0D%0A%09%09%09%7D%0D%0A%09%09%7D%2C%0D%0A%09%09%7B%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010053%22%2C%0D%0A%09%09%09%22NetworkElementName%22%3A%22meribel%22%2C%0D%0A%09%09%09%22MetaSwitchName%22%3A%22meribel%22%2C%0D%0A%09%09%09%22BusinessGroupName%22%3A%22Metronet_Croatia_API_Test4%22%2C%0D%0A%09%09%09%22SubscriberType%22%3A%22BusinessGroupLine%22%2C%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010053%22%2C%0D%0A%09%09%09%22PersistentProfile%22%3A%22ITG+Default%22%2C%0D%0A%09%09%09%22NumberStatus%22%3A%22Normal%22%2C%0D%0A%09%09%09%22SignalingType%22%3A%22SIP%22%2C%0D%0A%09%09%09%22CallAgentSignalingType%22%3A%22SIP%22%2C%0D%0A%09%09%09%22UseDNForIdentification%22%3A%22True%22%2C%0D%0A%09%09%09%22SIPUserName%22%3A%22MetroNetTest01%22%2C%0D%0A%09%09%09%22SIPDomainName%22%3A%2210.221.0.21%22%2C%0D%0A%09%09%09%22SIPAuthenticationRequired%22%3A%22True%22%2C%0D%0A%09%09%09%22NewSIPPassword%22%3A%22Test00023%22%2C%0D%0A%09%09%09%22ConfirmNewSIPPassword%22%3A%22Test00023%22%2C%0D%0A%09%09%09%22Locale%22%3A%22English+%28US%29%22%2C%0D%0A%09%09%09%22ChargeIndication%22%3A%7B%22UseDefault%22%3A%22True%22%7D%2C%0D%0A%09%09%09%22NetworkNode%22%3A%7B%22UseDefault%22%3A%22False%22%7D%2C%0D%0A%09%09%09%22RoutingAttributes%22%3A%7B%0D%0A%09%09%09%09%22UseDefault%22%3A%22False%22%2C%0D%0A%09%09%09%09%22Pre-paidOff-switchCallingCardSubscriber%22%3A%7B%22Value%22%3A%22True%22%7D%0D%0A%09%09%09%7D%0D%0A%09%09%7D%2C%0D%0A%09%09%7B%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010054%22%2C%0D%0A%09%09%09%22NetworkElementName%22%3A%22meribel%22%2C%0D%0A%09%09%09%22MetaSwitchName%22%3A%22meribel%22%2C%0D%0A%09%09%09%22BusinessGroupName%22%3A%22Metronet_Croatia_API_Test4%22%2C%0D%0A%09%09%09%22SubscriberType%22%3A%22BusinessGroupLine%22%2C%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010054%22%2C%0D%0A%09%09%09%22PersistentProfile%22%3A%22ITG+Default%22%2C%0D%0A%09%09%09%22NumberStatus%22%3A%22Normal%22%2C%0D%0A%09%09%09%22SignalingType%22%3A%22SIP%22%2C%0D%0A%09%09%09%22CallAgentSignalingType%22%3A%22SIP%22%2C%0D%0A%09%09%09%22UseDNForIdentification%22%3A%22True%22%2C%0D%0A%09%09%09%22SIPUserName%22%3A%22MetroNetTest01%22%2C%0D%0A%09%09%09%22SIPDomainName%22%3A%2210.221.0.21%22%2C%0D%0A%09%09%09%22SIPAuthenticationRequired%22%3A%22True%22%2C%0D%0A%09%09%09%22NewSIPPassword%22%3A%22Test00029%22%2C%0D%0A%09%09%09%22ConfirmNewSIPPassword%22%3A%22Test00029%22%2C%0D%0A%09%09%09%22Locale%22%3A%22English+%28US%29%22%2C%0D%0A%09%09%09%22ChargeIndication%22%3A%7B%22UseDefault%22%3A%22True%22%7D%2C%0D%0A%09%09%09%22NetworkNode%22%3A%7B%22UseDefault%22%3A%22False%22%7D%2C%0D%0A%09%09%09%22RoutingAttributes%22%3A%7B%0D%0A%09%09%09%09%22UseDefault%22%3A%22False%22%2C%0D%0A%09%09%09%09%22Pre-paidOff-switchCallingCardSubscriber%22%3A%7B%22Value%22%3A%22True%22%7D%0D%0A%09%09%09%7D%0D%0A%09%09%7D%2C%0D%0A%09%09%7B%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010055%22%2C%0D%0A%09%09%09%22NetworkElementName%22%3A%22meribel%22%2C%0D%0A%09%09%09%22MetaSwitchName%22%3A%22meribel%22%2C%0D%0A%09%09%09%22BusinessGroupName%22%3A%22Metronet_Croatia_API_Test4%22%2C%0D%0A%09%09%09%22SubscriberType%22%3A%22BusinessGroupLine%22%2C%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010055%22%2C%0D%0A%09%09%09%22PersistentProfile%22%3A%22ITG+Default%22%2C%0D%0A%09%09%09%22NumberStatus%22%3A%22Normal%22%2C%0D%0A%09%09%09%22SignalingType%22%3A%22SIP%22%2C%0D%0A%09%09%09%22CallAgentSignalingType%22%3A%22SIP%22%2C%0D%0A%09%09%09%22UseDNForIdentification%22%3A%22True%22%2C%0D%0A%09%09%09%22SIPUserName%22%3A%22MetroNetTest01%22%2C%0D%0A%09%09%09%22SIPDomainName%22%3A%2210.221.0.21%22%2C%0D%0A%09%09%09%22SIPAuthenticationRequired%22%3A%22True%22%2C%0D%0A%09%09%09%22NewSIPPassword%22%3A%22Test00020%22%2C%0D%0A%09%09%09%22ConfirmNewSIPPassword%22%3A%22Test00020%22%2C%0D%0A%09%09%09%22Locale%22%3A%22English+%28US%29%22%2C%0D%0A%09%09%09%22ChargeIndication%22%3A%7B%22UseDefault%22%3A%22True%22%7D%2C%0D%0A%09%09%09%22NetworkNode%22%3A%7B%22UseDefault%22%3A%22False%22%7D%2C%0D%0A%09%09%09%22RoutingAttributes%22%3A%7B%0D%0A%09%09%09%09%22UseDefault%22%3A%22False%22%2C%0D%0A%09%09%09%09%22Pre-paidOff-switchCallingCardSubscriber%22%3A%7B%22Value%22%3A%22True%22%7D%0D%0A%09%09%09%7D%0D%0A%09%09%7D%0D%0A%09%5D%2C%0D%0A%09%22Meta_Subscriber_BusyCallForwarding%22%3A+%5B%0D%0A%09%09%7B%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010051%22%2C%0D%0A%09%09%09%22Enabled%22%3A%22False%22%2C%0D%0A%09%09%09%22Number%22%3A%223859822444%22%0D%0A%09%09%7D%2C%0D%0A%09%09%7B%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010052%22%2C%0D%0A%09%09%09%22Enabled%22%3A%22False%22%2C%0D%0A%09%09%09%22Number%22%3A%2238598225555%22%0D%0A%09%09%7D%2C%0D%0A%09%09%7B%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010053%22%2C%0D%0A%09%09%09%22Enabled%22%3A%22False%22%2C%0D%0A%09%09%09%22Number%22%3A%2238598225557%22%0D%0A%09%09%7D%2C%0D%0A%09%09%7B%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010054%22%2C%0D%0A%09%09%09%22Enabled%22%3A%22False%22%2C%0D%0A%09%09%09%22Number%22%3A%2238598225558%22%0D%0A%09%09%7D%2C%0D%0A%09%09%7B%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010055%22%2C%0D%0A%09%09%09%22Enabled%22%3A%22False%22%2C%0D%0A%09%09%09%22Number%22%3A%2238598225559%22%0D%0A%09%09%7D%0D%0A%09%5D%0D%0A%7D"


sub POST{
    my ($self, $request, $response) = @_ ;
		
	$self->_Init($request);
	## Overide POST method with PUT method
	if ($self->{ConfigObject}->Get('MetaswitchRESTapiPOSTlikePUT')){
		return $self->PUT($request, $response);
	}
	my $Home              = $self->{ConfigObject}->Get('MetaswitchRESTapiUmbossHome');
	my $DirectoryNumber = $request->param('DirectoryNumber');
	my $ServiceIndication = $request->param('ServiceIndication') || 'Meta_Subscriber_BaseInformation';
	my $OriginHost = $self->{ConfigObject}->Get('MetaswitchRESTapiOriginHost') || 'user@domain?clientVersion=7.3';
	my @OrderConfParam = @{$self->{ConfigObject}->Get('MetaswitchRESTapiParamConfOrder')};
	
	my @ConfigData;
	my $SequenceNumber=0;

	if (! $self->_Auth($request)){
		$response->data()->{'MetaswitchAuthError'} = $self->{AuthError};
		return Apache2::Const::HTTP_OK ;
	}
	
	$request->requestedFormat($request->param('fmt') || $self->{ConfigObject}->Get('MetaswitchRESTapiWriter') || 'json') ;
	
	
	my $JSONInput = $request->param('ConfData');
		
	if ($JSONInput){
		#my $d = JSON->new->utf8;
		#my $data = $d->decode($JSONInput);
		my $data = $Kernel::OM->Get('Kernel::System::JSON')->Decode(Data => $JSONInput);
		for $ServiceIndication (@OrderConfParam){
			if (!$data->{$ServiceIndication}){
				next;
			}
			my @ServiceIndications;
			if (ref ($data->{$ServiceIndication}) eq "ARRAY") {
				push (@ServiceIndications, @{$data->{$ServiceIndication}});
			} else {
				push (@ServiceIndications, $data->{$ServiceIndication});
			}
			for my $data (@ServiceIndications){
				if ($data->{DirectoryNumber}){
					$DirectoryNumber = $data->{DirectoryNumber};
				}
				if ($data->{UserIdentity}){
					$DirectoryNumber = $data->{UserIdentity};
				}
				my @Keys = @{$self->{ConfigObject}->Get('MetaswitchRESTapiPOSTfields')->{$ServiceIndication}};
				my @InputParams;
				my %Param = $self->_AddParam($data);
				push (@InputParams, keys %Param);
				push (@ConfigData, {
					DirectoryNumber => $DirectoryNumber,
					ServiceIndication => $ServiceIndication,
					Keys => \@Keys,
					InputParams => \@InputParams,
					Param => \%Param
				});
			}
		}
		
		#$response->data()->{'Data'} = $data ;
		#return Apache2::Const::HTTP_OK ;
	} else {
		my @Keys = @{$self->{ConfigObject}->Get('MetaswitchRESTapiPOSTfields')->{$ServiceIndication}};
		my @InputParams = $request->param();
		my %Param;
		for my $Item (@InputParams) {
			if ($request->param($Item)){
				$Param{$Item} = $request->param($Item);
			}
		}
		push (@ConfigData, {
			ServiceIndication => $ServiceIndication,
			Keys => \@Keys,
			InputParams => \@InputParams,
			Param => \%Param
		});
	}
	
	for my $Conf (@ConfigData){
		my @Keys = @{$Conf->{Keys}};
		my @InputParams = @{$Conf->{InputParams}};
		my %Param = %{$Conf->{Param}};
		$ServiceIndication = $Conf->{ServiceIndication};
		
		if ($Conf->{DirectoryNumber}){
			$DirectoryNumber = $Conf->{DirectoryNumber};
		}
	
		if (
			first { /pattern/ } @{ $self->{ConfigObject}->Get('MetaswitchRESTapiPOSTuniqueMethods') }
		){
		# GET SequenceNumber	
			
			my $messageGET = $self->{LayoutObject}->Output(
				TemplateFile => "GET",
				Data => {
					UserIdentity => $DirectoryNumber,
					ServiceIndication => $ServiceIndication,
					OriginHost => $OriginHost,
					EASon => $self->{EASon},
				}
			);
			my $userAgentGET = LWP::UserAgent->new();
			my $requestLWPGET = HTTP::Request->new(POST => $self->{ConfigObject}->Get('MetaswitchRESTapiServiceURL' . $self->{EASon}));
			$requestLWPGET->header(
				%{ $self->{ConfigObject}->Get('MetaswitchRESTapiLWPrequestHeader' . $self->{EASon}) }
			);
			$messageGET = encode('UTF-8', $messageGET);
			$requestLWPGET->content($messageGET);
			$requestLWPGET->content_type($self->{ConfigObject}->Get('MetaswitchRESTapiContentType') || "text/xml; charset=utf-8");
			
			my $responseLWPGET = $userAgentGET->request($requestLWPGET);
			if($responseLWPGET->code == 200) {
				#$response->data()->{'MetaswitchAPI'} = $responseLWP->decoded_content;
				my $XML = $responseLWPGET->decoded_content;
				$XML =~ s/\w+\://ig;
				my $xs = XML::Simple->new();
				my $ref = $xs->XMLin($XML);
				if ($ref->{"Body"}->{"ShPullResponse"}->{"ResultCode"} eq "2001") { 
					$SequenceNumber = $ref->{"Body"}->{"ShPullResponse"}->{"UserData"}->{"Sh-Data"}->{"RepositoryData"}->{"SequenceNumber"};
				} else {
					$response->data()->{'MetaswitchAPI'} = $ref->{"Body"}->{"ShPullResponse"};
					return Apache2::Const::HTTP_OK ;
				}
				#$response->data()->{'MetaswitchAPI'} = $ref;
			} else {
				$response->data()->{'MetaswitchAPI'} = $response->status_line;
				return Apache2::Const::HTTP_OK ;
			}
		#return Apache2::Const::HTTP_OK ;

		
			
			$SequenceNumber++;
			my $MaxSequenceNumber = $self->{ConfigObject}->Get('MetaswitchRESTapiMaxSequenceNumber') || 65535;
			if ( $SequenceNumber>=$MaxSequenceNumber ){
				$SequenceNumber = 1;
			}
		
		# END SequenceNumber	
		}
		
		for my $Item1 (@Keys){
			my $Item;
			my $Flag=0;
			for my $InputItem (@InputParams) {
				my $Tmp;
				($Tmp, undef) = split(/\./,$InputItem);
				if ($Item1 eq $Tmp) {
					$Item = $InputItem;
					$Flag=1;
					last;
				}
			}
			if (!$Flag) {next;}
			if (index($Item,".")>-1) {
				my @List = split(/\./,$Item);
				my $IN="";
				my $OUT="";
				my $ItemConf;
				if ($List[0] eq "RoutingAttributes") {
					for my $Tmp (keys %{$self->{ConfigObject}->Get('MetaswitchRESTapiItemConf')}) {
						if (
							$self->{ConfigObject}->Get('MetaswitchRESTapiItemConf')->{$Tmp}->{Name} eq $List[0]
							&&
							$self->{ConfigObject}->Get('MetaswitchRESTapiItemConf')->{$Tmp}->{ServiceIndication} eq $ServiceIndication
							){
							$ItemConf = $self->{ConfigObject}->Get('MetaswitchRESTapiItemConf')->{$Tmp};
							last;
						}
						if (
							$self->{ConfigObject}->Get('MetaswitchRESTapiItemConf')->{$Tmp}->{Name} eq $List[0]
							&& !$self->{ConfigObject}->Get('MetaswitchRESTapiItemConf')->{$Tmp}->{ServiceIndication}
							){
							$ItemConf = $self->{ConfigObject}->Get('MetaswitchRESTapiItemConf')->{$Tmp};
						}
					}
					my $Data = $ItemConf->{Data};
					if ($Param{$List[0] . ".UseDefault"}) {
						$Data->{UseDefault} = $Param{$List[0] . ".UseDefault"};
					}
					if ($Param{$List[0] . ".Pre-paidOff-switchCallingCardSubscriber.Default"}) {
						$Data->{Pre_paidOff_switchCallingCardSubscriber}->{Default} = $Param{$List[0] . ".Pre-paidOff-switchCallingCardSubscriber.Default"};
					}
					if ($Param{$List[0] . ".Pre-paidOff-switchCallingCardSubscriber.Value"}) {
						$Data->{Pre_paidOff_switchCallingCardSubscriber}->{Value} = $Param{$List[0] . ".Pre-paidOff-switchCallingCardSubscriber.Value"};
					}
					
					if ($Param{$List[0] . ".FaxModemSubscriber.Default"}) {
						$Data->{FaxModemSubscriber}->{Default} = $Param{$List[0] . ".FaxModemSubscriber.Default"};
					}
					if ($Param{$List[0] . ".FaxModemSubscriber.Value"}) {
						$Data->{FaxModemSubscriber}->{Value} = $Param{$List[0] . ".FaxModemSubscriber.Value"};
					}
					
					if ($Param{$List[0] . ".NomadicSubscriber.Default"}) {
						$Data->{NomadicSubscriber}->{Default} = $Param{$List[0] . ".NomadicSubscriber.Default"};
					}
					if ($Param{$List[0] . ".NomadicSubscriber.Value"}) {
						$Data->{NomadicSubscriber}->{Value} = $Param{$List[0] . ".NomadicSubscriber.Value"};
					}
					$self->{LayoutObject}->Block(
						Name => "ItemBlock",
						Data => {
							ItemName => $List[0],
							TYPETYPE => "AAAA",
							EASon => $self->{EASon},
							%{$Data}
						}
					);
				} else {
					for my $Tmp (keys %{$self->{ConfigObject}->Get('MetaswitchRESTapiItemConf')}) {
						if ($self->{ConfigObject}->Get('MetaswitchRESTapiItemConf')->{$Tmp}->{Name} eq $List[0]){
							$ItemConf = $self->{ConfigObject}->Get('MetaswitchRESTapiItemConf')->{$Tmp};
						}
					}
					for my $Temp (@{$ItemConf->{IN}}) {
						if ($Param{$List[0] . "." . $Temp->{Name}}) {
							$Temp->{Value} = $Param{$List[0] . "." . $Temp->{Name}};
							delete $Param{$List[0] . "." . $Temp->{Name}};
						}
						$IN .= " " . $Temp->{Name} . '="' . $Temp->{Value} . '"';
					}
					for my $Temp (@{$ItemConf->{OUT}}) {
						if (ref ($Temp->{Value}) eq "ARRAY"){
							$OUT .= "<ser:" . $Temp->{Name} . '>';
							for my $Temp1 (@{$Temp->{Value}}){
								if ($Param{$List[0] . "." . $Temp->{Name} . "." . $Temp1->{Name}}) {
									$Temp1->{Value} = $Param{$List[0] . "." . $Temp->{Name} . "." . $Temp1->{Name}};
									delete $Param{$List[0] . "." . $Temp->{Name} . "." . $Temp1->{Name}};
								}
								$OUT .= "<ser:" . $Temp1->{Name} . '>' . $Temp1->{Value} . '</ser:' . $Temp1->{Name} . '>';
							}
							$OUT .= '</ser:' . $Temp->{Name} . '>';
						} else {
							if ($Param{$List[0] . "." . $Temp->{Name}}) {
								$Temp->{Value} = $Param{$List[0] . "." . $Temp->{Name}};
								delete $Param{$List[0] . "." . $Temp->{Name}};
							}
							$OUT .= "<ser:" . $Temp->{Name} . '>' . $Temp->{Value} . '</ser:' . $Temp->{Name} . '>';
						}
					}
					$self->{LayoutObject}->Block(
						Name => "ItemBlock",
						Data => {
							ItemName => $List[0],
							INdata => $IN,
							OUTdata => $OUT,
							TYPETYPE => "Hash",
							ServiceIndication => $ServiceIndication,
							EASon => $self->{EASon},
						}
					);
				}
			} elsif ($Param{$Item}) {
				$self->{LayoutObject}->Block(
					Name => "ItemBlock",
					Data => {
						ItemName => $Item,
						ItemValue => $Param{$Item},
						TYPETYPE => "Value",
						ServiceIndication => $ServiceIndication,
						EASon => $self->{EASon},
					}
				);
			}
		}
		my $message = $self->{LayoutObject}->Output(
			TemplateFile => "POST",
			Data => {
				DirectoryNumber => $DirectoryNumber,
				ServiceIndication => $ServiceIndication,
				OriginHost => $OriginHost,
				SequenceNumber => $SequenceNumber,
				EASon => $self->{EASon},
			}
		);

		$response->data()->{'SOAPXML'} = $message;
		#return Apache2::Const::HTTP_OK ;
		
		my $userAgent = LWP::UserAgent->new();
		my $requestLWP = HTTP::Request->new(POST => $self->{ConfigObject}->Get('MetaswitchRESTapiServiceURL' . $self->{EASon}));
		$requestLWP->header(
			%{ $self->{ConfigObject}->Get('MetaswitchRESTapiLWPrequestHeader' . $self->{EASon}) }
		);
		$message = encode('UTF-8', $message);
		$requestLWP->content($message);
		$requestLWP->content_type($self->{ConfigObject}->Get('MetaswitchRESTapiContentType') || "text/xml; charset=utf-8");
		
		my $responseLWP = $userAgent->request($requestLWP);
		if($responseLWP->code == 200) {
			#$response->data()->{'MetaswitchAPI'} = $responseLWP->decoded_content;
			my $XML = $responseLWP->decoded_content;
			$XML =~ s/\w+\://ig;
			my $xs = XML::Simple->new();
			my $ref = $xs->XMLin($XML);
			if ($ref->{"Body"}->{"ShUpdateResponse"}->{"ResultCode"} eq "2001") { 
				$response->data()->{$ServiceIndication} = $ref->{"Body"}->{"ShUpdateResponse"};
			} else {
				$response->data()->{$ServiceIndication} = $ref->{"Body"}->{"ShUpdateResponse"};
			}
			#$response->data()->{$ServiceIndication} = $ref;
		} else {
			$response->data()->{$ServiceIndication} = $response->status_line;
		}
	}
    #$response->data()->{'api_mess'} = 'Hello, this is MyApp REST API' ;
	#$response->data()->{'Umboss Home'} = $Home ;
	#$response->data()->{'message'} = $message ;
    return Apache2::Const::HTTP_OK ;
}

# REST DELETE HTTP method.
# restclient -r "http://192.168.210.33/MetaswitchREST/?DeleteUserIdentity=11010024&ServiceIndication=Meta_Subscriber_BaseInformation" -m DELETE -p ""
# JSON request
#	{"DeleteUserIdentity":"11010024","ServiceIndication":"Meta_Subscriber_BaseInformation"}
#	restclient -r "http://192.168.210.33/MetaswitchREST/?DeleteData=%7B%22DeleteUserIdentity%22%3A%2211010024%22%2C%22ServiceIndication%22%3A%22Meta_Subscriber_BaseInformation%22%7D" -m DELETE -p ""
# Delete business group
#
# {"DeleteUserIdentity":"meribel/Metronet_Croatia_API_Test4","ServiceIndication":"Meta_BusinessGroup_BaseInformation"}
# restclient -r "http://192.168.210.33/MetaswitchREST/?DeleteData=%7B%22DeleteUserIdentity%22%3A%22meribel%2FMetronet_Croatia_API_Test4%22%2C%22ServiceIndication%22%3A%22Meta_BusinessGroup_BaseInformation%22%7D" -m DELETE -p ""
#
# Delete more then one phone number
# [{"DeleteUserIdentity":"11010054","ServiceIndication":"Meta_Subscriber_BaseInformation"},{"DeleteUserIdentity":"11010053","ServiceIndication":"Meta_Subscriber_BaseInformation"}]
# restclient -r "http://192.168.210.33/MetaswitchREST/?DeleteData=%5B%7B%22DeleteUserIdentity%22%3A%2211010054%22%2C%22ServiceIndication%22%3A%22Meta_Subscriber_BaseInformation%22%7D%2C%7B%22DeleteUserIdentity%22%3A%2211010053%22%2C%22ServiceIndication%22%3A%22Meta_Subscriber_BaseInformation%22%7D%5D" -m DELETE -p ""
#
# Delete one phone number and one business group (in wich is not deleted phone number)
# [{"DeleteUserIdentity":"11010052","ServiceIndication":"Meta_Subscriber_BaseInformation"},{"DeleteUserIdentity":"meribel/Metronet_Croatia_API_Test3","ServiceIndication":"Meta_BusinessGroup_BaseInformation"}]
# restclient -r "http://192.168.210.33/MetaswitchREST/?DeleteData=%5B%7B%22DeleteUserIdentity%22%3A%2211010052%22%2C%22ServiceIndication%22%3A%22Meta_Subscriber_BaseInformation%22%7D%2C%7B%22DeleteUserIdentity%22%3A%22meribel%2FMetronet_Croatia_API_Test3%22%2C%22ServiceIndication%22%3A%22Meta_BusinessGroup_BaseInformation%22%7D%5D" -m DELETE -p ""
sub DELETE{
    my ($self, $request, $response) = @_ ;
	$self->_Init($request);
	my $Home              = $self->{ConfigObject}->Get('MetaswitchRESTapiUmbossHome');
	my $DeleteUserIdentity = $request->param('DeleteUserIdentity');
	my $ServiceIndication = $request->param('ServiceIndication') || 'Meta_Subscriber_BaseInformation';
	my $OriginHost = $self->{ConfigObject}->Get('MetaswitchRESTapiOriginHost') || 'user@domain?clientVersion=7.3';
	my $SequenceNumber=1;

	if (! $self->_Auth($request)){
		$response->data()->{'MetaswitchAuthError'} = $self->{AuthError};
		return Apache2::Const::HTTP_OK ;
	}
	
	my $JSONInput = $request->param('DeleteData');
	my @Rows;
	if ($JSONInput){
		#my $d = JSON->new->utf8;
		#my $data = $d->decode($JSONInput);
		my $data = $Kernel::OM->Get('Kernel::System::JSON')->Decode(Data => $JSONInput);
		if (ref($data) eq "ARRAY"){
			push (@Rows,@{$data});
			
		} else {
			#$DeleteUserIdentity = $data->{DeleteUserIdentity};
			#$ServiceIndication = $data->{ServiceIndication};
			push (@Rows,$data);
		}
		#$response->data()->{'Data'} = $data ;
		#return Apache2::Const::HTTP_OK ;
	} else {
		push (@Rows,{DeleteUserIdentity => $DeleteUserIdentity, ServiceIndication=>$ServiceIndication});
	}

	
	$request->requestedFormat($request->param('fmt') || $self->{ConfigObject}->Get('MetaswitchRESTapiWriter') || 'json') ;

	for my $Data (@Rows){
	
		$DeleteUserIdentity = $Data->{DeleteUserIdentity};
		$ServiceIndication = $Data->{ServiceIndication};
	# GET SequenceNumber	
		
		my $messageGET = $self->{LayoutObject}->Output(
			TemplateFile => "GET",
			Data => {
				UserIdentity => $DeleteUserIdentity,
				ServiceIndication => $ServiceIndication,
				OriginHost => $OriginHost,
				EASon => $self->{EASon}
			}
		);
		my $userAgentGET = LWP::UserAgent->new();
		my $requestLWPGET = HTTP::Request->new(POST => $self->{ConfigObject}->Get('MetaswitchRESTapiServiceURL' . $self->{EASon}));
		$requestLWPGET->header(
			%{ $self->{ConfigObject}->Get('MetaswitchRESTapiLWPrequestHeader' . $self->{EASon}) }
		);
		$requestLWPGET->content($messageGET);
		$requestLWPGET->content_type($self->{ConfigObject}->Get('MetaswitchRESTapiContentType') || "text/xml; charset=utf-8");
		
		my $responseLWPGET = $userAgentGET->request($requestLWPGET);
		if($responseLWPGET->code == 200) {
			#$response->data()->{'MetaswitchAPI'} = $responseLWP->decoded_content;
			my $XML = $responseLWPGET->decoded_content;
			$XML =~ s/\w+\://ig;
			my $xs = XML::Simple->new();
			my $ref = $xs->XMLin($XML);
			if ($ref->{"Body"}->{"ShPullResponse"}->{"ResultCode"} eq "2001") { 
				$SequenceNumber = $ref->{"Body"}->{"ShPullResponse"}->{"UserData"}->{"Sh-Data"}->{"RepositoryData"}->{"SequenceNumber"};
			} else {
				if ($self->{ConfigObject}->Get('MetaswitchRESTapiPUTmethodOvrideWithPOST')){
					$SequenceNumber = -1;
				} else {
					$response->data()->{'MetaswitchAPI'} = $ref->{"Body"}->{"ShPullResponse"};
					return Apache2::Const::HTTP_OK ;
				}
			}
			#$response->data()->{'MetaswitchAPI'} = $ref;
		} else {
			$response->data()->{'MetaswitchAPI'} = $response->status_line;
			return Apache2::Const::HTTP_OK ;
		}
	#return Apache2::Const::HTTP_OK ;

		#$response->data()->{'SequenceNumber'} = $SequenceNumber;
		$SequenceNumber++;
		my $MaxSequenceNumber = $self->{ConfigObject}->Get('MetaswitchRESTapiMaxSequenceNumber') || 65535;
		if ( $SequenceNumber>=$MaxSequenceNumber ){
			$SequenceNumber = 1;
		}
	
	# END SequenceNumber
	
	
		my $message = $self->{LayoutObject}->Output(
			TemplateFile => "DELETE",
			Data => {
				UserIdentity => $Data->{DeleteUserIdentity},
				ServiceIndication => $Data->{ServiceIndication},
				OriginHost => $OriginHost,
				SequenceNumber => $SequenceNumber,
				EASon => $self->{EASon}
			}
		);
		my $userAgent = LWP::UserAgent->new();
		my $requestLWP = HTTP::Request->new(POST => $self->{ConfigObject}->Get('MetaswitchRESTapiServiceURL' . $self->{EASon}));
		$requestLWP->header(
			%{ $self->{ConfigObject}->Get('MetaswitchRESTapiLWPrequestHeader' . $self->{EASon}) }
		);
		$message = encode('UTF-8', $message);
		$requestLWP->content($message);
		$requestLWP->content_type($self->{ConfigObject}->Get('MetaswitchRESTapiContentType') || "text/xml; charset=utf-8");
	
		my $responseLWP = $userAgent->request($requestLWP);
		if($responseLWP->code == 200) {
			my $XML = $responseLWP->decoded_content;
			$XML =~ s/\w+\://ig;
			my $xs = XML::Simple->new();
			my $ref = $xs->XMLin($XML);
			if ($ref->{"Body"}->{"ShUpdateResponse"}->{"ResultCode"} eq "2001") { 
				$response->data()->{$Data->{ServiceIndication}} = $ref->{"Body"}->{"ShUpdateResponse"};
			} else {
				$response->data()->{$Data->{ServiceIndication}} = $ref->{"Body"}->{"ShUpdateResponse"};
			}
		} else {
			$response->data()->{$Data->{ServiceIndication}} = $response->status_line;
		}
	}
    return Apache2::Const::HTTP_OK ;
}

# REST PUT HTTP method.
# restclient -r "http://192.168.210.33/MetaswitchREST/?DirectoryNumber=11010024&NewSIPPassword=AAAAAA123456&ConfirmNewSIPPassword=AAAAAA123456&ServiceIndication=Meta_Subscriber_BaseInformation" -m PUT -p ""
# restclient -r "http://192.168.210.33/MetaswitchREST/?DirectoryNumber=11010024&NewSIPPassword=AAAAAA123456&ConfirmNewSIPPassword=AAAAAA123456&ServiceIndication=Meta_Subscriber_BaseInformation&ChargeIndication.UseDefault=True&NetworkNode.UseDefault=True&RoutingAttributes.UseDefault=False&RoutingAttributes.Pre-paidOff-switchCallingCardSubscriber.Value=True" -m PUT -p ""

#####
# JSON examples
#####
#{
#	"Meta_Subscriber_BaseInformation":{
#		"NewSIPPassword":"BBBB123456",
#		"ConfirmNewSIPPassword":"BBBB123456"
#	}
#}

# restclient -r "http://192.168.210.33/MetaswitchREST/?DirectoryNumber=11010024&ConfData=%7B%0D%0A%09%22Meta_Subscriber_BaseInformation%22%3A%7B%0D%0A%09%09%22NewSIPPassword%22%3A%22BBBB123456%22%2C%0D%0A%09%09%22ConfirmNewSIPPassword%22%3A%22BBBB123456%22%0D%0A%09%7D%0D%0A%7D" -m PUT -p ""
####
#{
#	"Meta_Subscriber_BaseInformation":{
#		"NewSIPPassword":"AAAAAA123456",
#		"ConfirmNewSIPPassword":"AAAAAA123456",
#		"ChargeIndication":{"UseDefault":"True"},
#		"NetworkNode": {"UseDefault":"True"},
#		"RoutingAttributes": {
#			"UseDefault":"False",
#			"Pre-paidOff-switchCallingCardSubscriber": {"Value":"True"}
#		}
#	}
#}

# restclient -r "http://192.168.210.33/MetaswitchREST/?DirectoryNumber=11010024&ConfData=%7B%0D%0A%09%22Meta_Subscriber_BaseInformation%22%3A%7B%0D%0A%09%09%22NewSIPPassword%22%3A%22AAAAAA123456%22%2C%0D%0A%09%09%22ConfirmNewSIPPassword%22%3A%22AAAAAA123456%22%2C%0D%0A%09%09%22ChargeIndication%22%3A%7B%22UseDefault%22%3A%22True%22%7D%2C%0D%0A%09%09%22NetworkNode%22%3A+%7B%22UseDefault%22%3A%22True%22%7D%2C%0D%0A%09%09%22RoutingAttributes%22%3A+%7B%0D%0A%09%09%09%22UseDefault%22%3A%22False%22%2C%0D%0A%09%09%09%22Pre-paidOff-switchCallingCardSubscriber%22%3A+%7B%22Value%22%3A%22True%22%7D%0D%0A%09%09%7D%0D%0A%09%7D%0D%0A%7D" -m PUT -p ""
###
#{
#	"Meta_Subscriber_BaseInformation":{
#		"NewSIPPassword":"ZZZZZ9090",
#		"ConfirmNewSIPPassword":"ZZZZZ9090",
#		"ChargeIndication":{"UseDefault":"True"},
#		"NetworkNode": {"UseDefault":"True"},
#		"RoutingAttributes": {
#			"UseDefault":"False",
#			"Pre-paidOff-switchCallingCardSubscriber": {"Value":"True"}
#		}
#	},
#	"Meta_Subscriber_BusyCallForwarding":{
#		"Enabled":"False",
#		"Number":"38598222222"
#	}
#}

# restclient -r "http://192.168.210.33/MetaswitchREST/?DirectoryNumber=11010024&ConfData=%7B%0D%0A%09%22Meta_Subscriber_BaseInformation%22%3A%7B%0D%0A%09%09%22NewSIPPassword%22%3A%22ZZZZZ9090%22%2C%0D%0A%09%09%22ConfirmNewSIPPassword%22%3A%22ZZZZZ9090%22%2C%0D%0A%09%09%22ChargeIndication%22%3A%7B%22UseDefault%22%3A%22True%22%7D%2C%0D%0A%09%09%22NetworkNode%22%3A+%7B%22UseDefault%22%3A%22True%22%7D%2C%0D%0A%09%09%22RoutingAttributes%22%3A+%7B%0D%0A%09%09%09%22UseDefault%22%3A%22False%22%2C%0D%0A%09%09%09%22Pre-paidOff-switchCallingCardSubscriber%22%3A+%7B%22Value%22%3A%22True%22%7D%0D%0A%09%09%7D%0D%0A%09%7D%2C%0D%0A%09%22Meta_Subscriber_BusyCallForwarding%22%3A%7B%0D%0A%09%09%22Enabled%22%3A%22False%22%2C%0D%0A%09%09%22Number%22%3A%2238598222222%22%0D%0A%09%7D%0D%0A%7D" -m PUT -p ""

###
# Update multiple objects
#{
#	"Meta_BusinessGroup_BaseInformation":{
#		"DirectoryNumber":"meribel/Metronet_Croatia_API_Test4",
#		"NetworkElementName":"meribel",
#		"MetaSwitchName":"meribel",
#		"BusinessGroupName":"Metronet_Croatia_API_Test4",
#		"DelegatedManagementGroup":"default",
#		"PersistentProfile":"ITG Default",
#		"SyncWithProfileInProgress":"False",
#		"LocalCNAMName":"Metronet",	
#		"Locale":"English (US)",
#		"SecondLocale":"None",
#		"BillingTypeIntercomCalls":"Local calls flat rate",
#		"NumberOfDirectoryNumbers":"10",
#		"RoutingAttributes":{
#			"UseDefault":"False",
#			"Pre-paidOff-switchCallingCardSubscriber":{"Value":"True"}
#		},
#		"SASHostname":"10.232.206.55"
#	},
#	"Meta_BGNumberBlock_BaseInformation":{
#		"DirectoryNumber":"meribel/Metronet_Croatia_API_Test4/11010050",
#		"NetworkElementName":"meribel",
#		"MetaSwitchName":"meribel",
#		"BusinessGroupName":"Metronet_Croatia_API_Test4",
#		"DeviceTwinning":"None",
#		"BlockSize":"10",
#		"FirstDirectoryNumber":"11010050",
#		"LastDirectoryNumber":"11010059",
#		"SubscriberGroup":"Meribel subscribers"
#	},
#	"Meta_Subscriber_BaseInformation":[
#		{
#			"DirectoryNumber":"11010051",
#			"NetworkElementName":"meribel",
#			"MetaSwitchName":"meribel",
#			"BusinessGroupName":"Metronet_Croatia_API_Test4",
#			"SubscriberType":"BusinessGroupLine",
#			"DirectoryNumber":"11010051",
#			"PersistentProfile":"ITG Default",
#			"NumberStatus":"Normal",
#			"SignalingType":"SIP",
#			"CallAgentSignalingType":"SIP",
#			"UseDNForIdentification":"True",
#			"SIPUserName":"MetroNetTest01",
#			"SIPDomainName":"10.221.0.21",
#			"SIPAuthenticationRequired":"True",
#			"NewSIPPassword":"Test000234",
#			"ConfirmNewSIPPassword":"Test000234",
#			"Locale":"English (US)",
#			"ChargeIndication":{"UseDefault":"True"},
#			"NetworkNode":{"UseDefault":"False"},
#			"RoutingAttributes":{
#				"UseDefault":"False",
#				"Pre-paidOff-switchCallingCardSubscriber":{"Value":"True"}
#			}
#		},
#		{
#			"DirectoryNumber":"11010052",
#			"NetworkElementName":"meribel",
#			"MetaSwitchName":"meribel",
#			"BusinessGroupName":"Metronet_Croatia_API_Test4",
#			"SubscriberType":"BusinessGroupLine",
#			"DirectoryNumber":"11010052",
#			"PersistentProfile":"ITG Default",
#			"NumberStatus":"Normal",
#			"SignalingType":"SIP",
#			"CallAgentSignalingType":"SIP",
#			"UseDNForIdentification":"True",
#			"SIPUserName":"MetroNetTest01",
#			"SIPDomainName":"10.221.0.21",
#			"SIPAuthenticationRequired":"True",
#			"NewSIPPassword":"Test00022",
#			"ConfirmNewSIPPassword":"Test00022",
#			"Locale":"English (US)",
#			"ChargeIndication":{"UseDefault":"True"},
#			"NetworkNode":{"UseDefault":"False"},
#			"RoutingAttributes":{
#				"UseDefault":"False",
#				"Pre-paidOff-switchCallingCardSubscriber":{"Value":"True"}
#			}
#		},
#		{
#			"DirectoryNumber":"11010053",
#			"NetworkElementName":"meribel",
#			"MetaSwitchName":"meribel",
#			"BusinessGroupName":"Metronet_Croatia_API_Test4",
#			"SubscriberType":"BusinessGroupLine",
#			"DirectoryNumber":"11010053",
#			"PersistentProfile":"ITG Default",
#			"NumberStatus":"Normal",
#			"SignalingType":"SIP",
#			"CallAgentSignalingType":"SIP",
#			"UseDNForIdentification":"True",
#			"SIPUserName":"MetroNetTest01",
#			"SIPDomainName":"10.221.0.21",
#			"SIPAuthenticationRequired":"True",
#			"NewSIPPassword":"Test00023",
#			"ConfirmNewSIPPassword":"Test00023",
#			"Locale":"English (US)",
#			"ChargeIndication":{"UseDefault":"True"},
#			"NetworkNode":{"UseDefault":"False"},
#			"RoutingAttributes":{
#				"UseDefault":"False",
#				"Pre-paidOff-switchCallingCardSubscriber":{"Value":"True"}
#			}
#		},
#		{
#			"DirectoryNumber":"11010054",
#			"NetworkElementName":"meribel",
#			"MetaSwitchName":"meribel",
#			"BusinessGroupName":"Metronet_Croatia_API_Test4",
#			"SubscriberType":"BusinessGroupLine",
#			"DirectoryNumber":"11010054",
#			"PersistentProfile":"ITG Default",
#			"NumberStatus":"Normal",
#			"SignalingType":"SIP",
#			"CallAgentSignalingType":"SIP",
#			"UseDNForIdentification":"True",
#			"SIPUserName":"MetroNetTest01",
#			"SIPDomainName":"10.221.0.21",
#			"SIPAuthenticationRequired":"True",
#			"NewSIPPassword":"Test00029",
#			"ConfirmNewSIPPassword":"Test00029",
#			"Locale":"English (US)",
#			"ChargeIndication":{"UseDefault":"True"},
#			"NetworkNode":{"UseDefault":"False"},
#			"RoutingAttributes":{
#				"UseDefault":"False",
#				"Pre-paidOff-switchCallingCardSubscriber":{"Value":"True"}
#			}
#		},
#		{
#			"DirectoryNumber":"11010055",
#			"NetworkElementName":"meribel",
#			"MetaSwitchName":"meribel",
#			"BusinessGroupName":"Metronet_Croatia_API_Test4",
#			"SubscriberType":"BusinessGroupLine",
#			"DirectoryNumber":"11010055",
#			"PersistentProfile":"ITG Default",
#			"NumberStatus":"Normal",
#			"SignalingType":"SIP",
#			"CallAgentSignalingType":"SIP",
#			"UseDNForIdentification":"True",
#			"SIPUserName":"MetroNetTest01",
#			"SIPDomainName":"10.221.0.21",
#			"SIPAuthenticationRequired":"True",
#			"NewSIPPassword":"Test00020a",
#			"ConfirmNewSIPPassword":"Test00020a",
#			"Locale":"English (US)",
#			"ChargeIndication":{"UseDefault":"True"},
#			"NetworkNode":{"UseDefault":"False"},
#			"RoutingAttributes":{
#				"UseDefault":"False",
#				"Pre-paidOff-switchCallingCardSubscriber":{"Value":"True"}
#			}
#		}
#	],
#	"Meta_Subscriber_BusyCallForwarding": [
#		{
#			"DirectoryNumber":"11010051",
#			"Enabled":"False",
#			"Number":"3859822444"
#		},
#		{
#			"DirectoryNumber":"11010052",
#			"Enabled":"False",
#			"Number":"38598225555"
#		},
#		{
#			"DirectoryNumber":"11010053",
#			"Enabled":"False",
#			"Number":"38598225557"
#		},
#		{
#			"DirectoryNumber":"11010054",
#			"Enabled":"False",
#			"Number":"38598225558"
#		},
#		{
#			"DirectoryNumber":"11010055",
#			"Enabled":"False",
#			"Number":"38598225559"
#		}
#	]
#}
#
#curl "http://192.168.210.33/MetaswitchREST/" -k  -XPUT -d "ConfData=%7B%0D%0A%09%22Meta_BusinessGroup_BaseInformation%22%3A%7B%0D%0A%09%09%22DirectoryNumber%22%3A%22meribel%2FMetronet_Croatia_API_Test4%22%2C%0D%0A%09%09%22NetworkElementName%22%3A%22meribel%22%2C%0D%0A%09%09%22MetaSwitchName%22%3A%22meribel%22%2C%0D%0A%09%09%22BusinessGroupName%22%3A%22Metronet_Croatia_API_Test4%22%2C%0D%0A%09%09%22DelegatedManagementGroup%22%3A%22default%22%2C%0D%0A%09%09%22PersistentProfile%22%3A%22ITG+Default%22%2C%0D%0A%09%09%22SyncWithProfileInProgress%22%3A%22False%22%2C%0D%0A%09%09%22LocalCNAMName%22%3A%22Metronet%22%2C%09%0D%0A%09%09%22Locale%22%3A%22English+%28US%29%22%2C%0D%0A%09%09%22SecondLocale%22%3A%22None%22%2C%0D%0A%09%09%22BillingTypeIntercomCalls%22%3A%22Local+calls+flat+rate%22%2C%0D%0A%09%09%22NumberOfDirectoryNumbers%22%3A%2210%22%2C%0D%0A%09%09%22RoutingAttributes%22%3A%7B%0D%0A%09%09%09%22UseDefault%22%3A%22False%22%2C%0D%0A%09%09%09%22Pre-paidOff-switchCallingCardSubscriber%22%3A%7B%22Value%22%3A%22True%22%7D%0D%0A%09%09%7D%2C%0D%0A%09%09%22SASHostname%22%3A%2210.232.206.55%22%0D%0A%09%7D%2C%0D%0A%09%22Meta_BGNumberBlock_BaseInformation%22%3A%7B%0D%0A%09%09%22DirectoryNumber%22%3A%22meribel%2FMetronet_Croatia_API_Test4%2F11010050%22%2C%0D%0A%09%09%22NetworkElementName%22%3A%22meribel%22%2C%0D%0A%09%09%22MetaSwitchName%22%3A%22meribel%22%2C%0D%0A%09%09%22BusinessGroupName%22%3A%22Metronet_Croatia_API_Test4%22%2C%0D%0A%09%09%22DeviceTwinning%22%3A%22None%22%2C%0D%0A%09%09%22BlockSize%22%3A%2210%22%2C%0D%0A%09%09%22FirstDirectoryNumber%22%3A%2211010050%22%2C%0D%0A%09%09%22LastDirectoryNumber%22%3A%2211010059%22%2C%0D%0A%09%09%22SubscriberGroup%22%3A%22Meribel+subscribers%22%0D%0A%09%7D%2C%0D%0A%09%22Meta_Subscriber_BaseInformation%22%3A%5B%0D%0A%09%09%7B%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010051%22%2C%0D%0A%09%09%09%22NetworkElementName%22%3A%22meribel%22%2C%0D%0A%09%09%09%22MetaSwitchName%22%3A%22meribel%22%2C%0D%0A%09%09%09%22BusinessGroupName%22%3A%22Metronet_Croatia_API_Test4%22%2C%0D%0A%09%09%09%22SubscriberType%22%3A%22BusinessGroupLine%22%2C%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010051%22%2C%0D%0A%09%09%09%22PersistentProfile%22%3A%22ITG+Default%22%2C%0D%0A%09%09%09%22NumberStatus%22%3A%22Normal%22%2C%0D%0A%09%09%09%22SignalingType%22%3A%22SIP%22%2C%0D%0A%09%09%09%22CallAgentSignalingType%22%3A%22SIP%22%2C%0D%0A%09%09%09%22UseDNForIdentification%22%3A%22True%22%2C%0D%0A%09%09%09%22SIPUserName%22%3A%22MetroNetTest01%22%2C%0D%0A%09%09%09%22SIPDomainName%22%3A%2210.221.0.21%22%2C%0D%0A%09%09%09%22SIPAuthenticationRequired%22%3A%22True%22%2C%0D%0A%09%09%09%22NewSIPPassword%22%3A%22Test000234%22%2C%0D%0A%09%09%09%22ConfirmNewSIPPassword%22%3A%22Test000234%22%2C%0D%0A%09%09%09%22Locale%22%3A%22English+%28US%29%22%2C%0D%0A%09%09%09%22ChargeIndication%22%3A%7B%22UseDefault%22%3A%22True%22%7D%2C%0D%0A%09%09%09%22NetworkNode%22%3A%7B%22UseDefault%22%3A%22False%22%7D%2C%0D%0A%09%09%09%22RoutingAttributes%22%3A%7B%0D%0A%09%09%09%09%22UseDefault%22%3A%22False%22%2C%0D%0A%09%09%09%09%22Pre-paidOff-switchCallingCardSubscriber%22%3A%7B%22Value%22%3A%22True%22%7D%0D%0A%09%09%09%7D%0D%0A%09%09%7D%2C%0D%0A%09%09%7B%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010052%22%2C%0D%0A%09%09%09%22NetworkElementName%22%3A%22meribel%22%2C%0D%0A%09%09%09%22MetaSwitchName%22%3A%22meribel%22%2C%0D%0A%09%09%09%22BusinessGroupName%22%3A%22Metronet_Croatia_API_Test4%22%2C%0D%0A%09%09%09%22SubscriberType%22%3A%22BusinessGroupLine%22%2C%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010052%22%2C%0D%0A%09%09%09%22PersistentProfile%22%3A%22ITG+Default%22%2C%0D%0A%09%09%09%22NumberStatus%22%3A%22Normal%22%2C%0D%0A%09%09%09%22SignalingType%22%3A%22SIP%22%2C%0D%0A%09%09%09%22CallAgentSignalingType%22%3A%22SIP%22%2C%0D%0A%09%09%09%22UseDNForIdentification%22%3A%22True%22%2C%0D%0A%09%09%09%22SIPUserName%22%3A%22MetroNetTest01%22%2C%0D%0A%09%09%09%22SIPDomainName%22%3A%2210.221.0.21%22%2C%0D%0A%09%09%09%22SIPAuthenticationRequired%22%3A%22True%22%2C%0D%0A%09%09%09%22NewSIPPassword%22%3A%22Test00022%22%2C%0D%0A%09%09%09%22ConfirmNewSIPPassword%22%3A%22Test00022%22%2C%0D%0A%09%09%09%22Locale%22%3A%22English+%28US%29%22%2C%0D%0A%09%09%09%22ChargeIndication%22%3A%7B%22UseDefault%22%3A%22True%22%7D%2C%0D%0A%09%09%09%22NetworkNode%22%3A%7B%22UseDefault%22%3A%22False%22%7D%2C%0D%0A%09%09%09%22RoutingAttributes%22%3A%7B%0D%0A%09%09%09%09%22UseDefault%22%3A%22False%22%2C%0D%0A%09%09%09%09%22Pre-paidOff-switchCallingCardSubscriber%22%3A%7B%22Value%22%3A%22True%22%7D%0D%0A%09%09%09%7D%0D%0A%09%09%7D%2C%0D%0A%09%09%7B%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010053%22%2C%0D%0A%09%09%09%22NetworkElementName%22%3A%22meribel%22%2C%0D%0A%09%09%09%22MetaSwitchName%22%3A%22meribel%22%2C%0D%0A%09%09%09%22BusinessGroupName%22%3A%22Metronet_Croatia_API_Test4%22%2C%0D%0A%09%09%09%22SubscriberType%22%3A%22BusinessGroupLine%22%2C%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010053%22%2C%0D%0A%09%09%09%22PersistentProfile%22%3A%22ITG+Default%22%2C%0D%0A%09%09%09%22NumberStatus%22%3A%22Normal%22%2C%0D%0A%09%09%09%22SignalingType%22%3A%22SIP%22%2C%0D%0A%09%09%09%22CallAgentSignalingType%22%3A%22SIP%22%2C%0D%0A%09%09%09%22UseDNForIdentification%22%3A%22True%22%2C%0D%0A%09%09%09%22SIPUserName%22%3A%22MetroNetTest01%22%2C%0D%0A%09%09%09%22SIPDomainName%22%3A%2210.221.0.21%22%2C%0D%0A%09%09%09%22SIPAuthenticationRequired%22%3A%22True%22%2C%0D%0A%09%09%09%22NewSIPPassword%22%3A%22Test00023%22%2C%0D%0A%09%09%09%22ConfirmNewSIPPassword%22%3A%22Test00023%22%2C%0D%0A%09%09%09%22Locale%22%3A%22English+%28US%29%22%2C%0D%0A%09%09%09%22ChargeIndication%22%3A%7B%22UseDefault%22%3A%22True%22%7D%2C%0D%0A%09%09%09%22NetworkNode%22%3A%7B%22UseDefault%22%3A%22False%22%7D%2C%0D%0A%09%09%09%22RoutingAttributes%22%3A%7B%0D%0A%09%09%09%09%22UseDefault%22%3A%22False%22%2C%0D%0A%09%09%09%09%22Pre-paidOff-switchCallingCardSubscriber%22%3A%7B%22Value%22%3A%22True%22%7D%0D%0A%09%09%09%7D%0D%0A%09%09%7D%2C%0D%0A%09%09%7B%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010054%22%2C%0D%0A%09%09%09%22NetworkElementName%22%3A%22meribel%22%2C%0D%0A%09%09%09%22MetaSwitchName%22%3A%22meribel%22%2C%0D%0A%09%09%09%22BusinessGroupName%22%3A%22Metronet_Croatia_API_Test4%22%2C%0D%0A%09%09%09%22SubscriberType%22%3A%22BusinessGroupLine%22%2C%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010054%22%2C%0D%0A%09%09%09%22PersistentProfile%22%3A%22ITG+Default%22%2C%0D%0A%09%09%09%22NumberStatus%22%3A%22Normal%22%2C%0D%0A%09%09%09%22SignalingType%22%3A%22SIP%22%2C%0D%0A%09%09%09%22CallAgentSignalingType%22%3A%22SIP%22%2C%0D%0A%09%09%09%22UseDNForIdentification%22%3A%22True%22%2C%0D%0A%09%09%09%22SIPUserName%22%3A%22MetroNetTest01%22%2C%0D%0A%09%09%09%22SIPDomainName%22%3A%2210.221.0.21%22%2C%0D%0A%09%09%09%22SIPAuthenticationRequired%22%3A%22True%22%2C%0D%0A%09%09%09%22NewSIPPassword%22%3A%22Test00029%22%2C%0D%0A%09%09%09%22ConfirmNewSIPPassword%22%3A%22Test00029%22%2C%0D%0A%09%09%09%22Locale%22%3A%22English+%28US%29%22%2C%0D%0A%09%09%09%22ChargeIndication%22%3A%7B%22UseDefault%22%3A%22True%22%7D%2C%0D%0A%09%09%09%22NetworkNode%22%3A%7B%22UseDefault%22%3A%22False%22%7D%2C%0D%0A%09%09%09%22RoutingAttributes%22%3A%7B%0D%0A%09%09%09%09%22UseDefault%22%3A%22False%22%2C%0D%0A%09%09%09%09%22Pre-paidOff-switchCallingCardSubscriber%22%3A%7B%22Value%22%3A%22True%22%7D%0D%0A%09%09%09%7D%0D%0A%09%09%7D%2C%0D%0A%09%09%7B%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010055%22%2C%0D%0A%09%09%09%22NetworkElementName%22%3A%22meribel%22%2C%0D%0A%09%09%09%22MetaSwitchName%22%3A%22meribel%22%2C%0D%0A%09%09%09%22BusinessGroupName%22%3A%22Metronet_Croatia_API_Test4%22%2C%0D%0A%09%09%09%22SubscriberType%22%3A%22BusinessGroupLine%22%2C%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010055%22%2C%0D%0A%09%09%09%22PersistentProfile%22%3A%22ITG+Default%22%2C%0D%0A%09%09%09%22NumberStatus%22%3A%22Normal%22%2C%0D%0A%09%09%09%22SignalingType%22%3A%22SIP%22%2C%0D%0A%09%09%09%22CallAgentSignalingType%22%3A%22SIP%22%2C%0D%0A%09%09%09%22UseDNForIdentification%22%3A%22True%22%2C%0D%0A%09%09%09%22SIPUserName%22%3A%22MetroNetTest01%22%2C%0D%0A%09%09%09%22SIPDomainName%22%3A%2210.221.0.21%22%2C%0D%0A%09%09%09%22SIPAuthenticationRequired%22%3A%22True%22%2C%0D%0A%09%09%09%22NewSIPPassword%22%3A%22Test00020a%22%2C%0D%0A%09%09%09%22ConfirmNewSIPPassword%22%3A%22Test00020a%22%2C%0D%0A%09%09%09%22Locale%22%3A%22English+%28US%29%22%2C%0D%0A%09%09%09%22ChargeIndication%22%3A%7B%22UseDefault%22%3A%22True%22%7D%2C%0D%0A%09%09%09%22NetworkNode%22%3A%7B%22UseDefault%22%3A%22False%22%7D%2C%0D%0A%09%09%09%22RoutingAttributes%22%3A%7B%0D%0A%09%09%09%09%22UseDefault%22%3A%22False%22%2C%0D%0A%09%09%09%09%22Pre-paidOff-switchCallingCardSubscriber%22%3A%7B%22Value%22%3A%22True%22%7D%0D%0A%09%09%09%7D%0D%0A%09%09%7D%0D%0A%09%5D%2C%0D%0A%09%22Meta_Subscriber_BusyCallForwarding%22%3A+%5B%0D%0A%09%09%7B%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010051%22%2C%0D%0A%09%09%09%22Enabled%22%3A%22False%22%2C%0D%0A%09%09%09%22Number%22%3A%223859822444%22%0D%0A%09%09%7D%2C%0D%0A%09%09%7B%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010052%22%2C%0D%0A%09%09%09%22Enabled%22%3A%22False%22%2C%0D%0A%09%09%09%22Number%22%3A%2238598225555%22%0D%0A%09%09%7D%2C%0D%0A%09%09%7B%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010053%22%2C%0D%0A%09%09%09%22Enabled%22%3A%22False%22%2C%0D%0A%09%09%09%22Number%22%3A%2238598225557%22%0D%0A%09%09%7D%2C%0D%0A%09%09%7B%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010054%22%2C%0D%0A%09%09%09%22Enabled%22%3A%22False%22%2C%0D%0A%09%09%09%22Number%22%3A%2238598225558%22%0D%0A%09%09%7D%2C%0D%0A%09%09%7B%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010055%22%2C%0D%0A%09%09%09%22Enabled%22%3A%22False%22%2C%0D%0A%09%09%09%22Number%22%3A%2238598225559%22%0D%0A%09%09%7D%0D%0A%09%5D%0D%0A%7D"
#
# PUT as a POST (adding phone number 11010056 and update SIP pass for phone number 11010055, rest objects unchanged)
#{
#	"Meta_BusinessGroup_BaseInformation":{
#		"DirectoryNumber":"meribel/Metronet_Croatia_API_Test4",
#		"NetworkElementName":"meribel",
#		"MetaSwitchName":"meribel",
#		"BusinessGroupName":"Metronet_Croatia_API_Test4",
#		"DelegatedManagementGroup":"default",
#		"PersistentProfile":"ITG Default",
#		"SyncWithProfileInProgress":"False",
#		"LocalCNAMName":"Metronet",	
#		"Locale":"English (US)",
#		"SecondLocale":"None",
#		"BillingTypeIntercomCalls":"Local calls flat rate",
#		"NumberOfDirectoryNumbers":"10",
#		"RoutingAttributes":{
#			"UseDefault":"False",
#			"Pre-paidOff-switchCallingCardSubscriber":{"Value":"True"}
#		},
#		"SASHostname":"10.232.206.55"
#	},
#	"Meta_BGNumberBlock_BaseInformation":{
#		"DirectoryNumber":"meribel/Metronet_Croatia_API_Test4/11010050",
#		"NetworkElementName":"meribel",
#		"MetaSwitchName":"meribel",
#		"BusinessGroupName":"Metronet_Croatia_API_Test4",
#		"DeviceTwinning":"None",
#		"BlockSize":"10",
#		"FirstDirectoryNumber":"11010050",
#		"LastDirectoryNumber":"11010059",
#		"SubscriberGroup":"Meribel subscribers"
#	},
#	"Meta_Subscriber_BaseInformation":[
#		{
#			"DirectoryNumber":"11010051",
#			"NetworkElementName":"meribel",
#			"MetaSwitchName":"meribel",
#			"BusinessGroupName":"Metronet_Croatia_API_Test4",
#			"SubscriberType":"BusinessGroupLine",
#			"DirectoryNumber":"11010051",
#			"PersistentProfile":"ITG Default",
#			"NumberStatus":"Normal",
#			"SignalingType":"SIP",
#			"CallAgentSignalingType":"SIP",
#			"UseDNForIdentification":"True",
#			"SIPUserName":"MetroNetTest01",
#			"SIPDomainName":"10.221.0.21",
#			"SIPAuthenticationRequired":"True",
#			"NewSIPPassword":"Test000234",
#			"ConfirmNewSIPPassword":"Test000234",
#			"Locale":"English (US)",
#			"ChargeIndication":{"UseDefault":"True"},
#			"NetworkNode":{"UseDefault":"False"},
#			"RoutingAttributes":{
#				"UseDefault":"False",
#				"Pre-paidOff-switchCallingCardSubscriber":{"Value":"True"}
#			}
#		},
#		{
#			"DirectoryNumber":"11010052",
#			"NetworkElementName":"meribel",
#			"MetaSwitchName":"meribel",
#			"BusinessGroupName":"Metronet_Croatia_API_Test4",
#			"SubscriberType":"BusinessGroupLine",
#			"DirectoryNumber":"11010052",
#			"PersistentProfile":"ITG Default",
#			"NumberStatus":"Normal",
#			"SignalingType":"SIP",
#			"CallAgentSignalingType":"SIP",
#			"UseDNForIdentification":"True",
#			"SIPUserName":"MetroNetTest01",
#			"SIPDomainName":"10.221.0.21",
#			"SIPAuthenticationRequired":"True",
#			"NewSIPPassword":"Test00022",
#			"ConfirmNewSIPPassword":"Test00022",
#			"Locale":"English (US)",
#			"ChargeIndication":{"UseDefault":"True"},
#			"NetworkNode":{"UseDefault":"False"},
#			"RoutingAttributes":{
#				"UseDefault":"False",
#				"Pre-paidOff-switchCallingCardSubscriber":{"Value":"True"}
#			}
#		},
#		{
#			"DirectoryNumber":"11010053",
#			"NetworkElementName":"meribel",
#			"MetaSwitchName":"meribel",
#			"BusinessGroupName":"Metronet_Croatia_API_Test4",
#			"SubscriberType":"BusinessGroupLine",
#			"DirectoryNumber":"11010053",
#			"PersistentProfile":"ITG Default",
#			"NumberStatus":"Normal",
#			"SignalingType":"SIP",
#			"CallAgentSignalingType":"SIP",
#			"UseDNForIdentification":"True",
#			"SIPUserName":"MetroNetTest01",
#			"SIPDomainName":"10.221.0.21",
#			"SIPAuthenticationRequired":"True",
#			"NewSIPPassword":"Test00023",
#			"ConfirmNewSIPPassword":"Test00023",
#			"Locale":"English (US)",
#			"ChargeIndication":{"UseDefault":"True"},
#			"NetworkNode":{"UseDefault":"False"},
#			"RoutingAttributes":{
#				"UseDefault":"False",
#				"Pre-paidOff-switchCallingCardSubscriber":{"Value":"True"}
#			}
#		},
#		{
#			"DirectoryNumber":"11010054",
#			"NetworkElementName":"meribel",
#			"MetaSwitchName":"meribel",
#			"BusinessGroupName":"Metronet_Croatia_API_Test4",
#			"SubscriberType":"BusinessGroupLine",
#			"DirectoryNumber":"11010054",
#			"PersistentProfile":"ITG Default",
#			"NumberStatus":"Normal",
#			"SignalingType":"SIP",
#			"CallAgentSignalingType":"SIP",
#			"UseDNForIdentification":"True",
#			"SIPUserName":"MetroNetTest01",
#			"SIPDomainName":"10.221.0.21",
#			"SIPAuthenticationRequired":"True",
#			"NewSIPPassword":"Test00029",
#			"ConfirmNewSIPPassword":"Test00029",
#			"Locale":"English (US)",
#			"ChargeIndication":{"UseDefault":"True"},
#			"NetworkNode":{"UseDefault":"False"},
#			"RoutingAttributes":{
#				"UseDefault":"False",
#				"Pre-paidOff-switchCallingCardSubscriber":{"Value":"True"}
#			}
#		},
#		{
#			"DirectoryNumber":"11010055",
#			"NetworkElementName":"meribel",
#			"MetaSwitchName":"meribel",
#			"BusinessGroupName":"Metronet_Croatia_API_Test4",
#			"SubscriberType":"BusinessGroupLine",
#			"DirectoryNumber":"11010055",
#			"PersistentProfile":"ITG Default",
#			"NumberStatus":"Normal",
#			"SignalingType":"SIP",
#			"CallAgentSignalingType":"SIP",
#			"UseDNForIdentification":"True",
#			"SIPUserName":"MetroNetTest01",
#			"SIPDomainName":"10.221.0.21",
#			"SIPAuthenticationRequired":"True",
#			"NewSIPPassword":"Test00020aa",
#			"ConfirmNewSIPPassword":"Test00020aa",
#			"Locale":"English (US)",
#			"ChargeIndication":{"UseDefault":"True"},
#			"NetworkNode":{"UseDefault":"False"},
#			"RoutingAttributes":{
#				"UseDefault":"False",
#				"Pre-paidOff-switchCallingCardSubscriber":{"Value":"True"}
#			}
#		},
#		{
#			"DirectoryNumber":"11010056",
#			"NetworkElementName":"meribel",
#			"MetaSwitchName":"meribel",
#			"BusinessGroupName":"Metronet_Croatia_API_Test4",
#			"SubscriberType":"BusinessGroupLine",
#			"DirectoryNumber":"11010056",
#			"PersistentProfile":"ITG Default",
#			"NumberStatus":"Normal",
#			"SignalingType":"SIP",
#			"CallAgentSignalingType":"SIP",
#			"UseDNForIdentification":"True",
#			"SIPUserName":"MetroNetTest01",
#			"SIPDomainName":"10.221.0.21",
#			"SIPAuthenticationRequired":"True",
#			"NewSIPPassword":"Test6600020aa",
#			"ConfirmNewSIPPassword":"Test6600020aa",
#			"Locale":"English (US)",
#			"ChargeIndication":{"UseDefault":"True"},
#			"NetworkNode":{"UseDefault":"False"},
#			"RoutingAttributes":{
#				"UseDefault":"False",
#				"Pre-paidOff-switchCallingCardSubscriber":{"Value":"True"}
#			}
#		}
#	],
#	"Meta_Subscriber_BusyCallForwarding": [
#		{
#			"DirectoryNumber":"11010051",
#			"Enabled":"False",
#			"Number":"3859822444"
#		},
#		{
#			"DirectoryNumber":"11010052",
#			"Enabled":"False",
#			"Number":"38598225555"
#		},
#		{
#			"DirectoryNumber":"11010053",
#			"Enabled":"False",
#			"Number":"38598225557"
#		},
#		{
#			"DirectoryNumber":"11010054",
#			"Enabled":"False",
#			"Number":"38598225558"
#		},
#		{
#			"DirectoryNumber":"11010055",
#			"Enabled":"False",
#			"Number":"38598225559"
#		}
#	]
#}
#
#curl "http://192.168.210.33/MetaswitchREST/" -k  -XPUT -d "ConfData=%7B%0D%0A%09%22Meta_BusinessGroup_BaseInformation%22%3A%7B%0D%0A%09%09%22DirectoryNumber%22%3A%22meribel%2FMetronet_Croatia_API_Test4%22%2C%0D%0A%09%09%22NetworkElementName%22%3A%22meribel%22%2C%0D%0A%09%09%22MetaSwitchName%22%3A%22meribel%22%2C%0D%0A%09%09%22BusinessGroupName%22%3A%22Metronet_Croatia_API_Test4%22%2C%0D%0A%09%09%22DelegatedManagementGroup%22%3A%22default%22%2C%0D%0A%09%09%22PersistentProfile%22%3A%22ITG+Default%22%2C%0D%0A%09%09%22SyncWithProfileInProgress%22%3A%22False%22%2C%0D%0A%09%09%22LocalCNAMName%22%3A%22Metronet%22%2C%09%0D%0A%09%09%22Locale%22%3A%22English+%28US%29%22%2C%0D%0A%09%09%22SecondLocale%22%3A%22None%22%2C%0D%0A%09%09%22BillingTypeIntercomCalls%22%3A%22Local+calls+flat+rate%22%2C%0D%0A%09%09%22NumberOfDirectoryNumbers%22%3A%2210%22%2C%0D%0A%09%09%22RoutingAttributes%22%3A%7B%0D%0A%09%09%09%22UseDefault%22%3A%22False%22%2C%0D%0A%09%09%09%22Pre-paidOff-switchCallingCardSubscriber%22%3A%7B%22Value%22%3A%22True%22%7D%0D%0A%09%09%7D%2C%0D%0A%09%09%22SASHostname%22%3A%2210.232.206.55%22%0D%0A%09%7D%2C%0D%0A%09%22Meta_BGNumberBlock_BaseInformation%22%3A%7B%0D%0A%09%09%22DirectoryNumber%22%3A%22meribel%2FMetronet_Croatia_API_Test4%2F11010050%22%2C%0D%0A%09%09%22NetworkElementName%22%3A%22meribel%22%2C%0D%0A%09%09%22MetaSwitchName%22%3A%22meribel%22%2C%0D%0A%09%09%22BusinessGroupName%22%3A%22Metronet_Croatia_API_Test4%22%2C%0D%0A%09%09%22DeviceTwinning%22%3A%22None%22%2C%0D%0A%09%09%22BlockSize%22%3A%2210%22%2C%0D%0A%09%09%22FirstDirectoryNumber%22%3A%2211010050%22%2C%0D%0A%09%09%22LastDirectoryNumber%22%3A%2211010059%22%2C%0D%0A%09%09%22SubscriberGroup%22%3A%22Meribel+subscribers%22%0D%0A%09%7D%2C%0D%0A%09%22Meta_Subscriber_BaseInformation%22%3A%5B%0D%0A%09%09%7B%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010051%22%2C%0D%0A%09%09%09%22NetworkElementName%22%3A%22meribel%22%2C%0D%0A%09%09%09%22MetaSwitchName%22%3A%22meribel%22%2C%0D%0A%09%09%09%22BusinessGroupName%22%3A%22Metronet_Croatia_API_Test4%22%2C%0D%0A%09%09%09%22SubscriberType%22%3A%22BusinessGroupLine%22%2C%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010051%22%2C%0D%0A%09%09%09%22PersistentProfile%22%3A%22ITG+Default%22%2C%0D%0A%09%09%09%22NumberStatus%22%3A%22Normal%22%2C%0D%0A%09%09%09%22SignalingType%22%3A%22SIP%22%2C%0D%0A%09%09%09%22CallAgentSignalingType%22%3A%22SIP%22%2C%0D%0A%09%09%09%22UseDNForIdentification%22%3A%22True%22%2C%0D%0A%09%09%09%22SIPUserName%22%3A%22MetroNetTest01%22%2C%0D%0A%09%09%09%22SIPDomainName%22%3A%2210.221.0.21%22%2C%0D%0A%09%09%09%22SIPAuthenticationRequired%22%3A%22True%22%2C%0D%0A%09%09%09%22NewSIPPassword%22%3A%22Test000234%22%2C%0D%0A%09%09%09%22ConfirmNewSIPPassword%22%3A%22Test000234%22%2C%0D%0A%09%09%09%22Locale%22%3A%22English+%28US%29%22%2C%0D%0A%09%09%09%22ChargeIndication%22%3A%7B%22UseDefault%22%3A%22True%22%7D%2C%0D%0A%09%09%09%22NetworkNode%22%3A%7B%22UseDefault%22%3A%22False%22%7D%2C%0D%0A%09%09%09%22RoutingAttributes%22%3A%7B%0D%0A%09%09%09%09%22UseDefault%22%3A%22False%22%2C%0D%0A%09%09%09%09%22Pre-paidOff-switchCallingCardSubscriber%22%3A%7B%22Value%22%3A%22True%22%7D%0D%0A%09%09%09%7D%0D%0A%09%09%7D%2C%0D%0A%09%09%7B%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010052%22%2C%0D%0A%09%09%09%22NetworkElementName%22%3A%22meribel%22%2C%0D%0A%09%09%09%22MetaSwitchName%22%3A%22meribel%22%2C%0D%0A%09%09%09%22BusinessGroupName%22%3A%22Metronet_Croatia_API_Test4%22%2C%0D%0A%09%09%09%22SubscriberType%22%3A%22BusinessGroupLine%22%2C%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010052%22%2C%0D%0A%09%09%09%22PersistentProfile%22%3A%22ITG+Default%22%2C%0D%0A%09%09%09%22NumberStatus%22%3A%22Normal%22%2C%0D%0A%09%09%09%22SignalingType%22%3A%22SIP%22%2C%0D%0A%09%09%09%22CallAgentSignalingType%22%3A%22SIP%22%2C%0D%0A%09%09%09%22UseDNForIdentification%22%3A%22True%22%2C%0D%0A%09%09%09%22SIPUserName%22%3A%22MetroNetTest01%22%2C%0D%0A%09%09%09%22SIPDomainName%22%3A%2210.221.0.21%22%2C%0D%0A%09%09%09%22SIPAuthenticationRequired%22%3A%22True%22%2C%0D%0A%09%09%09%22NewSIPPassword%22%3A%22Test00022%22%2C%0D%0A%09%09%09%22ConfirmNewSIPPassword%22%3A%22Test00022%22%2C%0D%0A%09%09%09%22Locale%22%3A%22English+%28US%29%22%2C%0D%0A%09%09%09%22ChargeIndication%22%3A%7B%22UseDefault%22%3A%22True%22%7D%2C%0D%0A%09%09%09%22NetworkNode%22%3A%7B%22UseDefault%22%3A%22False%22%7D%2C%0D%0A%09%09%09%22RoutingAttributes%22%3A%7B%0D%0A%09%09%09%09%22UseDefault%22%3A%22False%22%2C%0D%0A%09%09%09%09%22Pre-paidOff-switchCallingCardSubscriber%22%3A%7B%22Value%22%3A%22True%22%7D%0D%0A%09%09%09%7D%0D%0A%09%09%7D%2C%0D%0A%09%09%7B%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010053%22%2C%0D%0A%09%09%09%22NetworkElementName%22%3A%22meribel%22%2C%0D%0A%09%09%09%22MetaSwitchName%22%3A%22meribel%22%2C%0D%0A%09%09%09%22BusinessGroupName%22%3A%22Metronet_Croatia_API_Test4%22%2C%0D%0A%09%09%09%22SubscriberType%22%3A%22BusinessGroupLine%22%2C%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010053%22%2C%0D%0A%09%09%09%22PersistentProfile%22%3A%22ITG+Default%22%2C%0D%0A%09%09%09%22NumberStatus%22%3A%22Normal%22%2C%0D%0A%09%09%09%22SignalingType%22%3A%22SIP%22%2C%0D%0A%09%09%09%22CallAgentSignalingType%22%3A%22SIP%22%2C%0D%0A%09%09%09%22UseDNForIdentification%22%3A%22True%22%2C%0D%0A%09%09%09%22SIPUserName%22%3A%22MetroNetTest01%22%2C%0D%0A%09%09%09%22SIPDomainName%22%3A%2210.221.0.21%22%2C%0D%0A%09%09%09%22SIPAuthenticationRequired%22%3A%22True%22%2C%0D%0A%09%09%09%22NewSIPPassword%22%3A%22Test00023%22%2C%0D%0A%09%09%09%22ConfirmNewSIPPassword%22%3A%22Test00023%22%2C%0D%0A%09%09%09%22Locale%22%3A%22English+%28US%29%22%2C%0D%0A%09%09%09%22ChargeIndication%22%3A%7B%22UseDefault%22%3A%22True%22%7D%2C%0D%0A%09%09%09%22NetworkNode%22%3A%7B%22UseDefault%22%3A%22False%22%7D%2C%0D%0A%09%09%09%22RoutingAttributes%22%3A%7B%0D%0A%09%09%09%09%22UseDefault%22%3A%22False%22%2C%0D%0A%09%09%09%09%22Pre-paidOff-switchCallingCardSubscriber%22%3A%7B%22Value%22%3A%22True%22%7D%0D%0A%09%09%09%7D%0D%0A%09%09%7D%2C%0D%0A%09%09%7B%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010054%22%2C%0D%0A%09%09%09%22NetworkElementName%22%3A%22meribel%22%2C%0D%0A%09%09%09%22MetaSwitchName%22%3A%22meribel%22%2C%0D%0A%09%09%09%22BusinessGroupName%22%3A%22Metronet_Croatia_API_Test4%22%2C%0D%0A%09%09%09%22SubscriberType%22%3A%22BusinessGroupLine%22%2C%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010054%22%2C%0D%0A%09%09%09%22PersistentProfile%22%3A%22ITG+Default%22%2C%0D%0A%09%09%09%22NumberStatus%22%3A%22Normal%22%2C%0D%0A%09%09%09%22SignalingType%22%3A%22SIP%22%2C%0D%0A%09%09%09%22CallAgentSignalingType%22%3A%22SIP%22%2C%0D%0A%09%09%09%22UseDNForIdentification%22%3A%22True%22%2C%0D%0A%09%09%09%22SIPUserName%22%3A%22MetroNetTest01%22%2C%0D%0A%09%09%09%22SIPDomainName%22%3A%2210.221.0.21%22%2C%0D%0A%09%09%09%22SIPAuthenticationRequired%22%3A%22True%22%2C%0D%0A%09%09%09%22NewSIPPassword%22%3A%22Test00029%22%2C%0D%0A%09%09%09%22ConfirmNewSIPPassword%22%3A%22Test00029%22%2C%0D%0A%09%09%09%22Locale%22%3A%22English+%28US%29%22%2C%0D%0A%09%09%09%22ChargeIndication%22%3A%7B%22UseDefault%22%3A%22True%22%7D%2C%0D%0A%09%09%09%22NetworkNode%22%3A%7B%22UseDefault%22%3A%22False%22%7D%2C%0D%0A%09%09%09%22RoutingAttributes%22%3A%7B%0D%0A%09%09%09%09%22UseDefault%22%3A%22False%22%2C%0D%0A%09%09%09%09%22Pre-paidOff-switchCallingCardSubscriber%22%3A%7B%22Value%22%3A%22True%22%7D%0D%0A%09%09%09%7D%0D%0A%09%09%7D%2C%0D%0A%09%09%7B%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010055%22%2C%0D%0A%09%09%09%22NetworkElementName%22%3A%22meribel%22%2C%0D%0A%09%09%09%22MetaSwitchName%22%3A%22meribel%22%2C%0D%0A%09%09%09%22BusinessGroupName%22%3A%22Metronet_Croatia_API_Test4%22%2C%0D%0A%09%09%09%22SubscriberType%22%3A%22BusinessGroupLine%22%2C%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010055%22%2C%0D%0A%09%09%09%22PersistentProfile%22%3A%22ITG+Default%22%2C%0D%0A%09%09%09%22NumberStatus%22%3A%22Normal%22%2C%0D%0A%09%09%09%22SignalingType%22%3A%22SIP%22%2C%0D%0A%09%09%09%22CallAgentSignalingType%22%3A%22SIP%22%2C%0D%0A%09%09%09%22UseDNForIdentification%22%3A%22True%22%2C%0D%0A%09%09%09%22SIPUserName%22%3A%22MetroNetTest01%22%2C%0D%0A%09%09%09%22SIPDomainName%22%3A%2210.221.0.21%22%2C%0D%0A%09%09%09%22SIPAuthenticationRequired%22%3A%22True%22%2C%0D%0A%09%09%09%22NewSIPPassword%22%3A%22Test00020aa%22%2C%0D%0A%09%09%09%22ConfirmNewSIPPassword%22%3A%22Test00020aa%22%2C%0D%0A%09%09%09%22Locale%22%3A%22English+%28US%29%22%2C%0D%0A%09%09%09%22ChargeIndication%22%3A%7B%22UseDefault%22%3A%22True%22%7D%2C%0D%0A%09%09%09%22NetworkNode%22%3A%7B%22UseDefault%22%3A%22False%22%7D%2C%0D%0A%09%09%09%22RoutingAttributes%22%3A%7B%0D%0A%09%09%09%09%22UseDefault%22%3A%22False%22%2C%0D%0A%09%09%09%09%22Pre-paidOff-switchCallingCardSubscriber%22%3A%7B%22Value%22%3A%22True%22%7D%0D%0A%09%09%09%7D%0D%0A%09%09%7D%2C%0D%0A%09%09%7B%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010056%22%2C%0D%0A%09%09%09%22NetworkElementName%22%3A%22meribel%22%2C%0D%0A%09%09%09%22MetaSwitchName%22%3A%22meribel%22%2C%0D%0A%09%09%09%22BusinessGroupName%22%3A%22Metronet_Croatia_API_Test4%22%2C%0D%0A%09%09%09%22SubscriberType%22%3A%22BusinessGroupLine%22%2C%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010056%22%2C%0D%0A%09%09%09%22PersistentProfile%22%3A%22ITG+Default%22%2C%0D%0A%09%09%09%22NumberStatus%22%3A%22Normal%22%2C%0D%0A%09%09%09%22SignalingType%22%3A%22SIP%22%2C%0D%0A%09%09%09%22CallAgentSignalingType%22%3A%22SIP%22%2C%0D%0A%09%09%09%22UseDNForIdentification%22%3A%22True%22%2C%0D%0A%09%09%09%22SIPUserName%22%3A%22MetroNetTest01%22%2C%0D%0A%09%09%09%22SIPDomainName%22%3A%2210.221.0.21%22%2C%0D%0A%09%09%09%22SIPAuthenticationRequired%22%3A%22True%22%2C%0D%0A%09%09%09%22NewSIPPassword%22%3A%22Test6600020aa%22%2C%0D%0A%09%09%09%22ConfirmNewSIPPassword%22%3A%22Test6600020aa%22%2C%0D%0A%09%09%09%22Locale%22%3A%22English+%28US%29%22%2C%0D%0A%09%09%09%22ChargeIndication%22%3A%7B%22UseDefault%22%3A%22True%22%7D%2C%0D%0A%09%09%09%22NetworkNode%22%3A%7B%22UseDefault%22%3A%22False%22%7D%2C%0D%0A%09%09%09%22RoutingAttributes%22%3A%7B%0D%0A%09%09%09%09%22UseDefault%22%3A%22False%22%2C%0D%0A%09%09%09%09%22Pre-paidOff-switchCallingCardSubscriber%22%3A%7B%22Value%22%3A%22True%22%7D%0D%0A%09%09%09%7D%0D%0A%09%09%7D%0D%0A%09%5D%2C%0D%0A%09%22Meta_Subscriber_BusyCallForwarding%22%3A+%5B%0D%0A%09%09%7B%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010051%22%2C%0D%0A%09%09%09%22Enabled%22%3A%22False%22%2C%0D%0A%09%09%09%22Number%22%3A%223859822444%22%0D%0A%09%09%7D%2C%0D%0A%09%09%7B%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010052%22%2C%0D%0A%09%09%09%22Enabled%22%3A%22False%22%2C%0D%0A%09%09%09%22Number%22%3A%2238598225555%22%0D%0A%09%09%7D%2C%0D%0A%09%09%7B%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010053%22%2C%0D%0A%09%09%09%22Enabled%22%3A%22False%22%2C%0D%0A%09%09%09%22Number%22%3A%2238598225557%22%0D%0A%09%09%7D%2C%0D%0A%09%09%7B%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010054%22%2C%0D%0A%09%09%09%22Enabled%22%3A%22False%22%2C%0D%0A%09%09%09%22Number%22%3A%2238598225558%22%0D%0A%09%09%7D%2C%0D%0A%09%09%7B%0D%0A%09%09%09%22DirectoryNumber%22%3A%2211010055%22%2C%0D%0A%09%09%09%22Enabled%22%3A%22False%22%2C%0D%0A%09%09%09%22Number%22%3A%2238598225559%22%0D%0A%09%09%7D%0D%0A%09%5D%0D%0A%7D"
#

sub PUT{
    my ($self, $request, $response) = @_ ;
	$self->_Init($request);
	my $Home              = $self->{ConfigObject}->Get('MetaswitchRESTapiUmbossHome');
	my $DirectoryNumber = $request->param('DirectoryNumber');
	my @OrderConfParam = @{$self->{ConfigObject}->Get('MetaswitchRESTapiParamConfOrder')};
	my @ConfigData;
	my $SequenceNumber;
	my $ServiceIndication = $request->param('ServiceIndication') || 'Meta_Subscriber_BaseInformation';
	my $OriginHost = $self->{ConfigObject}->Get('MetaswitchRESTapiOriginHost') || 'user@domain?clientVersion=7.3';

	if (! $self->_Auth($request)){
		$response->data()->{'MetaswitchAuthError'} = $self->{AuthError};
		return Apache2::Const::HTTP_OK ;
	}

	my $JSONInput = $request->param('ConfData');
	
	$request->requestedFormat($request->param('fmt') || $self->{ConfigObject}->Get('MetaswitchRESTapiWriter') || 'json') ;

	
	if ($JSONInput){
		#$JSONInput = $Kernel::OM->Get('Kernel::System::JSON')->Decode(Data => $JSONInput);
		my $d = JSON->new->utf8;
		my $data = $d->decode($JSONInput);
		#my $data = $Kernel::OM->Get('Kernel::System::JSON')->Decode(Data => $JSONInput);
		
		#for $ServiceIndication (keys %{$data}){
		my @Tmp;
		for my $ServiceIndication1 (@OrderConfParam){
			if (!$data->{$ServiceIndication1}){
				next;
			}
			my @ServiceIndications;
			if (ref ($data->{$ServiceIndication1}) eq "ARRAY") {
				push (@ServiceIndications, @{$data->{$ServiceIndication1}});
			} else {
				push (@ServiceIndications, $data->{$ServiceIndication1});
			}
			@Tmp = @ServiceIndications;
			for my $data (@ServiceIndications) {
				if ($data->{DirectoryNumber}){
					$DirectoryNumber = $data->{DirectoryNumber};
				}
				if ($data->{UserIdentity}){
					$DirectoryNumber = $data->{UserIdentity};
				}
				my @Keys = @{$self->{ConfigObject}->Get('MetaswitchRESTapiPOSTfields')->{$ServiceIndication1}};
				my @InputParams;
				my %Param = $self->_AddParam($data);
				push (@InputParams, keys %Param);
				push (@ConfigData, {
					DirectoryNumber => $DirectoryNumber,
					ServiceIndication => $ServiceIndication1,
					Keys => \@Keys,
					InputParams => \@InputParams,
					Param => \%Param
				});
			}
		}
		
		#$response->data()->{'Param'} = "$JSONInput:" . join(",",%{$data}) ;
		#return Apache2::Const::HTTP_OK ;
	} else {
		my @Keys = @{$self->{ConfigObject}->Get('MetaswitchRESTapiPOSTfields')->{$ServiceIndication}};
		my @InputParams = $request->param();
		my %Param;
		for my $Item (@InputParams) {
			if ($request->param($Item)){
				$Param{$Item} = $request->param($Item);
			}
		}
		
		for my $Item (@Keys) {
			if (index ($request->param($Item),$Item) == 0){
				if ($Item eq "DirectoryNumber"){ next;}
				if ($Item eq "UserIdentity"){ next;}
				if ($Item eq "ServiceIndication"){ next;}
				$Param{$Item} = $request->param($Item);
			}
		}
		push (@ConfigData, {
			ServiceIndication => $ServiceIndication,
			Keys => \@Keys,
			InputParams => \@InputParams,
			Param => \%Param
		});
	}
		
	for my $Conf (@ConfigData){
		my @Keys = @{$Conf->{Keys}};
		my @InputParams = @{$Conf->{InputParams}};
		my %Param = %{$Conf->{Param}};
		$ServiceIndication = $Conf->{ServiceIndication};
		if ($Conf->{DirectoryNumber}){
			$DirectoryNumber = $Conf->{DirectoryNumber};
		}		
	
	# GET SequenceNumber	
		
		my $messageGET = $self->{LayoutObject}->Output(
			TemplateFile => "GET",
			Data => {
				UserIdentity => $DirectoryNumber,
				ServiceIndication => $ServiceIndication,
				OriginHost => $OriginHost,
				EASon => $self->{EASon}
			}
		);
		my $userAgentGET = LWP::UserAgent->new();
		my $requestLWPGET = HTTP::Request->new(POST => $self->{ConfigObject}->Get('MetaswitchRESTapiServiceURL' . $self->{EASon}));
		$requestLWPGET->header(
			%{ $self->{ConfigObject}->Get('MetaswitchRESTapiLWPrequestHeader' . $self->{EASon}) }
		);
		$requestLWPGET->content($messageGET);
		$requestLWPGET->content_type($self->{ConfigObject}->Get('MetaswitchRESTapiContentType') || "text/xml; charset=utf-8");
		
		my $responseLWPGET = $userAgentGET->request($requestLWPGET);
		if($responseLWPGET->code == 200) {
			#$response->data()->{'MetaswitchAPI'} = $responseLWP->decoded_content;
			my $XML = $responseLWPGET->decoded_content;
			$XML =~ s/\w+\://ig;
			my $xs = XML::Simple->new();
			my $ref = $xs->XMLin($XML);
			if ($ref->{"Body"}->{"ShPullResponse"}->{"ResultCode"} eq "2001") { 
				$SequenceNumber = $ref->{"Body"}->{"ShPullResponse"}->{"UserData"}->{"Sh-Data"}->{"RepositoryData"}->{"SequenceNumber"};
			} else {
				if ($self->{ConfigObject}->Get('MetaswitchRESTapiPUTmethodOvrideWithPOST')){
					$SequenceNumber = -1;
				} else {
					$response->data()->{'MetaswitchAPI'} = $ref->{"Body"}->{"ShPullResponse"};
					return Apache2::Const::HTTP_OK ;
				}
			}
			#$response->data()->{'MetaswitchAPI'} = $ref;
		} else {
			$response->data()->{'MetaswitchAPI'} = $response->status_line;
			return Apache2::Const::HTTP_OK ;
		}
	#return Apache2::Const::HTTP_OK ;

		
		
		$SequenceNumber++;
		my $MaxSequenceNumber = $self->{ConfigObject}->Get('MetaswitchRESTapiMaxSequenceNumber') || 65535;
		if ( $SequenceNumber>=$MaxSequenceNumber ){
			$SequenceNumber = 1;
		}
	
	# END SequenceNumber	
	
			
		
		for my $Item1 (@Keys){
			my $Item;
			my $Flag=0;

			for my $InputItem (@InputParams) {
				my $Tmp;
				($Tmp, undef) = split(/\./,$InputItem);
				if ($Item1 eq $Tmp) {
					$Item = $InputItem;
					$Flag=1;
					last;
				}
			}
			if (!$Flag) {next;}
			if (index($Item,".")>-1) {
				my @List = split(/\./,$Item);
				my $IN="";
				my $OUT="";
				my $ItemConf;
				if ($List[0] eq "RoutingAttributes") {
					for my $Tmp (keys %{$self->{ConfigObject}->Get('MetaswitchRESTapiItemConf')}) {
						if ($self->{ConfigObject}->Get('MetaswitchRESTapiItemConf')->{$Tmp}->{Name} eq $List[0]){
							$ItemConf = $self->{ConfigObject}->Get('MetaswitchRESTapiItemConf')->{$Tmp};
						}
					}
					my $Data = $ItemConf->{Data};
					if ($Param{$List[0] . ".UseDefault"}) {
						$Data->{UseDefault} = $Param{$List[0] . ".UseDefault"};
					}
					if ($Param{$List[0] . ".Pre-paidOff-switchCallingCardSubscriber.Default"}) {
						$Data->{Pre_paidOff_switchCallingCardSubscriber}->{Default} = $Param{$List[0] . ".Pre-paidOff-switchCallingCardSubscriber.Default"};
					}
					if ($Param{$List[0] . ".Pre-paidOff-switchCallingCardSubscriber.Value"}) {
						$Data->{Pre_paidOff_switchCallingCardSubscriber}->{Value} = $Param{$List[0] . ".Pre-paidOff-switchCallingCardSubscriber.Value"};
					}
					
					if ($Param{$List[0] . ".FaxModemSubscriber.Default"}) {
						$Data->{FaxModemSubscriber}->{Default} = $Param{$List[0] . ".FaxModemSubscriber.Default"};
					}
					if ($Param{$List[0] . ".FaxModemSubscriber.Value"}) {
						$Data->{FaxModemSubscriber}->{Value} = $Param{$List[0] . ".FaxModemSubscriber.Value"};
					}
					
					if ($Param{$List[0] . ".NomadicSubscriber.Default"}) {
						$Data->{NomadicSubscriber}->{Default} = $Param{$List[0] . ".NomadicSubscriber.Default"};
					}
					if ($Param{$List[0] . ".NomadicSubscriber.Value"}) {
						$Data->{NomadicSubscriber}->{Value} = $Param{$List[0] . ".NomadicSubscriber.Value"};
					}
					$self->{LayoutObject}->Block(
						Name => "ItemBlock",
						Data => {
							ItemName => $List[0],
							TYPETYPE => "AAAA",
							EASon => $self->{EASon},
							%{$Data}
						}
					);
				} else {
					for my $Tmp (keys %{$self->{ConfigObject}->Get('MetaswitchRESTapiItemConf')}) {
						if (
							$self->{ConfigObject}->Get('MetaswitchRESTapiItemConf')->{$Tmp}->{Name} eq $List[0]
							&&
							$self->{ConfigObject}->Get('MetaswitchRESTapiItemConf')->{$Tmp}->{ServiceIndication} eq $ServiceIndication
							){
							$ItemConf = $self->{ConfigObject}->Get('MetaswitchRESTapiItemConf')->{$Tmp};
							last;
						}
						if (
							$self->{ConfigObject}->Get('MetaswitchRESTapiItemConf')->{$Tmp}->{Name} eq $List[0]
							&& !$self->{ConfigObject}->Get('MetaswitchRESTapiItemConf')->{$Tmp}->{ServiceIndication}
							){
							$ItemConf = $self->{ConfigObject}->Get('MetaswitchRESTapiItemConf')->{$Tmp};
						}
					}
					for my $Temp (@{$ItemConf->{IN}}) {
						if ($Param{$List[0] . "." . $Temp->{Name}}) {
							$Temp->{Value} = $Param{$List[0] . "." . $Temp->{Name}};
							delete $Param{$List[0] . "." . $Temp->{Name}};
						}
						$IN .= " " . $Temp->{Name} . '="' . $Temp->{Value} . '"';
					}
					for my $Temp (@{$ItemConf->{OUT}}) {
						if (ref ($Temp->{Value}) eq "ARRAY"){
							$OUT .= "<ser:" . $Temp->{Name} . '>';
							for my $Temp1 (@{$Temp->{Value}}){
								if ($Param{$List[0] . "." . $Temp->{Name} . "." . $Temp1->{Name}}) {
									$Temp1->{Value} = $Param{$List[0] . "." . $Temp->{Name} . "." . $Temp1->{Name}};
									delete $Param{$List[0] . "." . $Temp->{Name} . "." . $Temp1->{Name}};
								}
								$OUT .= "<ser:" . $Temp1->{Name} . '>' . $Temp1->{Value} . '</ser:' . $Temp1->{Name} . '>';
							}
							$OUT .= '</ser:' . $Temp->{Name} . '>';
						} else {
							if ($Param{$List[0] . "." . $Temp->{Name}}) {
								$Temp->{Value} = $Param{$List[0] . "." . $Temp->{Name}};
								delete $Param{$List[0] . "." . $Temp->{Name}};
							}
							$OUT .= "<ser:" . $Temp->{Name} . '>' . $Temp->{Value} . '</ser:' . $Temp->{Name} . '>';
						}
					}
					$self->{LayoutObject}->Block(
						Name => "ItemBlock",
						Data => {
							ItemName => $List[0],
							INdata => $IN,
							OUTdata => $OUT,
							TYPETYPE => "Hash",
							ServiceIndication => $ServiceIndication,
							EASon => $self->{EASon}
						}
					);	
				}				
			} elsif ($Param{$Item}) {
				$self->{LayoutObject}->Block(
					Name => "ItemBlock",
					Data => {
						ItemName => $Item,
						ItemValue => $Param{$Item},
						TYPETYPE => "Value",
						ServiceIndication => $ServiceIndication,
						EASon => $self->{EASon}
					}
				);
			}
		}
		my $message = $self->{LayoutObject}->Output(
			TemplateFile => "PUT",
			Data => {
				DirectoryNumber => $DirectoryNumber,
				SequenceNumber => $SequenceNumber,
				ServiceIndication => $ServiceIndication,
				OriginHost => $OriginHost,
				EASon => $self->{EASon}
			}
		);

		$response->data()->{'SOAPXML'} = $message;
		#return Apache2::Const::HTTP_OK ;
		
		my $userAgent = LWP::UserAgent->new();
		my $requestLWP = HTTP::Request->new(POST => $self->{ConfigObject}->Get('MetaswitchRESTapiServiceURL' . $self->{EASon}));
		$requestLWP->header(
			%{ $self->{ConfigObject}->Get('MetaswitchRESTapiLWPrequestHeader' . $self->{EASon}) }
		);
		$message = encode('UTF-8', $message);
		$requestLWP->content_type($self->{ConfigObject}->Get('MetaswitchRESTapiContentType') || "text/xml; charset=utf-8");
		$requestLWP->content($message);
		
		my $responseLWP = $userAgent->request($requestLWP);
		if($responseLWP->code == 200) {
			#$response->data()->{'MetaswitchAPI'} = $responseLWP->decoded_content;
			my $XML = $responseLWP->decoded_content;
			$XML =~ s/\w+\://ig;
			my $xs = XML::Simple->new();
			my $ref = $xs->XMLin($XML);
			if ($ref->{"Body"}->{"ShUpdateResponse"}->{"ResultCode"} eq "2001") { 
				$response->data()->{$ServiceIndication} = $ref->{"Body"}->{"ShUpdateResponse"};
			} else {
				$response->data()->{$ServiceIndication} = $ref->{"Body"}->{"ShUpdateResponse"};
			}
			#$response->data()->{'MetaswitchAPI'} = $ref;
			#$response->data()->{'XML'} = $message ;
		} else {
			$response->data()->{$ServiceIndication} = $response->status_line;
		}
	}
	
    #$response->data()->{'api_mess'} = 'Hello, this is MyApp REST API' ;
	#$response->data()->{'Umboss Home'} = $Home ;
	#$response->data()->{'XMLmessage'} = $message ;
    return Apache2::Const::HTTP_OK ;
}


# Authorize the methods.
sub isAuth{
   my ($self, $method, $req) = @ _; 
   return $method =~ 'GET|PUT|POST|DELETE';
}

sub _AddParam{
	my ($self, $Data, $KeyRoot) = @ _; 
	my %Hash=();
	
	for my $Key (keys %{$Data}){
		my $KeyTemp;
		if (! $KeyRoot){
			$KeyTemp = $Key;
		} else {
			$KeyTemp = $KeyRoot . "." . $Key;
		}
		if (ref ($Data->{$Key}) eq "HASH"){
			my %Tmp = $self->_AddParam($Data->{$Key}, $KeyTemp);
			%Hash = ( %Hash, %Tmp );
		} else {
			$Hash{$KeyTemp} = $Data->{$Key};
		}
	}
	return %Hash;
}


1;

__END__

=head1 NAME

Metaswitch::REST - Metaswitch API proxy REST to SOAP/CORBA

=head1 VERSION

This documentation refers to Metaswitch::REST version 0.1.

=over 4

=back



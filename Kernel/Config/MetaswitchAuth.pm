# Metaswitch API Auth config file
# VERSION:1.1
package Kernel::Config::Files::MetaswitchAuth;
use strict;
use warnings;
no warnings 'redefine';
use utf8;
sub Load {
    my ($File, $Self) = @_;
#
#
#
# {"UserIdentity":"11010061","ServiceIndication":["Msph_Subscriber_BaseInformation","Msph_Subscriber_BusinessGroup","Meta_Subscriber_BaseInformation"]}
# curl "http://192.168.210.33/MetaswitchREST/?Token=%26%2F%28%26%2F%26ZFGCfsdfhjshf131958425783756%27%27%5C&Username=testuser&EASon=1&GetData=%7B%22UserIdentity%22%3A%2211010061%22%2C%22ServiceIndication%22%3A%5B%22Msph_Subscriber_BaseInformation%22%2C%22Msph_Subscriber_BusinessGroup%22%2C%22Meta_Subscriber_BaseInformation%22%5D%7D"
#
# Username and Token input fields for Authentication.
#
	$Self->{'MetaswitchAuthOn'} = 0;   # On/Off this functionality


	
	### Defining user and token map for auth.
	$Self->{'MetaswitchAuth'} = {
		testuser => {
			token => "&/(&/&ZFGCfsdfhjshf131958425783756\'\'\\",  # URL encode %26%2F%28%26%2F%26ZFGCfsdfhjshf131958425783756%27%27%5C
		},
		bpm => {
			token => "bpmTest"
		},
	};
}
1;

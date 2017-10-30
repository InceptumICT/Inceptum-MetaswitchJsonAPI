# Metaswitch API config file
# VERSION:1.1
package Kernel::Config::Files::MetaswitchRESTapi;
use strict;
use warnings;
no warnings 'redefine';
use utf8;
use MIME::Base64;
sub Load {
    my ($File, $Self) = @_;
	$Self->{'MetaswitchRESTapiWriter'} = 'json';
	$Self->{'MetaswitchRESTapiOriginHost'} = 'user@domain?clientVersion=7.3';
	$Self->{'MetaswitchRESTapiContentType'} = 'text/xml;charset=UTF-8';
	$Self->{'MetaswitchRESTapiMaxSequenceNumber'} = 65535;
	$Self->{'MetaswitchRESTapiPUTmethodOvrideWithPOST'} = 1;  # Calculate Sequence number to avoid POST method unique errors; 0 or "" or undefined -off, any-on
	$Self->{'MetaswitchRESTapiPOSTlikePUT'} = 1;  # POST method like PUT method. Avoiding uniqueness of POST method; 0 or "" or undefined -off, any-on
	$Self->{'MetaswitchRESTapiServiceURL'} = 'http://mvs.sandbox.innovators.metaswitch.com:8080/services/ShService';  ### Without EAS
	#$Self->{'MetaswitchRESTapiServiceURLEAS'} = 'http://sasap:Sa5amt!@mvs.sandbox.innovators.metaswitch.com:8087/mvweb/services/ShService'; # user and password in url
	$Self->{'MetaswitchRESTapiServiceURLEAS'} = 'http://mvs.sandbox.innovators.metaswitch.com:8087/mvweb/services/ShService'; # user and password not in url
	$Self->{'MetaswitchRESTapiServiceEAS'} = 'EAS'; # 'EAS'-EAS, ''-CFS
	$Self->{'MetaswitchRESTapiLWPrequestHeader'} =  {
		'Accept-Encoding' => 'gzip,deflate',
		'Content-Type' => 'text/xml;charset=UTF-8',
		'SOAPAction' => 'http://www.metaswitch.com/ems/soap/sh#ShPull',
		'User-Agent' => 'Apache-HttpClient/4.1.1 (java 1.5)'
	};
	$Self->{'MetaswitchRESTapiLWPrequestHeaderEAS'} =  {
        'Accept-Encoding' => 'gzip,deflate',
        'Content-Type' => 'text/xml;charset=UTF-8',
        'SOAPAction' => 'http://www.metaswitch.com/ems/soap/sh#ShPull',
        'User-Agent' => 'Apache-HttpClient/4.1.1 (java 1.5)',
        #'Authorization' => 'Basic c2FzYXA6U2E1YW10IQ==',							# preencoded Auth
		'Authorization' => "Basic " . MIME::Base64::encode("sasap:Sa5amt!", ""),	# encoding user and pass fro Basic Auth
	};
	# Home folder
	$Self->{'MetaswitchRESTapiUmbossHome'} =  '/usr/local/umboss/';
# POST method which are unique. POST is not overridden with PUT.	
	$Self->{'MetaswitchRESTapiPOSTuniqueMethods'} = [
		"Meta_Subscriber_BaseInformation",
		"Meta_BusinessGroup_BaseInformation",
		"Meta_BGNumberBlock_BaseInformation",
		"Meta_ConfiguredSIPBinding_BaseInformation",
		"Meta_PBX_BaseInformation",
		"Meta_CallPickupGroup_BaseInformation",
		"Meta_Department_BaseInformation",
		"Meta_MLHG_BaseInformation",
		"Meta_MLHGPilotDN_BaseInformation",
		"Meta_MLHGPilotDN_TerminatingService",
		"Msph_Subscriber_BaseInformation",
	];
	
	$Self->{'MetaswitchRESTapiParamConfOrder'} = [
#
#
## CFS objects
#
#
## Server 
		"Meta_ServerGroup_BaseInformation",
## Department
		"Meta_Department_BaseInformation",
## Subscriber
		"Meta_BusinessGroup_BaseInformation",
		"Meta_BGNumberBlock_BaseInformation",
		"Meta_Subscriber_BaseInformation",
		"Meta_Subscriber_CallForwardingServices",
		"Meta_Subscriber_BusyCallForwarding",
		"Meta_Subscriber_UnconditionalCallForwarding",
		"Meta_Subscriber_DelayedCallForwarding",
		"Meta_Subscriber_UnavailableCallForwarding",
		"Meta_Subscriber_SelectiveCallForwarding", "Meta_Subscriber_SelectiveCallForwarding_NumbersList",
		"Meta_Subscriber_CallPickup",
		"Meta_Subscriber_DirectedPickupNoBarge-in",
		"Meta_Subscriber_DoNotDisturb", "Meta_Subscriber_DoNotDisturb_SCANumbersList", 
		"Meta_Subscriber_AnonymousCallRejection",
		"Meta_Subscriber_AutomaticCallback",
		"Meta_Subscriber_AutomaticRecall",
		"Meta_Subscriber_LineHunting",
		"Meta_Subscriber_CallBarring",
		"Meta_Subscriber_CallListsService",
		"Meta_Subscriber_CallTransfer",
		"Meta_Subscriber_3-WayCalling", "Meta_Subscriber_3-WayCallingCallTransferBilling",
		"Meta_Subscriber_CallTrace",
		"Meta_Subscriber_CallingNameAndNumberDeliveryOverIP",
		"Meta_Subscriber_CallerIDPresentation",
		"Meta_Subscriber_CallingNameDelivery",
		"Meta_Subscriber_CallingNumberDelivery",
		"Meta_Subscriber_CallingNumberDeliveryBlocking",
		"Meta_Subscriber_HighRiskCallLimits",
		"Meta_Subscriber_LastCallerIDErasure",
		"Meta_Subscriber_LineStateMonitoring",
		"Meta_Subscriber_MandatoryAccountCodes",
		"Meta_Subscriber_PINChange",
		"Meta_Subscriber_PriorityCall","Meta_Subscriber_PriorityCall_NumbersList",
		"Meta_Subscriber_SelectiveCallRejection", "Meta_Subscriber_SelectiveCallRejection_NumbersList",
		"Meta_Subscriber_SpeedCalling", "Meta_Subscriber_SpeedCalling_NumbersList",
		"Meta_Subscriber_Voicemail",
		"Meta_Subscriber_LineClassCodes",
		"Meta_BusinessGroup_ChildrenList_Department", "Meta_Department_DepartmentCallLimits",
## SIP binding
		"Meta_ConfiguredSIPBinding_BaseInformation",
		"Meta_ConfiguredSIPBinding_CustomerInformation",
## PBX
		"Meta_PBX_BaseInformation", "Meta_PBX_BusinessGroup", "Meta_PBX_LinesList", "Meta_PBX_DirectInwardCalling", 
		"Meta_PBXDIDNumber_BaseInformation", "Meta_PBXDIDNumber_UnavailableCallForwarding", "Meta_PBXDIDNumber_UnconditionalCallForwarding",
		"Meta_PBXDIDNumber_RecordingService",
		"Meta_PBX_AnonymousCallRejection",
		"Meta_PBX_LineHunting",
		"Meta_PBX_CallBarring",
		"Meta_PBX_CallTrace",
		"Meta_PBX_CallTransfer", "Meta_PBX_3-WayCallingCallTransferBilling",
		"Meta_PBX_CallerIDPresentation", "Meta_PBX_CallingNameAndNumberDeliveryOverIP",
		"Meta_PBX_CallingNameDelivery",
		"Meta_PBX_CallingNumberDelivery", "Meta_PBX_CallingNumberDeliveryBlocking",
		"Meta_PBX_CallForwardingServices", "Meta_PBX_UnconditionalCallForwarding", "Meta_PBX_BusyCallForwarding",
		"Meta_PBX_DelayedCallForwarding", "Meta_PBX_SelectiveCallForwarding","Meta_PBX_SelectiveCallForwarding_NumbersList",
		"Meta_PBX_UnavailableCallForwarding", "Meta_PBX_DoNotDisturb", "Meta_PBX_DoNotDisturb_SCANumbersList",
		"Meta_PBX_HighRiskCallLimits", "Meta_PBX_MandatoryAccountCodes",
		"Meta_PBX_PINChange",
		"Meta_PBX_SelectiveCallRejection", "Meta_PBX_SelectiveCallRejection_NumbersList",
		"Meta_PBX_SpeedCalling", "Meta_PBX_SpeedCalling_NumbersList",
		"Meta_PBX_Voicemail",
		"Meta_PBX_LineClassCodes",
## Call Pickup Groups
		"Meta_CallPickupGroup_BaseInformation", "Meta_CallPickupGroup_MembersList", "Meta_CallPickupGroup_PossibleMembersList",
## MLHGName
		"Meta_MLHG_BaseInformation", "Meta_MLHG_MembersList",
		"Meta_MLHGPilotDN_BaseInformation", "Meta_MLHGPilotDN_TerminatingService",
#
#
## EAS objects
#
#
		"Msph_Subscriber_BaseInformation",
		"Msph_Subscriber_BusinessGroup",
	];
	$Self->{'MetaswitchRESTapiPOSTfields'} = {
		"Meta_ServerGroup_BaseInformation" => ["MetaSphereServerGroupName", "MetaSphereServerGroupType", "ClusterName"],
		"Meta_Department_BaseInformation" => ["Name", "FullName", "ParentDepartment"],
		"Meta_Department_DepartmentCallLimits" => [
"ExternalCallsSupport", "MaximumExternalCalls", "TerminatingCallsSupport", "MaximumTerminatingCalls", "OriginatingCallsSupport",
"MaximumOriginatingCalls"
		],
		"Meta_BusinessGroup_ChildrenList_Department" => ["Department"],
		"Meta_Subscriber_BaseInformation" => [
'NetworkElementName', 'MetaSwitchName',
'BusinessGroupName', 'MLHGName', 'SiteName', 'ClusterName',
'SubscriberType', 'DirectoryNumber', 'TeenServiceLine',
'PresentationNumber', 'ChargeNumber', 'CallingPartyNumber',
'Department', 'DelegatedManagementGroup', 'PersistentProfile',
'IntercomDialingCode', 'AllowDirectDialing',
'TwinnedWithAPBXDIDNumber', 'NumberBlockDeviceTwinning',
'InUseBy', 'SubscriberGroup', 'SubscriberGroupBusLine',
'PrimaryLineDirectoryNumberRO', 'RingPatternRO', 'RingCadenceRO',
'NumberStatus', 'RecentlyMovedFromOldNumber',
'MovedFromDirectoryNumber', 'ConnectCallAfterAnnouncement',
'MovedToDirectoryNumber', 'MovedToNumberAsDialed', 'MovedDate',
'ExpireAfter', 'ExpiryDate', 'PortedExchangeID', 'SignalingType',
'CallAgentSignalingType', 'NoUserEquipment',
'FlashHookCallServicesProvidedBy', 'AccessDevice',
'AccessLineNumber', 'ISDNInterface',
'CascadeFaultMonitoringLevelOnApply',
'ISDNDefaultBearerCapabilities',
'CallingNumberPrecedenceForEmergencyCalls', 'PBXIsDuplicate',
'DeliverISDNUserProvidedNumberOnEmergencyCall',
'UseDNForIdentification', 'SIPUserName', 'SIPDomainName',
'AuthenticationUsernameIncludesDomain',
'MaximumSimultaneousRegistrations',
'CurrentNumberOfRegistrations', 'AccessionClientOnly',
'SubMediaGatewayModel', 'UseStaticNATMapping',
'SIPRegistrationStatus', 'SIPAuthenticationRequired',
'NewSIPPassword', 'ConfirmNewSIPPassword', 'SIPPassword',
'NetworkNode', 'PreferredLocationOfTrunkGateway',
'ESAProtectionDomain', 'MaximumCallAppearances',
'MaximumPermittedContactRefreshInterval', 'SignalFunctionCode',
'LineUsage', 'GR303NailedUpConnection', 'PreSubscribedConnection',
'GR303DialType', 'FSKFormat', 'LongDistanceCarrier',
'IntraLATACarrier', 'InternationalCarrier', 'PIN', 'Locale',
'SecondLocale', 'BillingType', 'AdviceOfChargeAOCD',
'AdviceOfChargeAOCE', 'RoutingAttributes',
'DenyAllUsageSensitiveFeatures',
'LineSideAnswerSupervisionSupported', 'ServiceSuspended',
'ServiceSuspendedBusGrpLine', 'DigitMaskingRequired',
'TariffGroup', 'OriginatingFacilityMarksDisabled',
'OriginatingFacilityMarksAttendedCallOffice',
'OriginatingFacilityMarksADC',
'TerminatingFacilityMarksServiceInterception',
'TerminatingFacilityMarksFixedDestinationService',
'ForceLNPLookup', 'Timezone', 'AdjustForDaylightSavings',
'SubscriberTimezone', 'LineTrafficStudy', 'EnabledDate',
'PresentPilotNameToAgents', 'BusinessGroupLinePrivileges',
'PayphoneMetering', 'ChargeIndication',
'SubscriberCallingCategory', 'NetworkDisconnectSignalDuration',
'AllowRehoming', 'PreferredSite', 'SASHostname'		
		],
		"Meta_Subscriber_BusyCallForwarding" => [
'Subscribed', 'Variant',
'Enabled', 'Number', 'UnconditionalBusyAndDelayCallForwardingUsageSensitiveBilling',
		],
		"Meta_BusinessGroup_BaseInformation" => [
'NetworkElementName', 'MetaSwitchName', 'SiteName', 'ClusterName', 'BusinessGroupName',
'NetworkWideBusinessGroupID', 'DelegatedManagementGroup', 'PersistentProfile',
'SyncWithProfileInProgress', 'NetworkNode', 'LocalCNAMName', 'LongDistanceCarrier',
'IntraLATACarrier', 'InternationalCarrier', 'Locale', 'SecondLocale', 'BillingType',
'BillingTypeIntercomCalls', 'RoutingAttributes', 'BusinessGroupForcedOffSwitchRouting',
'DenyAllUsageSensitiveFeatures', 'DistinctiveAlerting', 'ServiceSuspended', 'NumberOfDirectoryNumbers',
'NumberOfFreeDirectoryNumbers', 'NumberOfManagedDevices', 'EnableAdvancedAlertingFeatures',
'DefaultESAProtectionDomainForSIPSubscribers', 'BusinessGroupTrafficStudy', 'SendAdvancedSIPMessagesToServiceAssuranceServer',
'BusinessGroupCallLogsEnabled', 'AllowBGAdminChangeExpMod', 'BusinessGroupPrefixCallerIDWithExternalLineCodeIfPresent',
'BusinessGroupLinesSharePresence', 'DefaultBusinessGroupLinePrivileges', 'SubscriberGroupForNonReservedNumbers',
'AllowRehoming', 'PreferredSite', 'VQMCallLogging',
'SwitchsUniqueBGID', 'SASHostname', 'CreationTimestamp', 'FeaturesSupportedFlags'
		],
		"Meta_BGNumberBlock_BaseInformation" => [
"NetworkElementName", "MetaSwitchName", "BusinessGroupName", "DeviceTwinning",
"BlockSize", "FirstDirectoryNumber", "LastDirectoryNumber", "SubscriberGroup",
"NumberOfAssignedDirectoryNumbers",
		],
		"Meta_Subscriber_UnconditionalCallForwarding" => [
"Subscribed", "Variant", "Enabled", "Number", "SingleRing",
"UnconditionalBusyAndDelayCallForwardingUsageSensitiveBilling",
		],
		"Meta_Subscriber_DelayedCallForwarding" => [
"Subscribed", "Variant", "Enabled", "Number", "NoReplyTime",
"UnconditionalBusyAndDelayCallForwardingUsageSensitiveBilling",
		],
		"Meta_Subscriber_UnavailableCallForwarding" => [
"Subscribed", "Enabled", "Number",
		],
		"Meta_Subscriber_SelectiveCallForwarding" => [
"Subscribed", "Variant", "Enabled", "NumberToForwardTo", "SingleRing",
"NumberOfAnonymousNumbersForwarded",  "UsageSensitiveBilling",
		],
		"Meta_Subscriber_CallForwardingServices" => [
		"MaximumSimultaneousForwardings", "UserNotificationOfCallDiversion",
		"DeliverRedirectingNumberAsCallingNumber", "NumberReleasedToDivertedToUser",
		"NumberReleasedToCaller", "DivertedToNumberReleasedToCaller",
		"RequireCourtesyCall", "PlayConfirmTone",
		],
		"Meta_Subscriber_CallPickup" => ["Subscribed"],
		"Meta_Subscriber_DirectedPickupNoBarge-in" => ["DirectedPickupNoBargeInSubscribed"],
		"Meta_Subscriber_DoNotDisturb" => [
"Subscribed", "Enabled", "ServiceLevel", "SingleRing", "IntegratedDND",
"SelectiveCallAcceptanceNumberOfAnonymousNumbers", "SelectiveCallAcceptanceUsageSensitiveBilling",
		],
		"Meta_Subscriber_AnonymousCallRejection" => ["Subscribed", "Enabled", "UsageSensitiveBilling"],
		"Meta_Subscriber_AutomaticCallback" => ["Subscribed", "UsageSensitiveBilling"],
		"Meta_Subscriber_AutomaticRecall" => ["Subscribed", "UsageSensitiveBilling"],
		"Meta_Subscriber_LineHunting" => ["Subscribed", "Enabled", "NoReplyTime", "Arrangement"],
		"Meta_Subscriber_CallBarring" => [
"Subscribed", "UsageSensitiveBilling", "CurrentSubscriberBarredCallTypes","CurrentBarredCallTypes",
"CurrentOperatorBarredCallTypes"
		],
		"Meta_Subscriber_CallListsService" => ["Subscribed", "MaximumNumberOfCallsPerList"],
		"Meta_Subscriber_3-WayCallingCallTransferBilling" => ["TWCCTConfUsageSensitiveBilling"],
		"Meta_Subscriber_3-WayCalling" => ["Subscribed"],
		"Meta_Subscriber_CallTransfer" => ["Subscribed"],
		"Meta_Subscriber_CallTrace" => ["Subscribed", "UsageSensitiveBilling"],
		"Meta_Subscriber_CallerIDPresentation" => [
"Subscribed", "WithholdNumberByDefault", "NumberWithholdRejectionReason", "PresentNumberByDefault",
"WithholdDirectoryNumber", "AlwaysPresentNumberForIntercomCalls"
		],
		"Meta_Subscriber_CallingNameDelivery" => [
"Subscribed", "LocalName", "LocalNameBusLine", "UseLocalNameForIntercomCallsOnlyBusLine",
"Enabled", "UsageSensitiveBilling"
		],
		"Meta_Subscriber_CallingNumberDelivery" => [
"Subscribed", "Enabled", "UsageSensitiveBilling", "PreferredSIPFormat",
"OverridePrivacySettingOfCallingSubscriber"
		],
		"Meta_Subscriber_CallingNumberDeliveryBlocking" => ["Subscribed", "UsageSensitiveBilling"],
		"Meta_Subscriber_HighRiskCallLimits" => ["LimitType", "MaximumHighRiskCalls"],
		"Meta_Subscriber_LastCallerIDErasure" => ["Subscribed"],
		"Meta_Subscriber_LineStateMonitoring" => ["Subscribed", "MaximumNumberOfLines", "NumberOfLines", "MonitorDoNotDisturbStatus"],
		"Meta_Subscriber_MandatoryAccountCodes" => [
"Subscribed", "Variant", "USCallTypes_Old", "USCallTypes", "UKCallTypes",
"InheritCodesAndCodeLength", "CodeLength", "MaxIncorrectCodeAttemptsPerCall",
"MaxIncorrectCodeAttempts", "Blocked", "ValidAccountCodes"
		],
		"Meta_Subscriber_PINChange" => ["Subscribed"],
		"Meta_Subscriber_PriorityCall" => ["Subscribed", "Enabled", "NumberOfAnonymousNumbers", "UsageSensitiveBilling"],
		"Meta_Subscriber_PriorityCall_NumbersList" => ["Number"],
		"Meta_Subscriber_SelectiveCallRejection" => ["Subscribed", "Enabled", "NumberOfAnonymousNumbers", "UsageSensitiveBilling"],
		"Meta_Subscriber_SelectiveCallRejection_NumbersList" => ["Number"],
		"Meta_Subscriber_SpeedCalling" => ["Subscribed", "AllowedTypes", "HandsetAccessAllowed"],
		"Meta_Subscriber_SpeedCalling_NumbersList" => ["Number"],
		"Meta_Subscriber_Voicemail" => [
"SharePrimaryLineVoicemailMailbox", "Subscribed", "CallDeliveryMethod", "VoicemailSystemLineGroup",
"IncomingNumber", "ApplicationServer", "IndicatorNotificationMethod", "SMDILink", "AuthorizedIDForIndicatorControl",
"IndicatorNotificationApplicationServer", "VisualMessageWaitingIndicator", "AudibleMessageWaitingIndicator",
"SIPMessageWaitingIndicator", "MessageWaitingIndicatorStatus", "CallTransferTime"
		],
		"Meta_ConfiguredSIPBinding_BaseInformation" => [
"NetworkElementName", "MetaSwitchName", "SiteName", "ClusterName", "Name", "DelegatedManagementGroup",
"Usage", "PBXApplicationServer", "LearnsContactDetails", "UseDNForIdentification", "SIPAuthenticationRequired",
"SIPUserName", "SIPDomainName", "SIPPassword", "NewSIPPassword", "ConfirmNewSIPPassword", "IPAddressMatchRequired",
"ContactURI", "ContactAddressScheme", "ContactIPAddress", "ICSCFContactIPAddress", "ContactIPPort",
"ICSCFContactIPPort", "AdditionalInboundContactIPAddresses", "NoDTMFHubIfNotTerminatingMedia", "MediaIPAddress",
"ContactName", "ContactExpiryTime", "ContactDomainName", "ICSCFContactDomainName", "SupportedPreferredMediaAddressFamilies",
"SupportedIncomingTrunkGroupParameterType", "TrunkGroupParameterTypeOnOutgoingMessages", "VirtualTrunkGroupID",
"VirtualTrunkContext", "ProxyAddressScheme", "ProxyIPAddress", "ProxyIPPort", "AdditionalInboundProxyIPAddresses",
"ProxyDomainName", "TransportProtocol", "SignalingType", "MediaGatewayModel", "UseMediaIPAddressForNetworkNodeAssignment",
"NetworkNode", "SIPBindingLocation", "ESAProtectionDomain", "CallFeatureServerControlStatus", "CallAgentControlStatus",
"Trusted", "UseCallerNameProvidedBySIPDevice", "PlayAnnouncementsWhenErrorConditionsOccur", "UseStaticNATMapping",
"MaximumCallAppearances", "MaximumConcurrentHighBandwidthCallAppearancesAllowed", "MaximumPermittedContactRefreshInterval",
"PollPeerDevice", "PollingInterval", "UseCustomSIPINVITEResponseTimeout", "SIPINVITEResponseTimeout", "AutomaticRecovery",
"AutomaticRecoveryInterval", "PollCallPaths", "ConcurrentNumberOfCallAppearancesInUse", "ConcurrentNumberOfHighBandwidthCallAppearancesInUse",
"SuppressRedirectionInformation", "ForceValidationOfRedirectionNumber", "PerformTranslationsOnRedirectedNumbers",
"SelectNewTrunkOn3xxResponse", "UseTrunkRoutingTablesToMatchTGID", "MaximumNumberOfUntranslatedRedirections",
"ReturnCodesPreventingCallRedirection", "SignalCallingPartyLATAOnOutboundRequests", "TransparentHeaders", "OutboundRouteHeaderUserPart",
"DeactivationMode", "PollServiceRoutes", "ServiceRoutePollingInterval"
		],
		"Meta_ConfiguredSIPBinding_CustomerInformation" => [
"CustInfo", "CustInfo2", "CustInfo3", "CustInfo4", "CustInfo5", "CustInfo6"
		],
		"Meta_PBX_BaseInformation" => [
"NetworkElementName", "MetaSwitchName", "SiteName", "ClusterName", "DirectoryNumber", "PresentationNumber", "ChargeNumberRequired",
"ChargeNumber", "CallingPartyNumber", "DelegatedManagementGroup", "PersistentProfile", "IntercomDialingCode", "DefaultNumberOfDIDDigits",
"UseConfiguredTrunkGroupID", "ApplicationServerPBX", "TrunkGroupID", "SubscriberGroup", "NumberStatus", "RecentlyMovedFromOldNumber",
"MovedFromDirectoryNumber", "ConnectCallAfterAnnouncement", "MovedToDirectoryNumber", "MovedToNumberAsDialed", "MovedDate",
"ExpireAfter", "ExpiryDate", "PortedExchangeID", "SignalingType", "CallAgentSignalingType", "LineSelectionMethod", "DialtoneSupported",
"RingbackSupported", "PBXFixBits", "ANIDNISFormat", "SendDIDSequenceForListedDirectoryNumber", "DNISUsedInDIDSequenceForListedDirectoryNumber",
"NumberOfPulsedDigits", "SupportsExtensionDialingBySuffixDigits", "SendDDIPrefixExtensionDialingBySuffixDigits",
"DDIPrefixForExtensionDialingBySuffixDigits", "UseNationalNumberingPlanOn10DigitCalls", "CallingNumberPrecedenceForEmergencyCalls",
"CallingNumberConnectedLineIDScreening", "CallingNumberScreening", "AdditionalCallingNumberScreeningForEmergencyCalls",
"TotalCallsLimit", "MaximumCalls", "TerminatingCallsLimit", "MaximumTerminatingCalls", "OriginatingCallsLimit", "MaximumOriginatingCalls",
"LimitIntraBGCalls", "PBXIsDuplicate", "PBXIsRenumbering", "DeliverISDNUserProvidedNumberOnEmergencyCall", "MaximumCallAppearances",
"LDNPBXCapacityGroup", "LongDistanceCarrier", "IntraLATACarrier", "InternationalCarrier", "PIN", "Locale", "SecondLocale", "BillingType",
"AdviceOfChargeAOCD", "AdviceOfChargeAOCE", "RoutingAttributes", "DenyAllUsageSensitiveFeatures", "ServiceSuspended", "DigitMaskingRequired",
"TariffGroup", "TerminatingFacilityMarksServiceInterception", "ForceLNPLookup", "Timezone", "AdjustForDaylightSavings", "SubscriberTimezone",
"LineTrafficStudy", "EnabledDate", "ChargeIndication", "SubscriberCallingCategory", "AllowRehoming", "PreferredSite",
"UsePBXSuppliedFailureReasonForUnsuccessfulCalls", "SASHostname", "IsIMS"
		],
		"Meta_PBX_BusinessGroup" => [
"BusinessGroup", "ExternalLineCode", "InternalLineCode", "StarReplacementForPulseDialing", "SimpleDigitMatchingAutomaticallyApplied",
"ForceSimpleMatching", "DiagnosticsLogCorrelator"
		],
		"Meta_PBX_LinesList" => ["Line"],
		"Meta_PBX_DirectInwardCalling" => ["DirectInwardCalling"], 
		"Meta_PBXDIDNumber_BaseInformation" => [
"NetworkElementName", "MetaSwitchName", "PBXDirectoryNumber", "SiteName", "ClusterName", "DirectoryNumber",
"DelegatedManagementGroup", "ParentPBXDirectoryNumber"
		],
		"Meta_PBXDIDNumber_UnavailableCallForwarding" => ["Enabled", "Number"],
		"Meta_PBXDIDNumber_UnconditionalCallForwarding" => ["Enabled", "Number"],
		"Meta_PBXDIDNumber_RecordingService" => ["Subscribed", "Enabled", "Server", "ServerWebInterfaceURL"],
		"Meta_PBX_AnonymousCallRejection" => ["Subscribed", "Enabled", "UsageSensitiveBilling"],
		"Meta_PBX_LineHunting" => ["Subscribed", "Enabled", "NoReplyTime", "Arrangement"],
		"Meta_PBX_CallBarring" => [
"Subscribed", "UsageSensitiveBilling", "CurrentSubscriberBarredCallTypes", "CurrentBarredCallTypes", "CurrentOperatorBarredCallTypes",
		],
		"Meta_PBX_CallTrace" => ["Subscribed", "UsageSensitiveBilling"],
		"Meta_PBX_CallTransfer" => ["Subscribed"],
		"Meta_PBX_3-WayCallingCallTransferBilling" => ["TWCCTConfUsageSensitiveBilling"],
		"Meta_PBX_CallerIDPresentation" => [
"Subscribed", "WithholdNumberByDefault", "NumberWithholdRejectionReason", "PresentNumberByDefault", 
"WithholdDirectoryNumber", "CIDIgnorePBXSigPrsnt"
		],
		"Meta_PBX_CallingNameAndNumberDeliveryOverIP" => ["Subscribed", "Enabled", "Destination"],
		"Meta_Subscriber_CallingNameAndNumberDeliveryOverIP" => ["Subscribed", "Enabled", "Destination"],
		"Meta_PBX_CallingNameDelivery" => ["Subscribed", "LocalName", "Enabled", "UsageSensitiveBilling"],
		"Meta_PBX_CallingNumberDelivery" => ["Subscribed", "Enabled", "UsageSensitiveBilling", "PreferredSIPFormat", "OverridePrivacySettingOfCallingSubscriber"],
		"Meta_PBX_CallingNumberDeliveryBlocking" => ["Subscribed", "UsageSensitiveBilling"],
		"Meta_PBX_CallForwardingServices" => [
"MaximumSimultaneousForwardings", "UserNotificationOfCallDiversion", "DeliverRedirectingNumberAsCallingNumber", "NumberReleasedToDivertedToUser",
"NumberReleasedToCaller", "DivertedToNumberReleasedToCaller", "RequireCourtesyCall", "PlayConfirmTone"
		],
		"Meta_PBX_UnconditionalCallForwarding" => [
"Subscribed", "UseValuesAsDefaultsOnDIDNumbers", "Variant", "Enabled", "Number", "SingleRing",
"UnconditionalBusyAndDelayCallForwardingUsageSensitiveBilling"
		],
		"Meta_PBX_BusyCallForwarding" => ["Subscribed", "Variant", "Number", "UnconditionalBusyAndDelayCallForwardingUsageSensitiveBilling"],
		"Meta_PBX_DelayedCallForwarding" => [
"Subscribed", "Variant", "Number", "NoReplyTime", "UnconditionalBusyAndDelayCallForwardingUsageSensitiveBilling"
		],
		"Meta_PBX_SelectiveCallForwarding" => ["Subscribed", "Enabled", "NumberToForwardTo", "SingleRing", "NumberOfAnonymousNumbersForwarded", "UsageSensitiveBilling"],
		"Meta_PBX_SelectiveCallForwarding_NumbersList" => ["Number"],
		"Meta_Subscriber_SelectiveCallForwarding_NumbersList" => ["Number"],
		"Meta_PBX_UnavailableCallForwarding" => ["Subscribed", "Enabled", "Number"],
		"Meta_PBX_DoNotDisturb" => [
"Subscribed", "Enabled", "ServiceLevel", "SingleRing", "SelectiveCallAcceptanceNumberOfAnonymousNumbers",
"SelectiveCallAcceptanceUsageSensitiveBilling"
		],
		"Meta_PBX_DoNotDisturb_SCANumbersList" => ["Number"],
		"Meta_Subscriber_DoNotDisturb_SCANumbersList" => ["Number"],
		"Meta_PBX_HighRiskCallLimits" => ["LimitType", "MaximumHighRiskCalls"],
		"Meta_PBX_MandatoryAccountCodes" => [
"Subscribed", "Variant", "USMandatoryAccountCodesCallTypes", "USMandatoryAccountCodesCallTypes2", "UKMandatoryAccountCodesCallTypes",
"CodeLength", "MaxIncorrectCodeAttemptsPerCall", "MaxIncorrectCodeAttempts", "Blocked", "ValidAccountCodes"
		],
		"Meta_PBX_PINChange" => ["Subscribed"],
		"Meta_PBX_SelectiveCallRejection" => ["Subscribed", "Enabled", "NumberOfAnonymousNumbers", "UsageSensitiveBilling"],
		"Meta_PBX_SelectiveCallRejection_NumbersList" => ["Number"],
		"Meta_PBX_SpeedCalling" => ["Subscribed", "AllowedTypes", "HandsetAccessAllowed"],
		"Meta_PBX_SpeedCalling_NumbersList" => ["Number"],
		"Meta_PBX_Voicemail" => [
"Subscribed", "CallDeliveryMethod", "VoicemailSystemLineGroup", "RetrievalNumber", "IncomingNumber", "ApplicationServer",
"IndicatorNotificationMethod", "SMDILink", "AuthorizedIDForIndicatorControl", "IndicatorNotificationApplicationServer",
"VisualMessageWaitingIndicator", "AudibleMessageWaitingIndicator", "SIPMessageWaitingIndicator", "MessageWaitingIndicatorStatus",
"CallTransferTime", "SendDIDNumberToVoicemailServerOnForwardedCalls"
		],
		"Meta_PBX_LineClassCodes" => [
"LineClassCode1", "LineClassCode2", "LineClassCode3", "LineClassCode4", "LineClassCode5", "LineClassCode6", "LineClassCode7", "LineClassCode8",
"LineClassCode9", "LineClassCode11", "LineClassCode12", "LineClassCode13", "LineClassCode14", "LineClassCode15", "LineClassCode16", "LineClassCode17",
"LineClassCode18", "LineClassCode19", "LineClassCode20"
		],
		"Meta_Subscriber_LineClassCodes" => [
"LineClassCode1", "LineClassCode2", "LineClassCode3", "LineClassCode4", "LineClassCode5", "LineClassCode6", "LineClassCode7", "LineClassCode8",
"LineClassCode9", "LineClassCode11", "LineClassCode12", "LineClassCode13", "LineClassCode14", "LineClassCode15", "LineClassCode16", "LineClassCode17",
"LineClassCode18", "LineClassCode19", "LineClassCode20"
		],
		"Meta_CallPickupGroup_BaseInformation" => [
"NetworkElementName", "MetaSwitchName", "BusinessGroupName", "SiteName", "ClusterName", "GroupName", "Department", "NumberOfMembers"
		],
		"Meta_CallPickupGroup_MembersList" => ["Member"],
		"Meta_CallPickupGroup_PossibleMembersList" => ["Member"],
		"Meta_MLHG_BaseInformation" => [
"NetworkElementName", "MetaSwitchName", "BusinessGroupName", "SiteName", "ClusterName", "Name", "ServiceLevel", "Department", "Number",
"LoginLogoutSupportedByDefault", "DistributionAlgorithm", "QueuingSupported", "MaximumQueueLength", "LimitQueuingTime", "MaximumQueueTimeout",
"HuntOnNoAnswer", "NoAnswerTimeout", "NoAnswerExclusionTime", "HuntOnDirectDialedCalls", "UnavailableCallForwardingSupported",
"DeliveryOfCalledDNAsCallerID", "NumberOfMembers", "NumberOfLoggedInMembers", "TrafficStudy"
		],
		"Meta_MLHG_MembersList" => ["Member"],
		"Meta_MLHGPilotDN_BaseInformation" => [
"NetworkElementName", "MetaSwitchName", "BusinessGroupName", "SiteName", "ClusterName", "MLHGName", "DirectoryNumber", "DelegatedManagementGroup",
"PersistentProfile", "InUseBy", "IntercomDialingCode", "MultipleAppearanceDirectoryNumber", "MLHGIndex", "MLHGMemberIndex", "NumberStatus",
"RecentlyMovedFromOldNumber", "MovedFromDirectoryNumber", "ConnectCallAfterAnnouncement", "MovedToDirectoryNumber", "MovedDate", "ExpireAfter",
"ExpiryDate", "PortedExchangeID", "SignalingType", "UseDNForIdentification", "SIPUserName", "SIPDomainName", "PIN", "ForceLNPLookup", "Timezone",
"AdjustForDaylightSavings", "EnabledDate", "MLHGApplyDistinctiveRingPattern", "MLHGRingPattern", "PresentPilotNameToAgents", "ChargeIndication",
"SASHostname", "ActiveYear", "ActiveMonth", "ActiveDate"
		],
		"Meta_MLHGPilotDN_TerminatingService" => ["Subscribed", "Server"],
#
#
# EAS
#
#
		"Msph_Subscriber_BaseInformation" => [
"DisplayName", "CompanyName", "CoSID", "EmailAliases", "FaxNumber", "Gender", "GivenName", "LATA", "EmailAddress", "Disabled", "DisabledforMigration",
"PrimaryPhoneNumber", "PIN", "PreferredLanguage", "BillingNumber", "Surname", "TimeZone", "Groupname", "Device", "BroadcastGroups", "Password",
"PINChangedDate", "FaxPrintPhoneNumber", "ExceededLoginCount", "APNSDeviceTokens", "VvmSmsDeviceTokens", "ODRG", "EASSystemName", "VoicemailTranscriptionsEnabled",
"IctTargetAlternate", "IctTargetWireless", "IctSimTargetNumbers", "PasswordChangedDate", "IsPINAged", "IsPasswordAged", "ExtVmCFN", "VideoMessagingEnabled",
"SelfProvStatus", "PreferredSite", "SiteName", "ClusterName", "SecurityAddress"
		],
		"Msph_Subscriber_BusinessGroup" => ["BusinessGroup", "Department", "AccountType", "AdministrationDepartment", "IntercomCode", "OperatorNumber", "IsACDRSAllowed", "CurrentNumberOfScheduledReports"],
		
	};
	$Self->{'MetaswitchRESTapiItemConf'} = {
		1 => {
			Name => "NetworkNode",
			IN => [
				{
					Name => "Default",
					Value => "None"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "None"
				},
			]
		},
		2 => {
			Name => "ChargeIndication",
			IN => [
				{
					Name => "Default",
					Value => "None"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "None"
				},
			]
		},
		3 => {
			Name => "RoutingAttributes",
			Data => {
				UseDefault => "True",
				"Pre_paidOff_switchCallingCardSubscriber" => { Default=>"False", Value=>"False"},
				"FaxModemSubscriber" => { Default=>"False", Value=>"False"},
				"NomadicSubscriber" => { Default=>"False", Value=>"False"},
			}
		},
		4 => {
			Name => "InternationalCarrier",
			IN => [
				{
					Name => "Default",
					Value => "1234"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "1234"
				},
			]
		},
		5 => {
			Name => "SubscriberGroupBusLine",
			IN => [
				{
					Name => "Default",
					Value => "Meribel subscribers"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "Meribel subscribers"
				},
			]
		},
		6 => {
			Name => "FlashHookCallServicesProvidedBy",
			IN => [
				{
					Name => "Default",
					Value => "Endpoint"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "Endpoint"
				},
			]
		},
		7 => {
			Name => "CallingNumberPrecedenceForEmergencyCalls",
			IN => [
				{
					Name => "Default",
					Value => "CPN - UPN - DN"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "CPN - UPN - DN"
				},
			]
		},
		8 => {
			Name => "MaximumSimultaneousRegistrations",
			IN => [
				{
					Name => "Default",
					Value => "1"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "1"
				},
			]
		},
		9 => {
			Name => "SubMediaGatewayModel",
			IN => [
				{
					Name => "Default",
					Value => "Derived from SIP User Agent"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "Derived from SIP User Agent"
				},
			]
		},
		10 => {
			Name => "ESAProtectionDomain",
			IN => [
				{
					Name => "Default",
					Value => "None"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "None"
				},
			]
		},
		11 => {
			Name => "MaximumCallAppearances",
			IN => [
				{
					Name => "Default",
					Value => "1"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "1"
				},
			]
		},
		12 => {
			Name => "MaximumPermittedContactRefreshInterval",
			IN => [
				{
					Name => "Default",
					Value => "86400"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "86400"
				},
			]
		},
		13 => {
			Name => "LongDistanceCarrier",
			IN => [
				{
					Name => "Default",
					Value => "1234"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "1234"
				},
			]
		},
		14 => {
			Name => "IntraLATACarrier",
			IN => [
				{
					Name => "Default",
					Value => "1234"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "1234"
				},
			]
		},
		15 => {
			Name => "ServiceSuspendedBusGrpLine",
			IN => [
				{
					Name => "Default",
					Value => "None"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "None"
				},
			]
		},
		16 => {
			Name => "ForceLNPLookup",
			IN => [
				{
					Name => "Default",
					Value => "False"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "False"
				},
			]
		},
		17 => {
			Name => "SubscriberTimezone",
			IN => [
				{
					Name => "Default",
					Value => "GB"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "GB"
				},
			]
		},
		18 => {
			Name => "BusinessGroupLinePrivileges",
			IN => [
				{
					Name => "Default",
					Value => "0"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "0"
				},
			]
		},
		19 => {
			Name => "SubscriberCallingCategory",
			IN => [
				{
					Name => "Default",
					Value => "Ordinary calling subscriber"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "Ordinary calling subscriber"
				},
			]
		},
		20 => {
			Name => "Subscribed",
			IN => [
				{
					Name => "Default",
					Value => "True"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "True"
				},
			]
		},
		20001 =>{
			Name => "DirectedPickupNoBargeInSubscribed",
			IN => [
				{
					Name => "Default",
					Value => "True"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "True"
				},
			]
		},
		21 => {
			Name => "Variant",
			IN => [
				{
					Name => "Default",
					Value => "Variable"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "Variable"
				},
			]
		},
		2100 => {
			Name => "Variant",
			ServiceIndication => "Meta_Subscriber_MandatoryAccountCodes",
			IN => [
				{
					Name => "Default",
					Value => "Non-validated"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "Non-validated"
				},
			]
		},
		2101 => {
			Name => "Variant",
			ServiceIndication => "Meta_PBX_MandatoryAccountCodes",
			IN => [
				{
					Name => "Default",
					Value => "Non-validated"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "Non-validated"
				},
			]
		},
		22 => {
			Name => "UnconditionalBusyAndDelayCallForwardingUsageSensitiveBilling",
			IN => [
				{
					Name => "Default",
					Value => "False"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "False"
				},
			]
		},
		23 => {
			Name => "BillingType",
			IN => [
				{
					Name => "Default",
					Value => "Flat rate"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "Flat rate"
				},
			]
		},
		24 => {
			Name => "BusinessGroupForcedOffSwitchRouting",
			IN => [
				{
					Name => "Default",
					Value => "None"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "None"
				},
			]
		},
		25 => {
			Name => "DenyAllUsageSensitiveFeatures",
			IN => [
				{
					Name => "Default",
					Value => "False"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "False"
				},
			]
		},
		26 => {
			Name => "EnableAdvancedAlertingFeatures",
			IN => [
				{
					Name => "Default",
					Value => "True"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "True"
				},
			]
		},
		27 => {
			Name => "DefaultESAProtectionDomainForSIPSubscribers",
			IN => [
				{
					Name => "Default",
					Value => "None"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "None"
				},
			]
		},
		28 => {
			Name => "BusinessGroupCallLogsEnabled",
			IN => [
				{
					Name => "Default",
					Value => "False"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "False"
				},
			]
		},
		29 => {
			Name => "AllowBGAdminChangeExpMod",
			IN => [
				{
					Name => "Default",
					Value => "False"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "False"
				},
			]
		},
		30 => {
			Name => "BusinessGroupPrefixCallerIDWithExternalLineCodeIfPresent",
			IN => [
				{
					Name => "Default",
					Value => "False"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "False"
				},
			]
		},
		31 => {
			Name => "BusinessGroupLinesSharePresence",
			IN => [
				{
					Name => "Default",
					Value => "False"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "False"
				},
			]
		},
		32 => {
			Name => "VQMCallLogging",
			IN => [
				{
					Name => "Default",
					Value => "True"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "True"
				},
			]
		},
		33 => {
			Name => "NoReplyTime",
			IN => [
				{
					Name => "Default",
					Value => "36"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "36"
				},
			]
		},
		34 => {
			Name => "SingleRing",
			IN => [
				{
					Name => "Default",
					Value => "False"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "False"
				},
			]
		},
		35 => {
			Name => "MaximumSimultaneousForwardings",
			IN => [
				{
					Name => "Default",
					Value => "1000"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "1000"
				},
			]
		},
		36 => {
			Name => "UserNotificationOfCallDiversion",
			IN => [
				{
					Name => "Default",
					Value => "False"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "False"
				},
			]
		},
		37 => {
			Name => "DeliverRedirectingNumberAsCallingNumber",
			IN => [
				{
					Name => "Default",
					Value => "False"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "False"
				},
			]
		},
		38 => {
			Name => "NumberReleasedToDivertedToUser",
			IN => [
				{
					Name => "Default",
					Value => "True"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "True"
				},
			]
		},
		39 => {
			Name => "NumberReleasedToCaller",
			IN => [
				{
					Name => "Default",
					Value => "True"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "True"
				},
			]
		},
		40 => {
			Name => "DivertedToNumberReleasedToCaller",
			IN => [
				{
					Name => "Default",
					Value => "True"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "True"
				},
			]
		},
		41 => {
			Name => "RequireCourtesyCall",
			IN => [
				{
					Name => "Default",
					Value => "True"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "True"
				},
			]
		},
		42 => {
			Name => "PlayConfirmTone",
			IN => [
				{
					Name => "Default",
					Value => "True"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "True"
				},
			]
		},
		43 => {
			Name => "ServiceLevel",
			IN => [
				{
					Name => "Default",
					Value => "Do Not Disturb"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "Do Not Disturb"
				},
			]
		},
		44 => {
			Name => "IntegratedDND",
			IN => [
				{
					Name => "Default",
					Value => "False"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "False"
				},
			]
		},
		45 => {
			Name => "SelectiveCallAcceptanceUsageSensitiveBilling",
			IN => [
				{
					Name => "Default",
					Value => "False"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "False"
				},
			]
		},
		46 => {
			Name => "UsageSensitiveBilling",
			IN => [
				{
					Name => "Default",
					Value => "False"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "False"
				},
			]
		},
		47 => {
			Name => "Arrangement",
			IN => [
				{
					Name => "Default",
					Value => "Circular"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "Circular"
				},
			]
		},
		48 => {
			Name => "CurrentSubscriberBarredCallTypes",
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => [
						{
							Name => "International",
							Value => "False"
						},
						{
							Name => "NationalAndMobile",
							Value => "False"
						},
						{
							Name => "Local",
							Value => "False"
						},
						{
							Name => "Operator",
							Value => "False"
						},
						{
							Name => "AccessCodes",
							Value => "False"
						},
						{
							Name => "Premium",
							Value => "False"
						},
						{
							Name => "AccessCodesThatChangeConfiguration",
							Value => "False"
						},
						{
							Name => "DirectoryAssistance",
							Value => "False"
						},
						{
							Name => "National",
							Value => "False"
						},
						{
							Name => "Mobile",
							Value => "False"
						}
					]
				}
			]
		},
		49 => {
			Name => "CurrentOperatorBarredCallTypes",
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => [
						{
							Name => "International",
							Value => "False"
						},
						{
							Name => "NationalAndMobile",
							Value => "False"
						},
						{
							Name => "Local",
							Value => "False"
						},
						{
							Name => "Operator",
							Value => "False"
						},
						{
							Name => "AccessCodes",
							Value => "False"
						},
						{
							Name => "Premium",
							Value => "False"
						},
						{
							Name => "AccessCodesThatChangeConfiguration",
							Value => "False"
						},
						{
							Name => "DirectoryAssistance",
							Value => "False"
						},
						{
							Name => "National",
							Value => "False"
						},
						{
							Name => "Mobile",
							Value => "False"
						}
					]
				}
			]
		},
		50 => {
			Name => "MaximumNumberOfCallsPerList",
			IN => [
				{
					Name => "Default",
					Value => "10"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "10"
				},
			]
		},
		51 => {
			Name => "TWCCTConfUsageSensitiveBilling",
			IN => [
				{
					Name => "Default",
					Value => "True"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "True"
				},
			]
		},
		52 => {
			Name => "WithholdNumberByDefault",
			IN => [
				{
					Name => "Default",
					Value => "False"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "False"
				},
			]
		},
		53 => {
			Name => "NumberWithholdRejectionReason",
			IN => [
				{
					Name => "Default",
					Value => "Blocked"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "Blocked"
				},
			]
		},
		54 => {
			Name => "PresentNumberByDefault",
			IN => [
				{
					Name => "Default",
					Value => "False"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "False"
				},
			]
		},
		55 => {
			Name => "WithholdDirectoryNumber",
			IN => [
				{
					Name => "Default",
					Value => "False"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "False"
				},
			]
		},
		56 => {
			Name => "AlwaysPresentNumberForIntercomCalls",
			IN => [
				{
					Name => "Default",
					Value => "False"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "False"
				},
			]
		},
		57 => {
			Name => "UseLocalNameForIntercomCallsOnlyBusLine",
			IN => [
				{
					Name => "Default",
					Value => "False"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "False"
				},
			]
		},
		58 => {
			Name => "LocalNameBusLine",
			IN => [
				{
					Name => "Default",
					Value => "XYZ"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "XYZ"
				},
			]
		},
		59 => {
			Name => "PreferredSIPFormat",
			IN => [
				{
					Name => "Default",
					Value => "Directory Number"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "Directory Number"
				},
			]
		},
		60 => {
			Name => "OverridePrivacySettingOfCallingSubscriber",
			IN => [
				{
					Name => "Default",
					Value => "False"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "False"
				},
			]
		},
		61 => {
			Name => "LimitType",
			IN => [
				{
					Name => "Default",
					Value => "Limited"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "Limited"
				},
			]
		},
		62 => {
			Name => "MaximumHighRiskCalls",
			IN => [
				{
					Name => "Default",
					Value => "2"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "2"
				},
			]
		},
		6201 => {
			Name => "MaximumHighRiskCalls",
			ServiceIndication => "Meta_PBX_HighRiskCallLimits",
			IN => [
				{
					Name => "Default",
					Value => "5"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "5"
				},
			]
		},
		63 => {
			Name => "MaximumNumberOfLines",
			IN => [
				{
					Name => "Default",
					Value => "10"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "10"
				},
			]
		},
		64 => {
			Name => "MonitorDoNotDisturbStatus",
			IN => [
				{
					Name => "Default",
					Value => "False"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "False"
				},
			]
		},
		65 => {
			Name => "USCallTypes",
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => [
						{
							Name => "Local",
							Value => "False"
						},
						{
							Name => "Operator",
							Value => "True"
						},
						{
							Name => "Premium",
							Value => "True"
						},
						{
							Name => "Directory",
							Value => "True"
						},
						{
							Name => "LocalBusinessGroup",
							Value => "False"
						},
						{
							Name => "OtherBusinessGroup",
							Value => "False"
						},
						{
							Name => "National",
							Value => "True"
						},
						{
							Name => "Regional",
							Value => "True"
						},
						{
							Name => "CarrierDialed",
							Value => "True"
						},
						{
							Name => "International",
							Value => "True"
						}
					]
				}
			]
		},
		64 => {
			Name => "CodeLength",
			IN => [
				{
					Name => "Default",
					Value => "4"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "4"
				},
			]
		},
		66 => {
			Name => "MaxIncorrectCodeAttemptsPerCall",
			IN => [
				{
					Name => "Default",
					Value => "1"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "1"
				},
			]
		},
		67 => {
			Name => "MonitorDoNotDisturbStatus",
			IN => [
				{
					Name => "Default",
					Value => "True"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "True"
				},
			]
		},
		68 => {
			Name => "AllowedTypes",
			IN => [
				{
					Name => "Default",
					Value => "One and two digit"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "One and two digit"
				},
			]
		},
		69 => {
			Name => "CallDeliveryMethod",
			IN => [
				{
					Name => "Default",
					Value => "SIP"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "SIP"
				},
			]
		},
		70 => {
			Name => "ApplicationServer",
			IN => [
				{
					Name => "Default",
					Value => "Courchevel EAS"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "Courchevel EAS"
				},
			]
		},
		71 => {
			Name => "IndicatorNotificationMethod",
			IN => [
				{
					Name => "Default",
					Value => "SIP"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "SIP"
				},
			]
		},
		72 => {
			Name => "SIPMessageWaitingIndicator",
			IN => [
				{
					Name => "Default",
					Value => "False"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "False"
				},
			]
		},
		73 => {
			Name => "CallTransferTime",
			IN => [
				{
					Name => "Default",
					Value => "36"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "36"
				},
			]
		},
		74 => {
			Name => "VoicemailSystemLineGroup",
			IN => [
				{
					Name => "Default",
					Value => "36"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "36"
				},
			]
		},
		75 => {
			Name => "SupportedPreferredMediaAddressFamilies",
			IN => [
				{
					Name => "Default",
					Value => "IPv4"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "IPv4"
				},
			]
		},
		76 => {
			Name => "DialtoneSupported",
			OUT => [
				{
					Name => "EMWinkStart",
					Value => "False"
				}
			]
		},
		77 => {
			Name => "PBXFixBits",
			OUT => [
				{
					Name => "OneZeroDigitMaxANI",
					Value => "False"
				},
				{
					Name => "Always10DigitANI",
					Value => "False"
				}
			]
		},
		78 => {
			Name => "CallingNumberPrecedenceForEmergencyCalls",
			IN => [
				{
					Name => "Default",
					Value => "CPN - UPN - DN"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "CPN - UPN - DN"
				},
			]
		},
		79 => {
			Name => "CallingNumberConnectedLineIDScreening",
			IN => [
				{
					Name => "Default",
					Value => "No Screening"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "No Screening"
				},
			]
		},
		80 => {
			Name => "CallingNumberScreening",
			IN => [
				{
					Name => "Default",
					Value => "No Screening"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "No Screening"
				},
			]
		},
		81 => {
			Name => "AdditionalCallingNumberScreeningForEmergencyCalls",
			IN => [
				{
					Name => "Default",
					Value => "No Screening"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "No Screening"
				},
			]
		},
		82 => {
			Name => "MaximumCallAppearances",
			IN => [
				{
					Name => "Default",
					Value => "64"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "64"
				},
			]
		},
		83 => {
			Name => "LongDistanceCarrier",
			IN => [
				{
					Name => "Default",
					Value => ""
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => ""
				},
			]
		},
		84 => {
			Name => "IntraLATACarrier",
			IN => [
				{
					Name => "Default",
					Value => ""
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => ""
				},
			]
		},
		85 => {
			Name => "InternationalCarrier",
			IN => [
				{
					Name => "Default",
					Value => ""
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => ""
				},
			]
		},
		86 => {
			Name => "AdviceOfChargeAOCD",
			IN => [
				{
					Name => "Default",
					Value => "Never provided"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "Never provided"
				},
			]
		},
		87 => {
			Name => "AdviceOfChargeAOCE",
			IN => [
				{
					Name => "Default",
					Value => "Never provided"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "Never provided"
				},
			]
		},
		88 => {
			Name => "DenyAllUsageSensitiveFeatures",
			IN => [
				{
					Name => "Default",
					Value => "False"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "False"
				},
			]
		},
		89 => {
			Name => "TariffGroup",
			IN => [
				{
					Name => "Default",
					Value => "42"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "42"
				},
			]
		},
		90 => {
			Name => "ForceLNPLookup",
			IN => [
				{
					Name => "Default",
					Value => "False"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "False"
				},
			]
		},
		91 => {
			Name => "Timezone",
			IN => [
				{
					Name => "Default",
					Value => "Unknown"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "Unknown"
				},
			]
		},
		92 => {
			Name => "AdjustForDaylightSavings",
			IN => [
				{
					Name => "Default",
					Value => "False"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "False"
				},
			]
		},
		93 => {
			Name => "CIDIgnorePBXSigPrsnt",
			IN => [
				{
					Name => "Default",
					Value => "Use if not withheld"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "Use if not withheld"
				},
			]
		},
		94 => {
			Name => "Destination",
			IN => [
				{
					Name => "Default",
					Value => "Default desination"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "Default desination"
				},
			]
		},
		95 => {
			Name => "USMandatoryAccountCodesCallTypes",
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => [
						{
							Name => "International",
							Value => "True"
						},
						{
							Name => "NationalMobile",
							Value => "False"
						},
						{
							Name => "Local",
							Value => "False"
						},
						{
							Name => "Operator",
							Value => "True"
						},
						{
							Name => "Premium",
							Value => "True"
						},
						{
							Name => "Directory",
							Value => "True"
						},
						{
							Name => "LocalBusinessGroup",
							Value => "True"
						},
						{
							Name => "OtherBusinessGroup",
							Value => "True"
						},
						{
							Name => "Regional",
							Value => "False"
						},
						{
							Name => "CarrierDialed",
							Value => "False"
						}
					]
				},
			]
		},
		96 => {
			Name => "USMandatoryAccountCodesCallTypes2",
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => [
						{
							Name => "International",
							Value => "True"
						},
						{
							Name => "National",
							Value => "False"
						},
						{
							Name => "Local",
							Value => "False"
						},
						{
							Name => "Operator",
							Value => "True"
						},
						{
							Name => "Premium",
							Value => "True"
						},
						{
							Name => "Directory",
							Value => "True"
						},
						{
							Name => "LocalBusinessGroup",
							Value => "True"
						},
						{
							Name => "OtherBusinessGroup",
							Value => "True"
						}
					]
				},
			]
		},
		97 => {
			Name => "UKMandatoryAccountCodesCallTypes",
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => [
						{
							Name => "International",
							Value => "True"
						},
						{
							Name => "National",
							Value => "False"
						},
						{
							Name => "Local",
							Value => "False"
						},
						{
							Name => "Operator",
							Value => "True"
						},
						{
							Name => "Premium",
							Value => "True"
						},
						{
							Name => "Directory",
							Value => "True"
						},
						{
							Name => "LocalBusinessGroup",
							Value => "True"
						},
						{
							Name => "OtherBusinessGroup",
							Value => "True"
						},
						{
							Name => "Regional",
							Value => "False"
						},
						{
							Name => "CarrierDialed",
							Value => "False"
						}
					]
				},
			]
		},
		98 => {
			Name => "MaxIncorrectCodeAttemptsPerCall",
			IN => [
				{
					Name => "Default",
					Value => "1"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "1"
				},
			]
		},
		9901 => {
			Name => "LineClassCode1",
			IN => [
				{
					Name => "Default",
					Value => "0 Default"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "0 Default"
				},
			]
		},
		9902 => {
			Name => "LineClassCode2",
			IN => [
				{
					Name => "Default",
					Value => "0"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "0"
				},
			]
		},
		9903 => {
			Name => "LineClassCode3",
			IN => [
				{
					Name => "Default",
					Value => "0"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "0"
				},
			]
		},
		9904 => {
			Name => "LineClassCode4",
			IN => [
				{
					Name => "Default",
					Value => "0 Default"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "0 Default"
				},
			]
		},
		9905 => {
			Name => "LineClassCode5",
			IN => [
				{
					Name => "Default",
					Value => "0"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "0"
				},
			]
		},
		9906 => {
			Name => "LineClassCode6",
			IN => [
				{
					Name => "Default",
					Value => "0"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "0"
				},
			]
		},
		9907 => {
			Name => "LineClassCode7",
			IN => [
				{
					Name => "Default",
					Value => "0"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "0"
				},
			]
		},
		9908 => {
			Name => "LineClassCode8",
			IN => [
				{
					Name => "Default",
					Value => "0"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "0"
				},
			]
		},
		9909 => {
			Name => "LineClassCode9",
			IN => [
				{
					Name => "Default",
					Value => "0"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "0"
				},
			]
		},
		9910 => {
			Name => "LineClassCode10",
			IN => [
				{
					Name => "Default",
					Value => "0"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "0"
				},
			]
		},
		9911 => {
			Name => "LineClassCode11",
			IN => [
				{
					Name => "Default",
					Value => "0"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "0"
				},
			]
		},
		9912 => {
			Name => "LineClassCode12",
			IN => [
				{
					Name => "Default",
					Value => "0"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "0"
				},
			]
		},
		9913 => {
			Name => "LineClassCode13",
			IN => [
				{
					Name => "Default",
					Value => "0"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "0"
				},
			]
		},
		9914 => {
			Name => "LineClassCode14",
			IN => [
				{
					Name => "Default",
					Value => "0"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "0"
				},
			]
		},
		9915 => {
			Name => "LineClassCode15",
			IN => [
				{
					Name => "Default",
					Value => "0"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "0"
				},
			]
		},
		9916 => {
			Name => "LineClassCode16",
			IN => [
				{
					Name => "Default",
					Value => "0"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "0"
				},
			]
		},
		9917 => {
			Name => "LineClassCode17",
			IN => [
				{
					Name => "Default",
					Value => "0"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "0"
				},
			]
		},
		9918 => {
			Name => "LineClassCode18",
			IN => [
				{
					Name => "Default",
					Value => "0 Default"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "0 Default"
				},
			]
		},
		9919 => {
			Name => "LineClassCode19",
			IN => [
				{
					Name => "Default",
					Value => "0"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "0"
				},
			]
		},
		9920 => {
			Name => "LineClassCode20",
			IN => [
				{
					Name => "Default",
					Value => "0 Default International"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "0 Default International"
				},
			]
		},
		100 => {
			Name => "Server",
			IN => [
				{
					Name => "Default",
					Value => "Courchevel EAS"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "Courchevel EAS"
				},
			]
		},
		101 => {
			Name => "Enabled",
			ServiceIndication => "Meta_PBXDIDNumber_UnavailableCallForwarding",
			IN => [
				{
					Name => "Default",
					Value => "False"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "False"
				},
				{
					Name => "Value",
					Value => "False"
				},
			]
		},
		102 => {
			Name => "Number",
			ServiceIndication => "Meta_PBXDIDNumber_UnavailableCallForwarding",
			IN => [
				{
					Name => "Default",
					Value => ""
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "False"
				},
				{
					Name => "Value",
					Value => ""
				},
			]
		},
		103 => {
			Name => "Enabled",
			ServiceIndication => "Meta_PBXDIDNumber_UnconditionalCallForwarding",
			IN => [
				{
					Name => "Default",
					Value => "False"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "False"
				},
				{
					Name => "Value",
					Value => "False"
				},
			]
		},
		104 => {
			Name => "Number",
			ServiceIndication => "Meta_PBXDIDNumber_UnconditionalCallForwarding",
			IN => [
				{
					Name => "Default",
					Value => ""
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "False"
				},
				{
					Name => "Value",
					Value => ""
				},
			]
		},
		105 => {
			Name => "Enabled",
			ServiceIndication => "Meta_PBXDIDNumber_RecordingService",
			IN => [
				{
					Name => "Default",
					Value => "False"
				},
			],
			OUT => [
				{
					Name => "UseDefault",
					Value => "True"
				},
				{
					Name => "Value",
					Value => "False"
				},
			]
		},
	};
}
1;
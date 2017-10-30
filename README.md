# Inceptum-MetaswitchJsonAPI
JSON API Proxy to Metaswitch Voice platform.
This API provides JSON access to Metaswitch Voice platform for provisioning single and PBX lines.
This code is suitable for CentOS 7.x OS, but it should work on other linux/unix system.
Required components which should be preinstalled are:
  - OTRS version 5.x at least (just perl modules, OTRS system scripts and OTRS WEB libraries not needed and OTRS daemon should not be started for this API purposes)
  - Apache WEB server version 2.4 at least
     - configuration of Metaswitch REST endpoint under Apache is described in Conf/REST.conf file on this github repository
  - Perl at least version 5.16
  - Perl modules required and should be installed: Apache2::Request, Apache2::REST
  - In perl bootstrap script for Apache (apache2-perl-startup.pl) probably should be added line to API library (where is Metaswitch::REST module installed). 
    For example:
    use lib "/usr/local/umboss/lib";
  - linux modules required: libapreq2, perl-libapreq2
    - Installation this modules on CentOS
      yum install libapreq2
      yum install perl-libapreq2
    
Authentication is defined inside perl module Kernel/Config/MetaswitchAuth.pm withe simple user<=>token pair.
Configuration of some Metaswitch provisioning objects should be defined in file Kernel/Config/MetaswitchRESTapi.pm.

Have a fun!!!

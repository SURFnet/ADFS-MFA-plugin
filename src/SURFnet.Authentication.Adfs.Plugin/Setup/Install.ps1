﻿#####################################################################
#Copyright 2017 SURFnet bv, The Netherlands
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.
#####################################################################

Import-Module SURFnetMFA
cls
$error.Clear()
$date=get-date -f "yyyyMMdd.HHmmss"
start-transcript "Log/Install-SurfnetMfaPlugin.$($date).log"

function Initialize-UserSettings()
{	
	$GLOBAL:EXECUTIONCANCELLED = $false
	$ErrorActionPreference = "Stop"	
	$global:pfxPassword = $null;

	#Defaults
	$Settings_SecondFactorEndpoint_default			= ""
	$Settings_MinimalLoa_default 		   			= ""
	$Settings_schacHomeOrganization_default 		= ""
	$Settings_ActiveDirectoryName_default   		= ""
	$Settings_ActiveDirectoryUserIdAttribute_default= ""
	$ServiceProvider_EntityId_default 			    = ""                        
	$ServiceProvider_SigningCertificate_default 	= ""
	$IdentityProvider_EntityId_default 				= ""
	$IdentityProvider_Certificate_default 			= ""
	$GwServer_default = 1

	# Prepare default names and Endpoints
	# TODO (for conversion/update: get from existing
	#       get from ADFS hostname: endpoint and entityID [or ]
	$ServiceProvider_EntityId_default = "http://adfs-2012.test2.surfconext.nl/stepup-mfa"
	# TODO:  Must ask
	$Settings_ActiveDirectoryUserIdAttribute_default= "employeeNumber"
	$Settings_schacHomeOrganization_default 		= "institution-b.nl"
	$Settings_ActiveDirectoryName_default   		= "niet-meer-nodig"


	$needGWChoice = $true
	$GwServer = 1
	Write-Host -f yellow "0. Select the Stepup Gateway (1: Production, 2: Pilot, 3: Test, 4. Manual with Production defaults."
	do {
		$GwServer = read-host "Stepup Gateway choice? (default is $($GwServer_default))"
        $GwServer = [int]$GwServer
		if ( $GwServer -eq 0 ) {
			$GwServer = $GwServer_default
        }

		switch ( $GwServer ) {
			1 {
				Write-Host -f red "   Choice 1 not yet implemented"
				break
			}
			2 {
				Write-Host -f red "   Choice 2 not yet implemented"
				break
			}
			3 {
				$Settings_MinimalLoa_default 		   			= "http://test.surfconext.nl/assurance/sfo-level2"
				$ServiceProvider_SigningCertificate_default 	= ""
				$Settings_SecondFactorEndpoint_default			= "https://sa-gw.test.surfconext.nl/second-factor-only/single-sign-on"
				$IdentityProvider_EntityId_default 				= "https://sa-gw.test.surfconext.nl/second-factor-only/metadata"
				$IdentityProvider_Certificate_default 			= "sa-gw.test.crt"
				$needGWChoice = $false
				break
			}
			4 {
				Write-Host -f red "   Choice 4 not yet implemented"
				break
			}

			default {
				Write-Host -f red "   Invalid choice ($GwServer), valid: 1-4"
				break
			}
		}
	} while ( $needGWChoice )
	
	#Ask for installation parameters
	Write-Host -f yellow "1. Enter the Assertion Consumer Service (ACS) location of the Second Factor Only (SFO) endpoint of the SURFsecureID Gateway."
	$global:Settings_SecondFactorEndpoint           = read-host "Second Factor Endpoint? (default is $($Settings_SecondFactorEndpoint_default))"
	
    Write-Host -f yellow "2. Enter the minimum Level-of-Assurance (LoA) identifier for authentication requests from the ADFS MFA extension to the SURFsecureID Gateway."
	$global:Settings_MinimalLoa 		   			= read-host "Minimal Loa (default is $($Settings_MinimalLoa_default))"
	
    Write-Host -f yellow "3. Enter the value of the schacHomeOrganization attribute of your institution (the one that your institution provides to SURFconext)."  
	Write-Host -f yellow "Must be the same value that is used in the urn:mace:terena.org:attribute-def:schacHomeOrganization attribute your institution sends to SURFconext."
	$global:Settings_schacHomeOrganization 			= read-host "schacHomeOrganization? (default is $($Settings_schacHomeOrganization_default))"
	
    Write-Host -f yellow "4. Enter the name of the Active Directory (AD) that contains the useraccounts used by the ADFS MFA extension. E.g. 'example.org'."
	$global:Settings_ActiveDirectoryName   			= read-host "ActiveDirectoryName? (default is $($Settings_ActiveDirectoryName_default))"
	
    Write-Host -f yellow "5. Enter the name of the attribute in AD containing the userid known by SURFsecureID." 
	Write-Host -f yellow "The result must be same value that was used in the urn:mace:dir:attribute-def:uid attribute during authentication to SURFconext."
	$global:Settings_ActiveDirectoryUserIdAttribute = read-host "ActiveDirectoryUserIdAttribute? (default is $($Settings_ActiveDirectoryUserIdAttribute_default))"
	
    Write-Host -f yellow "6. Enter the EntityID of your Service Provider (SP)." 
	Write-Host -f yellow " This is the entityid used by the ADFS MFA extenstion to communicatie with SURFsecureID. Choose a value in the form of an URL or URN."
	$global:ServiceProvider_EntityId 			    = read-host "Service provider Entity Id? (default is $($ServiceProvider_EntityId_default))"
	
    Write-Host -f yellow "7. Optional, enter (if present) the filename of a .pfx file containing the X.509 certificate and RSA private key which will be used to sign the authentication request to the SFO Endpoint" 
	Write-Host -f yellow " When using an existing X.509 certificate, please register the certificate with SURFsecureID." 
	Write-Host -f yellow " When not present a X.509 certificate and private key is generated by the install script, and written as a .pfx file to the installation folder. Please register the certificate with SURFsecureID." 
	Write-Host -f yellow " Caution: In case of a multi server farm, use the same signing certificate" 
	$global:ServiceProvider_SigningCertificate 	    = read-host "Service provider SigningCertificate? (default is autogenerate)"
	
    Write-Host -f yellow "8. Enter the EntityID of the SFO endpoint of the SURFsecureID Gateway"
	$global:IdentityProvider_EntityId 				= read-host "Identity  provider identity Id? (default is $($IdentityProvider_EntityId_default))"
	
    Write-Host -f yellow "9. Enter the filename of the .crt file containing the SAML signing certificate of the SURFsecureID Gateway."
    Write-Host -f yellow "   Nothing if there is already a singning certificate. Must be in the '$PSScriptroot'\Certificates directory."
	$global:IdentityProvider_Certificate 			= read-host "Identity  provider certificate? (default is $($IdentityProvider_Certificate_default))"

	if($global:Settings_SecondFactorEndpoint -eq ""){$global:Settings_SecondFactorEndpoint = $Settings_SecondFactorEndpoint_default}
	if($global:Settings_MinimalLoa -eq ""){$global:Settings_MinimalLoa=$Settings_MinimalLoa_default}
	if($global:Settings_schacHomeOrganization -eq ""){$global:Settings_schacHomeOrganization=$Settings_schacHomeOrganization_default}
	if($global:Settings_ActiveDirectoryName -eq ""){$global:Settings_ActiveDirectoryName=$Settings_ActiveDirectoryName_default}   			
	if($global:Settings_ActiveDirectoryUserIdAttribute -eq ""){$global:Settings_ActiveDirectoryUserIdAttribute=$Settings_ActiveDirectoryUserIdAttribute_default} 
	if($global:ServiceProvider_EntityId -eq ""){$global:ServiceProvider_EntityId=$ServiceProvider_EntityId_default} 			    
	if($global:ServiceProvider_SigningCertificate -eq ""){$global:ServiceProvider_SigningCertificate=$ServiceProvider_SigningCertificate_default} 	    
	if($global:IdentityProvider_EntityId -eq ""){$global:IdentityProvider_EntityId=$IdentityProvider_EntityId_default} 				
	if($global:IdentityProvider_Certificate -eq ""){$global:IdentityProvider_Certificate=$IdentityProvider_Certificate_default} 			



	Write-Host ""
    Write-Host ""
    Write-Host ""
    Write-Host ""

    Write-Host -ForegroundColor Green "======================================Installation Configuration Summary =========================================="
    write-Host -f yellow "Installation settings"
	Write-Host -f green  "Location of SFO endpoint from SURFsecureID Gateway       :" $global:Settings_SecondFactorEndpoint 
	Write-Host -f green  "Minimum LoA for authentication requests                  :" $global:Settings_MinimalLoa 		   			
	Write-Host -f green  "schacHomeOrganization attribute of your institution      :" $global:Settings_schacHomeOrganization 			
	Write-Host -f green  "AD containing the useraccounts                           :" $global:Settings_ActiveDirectoryName   			
	Write-Host -f green  "AD userid attribute                                      :" $global:Settings_ActiveDirectoryUserIdAttribute 
	Write-Host -f green  "SAML EntityID of the ADFS MFA extension                  :" $global:ServiceProvider_EntityId 			    
	Write-Host -f green  ".pfx file with the extension's X.509 cert and RSA keypair:" $global:ServiceProvider_SigningCertificate 	    
	Write-Host -f green  "SAML EntityID of the SURFsecureID Gateway                :" $global:IdentityProvider_EntityId 				
	Write-Host -f green  ".crt file with X.509 cert of the SURFsecureID Gateway    :" $global:IdentityProvider_Certificate 			
    Write-Host -ForegroundColor Green "==================================================================================================================="
	
    Write-Host ""
    Write-Host ""

    if((read-host "Continue the installation with these settings? Y/N") -ne  "Y")
	{
	  return $false
	}
	return $true
}

function Verify-Installation{

	if( -NOT (Get-module SURFnetMFA))	
	{
		throw "Missing the SURFnetMFA PowerShell Module"
    }

	if(([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator") -ne $true){
		throw "Cannot run script. Please run this script in administrator mode."
	}

    $adfssrv = Get-WmiObject win32_service |? {$_.name -eq "adfssrv"}
    if(!$adfssrv){
		$GLOBAL:EXECUTIONCANCELLED = $true
        throw "No AD FS service found on this server. Please run this script locally at the target AD FS server."
		
    }
    $global:adfsServiceAccount = $adfssrv.StartName

	$global:AdfsProperties = Get-AdfsProperties
}


function Print-Summary{
    Param(
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        [Parameter(Mandatory=$true)]
        $cert,
        [String]
        [Parameter(Mandatory=$true)]
        $entityId
    )


    Write-Host ""
    Write-Host ""
    Write-Host ""
    Write-Host -ForegroundColor Green "======================================Details=========================================="
    if($global:pfxPassword){
        Write-Host "The signing certificate has been created during installation and exported to the installation folder. Use the following password to install the certificate on other AD FS servers: `"$global:pfxPassword`"."
        Write-Host ""
    }



    Write-Host -ForegroundColor Green "Provide the data below to SURFsecureID support"
    Write-Host -ForegroundColor White "Your EntityID: $entityId"
    Write-Host ""  
    Write-Host "Your Signing certificate"
    Write-Host -ForegroundColor White "-----BEGIN CERTIFICATE-----"
    Write-Host -ForegroundColor White ([Convert]::ToBase64String($cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert), [System.Base64FormattingOptions]::InsertLineBreaks))
    Write-Host -ForegroundColor White "-----END CERTIFICATE-----"
    Write-Host ""    
    Write-Host -ForegroundColor Green "======================================================================================="
    Write-Host ""  
}

try
{	
    Verify-Installation
	if(Initialize-UserSettings)
	{			
		if(Install-Log4NetConfiguration -InstallDir "$PSScriptroot\config")
		{
			$x509SigningCertificate = Install-SigningCertificate -CertificateFile $global:ServiceProvider_SigningCertificate `
                                                               -InstallDir "$PSScriptroot\Certificates" `
                                                               -AdfsServiceAccountName $global:adfsServiceAccount
			$x509SfoCertificate = Install-SfoCertificate -InstallDir "$PSScriptroot\Certificates" -CertificateFile $global:IdentityProvider_Certificate
			Install-EventLogForMfaPlugin -LiteralPath "$PSScriptRoot\Config"
			Install-AuthProvider -InstallDir $PSScriptroot -ProviderName ADFS.SCSA -AssemblyName "SURFnet.Authentication.Adfs.Plugin.dll" -TypeName "SURFnet.Authentication.Adfs.Plugin.Adapter"
		    Update-ADFSConfiguration -InstallDir "$PSScriptRoot\Config" `
                                     -ServiceProviderEntityId $global:ServiceProvider_EntityId `
                                     -IdentityProviderEntityId $global:IdentityProvider_EntityId `
                                     -SecondFactorEndpoint $global:Settings_SecondFactorEndpoint `
                                     -MinimalLoa $global:Settings_MinimalLoa `
                                     -schacHomeOrganization $global:Settings_schacHomeOrganization `
                                     -ActiveDirectoryName $global:Settings_ActiveDirectoryName `
                                     -ActiveDirectoryUserIdAttribute $global:Settings_ActiveDirectoryUserIdAttribute `
                                     -sfoCertificateThumbprint $x509SfoCertificate.Thumbprint `
                                     -ServiceProviderCertificateThumbprint $x509SigningCertificate.Thumbprint
            

            if($global:ServiceProvider_SigningCertificate -eq $null -or $global:ServiceProvider_SigningCertificate -eq ""){
			    $global:pfxPassword = Export-SigningCertificate -CertificateThumbprint $x509SigningCertificate.Thumbprint -ExportTo "$PSScriptroot\Certificates\"+$x509SigningCertificate.DnsNameList[0].Unicode + ".pfx"
            }
			
            Print-Summary $x509SigningCertificate $global:ServiceProvider_EntityId
		}
    }
}
catch{
    Write-Host -ForegroundColor Red "Error while installing plugin:" $_.Exception.Message
}

Stop-Transcript

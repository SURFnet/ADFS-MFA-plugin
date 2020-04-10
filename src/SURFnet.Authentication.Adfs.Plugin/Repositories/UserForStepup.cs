﻿using SURFnet.Authentication.Adfs.Plugin.Configuration;
using SURFnet.Authentication.Adfs.Plugin.Services;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;

namespace SURFnet.Authentication.Adfs.Plugin.Repositories
{
    public class UserForStepup
    {
        public Claim UserClaim { get; private set; }
        public string ErrorMsg { get; private set; }
        public string SfoUid { get; private set; }

        private UserForStepup() { }

        public UserForStepup(Claim claim)
        {
            UserClaim = claim;
        }

        public bool TryGetSfoUidValue()
        {
            bool rc = false;
            var linewidthsaver = StepUpConfig.Current.InstitutionConfig.ActiveDirectoryUserIdAttribute;
            // Claim is windowsaccountname claim. Fixe in Metadata! No need to check.

            var domainName = UserClaim.Value.Split('\\')[0];

            if (ActiveDirectoryRepository.TryGetAttributeValue(domainName, UserClaim.Value, linewidthsaver, out string userid, out string error))
            {
                // OK there was an attribute
                if (string.IsNullOrWhiteSpace(userid))
                {
                    ErrorMsg = $"The {linewidthsaver} attribute for {UserClaim.Value} IsNullOrWhiteSpace()";
                }
                else
                {
                    SfoUid = userid;
                    rc = true;
                }
            }
            else
            {
                // attribute not found, operational error.
                if (error != null)
                {
                    // but this is a really unexpected fatal error.
                    ErrorMsg = error;
                    // TODO:  Could/should throw!!
                }
            }

            return rc;
        }
    }
}
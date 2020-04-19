﻿using SURFnet.Authentication.Adfs.Plugin.Setup.Configuration;
using SURFnet.Authentication.Adfs.Plugin.Setup.Models;
using SURFnet.Authentication.Adfs.Plugin.Setup.Question;
using SURFnet.Authentication.Adfs.Plugin.Setup.Services;
using SURFnet.Authentication.Adfs.Plugin.Setup.Versions;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SURFnet.Authentication.Adfs.Plugin.Setup
{
    public static class RulesAndChecks
    {
        /// <summary>
        /// Decides if this setup program can and should uninstall.
        /// Writes messages and ask questions.
        /// At the end asks if "sure".
        /// </summary>
        /// <param name="setupstate"></param>
        /// <returns></returns>
        public static bool CanUNinstall(SetupState setupstate)
        {
            bool doit = false;

            // Everything else was OK now last confirmation question (if actually needed)
            if ( setupstate.RegisteredVersionInAdfs.Major == 0)
            {
                if (Messages.DoYouWantTO($"Do you really want to UNINSTALL version: {setupstate.DetectedVersion}?"))
                {
                    doit = true;
                }
            }
            else
            {
                // Some registration in ADFS configuration.
                if ( setupstate.AdfsConfig.SyncProps.IsPrimary )
                {
                    // primary
                    Console.WriteLine("*******");
                    Console.WriteLine("  Primary computer in the farm with an MFA registration the ADFS configuration.");
                    Console.WriteLine("  Not removing this MFA registration from ADFS will produce messages in the evenlog.");
                    Console.WriteLine();
                    if ( Messages.DoYouWantTO("Unregister the SFO MFA extension configuration for all servers in the farm?") )
                    {
                        doit = true;
                        if ( AdfsPSService.UnregisterAdapter() )
                        {
                            setupstate.AdfsConfig.RegisteredAdapterVersion = V0Assemblies.AssemblyNullVersion;
                            Console.WriteLine("\"Unregister\" successful, the ADFS eventlog should no longer show loading this adapter.");
                            Console.WriteLine();
                            if ( ! Messages.DoYouWantTO("Continue with Uninstall?") )
                            {
                                // abandon as the admin said
                                doit = false;
                            }
                        }
                        else
                        {
                            // Unregistration failed.
                            doit = false;
                        }
                    }
                }
                else
                {
                    // secondary, cannot Unregister

                    Console.WriteLine("Secondary computer in the farm with MFA registration the ADFS configuration.");
                    Console.WriteLine("Uninstalling the MFA extension will produce errors in the evenlog.");
                    if (Messages.DoYouWantTO($"Do you really want to UNINSTALL version: {setupstate.DetectedVersion}?"))
                    {
                        doit = true;
                    }
                }
            }

            return doit;
        }

        public static bool CanInstall(Version version)
        {

            return Messages.DoYouWantTO($"Do you want to install version: {version}");
        }

        public static int ExtraChecks(SetupState setupstate)
        {
            int rc = 0;


            // TODO: Report on relation between Server role and settings in ADFS.
            if ( setupstate.DetectedVersion.Major == 0 )
            {
                // Nothing on disk
                // TODONOW: give advice
            }
            else
            {
                // something on disk
                Console.WriteLine();
                Console.WriteLine("Current Settings:");
                if (setupstate.FoundSettings != null && setupstate.FoundSettings.Count > 0)
                {
                    foreach (Setting setting in setupstate.FoundSettings)
                    {
                        Console.WriteLine(setting.ToString());
                    }
                }
                else
                {
                    Console.WriteLine("     None");
                }

                // TODONOW: give advice
            }

            Console.WriteLine();
            Console.WriteLine("Checked the installation: did not find any blocking errors.");

            return rc;
        }

    }
}
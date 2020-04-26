﻿using SURFnet.Authentication.Adfs.Plugin.Setup.Question;
using SURFnet.Authentication.Adfs.Plugin.Setup.Services;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Threading.Tasks;

namespace SURFnet.Authentication.Adfs.Plugin.Setup.Configuration
{
    public static class CertExport
    {
        private static readonly RNGCryptoServiceProvider rg = new RNGCryptoServiceProvider(); // avoid expensive GC


        public static void DoYouWantToExport(X509Certificate2 certificate)
        {
            QuestionIO.WriteLine();
            QuestionIO.WriteLine("The new certificate is now in the Certificate Store (Local Computer).");
            QuestionIO.WriteLine("  It can be exported at any time.");
            QuestionIO.WriteLine("  Other servers in the farm must use the same certificate.");
            QuestionIO.WriteLine();

            if ( 'y' == AskYesNo.Ask("    Do you want to export this certificate now as a '.pfx'") )
            {
                // generate random pwd
                string pwd = GetRandomPwd(20);

                try
                {
                    byte[] pfxbytes = certificate.Export(X509ContentType.Pfx, pwd);
                    string filepath = FileService.OurDirCombine(FileDirectory.Config, SetupConstants.SPCertPfxFilename);
                    File.WriteAllBytes(filepath, pfxbytes);

                    QuestionIO.WriteLine();
                    QuestionIO.WriteLine("   The password is: "+pwd);
                    QuestionIO.WriteLine("   Save it in a safe place.");
                    QuestionIO.WriteLine();

                    while ('y' != AskYesNo.Ask("    Did you save it somehere in a safe place")) { }
                }
                catch (Exception ex)
                {
                    LogService.WriteFatalException("Failed to Export/Write SP (SFO MFA extension) signing certificate.", ex);
                }

            }
            // else: ignore all other things like abort etc.
        }

        /// <summary>
        /// For the time being.....
        /// </summary>
        /// <param name="length"></param>
        /// <returns></returns>
        public static string GetRandomPwd(uint length)
        {
            const string valid = "abcdefghijklmnopqrstuvwxyz%$#@!ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";
            StringBuilder sb = new StringBuilder((int)length + 2);
            byte[] bytes = new byte[length];
            rg.GetBytes(bytes);

            uint modulus = (uint)valid.Length;
            for (int i=0; i<length; i++)
            {
                uint index = (uint)bytes[i] % modulus;
                sb.Append(valid[(int)index]);
            }

            return sb.ToString();
        }
    }
}

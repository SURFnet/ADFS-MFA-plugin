﻿/*
* Copyright 2017 SURFnet bv, The Netherlands
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

namespace SURFnet.Authentication.Adfs.Plugin.Setup.Question.SettingsQuestions
{
    /// <summary>
    /// Interface IAnswer
    /// </summary>
    public interface IAnswer
    {
        /// <summary>
        /// Gets or sets a value indicating whether this answer is mandatory.
        /// </summary>
        /// <value><c>true</c> if this answer is mandatory; otherwise, <c>false</c>.</value>
        bool IsMandatory { get; set; }

        /// <summary>
        /// Gets or sets the display name.
        /// </summary>
        /// <value>The display name.</value>
        string DisplayName { get; set; }

        /// <summary>
        /// Reads the user response.
        /// </summary>
        /// <returns>The user input.</returns>
        string ReadUserReponse();
    }
}
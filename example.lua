local Serializer = require("src.serializer")

print(Serializer:tableToVars{
    exampleString = "Hello! This is an example string containing '\n' and '\0', and even '😂'!",
    exampleTable = {{"Nested tables are fun, don't you think?"}},
    exampleNumber = 1e500,
    exampleBoolean = true
})
--[[OUTPUT:
    local exampleTable = {
        [1] = {
            [1] = "Nested tables are fun, don't you think?"
        }
    }
    local exampleBoolean = true
    local exampleNumber = math.huge
    local exampleString = "Hello! This is an example string containing '\n' and '\0', and even '\240\159\152\130'!"
]]

-- This is used to configure settings, currently there is only one setting: NoFormatUnknowns, which disables auto-
-- formatting of unknown chars (generally utf8)
Serializer:configureSetting("NoFormatUnknowns", true)

print(Serializer:valueToVar("This is an unformatted utf8 char: 😂", "unformatted"))
--[[OUTPUT:
    local unformatted = "This is an unformatted utf8 char: 😂"
]]
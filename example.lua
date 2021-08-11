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
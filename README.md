# Lua-Serializer
## A lightweight Lua serializer
```Typescript
Serializer: {
  configureSetting: function(<string> name, <any> value),
  tableToVars: function(<table> t) <string>,
  valueToString: function(<any> value) <string>,
  valueToVar: function(<any>, value[, <string> name]) <string>,
}
```

With configureSetting, the only setting is "NoFormatUnknowns", which disables auto-formatting of unknown chars (generally utf8), see example.lua for more information.

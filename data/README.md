Data for the answers site archive

1. Migrated questions
2. Unmigrated questions
3. Migrated question StackExchange ID/URL
4. Instead of exporting user ids we'll create very basic profiles of questions and answers only for users which have them.

Check dump schema against the archive.schema.json in this project with `check-jsonschema`.
Installable in [Arch Linux](https://archlinux.org/packages/extra/any/check-jsonschema/) or from [pypi](https://archlinux.org/packages/extra/any/check-jsonschema/).
```
check-jsonschema --schemafile archive.schema.json FILE.json
```


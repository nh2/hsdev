hsdev
=====

Haskell development library and tool with support of autocompletion, symbol info, go to declaration, find references etc.

Usage
-----

Use `hsdev server start` to start remove server. Specify `--cache`, where `hsdev` will store information.
Use `scan` commands to scan cabal modules, projects and directories, for example:

```
PS> hsdev server start --cache=cache
Server started at port 4567
PS> hsdev scan cabal
{}
PS> hsdev scan -f Test.hs -p Projects --proj hsdev\hsdev.cabal
{}
```

Other commands can be used to extract info about modules, projects, declarations etc.

```
PS> hsdev complete foldM -f hsdev\src\HsDev\Commands.hs | json | % { $_.declaration.name }
foldM
foldM_
foldM
foldM_
foldMapDefault
PS> hsdev --pretty symbol partitionEithers
[
    {
        "module-id": {
            "name": "Data.Either",
            "location": {
                "package": null,
                "name": "Data.Either",
                "cabal": "\u003ccabal\u003e"
            }
        },
        "declaration": {
            "pos": null,
            "decl": {
                "what": "function",
                "type": "[Either a b] -\u003e ([a], [b])"
            },
            "name": "partitionEithers",
            "docs": "Partitions a list of Either into two lists\n All the Left elements are extracted, in order, to the first\n component of the output. Similarly the Right elements are extracted\n to the second component of the output."
        }
    }
]
PS> hsdev --pretty whois selectModules -f hsdev\src\HsDev\Commands.hs
{
    "module-id": {
        "name": "HsDev.Database",
        "location": {
            "project": "E:\\users\\voidex\\Documents\\Projects\\hsdev\\hsdev.cabal",
            "file": "E:\\users\\voidex\\Documents\\Projects\\hsdev\\src\\HsDev\\Database.hs"
        }
    },
    "declaration": {
        "pos": {
            "line": 121,
            "column": 1
        },
        "decl": {
            "what": "function",
            "type": "(Module -\u003e Bool) -\u003e Database -\u003e [Module]"
        },
        "name": "selectModules",
        "docs": null
    }
}
```

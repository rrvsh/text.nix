{ lib, ... }:
let
  inherit (lib)
    mapAttrsToList
    optional
    concatStrings
    flatten
    mkOption
    mapAttrs
    isString
    replicate
    flip
    getAttr
    concatStringsSep
    ;
  inherit (lib.types)
    lazyAttrsOf
    oneOf
    submodule
    lines
    listOf
    ;
  textType = oneOf [
    lines
    (submodule {
      options = {
        heading = mkOption {
          type = lines;
          default = "";
        };
        description = mkOption {
          type = lines;
          default = "";
        };
        order = mkOption {
          type = listOf lines;
          default = [ ];
        };
        parts = mkOption { type = lazyAttrsOf textType; };
      };
    })
  ];
  mkListFromAttrs =
    prefix:
    { name, value }:
    let
      sectionHeading = result: "${concatStrings (replicate prefix "#")} ${result}";
    in
    if isString value then
      [
        (sectionHeading name)
        value
      ]
    else
      flatten [
        [
          (sectionHeading (if value.heading == "" then name else value.heading))
        ]
        (optional (value.description != "") value.description)
        (map (mkListFromAttrs (prefix + 1)) (
          if value.order == [ ] then
            mapAttrsToList (name: value: { inherit name value; }) value.parts
          else
            map (x: {
              name = x;
              value = flip getAttr value.parts x;
            }) value.order
        ))
      ];
in
{
  options.text = mkOption {
    default = { };
    type = lazyAttrsOf textType;
    apply = mapAttrs (
      name: value: concatStringsSep "\n" (flatten (mkListFromAttrs 1 { inherit name value; }))
    );
  };
}

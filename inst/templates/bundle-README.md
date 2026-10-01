# Connectivity analysis: {{species}}

Interpatch distances: {{distances}}

Data resolution: {{resolution}} metres

Coordinate reference system: {{crs}}

Produced {{date}} by urbioconnect {{version}}.

## Reading these files

Patch areas are in square metres, and the summary's `patch_area_total_ha` and
`effective_mesh_ha` are in hectares. The coordinate reference system above
comes from the habitat layer you supplied, and every spatial file here uses it.

`patches.gpkg` and `patches.shp` hold the same polygons. The GeoPackage is one
file and keeps full column names; the shapefile is there for software that
expects one, and comes with the `.shx`, `.dbf` and `.prj` files beside it.

A folder for an interpatch distance with no connected patches will have no
polygon files, because there is no geometry to write.

## Files

{{files}}

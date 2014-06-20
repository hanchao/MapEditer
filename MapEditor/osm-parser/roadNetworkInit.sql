--
--
-- This SQL script creates the DB model used to store information extracted during a .osm file parsing.
--
-- 
-- SELECT InitSpatialMetaData();
-- INSERT INTO spatial_ref_sys (srid, auth_name, auth_srid, ref_sys_name, proj4text) VALUES (4326, 'epsg', 4326,'WGS 84', '+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs');
DROP TABLE IF EXISTS nodes;
DROP TABLE IF EXISTS nodes_tags;
DROP TABLE IF EXISTS ways;
DROP TABLE IF EXISTS ways_tags;
DROP TABLE IF EXISTS ways_nodes;
DROP TABLE IF EXISTS relations;
DROP TABLE IF EXISTS relations_members;
DROP TABLE IF EXISTS relations_tags;

CREATE TABLE nodes (
	id INTEGER PRIMARY KEY  NOT NULL , 
	latitude DOUBLE NOT NULL , 
	longitude DOUBLE NOT NULL,
	user TEXT,
	uid INTEGER,
	timestamp TEXT,
	version TEXT,
	changeset INTEGER,
	action TEXT CHECK ( action IN ("delete", "update"))
);

CREATE TABLE nodes_tags (
	node_id INTEGER REFERENCES nodes ( id ),
	key TEXT, 
	value TEXT,
	UNIQUE ( node_id, key, value )
	);
CREATE TABLE ways (
	id INTEGER PRIMARY KEY NOT NULL,
	user TEXT,
	uid INTEGER,
	timestamp TEXT,
	version TEXT,
	changeset INTEGER,
	action TEXT CHECK ( action IN ("delete", "update"))
);

CREATE TABLE ways_tags (
	way_id INTEGER REFERENCES ways ( id ),
    key TEXT,
    value TEXT,
    UNIQUE ( way_id, key, value )
);

CREATE TABLE ways_nodes (
	way_id INTEGER REFERENCES ways ( id ),
    node_id INTEGER REFERENCES nodes ( id ),
    local_order INTEGER,
    UNIQUE ( way_id, local_order, node_id )
);


CREATE TABLE relations (
	id INTEGER NOT NULL,
	user TEXT,
	uid INTEGER,
	timestamp TEXT,
	version TEXT,
	changeset INTEGER,
	action TEXT CHECK ( action IN ("delete", "update"))
);
CREATE TABLE relations_members (
	relation_id INTEGER REFERENCES relations ( id ),
	type TEXT CHECK ( type IN ("node", "way", "relation")), 
	ref INTEGER NOT NULL , 
	role TEXT,
	local_order INTEGER,
	UNIQUE (relation_id,ref,local_order)
);
CREATE TABLE relations_tags (
	relation_id INTEGER NOT NULL REFERENCES relations ( id ), 
	key TEXT, 
	value TEXT,
	UNIQUE (relation_id,key,value)
);

-- create index way_nodes_way_id ON way_nodes ( way_id );
-- create index way_nodes_node_id ON way_nodes ( node_id );
-- SELECT AddGeometryColumn('ways', 'geom', 4326, 'LINESTRING', 2);
-- CREATE TABLE roadsDefinitions (ref VARCHAR[10], name VARCHAR[100], course VARCHAR[2], section VARCHAR[2]);
--CREATE TABLE ways_info (ref VARCHAR[10], name VARCHAR[100]);

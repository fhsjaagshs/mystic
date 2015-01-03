/*
 oids.h
 
 contains defines for common oids.
 */

// IMPORTANT!
// To get the types, use the below query:
// SELECT typname, oid, typtype FROM pg_type WHERE typtype = 'b';
// this is a good link: http://www.postgresql.org/docs/current/interactive/catalog-pg-type.html

/* Postgres type oids */
/* Built-in OIDs don't change*/
#define BOOLOID 16

#define INT8OID 20
#define INT2OID 21
#define INT4OID 23
#define FLOAT4OID 700
#define FLOAT8OID 701
#define NUMERICOID 1700
#define OIDOID 26

#define MONEYOID 790

// Representation formats
#define JSONOID 114
#define XMLOID 142

// Date/Time formats
#define ABSTIMEOID 702
#define DATEOID 1082
#define TIMEOID 1083
#define TIMESTAMPOID 1114
#define TIMESTAMPTZOID 1184
#define TIMETZOID 1266

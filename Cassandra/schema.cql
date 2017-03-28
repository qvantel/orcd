CREATE KEYSPACE IF NOT EXISTS qvantel WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1 };

CREATE TYPE qvantel.ServiceUnit(
amount int,
currency text,
unit_of_measure text
);

CREATE TYPE qvantel.LocationInformation(
destination text,
location_number text,
location_area_identification text,
cell_global_identification text
);

CREATE TYPE qvantel.EventDetails(
traffic_case text,
event_type text,
a_party_number text,
is_roaming boolean,
a_party_location frozen <LocationInformation>,
b_party_number text,
b_party_location frozen <LocationInformation>
);

CREATE TYPE qvantel.Product(
id text,
name text
);

CREATE TYPE qvantel.ChargedAmounts(
id text,
name text,
charged_type text,
event_type text,
resource_type text,
amount int,
end_balance int,
expiry_date text
);

CREATE TYPE qvantel.eventCharges(
charged_units frozen <ServiceUnit>,
product frozen <Product>,
charged_amounts set <frozen <ChargedAmounts>>
);

CREATE TABLE IF NOT EXISTS qvantel.cdr(
id uuid,
created_at timestamp,
started_at timestamp,
used_service_units frozen <ServiceUnit>,
service text,
event_details frozen <EventDetails>,
event_charges frozen <EventCharges>,
PRIMARY KEY (id, created_at)
)
WITH CLUSTERING ORDER BY (created_at ASC);

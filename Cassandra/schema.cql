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
  access_point_name text,
  traffic_case text,
  event_type text,
  is_roaming boolean,
  a_party_number text,
  b_party_number text,
  a_party_location frozen <LocationInformation>,
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

CREATE TYPE qvantel.EventCharges(
  charged_units frozen <ServiceUnit>,
  product frozen <Product>,
  charged_amounts set <frozen <ChargedAmounts>>
);

CREATE TABLE IF NOT EXISTS qvantel.cdr(
  id uuid,
  service text,
  product text,
  created_at bigint,
  started_at bigint,
  used_service_units frozen <ServiceUnit>,
  event_details frozen <EventDetails>,
  event_charges frozen <EventCharges>,
  clustering_key int,
  PRIMARY KEY ((clustering_key), created_at)
)
WITH CLUSTERING ORDER BY (created_at ASC);

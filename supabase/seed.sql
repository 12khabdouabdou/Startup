-- Seed data for local development
INSERT INTO profiles (id, role, full_name, verification_status) VALUES
  ('00000000-0000-0000-0000-000000000001', 'developer', 'Test Developer', 'approved'),
  ('00000000-0000-0000-0000-000000000002', 'hauler', 'Test Hauler', 'approved'),
  ('00000000-0000-0000-0000-000000000003', 'recycler', 'Test Recycler', 'approved'),
  ('00000000-0000-0000-0000-000000000004', 'admin', 'Test Admin', 'approved');

INSERT INTO waste_posts (developer_id, waste_type, quantity, quantity_unit, location, status, price) VALUES
  ('00000000-0000-0000-0000-000000000001', 'concrete', 5.00, 'tons', ST_SetSRID(ST_MakePoint(-73.94, 40.73), 4326), 'posted', 250.00);

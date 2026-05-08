-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE waste_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE waste_selections ENABLE ROW LEVEL SECURITY;
ALTER TABLE hauls ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE tracking_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE commission_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_refunds ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform_audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Profiles
CREATE POLICY "Users read own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Admin read all profiles" ON profiles FOR SELECT USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY "Users update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

-- Waste posts
CREATE POLICY "Developers read own posts" ON waste_posts FOR SELECT USING (
  (SELECT role FROM profiles WHERE id = auth.uid()) IN ('developer', 'admin')
  OR developer_id = auth.uid()
);
CREATE POLICY "Recyclers view available posts" ON waste_posts FOR SELECT USING (
  (SELECT role FROM profiles WHERE id = auth.uid()) IN ('recycler', 'admin')
  OR status = 'posted'
);
CREATE POLICY "Developers insert posts" ON waste_posts FOR INSERT WITH CHECK (auth.uid() = developer_id);
CREATE POLICY "Developers update own posts" ON waste_posts FOR UPDATE USING (auth.uid() = developer_id);

-- Hauls
CREATE POLICY "Haulers read assigned" ON hauls FOR SELECT USING (
  hauler_id = auth.uid()
  OR recycler_id = auth.uid()
  OR EXISTS (SELECT 1 FROM waste_posts wp WHERE wp.id = waste_post_id AND wp.developer_id = auth.uid())
  OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY "Haulers update assigned" ON hauls FOR UPDATE USING (hauler_id = auth.uid());

-- Payments
CREATE POLICY "Users read own payments" ON payments FOR SELECT USING (
  payer_id = auth.uid()
  OR EXISTS (SELECT 1 FROM hauls h WHERE h.id = haul_id AND h.hauler_id = auth.uid())
  OR EXISTS (SELECT 1 FROM waste_posts wp JOIN hauls h ON h.waste_post_id = wp.id WHERE h.id = haul_id AND wp.developer_id = auth.uid())
  OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Tracking events
CREATE POLICY "Party read tracking" ON tracking_events FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM hauls h
    WHERE h.id = haul_id
      AND (h.hauler_id = auth.uid()
        OR h.recycler_id = auth.uid()
        OR EXISTS (SELECT 1 FROM waste_posts wp WHERE wp.id = h.waste_post_id AND wp.developer_id = auth.uid())
        OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'))
  )
);

-- Commission settings (admin write, public read)
CREATE POLICY "Admins modify commission" ON commission_settings FOR ALL USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY "Everyone read commission" ON commission_settings FOR SELECT USING (true);

-- Notifications
CREATE POLICY "Users read own notifications" ON notifications FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users update own notifications" ON notifications FOR UPDATE USING (user_id = auth.uid());

-- Audit log (admin read)
CREATE POLICY "Admins read audit" ON platform_audit_log FOR SELECT USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Payment refunds (admin read)
CREATE POLICY "Admins read refunds" ON payment_refunds FOR SELECT USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Trigger to auto-create profile on auth signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, role, full_name)
  VALUES (NEW.id, 'developer', NEW.raw_user_meta_data->>'full_name');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Trigger to log update status on haul update (placeholder for future logic)
CREATE OR REPLACE FUNCTION public.log_haul_status_change()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    -- Add notification or additional logic here if needed
    NULL;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_haul_status_change
  AFTER UPDATE ON hauls
  FOR EACH ROW EXECUTE FUNCTION public.log_haul_status_change();

-- Insert default commission setting (run after seed if needed)
INSERT INTO commission_settings (rate) SELECT 0.10 WHERE NOT EXISTS (SELECT 1 FROM commission_settings);

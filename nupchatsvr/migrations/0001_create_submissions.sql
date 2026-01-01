-- DRM Submissions Table
-- Stores form data with location hierarchy for filtering/sorting
CREATE TABLE IF NOT EXISTS drm_submissions (
  id TEXT PRIMARY KEY,
  district_code TEXT NOT NULL,
  district_name TEXT NOT NULL,
  county_code TEXT NOT NULL,
  county_name TEXT NOT NULL,
  sub_county_code TEXT NOT NULL,
  sub_county_name TEXT NOT NULL,
  parish_code TEXT NOT NULL,
  parish_name TEXT NOT NULL,
  polling_station_code TEXT NOT NULL,
  polling_station_name TEXT NOT NULL,
  image_url TEXT NOT NULL,
  created_at TEXT NOT NULL,
  uploaded_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Indexes for efficient filtering by location hierarchy
CREATE INDEX IF NOT EXISTS idx_district ON drm_submissions(district_code);
CREATE INDEX IF NOT EXISTS idx_county ON drm_submissions(district_code, county_code);
CREATE INDEX IF NOT EXISTS idx_sub_county ON drm_submissions(district_code, county_code, sub_county_code);
CREATE INDEX IF NOT EXISTS idx_parish ON drm_submissions(district_code, county_code, sub_county_code, parish_code);
CREATE INDEX IF NOT EXISTS idx_polling_station ON drm_submissions(polling_station_code);
CREATE INDEX IF NOT EXISTS idx_created_at ON drm_submissions(created_at DESC);

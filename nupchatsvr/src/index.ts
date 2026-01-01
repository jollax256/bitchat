import { Hono } from 'hono';
import { cors } from 'hono/cors';

// Type definitions for Cloudflare bindings
interface Env {
  DRM_IMAGES: R2Bucket;
  DRM_DB: D1Database;
}

// Submission interface matching Flutter model
interface DrmSubmission {
  id: string;
  districtCode: string;
  districtName: string;
  countyCode: string;
  countyName: string;
  subCountyCode: string;
  subCountyName: string;
  parishCode: string;
  parishName: string;
  pollingStationCode: string;
  pollingStationName: string;
  imageUrl: string;
  timestamp: string;
}

const app = new Hono<{ Bindings: Env }>();

// Enable CORS for Flutter app
app.use('/*', cors({
  origin: '*',
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization'],
}));

// Health check endpoint
app.get('/', (c) => {
  return c.json({
    status: 'ok',
    service: 'NupChat DRM Server',
    version: '1.0.0',
  });
});

// ==================== Image Upload ====================

/**
 * Upload a single image to R2 bucket
 * Returns the public URL of the uploaded image
 */
app.post('/api/drm/upload-image', async (c) => {
  try {
    const formData = await c.req.formData();
    const imageFile = formData.get('image') as File | null;

    if (!imageFile) {
      return c.json({ error: 'No image file provided' }, 400);
    }

    // Generate unique filename with timestamp
    const timestamp = Date.now();
    const extension = imageFile.name.split('.').pop() || 'jpg';
    const filename = `drm/${timestamp}-${crypto.randomUUID()}.${extension}`;

    // Upload to R2
    const imageBuffer = await imageFile.arrayBuffer();
    await c.env.DRM_IMAGES.put(filename, imageBuffer, {
      httpMetadata: {
        contentType: imageFile.type || 'image/jpeg',
      },
    });

    // Construct public URL (assumes R2 bucket has public access or custom domain)
    // Update this URL pattern to match your R2 bucket configuration
    const publicUrl = `https://drm-images.YOUR_DOMAIN.com/${filename}`;

    return c.json({
      success: true,
      url: publicUrl,
      filename: filename,
    });
  } catch (error) {
    console.error('Image upload error:', error);
    return c.json({ error: 'Failed to upload image' }, 500);
  }
});

// ==================== Submissions CRUD ====================

/**
 * Create a new DRM submission
 */
app.post('/api/drm/submissions', async (c) => {
  try {
    const body = await c.req.json<DrmSubmission>();

    // Validate required fields
    const requiredFields = [
      'id', 'districtCode', 'districtName', 'countyCode', 'countyName',
      'subCountyCode', 'subCountyName', 'parishCode', 'parishName',
      'pollingStationCode', 'pollingStationName', 'imageUrl', 'timestamp'
    ];

    for (const field of requiredFields) {
      if (!body[field as keyof DrmSubmission]) {
        return c.json({ error: `Missing required field: ${field}` }, 400);
      }
    }

    // Insert into D1 database
    const result = await c.env.DRM_DB.prepare(`
      INSERT INTO drm_submissions (
        id, district_code, district_name, county_code, county_name,
        sub_county_code, sub_county_name, parish_code, parish_name,
        polling_station_code, polling_station_name, image_url, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
      body.id,
      body.districtCode,
      body.districtName,
      body.countyCode,
      body.countyName,
      body.subCountyCode,
      body.subCountyName,
      body.parishCode,
      body.parishName,
      body.pollingStationCode,
      body.pollingStationName,
      body.imageUrl,
      body.timestamp
    ).run();

    return c.json({
      success: true,
      id: body.id,
      message: 'Submission created successfully',
    }, 201);
  } catch (error) {
    console.error('Submission creation error:', error);
    return c.json({ error: 'Failed to create submission' }, 500);
  }
});

/**
 * Get all submissions with optional filtering by location
 * Query params: district_code, county_code, sub_county_code, parish_code, polling_station_code
 */
app.get('/api/drm/submissions', async (c) => {
  try {
    const districtCode = c.req.query('district_code');
    const countyCode = c.req.query('county_code');
    const subCountyCode = c.req.query('sub_county_code');
    const parishCode = c.req.query('parish_code');
    const pollingStationCode = c.req.query('polling_station_code');
    const limit = parseInt(c.req.query('limit') || '50');
    const offset = parseInt(c.req.query('offset') || '0');

    // Build dynamic query based on filters
    let query = 'SELECT * FROM drm_submissions WHERE 1=1';
    const params: string[] = [];

    if (districtCode) {
      query += ' AND district_code = ?';
      params.push(districtCode);
    }
    if (countyCode) {
      query += ' AND county_code = ?';
      params.push(countyCode);
    }
    if (subCountyCode) {
      query += ' AND sub_county_code = ?';
      params.push(subCountyCode);
    }
    if (parishCode) {
      query += ' AND parish_code = ?';
      params.push(parishCode);
    }
    if (pollingStationCode) {
      query += ' AND polling_station_code = ?';
      params.push(pollingStationCode);
    }

    query += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
    params.push(limit.toString(), offset.toString());

    const result = await c.env.DRM_DB.prepare(query).bind(...params).all();

    // Transform snake_case to camelCase for Flutter
    const submissions = result.results?.map((row: any) => ({
      id: row.id,
      districtCode: row.district_code,
      districtName: row.district_name,
      countyCode: row.county_code,
      countyName: row.county_name,
      subCountyCode: row.sub_county_code,
      subCountyName: row.sub_county_name,
      parishCode: row.parish_code,
      parishName: row.parish_name,
      pollingStationCode: row.polling_station_code,
      pollingStationName: row.polling_station_name,
      imageUrl: row.image_url,
      createdAt: row.created_at,
      uploadedAt: row.uploaded_at,
    })) || [];

    return c.json({
      success: true,
      count: submissions.length,
      submissions,
    });
  } catch (error) {
    console.error('Submissions query error:', error);
    return c.json({ error: 'Failed to fetch submissions' }, 500);
  }
});

/**
 * Get a single submission by ID
 */
app.get('/api/drm/submissions/:id', async (c) => {
  try {
    const id = c.req.param('id');

    const result = await c.env.DRM_DB.prepare(
      'SELECT * FROM drm_submissions WHERE id = ?'
    ).bind(id).first();

    if (!result) {
      return c.json({ error: 'Submission not found' }, 404);
    }

    const submission = {
      id: result.id,
      districtCode: result.district_code,
      districtName: result.district_name,
      countyCode: result.county_code,
      countyName: result.county_name,
      subCountyCode: result.sub_county_code,
      subCountyName: result.sub_county_name,
      parishCode: result.parish_code,
      parishName: result.parish_name,
      pollingStationCode: result.polling_station_code,
      pollingStationName: result.polling_station_name,
      imageUrl: result.image_url,
      createdAt: result.created_at,
      uploadedAt: result.uploaded_at,
    };

    return c.json({
      success: true,
      submission,
    });
  } catch (error) {
    console.error('Submission fetch error:', error);
    return c.json({ error: 'Failed to fetch submission' }, 500);
  }
});

/**
 * Get submission statistics grouped by location
 */
app.get('/api/drm/stats', async (c) => {
  try {
    // Get counts by district
    const districtStats = await c.env.DRM_DB.prepare(`
      SELECT 
        district_code,
        district_name,
        COUNT(*) as count
      FROM drm_submissions
      GROUP BY district_code, district_name
      ORDER BY count DESC
    `).all();

    // Get total count
    const totalResult = await c.env.DRM_DB.prepare(
      'SELECT COUNT(*) as total FROM drm_submissions'
    ).first();

    return c.json({
      success: true,
      total: totalResult?.total || 0,
      byDistrict: districtStats.results?.map((row: any) => ({
        districtCode: row.district_code,
        districtName: row.district_name,
        count: row.count,
      })) || [],
    });
  } catch (error) {
    console.error('Stats query error:', error);
    return c.json({ error: 'Failed to fetch stats' }, 500);
  }
});

export default app;

const limits = new Map();

function escapeHtml(value = '') {
  return String(value).replace(/[&<>'"]/g, char => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', "'": '&#39;', '"': '&quot;'
  })[char]);
}

export default async function handler(request, response) {
  if (request.method !== 'POST') return response.status(405).json({ error: 'Method not allowed' });

  const origin = request.headers.origin || '';
  if (!/^https:\/\/(smsoluciones-survey|smsolcuiones-survey|survey-smsoluciones-[a-z0-9-]+)\.vercel\.app$/.test(origin)) {
    return response.status(403).json({ error: 'Origin not allowed' });
  }

  const ip = String(request.headers['x-forwarded-for'] || request.socket?.remoteAddress || 'unknown').split(',')[0].trim();
  const now = Date.now();
  const recent = (limits.get(ip) || []).filter(time => now - time < 60_000);
  if (recent.length >= 5) return response.status(429).json({ error: 'Too many requests' });
  recent.push(now);
  limits.set(ip, recent);

  const survey = String(request.body?.survey || '').trim().slice(0, 140);
  const name = String(request.body?.name || 'Anónimo').trim().slice(0, 200);
  const area = String(request.body?.area || 'Sin área').trim().slice(0, 200);
  if (!survey) return response.status(400).json({ error: 'Survey is required' });
  if (!process.env.RESEND_API_KEY) return response.status(500).json({ error: 'Email service is not configured' });

  const resendResponse = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${process.env.RESEND_API_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      from: 'SMSURVEY <notificaciones@sportcstudio.com>',
      to: ['pako@smsoluciones-group.com.mx'],
      subject: `Nueva respuesta: ${survey}`,
      html: `<h2>Nueva respuesta en SMSURVEY</h2><p><strong>Encuesta:</strong> ${escapeHtml(survey)}</p><p><strong>Nombre:</strong> ${escapeHtml(name)}</p><p><strong>Área:</strong> ${escapeHtml(area)}</p><p><a href="https://smsoluciones-survey.vercel.app/#admin">Ver respuestas en el panel</a></p>`
    })
  });

  const result = await resendResponse.json().catch(() => ({}));
  if (!resendResponse.ok) return response.status(502).json({ error: result.message || 'Email delivery failed' });
  return response.status(200).json({ ok: true, id: result.id });
}

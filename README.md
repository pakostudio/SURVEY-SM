# SMSURVEY

Administrador de encuestas de SM Soluciones.

- Producción: https://smsolcuiones-survey.vercel.app
- Código: https://github.com/pakostudio/SURVEY-SM

## Funciones

- Portada con encuestas publicadas.
- Creación y edición de encuestas.
- Preguntas de texto, selección única, selección múltiple, sí/no y escala.
- Publicación o borrador.
- Reordenamiento de preguntas.
- Respuestas privadas por encuesta, detalle y CSV seguro.
- Supabase Auth y políticas RLS para administración.

## Despliegue

Proyecto Vercel: `survey-smsoluciones`.

La aplicación es estática. Vercel sirve `index.html`, `styles.css` y `app.js` directamente.

## Base de datos

La migración está en `supabase/migrations/20260801_smsurvey_admin_builder.sql`.
El administrador inicial es el usuario existente de Supabase Auth `pako@sportcstudio.com`.

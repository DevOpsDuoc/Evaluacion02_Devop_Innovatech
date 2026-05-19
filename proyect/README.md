# Dockerización de Innovatech Chile - tienda perritos

## Estrategia de contenedorización

- El backend se construye como un servicio Spring Boot independiente con un Dockerfile multi-stage, usando una imagen base `slim` para mantener el contenedor ligero y seguro.
- El frontend Vite React se compila en un contenedor de construcción y se sirve de manera optimizada con NGINX en el runtime.
- La orquestación se realiza con `docker-compose.yml` ubicado en la raíz de `proyect/`, uniendo `frontend`, `backend` y `db`.
- La base de datos MySQL utiliza un volumen con nombre para persistencia de datos.

## Justificación técnica: Named Volume vs Bind Mount

Para los requerimientos de Innovatech Chile se seleccionó un `Named Volume` en lugar de un `Bind Mount` porque:

1. **Aislamiento y seguridad:** un volumen con nombre proporciona una separación clara entre el contenedor y el host. No expone rutas de archivos locales ni dependencias del sistema de archivos del host, reduciendo la superficie de ataque y evitando errores por permisos incorrectos.

2. **Portabilidad:** los volúmenes con nombre son gestionados por Docker y se pueden mover entre hosts compatibles más fácilmente que los bind mounts, que dependen de rutas de directorio específicas del servidor y tienen dependencias de entorno.

3. **Integridad de datos:** para la DB y cualquier datos críticos del backend, un volume nombrado garantiza que el contenido persista incluso cuando los contenedores se recrean o actualizan. Esto es esencial en producción, donde los contenedores deben ser efímeros y la persistencia debe delegarse al almacenamiento gestionado.

4. **Rendimiento y consistencia:** Docker optimiza el acceso a volúmenes nombrados para los motores de almacenamiento soportados. Un bind mount puede verse afectado por la latencia y comportamiento variable del sistema de archivos del host.

5. **Bajo acoplamiento:** en producción, el backend debe ser un microservicio independiente y sin estado. Un volume nombrado protege la información crítica de la base de datos y evita que la aplicación dependa de rutas locales del host.

En resumen, la elección de `Named Volumes` es la mejor práctica para proteger la información crítica y garantizar una infraestructura más robusta, portable y segura para el ciclo de CI/CD de Innovatech Chile.

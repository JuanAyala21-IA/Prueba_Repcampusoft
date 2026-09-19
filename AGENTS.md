# REPCAMPUSOFT

## Descripción del proyecto

REPCAMPUSOFT es una aplicación móvil multiplataforma (Flutter + Firebase) para
las Unidades Tecnológicas de Santander (UTS). Permite a los estudiantes
reportar daños en la infraestructura del campus y hacer seguimiento al estado de
sus reportes, y permite a un rol Admin gestionar esos reportes.

## Stack tecnológico

- **Flutter** (Dart) para UI multiplataforma (Android e iOS).
- **Firebase Authentication** para autenticación de usuarios.
- **Cloud Firestore** como base de datos.
- **Firebase Cloud Messaging (FCM)** para notificaciones push.

## Roles

- **Estudiante**: crea reportes de daños y hace seguimiento de su estado.
- **Admin**: gestiona (revisa, actualiza estado, cierra) los reportes.

## Reglas de código

- **Null-safety obligatorio**: no usar tipos nullable innecesarios; evitar `!`
  salvo que el valor esté garantizado.
- **Nombres**: el dominio (entidades, estados, colecciones de Firestore) en
  español; el código (variables, funciones, clases) en inglés.
- **Arquitectura**: organización por features.
- **Widgets**: sin lógica de negocio dentro de los widgets; la lógica vive en
  capas de dominio/datos/estado.

## Regla de fases

- **Trabajar por fases; no implementar nada fuera de la fase actual.**
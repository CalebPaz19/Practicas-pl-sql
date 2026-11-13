/*1. Crear una función llamada F_REGISTRAR_ARTISTA, que reciba como parámetros toda la información 
relacionada. Debe verificar si el artista existe en base al nombre, en caso de no existir que lo cree, de lo contrario 
que actualice la información relacionada al artista. Retornar el código del artista y un parámetro de salida con 
el mensaje de resultado.*/

SELECT * FROM ARTISTAS
WHERE NOMBRE = 'Drake';

SELECT COUNT(*)
    FROM ARTISTAS
    WHERE NOMBRE = 'Drake';

CREATE SEQUENCE SQ_CODIGO_ARTISTA START WITH 22;



CREATE OR REPLACE FUNCTION F_REGISTRAR_ARTISTA (
    FI_NOMBRE ARTISTAS.NOMBRE%TYPE,
    FI_NACIONALIDAD ARTISTAS.NACIONALIDAD%TYPE,
    FI_FECHA_NACIMIENTO ARTISTAS.FECHA_NACIMIENTO%TYPE,
    FO_MENSAJE_RESULTADO OUT varchar2
) RETURN NUMBER AS

V_CANTIDAD_ARTISTAS NUMBER;
V_ID_ARTISTA ARTISTAS.ID_ARTISTA%TYPE;
BEGIN

    SELECT COUNT(*)
    INTO V_CANTIDAD_ARTISTAS
    FROM ARTISTAS
   WHERE UPPER(NOMBRE) = UPPER(FI_NOMBRE);

    IF (V_CANTIDAD_ARTISTAS = 0) then
        
        V_ID_ARTISTA := SQ_CODIGO_ARTISTA.NEXTVAL;
        INSERT INTO ARTISTAS (
            ID_ARTISTA,
            NOMBRE,
            NACIONALIDAD,
            FECHA_NACIMIENTO
        ) VALUES (
            V_ID_ARTISTA,
            FI_NOMBRE,
            FI_NACIONALIDAD,
            FI_FECHA_NACIMIENTO
        );
        FO_MENSAJE_RESULTADO := 'Artista creado correctamente';
        
    ELSE
        SELECT ID_ARTISTA
        INTO V_ID_ARTISTA
        FROM ARTISTAS
        WHERE UPPER(NOMBRE) = UPPER(FI_NOMBRE);

        UPDATE ARTISTAS
        SET NACIONALIDAD = FI_NACIONALIDAD,
            FECHA_NACIMIENTO = FI_FECHA_NACIMIENTO
        WHERE ID_ARTISTA = V_ID_ARTISTA;

        FO_MENSAJE_RESULTADO := 'Artista existente, Datos actualizados';
    END IF;

    COMMIT;
    RETURN V_ID_ARTISTA;

    EXCEPTION
        WHEN OTHERS THEN
        ROLLBACK;
        FO_MENSAJE_RESULTADO := 'Error';
        RETURN NULL;
    
END F_REGISTRAR_ARTISTA;
/

DECLARE
V_ID_ARTISTA NUMBER;
V_MENSAJE varchar2(200);
BEGIN
    V_ID_ARTISTA := F_REGISTRAR_ARTISTA('DRAKE', 'Canada', TO_DATE('24/10/86', 'DD/MM/YY' ), V_MENSAJE );
    DBMS_OUTPUT.PUT_LINE('ID: ' || V_ID_ARTISTA || ' - ' || V_MENSAJE); 
END;


/*2. Crear un procedimiento almacenado llamado P_AGREGAR_REPRODUCCION que reciba como parámetro el 
correo electrónico del usuario el id de la canción y la duración de la reproducción. Deberá obtener el id del 
usuario en base al correo electrónico, en caso de no existir lanzar una excepción personalizada. Crear la 
secuencia correspondiente para el identificador de la reproducción. Por cada  nueva reproducción se debe 
incrementar en uno el campo de cantidad de reproducciones de la tabla canciones y de la tabla estadísticas (esta 
tabla guarda las estadísticas por usuario, por lo cual se debe incrementar solo las estadísticas de ese usuario). 
Verificar que la canción exista, de lo contrario lanzar una excepción personalizada. Enviar dos parámetros de 
salida, el primero sería el código de la reproducción y el segundo un mensaje del resultado de la ejecución del 
procedimiento (ya sea exitoso o fallido). */

SELECT * FROM REPRODUCCIONES;

SELECT * FROM USUARIOS WHERE CORREO = 'john@example.com';
CREATE SEQUENCE SQ_CODIGO_USUARIO START WITH 21;

SELECT * FROM CANCIONES;
CREATE SEQUENCE SQ_CODIGO_REPRODUCCION START WITH 1;

SELECT * FROM ESTADISTICAS;

INSERT INTO ESTADISTICAS (
    ID_USUARIO,
    ID_CANCION,
    CANTIDAD_REPRODUCCIONES,
    FECHA_ULTIMA_REPRODUCCION,
    CANTIDAD_MINUTOS_REPRODUCCION
   ) VALUES ( 1, 1, 1, SYSDATE, 60);

COMMIT;
ROLLBACK;

CREATE OR REPLACE PROCEDURE P_AGREGAR_REPRODUCCION (
    PI_CORREO USUARIOS.CORREO%TYPE,
    PI_ID_CANCION CANCIONES.ID_CANCION%TYPE,
    PI_DURACION_REPRODUCCION REPRODUCCIONES.DURACION_REPRODUCCION_SEGUNDOS%TYPE,
    PO_ID_REPRODUCCION OUT REPRODUCCIONES.ID_REPRODUCCION%TYPE,
    PO_MENSAJE OUT varchar2
) IS
E_CANCION_NO_EXISTE EXCEPTION;
E_USUARIO_NO_EXISTE EXCEPTION;
V_ID_USUARIO USUARIOS.ID_USUARIO%TYPE;
V_ID_REPRODUCCION REPRODUCCIONES.ID_REPRODUCCION%TYPE;
V_CANTIDAD_CANCIONES NUMBER;
V_CANTIDAD_USUARIOS NUMBER;
V_CANTIDAD_ESTADISTICAS NUMBER;

BEGIN

    
    SELECT COUNT(*) 
    INTO V_CANTIDAD_USUARIOS
    FROM USUARIOS
    WHERE CORREO = PI_CORREO;

    IF (V_CANTIDAD_USUARIOS = 0) THEN
        RAISE E_USUARIO_NO_EXISTE;
    END IF;

    SELECT COUNT(*) 
    INTO V_CANTIDAD_CANCIONES
    FROM CANCIONES
    WHERE ID_CANCION = PI_ID_CANCION;

    IF (V_CANTIDAD_CANCIONES = 0) THEN
        RAISE E_CANCION_NO_EXISTE;
    END IF;

    SELECT ID_USUARIO 
    INTO V_ID_USUARIO
    FROM USUARIOS
    WHERE CORREO = PI_CORREO;    

    V_ID_REPRODUCCION := SQ_CODIGO_REPRODUCCION.nextval;
    INSERT INTO REPRODUCCIONES (
        ID_REPRODUCCION,
        ID_USUARIO,
        ID_CANCION,
        FECHA_REPRODUCCION,
        DURACION_REPRODUCCION_SEGUNDOS
    ) VALUES(
        V_ID_REPRODUCCION,
        V_ID_USUARIO,
        PI_ID_CANCION,
        SYSDATE,
        PI_DURACION_REPRODUCCION
    );

    UPDATE CANCIONES
    SET CANTIDAD_REPRODUCCIONES = NVL(CANTIDAD_REPRODUCCIONES, 0) + 1 
    WHERE ID_CANCION = PI_ID_CANCION;

    SELECT COUNT(*)
    INTO V_CANTIDAD_ESTADISTICAS
    FROM ESTADISTICAS
    WHERE ID_USUARIO = V_ID_USUARIO
    AND ID_CANCION = PI_ID_CANCION;

    IF (V_CANTIDAD_ESTADISTICAS = 0) THEN
        INSERT INTO ESTADISTICAS (
            ID_USUARIO,
            ID_CANCION,
            CANTIDAD_REPRODUCCIONES,
            FECHA_ULTIMA_REPRODUCCION,
            CANTIDAD_MINUTOS_REPRODUCCION
        ) VALUES (
            V_ID_USUARIO,
            PI_ID_CANCION,
            1,
            SYSDATE,
            ROUND(PI_DURACION_REPRODUCCION / 60, 2)
        );
        
    ELSE 
        UPDATE ESTADISTICAS
        SET CANTIDAD_REPRODUCCIONES = CANTIDAD_REPRODUCCIONES + 1
        WHERE ID_USUARIO = V_ID_USUARIO 
        AND ID_CANCION = PI_ID_CANCION;

    END IF;

    COMMIT;
    PO_ID_REPRODUCCION := V_ID_REPRODUCCION;
    PO_MENSAJE := 'Reproduccion registrada con exito';


EXCEPTION
    WHEN E_USUARIO_NO_EXISTE THEN
        ROLLBACK;
        PO_ID_REPRODUCCION := NULL;
        PO_MENSAJE := 'Usuario no existe';
    WHEN E_CANCION_NO_EXISTE THEN
        ROLLBACK;
        PO_ID_REPRODUCCION := NULL;
        PO_MENSAJE := 'Cancion no existe';
    WHEN OTHERS THEN
        ROLLBACK;
        PO_ID_REPRODUCCION := NULL;
        PO_MENSAJE := 'Error inesperado: ' || SQLERRM;

END P_AGREGAR_REPRODUCCION;
/

DECLARE
    V_ID      NUMBER;
    V_MENSAJE VARCHAR2(200);
BEGIN
    P_AGREGAR_REPRODUCCION('john@example.com', 1, 180, V_ID, V_MENSAJE);
    DBMS_OUTPUT.PUT_LINE('ID: ' || V_ID || ' - ' || V_MENSAJE);
END;

/*3. Crear un procedimiento almacenado llamado P_CREAR_LISTA_REPRODUCCION  para crear listas de 
reproducción, que reciba de parámetro la lista de los campos relacionados y que valide si el usuario tiene un 
pago realizado para el mes actual, validar esto en base a la fecha de pago, por ejemplo si la fecha de pago es 
05/Sep/2024 se asumiría que pagó el mes de septiembre, si pagó el 01/Nov/2024 significa que pagó el mes de 
noviembre, así que si intenta crear la lista de reproducción para el día de hoy no tendría problema porque pagó 
el mes actual. El procedimiento deberá recibir el código de la primera canción de la lista de reproducción y con 
este campo agregar un registro en la tabla LISTAS_X_CANCIONES. Verificar que la canción exista utilizando 
excepciones personalizadas. */

SELECT * FROM LISTAS_REPRODUCCION;
SELECT * FROM REPRODUCCIONES WHERE ID_USUARIO = 1;

CREATE SEQUENCE SQ_CODIGO_LISTA_REPRODUCCION START WITH 21;

SELECT * FROM PAGOS 
WHERE ID_USUARIO = 1 
AND FECHA_PAGO >= TRUNC(SYSDATE, 'MM')
AND FECHA_PAGO < ADD_MONTHS(TRUNC(SYSDATE, 'MM'), 1);

SELECT * FROM PLANES;

INSERT INTO PLANES (
    ID_PLAN,
    NOMBRE,
    PRECIO,
    DESCRIPCION
   ) VALUES (
        1,
        'Plus',
        126,
        'Sin anuncios'
   );

INSERT INTO PAGOS (
    ID_PAGO,
    ID_USUARIO,
    ID_PLAN,
    FECHA_PAGO
   ) VALUES (
        1,
        1,
        1,
        SYSDATE
   );



CREATE OR REPLACE PROCEDURE P_CREAR_LISTA_REPRODUCCION (
    PI_NOMBRE LISTAS_REPRODUCCION.NOMBRE%TYPE,
    PI_ID_USUARIO LISTAS_REPRODUCCION.ID_USUARIO%TYPE,
    PI_ID_CANCION CANCIONES.ID_CANCION%TYPE,
    PO_MENSAJE OUT VARCHAR2,
    PO_ID_LISTA OUT VARCHAR2
) IS
E_USUARIO_NO_EXISTE EXCEPTION;
E_PAGO_NO_EXISTE EXCEPTION;
E_CANCION_NO_EXISTE EXCEPTION;
V_ID_LISTA NUMBER;
V_CANTIDAD_USUARIOS NUMBER;
V_CANTIDAD_PAGO NUMBER;
V_CANTIDAD_CANCIONES NUMBER;
BEGIN

    SELECT COUNT(*)
    INTO V_CANTIDAD_USUARIOS
    FROM USUARIOS
    WHERE ID_USUARIO = PI_ID_USUARIO;

    IF (V_CANTIDAD_USUARIOS = 0) THEN
        RAISE E_USUARIO_NO_EXISTE;
    END IF;

    SELECT COUNT(*) 
    INTO V_CANTIDAD_PAGO
    FROM PAGOS
    WHERE ID_USUARIO = PI_ID_USUARIO 
    AND FECHA_PAGO >= TRUNC(SYSDATE, 'MM')
    AND FECHA_PAGO < ADD_MONTHS(TRUNC(SYSDATE, 'MM'), 1);

    IF (V_CANTIDAD_PAGO = 0) THEN 
        RAISE E_PAGO_NO_EXISTE;
    END IF;

    SELECT COUNT(*)
    INTO V_CANTIDAD_CANCIONES
    FROM CANCIONES
    WHERE ID_CANCION = PI_ID_CANCION;

    IF (V_CANTIDAD_CANCIONES = 0) THEN
        RAISE E_CANCION_NO_EXISTE;
    END IF;

    V_ID_LISTA := SQ_CODIGO_LISTA_REPRODUCCION.NEXTVAL;

    INSERT INTO LISTAS_REPRODUCCION (
    ID_LISTA,
    NOMBRE,
    ID_USUARIO,
    FECHA_CREACION
   ) VALUES (
        V_ID_LISTA,
        PI_NOMBRE,
        PI_ID_USUARIO,
        SYSDATE
   );

   INSERT INTO LISTAS_X_CANCIONES (
    ID_LISTA,
    ID_CANCION,
    FECHA_HORA_AGREGADA
   ) VALUES (
        V_ID_LISTA,
        PI_ID_CANCION,
        SYSDATE
   );

   COMMIT;
    PO_ID_LISTA := V_ID_LISTA;
    PO_MENSAJE  := 'Lista de reproduccion creada con exito';

EXCEPTION
    WHEN E_USUARIO_NO_EXISTE THEN
        ROLLBACK;
        PO_ID_LISTA := NULL;
        PO_MENSAJE  := 'Error: el usuario no existe';
    WHEN E_PAGO_NO_EXISTE THEN
        ROLLBACK;
        PO_ID_LISTA := NULL;
        PO_MENSAJE  := 'Error: el usuario no ha pagado el mes actual';
    WHEN E_CANCION_NO_EXISTE THEN
        ROLLBACK;
        PO_ID_LISTA := NULL;
        PO_MENSAJE  := 'Error: la cancion no existe';
    WHEN OTHERS THEN
        ROLLBACK;
        PO_ID_LISTA := NULL;
        PO_MENSAJE  := 'Error inesperado: ' || SQLERRM;
END P_CREAR_LISTA_REPRODUCCION;
/


DECLARE
MENSAJE varchar2(200);
ID_LISTA NUMBER;
BEGIN
    P_CREAR_LISTA_REPRODUCCION('Lista de prueba', 1, 1, MENSAJE, ID_LISTA);
    DBMS_OUTPUT.PUT_LINE('ID: ' || ID_LISTA || ',' || MENSAJE);
END;
/*4. Crear un procedimiento almacenado llamado P_GENERAR_ESTADISTICAS que calcule las estadísticas de 
reproducción de una canción específica y lo inserte en la tabla de estadisticas. El procedimiento debe recibir 
id_cancion y actualizar los datos de cantidad_reproducciones y cantidad_minutos_reproduccion en la tabla 
estadisticas para cada usuario que haya reproducido la canción. (Tip, deberá realizar un agrupado para obtener 
el conteo de las reproducciones y sumar los minutos de reproducción). En caso de que ya exista la estadística 
de un usuario que la elimine y la vuelva a insertar. */
SELECT
        ID_USUARIO,
        ID_CANCION,
        COUNT(*),
        MAX(FECHA_REPRODUCCION),
        ROUND(SUM(DURACION_REPRODUCCION_SEGUNDOS) / 60, 2)
    FROM REPRODUCCIONES
    WHERE ID_CANCION = 1
    GROUP BY ID_USUARIO, ID_CANCION;

CREATE OR REPLACE PROCEDURE P_GENERAR_ESTADISTICAS (
    PI_ID_CANCION IN CANCIONES.ID_CANCION%TYPE
) IS
    E_CANCION_NO_EXISTE  EXCEPTION;
    V_CANTIDAD_CANCIONES NUMBER;
    V_USUARIOS_PROCESADOS NUMBER;
BEGIN
    -- Validar canción
    SELECT COUNT(*) INTO V_CANTIDAD_CANCIONES
    FROM CANCIONES
    WHERE ID_CANCION = PI_ID_CANCION;

    IF V_CANTIDAD_CANCIONES = 0 THEN
        RAISE E_CANCION_NO_EXISTE;
    END IF;

    -- Eliminar estadísticas existentes de esa canción
    DELETE FROM ESTADISTICAS
    WHERE ID_CANCION = PI_ID_CANCION;

    -- Calcular e insertar estadísticas por usuario
    INSERT INTO ESTADISTICAS (
        ID_USUARIO,
        ID_CANCION,
        CANTIDAD_REPRODUCCIONES,
        FECHA_ULTIMA_REPRODUCCION,
        CANTIDAD_MINUTOS_REPRODUCCION
    )
    SELECT
        ID_USUARIO,
        ID_CANCION,
        COUNT(*),
        MAX(FECHA_REPRODUCCION),
        ROUND(SUM(DURACION_REPRODUCCION_SEGUNDOS) / 60, 2)
    FROM REPRODUCCIONES
    WHERE ID_CANCION = PI_ID_CANCION
    GROUP BY ID_USUARIO, ID_CANCION;

    V_USUARIOS_PROCESADOS := SQL%ROWCOUNT;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Estadisticas generadas para ' || V_USUARIOS_PROCESADOS || ' usuario(s)');

EXCEPTION
    WHEN E_CANCION_NO_EXISTE THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: la cancion no existe');
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
END P_GENERAR_ESTADISTICAS;
/

BEGIN
    P_GENERAR_ESTADISTICAS(1);
END;
/

SELECT * FROM ESTADISTICAS WHERE ID_CANCION = 1;
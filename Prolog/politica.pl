:- encoding(utf8).

/*  politica.pl  --  CEmestre, Etapa 3 (Prolog)  --  Persona A
 *
 *  Reglas de política académica y predicado principal de validación.
 *
 *  CONTRATO DE DATOS (acordar con B y C)
 *  -------------------------------------
 *  Curso:        curso(Codigo, Grupo, Creditos, Carrera, Area)
 *                 Codigo  : átomo      (ej. 'CE1106')
 *                 Grupo   : entero     (ej. 1)
 *                 Creditos: entero
 *                 Carrera : átomo      (ej. ce, ee)
 *                 Area    : átomo      (ej. programacion, matematica)
 *  Combinacion:  lista de términos curso/5.
 *
 *  Hechos de política (los define C en politica_datos.pl):
 *      max_porcentaje(Carrera, Pct).   % Pct: entero 0..100, máx. de créditos
 *      max_cursos_area(N).             % máx. de cursos de una misma área
 *      incompatible(CodigoA, CodigoB). % se declara UNA vez; se usa simétrico
 *
 *  Razón de rechazo (término compuesto, lo exporta B):
 *      balance_carreras(Carrera, Creditos, Total, MaxPct)
 *      limite_area(Area, Cantidad, Max)
 *      incompatibilidad(CodigoA, CodigoB)
 *      ninguna                       % cuando la combinación cumple
 *
 *  Orden de las reglas (decisión de diseño, justificada abajo):
 *      1. balance entre carreras
 *      2. límite por área
 *      3. incompatibilidad
 *
 *  Sin assert/retract ni variables globales: todo por argumentos y unificación.
 */

% Los hechos de política viven en otro archivo; así no hay error de
% "procedure does not exist" si se consulta politica.pl antes que los datos.
:- multifile max_porcentaje/2, max_cursos_area/1, incompatible/2.
:- discontiguous max_porcentaje/2, max_cursos_area/1, incompatible/2.


/* ===================================================================
 *  EVALUACIÓN PRINCIPAL
 * =================================================================== */

%  evaluar(+Combinacion, ?Cumple, ?Razon)
%
%  Cumple = true,  Razon = ninguna       si no viola ninguna regla.
%  Cumple = false, Razon = <primera>     si viola alguna; <primera> según
%                                        el orden de violacion/2.
%
%  Cláusula 1: si existe una violación, el corte (!) fija la PRIMERA y
%  descarta las demás: evita que el backtracking devuelva razones
%  posteriores y que se alcance la cláusula 2.
%  Cláusula 2: negación por falla (\+): cumple si NO se puede demostrar
%  ninguna violación. Es lo que hace correcto evaluar(C, true, R):
%  la cláusula 1 no unifica con true y la 2 comprueba de verdad.
evaluar(Combinacion, false, Razon) :-
    violacion(Combinacion, Razon),
    !.
evaluar(Combinacion, true, ninguna) :-
    \+ violacion(Combinacion, _).


%  violacion(+Combinacion, -Razon)
%  El ORDEN de estas cláusulas es el orden de prioridad de las reglas.
%  Los cortes impiden que, tras fallar algo más adelante, se pruebe otra
%  violación de la misma regla (cada regla aporta a lo sumo una razón).
%
%  Justificación del orden: de lo más global a lo más específico. El balance
%  mira toda la combinación, el límite por área mira un subconjunto, y la
%  incompatibilidad mira un par concreto de cursos.
violacion(Combinacion, Razon) :-
    viola_balance(Combinacion, Razon), !.
violacion(Combinacion, Razon) :-
    viola_area(Combinacion, Razon), !.
violacion(Combinacion, Razon) :-
    viola_incompatibilidad(Combinacion, Razon), !.


/* ===================================================================
 *  REGLA 1: BALANCE ENTRE CARRERAS
 * =================================================================== */

%  viola_balance(+Combinacion, -balance_carreras(Carrera,Cred,Total,Max))
%  Una carrera viola si Cred/Total > Max/100. Se compara con enteros
%  (Cred*100 > Max*Total) para evitar errores de punto flotante en el
%  caso límite "exactamente igual al máximo" (eso SÍ es válido).
viola_balance(Combinacion, balance_carreras(Carrera, Cred, Total, Max)) :-
    creditos_totales(Combinacion, Total),
    carrera_en(Combinacion, Carrera),
    max_porcentaje(Carrera, Max),
    creditos_carrera(Combinacion, Carrera, Cred),
    Cred * 100 > Max * Total.

%  carrera_en(+Combinacion, ?Carrera): carreras presentes, sin repetir.
carrera_en(Combinacion, Carrera) :-
    findall(C, member(curso(_, _, _, C, _), Combinacion), Cs),
    sort(Cs, Unicas),
    member(Carrera, Unicas).

%  creditos_totales(+Combinacion, -Total)
creditos_totales(Combinacion, Total) :-
    sumar_creditos(Combinacion, Total).

%  creditos_carrera(+Combinacion, +Carrera, -Suma)
creditos_carrera(Combinacion, Carrera, Suma) :-
    findall(Cr, member(curso(_, _, Cr, Carrera, _), Combinacion), Crs),
    sum_list(Crs, Suma).

sumar_creditos([], 0).
sumar_creditos([curso(_, _, Cr, _, _) | Resto], Total) :-
    sumar_creditos(Resto, Parcial),
    Total is Parcial + Cr.

%  porcentaje_carrera(+Combinacion, +Carrera, -Pct)
%  Utilidad informativa (Pct como flotante); la regla usa aritmética entera.
porcentaje_carrera(Combinacion, Carrera, Pct) :-
    creditos_totales(Combinacion, Total),
    Total > 0,
    creditos_carrera(Combinacion, Carrera, Suma),
    Pct is Suma * 100 / Total.


/* ===================================================================
 *  REGLA 2: LÍMITE POR ÁREA
 * =================================================================== */

%  viola_area(+Combinacion, -limite_area(Area, Cantidad, Max))
viola_area(Combinacion, limite_area(Area, Cantidad, Max)) :-
    max_cursos_area(Max),
    area_en(Combinacion, Area),
    cursos_por_area(Combinacion, Area, Cantidad),
    Cantidad > Max.

area_en(Combinacion, Area) :-
    findall(A, member(curso(_, _, _, _, A), Combinacion), As),
    sort(As, Unicas),
    member(Area, Unicas).

%  cursos_por_area(+Combinacion, +Area, -Cantidad)
cursos_por_area(Combinacion, Area, Cantidad) :-
    findall(Cod, member(curso(Cod, _, _, _, Area), Combinacion), Cods),
    length(Cods, Cantidad).


/* ===================================================================
 *  REGLA 3: INCOMPATIBILIDAD (simétrica)
 * =================================================================== */

%  viola_incompatibilidad(+Combinacion, -incompatibilidad(A, B))
%  Se busca cualquier par declarado (en cualquier sentido) cuyos dos
%  cursos estén en la combinación.
viola_incompatibilidad(Combinacion, incompatibilidad(A, B)) :-
    incompatibles(A, B),
    member(curso(A, _, _, _, _), Combinacion),
    member(curso(B, _, _, _, _), Combinacion).

%  incompatibles(?A, ?B): cierre simétrico del hecho incompatible/2.
%  Se declara un solo sentido en los datos; aquí se obtiene el otro.
incompatibles(A, B) :- incompatible(A, B).
incompatibles(A, B) :- incompatible(B, A).


/* ===================================================================
 *  PREDICADO MULTIMODO
 * =================================================================== */

%  curso_en_combinacion(?Codigo, ?Grupo, +Combinacion)
%
%  Modo 1 (verificación): Codigo y Grupo instanciados -> true/false.
%      ?- curso_en_combinacion('CE1106', 1, Comb).
%  Modo 2 (enumeración): variables libres -> enumera por backtracking
%  cada par curso-grupo de la combinación.
%      ?- curso_en_combinacion(Cod, Gr, Comb).
%  Modo 3 (parcial): fijar solo el código -> devuelve sus grupos.
%      ?- curso_en_combinacion('CE1106', Gr, Comb).
%  Comb debe estar instanciada.
curso_en_combinacion(Codigo, Grupo, Combinacion) :-
    member(curso(Codigo, Grupo, _, _, _), Combinacion).


/* ===================================================================
 *  PARA B (sugerencia de retiro, grupos de 4)
 * =================================================================== */

%  Para probar "quitar un curso", B puede usar select/3 y volver a llamar
%  a evaluar/3 (sin duplicar lógica):
%
%      select(Curso, Combinacion, Resto),
%      evaluar(Resto, true, _)
%
%  Un caso límite a tener en cuenta: tras retirar, Resto = [] cumple
%  trivialmente (no hay carreras ni áreas). B decide si lo acepta como
%  sugerencia válida.

:- encoding(utf8).
:- use_module(library(http/json)).

exportar_resultados(Ruta, Resultados) :-
    maplist(resultado_json, Resultados, Objetos),
    setup_call_cleanup(
        open(Ruta, write, Out, [encoding(utf8)]),
        ( json_write_dict(Out, _{combinaciones: Objetos}, [width(1)]),
          nl(Out) ),
        close(Out)).

resultado_json(resultado(Id, Pares, Cumple, Razon, Sugerencia),
               _{id: Id, cursos: Cursos, cumple: Cumple,
                 razon: RazonJson, sugerencia: SugJson}) :-
    maplist(par_json, Pares, Cursos),
    razon_json(Razon, RazonJson),
    sugerencia_json(Sugerencia, Cumple, SugJson).

par_json(Cod-Gr, _{codigo: Cod, grupo: Gr}).

razon_json(ninguna, null).
razon_json(balance_carreras(Carrera, Cred, Total, Max),
           _{regla: balance_carreras, carrera: Carrera, creditos: Cred,
             total: Total, max_porcentaje: Max}).
razon_json(limite_area(Area, Cantidad, Max),
           _{regla: limite_area, area: Area, cantidad: Cantidad, maximo: Max}).
razon_json(incompatibilidad(A, B),
           _{regla: incompatibilidad, curso_a: A, curso_b: B}).

sugerencia_json(_, true, null).
sugerencia_json(retirar(Cod-Gr), false,
                _{existe: true, retirar: _{codigo: Cod, grupo: Gr}}).
sugerencia_json(ninguna, false, _{existe: false, retirar: null}).
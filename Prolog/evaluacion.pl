:- encoding(utf8).
:- ensure_loaded(politica).

%  veredicto(+Combinaciones, ?Id, ?Combinacion, ?Cumple, ?Razon)
%  Con Id libre, combinacion_id/4 enumera cada combinación por backtracking;
%  evaluar/3 (de A) da el veredicto y la primera razón de rechazo.
veredicto(Combinaciones, Id, Combinacion, Cumple, Razon) :-
    combinacion_id(Combinaciones, 1, Id, Combinacion),
    evaluar(Combinacion, Cumple, Razon).

%  combinacion_id(+Combinaciones, +N, ?Id, ?Combinacion)
%  Cláusula 1: la cabeza de la lista es la combinación número N.
%  Cláusula 2: se descarta la cabeza y se sigue con N+1. Al fallar algo
%  más adelante, Prolog vuelve a la cláusula 2 y produce la siguiente.
combinacion_id([Combinacion | _], N, N, Combinacion).
combinacion_id([_ | Resto], N0, Id, Combinacion) :-
    N1 is N0 + 1,
    combinacion_id(Resto, N1, Id, Combinacion).

%  evaluar_todas(+Combinaciones, -Resultados)
%  Resultados = [resultado(Id, Pares, Cumple, Razon, Sugerencia), ...]
evaluar_todas(Combinaciones, Resultados) :-
    findall(resultado(Id, Pares, Cumple, Razon, Sugerencia),
            ( veredicto(Combinaciones, Id, Combinacion, Cumple, Razon),
              pares_curso_grupo(Combinacion, Pares),
              sugerencia(Cumple, Combinacion, Sugerencia) ),
            Resultados).

%  sugerencia(+Cumple, +Combinacion, -Sugerencia)
sugerencia(true, _, ninguna).
sugerencia(false, Combinacion, Sugerencia) :-
    sugerir_retiro(Combinacion, Sugerencia).

%  sugerir_retiro(+Combinacion, -Sugerencia)
%  retirar(Codigo-Grupo): primer curso cuyo retiro hace cumplir.
%  ninguna: ningún retiro individual funciona.
%  Cláusula 1: el corte se queda con el primer retiro válido.
%  Cláusula 2: negación por falla, solo si no existe ningún retiro válido.
sugerir_retiro(Combinacion, retirar(Par)) :-
    retiro_valido(Combinacion, Par), !.
sugerir_retiro(Combinacion, ninguna) :-
    \+ retiro_valido(Combinacion, _).

%  retiro_valido(+Combinacion, ?Codigo-Grupo)
%  select/3 quita un curso a la vez (backtracking) y se vuelve a llamar a
%  evaluar/3 sobre el resto: no se duplica la lógica de las reglas.
retiro_valido(Combinacion, Cod-Gr) :-
    select(curso(Cod, Gr, _, _, _), Combinacion, Resto),
    Resto \== [],
    evaluar(Resto, true, _).

%  pares_curso_grupo(+Combinacion, -Pares)   Pares = [Codigo-Grupo, ...]
pares_curso_grupo([], []).
pares_curso_grupo([curso(Cod, Gr, _, _, _) | Resto], [Cod-Gr | Pares]) :-
    pares_curso_grupo(Resto, Pares).
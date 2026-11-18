:- encoding(utf8).

:- consult(cargar).
:- consult(evaluacion).
:- consult(politica_datos).
:- consult(exportar).

:- initialization(main, main).

%  main(+Argumentos)   Argumentos = [RutaEntrada, RutaSalida]
main([Entrada, Salida]) :-
    !,
    cargar_combinaciones(Entrada, Combinaciones),
    evaluar_todas(Combinaciones, Resultados),
    exportar_resultados(Salida, Resultados),
    length(Resultados, N),
    format("Evaluadas ~d combinaciones. Resultado en ~w~n", [N, Salida]).
main(_) :-
    format(user_error, "Uso: swipl main.pl entrada.json salida.json~n", []),
    halt(1).
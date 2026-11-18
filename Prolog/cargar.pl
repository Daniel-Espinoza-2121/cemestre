:- encoding(utf8).
:- use_module(library(http/json)).

cargar_combinaciones(Ruta, Combinaciones) :-
    setup_call_cleanup(
        open(Ruta, read, In, [encoding(utf8)]),
        json_read_dict(In, Doc, [value_string_as(atom)]),
        close(In)),
    maplist(json_a_combinacion, Doc.combinaciones, Combinaciones).

json_a_combinacion(Objeto, Combinacion) :-
    maplist(json_a_curso, Objeto.cursos, Combinacion).

json_a_curso(Objeto, curso(Codigo, Grupo, Creditos, Carrera, Area)) :-
    Codigo   = Objeto.codigo,
    Grupo    = Objeto.grupo,
    Creditos = Objeto.creditos,
    Carrera  = Objeto.carrera,
    Area     = Objeto.area.
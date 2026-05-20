/*
Pips solver.

Main predicate:
  solucio_pips(+Regions, +Pieces, ?Solution)

Regions is the list of region(Type, Target, Coords) terms that defines the
board and its constraints. Pieces is the ordered list of domino pieces. Solution
is the ordered list of coordinate pairs where each piece is placed. The nth
entry in Solution corresponds to the nth entry in Pieces.

Example checks a stored solution:
  ?- puzzle(20250818, easy, Regions, Pieces, Solution),
     solucio_pips(Regions, Pieces, Solution).

Example generates a solution:
  ?- puzzle(20250818, easy, Regions, Pieces, _),
     solucio_pips(Regions, Pieces, Solution).
*/

% list_append(+List1, +List2, -Result)
% Result is List1 followed by List2. Used to build the board coordinate list.
list_append([], L, L).
list_append([X | Xs], Ys, [X | Zs]) :- list_append(Xs, Ys, Zs).

% list_contains(?Element, +List)
% True when Element can be unified with an element of List.
list_contains(X, [X | _]).
list_contains(X, [_ | L]) :- list_contains(X, L).

% all_equal_values(+Values)
% True when all numbers in Values are equal. Empty and one-cell regions pass.
all_equal_values([]).
all_equal_values([_]).
all_equal_values([X, X | L]) :- all_equal_values([X | L]).

% all_distinct_values(+Values)
% True when no number appears twice in Values.
all_distinct_values([]).
all_distinct_values([_]).
all_distinct_values([X | L]) :- not(list_contains(X, L)), all_distinct_values(L).

% sum_values(+Values, ?Total)
% Total is the arithmetic sum of Values.
sum_values([], 0).
sum_values([X | L], Total) :- sum_values(L, RestTotal), Total is X + RestTotal.

% adjacent_coords(+Coord1, +Coord2)
% True when Coord1 and Coord2 share one side on the board.
adjacent_coords([Row1, Col1], [Row2, Col2]) :- 1 is abs(Row1 - Row2) + abs(Col1 - Col2).

% select_coord(?Coord, +Coords, -RemainingCoords)
% Chooses Coord from Coords and removes that occurrence from RemainingCoords.
select_coord(X, [X | L], L).
select_coord(X, [Y | L], [Y | R]) :- select_coord(X, L, R).

% coords_from_regions(+Regions, -Coords)
% Coords contains all board coordinates listed by the regions.
coords_from_regions([], []).
coords_from_regions([region(_, _, Coords) | RegionRest], BoardCoords) :-
    coords_from_regions(RegionRest, RestCoords),
    list_append(Coords, RestCoords, BoardCoords).

% place_pieces(+Pieces, +FreeCoords, ?Solution, -Cells)
% Places each piece on two unused adjacent coordinates.
% Cells stores the value assigned to each occupied coordinate.
place_pieces([], [], [], []).
place_pieces([[V1, V2] | PieceRest], FreeCoords, [[C1, C2] | SolutionRest], [cell(C1, V1), cell(C2, V2) | CellRest]) :-
    select_coord(C1, FreeCoords, FreeCoords1),
    select_coord(C2, FreeCoords1, FreeCoords2),
    adjacent_coords(C1, C2),
    place_pieces(PieceRest, FreeCoords2, SolutionRest, CellRest).

% values_for_coords(+Coords, +Cells, -Values)
% Values are the numbers assigned to Coords in the same order.
values_for_coords([], _, []).
values_for_coords([Coord | CoordRest], Cells, [Value | ValueRest]) :-
    list_contains(cell(Coord, Value), Cells),
    values_for_coords(CoordRest, Cells, ValueRest).

% values_satisfy_constraint(+Values, +Type, +Target)
% True when Values satisfy the region restriction Type/Target.
values_satisfy_constraint(_, empty, nil).
values_satisfy_constraint(Values, equals, nil) :- all_equal_values(Values).
values_satisfy_constraint(Values, unequal, nil) :- all_distinct_values(Values).
values_satisfy_constraint(Values, sum, Target) :- sum_values(Values, Target).
values_satisfy_constraint(Values, less, Target) :- sum_values(Values, Sum), Sum < Target.
values_satisfy_constraint(Values, greater, Target) :- sum_values(Values, Sum), Sum > Target.

% region_satisfied_by_cells(+Region, +Cells)
% True when the values assigned to Region's coordinates satisfy its restriction.
region_satisfied_by_cells(region(Type, Target, Coords), Cells) :-
    values_for_coords(Coords, Cells, Values),
    values_satisfy_constraint(Values, Type, Target).

% regions_satisfied_by_cells(+Regions, +Cells)
% True when every region is satisfied by the current board values.
regions_satisfied_by_cells([], _).
regions_satisfied_by_cells([Region | RegionRest], Cells) :-
    region_satisfied_by_cells(Region, Cells),
    regions_satisfied_by_cells(RegionRest, Cells).

% solucio_pips(+Regions, +Pieces, ?Solution)
% Checks or generates a Pips solution using the ordered list of Pieces.
solucio_pips(Regions, Pieces, Solution) :-
    coords_from_regions(Regions, BoardCoords),
    place_pieces(Pieces, BoardCoords, Solution, Cells),
    regions_satisfied_by_cells(Regions, Cells).

/*******************************************************/

puzzle(20250818, easy,
  [region(empty, nil, [[0,0]]),
   region(equals, nil, [[0,1],[0,2],[1,1],[1,2]]),
   region(sum, 5, [[0,3]]),
   region(sum, 12, [[2,1],[2,2]])],
  [[2,2],
   [2,3],
   [5,2],
   [6,6]],
  [[[1,1],[1,2]],
   [[0,1],[0,0]],
   [[0,3],[0,2]],
   [[2,1],[2,2]]]).


puzzle(20250818, medium,
  [region(less, 13, [[0,0],[1,0],[1,1]]),
   region(empty, nil, [[0,1]]),
   region(sum, 18, [[1,3],[2,2],[2,3]]),
   region(less, 3, [[1,4]]),
   region(sum, 2, [[2,1]]),
   region(greater, 4, [[2,4]])],
  [[1,6],
   [4,4],
   [6,3],
   [2,6],
   [5,6]],
  [[[1,4],[1,3]],
   [[1,0],[1,1]],
   [[0,1],[0,0]],
   [[2,1],[2,2]],
   [[2,4],[2,3]]]).


puzzle(20250818, hard,
  [region(less, 3, [[0,1],[0,2]]),
   region(empty, nil, [[0,6]]),
   region(equals, nil, [[0,7],[1,7]]),
   region(equals, nil, [[1,0],[1,1]]),
   region(sum, 1, [[1,2]]),
   region(equals, nil, [[1,4],[2,4]]),
   region(sum, 18, [[1,5],[1,6],[2,6]]),
   region(sum, 10, [[1,8],[2,8]]),
   region(sum, 0, [[2,0],[2,1],[2,2],[2,3]]),
   region(sum, 4, [[2,7]])],
  [[0,0],
   [6,6],
   [1,6],
   [1,1],
   [2,0],
   [0,6],
   [2,6],
   [3,1],
   [3,5],
   [4,5]],
  [[[2,1],[2,2]],
   [[1,6],[2,6]],
   [[1,2],[1,1]],
   [[0,1],[0,2]],
   [[2,4],[2,3]],
   [[2,0],[1,0]],
   [[1,4],[1,5]],
   [[0,7],[0,6]],
   [[1,7],[1,8]],
   [[2,7],[2,8]]]).


puzzle(20250819, easy,
  [region(sum, 6, [[0,1]]),
   region(empty, nil, [[1,0]]),
   region(empty, nil, [[1,1]]),
   region(sum, 5, [[1,2]]),
   region(equals, nil, [[2,0],[2,1]]),
   region(empty, nil, [[2,2]]),
   region(sum, 0, [[3,1]])],
  [[6,1],
   [2,4],
   [5,3],
   [2,0]],
  [[[0,1],[1,1]],
   [[2,0],[1,0]],
   [[1,2],[2,2]],
   [[2,1],[3,1]]]).


puzzle(20250819, medium,
  [region(empty, nil, [[0,0]]),
   region(greater, 3, [[0,3]]),
   region(equals, nil, [[1,0],[1,1],[1,2],[1,3]]),
   region(sum, 3, [[2,2],[2,3],[3,3]]),
   region(empty, nil, [[2,4]]),
   region(sum, 2, [[3,2]]),
   region(sum, 6, [[3,4]])],
  [[2,1],
   [1,6],
   [1,3],
   [3,4],
   [3,3],
   [1,0]],
  [[[3,2],[2,2]],
   [[3,3],[3,4]],
   [[0,0],[1,0]],
   [[1,3],[0,3]],
   [[1,1],[1,2]],
   [[2,3],[2,4]]]).


puzzle(20250819, hard,
  [region(unequal, nil, [[0,0],[1,0],[2,0]]),
   region(sum, 0, [[0,1],[1,1]]),
   region(equals, nil, [[2,1],[2,2],[3,2],[3,3],[4,3],[4,4]]),
   region(sum, 2, [[2,3]]),
   region(sum, 7, [[2,5],[3,5]]),
   region(sum, 3, [[3,1]]),
   region(sum, 5, [[3,4]]),
   region(sum, 4, [[4,2]]),
   region(sum, 6, [[4,5]])],
  [[4,1],
   [5,6],
   [6,1],
   [3,1],
   [5,1],
   [1,0],
   [3,4],
   [1,2],
   [0,4]],
  [[[4,2],[4,3]],
   [[1,0],[2,0]],
   [[4,5],[4,4]],
   [[3,1],[3,2]],
   [[3,4],[3,3]],
   [[2,1],[1,1]],
   [[2,5],[3,5]],
   [[2,2],[2,3]],
   [[0,1],[0,0]]]).


puzzle(20250820, easy,
  [region(empty, nil, [[0,0]]),
   region(sum, 0, [[0,1],[0,2],[0,3]]),
   region(sum, 4, [[1,0]]),
   region(empty, nil, [[1,1]]),
   region(sum, 2, [[1,2],[1,3]])],
  [[0,0],
   [4,6],
   [1,0],
   [5,1]],
  [[[0,1],[0,2]],
   [[1,0],[0,0]],
   [[1,3],[0,3]],
   [[1,1],[1,2]]]).


puzzle(20250820, medium,
  [region(equals, nil, [[0,2],[1,2]]),
   region(sum, 2, [[0,3],[1,3]]),
   region(sum, 2, [[1,1]]),
   region(equals, nil, [[2,1],[2,2],[2,3],[3,1]]),
   region(sum, 3, [[3,0]])],
  [[3,3],
   [6,6],
   [6,3],
   [6,2],
   [1,1]],
  [[[0,2],[1,2]],
   [[2,2],[2,3]],
   [[3,1],[3,0]],
   [[2,1],[1,1]],
   [[0,3],[1,3]]]).


puzzle(20250820, hard,
  [region(sum, 6, [[0,0]]),
   region(sum, 2, [[1,0],[2,0]]),
   region(empty, nil, [[3,0]]),
   region(empty, nil, [[4,0]]),
   region(sum, 4, [[4,1],[4,2]]),
   region(equals, nil, [[4,3],[4,4],[4,5],[5,5]]),
   region(empty, nil, [[5,0]]),
   region(equals, nil, [[6,0],[7,0],[8,0]]),
   region(equals, nil, [[6,5],[7,5],[8,5]])],
  [[2,1],
   [2,3],
   [4,6],
   [1,6],
   [4,4],
   [6,6],
   [5,5],
   [2,5],
   [6,5]],
  [[[3,0],[2,0]],
   [[4,1],[4,0]],
   [[6,0],[5,0]],
   [[1,0],[0,0]],
   [[7,0],[8,0]],
   [[7,5],[8,5]],
   [[4,4],[4,5]],
   [[4,2],[4,3]],
   [[6,5],[5,5]]]).


puzzle(20250821, easy,
  [region(sum, 2, [[0,0]]),
   region(sum, 7, [[0,1],[1,1]]),
   region(sum, 7, [[2,1],[3,1]]),
   region(sum, 9, [[4,1],[5,1]]),
   region(sum, 2, [[5,2]])],
  [[2,3],
   [4,5],
   [4,3],
   [4,2]],
  [[[0,0],[0,1]],
   [[3,1],[4,1]],
   [[1,1],[2,1]],
   [[5,1],[5,2]]]).


puzzle(20250821, medium,
  [region(unequal, nil, [[0,1],[1,1],[2,1]]),
   region(sum, 5, [[3,1],[3,2],[4,1],[4,2],[5,2]]),
   region(sum, 5, [[3,3]]),
   region(empty, nil, [[4,0]])],
  [[1,5],
   [1,1],
   [5,0],
   [3,2],
   [6,5]],
  [[[4,1],[4,0]],
   [[4,2],[5,2]],
   [[3,3],[3,2]],
   [[2,1],[3,1]],
   [[0,1],[1,1]]]).


puzzle(20250821, hard,
  [region(equals, nil, [[0,1],[1,0],[1,1],[1,2],[2,1]]),
   region(empty, nil, [[0,2]]),
   region(sum, 10, [[0,3],[1,3]]),
   region(empty, nil, [[2,0]]),
   region(sum, 0, [[3,1],[3,2],[3,3],[3,4]]),
   region(equals, nil, [[4,4],[5,3],[5,4],[5,5],[6,4]]),
   region(empty, nil, [[4,5]]),
   region(sum, 3, [[5,2]]),
   region(sum, 4, [[6,2],[6,3]])],
  [[4,4],
   [1,1],
   [0,5],
   [4,1],
   [5,6],
   [1,0],
   [6,1],
   [2,5],
   [5,5],
   [0,0],
   [0,3]],
  [[[0,2],[0,3]],
   [[5,3],[5,4]],
   [[3,1],[2,1]],
   [[6,3],[6,4]],
   [[1,2],[1,3]],
   [[4,4],[3,4]],
   [[4,5],[5,5]],
   [[2,0],[1,0]],
   [[0,1],[1,1]],
   [[3,2],[3,3]],
   [[6,2],[5,2]]]).


puzzle(20250822, easy,
  [region(sum, 1, [[0,0]]),
   region(empty, nil, [[0,1]]),
   region(sum, 0, [[0,2]]),
   region(empty, nil, [[1,0]]),
   region(sum, 1, [[2,0]]),
   region(sum, 8, [[2,1],[2,2]]),
   region(empty, nil, [[3,2]]),
   region(equals, nil, [[4,0],[4,1]])],
  [[5,1],
   [6,0],
   [1,1],
   [1,6],
   [4,3]],
  [[[2,1],[2,0]],
   [[0,1],[0,2]],
   [[4,0],[4,1]],
   [[0,0],[1,0]],
   [[3,2],[2,2]]]).


puzzle(20250822, medium,
  [region(empty, nil, [[0,0]]),
   region(sum, 3, [[0,1],[0,2]]),
   region(equals, nil, [[1,0],[1,1],[1,2]]),
   region(sum, 5, [[2,0]]),
   region(equals, nil, [[2,1],[3,1]]),
   region(sum, 6, [[2,3],[3,2],[3,3]])],
  [[6,5],
   [5,5],
   [1,1],
   [0,4],
   [4,6],
   [5,3]],
  [[[2,1],[2,0]],
   [[1,0],[1,1]],
   [[2,3],[3,3]],
   [[0,1],[0,0]],
   [[3,2],[3,1]],
   [[1,2],[0,2]]]).


puzzle(20250822, hard,
  [region(sum, 18, [[0,1],[0,2],[0,3]]),
   region(equals, nil, [[0,4],[1,4],[2,4]]),
   region(empty, nil, [[1,0]]),
   region(sum, 0, [[1,1],[1,2],[2,1],[2,2],[2,3]]),
   region(empty, nil, [[1,3]]),
   region(sum, 1, [[3,1]]),
   region(empty, nil, [[3,2]]),
   region(equals, nil, [[4,2],[5,2]]),
   region(sum, 2, [[4,4]]),
   region(equals, nil, [[5,3],[5,4]])],
  [[0,0],
   [0,1],
   [0,2],
   [0,5],
   [6,6],
   [6,3],
   [3,4],
   [2,2],
   [3,2],
   [4,1]],
  [[[1,2],[2,2]],
   [[2,1],[3,1]],
   [[2,3],[2,4]],
   [[1,1],[1,0]],
   [[0,1],[0,2]],
   [[0,3],[1,3]],
   [[5,3],[5,2]],
   [[0,4],[1,4]],
   [[5,4],[4,4]],
   [[4,2],[3,2]]]).


puzzle(20250823, easy,
  [region(empty, nil, [[0,0]]),
   region(sum, 1, [[0,1],[0,2]]),
   region(equals, nil, [[1,0],[1,1],[1,2]]),
   region(sum, 4, [[2,0],[2,1]])],
  [[0,0],
   [3,1],
   [3,3],
   [4,0]],
  [[[0,0],[0,1]],
   [[1,2],[0,2]],
   [[1,0],[1,1]],
   [[2,0],[2,1]]]).


puzzle(20250823, medium,
  [region(less, 2, [[0,1]]),
   region(equals, nil, [[0,2],[1,1],[1,2]]),
   region(empty, nil, [[1,0]]),
   region(sum, 12, [[2,0],[3,0]]),
   region(equals, nil, [[3,1],[3,2],[4,1]]),
   region(empty, nil, [[4,0]]),
   region(empty, nil, [[4,2]])],
  [[6,3],
   [1,4],
   [1,5],
   [4,6],
   [5,5],
   [3,4]],
  [[[2,0],[1,0]],
   [[4,2],[3,2]],
   [[0,1],[0,2]],
   [[3,1],[3,0]],
   [[1,1],[1,2]],
   [[4,0],[4,1]]]).


puzzle(20250823, hard,
  [region(less, 6, [[0,6],[1,6],[2,6],[3,6]]),
   region(empty, nil, [[0,7]]),
   region(sum, 4, [[1,1],[1,2],[1,3],[1,4]]),
   region(sum, 3, [[1,7]]),
   region(equals, nil, [[2,1],[3,0],[3,1],[4,0]]),
   region(sum, 6, [[2,4]]),
   region(greater, 2, [[3,3]]),
   region(sum, 6, [[3,4]]),
   region(sum, 6, [[4,1]]),
   region(sum, 6, [[4,3]]),
   region(empty, nil, [[4,4]])],
  [[1,0],
   [1,1],
   [1,6],
   [1,4],
   [1,3],
   [1,2],
   [6,3],
   [0,0],
   [0,6],
   [6,2]],
  [[[3,6],[2,6]],
   [[3,0],[4,0]],
   [[3,1],[4,1]],
   [[0,6],[0,7]],
   [[1,6],[1,7]],
   [[2,1],[1,1]],
   [[3,4],[3,3]],
   [[1,2],[1,3]],
   [[4,4],[4,3]],
   [[2,4],[1,4]]]).


puzzle(20250824, easy,
  [region(empty, nil, [[0,0]]),
   region(sum, 6, [[1,0]]),
   region(equals, nil, [[1,1],[1,2]]),
   region(empty, nil, [[2,1]]),
   region(equals, nil, [[2,2],[2,3],[3,3]])],
  [[0,4],
   [6,5],
   [4,4],
   [1,1]],
  [[[2,1],[2,2]],
   [[1,0],[0,0]],
   [[2,3],[3,3]],
   [[1,1],[1,2]]]).


puzzle(20250824, medium,
  [region(sum, 1, [[0,1]]),
   region(sum, 16, [[0,2],[1,2],[2,2],[3,2]]),
   region(greater, 2, [[1,3]]),
   region(empty, nil, [[2,0]]),
   region(empty, nil, [[2,3]]),
   region(sum, 0, [[3,0],[3,1]]),
   region(empty, nil, [[4,2]]),
   region(sum, 0, [[5,0]]),
   region(equals, nil, [[5,1],[5,2]])],
  [[1,4],
   [2,0],
   [3,4],
   [4,2],
   [0,1],
   [3,2],
   [0,4]],
  [[[0,1],[0,2]],
   [[5,1],[5,0]],
   [[1,3],[1,2]],
   [[2,2],[2,3]],
   [[3,0],[2,0]],
   [[4,2],[5,2]],
   [[3,1],[3,2]]]).


puzzle(20250824, hard,
  [region(less, 3, [[0,0]]),
   region(equals, nil, [[0,1],[1,1],[1,4],[2,1],[2,2],[2,3],[2,4]]),
   region(less, 2, [[0,4]]),
   region(sum, 2, [[0,5],[1,5]]),
   region(empty, nil, [[1,0]]),
   region(equals, nil, [[2,0],[3,0]]),
   region(sum, 0, [[2,5],[3,5]]),
   region(empty, nil, [[3,1]]),
   region(sum, 10, [[3,2],[3,3]]),
   region(empty, nil, [[3,4]])],
  [[2,6],
   [5,6],
   [4,6],
   [6,0],
   [0,3],
   [4,3],
   [5,5],
   [6,1],
   [0,1],
   [6,6]],
  [[[0,0],[0,1]],
   [[1,0],[1,1]],
   [[2,0],[2,1]],
   [[2,4],[2,5]],
   [[3,5],[3,4]],
   [[3,0],[3,1]],
   [[3,2],[3,3]],
   [[1,4],[1,5]],
   [[0,4],[0,5]],
   [[2,2],[2,3]]]).

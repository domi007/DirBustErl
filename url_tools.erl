-module(url_tools).
-export([urljoin/2, subslashes/1, ensure_ends_with_slash/1]).

urljoin(Base, [$/, $/ | _] = Path) ->
	re:replace(Base, "^([^:]+:)//.*$", "\\1" ++ Path, [{return, list}]);
urljoin(Base, [$/ | _] = Path) ->
	re:replace(Base, "^([^:]+://[^/]+)/.*$", "\\1" ++ Path, [{return, list}]);
urljoin(Base, [$., $/ | Rest]) ->
	urljoin(lists:reverse(subslashes(lists:reverse(Base))), Rest);
urljoin(Base, [$., $., $/ | Rest] = Path) ->
	case has_at_least_three_slashes(Base) of
		true -> urljoin(urljoin(Base, ".."), Rest);
		false -> lists:reverse(subslashes(lists:reverse(Base)), Path)
	end;
urljoin(Base, [Sym | Rest]) when Sym =:= $#; Sym =:= $?; Sym =:= $; ->
	case strip_symbol(lists:reverse(Base), Sym) of
		not_found -> Base ++ Rest;
		Stripped -> lists:reverse(Stripped, Rest)
	end;
urljoin(Base, "") -> Base;
urljoin(Base, ".") -> lists:reverse(subslashes(lists:reverse(Base)));
urljoin(Base, "..") ->
	lists:reverse(subslashes(tl(subslashes(lists:reverse(Base)))));
urljoin(Base, Path) ->
	case lists:member($:, Path) of
		true -> Path;
		false ->
			{PathElem, Rest} = split_path(Path),
			SubSlashed = subslashes(lists:reverse(Base)),
			case is_special_path_elem(PathElem) of
				true -> lists:reverse(SubSlashed, Path);
				false -> urljoin(lists:reverse(SubSlashed, PathElem), Rest)
			end
	end.

split_path(Path) ->
	{Element, Rest} = split_path(Path, []),
	{lists:reverse(Element), Rest}.
split_path([] = L, Acc) -> {Acc, L};
split_path([$/ | Path], Acc) -> {[$/ | Acc], Path};
split_path([Char | Path], Acc) ->
	split_path(Path, [Char | Acc]).

is_special_path_elem([$? | _]) -> true;
is_special_path_elem([$# | _]) -> true;
is_special_path_elem([$; | _]) -> true;
is_special_path_elem([_ | Rest]) -> is_special_path_elem(Rest);
is_special_path_elem([]) -> false.

has_at_least_three_slashes(URL) -> has_at_least_three_slashes(URL, 3).
has_at_least_three_slashes("", _) -> false;
has_at_least_three_slashes(_, 0) -> true;
has_at_least_three_slashes([$/ | URL], N) ->
	has_at_least_three_slashes(URL, N - 1);
has_at_least_three_slashes([_ | URL], N) ->
	has_at_least_three_slashes(URL, N).

subslashes([$/ | _] = URL) -> URL;
subslashes([_ | Rest]) -> subslashes(Rest).

strip_symbol([], _) -> not_found;
strip_symbol([Symbol | _] = URL, Symbol) -> URL;
strip_symbol([_ | Rest], Symbol) -> strip_symbol(Rest, Symbol).

ensure_ends_with_slash(Str) ->
	case lists:last(Str) of
		$/ -> Str;
		_ -> Str ++ "/"
	end.

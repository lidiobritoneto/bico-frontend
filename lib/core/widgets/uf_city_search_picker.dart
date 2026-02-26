import 'package:flutter/material.dart';
import '../services/ibge_localidades_service.dart';

class UfCityPicked {
  final IbgeUf uf;
  final IbgeMunicipio city;

  UfCityPicked({required this.uf, required this.city});
}

/// Picker com lista pesquisável para UF e Cidade.
/// - UF: bottom sheet com busca
/// - Cidade: bottom sheet com busca (carrega ao escolher UF)
class UfCitySearchPicker extends StatefulWidget {
  final String? initialUfSigla;
  final int? initialCityId;
  final String? initialCityName;
  final void Function(UfCityPicked? value) onChanged;

  const UfCitySearchPicker({
    super.key,
    required this.onChanged,
    this.initialUfSigla,
    this.initialCityId,
    this.initialCityName,
  });

  @override
  State<UfCitySearchPicker> createState() => _UfCitySearchPickerState();
}

class _UfCitySearchPickerState extends State<UfCitySearchPicker> {
  final _ibge = IbgeLocalidadesService();

  bool _loadingUf = true;
  bool _loadingCity = false;

  List<IbgeUf> _ufs = [];
  List<IbgeMunicipio> _cities = [];

  IbgeUf? _ufSel;
  IbgeMunicipio? _citySel;

  @override
  void initState() {
    super.initState();
    _loadUfs();
  }

  Future<void> _loadUfs() async {
    try {
      final ufs = await _ibge.getUfs();
      setState(() {
        _ufs = ufs;
        _loadingUf = false;
        if (widget.initialUfSigla != null) {
          _ufSel = ufs.firstWhere(
            (u) => u.sigla == widget.initialUfSigla,
            orElse: () => ufs.first,
          );
        }
      });

      if (_ufSel != null) {
        await _loadCities(_ufSel!.sigla, trySelectInitial: true);
      } else {
        _emit();
      }
    } catch (_) {
      setState(() => _loadingUf = false);
      rethrow;
    }
  }

  Future<void> _loadCities(String ufSigla, {bool trySelectInitial = false}) async {
    setState(() {
      _loadingCity = true;
      _cities = [];
      _citySel = null;
    });

    final cities = await _ibge.getMunicipiosByUf(ufSigla);
    setState(() {
      _cities = cities;
      _loadingCity = false;

      if (trySelectInitial && widget.initialCityId != null) {
        _citySel = cities.firstWhere(
          (c) => c.id == widget.initialCityId,
          orElse: () => cities.first,
        );
      } else if (trySelectInitial && widget.initialCityId == null && widget.initialCityName != null) {
        final name = widget.initialCityName!.trim().toLowerCase();
        if (name.isNotEmpty) {
          _citySel = cities.firstWhere(
            (c) => c.nome.toLowerCase() == name,
            orElse: () => cities.first,
          );
        }
      }
    });

    _emit();
  }

  void _emit() {
    if (_ufSel == null || _citySel == null) {
      widget.onChanged(null);
      return;
    }
    widget.onChanged(UfCityPicked(uf: _ufSel!, city: _citySel!));
  }

  Future<IbgeUf?> _pickUf() async {
    if (_loadingUf) return null;
    if (_ufs.isEmpty) return null;

    return showModalBottomSheet<IbgeUf>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final controller = TextEditingController();
        final focus = FocusNode();
        List<IbgeUf> filtered = List.of(_ufs);

        void applyFilter(StateSetter setModalState, String q) {
          final query = q.trim().toLowerCase();
          setModalState(() {
            filtered = query.isEmpty
                ? List.of(_ufs)
                : _ufs
                    .where((u) =>
                        u.nome.toLowerCase().contains(query) ||
                        u.sigla.toLowerCase().contains(query))
                    .toList(growable: false);
          });
        }

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 10,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (ctx2, setModalState) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!focus.hasFocus) focus.requestFocus();
              });

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selecione o estado (UF)',
                    style: Theme.of(ctx2).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: controller,
                    focusNode: focus,
                    decoration: const InputDecoration(
                      hintText: 'Pesquisar UF… (ex: MA, Maranhão)',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (q) => applyFilter(setModalState, q),
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx2).size.height * 0.55),
                    child: Material(
                      borderRadius: BorderRadius.circular(12),
                      clipBehavior: Clip.antiAlias,
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final u = filtered[i];
                          final selected = _ufSel?.sigla == u.sigla;
                          return ListTile(
                            dense: true,
                            title: Text('${u.nome} (${u.sigla})'),
                            trailing: selected ? const Icon(Icons.check) : null,
                            onTap: () => Navigator.of(ctx2).pop(u),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<IbgeMunicipio?> _pickCity() async {
    if (_ufSel == null) return null;
    if (_loadingCity) return null;
    if (_cities.isEmpty) return null;

    return showModalBottomSheet<IbgeMunicipio>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final controller = TextEditingController();
        final focus = FocusNode();
        List<IbgeMunicipio> filtered = List.of(_cities);

        void applyFilter(StateSetter setModalState, String q) {
          final query = q.trim().toLowerCase();
          setModalState(() {
            filtered = query.isEmpty
                ? List.of(_cities)
                : _cities.where((c) => c.nome.toLowerCase().contains(query)).toList(growable: false);
          });
        }

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 10,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (ctx2, setModalState) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!focus.hasFocus) focus.requestFocus();
              });

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selecione a cidade',
                    style: Theme.of(ctx2).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: controller,
                    focusNode: focus,
                    decoration: const InputDecoration(
                      hintText: 'Pesquisar cidade…',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (q) => applyFilter(setModalState, q),
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx2).size.height * 0.55),
                    child: Material(
                      borderRadius: BorderRadius.circular(12),
                      clipBehavior: Clip.antiAlias,
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final c = filtered[i];
                          final selected = _citySel?.id == c.id;
                          return ListTile(
                            dense: true,
                            title: Text(c.nome),
                            trailing: selected ? const Icon(Icons.check) : null,
                            onTap: () => Navigator.of(ctx2).pop(c),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ufLabel = _ufSel == null ? 'Selecione…' : '${_ufSel!.nome} (${_ufSel!.sigla})';
    final cityLabel = _citySel == null ? 'Selecione…' : _citySel!.nome;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _loadingUf
              ? null
              : () async {
                  final chosen = await _pickUf();
                  if (chosen == null) return;
                  if (chosen.sigla == _ufSel?.sigla) return;
                  setState(() {
                    _ufSel = chosen;
                    _citySel = null;
                    _cities = [];
                  });
                  await _loadCities(chosen.sigla);
                },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Estado (UF)',
              prefixIcon: const Icon(Icons.map_outlined),
              border: const OutlineInputBorder(),
              enabled: !_loadingUf,
            ),
            child: Row(
              children: [
                Expanded(child: Text(ufLabel)),
                if (_loadingUf) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                if (!_loadingUf) const Icon(Icons.expand_more),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: (_ufSel == null || _loadingCity)
              ? null
              : () async {
                  final chosen = await _pickCity();
                  if (chosen == null) return;
                  setState(() => _citySel = chosen);
                  _emit();
                },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Cidade',
              prefixIcon: const Icon(Icons.location_city_outlined),
              border: const OutlineInputBorder(),
              enabled: _ufSel != null && !_loadingCity,
            ),
            child: Row(
              children: [
                Expanded(child: Text(_ufSel == null ? 'Selecione a UF primeiro' : cityLabel)),
                if (_loadingCity) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                if (!_loadingCity) const Icon(Icons.search),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

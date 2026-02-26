import 'package:flutter/material.dart';
import '../services/ibge_localidades_service.dart';

class UfCityResult {
  final String ufSigla;
  final String ufNome;
  final int cityId;
  final String cityNome;

  UfCityResult({
    required this.ufSigla,
    required this.ufNome,
    required this.cityId,
    required this.cityNome,
  });
}

class UfCityCombo extends StatefulWidget {
  final String? initialUfSigla; // ex: "MA"
  final int? initialCityId; // ex: 2103000
  final String? initialCityName; // fallback (ex: "Caxias")
  final void Function(UfCityResult? value) onChanged;

  const UfCityCombo({
    super.key,
    required this.onChanged,
    this.initialUfSigla,
    this.initialCityId,
    this.initialCityName,
  });

  @override
  State<UfCityCombo> createState() => _UfCityComboState();
}

class _UfCityComboState extends State<UfCityCombo> {
  final _ibge = IbgeLocalidadesService();

  List<IbgeUf> _ufs = [];
  List<IbgeMunicipio> _cidades = [];

  IbgeUf? _ufSel;
  IbgeMunicipio? _citySel;

  bool _loadingUf = true;
  bool _loadingCity = false;

  @override
  void initState() {
    super.initState();
    _loadUfs();
  }

  Future<void> _loadUfs() async {
    try {
      final ufs = await _ibge.getUfs();
      IbgeUf? pre;
      if (widget.initialUfSigla != null && widget.initialUfSigla!.trim().isNotEmpty) {
        final sigla = widget.initialUfSigla!.trim().toUpperCase();
        pre = ufs.where((u) => u.sigla.toUpperCase() == sigla).cast<IbgeUf?>().firstOrNull;
      }

      setState(() {
        _ufs = ufs;
        _loadingUf = false;
        _ufSel = pre;
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
      _cidades = [];
      _citySel = null;
    });

    final cities = await _ibge.getMunicipiosByUf(ufSigla);

    IbgeMunicipio? preCity;
    if (trySelectInitial) {
      if (widget.initialCityId != null) {
        final id = widget.initialCityId;
        preCity = cities.where((c) => c.id == id).cast<IbgeMunicipio?>().firstOrNull;
      }
      preCity ??= (widget.initialCityName != null && widget.initialCityName!.trim().isNotEmpty)
          ? cities
              .where((c) => c.nome.trim().toLowerCase() == widget.initialCityName!.trim().toLowerCase())
              .cast<IbgeMunicipio?>()
              .firstOrNull
          : null;
    }

    setState(() {
      _cidades = cities;
      _loadingCity = false;
      _citySel = preCity;
    });

    _emit();
  }

  void _emit() {
    if (_ufSel == null || _citySel == null) {
      widget.onChanged(null);
      return;
    }
    widget.onChanged(
      UfCityResult(
        ufSigla: _ufSel!.sigla,
        ufNome: _ufSel!.nome,
        cityId: _citySel!.id,
        cityNome: _citySel!.nome,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<IbgeUf>(
          value: _ufSel,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Estado (UF)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.map_outlined),
          ),
          items: _ufs
              .map((u) => DropdownMenuItem(
                    value: u,
                    child: Text('${u.nome} (${u.sigla})'),
                  ))
              .toList(),
          onChanged: _loadingUf
              ? null
              : (u) async {
                  if (u == null) return;
                  setState(() => _ufSel = u);
                  await _loadCities(u.sigla);
                },
        ),
        const SizedBox(height: 12),
        _SearchableCityField(
          enabled: _ufSel != null && !_loadingCity,
          label: 'Cidade',
          valueText: _citySel?.nome,
          loading: _loadingCity,
          onTap: () async {
            if (_ufSel == null || _loadingCity) return;
            final picked = await _pickCityBottomSheet(context);
            if (picked == null) return;
            setState(() => _citySel = picked);
            _emit();
          },
        ),
      ],
    );
  }

  Future<IbgeMunicipio?> _pickCityBottomSheet(BuildContext context) async {
    if (_cidades.isEmpty) return null;
    return showModalBottomSheet<IbgeMunicipio>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final controller = TextEditingController();
        final focus = FocusNode();
        List<IbgeMunicipio> filtered = List.of(_cidades);

        void applyFilter(StateSetter setModalState, String q) {
          final query = q.trim().toLowerCase();
          setModalState(() {
            filtered = query.isEmpty
                ? List.of(_cidades)
                : _cidades.where((c) => c.nome.toLowerCase().contains(query)).toList(growable: false);
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
}

class _SearchableCityField extends StatelessWidget {
  final bool enabled;
  final String label;
  final String? valueText;
  final bool loading;
  final VoidCallback onTap;

  const _SearchableCityField({
    required this.enabled,
    required this.label,
    required this.valueText,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.location_city_outlined),
          suffixIcon: loading
              ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : const Icon(Icons.arrow_drop_down),
        ),
        isEmpty: (valueText == null || valueText!.trim().isEmpty),
        child: Text(
          (valueText == null || valueText!.trim().isEmpty) ? 'Toque para selecionar' : valueText!,
          style: TextStyle(color: enabled ? null : Theme.of(context).disabledColor),
        ),
      ),
    );
  }
}

extension _FirstOrNullExt<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

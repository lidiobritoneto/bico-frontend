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
  final String? initialUfSigla;
  final int? initialCityId;
  final void Function(UfCityResult? value) onChanged;

  const UfCityCombo({
    super.key,
    required this.onChanged,
    this.initialUfSigla,
    this.initialCityId,
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
      setState(() {
        _ufs = ufs;
        _loadingUf = false;
        _ufSel = widget.initialUfSigla == null
            ? null
            : ufs.firstWhere(
                (u) => u.sigla == widget.initialUfSigla,
                orElse: () => ufs.first,
              );
      });

      if (_ufSel != null) {
        await _loadCities(_ufSel!.sigla, trySelectInitial: true);
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

    setState(() {
      _cidades = cities;
      _loadingCity = false;

      if (trySelectInitial && widget.initialCityId != null) {
        _citySel = cities.firstWhere(
          (c) => c.id == widget.initialCityId,
          orElse: () => cities.first,
        );
      }
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
        DropdownButtonFormField<IbgeMunicipio>(
          value: _citySel,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Cidade',
            prefixIcon: const Icon(Icons.location_city_outlined),
            suffixIcon: _loadingCity
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          items: _cidades
              .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c.nome),
                  ))
              .toList(),
          onChanged: (_ufSel == null || _loadingCity)
              ? null
              : (c) {
                  setState(() => _citySel = c);
                  _emit();
                },
        ),
      ],
    );
  }
}
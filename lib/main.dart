import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cadastro de Empresa',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CompanyFormPage(),
    );
  }
}

class CompanyFormPage extends StatefulWidget {
  @override
  _CompanyFormPageState createState() => _CompanyFormPageState();
}

class _CompanyFormPageState extends State<CompanyFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _cnpjController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _fantasyNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _businessActivityController = TextEditingController();

  bool _isFieldsEnabled = false; // Controla habilitação dos campos

  // Máscara para o CNPJ
  final _cnpjMask = MaskTextInputFormatter(
    mask: '##.###.###/####-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  // função para buscar dados da empresa usando a API
  Future<void> _fetchCompanyData() async {
    final rawCnpj = _cnpjMask.getUnmaskedText(); // obtém o CNPJ sem máscara

    if (rawCnpj.isEmpty || rawCnpj.length != 14) {
      _showError("Por favor, insira um CNPJ válido com 14 dígitos.");
      return;
    }

    final url = Uri.parse('https://api-publica.speedio.com.br/buscarcnpj?cnpj=$rawCnpj');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Preenche os campos com os dados obtidos
        setState(() {
          _companyNameController.text = data['RAZAO SOCIAL'] ?? '';
          _fantasyNameController.text = data['NOME FANTASIA'] ?? '';
          _addressController.text = data['LOGRADOURO'] ?? '';
          _phoneController.text = data['TELEFONE'] ?? '';
          _businessActivityController.text = data['CNAE PRINCIPAL DESCRICAO'] ?? '';

          _isFieldsEnabled = true; // habilita os outros campos
        });
      } else {
        _showError("Erro ao buscar dados da empresa. Verifique o CNPJ.");
      }
    } catch (e) {
      _showError("Erro de conexão. Verifique a internet.");
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Erro"),
          content: Text(message),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Coleta os dados do formulário
      final cnpj = _cnpjMask.getMaskedText(); // obtém o cnpj no formato com máscara
      final companyName = _companyNameController.text;
      final fantasyName = _fantasyNameController.text;
      final address = _addressController.text;
      final phone = _phoneController.text;
      final businessActivity = _businessActivityController.text;

      // exibe uma mensagem de confirmação com os dados coletados
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Dados da Empresa"),
            content: Text(
              "CNPJ: $cnpj\n"
                  "Razão Social: $companyName\n"
                  "Nome Fantasia: $fantasyName\n"
                  "Endereço: $address\n"
                  "Telefone: $phone\n"
                  "Ramo de Atividade: $businessActivity",
            ),
            actions: [
              TextButton(
                child: Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                  _formKey.currentState!.reset(); // limpa o formulário
                  _cnpjController.clear();
                  _companyNameController.clear();
                  _fantasyNameController.clear();
                  _addressController.clear();
                  _phoneController.clear();
                  _businessActivityController.clear();
                  setState(() {
                    _isFieldsEnabled = false; // bloqueia os campos novamente
                  });
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cadastro de Empresa'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _cnpjController,
                inputFormatters: [_cnpjMask], // aplica a máscara
                decoration: InputDecoration(
                  labelText: 'CNPJ',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search),
                    onPressed: _fetchCompanyData,
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final rawCnpj = _cnpjMask.getUnmaskedText(); // valida o cnpj sem máscara
                  if (rawCnpj.isEmpty || rawCnpj.length != 14) {
                    return 'O CNPJ deve ter 14 dígitos';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _companyNameController,
                decoration: InputDecoration(labelText: 'Razão Social'),
                enabled: false,
              ),
              TextFormField(
                controller: _fantasyNameController,
                decoration: InputDecoration(labelText: 'Nome Fantasia'),
                enabled: _isFieldsEnabled,
              ),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(labelText: 'Endereço'),
                enabled: _isFieldsEnabled,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Telefone'),
                keyboardType: TextInputType.phone,
                enabled: _isFieldsEnabled,
              ),
              TextFormField(
                controller: _businessActivityController,
                decoration: InputDecoration(labelText: 'Ramo de Atividade'),
                enabled: _isFieldsEnabled,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Enviar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

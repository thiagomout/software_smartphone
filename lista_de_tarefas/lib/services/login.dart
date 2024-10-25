import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  Future<String> fazerLogin(String email, String senha) async {
    final url = Uri.https('barra.cos.ufrj.br:443', '/rest/rpc/fazer_login');
    final client = http.Client();

    final headers = {
      'accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final body = {
      'email': email,
      'senha': senha,
    };

    try {
      final jsonBody = json.encode(body);
      final response = await client.post(url, headers: headers, body: jsonBody);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData.containsKey('token') && responseData['token'] != null) {
          String token = responseData['token'];
          print('Token obtido: $token');
          return token;
        } else {
          print('Token não encontrado ou é inválido na resposta.');
          return '';
        }
      } else {
        print('Erro: ${response.statusCode} - ${response.body}');
        return '';
      }
    } catch (e) {
      print('Ocorreu um erro: ${e.toString()}');
      return '';
    } finally {
      client.close();
    }
  }

  Future<void> criarListaVazia(String token, String email) async {
    final url = Uri.https('barra.cos.ufrj.br:443', '/rest/tarefas');
    final client = http.Client();
    
    final headers = {
      'accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = json.encode({
      'email': email,
      'valor': [],
    });

    try {
      final response = await client.post(url, headers: headers, body: body);
      if (response.statusCode == 201) {
        print('ok');
      } else {
        print('Erro ao criar lista de tarefas: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Ocorreu um erro: ${e.toString()}');
    } finally {
      client.close();
    }
  }
}

void main() async {
  String email = '';
  String senha = '';
  
  final AuthService authService = AuthService();
  String token = await authService.fazerLogin(email, senha);
  
  if (token.isNotEmpty) {
    await authService.criarListaVazia(token, email);
  } else {
    print('Não foi possível obter o token JWT. Verifique as credenciais ou a resposta da API.');
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Perfil com Foto e Localização',
      home: TelaPerfil(),
    );
  }
}

class TelaPerfil extends StatefulWidget {
  const TelaPerfil({super.key});

  @override
  State<TelaPerfil> createState() => _TelaPerfilState();
}

class _TelaPerfilState extends State<TelaPerfil> {
  // Variáveis para armazenar a foto e o estado da localização
  File? foto;
  String localizacao = 'Localização ainda não obtida';
  bool localizacaoObtida = false;
  bool buscandoLocalizacao = false;

  // Função para escolher ou tirar a foto
  Future<void> escolherFoto(ImageSource origem) async {
    final picker = ImagePicker();
    final imagem = await picker.pickImage(
      source: origem,
    );

    if (imagem != null) {
      setState(() {
        foto = File(imagem.path);
      });
    }
  }

  // Função para obter a localização atual do dispositivo
  Future<void> obterLocalizacao() async {
    setState(() {
      buscandoLocalizacao = true;
    });

    try {
      final servicoAtivo = await Geolocator.isLocationServiceEnabled();
      if (!servicoAtivo) {
        atualizarErroLocalizacao('Ative o GPS do dispositivo.');
        return;
      }

      var permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
      }

      if (permissao == LocationPermission.denied) {
        atualizarErroLocalizacao('Permissão de localização negada.');
        return;
      }

      if (permissao == LocationPermission.deniedForever) {
        atualizarErroLocalizacao(
          'Permissão negada permanentemente. Libere-a nas configurações.',
        );
        return;
      }

      final posicao = await Geolocator.getCurrentPosition();

      if (!mounted) return;

      setState(() {
        localizacao =
            'Latitude: ${posicao.latitude.toStringAsFixed(4)}\nLongitude: ${posicao.longitude.toStringAsFixed(4)}';
        localizacaoObtida = true;
        buscandoLocalizacao = false;
      });
    } catch (_) {
      atualizarErroLocalizacao('Não foi possível obter a localização.');
    }
  }

  // Centraliza o tratamento de erros de localização
  void atualizarErroLocalizacao(String mensagem) {
    if (!mounted) return;
    setState(() {
      localizacao = mensagem;
      localizacaoObtida = false;
      buscandoLocalizacao = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil com Foto e Localização'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar para exibir a foto do perfil ou ícone padrão
              CircleAvatar(
                radius: 60,
                backgroundImage: foto != null ? FileImage(foto!) : null,
                child: foto == null
                    ? const Icon(
                        Icons.person,
                        size: 60,
                      )
                    : null,
              ),
              const SizedBox(height: 16),

              // Botão para tirar foto com a câmera
              ElevatedButton.icon(
                onPressed: () => escolherFoto(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Tirar foto'),
              ),
              const SizedBox(height: 8),

              // Botão para escolher foto da galeria
              ElevatedButton.icon(
                onPressed: () => escolherFoto(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Escolher da galeria'),
              ),
              const SizedBox(height: 24),

              // Ícone que muda de acordo com o estado da localização
              Icon(
                localizacaoObtida ? Icons.location_on : Icons.location_searching,
                size: 36,
                color: localizacaoObtida ? Colors.green : Colors.grey,
              ),
              const SizedBox(height: 8),

              // Texto com as coordenadas de latitude e longitude
              Text(
                localizacao,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Botão para acionar a obtenção da localização com indicador de progresso
              ElevatedButton.icon(
                onPressed: buscandoLocalizacao ? null : obterLocalizacao,
                icon: buscandoLocalizacao
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.my_location),
                label: Text(
                  buscandoLocalizacao
                      ? 'Obtendo localização...'
                      : 'Usar minha localização',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
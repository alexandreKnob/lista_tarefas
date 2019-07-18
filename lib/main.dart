import 'dart:convert'; // para o json.encode
import 'dart:io'; // para o File
import 'dart:async'; // para o await

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _tarefaController = TextEditingController();
  List _tarefas = [];
  Map<String, dynamic> _ultimaRemovida;
  int _ultimaRemovidaPos;

  @override
  void initState() {
    super.initState();
    _lerDados().then((dados) {
      // o then é que vai rodar depois de receber.
      setState(() {
        _tarefas = json.decode(dados); // joga na lista _tarefas um JSON
      });
    });
  }

  void _adicionaTarefa() {
    setState(() {
      Map<String, dynamic> novaTarefa = Map();
      novaTarefa["title"] = _tarefaController.text;
      _tarefaController.text = "";
      novaTarefa["ok"] = false;
      _tarefas.add(novaTarefa);
      _salvaDados();
      _atualizaOrdem();
    });
  }

  Future<Null> _atualizaOrdem() async {
    setState(() {
      _tarefas.sort((a, b) {
        if (a["ok"] && !b["ok"])       return 1;
        else if (!a["ok"] && b["ok"])  return -1;
        else  return 0;
        //return  a["title"].toLowerCase().compareTo(b["title"].toLowerCase());
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Mercado de Alexandre Knob"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17, 1, 7, 1),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _tarefaController,
                    decoration: InputDecoration(
                      labelText: "Novo Ítem",
                      labelStyle: TextStyle(color: Colors.blueAccent),
                    ),
                  ),
                ),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.add),
                      Text("Adicionar"),
                    ],
                  ),
                  textColor: Colors.white,
                  onPressed: _adicionaTarefa,
                )
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
                child: ListView.builder(
                    padding: EdgeInsets.only(top: 10.0),
                    itemCount: _tarefas.length,
                    itemBuilder: montaItem),
                onRefresh: _atualizaOrdem),
          )
        ],
      ),
    );
  }

  Widget montaItem(context, index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0), // para alinhar o ícone esquerda
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_tarefas[index]["title"]),
        value: _tarefas[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_tarefas[index]["ok"] ? Icons.check : Icons.error),
        ),
        onChanged: (c) {
          setState(() {
            _tarefas[index]["ok"] = c;
            _salvaDados();
          });
        },
      ),
      onDismissed: (direcao) {
        setState(() {
          _ultimaRemovida = Map.from(_tarefas[index]);
          _ultimaRemovidaPos = index;
          _tarefas.removeAt(index); // remove da lista
          _salvaDados(); // salva sem o item

          final snack = SnackBar(
            content: Text(
                "A Tarefa " + _ultimaRemovida["title"] + " foi removida !"),
            action: SnackBarAction(
                label: "Desfazer",
                onPressed: () {
                  setState(() {
                    _tarefas.insert(_ultimaRemovidaPos,
                        _ultimaRemovida); // adiciona novamente
                    _salvaDados();
                  });
                }),
            duration: Duration(seconds: 2),
          );
          Scaffold.of(context).showSnackBar(snack); // mostra a snack
        });
      },
    );
  }

  Future<File> _buscaArquivo() async {
    // o path provider vai providenciar o acesso, (android  e IOS)
    final diretorio = await getApplicationDocumentsDirectory(); //demora(assincrono)
    return File("${diretorio.path}/tarefas.json"); // retorno o arquivo
  }

  Future<File> _salvaDados() async {
    String dados = json.encode(_tarefas); // converte a lista para json
    final arquivo = await _buscaArquivo(); // busca o arquivo
    return arquivo.writeAsString(dados); // grava os dados json no arquivo
  }

  Future<String> _lerDados() async {
    try {
      final arquivo = await _buscaArquivo(); // pega o arquivo
      return arquivo.readAsString(); // ler o arquivo como string
    } catch (e) {
      return null;
    }
  }
}

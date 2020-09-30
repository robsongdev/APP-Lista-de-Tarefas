import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';

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
  final _toDoController = TextEditingController();
  List _toDoList = [];
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;

  //quando a aplicação é iniciada ler o arquivo json
  @override
  void initState() {
    super.initState();
    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  void _addToDo() {
    //chamar função no raisedbutton
    setState(() {
      Map<String, dynamic> newTodo = Map(); //criando map vazio
      newTodo["title"] = _toDoController.text;
      _toDoController.text = "";
      newTodo["ok"] = false;
      _toDoList.add(newTodo); //adicionando o map à lista
      _saveData();
    });
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      //ordenando por tarefa concuida
      _toDoList.sort((a, b) {
        if (a["ok"] && !b["ok"])
          return 1;
        else if (!a["ok"] && b["ok"])
          return -1;
        else
          return 0;
      });
      _saveData();
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
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
                  //expande o maximo que der
                  child: TextField(
                    controller: _toDoController,
                    decoration: InputDecoration(
                        labelText: "Nova Tarefa",
                        labelStyle: TextStyle(color: Colors.blueAccent)),
                  ),
                ),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text("ADD"),
                  textColor: Colors.white,
                  onPressed: _addToDo,
                )
              ],
            ),
          ),
          Expanded(
              child: RefreshIndicator(
                  //puxar a tela de cima para baixo e att
                  child: ListView.builder(
                      padding: EdgeInsets.only(top: 10),
                      itemCount: _toDoList.length, //quantidade de itens
                      itemBuilder: buildItem),
                  onRefresh: _refresh))
        ],
      ),
    );
  }

  //LISTA DE ITENS
  Widget buildItem(context, index) {
    return Dismissible(
      //adicionando uma chave qualquer (tempo em mimlisegundos)
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      //apagar com o delize
      background: Container(
        color: Colors.red,
        child: Align(
          //distancia horizontal(x -1 esq 1 centro/ y -1 centro 1 dir)
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd, //em que direção arrastar
      child: CheckboxListTile(
        // lista com checkbox
        title: Text(_toDoList[index]["title"]), //titulo
        value: _toDoList[index]["ok"], //checkbox flagada ou n(true/false)
        secondary: CircleAvatar(
          //icone dependendo do "ok (true/false)"
          child: Icon(_toDoList[index]["ok"] ? Icons.check : Icons.error),
        ),
        onChanged: (c) {
          //(c) = true/false
          setState(() {
            _toDoList[index]["ok"] = c;
            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]); //salvando antes de excluir
          _lastRemovedPos = index;
          _toDoList.removeAt(index); //excluindo

          _saveData(); //atualizando a lista

          final snack = SnackBar(
            content: Text("Tarefa \"${_lastRemoved["title"]}\" removida"),
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: () {
                setState(() {
                  _toDoList.insert(
                      _lastRemovedPos, _lastRemoved); //reeinserindo o arquivo
                  _saveData();
                });
              },
            ),
            duration: Duration(seconds: 2), //tempo que o snack vai ficar ativo
          );
          
          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snack); //chamando snack
        });
      },
    );
  }

  /*
  
  */
  Future<File> _getFile() async {
    //salvar no diretorio do dispositivo
    final directory =
        await getApplicationDocumentsDirectory(); //local que salva arquivos e pede permissao para salvar
    return File("${directory.path}/data.json"); //criando arquivo json
  }

  Future<File> _saveData() async {
    String data = json
        .encode(_toDoList); //transformando para json e armazenando e ua string
    final file = await _getFile(); //pegando o arquivo
    return file.writeAsString(data); //escrevendo no arquivo
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}

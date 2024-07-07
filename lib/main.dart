import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Listas osi',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ListaGeneralScreen(),
    );
  }
}

class ListaGeneralScreen extends StatefulWidget {
  @override
  _ListaGeneralScreenState createState() => _ListaGeneralScreenState();
}

class _ListaGeneralScreenState extends State<ListaGeneralScreen> {
  List<Map<String, dynamic>> _listas = [];

  @override
  void initState() {
    super.initState();
    _loadListas();
  }

  _loadListas() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? listasString = prefs.getString('listas');
    if (listasString != null) {
      setState(() {
        _listas = List<Map<String, dynamic>>.from(json.decode(listasString));
      });
    }
  }

  _saveListas() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('listas', json.encode(_listas));
  }

  _addLista(String titulo) {
    setState(() {
      _listas.add({'titulo': titulo, 'items': []});
    });
    _saveListas();
  }

  _removeLista(int index) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Confirmar'),
        content: Text('¿Estas super sugur@ de eliminar la lista?'),
        actions: <Widget>[
          TextButton(
            child: Text('Cancelar'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            child: Text('Eliminar'),
            onPressed: () {
              _removeListaConfirmed(index);
              Navigator.of(context).pop(); // Cierra el diálogo de confirmación
            },
          ),
        ],
      );
    },
  );
}

_removeListaConfirmed(int index) {
  setState(() {
    _listas.removeAt(index);
  });
  _saveListas();
}


  _editLista(int index, String newTitulo) {
    setState(() {
      _listas[index]['titulo'] = newTitulo;
    });
    _saveListas();
  }

  _navigateToSubLista(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubListaScreen(
          lista: _listas[index],
          onListChanged: (updatedList) {
            setState(() {
              _listas[index] = updatedList;
            });
            _saveListas();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Listas'),
      ),
      body: ListView.builder(
        itemCount: _listas.length,
        itemBuilder: (context, index) {
          return Dismissible(
            key: Key(_listas[index]['titulo']),
            onDismissed: (direction) {
              _removeLista(index);
            },
            background: Container(
              color: Colors.purple,
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Icon(Icons.delete, color: Colors.white),
            ),
            child: Card(
              child: ListTile(
                title: Text(
                  _listas[index]['titulo'],
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onTap: () => _navigateToSubLista(index),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _displayAddDialog(context);
        },
        child: Icon(Icons.add),
      ),
    );
  }

  _displayAddDialog(BuildContext context) async {
    TextEditingController controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Agregar Lista'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: "Título de la lista"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Agregar'),
              onPressed: () {
                _addLista(controller.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class SubListaScreen extends StatefulWidget {
  final Map<String, dynamic> lista;
  final Function(Map<String, dynamic>) onListChanged;

  SubListaScreen({required this.lista, required this.onListChanged});

  @override
  _SubListaScreenState createState() => _SubListaScreenState();
}

class _SubListaScreenState extends State<SubListaScreen> {
  late List<String> _items;

  @override
  void initState() {
    super.initState();
    _items = List<String>.from(widget.lista['items']);
  }

  _addItem(String item) {
    setState(() {
      _items.add(item);
    });
    widget.lista['items'] = _items;
    widget.onListChanged(widget.lista);
  }

  _removeItem(int index) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Confirmar'),
        content: Text('¿Estas super sugur@ de eliminar la lista??'),
        actions: <Widget>[
          TextButton(
            child: Text('Cancelar'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            child: Text('Eliminar'),
            onPressed: () {
              _removeItemConfirmed(index);
              Navigator.of(context).pop(); // Cierra el diálogo de confirmación
            },
          ),
        ],
      );
    },
  );
}

_removeItemConfirmed(int index) {
  setState(() {
    _items.removeAt(index);
  });
  widget.lista['items'] = _items;
  widget.onListChanged(widget.lista);
}



  _editItem(int index, String newItem) {
    setState(() {
      _items[index] = newItem;
    });
    widget.lista['items'] = _items;
    widget.onListChanged(widget.lista);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lista['titulo']),
      ),
      body: ReorderableListView(
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) {
              newIndex -= 1;
            }
            final item = _items.removeAt(oldIndex);
            _items.insert(newIndex, item);
          });
          widget.lista['items'] = _items;
          widget.onListChanged(widget.lista);
        },
        children: List.generate(
          _items.length,
          (index) {
            return Dismissible(
              key: Key(_items[index]),
              onDismissed: (direction) {
                _removeItem(index);
              },
              background: Container(
                color: Colors.purple,
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Icon(Icons.delete, color: Colors.white),
              ),
              child: ListTile(
                title: Text(
                  _items[index],
                  style: TextStyle(fontSize: 18),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.edit, color: Colors.blueAccent),
                  onPressed: () {
                    _displayEditDialog(context, index);
                  },
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _displayAddDialog(context);
        },
        child: Icon(Icons.add),
      ),
    );
  }

  _displayAddDialog(BuildContext context) async {
    TextEditingController controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Agregar sublista'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: "Nombre del la otra lista"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Agregar'),
              onPressed: () {
                _addItem(controller.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  _displayEditDialog(BuildContext context, int index) async {
    TextEditingController controller = TextEditingController();
    controller.text = _items[index];
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Editar sublista'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: "Nombre del la otra lista"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Guardar'),
              onPressed: () {
                _editItem(index, controller.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_list/app/components/message_dialog.dart';
import 'package:todo_list/app/components/task_item.dart';
import 'package:todo_list/app/data/app_state.dart';
import 'package:todo_list/app/data/data_base.dart';
import 'package:todo_list/app/data/task_list_page_model.dart';
import 'package:todo_list/app/data/todo_task.dart';
import 'package:todo_list/app/pages/login_page.dart';
import 'package:todo_list/app/utils/date_time.dart';

class TodoListPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => TodoListState();
}

const Color DOING_TASK_COLOR = Color.fromARGB(255, 80, 210, 194);
const Color LATER_TASK_COLOR = Color.fromARGB(255, 255, 51, 102);

class TodoListState extends State<TodoListPage> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  TaskListPageModel<TodoTask> _list;

  Set<String> selectedTask = Set();

  int _lastStarIndex = 0;
  AppState appState;
  DataBase _dataBase;
  bool _loading = true;

  VoidCallback listener;

  @override
  void initState() {
    super.initState();
    _hadLogined();
    listener = () {
      setState(() {
        _list = TaskListPageModel(listKey: _listKey, initialItems: appState.tasks.value, removedItemBuilder: _buildRow);
      });
    };
  }

  _hadLogined() async {
    String email = await _savedEmail();
    if (email == null) {
      /// 弹窗登录页面
      email = await Navigator.of(context).push(PageRouteBuilder(
          pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) =>
              LoginPage(),
          transitionsBuilder:
              (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
            return SlideTransition(
              position: Tween(begin: const Offset(0.0, 1.0), end: const Offset(0.0, 0.0)).animate(animation),
              child: child,
            );
          }));
    }
    if (_dataBase == null || appState.email != email) {
      _dataBase = DataBase(userName: email);
    }
    List<TodoTask> tasks = await _dataBase.data();
    tasks.forEach((task) {
      if (task.import) {
        _lastStarIndex++;
      }
    });
    _list = TaskListPageModel(listKey: _listKey, initialItems: tasks, removedItemBuilder: _buildRow);
    setState(() {
      appState.email = email;
      appState.tasks.value = tasks;
      _loading = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (appState == null) {
      appState = AppStateContainer.of(context);
      appState.tasks.addListener(listener);
    }
  }

  @override
  void dispose() {
    print('dispose');
    if (appState != null) {
      //在这里移除监听事件
      appState.tasks.removeListener(listener);
    }
    super.dispose();
  }

  Widget _getBody() {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    } else {
      return AnimatedList(
          key: _listKey,
          initialItemCount: _list.length,
          itemBuilder: (context, index, animation) {
            if (index < 0 || index >= _list.length) {
              return null;
            }
            return _buildRow(index, context, animation);
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('YOUR LIST'),
        actions: <Widget>[],
      ),
      body: _getBody(),
    );
  }

  void _finished(TodoTask task) {
    task.finished = !task.finished;
    _dataBase.updateTask(task);
    if (_list.indexOf(task) == 0) {
      setState(() {});
      return;
    }

    _list.remove(task);
    if (task.finished) {
      _list.insert(_list.length, task);
    } else {
      _list.insert(0, task);
    }
  }

  AnimatedListState get _animatedList => _listKey.currentState;

  void _star(TodoTask task) {
//    if (task.finished) return;
    task.import = !task.import;

    _dataBase.updateTask(task);

    if (task.import) {
      if (_list.indexOf(task) == 0) {
        setState(() {});
        return;
      }
      _list.remove(task);
      _list.insert(0, task);
      _lastStarIndex++;
    } else {
      _list.remove(task);
      _list.insert(_lastStarIndex--, task);
    }
  }

  void _delete(TodoTask task) async {
    _dataBase.delete(task.id);
    _list.remove(task);
  }

  void animatedInsert(TodoTask task, {int index = 0}) {
    _list.insert(index, task);
  }

  void animatedRemove(int index) {
    _animatedList.removeItem(index, (context, animation) {
      return _buildRow(index, context, animation, canOption: false);
    });
  }

  Future<String> _savedEmail() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getString("Email");
  }

  Widget _buildRow(int index, BuildContext context, Animation animation, {bool canOption = true}) {
    if (index >= _list.length) {
      return null;
    }
    TodoTask task = _list[index];
    return TaskItem(
      task: task,
      animation: animation,
      onFinished: _finished,
      onImported: _star,
      onDelete: _delete,
      canOption: canOption,
      confirmDismissCallback: confirmDismissCallback,
    );
  }

  Future<bool> confirmDismissCallback(DismissDirection direction, TodoTask task) async {
    if (direction == DismissDirection.endToStart) {
      String title = "${task.title}";
      if (title.length == 0) {
        title = "暂无任务名";
      }
      String desc = "${task.description}";
      if (desc.length == 0) {
        desc = "暂无描述";
      }

      String time =
          "${DateTimeFormatter.formatChineseDate(task.fromTime)}-${DateTimeFormatter.formatChineseDate(task.toTime)}";
      bool result = await showCupertinoDialog(
          context: context,
          builder: (BuildContext context) {
            return MessageDialog(
              taskName: "确认删除任务：$title",
              taskTime: time,
              taskDesc: desc,
            );
          });
      print(result);
      return result;
    }
    return false;
  }
}

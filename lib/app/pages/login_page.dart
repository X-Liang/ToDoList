import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_list/app/data/app_state.dart';

import 'login_operation.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool canLogin;
  LoginBloc _loginBloc;
  TokenVerifyBloc _tokenVerifyBloc;
  TextEditingController _emailController;
  TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    canLogin = false;
//    String email = await _savedEmail();
//    String password;
//    if (email != null) {
//      password = await _savedPassword(email);
//      _emailController = TextEditingController.fromValue(TextEditingValue(text: email));
//      _passwordController = TextEditingController.fromValue(TextEditingValue(text: password));
//    } else {
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
//    }

    _tokenVerifyBloc = TokenVerifyBloc();
    _loginBloc = LoginBloc(loginOperation: LoginOperation(), tokenVerifyBloc: _tokenVerifyBloc);
  }

  void _checkInputValid(String _) {
    bool isInputValid = _emailController.text.contains('@') && _passwordController.text.length >= 6;
    if (isInputValid == canLogin) {
      return;
    }
    setState(() {
      canLogin = isInputValid;
    });
  }

  _login() {
    _loginBloc.dispatch(LoginButtonPressEvent(username: _emailController.text, password: _passwordController.text));
  }

  AppState _appState;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_appState == null) {
      _appState = AppStateContainer.of(context);
    }
  }

//  _login() async {
//    String email = _emailController.text;
//    String password = _passwordController.text;
//    showDialog(
//        context: context,
//        builder: (BuildContext context) {
//          return Dialog(
//            child: Padding(
//              padding: const EdgeInsets.only(top: 15.0, bottom: 15.0),
//              child: Row(
//                mainAxisAlignment: MainAxisAlignment.center,
//                children: <Widget>[
//                  CircularProgressIndicator(),
//                  Text('请求中...'),
//                ],
//              ),
//            ),
//          );
//        });
//    Response response = await post('http://10.0.2.2:8989/login',
//        body: JsonEncoder().convert({
//          'email': email,
//          'password': password,
//        }),
//        headers: {
//          'Content-Type': 'application/json',
//        });
//    Map<String, dynamic> body = JsonDecoder().convert(response.body);
//    print(body);
//    Navigator.of(context).pop();
//    showDialog(
//        context: context,
//        builder: (BuildContext context) => AlertDialog(
//              title: Text('服务器返回信息'),
//              content: Text(body['error'].isEmpty
//                  ? '登录成功'
//                  : '登录失败，服务器信息为：${body['error']}'),
//              actions: <Widget>[
//                FlatButton(
//                  child: Text('确定'),
//                  onPressed: () {
//                    Navigator.of(context).pop();
//                  },
//                )
//              ],
//            ));
//  }

  @override
  Widget build(BuildContext context) {
    FocusNode emailFocusNode = FocusNode();
    FocusNode passwordFocusNode = FocusNode();

    return BlocBuilder<VerifyEvent, LoginState>(
      bloc: _tokenVerifyBloc,
      builder: (context, state) {
        if (state is LoginSuccess) {
          WidgetsBinding.instance.addPostFrameCallback((_) => this.showLoginResultDialog());
        } else if (state is LoginFailure) {
          WidgetsBinding.instance.addPostFrameCallback((_) => this.showLoginResultDialog(error: "密码错误"));
        }
        return Scaffold(
//          appBar: AppBar(
//            title: Text("LoginPage"),
//          ),
          body: GestureDetector(
            onTap: () {
              emailFocusNode.unfocus();
              passwordFocusNode.unfocus();
            },
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height,
                ),
                child: Column(
                  children: <Widget>[
                    Expanded(
                      child: Container(
                          child: Center(
                              child: FractionallySizedBox(
                        child: Image.asset('assets/images/mark.png'),
                        widthFactor: 0.4,
                        heightFactor: 0.4,
                      ))),
                    ),
                    Expanded(
                      child: Container(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.only(left: 24, right: 24, bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                TextField(
                                  decoration: InputDecoration(
                                    hintText: '请输入邮箱',
                                    labelText: '邮箱',
                                  ),
                                  focusNode: emailFocusNode,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  onSubmitted: (String value) {
                                    FocusScope.of(context).requestFocus(passwordFocusNode);
                                  },
                                  onChanged: _checkInputValid,
                                  controller: _emailController,
                                ),
                                TextField(
                                  decoration: InputDecoration(
                                    hintText: '请输入六位以上的密码',
                                    labelText: '密码',
                                    suffixIcon: FlatButton(
                                      child: Text('忘记密码？'),
                                      onPressed: () {},
                                    ),
                                  ),
                                  obscureText: true,
                                  focusNode: passwordFocusNode,
                                  textInputAction: TextInputAction.done,
                                  onChanged: _checkInputValid,
                                  controller: _passwordController,
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 12),
                            child: FlatButton(
                              onPressed: canLogin ? _login : null,
                              color: Color.fromRGBO(69, 202, 181, 1),
                              disabledColor: Color.fromRGBO(69, 202, 160, 0.5),
                              child: Text(
                                '登录',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                              padding: EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text('没有账号？'),
                                  InkWell(
                                    child: Text('立即注册'),
                                    onTap: () {},
                                  )
                                ],
                              )),
                        ],
                      )),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void showLoginResultDialog({String error}) {
    _save();
    _appState.email = _emailController.text;
    Navigator.of(context).pop(_emailController.text);
//    if (error == null) {
//      _save();
//    }
//    showDialog(
//        context: context,
//        builder: (BuildContext context) => AlertDialog(
//              title: Text('服务器返回信息'),
//              content: Text(error == null ? '登录成功' : '登录失败，服务器信息为：${error}'),
//              actions: <Widget>[
//                FlatButton(
//                  child: Text('确定'),
//                  onPressed: () {
//                    Navigator.of(context).pop();
//                  },
//                )
//              ],
//            ));
  }

  void _save() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setString("Email", _emailController.text);
    sharedPreferences.setString(_emailController.text, _passwordController.text);
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_api/models/user_info.dart';
import 'package:todo_api/providers/demo_provider.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: ChangeNotifierProvider(
        create: (context) => DemoProvider(),
        child: DemoApiScreen(),
      ),
    );
  }
}

class DemoApiScreen extends StatefulWidget {
  const DemoApiScreen({super.key});

  @override
  State<DemoApiScreen> createState() => _DemoApiScreenState();
}

class _DemoApiScreenState extends State<DemoApiScreen> {
  int counterDemo = 10;
  // Map<String, dynamic> userInfo = {};

  @override
  void initState() {
    super.initState();
  }

  Future<UserInfo> loginUser() async {
    try {
      var url = Uri.parse('https://dummyjson.com/user/login');
      // var data = {
      //   'username': 'emilys',
      //   'password': 'emilyspass',
      //   'expiresInMins': 30,
      // };

      UserLoginRequest userLoginRequest = UserLoginRequest(
        expiresInMins: 30,
        password: 'emilyspass',
        username: 'emilys',
      );

      /// DTO -> data transfer object

      /// http request body -> json -> string
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        // body: jsonEncode(data),
        body: jsonEncode(userLoginRequest.toJson()),
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      print('Response body in Map: ${jsonDecode(response.body)}');
      // userInfo = jsonDecode(response.body);
      /// http response -> string -> json -> object
      final jsonResponse = jsonDecode(response.body);
      return UserInfo.fromJson(jsonResponse);
    } catch (e) {
      print('error: $e');
      throw Exception();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Processing Counter'),
          Row(
            children: [
              TextButton(
                onPressed: () async {
                  /// ví dụ thực hiện logic hàm này mất 100s
                  /// -> app bị đóng băng trong 100s -> đơ , crash
                  // for (int i = 0; i <= 10000000000; i++) {
                  //   counterDemo = i;
                  //   print('counterDemo $counterDemo');
                  // }
                  await Future.delayed(Duration(seconds: 100), () {
                    print('Hoan thanh');
                  });
                },
                child: Text('increase counter'),
              ),
              TextButton(onPressed: () {}, child: Text('decrease counter')),
            ],
          ),
          FutureBuilder<UserInfo>(
            future: loginUser(),
            builder: (_, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasData) {
                // return Text('data ${snapshot.data!['email']}');
                return Text('data ${snapshot.data!.email}');
              }
              return Text('No data');
            },
          ),
        ],
      ),
    );
  }
}

class DemoScreen extends StatelessWidget {
  const DemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // final demoProvider = context.watch<DemoProvider>();
    // final counter = context.select<DemoProvider, int>(
    //   (demoProvider) => demoProvider.counter,
    // );
    /// ChangeNotifierProvider
    /// Provider.of
    /// context.watch
    /// context.read
    /// context.select
    /// Selector
    /// Consumer
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Counter '),
          Container(width: 50, height: 50, color: Colors.black),
          // Selector<DemoProvider, int>(
          //   builder: (_, data, __) {
          //     return Text('Counter $data');
          //   },
          //   selector: (_, demoProvider) => demoProvider.counter,
          // ),
          Consumer<DemoProvider>(
            builder: (_, demoProvider, __) {
              return Text('Counter ${demoProvider.counter}');
            },
          ),
          TextButton(
            onPressed: () {
              // demoProvider.increaseCounter();
              context.read<DemoProvider>().increaseCounter();
            },
            child: Text('Increase counter'),
          ),
          TextButton(
            onPressed: () {
              // demoProvider.decreaseCounter();
              context.read<DemoProvider>().decreaseCounter();
            },
            child: Text('Decrease counter'),
          ),

          Text('Counter '),
          Container(width: 50, height: 50, color: Colors.yellow),
          // Text('Age ${context.read<DemoProvider>().age}'),
          // Selector<DemoProvider, int>(
          //   builder: (_, data, __) {
          //     return Text('Age $data');
          //   },
          //   selector: (_, demoProvider) => demoProvider.age,
          // ),
          Consumer<DemoProvider>(
            builder: (_, demoProvider, __) {
              return Text('Age ${demoProvider.age}');
            },
          ),
          TextButton(
            onPressed: () {
              // demoProvider.increaseAge();
              context.read<DemoProvider>().increaseAge();
            },
            child: Text('Increase counter'),
          ),
          TextButton(
            onPressed: () {
              // demoProvider.decreaseAge();
              context.read<DemoProvider>().decreaseAge();
            },
            child: Text('Decrease counter'),
          ),
        ],
      ),
    );
  }
}

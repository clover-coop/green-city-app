import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_scaffold.dart';
import '../../common/socket_service.dart';
import '../../common/form_input/input_fields.dart';
import './blog_class.dart';
import './blog_state.dart';
import '../user_auth/current_user_state.dart';

class BlogView extends StatefulWidget {
  String? slug;

  BlogView({ @required this.slug, });

  @override
  _BlogViewState createState() => _BlogViewState();
}

class _BlogViewState extends State<BlogView> {
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();

  bool _loading = false;
  String _message = '';
  BlogClass _blog = BlogClass.fromJson({});

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('getBlogs', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1 && data['blogs'].length > 0) {
        if (data.containsKey('blogs')) {
          _blog = BlogClass.fromJson(data['blogs'][0]);
        } else {
          _message = 'Error.';
        }
      } else {
        _message = data['msg'].length > 0 ? data['msg'] : 'Error.';
      }
      setState(() {
        _loading = false;
        _message = _message;
        _blog = _blog;
      });
    }));

    _socketService.emit('getBlogs', { 'slug': widget.slug });
  }

  Widget _buildBlog(context) {
    if (_blog == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: LinearProgressIndicator(
        ),
      );
    }

    Widget imageCredit = SizedBox.shrink();
    if (_blog.image_credit != null && _blog.image_credit!.length > 0) {
      imageCredit = Column(
        children: [
          SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MarkdownBody(
                data: _blog.image_credit!,
                onTapLink: (text, href, title) {
                  launch(href!);
                },
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                  p: Theme.of(context).textTheme.headline6,
                ),
              ),
            ]
          )
        ]
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Image.network(_blog.image_url!, height: 300, width: double.infinity, fit: BoxFit.cover),
        imageCredit,
        SizedBox(height: 10),
        Container(
          padding: EdgeInsets.only(left: 20, right: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_blog.title!,
                style: Theme.of(context).textTheme.headline1,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 5),
              //Text('Tags: ${_blog.tags.join(', ')}'),
              //SizedBox(height: 5),
              MarkdownBody(
                data: _blog.text!,
                onTapLink: (text, href, title) {
                  launch(href!);
                },
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                  h1: Theme.of(context).textTheme.headline1,
                  h2: Theme.of(context).textTheme.headline2,
                  h3: Theme.of(context).textTheme.headline3,
                  h4: Theme.of(context).textTheme.headline4,
                  h5: Theme.of(context).textTheme.headline5,
                  h6: Theme.of(context).textTheme.headline6,
                ),
              ),
            ]
          )
        ),
      ]
    );
  }

  @override
  Widget build(BuildContext context) {
//    const String text = """
//# Markdown syntax guide
//## Headers
//### Header 3
//#### Header 4

//**This text will be bold**

//You may be using [Markdown Live Preview](https://markdownlivepreview.com/).
//""";

    return AppScaffoldComponent(
      body: ListView(
        children: <Widget> [
          Container(
            //width: 600,
            padding: const EdgeInsets.only(bottom: 50),
            child: _buildBlog(context),
          )
        ]
      )
    );
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }
}
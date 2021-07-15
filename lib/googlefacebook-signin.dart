import 'dart:async';
import 'dart:convert';

import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;

import 'welcomescreen.dart';

class WebViewGoogleFacebook extends StatefulWidget {

  String idendity_provider;
  WebViewGoogleFacebook(this.idendity_provider);

  @override
  WebViewGoogleFacebookState createState() => WebViewGoogleFacebookState();
}

class WebViewGoogleFacebookState extends State<WebViewGoogleFacebook> {

  final Completer<WebViewController> _webViewController =
  Completer<WebViewController>();

  @override
  void initState() {
    super.initState();
    // Enable hybrid composition.
    // if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
  }





  final COGNITO_CLIENT_ID = '21sddcivk9gvg04osdkt9io2eu';
  final COGNITO_Pool_ID = 'ap-south-1:41aa7654-2e92-4c08-92fa-dd581496f935';
  final COGNITO_POOL_URL = 'cmpstg.auth.ap-south-1.amazoncognito.com/';  // CHANGE YOUR DOMAIN NAME
  final CLIENT_SECRET = '21sddcivk9gvg04osdkt9io2eu';
  var web_view_enable=0;




  Widget getWebView() {
    if(widget.idendity_provider=="Google")
    {
      widget.idendity_provider = "Google";
    }
    else
    {
      widget.idendity_provider = "Facebook";
    }
    var signin=0;
    var url = "https://cmpstg.auth.ap-south-1.amazoncognito.com/login?"
        "response_type=code&client_id=21sddcivk9gvg04osdkt9io2eu&redirect_uri=cubmcpaws://";
    return WebView(
      initialUrl: url,
      userAgent: 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) ' +
          'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.94 Mobile Safari/537.36',
      javascriptMode: JavascriptMode.unrestricted,
      onWebViewCreated: (WebViewController webViewController) {
        _webViewController.complete(webViewController);
      },

      navigationDelegate: (NavigationRequest request) {
        if (request.url.startsWith("myapp://?code=") && signin==0) {
          String code = request.url.substring("myapp://?code=".length);
          signUserInWithAuthCode(code);
          signin=1;
          return NavigationDecision.prevent;
        }

        return NavigationDecision.navigate;
      },
      gestureNavigationEnabled: true,
    );
  }



  Future signUserInWithAuthCode(String authCode) async {
    String url = "https://${COGNITO_POOL_URL}" +
        ".amazoncognito.com/oauth2/token?grant_type=authorization_code&client_id=" +
        "${COGNITO_CLIENT_ID}&client_secret=${CLIENT_SECRET}&code=" +
        authCode +
        "&redirect_uri=myapp://";
    final response = await http.post(url,
        body: {},
        headers: {'Content-Type': 'application/x-www-form-urlencoded'});
    if (response.statusCode != 200) {
      throw Exception("Received bad status code from Cognito for auth code:" +
          response.statusCode.toString() +
          "; body: " +
          response.body);
    }

    final tokenData = json.decode(response.body);

    final idToken = new CognitoIdToken(tokenData['id_token']);
    final accessToken = new CognitoAccessToken(tokenData['access_token']);
    final refreshToken = new CognitoRefreshToken(tokenData['refresh_token']);
    final session = new CognitoUserSession(idToken, accessToken,
        refreshToken: refreshToken);

    final userPool =
    new CognitoUserPool(COGNITO_Pool_ID,COGNITO_CLIENT_ID);
    final user = new CognitoUser(null, userPool, signInUserSession: session);

    // NOTE: in order to get the email from the list of user attributes, make sure you select email in the list of
    // attributes in Cognito and map it to the email field in the identity provider.
    final attributes = await user.getUserAttributes();
    for (CognitoUserAttribute attribute in attributes) {
      if (attribute.getName() == "email") {
        user.username = attribute.getValue();
        break;
      }
    }

    print("login successfully.");
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => WelcomeScreen()),
    );

    return user;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          return true;
        },
        child: Scaffold(
            appBar: AppBar(
                title: Text(widget.idendity_provider + " Authentication")
            ),
            body:  getWebView())
    );



  }}
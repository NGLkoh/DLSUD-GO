import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PanoramaViewScreen extends StatefulWidget {
  final String imageUrl;

  const PanoramaViewScreen({super.key, required this.imageUrl});

  @override
  State<PanoramaViewScreen> createState() => _PanoramaViewScreenState();
}

class _PanoramaViewScreenState extends State<PanoramaViewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    // Lock orientation to landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    final htmlContent = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
      <title>360° Panorama</title>
      <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { overflow: hidden; background: #000; touch-action: none; }
        canvas { display: block; width: 100vw; height: 100vh; }
        #loading { position: absolute; top:50%; left:50%; transform:translate(-50%,-50%);
                   color:white; font-family:Arial,sans-serif; text-align:center; z-index:100; }
        .spinner { border:4px solid rgba(255,255,255,0.3); border-top:4px solid white;
                   border-radius:50%; width:40px; height:40px; animation:spin 1s linear infinite;
                   margin:0 auto 10px; }
        @keyframes spin { 0% { transform:rotate(0deg); } 100% { transform:rotate(360deg); } }
        #instructions { position:absolute; bottom:20px; left:50%; transform:translateX(-50%);
                        background:rgba(0,0,0,0.7); color:white; padding:10px 20px;
                        border-radius:20px; font-size:14px; font-family:Arial,sans-serif; z-index:100;
                        animation:fadeOut 4s forwards; }
        @keyframes fadeOut { 0%,70% { opacity:1; } 100% { opacity:0; } }
      </style>
    </head>
    <body>
      <div id="loading">
        <div class="spinner"></div>
        <div>Loading panorama...</div>
      </div>
      <div id="instructions">👆 Drag to look around • Pinch to zoom</div>

      <script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
      <script src="https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/controls/OrbitControls.js"></script>
      <script>
        const imageUrl = "${widget.imageUrl}";
        const scene = new THREE.Scene();
        const camera = new THREE.PerspectiveCamera(75, window.innerWidth/window.innerHeight, 0.1, 1000);
        const renderer = new THREE.WebGLRenderer({ antialias: true });
        renderer.setSize(window.innerWidth, window.innerHeight);
        document.body.appendChild(renderer.domElement);

        const geometry = new THREE.SphereGeometry(500, 60, 40);
        geometry.scale(-1,1,1);

        const material = new THREE.MeshBasicMaterial();
        const mesh = new THREE.Mesh(geometry, material);
        scene.add(mesh);

        camera.position.set(0,0,0.1);

        const controls = new THREE.OrbitControls(camera, renderer.domElement);
        controls.enableZoom = true;
        controls.enablePan = false;
        controls.rotateSpeed = -0.6;
        controls.minDistance = 1;
        controls.maxDistance = 500;
        controls.minPolarAngle = 0;
        controls.maxPolarAngle = Math.PI;

        const loader = new THREE.TextureLoader();
        loader.load(imageUrl, function(texture) {
          material.map = texture;
          material.needsUpdate = true;
          document.getElementById('loading').style.display = 'none';
        });

        function animate() {
          requestAnimationFrame(animate);
          controls.update();
          renderer.render(scene, camera);
        }
        animate();

        window.addEventListener('resize', () => {
          camera.aspect = window.innerWidth / window.innerHeight;
          camera.updateProjectionMatrix();
          renderer.setSize(window.innerWidth, window.innerHeight);
        });
      </script>
    </body>
    </html>
    """;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..loadRequest(Uri.dataFromString(
        htmlContent,
        mimeType: 'text/html',
        encoding: utf8,
      ));
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: WebViewWidget(controller: _controller),
    );
  }
}

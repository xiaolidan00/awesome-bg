function flatArr(arr) {
  return arr.flat(Infinity);
}
function resize(gl) {
  gl.canvas.width = gl.canvas.parentElement.offsetWidth;
  gl.canvas.height = gl.canvas.parentElement.offsetHeight;
  gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);
}
function initGl(id) {
  var canvas = document.getElementById(id);
  canvas.style.background = 'black';

  // var weglKey = ['webgl2', 'experimental-webgl2', 'webgl', 'experimental-webgl'];

  // var gl;
  // for (let i = 0; i < weglKey.length; i++) {
  //   gl = canvas.getContext(weglKey[i]);
  //   if (gl) {
  //     break;
  //   }
  // }
  var gl = canvas.getContext('webgl');
  resize(gl);
  window.addEventListener('resize', () => {
    resize(gl);
  });
  return gl;
}
function cleanGl(gl) {
  gl.clearColor(0.0, 0.0, 0.0, 1.0);
  gl.clearDepth(1.0);
  gl.enable(gl.DEPTH_TEST);
  gl.depthFunc(gl.LEQUAL);
  gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
}
function loadShader(gl, type, source) {
  const shader = gl.createShader(type);

  gl.shaderSource(shader, source);

  gl.compileShader(shader);

  if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
    console.log(
      (type == gl.VERTEX_SHADER ? '顶点着色器-错误' : '片元着色器-错误') +
        gl.getShaderInfoLog(shader)
    );
    gl.deleteShader(shader);
    return null;
  }

  return shader;
}
function initShaderProgram(gl, fs) {
  const vs = `attribute vec2 pos;
    void main(){gl_Position=vec4(pos,0.0,1.0);}`;

  const vertexShader = loadShader(gl, gl.VERTEX_SHADER, vs);
  const fragmentShader = loadShader(gl, gl.FRAGMENT_SHADER, fs);
  const shaderProgram = gl.createProgram();
  gl.attachShader(shaderProgram, vertexShader);
  gl.attachShader(shaderProgram, fragmentShader);
  gl.linkProgram(shaderProgram);
  gl.useProgram(shaderProgram);
  gl.program = shaderProgram;

  if (!gl.getProgramParameter(shaderProgram, gl.LINK_STATUS)) {
    console.log('Unable to initialize the shader program: ' + gl.getProgramInfoLog(shaderProgram));
    gl.deleteProgram(shaderProgram); //删除着色器程序
    gl.deleteProgram(fragmentShader); //删除片元着色器
    gl.deleteProgram(vertexShader); //删除顶点着色器
    return null;
  }
  initArrBuffer(
    gl,
    'pos',
    new Float32Array(
      flatArr([
        [1.0, 1.0],
        [1.0, -1.0],
        [-1.0, -1.0],
        [-1.0, -1.0],
        [-1.0, 1.0],
        [1.0, 1.0]
      ])
    ),
    2
  );
  return shaderProgram;
}
function getGLSL(url) {
  return new Promise((resolve) => {
    let xhr = new XMLHttpRequest();
    xhr.open('GET', url, true);
    xhr.onload = function () {
      if (xhr.status === 200) {
        resolve(xhr.response);
      }
    };
    xhr.onerror = function (err) {
      console.log(err);
      resolve();
    };
    xhr.send();
  });
}
function isPowerOf2(value) {
  return (value & (value - 1)) == 0;
}
function initTexture(gl, url) {
  return new Promise((resolve) => {
    var image = new Image();
    image.src = url; // 必须同域
    image.onload = function () {
      const texture = gl.createTexture();

      gl.bindTexture(gl.TEXTURE_2D, texture);

      if (isPowerOf2(image.width) && isPowerOf2(image.height)) {
        gl.generateMipmap(gl.TEXTURE_2D);
      } else {
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
      }
      gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image);

      resolve(texture);
    };
  });
}
function initArrBuffer(gl, code, value, perLen) {
  const buffer = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
  gl.bufferData(gl.ARRAY_BUFFER, value, gl.STATIC_DRAW);

  let aVal = gl.getAttribLocation(gl.program, code);
  gl.vertexAttribPointer(aVal, perLen, gl.FLOAT, false, 0, 0);
  gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
  gl.enableVertexAttribArray(aVal);
}
async function init() {
  let res = window.location.search.substring(1);
  if (res && res.indexOf('res=') >= 0) {
    res = res.split('=')[1];
  }
  const fs = await getGLSL(res || 'glsl/base.glsl');
  console.log(fs);
  var gl = initGl('webgl');

  var program = initShaderProgram(gl, fs);

  // gl.getExtension('OES_standard_derivatives');

  // if (fs.indexOf('sampler2D') >= 0) {
  //   gl.getExtension('EXT_shader_texture_lod');
  //   gl.getExtension('OES_texture_float');
  //   var texture = await initTexture(gl, 'noise.png');
  // }

  var startTime = performance.now();
  var mouse = { x: 0, y: 0 };

  gl.canvas.addEventListener('pointer', (ev) => {
    mouse.x = ev.clientX / gl.canvas.width;
    mouse.y = 1 - ev.clientY / gl.canvas.height;
  });
  function drawScene() {
    cleanGl(gl);
    gl.uniform2f(
      gl.getUniformLocation(gl.program, 'resolution'),
      gl.canvas.width,
      gl.canvas.height
    );
    var time = performance.now() - startTime;
    gl.uniform1f(gl.getUniformLocation(gl.program, 'time'), time / 1000);
    gl.uniform2f(gl.getUniformLocation(gl.program, 'mouse'), mouse.x, mouse.y);
    gl.drawArrays(gl.TRIANGLES, 0, 6);
  }
  function animate() {
    drawScene();
    requestAnimationFrame(animate);
  }
  animate();
}

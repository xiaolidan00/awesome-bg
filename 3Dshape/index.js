import { createProgram, createShader } from '../utils/webglUtils.js';

import shaderList from './shaders.js';

const shaderhtml = [];
shaderList.forEach((item) => {
  shaderhtml.push(`<a id="${item}" href="#${item}">${item.substring(0, item.length - 5)}</a>`);
});
console.log(shaderList);
const menuDom = document.getElementById('menu');
menuDom.innerHTML = shaderhtml.join('');

function main(fragment) {
  const canvas = document.getElementById('myCanvas');

  const iMouse = {
    x: 0,
    y: 0,
    z: 0
  };
  canvas.onmousedown = () => {
    iMouse.z = 1;
  };
  canvas.onmousemove = (event) => {
    iMouse.x = event.offsetX;
    iMouse.y = event.offsetY;
  };
  canvas.onmouseup = () => {
    iMouse.z = 0;
  };
  canvas.onmouseleave = () => {
    iMouse.z = 0;
  };
  const gl =
    canvas.getContext('webgl2') || canvas.getContext('webgl') || c.getContext('experimental-webgl');
  //顶点着色器代码
  const vertexShader = /* glsl*/ `#version 300 es
   in vec2 position;
void main(void) {
    gl_Position = vec4(position,0.,1.0);
}`;
  //创建顶点着色器
  const vs = createShader(gl, vertexShader, 'vs');

  //片元着色器代码
  const fragmentShader = /* glsl*/ `#version 300 es
  precision highp float;
uniform float iTime;
uniform vec3 iMouse;
uniform vec2 iResolution;
 out vec4 outColor;
${fragment}
void main(void)
{
    mainImage(outColor,gl_FragCoord.xy);
}
`;

  //创建片元着色器
  const fs = createShader(gl, fragmentShader, 'fs');

  const program = createProgram(gl, vs, fs);

  //顶点着色器数据输入
  const vertex = new Float32Array([-1, -1, -1, 1, 1, 1, -1, -1, 1, 1, 1, -1]);

  const positionBuffer = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);
  gl.bufferData(gl.ARRAY_BUFFER, vertex, gl.STATIC_DRAW);
  const posAttr = gl.getAttribLocation(program, 'position');
  gl.enableVertexAttribArray(posAttr);
  gl.vertexAttribPointer(
    posAttr, // location
    2, // size (components per iteration)
    gl.FLOAT, // type of to get from buffer
    false, // normalize
    0, // stride (bytes to advance each iteration)
    0 // offset (bytes from start of buffer)
  );

  function animate(iTime) {
    //清空画布
    gl.clearColor(0.0, 0.0, 0.0, 1.0);
    gl.clearDepth(1.0);
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    gl.uniform2f(gl.getUniformLocation(program, 'iResolution'), canvas.width, canvas.height);
    gl.uniform1f(gl.getUniformLocation(program, 'iTime'), iTime * 0.001);
    gl.uniform3f(gl.getUniformLocation(program, 'iMouse'), iMouse.x, iMouse.y, iMouse.z);
    gl.drawArrays(gl.TRIANGLES, 0, 6);
    window.requestAnimationFrame(animate);
  }
  animate(0);
}

function getShader(str) {
  const url = window.location.hash.substring(1) || str;
  const pre = document.querySelector('#menu>a.active');
  if (pre) {
    pre.classList.remove('active');
  }
  document.getElementById(url).classList.add('active');
  fetch(url)
    .then((res) => res.text())
    .then((fragment) => {
      console.log(fragment);
      main(fragment);
    });
}
getShader(shaderList[0]);

window.onhashchange = () => {
  getShader();
};

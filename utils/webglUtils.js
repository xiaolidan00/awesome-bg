/**
 *
 * @param {WebGLRenderingContext} gl
 * @param {string} shader 着色器代码
 * @param {'vs'|'fs'} type 着色器类型
 */
export function createShader(gl, code, type = 'vs') {
  //创建着色器  gl.VERTEX_SHADER顶点着色器 gl.FRAGMENT_SHADER片元着色器
  const shader = gl.createShader(type === 'vs' ? gl.VERTEX_SHADER : gl.FRAGMENT_SHADER);
  if (shader) {
    //设置着色器代码
    gl.shaderSource(shader, code);
    //编译着色器
    gl.compileShader(shader);
    //判断着色器编译是否通过
    if (gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
      return shader;
    } else {
      //编译错误,打印错误信息
      console.log(gl.getShaderInfoLog(shader), code);
      //删除着色器
      gl.deleteShader(shader);
    }
  }
}

/**
 *
 * @param {WebGLRenderingContext} gl
 * @param {WebGLShader} vs 顶点着色器
 * @param {WebGLShader} fs 片元着色器
 * @returns
 */
export function createProgram(gl, vs, fs) {
  //创建着色器程序
  const program = gl.createProgram();
  //绑定顶点着色器
  gl.attachShader(program, vs);
  //绑定片元着色器
  gl.attachShader(program, fs);
  //连接着色器程序
  gl.linkProgram(program);
  //判断着色器程序是否正常连接
  if (gl.getProgramParameter(program, gl.LINK_STATUS)) {
    //使用着色器程序
    gl.useProgram(program);
    return program;
  } else {
    //着色器程序编译错误
    console.log(gl.getProgramInfoLog(program));
    //删除着色器程序
    gl.deleteProgram(program);
  }
}

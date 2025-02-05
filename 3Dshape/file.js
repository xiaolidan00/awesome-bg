const fs = require('fs');
fs.readdir('./', (err, data) => {
  if (!err) {
    fs.writeFile(
      './shaders.js',
      `export default ${JSON.stringify(data.filter((a) => a.endsWith('.glsl')))}`,
      (error) => {
        if (!error) {
          console.log('更新glsl文件夹完毕');
        }
      }
    );
  }
});

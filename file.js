const fs = require('fs');
fs.readdir('./glsl', (err, data) => {
  if (!err) {
    fs.writeFile('./index.js', `var files=${JSON.stringify(data)}`, (error) => {
      if (!error) {
        console.log('更新glsl文件夹完毕');
      }
    });
  }
});

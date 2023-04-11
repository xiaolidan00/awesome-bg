export function CanvasBg(el, pointNum = 500) {
  let animateFrame;
  let simplex = new SimplexNoise();
  let canvas = document.createElement('canvas');
  canvas.width = el.parentNode.offsetWidth;
  canvas.height = el.parentNode.offsetHeight;
  el.append(canvas);

  let ctx = canvas.getContext('2d');
  const md = 50;

  const vel = 0.2;
  const brown = 0.2;
  let dt = 0.1;
  let lastT = new Date().getTime();
  let pointList = [];
  const noiseScale = 0.01;
  const noiseSpeed = 0.0005;
  let distance = canvas.height * 0.2;

  function getDistance(p1, p2) {
    let dx = p1.x - p2.x;
    let dy = p1.y - p2.y;
    return Math.sqrt(dx * dx + dy * dy);
  }
  let Point = function () {
    let x = parseInt(Math.random() * canvas.width);
    let y = parseInt(Math.random() * canvas.height);
    this.x = x;
    this.y = y;
    this.size = parseInt(Math.random() * 3) + 2;
    // this.moveX = Math.pow(-1, parseInt(Math.random() * 10)) * 0.1;
    // this.moveY = Math.pow(-1, parseInt(Math.random() * 10)) * 0.1;
    // this.opacity = parseInt(Math.random() * 10) * 0.1;
  };
  Point.prototype.move = function (t) {
    const u =
      (Math.random() - 0.5) * brown +
      simplex.noise3D(this.x * noiseScale, this.y * noiseScale, t * noiseSpeed);
    const v =
      (Math.random() - 0.5) * brown +
      simplex.noise3D((this.x + 15000) * noiseScale, (this.y + 15000) * noiseScale, t * noiseSpeed);

    this.x = (this.x + u * dt * vel) % (canvas.width + 2 * md);
    this.y = (this.y + v * dt * vel) % (canvas.height + 2 * md);
  };
  Point.prototype.drawLine = function () {
    ctx.strokeStyle = 'rgba(0,0,0,0.1)';
    pointList.forEach((item) => {
      let d = getDistance(item, this);
      if (d <= distance) {
        ctx.beginPath();
        ctx.moveTo(item.x, item.y);
        ctx.lineTo(this.x, this.y);
        ctx.closePath();
        ctx.stroke();
      }
    });
  };
  Point.prototype.draw = function () {
    ctx.beginPath();
    ctx.fillStyle = 'rgba(0,0,0,1)';
    ctx.arc(this.x, this.y, this.size, 0, Math.PI * 2, true);
    ctx.closePath();
    ctx.fill();
  };

  function createPoints() {
    pointList = [];
    for (let i = 0; i < pointNum; i++) {
      pointList.push(new Point());
    }
  }
  createPoints();
  function animation(t) {
    dt = t - lastT;
    lastT = t;
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    pointList.forEach((item) => {
      item.move(t);
    });
    pointList.forEach((item) => {
      item.draw();
      item.drawLine();
    });
    animateFrame = window.requestAnimationFrame(animation);
  }

  animateFrame = window.requestAnimationFrame(animation);

  function onBgResize() {
    canvas.width = el.parentNode.offsetWidth;
    canvas.height = el.parentNode.offsetHeight;
    distance = canvas.height * 0.12;
    pointNum = Math.min(canvas.width, canvas.height) * 0.1;
    createPoints();
  }
  this.onBgResize = onBgResize;
  window.addEventListener('resize', onBgResize);
  this.cleanAnimate = function () {
    window.cancelAnimationFrame(animateFrame);
    window.removeEventListener('resize', onBgResize);
  };
  return this;
}

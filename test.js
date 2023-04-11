const canvas = document.querySelector('canvas');
const ctx = canvas.getContext('2d');
requestAnimationFrame(draw);

const md = 50;
const mds = md * md;
const tt = 0.4;
const noiseScale = 0.003;
const noiseSpeed = 0.0005;
const vel = 0.2;
const ps = 600;
const brown = 0.1;

let points = [];
let lastT = performance.now();

const simplex = new SimplexNoise();

const randPtX = () => Math.random() * (innerWidth + 2 * md);
const randPtY = () => Math.random() * (innerWidth + 2 * md);
const randPt = () => [randPtX(), randPtY()];

function draw(t) {
  const dt = t - lastT;
  lastT = t;

  ctx.fillStyle = 'white';
  ctx.strokeStyle = 'black';

  if (canvas.width !== innerWidth || canvas.height !== innerHeight) {
    canvas.width = innerWidth;
    canvas.height = innerHeight;
    points = Array.from({ length: ps }, randPt);
  } else {
    ctx.clearRect(0, 0, innerWidth, innerHeight);
  }

  points.forEach((p) => {
    const u =
      (Math.random() - 0.5) * brown +
      simplex.noise3D(p[0] * noiseScale, p[1] * noiseScale, t * noiseSpeed);
    const v =
      (Math.random() - 0.5) * brown +
      simplex.noise3D((p[0] + 15000) * noiseScale, (p[1] + 15000) * noiseScale, t * noiseSpeed);

    p[0] = (p[0] + u * dt * vel) % (innerWidth + 2 * md);
    p[1] = (p[1] + v * dt * vel) % (innerHeight + 2 * md);
  });

  const l = points.length;
  for (let i = 0; i < l; i++) {
    const [x1, y1] = points[i];
    for (let j = i + 1; j < l; j++) {
      const [x2, y2] = points[j];
      const dx = x1 - x2;
      const dy = y1 - y2;
      if (dx > md || dx < -md || dy > md || dy < -md) continue;
      const rr = dx * dx + dy * dy;
      if (rr < 1) {
        points[i][0] = randPtX();
        points[i][1] = randPtY();
        continue;
      }
      if (rr > mds) continue;
      const f = (mds - rr) / mds;

      ctx.beginPath();
      ctx.globalAlpha = f;
      ctx.moveTo(x1, y1);
      ctx.lineTo(x2, y2);
      ctx.stroke();
    }
  }

  ctx.globalAlpha = 1;
  ctx.restore();

  requestAnimationFrame(draw);
}

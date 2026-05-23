const fs = require('fs');
const file = 'build/web/flutter_bootstrap.js';
if (fs.existsSync(file)) {
  let content = fs.readFileSync(file, 'utf8');
  if (content.includes(',let u;')) {
    content = content.replace(',let u;', ';let u;');
    fs.writeFileSync(file, content, 'utf8');
    console.log('Successfully repaired flutter_bootstrap.js syntax error!');
  } else {
    console.log('No syntax error found to repair.');
  }
} else {
  console.log('flutter_bootstrap.js does not exist.');
}

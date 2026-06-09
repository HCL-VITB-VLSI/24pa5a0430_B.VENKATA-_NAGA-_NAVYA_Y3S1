const fs = require('fs');
const path = require('path');

const commonPaths = [
  'C:\\iverilog\\bin',
  'C:\\yosys\\bin',
  'C:\\oss-cad-suite\\bin',
  'C:\\Program Files\\oss-cad-suite\\bin',
  'C:\\msys64\\mingw64\\bin',
  'C:\\msys64\\usr\\bin',
  'C:\\tools\\msys64\\mingw64\\bin',
  'C:\\tools\\msys64\\usr\\bin',
  'C:\\Users\\' + process.env.USERNAME + '\\AppData\\Local\\Programs\\Python',
];

console.log('Searching for tools...');

commonPaths.forEach(dir => {
  try {
    if (fs.existsSync(dir)) {
      console.log(`Checking directory: ${dir}`);
      const files = fs.readdirSync(dir);
      files.forEach(file => {
        if (file.toLowerCase().includes('iverilog') || file.toLowerCase().includes('yosys') || file.toLowerCase().includes('python')) {
          console.log(`Found tool: ${path.join(dir, file)}`);
        }
      });
    }
  } catch (err) {
    // Ignore error
  }
});

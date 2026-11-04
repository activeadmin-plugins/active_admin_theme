import { execSync } from 'child_process';
import activeAdminPlugin from '@activeadmin/activeadmin/plugin';

// Last line only: Bundler's DEBUG env prints extra lines.
const bundleShow = (gem) => execSync(`bundle show ${gem}`, { encoding: 'utf-8' }).trim().split(/\r?\n/).pop();
const activeAdminPath = bundleShow('activeadmin');
const themePath = bundleShow('active_admin_theme');

export default {
  content: [
    `${activeAdminPath}/vendor/javascript/flowbite.js`,
    `${activeAdminPath}/plugin.js`,
    `${activeAdminPath}/app/views/**/*.{arb,erb,html,rb}`,
    `${themePath}/app/**/*.{arb,erb,html,rb,js}`,
    `${themePath}/lib/**/*.rb`,
    './app/admin/**/*.{arb,erb,html,rb}',
    './app/views/**/*.{arb,erb,html,rb}',
    './app/javascript/**/*.js'
  ],
  darkMode: "selector",
  plugins: [
    activeAdminPlugin
  ]
}

import 'ninja-keys';
import 'katex';

import autoRenderMath from 'katex/contrib/auto-render';

function setDarkMode(dark, preference) {
    if (dark) {
        preference !== "dark" ? localStorage.setItem('theme', 'dark') : localStorage.removeItem('theme');
        document.documentElement.classList.add('dark');
    } else if (!dark) {
        preference !== "light" ? localStorage.setItem('theme', 'light') : localStorage.removeItem('theme');
        document.documentElement.classList.remove('dark');
    }
};
const preference = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
if (localStorage.getItem('theme') === "dark" || (!('theme' in localStorage) && preference === 'dark')) {
    setDarkMode(true, preference);
}

const darkModeButton = document.getElementById("button-dark-mode");
const isDarkModeEnabled = () => document.documentElement.classList.toggle("dark");

darkModeButton.addEventListener("click", function() {
    setDarkMode(isDarkModeEnabled(), preference);
});


// ===

function partition(array, isValid) {
 return array.reduce(([pass, fail], elem) => {
  return isValid(elem) ? [[...pass, elem], fail] : [pass, [...fail, elem]];
 }, [[], []]);
}

window.addEventListener("load", (event) => {
 autoRenderMath(document.body)

 const openAllDetailsAbove = elt => {
  while (elt != null) {
   if (elt.nodeName == 'DETAILS') {
    elt.open = true
   }

   elt = elt.parentNode;
  }
 }

 const jumpToSubtree = evt => {
  if (evt.target.tagName === "A") {
   return;
  }

  const link = evt.target.closest('span[data-target]')
  const selector = link.getAttribute('data-target')
  const tree = document.querySelector(selector)
  openAllDetailsAbove(tree)
  window.location = selector
 }


 [...document.querySelectorAll("[data-target^='#']")].forEach(
  el => el.addEventListener("click", jumpToSubtree)
 );
});

const ninja = document.querySelector('ninja-keys');

fetch("./forest.json")
 .then((res) => res.json())
 .then((data) => {
  const items = []

  const bookmarkIcon = '<svg xmlns="http://www.w3.org/2000/svg" height="20" viewBox="0 -960 960 960" width="20"><path d="M120-40v-700q0-24 18-42t42-18h480q24 0 42.5 18t18.5 42v700L420-167 120-40Zm60-91 240-103 240 103v-609H180v609Zm600 1v-730H233v-60h547q24 0 42 18t18 42v730h-60ZM180-740h480-480Z"/></svg>'

  const isTopTree = (addr) => {
   const item = data[addr]
   return item.tags ? item.tags.includes('top') : false
  }

  const addItemToSection = (addr, section, icon) => {
   const item = data[addr]
   const title =
    item.taxon
     ? (item.title ? `${item.taxon}. ${item.title}` : item.taxon)
     : (item.title ? item.title : "Untitled")
   const fullTitle = `${title} [${addr}]`
   items.push({
    id: addr,
    title: fullTitle,
    section: section,
    icon: icon,
    handler: () => {
     window.location.href = item.route.replace('.xml', '.html');
    }
   })
  }

  const [top, rest] = partition(Object.keys(data), isTopTree)
  top.forEach((addr) => addItemToSection(addr, "Top Trees", bookmarkIcon))
  rest.forEach((addr) => addItemToSection(addr, "All Trees", null))

  ninja.data = items
 });

window.onload = function() {
  const vertElement = document.querySelector('.vert');
  if (vertElement) {
    window.scrollTo({
      top: 0,
      left: document.body.scrollWidth,
      behavior: "smooth",
    });
  }
};

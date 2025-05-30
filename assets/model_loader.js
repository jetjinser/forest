onmessage = function(_) {
  const url = new URL("/models/puppet.inp", "https://assets.purejs.icu").href;
  console.log('Worker: Message received from main script. downloading file from', url);
  fetch(url)
    .then(resp => resp.blob())
    .then(blob => blob.arrayBuffer())
    .then(array_buffer => { postMessage(array_buffer); })
    .catch((error) => console.error(error));
  console.log('Worker: done');
}

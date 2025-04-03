import * as THREE from 'three';

const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera( 75, window.innerWidth / window.innerHeight, 0.1, 1000 );

const renderer = new THREE.WebGLRenderer();
renderer.setSize( window.innerWidth, window.innerHeight );
renderer.setAnimationLoop( animate );
document.body.appendChild( renderer.domElement );


const sun_geometry = new THREE.SphereGeometry( 15,32,16); 
const sunTexture = new THREE.TextureLoader().load('download.jpeg');
const sun_material = new THREE.MeshBasicMaterial( { map: sunTexture } ); 
const sun = new THREE.Mesh( sun_geometry, sun_material ); 
scene.add( sun );

const mer_geometry = new THREE.SphereGeometry( 7,16,8); 
const merTexture = new THREE.TextureLoader().load('mer.jpg');
const mer_material = new THREE.MeshBasicMaterial( {  map: merTexture } ); 
const mer = new THREE.Mesh( mer_geometry, mer_material ); 
scene.add( mer );

const mars_geometry = new THREE.SphereGeometry( 7,16,8); 
const marsTexture = new THREE.TextureLoader().load('mars.png');
const mars_material = new THREE.MeshBasicMaterial( { map: marsTexture } ); 
const mars = new THREE.Mesh( mars_geometry, mars_material ); 
scene.add( mars );

const earth_geometry = new THREE.SphereGeometry( 7,16,8); 
const earthTexture = new THREE.TextureLoader().load('earth.jpg');
const earth_material = new THREE.MeshBasicMaterial( { map: earthTexture } ); 
const earth = new THREE.Mesh( earth_geometry, earth_material ); 
scene.add( earth );

camera.position.z = 150;

mer.position.x=50;
mars.position.x=90;
earth.position.x=120;

function animate() {

	requestAnimationFrame(animate);
	const time1=Date.now()*0.001;
	const time2=Date.now()*0.002;
	const time3=Date.now()*0.003;
	//sun.rotation.x += 0.00;
	//sun.rotation.y += 0.01;
	/*mer.rotation.x += 0.01;
	mer.rotation.y += 0.01;
	mars.rotation.x += 0.01;
	mars.rotation.y += 0.01;
	earth.rotation.x += 0.01;
	earth.rotation.y += 0.01;*/
	
	mer.position.x=30*Math.sin(time1);
	mer.position.z=30*Math.cos(time1);
	earth.position.x=30*Math.sin(time2);
	earth.position.z=30*Math.cos(time2);
	mars.position.x=30*Math.sin(time3);
	mars.position.z=30*Math.cos(time3);
	renderer.render( scene, camera );

}
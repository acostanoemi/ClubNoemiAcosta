importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyAUZiVgzLoJg-K4UxZJH2j1m6MSOL90RIA",
  authDomain: "clubnoemiacosta.firebaseapp.com",
  projectId: "clubnoemiacosta",
  storageBucket: "clubnoemiacosta.firebasestorage.app",
  messagingSenderId: "1062598928107",
  appId: "1:1062598928107:web:f319bd94f379bbddaf00ae"
});

const messaging = firebase.messaging();

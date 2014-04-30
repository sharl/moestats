// -*- coding: utf-8 -*-
$.ajaxSetup({ cache: false }); // IEは死ねばいいのに


// これ以降のソースはjQuery使いこなしてないので見ないで＞＜
var uri = 'stats';
var timer = new wTimer({
    fps: 0.1,
    run: function() {
      $.getJSON(uri, function(servers) {
          var html = "<caption>リアルタイム更新中</caption>";
          html += "<tr><th>server</th><th>stats</th><th>now</th><th>max</th><th>reboot</th></tr>";
          for (var s in servers) {
            var server    = servers[s]["name"];
            var stats     = servers[s]["status"];
            var login     = servers[s]["login"];
            var login_max = servers[s]["login_max"];
            var reboot    = new Date(servers[s]["reboot"] * 1000);
            var year  = reboot.getFullYear() % 100;
            var month = reboot.getMonth() + 1; month = (month < 10) ? '0' + month : month;
            var day   = reboot.getDate();      day   = (day   < 10) ? '0' + day   : day;
            var hour  = reboot.getHours();     hour  = (hour  < 10) ? '0' + hour  : hour;
            var min   = reboot.getMinutes();   min   = (min   < 10) ? '0' + min   : min;
            var sec   = reboot.getSeconds();   sec   = (sec   < 10) ? '0' + sec   : sec;
            reboot = year + '-' + month + '-' + day + ' ' + hour + ':' + min + ':' + sec;
			
            html += "<tr id='server'>";
            html += "<td id='name'>" + server + "</td>";
            html += "<td id='status'>" + stats + "</td>";
            html += "<td id='login'>" + login + "</td>";
            html += "<td id='login_max'>" + login_max + "</td>";
            html += "<td id='reboot'>" + reboot + "</td>";
            html += "</tr>";
          }
          html = "<table>" + html + "</table>";
          document.getElementById("servers").innerHTML = html;
        });
    }
  });

window.onload = function() {
  timer.start();
};

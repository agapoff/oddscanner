#!/usr/bin/php
<?php
function getUrlContent($url){
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL,$url);
    curl_setopt($ch, CURLOPT_TIMEOUT, 5);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    $data = curl_exec($ch);
    $httpcode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    return ($httpcode>=200 && $httpcode<300) ? $data : false;
}

$json = getUrlContent("http://78.46.50.55:8000/parimatch/");

$data = json_decode($json, true);


#var_dump($data);
print $data{'lastUpdate'};
var_dump($data{'data'});

?>

// Bajar datos desde SINAVE
// URL: https://covid19.sinave.gob.mx/graficasconfirmados.aspx
// Esto hay que correrlo desde la consola de Chrome

function download(content, fileName, contentType) {
    var a = document.createElement("a");
    var file = new Blob([content], {type: contentType});
    a.href = URL.createObjectURL(file);
    a.download = fileName;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
}

function descarga_estados(result) {
    download(JSON.stringify(result,null,2), 'estados.txt', 'text/plain');
}

function descarga_datos(result) {
    download(JSON.stringify(result,null,2), 'datos.txt', 'text/plain');
}

function descarga_datos2(result) {
    download(JSON.stringify(result,null,2), 'datos2.txt', 'text/plain');
}

function descargarEstados() {
    $.ajax({
        type: "POST",
        contentType: "application/json; charset=utf-8",
        url: "Graficasconfirmados.aspx/Estados",
        data: "{}",
        datatype: "json",
        success: descarga_estados,
        error: function ajaxError(result) {
            alert(result.status + ' : ' + result.statusText);
        }
    });
}

function descargarDatos() {
    $.ajax({
        type: "POST",
        contentType: "application/json; charset=utf-8",
        url: "Graficasconfirmados.aspx/Datos",
        data: "{}",
        datatype: "json",
        success: descarga_datos,
        error: function ajaxError(result) {
            alert(result.status + ' : ' + result.statusText);
        }
    });
    
    $.ajax({
        type: "POST",
        contentType: "application/json; charset=utf-8",
        url: "Graficasconfirmados.aspx/Datos2",
        data: "{}",
        datatype: "json",
        success: descarga_datos2,
        error: function ajaxError(result) {
            alert(result.status + ' : ' + result.statusText);
        }
    });
    
}

descargarEstados();
descargarDatos();

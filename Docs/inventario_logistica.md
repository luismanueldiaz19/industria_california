Crear la migration de producto
- codigo unico de producto
- nombre
- unidad (unidad,libra,kg y otros), todo de forma UPPERCASE
- costo
- venta
- stock
- stock maximo
- stock minimo
- categoria
- imagen_producto (path url, y tomar en cuenta tamaño de la imagen para no afectar el rendimiento).


Crear un endpoint en el backend para obtener los productos.
CRUD todo completo , solo el administrador del sistema puede crear, editar y eliminar productos.

forma del UI ara agregar un producto
y forma masico con files excel para importar los productos.

poner las column mas importante primero.
y luego las opcionales.

tener una migracion de categoria,
en el formulario tiene que esta un drop disponible de categoria
si no hay tener la opcion de crear una categoria y actualizar para obtener la lista de categorias disponibles.

tener en el formulario de producto
poder crear o actualizar todo los campos
disponible tambien si tiene imagen el producto poder eliminar o subir 
una nueva imagen para este producto. 

quiero una pagina de administracion de producto
en una pagina.
vista de producto den Grid vista insdustrial y moderno. 
para desde ahi hacer todo el proceso de CRUD.

Barra de busqueda y filtros de categoria combinador
el bottom poder ver disponiblida,alerta de minimo y maximo, si esta disponible o no el producto.

filtro especial retectar numero negativo para general 
pdf con blade y usar la forma que se genera, sin ruta para el cliente.
poder aplicar order by, de menor a mayor o contrario. 

esta page que me sirva como inventario de producto. 
esta pagina tiene que tener todo sobre la forma correcta de pagination
en conjunto con el api de backend. 
toda las consulta tiene que ser protegida.

la forma decargar la imagenes si tiene el producto
tiene que ser de manera optima.


ahora mediante a esto tenemos que hacer un 
movimiento de inventario 

donde se guarde 
quien lo hizo , cantidad que producto y guardar el balance anterio
la causa de movimiento. 
si es ajustes, produccion o venta o (malo, perdido o dañado)
como sea mejora. 

crear reporte empresariales

y crear todo crear su blade de pdf.

utilizar el generador url para las ruta de pdf que tenemos. 













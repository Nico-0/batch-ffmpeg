@echo off
Echo inserte su texto deseado
Set /p variable_usuario=
echo has inserado %variable_usuario% , correcto?
Set /A cuenta = 2*16
echo cuenta ejemplo: %cuenta%
@pause
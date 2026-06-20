$(document).ready(function () {
  $('#RegistrarClienteForm').validate({
    rules: {
      Cedula: { required: true },
      Nombre: { required: true },
      Correo: { required: true, email: true }
    },
    messages: {
      Cedula: { required: 'Campo obligatorio.' },
      Nombre: { required: 'Campo obligatorio.' },
      Correo: { required: 'Campo obligatorio.', email: 'Formato no válido.' }
    },
    errorElement: 'span',
    errorClass: 'text-danger small',
    errorPlacement: function (error, element) {
      error.insertAfter(element.closest('.form-group'));
    },
    highlight: function (element) {
      $(element).addClass('is-invalid');
    },
    unhighlight: function (element) {
      $(element).removeClass('is-invalid');
    }
  });
});

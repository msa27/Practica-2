$(document).ready(function () {
  $('#RegistrarMascotaForm').validate({
    rules: {
      IdCliente: { required: true },
      Nombre: { required: true },
      Especie: { required: true },
      Raza: { required: true },
      Peso: { required: true, number: true, min: 0.01 }
    },
    messages: {
      IdCliente: { required: 'Campo obligatorio.' },
      Nombre: { required: 'Campo obligatorio.' },
      Especie: { required: 'Campo obligatorio.' },
      Raza: { required: 'Campo obligatorio.' },
      Peso: {
        required: 'Campo obligatorio.',
        number: 'Debe ser un número válido.',
        min: 'El peso mínimo es 0.01.'
      }
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

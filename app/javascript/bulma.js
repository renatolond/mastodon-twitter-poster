document.addEventListener("turbo:load", function() {
  // Get all "navbar-burger" elements
  const $navbarBurgers = Array.prototype.slice.call(document.querySelectorAll('.navbar-burger'), 0);

  // Check if there are any navbar burgers
  if ($navbarBurgers.length > 0) {

    // Add a click event on each of them
    $navbarBurgers.forEach( el => {
      el.addEventListener('click', () => {

        // Get the target from the "data-target" attribute
        const target = el.dataset.target;
        const $target = document.getElementById(target);

        // Toggle the "is-active" class on both the "navbar-burger" and the "navbar-menu"
        el.classList.toggle('is-active');
        $target.classList.toggle('is-active');

      });
    });
  }

  //$('#add_another_masto_word').click(function(e) {
  //  e.preventDefault();
  //  $('<input name="user[masto_word_list][]" value="" placeholder="#tw" class="input" type="text" id="user_masto_word_list">').insertBefore('#word_list_help');
  //});
  //$('#add_another_twitter_word').click(function(e) {
  //  e.preventDefault();
  //  $('<input name="user[twitter_word_list][]" value="" placeholder="#tw" class="input" type="text" id="user_twitter_word_list">').insertBefore('#word_list_help');
  //});
})

// This is where it all goes :)
// 
var header = new communityHeader();


$(function() {
  var cta = $('#cta');
  var modal = document.createElement('div');
  modal.classList.add('modal', 'elevation1', 'z-10');
  let modalTemplate = `
  <div class="modal--inner">
    <a href="#" class="modal--close btn btn-static-secondary" onclick="this.parentNode.parentNode.remove()"><span class="icon icon-cancel"></span></a>
    <header>
      <h2>Happy April Fools day!</h2>
    </header>
    <section>
      <p>We're glad you think this CSS API Client would be interesting for you; unfortunatly, it's all a joke</p>
      <p>But wait, we know how to do search. Why don't you have a look at our other, <strong>real</strong>, projects?</p>
      <div class="col-md-12 chapter-wrap">
        <span class="spacer40"></span>
         <div class="chapter">
            <h3>API Clients</h3>
            <div class="api-inte-list clearfix">
               <article class="guide-sm text-center">
                  <a href="https://algolia.com/doc/api-client/php/">
                     <img src="https://algolia.com/doc/assets/images/languages/php-53888094.svg" class="m-l-r-auto" alt="Php">
                     <h4 class="text-ellipsis"> PHP </h4>
                  </a>
               </article>
               <article class="guide-sm text-center">
                  <a href="https://algolia.com/doc/api-client/ruby/">
                     <img src="https://algolia.com/doc/assets/images/languages/ruby-00bdd41f.svg" class="m-l-r-auto" alt="Ruby">
                     <h4 class="text-ellipsis"> Ruby </h4>
                  </a>
               </article>
               <article class="guide-sm text-center">
                  <a href="https://algolia.com/doc/api-client/javascript/">
                     <img src="https://algolia.com/doc/assets/images/languages/javascript-68104683.svg" class="m-l-r-auto" alt="Javascript">
                     <h4 class="text-ellipsis"> JavaScript </h4>
                  </a>
               </article>
               <article class="guide-sm text-center">
                  <a href="https://algolia.com/doc/api-client/python/">
                     <img src="https://algolia.com/doc/assets/images/languages/python-dd5a8a8d.svg" class="m-l-r-auto" alt="Python">
                     <h4 class="text-ellipsis"> Python </h4>
                  </a>
               </article>
               <article class="guide-sm text-center">
                  <a href="https://algolia.com/doc/api-client/swift/">
                     <img src="https://algolia.com/doc/assets/images/languages/swift-4cb5cf0e.svg" class="m-l-r-auto" alt="Swift">
                     <h4 class="text-ellipsis"> iOS </h4>
                  </a>
               </article>
               <article class="guide-sm text-center">
                  <a href="https://algolia.com/doc/api-client/android/">
                     <img src="https://algolia.com/doc/assets/images/languages/android-f03624e7.svg" class="m-l-r-auto" alt="Android">
                     <h4 class="text-ellipsis"> Android </h4>
                  </a>
               </article>
               <article class="guide-sm text-center">
                  <a href="https://algolia.com/doc/api-client/csharp/">
                     <img src="https://algolia.com/doc/assets/images/languages/csharp-4075daa3.svg" class="m-l-r-auto" alt="Csharp">
                     <h4 class="text-ellipsis"> C# </h4>
                  </a>
               </article>
               <article class="guide-sm text-center">
                  <a href="https://algolia.com/doc/api-client/java/">
                     <img src="https://algolia.com/doc/assets/images/languages/java-65dd222f.svg" class="m-l-r-auto" alt="Java">
                     <h4 class="text-ellipsis"> Java </h4>
                  </a>
               </article>
               <article class="guide-sm text-center">
                  <a href="https://algolia.com/doc/api-client/go/">
                     <img src="https://algolia.com/doc/assets/images/languages/go-5f1359de.svg" class="m-l-r-auto" alt="Go">
                     <h4 class="text-ellipsis"> Go </h4>
                  </a>
               </article>
               <article class="guide-sm text-center">
                  <a href="https://algolia.com/doc/api-client/scala/">
                     <img src="https://algolia.com/doc/assets/images/languages/scala-bce891cf.svg" class="m-l-r-auto" alt="Scala">
                     <h4 class="text-ellipsis"> Scala </h4>
                  </a>
               </article>
            </div>
         </div>
      </div>
    </section>
  </div>`;
  modal.innerHTML = modalTemplate;
  var messages = [
    'Really?',
    'Are you sure?',
    'Ok, one more click...'
  ];
  cta.on('click', function(event) {
    event.preventDefault();

    var nextMessage = messages.shift();
    if (!nextMessage) {
      document.body.appendChild(modal)
      return;
    }
    $(this).text(nextMessage);

  });
});


import Sortable from 'sortablejs';

let KanbanHooks = {};

KanbanHooks.Drag = {
  mounted() {
  let dragged; // this will change so we use `let`

  const hook = this;

  const selector = '#' + this.el.id;
  // var el = document.getElementById('items');
  // var sortable = Sortable.create(el);
  // return sortable
  document.querySelectorAll('.dropzone').forEach((dropzone) => {
    console.log(dropzone)
    var sortable = new Sortable(dropzone, {
      animation: 150,
      draggable: '.draggable',
      delay: 50,
      sort: true,
      delayOnTouchOnly: true,
      group: 'shared',
      chosenClass: "sortable-chosen",
      ghostClass: 'sortable-ghost',
      dragClass: "sortable-drag",  
      onStart: function(evt) {
        
      },
      onEnd: function(evt) {
        hook.pushEventTo(selector, 'dropped', {
          draggedId: evt.item.id, // id of the dragged item
          dropzoneId: evt.to.id, // id of the drop zone where the drop occured
          draggableIndex: evt.newDraggableIndex, // index where the item was dropped (relative to other items in the drop zone)
        });
      }
    });
    return sortable
    // var sortable = Sortable.create(dropzone);
    // return sortable
  });
 }

};


export { KanbanHooks }
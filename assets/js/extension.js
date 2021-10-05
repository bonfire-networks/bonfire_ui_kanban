import Sortable from 'sortablejs';

let KanbanHooks = {};

KanbanHooks.Drag = {
 mounted() {
  let dragged; // this will change so we use `let`

  const hook = this;

  const selector = '#' + this.el.id;
  console.log('the selector is: ', selector)
 }

};


export { KanbanHooks }
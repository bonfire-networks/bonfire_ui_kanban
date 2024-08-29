import Sortable from "sortablejs";

let KanbanHooks = {};

KanbanHooks.Sortable = {
	mounted() {
		let dragged; // this will change so we use `let`

		const hook = this;

		const selector = "#" + this.el.id;
		// var el = document.getElementById('items');
		// var sortable = Sortable.create(el);
		// return sortable
		document.querySelectorAll(".dropzone").forEach((dropzone) => {
			console.log(dropzone.dataset.group);
			var sortable = new Sortable(dropzone, {
				animation: 150,
				draggable: ".draggable",
				delay: 50,
				sort: true,
				delayOnTouchOnly: true,
				group: dropzone.dataset.group || "shared",
				chosenClass: "sortable-chosen",
				ghostClass: "sortable-ghost",
				dragClass: "sortable-drag",
				onStart: function (evt) {},
				onEnd: function (evt) {
					hook.pushEventTo(selector, "dropped", {
						dragged_id: evt.item.id, // id of the dragged item
						dragged_from_id: evt.from.id, // id of the drop zone where the item was dragged from
						dropped_to_id: evt.to.id, // id of the drop zone where the drop occurred
						dropped_index: evt.newDraggableIndex, // index where the item was dropped (relative to other items in the drop zone)
					});
				},
			});
			return sortable;
			// var sortable = Sortable.create(dropzone);
			// return sortable
		});
	},
};

export { KanbanHooks };

const rName = GetParentResourceName();

async function sendPost(url, data = {}){
    const response = await fetch(`https://${rName}/${url}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    });
        
    return await response.json();
}

function handleResize() {
    $("body").css("zoom", Math.min($(window).width() / 1920, $(window).height() / 1080))
}; handleResize(); window.addEventListener("resize", handleResize)

function handleImageError(dom) {
    dom.setAttribute("src", "./img/error.svg");
}

window.addEventListener("message",function(evt){
    var data = evt.data;

    switch(data.event){
        case 'openInventory':
            inventoryMenu.buildInventory(data.data);
        break;

        case 'addInventoryItem':
            inventoryMenu.addItem(data.data[0], data.data[1]);
        break;
        
        case 'removeInventoryItem':
            inventoryMenu.removeItem(data.data[0], data.data[1]);
        break;

        case 'showFastSlotsPreview':
            fastSlotsPreview.showFastSlotsPreview(data.data);
        break;

        case 'setLanguage':
            inventoryMenu.Lang = data.data;
        break;
    }
});

const promptManager = new Vue({
    el: ".prompt-layout",

    data: {
        active: false,
        title: "",
        description: "",
        response: "",
        promptResolve: null,
    },

    methods: {
        createPrompt(title, description, response) {
            return new Promise((resolve, _) => {
                this.active = true;
                this.promptResolve = resolve;

                $(".prompt-layout").show();
                $(".prompt-layout > .prompt-menu > .wrapper > input").focus();
                
                this.title = title || 'Prompt Menu';
                this.description = description || 'Introdu raspunsul dorit in caseta de mai jos si apoi apasa pe butonul pentru confirmare.';

                if (response)
                    this.response = response;
            });
        },

        usePrompt(ok) {
            var response = this.response;

            if (!ok){
                response = ok;
            }

            if (((typeof(response) == "string" ? response : "fakestring") || "").trim().length == 0){
                response = false;
            }
            
            if (this.promptResolve) {
                this.promptResolve(response);
            }

            this.hidePrompt();
        },

        hidePrompt() {
            $(".prompt-layout").hide();
            this.active = false;
            this.response = "";
            
            if (this.promptResolve) {
                this.promptResolve(false);
            }
            
            this.promptResolve = null;
        },
    },
});

const inventoryMenu = new Vue({
    el: ".inventory-wrapper",
    data: {
        active: false,
        showFast: false,

        inInfoMenu: false,
        fastSlots: {},
        userItems: {},

        charName: "Ilea Iulian",
        myWeight: "0/0kg",
        
        secondData: {
            id: "",
            weight: "0/0kg",
            slots: 7*10,
            items: {}
        },

        selectedItem: {
            label: "",
            item: "",
            desc: "",
            weight: 0,
            amount: 0,
        },

        Lang: {}
    },

    mounted() {
        window.addEventListener("keydown", this.onKey);
    },

    methods: {
        closeItemInfo() {
            if (!this.inInfoMenu) return;

            $(".iteminfo-container").hide();
            this.inInfoMenu = false;
        },

        onKey() {
            var theKey = event.code;

            if (theKey == "Escape" && this.active) {
                if (this.inInfoMenu) {
                    $(".iteminfo-container").hide();
                    this.inInfoMenu = false;
                } else {
                    this.destroy();
                }
            }
        },

        buildInventory(data) {
            this.active = true;

            if (data.fastSlots) this.fastSlots = data.fastSlots;
            if (data.userItems) this.userItems = data.userItems;
            if (data.secondData) this.secondData = data.secondData;
            if (data.charName) this.charName = data.charName;
            if (data.myWeight) this.myWeight = data.myWeight;

            this.$nextTick(() => {
                $(".userInv").droppable({
                    drop: async function (event, ui) {
                        const itemWhere = $(ui.draggable).attr("data-where");
                        const itemSlot = $(ui.draggable).attr("data-itemSlot");
                        const slotId = $(this).attr("data-slotId");

                        if (slotId == itemSlot) return;
                        if (itemWhere == 'second') {
                            const itemExist = inventoryMenu.itemExist(inventoryMenu.userItems, inventoryMenu.secondData.items[itemSlot].item, false)

                            if (inventoryMenu.userItems[slotId] && slotId != itemExist) return;
                        
                            let amount = await promptManager.createPrompt(
                                inventoryMenu.Lang["move_item"], 
                                inventoryMenu.Lang["move_item_desc"]
                            );

                            if (!amount) return;
                            amount = Number(amount);

                            if (amount > 0 && amount <= inventoryMenu.secondData.items[itemSlot].amount) {                                                                
                                if (itemExist != "") { 
                                    inventoryMenu.userItems[itemExist].amount += amount;
                                    inventoryMenu.makeItem(itemExist);
                                } else {
                                    inventoryMenu.userItems[slotId] = {
                                        amount: amount,
                                        item: inventoryMenu.secondData.items[itemSlot].item
                                    }
                                    inventoryMenu.makeItem(slotId);
                                }
                    
                                if (amount == inventoryMenu.secondData.items[itemSlot].amount) {
                                    inventoryMenu.secondData.items[itemSlot] = undefined;
                                } else {
                                    inventoryMenu.secondData.items[itemSlot].amount -= amount;
                                }
                                
                                inventoryMenu.makeItem(itemSlot, true);
                                sendPost("inventory:takeItem", [itemSlot, inventoryMenu.secondData.id, slotId, amount])
                            }
                        } else {
                            if (inventoryMenu.userItems[slotId]) {
                                const old = inventoryMenu.userItems[slotId];
                                inventoryMenu.userItems[slotId] = inventoryMenu.userItems[itemSlot];
                                inventoryMenu.userItems[itemSlot] = old;

                                inventoryMenu.makeItem(itemSlot);
                                inventoryMenu.makeItem(slotId);
                            } else {
                                inventoryMenu.userItems[slotId] = inventoryMenu.userItems[itemSlot];
                                inventoryMenu.userItems[itemSlot] = undefined;

                                inventoryMenu.makeItem(itemSlot);
                                inventoryMenu.makeItem(slotId);
                            }

                            sendPost("inventory:moveItem", [itemSlot, slotId])
                        }
                    }
                });

                $(".secondInv").droppable({
                    drop: async function (event, ui) {
                        const itemWhere = $(ui.draggable).attr("data-where");
                        const itemSlot = $(ui.draggable).attr("data-itemSlot");
                        const slotId = $(this).attr("data-slotId");

                        if (slotId == itemSlot) return;
                        if (itemWhere == 'main') {
                            const itemExist = inventoryMenu.itemExist(inventoryMenu.secondData.items, inventoryMenu.userItems[itemSlot].item, true)

                            if (inventoryMenu.secondData.items[slotId] && slotId != itemExist) return;

                            let amount = await promptManager.createPrompt(
                                inventoryMenu.Lang["move_item"], 
                                inventoryMenu.Lang["move_item_desc"]
                            );

                            if (!amount) return;
                            amount = Number(amount);
                                                        
                            if (amount > 0 && amount <= inventoryMenu.userItems[itemSlot].amount) {
                                
                                if (itemExist != "") {                                        
                                    inventoryMenu.secondData.items[itemExist].amount += amount;
                                    inventoryMenu.makeItem(itemExist, true);
                                } else {
                                    inventoryMenu.secondData.items[slotId] = {
                                        amount: amount,
                                        item: inventoryMenu.userItems[itemSlot].item
                                    }
                                }

                                if (amount == inventoryMenu.userItems[itemSlot].amount) {
                                    inventoryMenu.userItems[itemSlot] = undefined;
                                } else {
                                    inventoryMenu.userItems[itemSlot].amount -= amount;
                                }
                                
                                inventoryMenu.makeItem(itemSlot);
                                inventoryMenu.makeItem(slotId, true);
                                sendPost("inventory:throwItem", [itemSlot, inventoryMenu.secondData.id, slotId, amount])
                            }
                        } else {
                            if (inventoryMenu.secondData.items[slotId]) {
                                const old = inventoryMenu.secondData.items[slotId];
                                inventoryMenu.secondData.items[slotId] = inventoryMenu.secondData.items[itemSlot];
                                inventoryMenu.secondData.items[itemSlot] = old;

                                inventoryMenu.makeItem(itemSlot, true);
                                inventoryMenu.makeItem(slotId, true);
                            } else {
                                inventoryMenu.secondData.items[slotId] = inventoryMenu.secondData.items[itemSlot];
                                inventoryMenu.secondData.items[itemSlot] = undefined;

                                inventoryMenu.makeItem(itemSlot, true);
                                inventoryMenu.makeItem(slotId, true);
                            }                            
                            sendPost("inventory:moveItemSecond", [itemSlot, inventoryMenu.secondData.id, slotId])
                        }
                    }
                });

                $(".destroy-data").droppable({
                    drop: async function (event, ui) {
                        const itemWhere = $(ui.draggable).attr("data-where");
                        const itemSlot = $(ui.draggable).attr("data-itemSlot");

                        if (itemWhere == "main") {
                            let amount = await promptManager.createPrompt(
                                inventoryMenu.Lang["destroy_item"], 
                                inventoryMenu.Lang["destroy_item_desc"]
                            );

                            if (!amount) return;
                            amount = Number(amount);
                                                        
                            if (amount > 0 && amount <= inventoryMenu.userItems[itemSlot].amount) {
                                if (amount == inventoryMenu.userItems[itemSlot].amount) {
                                    inventoryMenu.userItems[itemSlot] = undefined;
                                } else {
                                    inventoryMenu.userItems[itemSlot].amount -= amount;
                                }
                                
                                inventoryMenu.makeItem(itemSlot);
                                sendPost("inventory:destroyItem", [itemSlot, amount])
                            }
                        }
                    }
                });

                $(".fastInv").droppable({
                    drop: function (event, ui) {
                        const itemWhere = $(ui.draggable).attr("data-where");
                        const itemSlot = $(ui.draggable).attr("data-itemSlot");
                        const slotId = $(this).attr("data-slotId");

                        if (itemWhere == "main") {
                            $("#fastSlot-" + slotId).append(`
                                <img onerror = "handleImageError(this)" src = "img/${inventoryMenu.userItems[itemSlot].item}.png" data-fastSlotId = "${slotId}">
                            `)

                            $("#fastSlotPreview-" + slotId).append(`
                                <img onerror = "handleImageError(this)" src = "img/${inventoryMenu.userItems[itemSlot].item}.png">
                            `)

                            $("#fastSlot-" + slotId + " > img").on( "contextmenu", function() {
                                $("#fastSlot-" + slotId).html(`<p>${Number(slotId) + 1}</p>`);
                                sendPost("inventory:setFastSlot", [slotId, false])
                            });
                            
                            sendPost("inventory:setFastSlot", [slotId, inventoryMenu.userItems[itemSlot].item])
                        }
                    }
                });


                for (let slotId = 0; slotId <= 6; slotId++){
                    $("#fastSlot-" + slotId).html(`<p>${slotId + 1}</p>`);
                    $("#fastSlotPreview-" + slotId).empty();

                    if (inventoryMenu.fastSlots[slotId]) {                        
                        const itemExist = inventoryMenu.itemExist(inventoryMenu.userItems, inventoryMenu.fastSlots[slotId])

                        $("#fastSlot-" + slotId).append(`
                            <img onerror = "handleImageError(this)" src = "img/${inventoryMenu.userItems[itemExist].item}.png" data-fastSlotId = "${slotId}">
                        `)

                    
                        $("#fastSlotPreview-" + slotId).append(`
                            <img onerror = "handleImageError(this)" src = "img/${inventoryMenu.userItems[itemExist].item}.png">
                        `)

                        $("#fastSlot-" + slotId + " > img").on( "contextmenu", function() {
                            $("#fastSlot-" + slotId).html(`<p>${slotId + 1}</p>`);
                            sendPost("inventory:setFastSlot", [String(slotId), false])
                        });
                    }
                }

                for (let slotId = 0; slotId <= 34; slotId++) this.makeItem(slotId);
                for (let slotId = 0; slotId <= this.secondData.slots; slotId++) this.makeItem(slotId, true);
            })

            sendPost("setFocus", [true]);
        },

        useCloth(cloth) {
            sendPost("inventory:useCloth", [cloth])
        },

        addItem(itemSlot, data) {
            if (!this.active) return;            

            if(this.userItems[itemSlot]) {
                this.userItems[itemSlot].amount = data.amount
            } else {
                this.userItems[itemSlot] = data
            }

            this.makeItem(itemSlot)
        },

        removeItem(itemSlot, amount) {
            if (!this.active) return;            

            if (!this.userItems[itemSlot]) return;

            if(this.userItems[itemSlot].amount > amount) {
                this.userItems[itemSlot].amount -= amount
            } else {
                this.userItems[itemSlot] = undefined
            }

            this.makeItem(itemSlot)
        },
        
        makeItem(itemSlot, second) {            
            const element = second ? this.secondData.items[itemSlot] : this.userItems[itemSlot];
                          

            $(second ? "#secondSlot-" + itemSlot : "#userSlot-" + itemSlot).empty();

            if (element) {                
                $(second ? "#secondSlot-" + itemSlot : "#userSlot-" + itemSlot).append(`
                    <img onerror = "handleImageError(this)" src = "img/${element.item}.png" data-itemSlot = "${itemSlot}" data-where = "${second ? 'second' : 'main'}">
                    <p>${element.amount}</p>
                `)
    
                $((second ? "#secondSlot-" + itemSlot : "#userSlot-" + itemSlot) + " > img").draggable({
                    appendTo: "body",
                    helper: "clone",
                    containment: "window",
                    zIndex: 1000,
    
                    start: function () {
                        $(this).css({ position: "absolute" });
                    }
                });

                if (!second) {
                    $("#userSlot-" + itemSlot + " > img").on("contextmenu", function (event) {
                        event.preventDefault();
                        inventoryMenu.openItemSelector(element, "#userSlot-" + itemSlot);
                    }).dblclick(function(){
                        sendPost('inventory:useItem', [element.item]);

                        this.inInfoMenu = false;
                        $(".iteminfo-container").hide();
                    });
                }
            }
        },

        itemExist(tbl, item, second) {
            const what = second ? this.secondData.slots : 34
            
            for (let index = 0; index <= what; index++){
                const slotId = String(index);

                if (tbl[slotId] && tbl[slotId].item == item) return slotId;
            }
            
            return ""
        },

        async openItemSelector(actData, dom) {
            let element = $(".iteminfo-container");
            let itemOffset = $(dom).offset();            
    
            if (itemOffset) {
                element.css("top", itemOffset.top);
        
                let leftOffset = itemOffset.left;
                if (leftOffset + element.width() > $(window).width()) {
                    leftOffset = $(window).width() - element.width() - 20;
                }
        
                element.css("left", leftOffset);
        
                this.selectedItem = await sendPost("inventory:getItemData", [actData]);
        
                if (this.selectedItem.desc == "" || this.selectedItem.desc == null) {
                    this.selectedItem.desc = inventoryMenu.Lang["no_description"];
                }

                this.inInfoMenu = true;
                $(".iteminfo-container").show();
            }
        },

        async giveItem(item){
            let amount = await promptManager.createPrompt(
                inventoryMenu.Lang["give_item"], 
                inventoryMenu.Lang["give_item_desc"]
            );

            if (!amount) return;
            amount = Number(amount);

            const itemExist = inventoryMenu.itemExist(inventoryMenu.userItems, item);

            if (itemExist != "" && this.userItems[itemExist]) {
                sendPost('inventory:giveItem', [itemExist, amount]);
                this.destroy();
            }

            this.inInfoMenu = false;
            $(".iteminfo-container").hide();
        },

        useItem(item){
            const itemExist = inventoryMenu.itemExist(inventoryMenu.userItems, item);
            
            if (itemExist != "" && this.userItems[itemExist]) {
                sendPost('inventory:useItem', [item]);
            }

            this.inInfoMenu = false;
            $(".iteminfo-container").hide();
        },

        destroy() {
            this.active = false;
            this.inInfoMenu = false;

            if (promptManager.active) promptManager.hidePrompt();

            sendPost("inventory:closeInventory", []);
        },
    },
});

const fastSlotsPreview = new Vue({
    el: ".fastSlotsPreview",

    data: {
        active: false,
    },

    methods: {
        showFastSlotsPreview(fastSlots) {
            if (this.active) return;
            
            this.active = true;

            this.$nextTick(() => {
                for (let slotId = 0; slotId <= 6; slotId++){
                    $("#fastSlotPreview-" + slotId).empty();
                    
                    if (fastSlots[slotId]) {
                        $("#fastSlotPreview-" + slotId).append(`
                            <img onerror = "handleImageError(this)" src = "img/${fastSlots[slotId]}.png">
                        `)

                    }
                }

                setTimeout(() => {
                    $(".fastSlotsPreview").fadeOut(1000);
                }, 7000);
            });
            
            setTimeout(() => {
                fastSlotsPreview.active = false;
            }, 9000);
        },
    },
});
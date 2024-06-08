"use strict";
(function(){
    $.Schedule(3,function() {
        $.GetContextPanel().DeleteAsync(0);
    });
})();
window.dhtmlHistory.create({
    toJSON: function(o) {
        return JSON.stringify(o);
    }
    , fromJSON: function(s) {
        return JSON.parse(s);
    }
});

(function($) {
    SPA = {
        initialHash: null,
        initailArgs: { },
        historyChange: function(newLocation, historyData, first) {
            // if has first history, meaning ! is first load
            if (first) {
                dhtmlHistory.add(newLocation, historyData);
            } 
            else {
                // first page load
                if (historyStorage.hasKey(newLocation)) {
                    Jifty.update(historyStorage.get(newLocation), "");
                } 
                else {
                    // go back to initail hash or initail path
                    Jifty.update({ 
                             "continuation": {}, 
                                  "actions": {}, 
                         "action_arguments": {},
                                "fragments": [ { 
                                        "mode": "Replace", 
                                        "args": SPA.initailArgs , 
                                      "region": "__page", 
                                        "path": SPA.initialHash 
                                          } ] }, "");
                }
            }
        },
        _sp_submit_form: function(elt, event, submit_to) {
            if(event.ctrlKey||event.metaKey||event.altKey||event.shiftKey) return true;

            var form = Jifty.Form.Element.getForm(elt);
            var elements = Jifty.Form.getElements(form);

            // Three things need to get merged -- hidden defaults, defaults
            // from buttons, and form values.  Hence, we build up three lists
            // and then merge them.
            var hiddens = {};
            var buttons = {};
            var inputs = {};
            for (var i = 0; i < elements.length; i++) {
                var e = elements[i];
                var parsed = e.getAttribute("name").match(/^J:V-region-__page\.(.*)/);
                var extras = Jifty.Form.Element.buttonArguments(e);

                var extras_key_length = 0;
                $.each(extras, function() { extras_key_length++ });

                if (extras_key_length > 1) {
                    // Button with values
                    $.each(extras, function(k, v) {
                        if (k == 'extend') return;
                        parsed = k.match(/^J:V-region-__page\.(.*)/);
                        if ((parsed != null) && (parsed.length == 2)) {
                            buttons[ parsed[1] ] = v;
                        } else if (v.length > 0) {
                            inputs[ k ] = v;
                        }
                    });
                } else if ((parsed != null) && (parsed.length == 2)) {
                    // Hidden default
                    hiddens[ parsed[1] ] = $(e).val();
                } else if (e.name.length > 0) {
                    // Straight up values
                    inputs[ e.name ] = $(e).val();
                }
            }

            var args = $.extend({}, hiddens, buttons, inputs);

            return Jifty.update( {'continuation':{},'actions':null,'fragments':[
                        {'mode':'Replace','args':args,'region':'__page','path': submit_to
                    }]}, elt );
        }
    };

    // for page load event
    $(document).ready(function(){
        var hash = location.hash.slice(1);
        var search = location.search.slice(1);

        if( location.hash && ! location.search ) {
            if ( hash.indexOf('?') >= 0 ) {
                search = location.hash.slice(1);
                search = search.substring( search.indexOf('?') + 1 );
                hash = hash.substring( 0 , hash.indexOf('?') );
            }else {
                search = '';
            }

            var args = { } ;
            var gy = search.split("&");
            for (i=0; i<gy.length; i++) {
                var res =  gy[i].split("=");
                args[  res[0]  ] = res[1];
            }

            SPA.initailArgs = args;
            SPA.initialHash = hash;

        }
        else {
            SPA.initialHash = location.pathname + location.search; // /entrypoint
        }

        dhtmlHistory.initialize();
        dhtmlHistory.addListener(SPA.historyChange);

        // fire history event manually
        if( dhtmlHistory.isFirstLoad() && location.hash ) {
            dhtmlHistory.fireHistoryEvent( hash );
        }
    });
    
})(jQuery);

/* Follow buttons
 * Handles calling the API to follow the current user
 *
 * action - This being the action that the button should perform. Currently: "follow" or "unfollow"
 * type - The being the type of object the user is trying to support. Currently: "user", "group" or "dataset"
 * id - id of the objec the user is trying to follow
 * loading - State management helper
 *
 * Examples
 *
 *   <a data-module="follow" data-module-action="follow" data-module-type="user" data-module-id="{user_id}">Follow User</a>
 *
 */
this.ckan.module('follow', function($) {
	return {
		/* options object can be extended using data-module-* attributes */
		options : {
			action: null,
			type: null,
			id: null,
			loading: false
		},

		/* Initialises the module setting up elements and event listeners.
		 *
		 * Returns nothing.
		 */
		initialize: function () {
			$.proxyAll(this, /_on/);
			this.el.on('click', this._onClick);
		},

		/* Handles the clicking of the follow button
		 *
		 * event - An event object.
		 *
		 * Returns nothing.
		 */
		_onClick: function(event) {
			var options = this.options;
			if (
				options.action
				&& options.type
				&& options.id
				&& !options.loading
			) {
				event.preventDefault();
				var client = this.sandbox.client;
				var path = options.action + '_' + options.type;
				options.loading = true;
				this.el.addClass('disabled');
				client.call('POST', path, { id : options.id }, this._onClickLoaded, this._onClickFailed);
			}
		},

		/* Fired after the call to the API to either follow or unfollow
		 *
		 * json - The return json from the follow / unfollow API call
		 *
		 * Returns nothing.
		 */
		_onClickLoaded: function(json) {
			var options = this.options;
			var sandbox = this.sandbox;
			var oldAction = options.action;
			options.loading = false;
			this.el.removeClass('disabled');
                        /* We don't try to detect whether searches are already followed; maintain this UX here */
                        if (options.type != 'search') { 
			  if (options.action == 'follow') {
			      	options.action = 'unfollow';
				this.el.html('<i class="fa fa-times-circle"></i> ' + this._('Unfollow')).removeClass('btn-success').addClass('btn-danger');
			  } else {
				options.action = 'follow';
				this.el.html('<i class="fa fa-plus-circle"></i> ' + this._('Follow')).removeClass('btn-danger').addClass('btn-success');
			  }
                        }
                        else {
                          if (options.action == 'follow') {
                                $('.flash-messages').append('<div class=\"alert fade in alert-info\">' + this._('Saved search') + ' <a class=\"close\" href=\"#\">&#215;</a></div>');
                          } else {
                                $('#' + options.id).remove();
                          }
                        }
			sandbox.publish('follow-' + oldAction + '-' + options.id);
		},

                /* Fired if the call to the API failed
                 *
                 * json - The return json from the follow / unfollow API call
                 *
                 * Returns nothing.
                 */
                _onClickFailed: function(json) {
                        var options = this.options;
                        var sandbox = this.sandbox;
                        var oldAction = options.action;
                        options.loading = false;
                        this.el.removeClass('disabled');
                        if (options.type == 'search' && (json.responseJSON.error.search_string || json.responseJSON.error.follower)) {
                          errorText = (json.responseJSON.error.search_string || json.responseJSON.error.follower)[0];
                        }
                        else errorText = json.statusText;
                        $('.flash-messages').append('<div class=\"alert fade in alert-error\">' + this._('Follow') + ' ' + this._(options.type) + ' ' + this._('failed') + ': ' + errorText + '<a class=\"close\" href=\"#\">&#215;</a></div>');
                        sandbox.publish('follow-' + oldAction + '-' + options.id);
                }
	};
});

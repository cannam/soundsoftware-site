/**
 * This file is a part of redmine_tags
 * redMine plugin, that adds tagging support.
 *
 * Copyright (c) 2010 Aleksey V Zapparov AKA ixti
 *
 * redmine_tags is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * redmine_tags is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with redmine_tags.  If not, see <http://www.gnu.org/licenses/>.
 */

var Redmine = Redmine || {};

Redmine.TagsInput = Class.create({
  initialize: function(element, update) {
    this.element  = $(element);
    this.input    = new Element('input', { 'type': 'text', 'autocomplete': 'off', 'size': 10 });
    this.button   = new Element('span', { 'class': 'tag-add icon icon-add' });
    this.tags     = new Hash();
    
		this.update = update;
		
		var uri_params = window.location.href.toQueryParams();
		if (uri_params["project[tag_list]"] != undefined){
			this.addTag(uri_params["project[tag_list]"], true);			
		};
		
    Event.observe(this.button, 'click', this.readTags.bind(this));
    Event.observe(this.input, 'keypress', this.onKeyPress.bindAsEventListener(this));

    this.element.insert({ 'after': this.input });
    this.input.insert({ 'after': this.button });
    this.addTagsList(this.element.value);
  },

  readTags: function() {		
    this.addTagsList(this.input.value);
    this.input.value = '';
		if(this.update){
			submitForm();
		};
  },

  onKeyPress: function(event) {
    if (Event.KEY_RETURN == event.keyCode) {
      this.readTags(event);
      Event.stop(event);			
    }
  },

  addTag: function(tag, noSubmit) {
    if (tag.blank() || this.tags.get(tag)) return;

		if(noSubmit==undefined){noSubmit=false;}

    var button = new Element('span', { 'class': 'tag-delete icon icon-del' });
    var label  = new Element('span', { 'class': 'tag-label' }).insert(tag).insert(button);

    this.tags.set(tag, 1);
    this.element.value = this.getTagsList();
    this.element.insert({ 'before': label });

		if(noSubmit==false){
			if(this.update){
				console.log('It is true??');
				console.log(this.update);
				submitForm();
			};
		};

    Event.observe(button, 'click', function(){
      this.tags.unset(tag);
      this.element.value = this.getTagsList();
      label.remove();
		  if(this.update){submitForm();};
    }.bind(this));
  },

  addTagsList: function(tags_list) {
    var tags = tags_list.split(',');
    for (var i = 0; i < tags.length; i++) {
      this.addTag(tags[i].strip());
    }
  },

  getTagsList: function() {
    return this.tags.keys().join(',');
  },

  autocomplete: function(container, url) {
    new Ajax.Autocompleter(this.input, container, url, {
      'minChars': 1,
      'frequency': 0.5,
      'paramName': 'q',
      'updateElement': function(el) {
        this.input.value = el.getAttribute('name');
        this.readTags();
      }.bind(this)
    });
  }
});


function observeIssueTagsField(url) {
  new Redmine.TagsInput('issue_tag_list', false).autocomplete('issue_tag_candidates', url);
}

function observeProjectTagsField(url, update) {
	if(!update) { 
			var update = false;
		};
	
	new Redmine.TagsInput('project_tag_list', update).autocomplete('project_tag_candidates', url);
}
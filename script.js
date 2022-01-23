function tag(q){return document.getElementsByTagName(q)[0]}
function id(q){return document.getElementById(q)}
function $(q){return document.querySelector(q)}
function $$(q){return document.querySelectorAll(q)}

var posts=[];
var tags=[];
var tags_count={};
var search_loaded=false;
var marked_posts=[];
var user_input=false;

function load(){
	var objs=$$('main li');
	for(var i=0; i<objs.length; i++){
		var text=objs[i].lastElementChild.innerHTML.toLowerCase().split('\n');
		posts[i]={
				'created':text[1],
				'tags':text[2].split(' '),
				obj:objs[i],
		};
	}
}

function load_search(){
	posts.forEach(function(post){
		var matches=post.obj.innerHTML.match(/class="(title|intro)">.*/g);
		for(var i=0; i<matches.length; i++){
			if(matches[i][7]=='t'){
				post.title=matches[i].slice(14,-4).toLowerCase();
			} else {
				post.intro=matches[i].slice(14,-7).toLowerCase();
			}
		}
	});
	search_loaded=true;
}


function addTags(){
	id('tags').innerHTML=tags.map(function(tag){
		return '<a href="#tag:'+tag+'">'+tag+'&nbsp;('+tags_count[tag]+')</a>';
	}).join(' ');
}

function init(){
	load();
	posts.forEach(function(post){
		post.tags.forEach(function(tag){
			if(tag)
				if(tags_count[tag])
					tags_count[tag]++;
				else
					tags_count[tag]=1;
		});
	});
	tags=Object.keys(tags_count).sort();
	addTags();
	id('search').oninput=function(){
		if(this.value) {
			user_input=true;
			location.hash='#search:'+this.value;
		} else {
			show_sorted('created',-1);
			location.hash='';
		}
	}
	window.onhashchange=function(){
		var params=decodeURIComponent(location.hash).split(':');
		//if(params.length!=2) return;
		id('search').value='';
		if(marked_posts){
			unmark_posts(marked_posts);
			marked_posts=[];
		}
		switch(params[0]){
			case '#tag':
				show_tag(params[1]);
			break;
			case '#search':
				id('search').value=params[1];
				search(params[1]);
				user_input=false;
			break;
			default:
				show_sorted('created',-1,window.posts,10);
		}
	}
	window.onhashchange();
};

function init2(){
	posts.forEach(function(post){
		var as=post.obj.getElementsByTagName('a');
		as[0].onkeypress=function(e){
			if(e.key==' '){
				e.target.click();
				return false;
			}
		};
		for(var i=1; i<as.length; i++){
			as[i].tabIndex=-1;
		};
	});
}

function display(posts, max, skip){
	var par=$('main ol');
	var docFrag = document.createDocumentFragment();
	if(!skip) {
		par.innerHTML='';
		skip=0;
	}
	if(max) {
		if(max<posts.length)
			setTimeout(function(){display(posts, 0, max)},1100)
		max=Math.min(max, posts.length);
	} else
		max=posts.length;
	for(var i=skip; i<max; i++)
		docFrag.appendChild(posts[i].obj);
	par.appendChild(docFrag);
};

function show_sorted(param, sort_order=1, posts=window.posts, max=0){
	display(posts.sort(function(a,b){
		if ( a[param] < b[param] ) return -1*sort_order;
		if ( a[param] > b[param] ) return 1*sort_order;
		return 0;
	}), max);
}

function unmark_posts(posts){
	posts.forEach(function(post){
		post.obj.querySelector('.title').innerHTML=post.title;
		post.obj.querySelector('.intro').innerHTML=post.intro;
	});
}

function search(text, posts=window.posts){
	if(!search_loaded){load_search()};
	text=text.toLowerCase();
	marked_posts=posts.map(function(post){
			var pos;
			if((pos=post.title.indexOf(text))>-1)
				post.rel=1e6+pos+'a';
			else if((pos=post.intro.indexOf(text))>-1)
				post.rel=2e6+pos+'a';
			else
				post.rel=false;
			return post;
		}).filter(function(post){
			return post.rel;
		}).map(function(post){
			if(post.rel[0]=='1'){
				post.obj.querySelector('.title').innerHTML=post.title.replace(text,'<mark>'+text+'</mark>');
			} else {
				post.obj.querySelector('.intro').innerHTML=post.intro.replace(text,'<mark>'+text+'</mark>');
			}
			return post;
		});
	show_sorted('rel',1,marked_posts);
	if(user_input && marked_posts.length==1){
		marked_posts[0].obj.getElementsByTagName('a')[0].click();
	}
}

function show_tag(text, posts=window.posts){
	show_sorted('created',-1, posts.filter(function(post){
			return post.tags.indexOf(text)>-1;
		})
	);
}

init();
setTimeout(init2,1100);

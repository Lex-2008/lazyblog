function tag(q){return document.getElementsByTagName(q)[0]}
function id(q){return document.getElementById(q)}
function $(q){return document.querySelector(q)}
function $$(q){return document.querySelectorAll(q)}

var obj_loaded=false;
var search_loaded=false;
var marked_posts=[];
var user_input=false;
var display_timer=0;
var loading=true;

function load_obj(){
	var objs=$$('main li');
	for(var i=0; i<objs.length; i++){
		posts[i].obj=objs[i];
	}
	obj_loaded=true;
}

function load_search(){
	if(!obj_loaded) load_obj();
	for(var i=0; i<posts.length; i++){
		post=posts[i];
		post.titleObj=post.obj.querySelector('.title');
		post.titleHTML=post.titleObj.innerHTML;
		post.titleText=post.titleObj.innerText;
		post.introObj=post.obj.querySelector('.intro div');
		post.introHTML=post.introObj.innerHTML;
		post.introText=post.introObj.innerText;
	}
	search_loaded=true;
}

function addTags(){
	id('tags').innerHTML=tags.map(function(tag){
		return '<a href="#tag:'+tag+'">'+tag+'&nbsp;('+tags_count[tag]+')</a>';
	}).join(' ');
}

function searchTags(text){
	id('tags').innerHTML=tags./*filter(function(tag){
		return tag.indexOf(text)>-1;
	}).*/map(function(tag){
		const visibility=tag.indexOf(text)==-1?'style="visibility:hidden"':'';
		return '<a href="#tag:'+tag+'" '+visibility+'>'+tag.replace(text,'<mark>'+text+'</mark>')+'&nbsp;('+tags_count[tag]+')</a>';
	}).join(' ');
}

function init(){
	id('search').oninput=function(){
		if(this.value) {
			user_input=true;
			location.hash='#search:'+this.value;
		} else {
			show_sorted('created',-1);
			location.hash='';
		}
	}
	id('search').focus();
	window.onhashchange=function(){
		var params=decodeURIComponent(location.hash).split(':');
		//if(params.length!=2) return;
		id('search').value='';
		if(marked_posts){
			unmark_posts(marked_posts);
			marked_posts=[];
			addTags();
		}
		switch(params[0]){
			case '#tag':
				show_tag(params[1]);
			break;
			case '#search':
				id('search').value=params[1];
				search(params[1]);
				searchTags(params[1]);
				user_input=false;
			break;
			case '#random':
				if(!obj_loaded) load_obj();
				window.posts[Math.floor(Math.random()*posts.length)].obj.querySelector('.title').click();
			break;
			default:
				show_sorted('created',-1,window.posts);
		}
	}
	if(location.hash.length>2){
		window.onhashchange();
	}
	loading = false;
};

function init2(){
	if(!obj_loaded){load_obj()};
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
	if(false && !loading && document.startViewTransition){
		document.startViewTransition(() => x_display(posts, max, skip));
	}
	else {
		x_display(posts, max, skip);
	}
}

function x_display(posts, max, skip){
	clearTimeout(display_timer);
	var par=$('main ol');
	var docFrag = document.createDocumentFragment();
	if(!skip) {
		par.innerHTML='';
		skip=0;
	}
	if(max) {
		if(max<posts.length)
			display_timer=setTimeout(function(){display(posts, 0, max)},1100);
		max=Math.min(max, posts.length);
	} else
		max=posts.length;
	for(var i=skip; i<max; i++)
		docFrag.appendChild(posts[i].obj);
	par.appendChild(docFrag);
};

function show_sorted(param, sort_order=1, posts=window.posts, max=0){
	if(!obj_loaded){load_obj()};
	display(posts.sort(function(a,b){
		if ( a[param] < b[param] ) return -1*sort_order;
		if ( a[param] > b[param] ) return 1*sort_order;
		return 0;
	}), max);
}

function unmark_posts(posts){
	posts.forEach(function(post){
		post.titleObj.innerHTML=post.titleHTML;
		post.introObj.innerHTML=post.introHTML;
	});
}

function search(text, posts=window.posts){
	if(!search_loaded){load_search()};
	var re=new RegExp(text, "i");
	marked_posts=posts.map(function(post){
			var m;
			if(m=re.exec(post.titleText))
				post.rel=1e6+m.index+'a';
			else if(m=re.exec(post.introText))
				post.rel=2e6+m.index+'a';
			else
				post.rel=false;
			return post;
		}).filter(function(post){
			return post.rel;
		}).map(function(post){
			if(post.rel[0]=='1'){
				post.titleObj.innerHTML=post.titleText.replace(re,'<mark>$&</mark>');
			} else {
				post.introObj.innerHTML=post.introText.replace(re,'<mark>$&</mark>');
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

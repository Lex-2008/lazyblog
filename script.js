function id(q){return document.getElementById(q)}
function $(q){return document.querySelector(q)}

var posts=[];
var tags=[];
var tags_count={};

function load(){
	var objs=id('content').children;
	for(var i=0; i<objs.length; i++){
		var text=objs[i].lastElementChild.innerHTML.toLowerCase().split('\n');
		posts[i]={
				'title':text[1],
				'created':text[2],
				'modified':text[3],
				'tags':text[4].split(' '),
				'intro':text[5],
				obj:objs[i],
		};
	}
}

function addTags(){
	var ui='';
	tags.forEach(function(tag){
		ui+='<a href="#tag:'+tag+'" data-count="'+tags_count[tag]+'">'+tag+'</a> ';
	});
	id('tags').innerHTML=ui;
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
	$('#controls input[type="search"]').oninput=function(){
		if(this.value) {
			search(this.value);
			location.hash='#search:'+this.value;
		} else {
			show_sorted('created',-1);
			location.hash='';
		}
	}
	window.onhashchange=function(){
		var params=location.hash.split(':');
		//if(params.length!=2) return;
		$('#controls input[type="search"]').value='';
		switch(params[0]){
			case '#sort':
				var sort_orders={'title':1,'created':-1,'modified':-1};
				show_sorted(params[1],sort_orders[params[1]]);
			break;
			case '#tag':
				show_tag(params[1]);
			break;
			case '#search':
				$('#controls input[type="search"]').value=params[1];
				search(params[1]);
			break;
			default:
				show_sorted('created',-1,window.posts,10);
		}
	}
	window.onhashchange();
};

function init2(){
	posts.forEach(function(post){
		post.obj.querySelector('h2 > a').onkeypress=function(e){
			if(e.key==' '){
				e.target.click();
				return false;
			}
		};
		post.obj.querySelector('.readmore > a').tabIndex=-1;
	});
}

function display(posts, max){
	var par=id('content');
	var docFrag = document.createDocumentFragment();
	par.innerHTML='';
	if(max) {
		if(max<posts.length)
			setTimeout(function(){display(posts)},200)
		max=Math.min(max, posts.length);
	} else
		max=posts.length;
	for(var i=0; i<max; i++)
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

function search(text, posts=window.posts){
	text=text.toLowerCase();
	show_sorted('rel',1,
		posts.map(function(post){
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
		})
	);
}

function show_tag(text, posts=window.posts){
	show_sorted('created',-1, posts.filter(function(post){
			return post.tags.indexOf(text)>-1;
		})
	);
}

init();
setTimeout(init2,300);

package
{
	import com.greensock.events.LoaderEvent;
	import com.greensock.loading.ImageLoader;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	import leelib.util.flvEncoder.FileStreamFlvEncoder;
	import leelib.util.flvEncoder.VideoPayloadMakerAlchemy;

	public class RenderVideo extends Sprite
	{
		
		private var videoWidth:int;
		private var videoHeight:int;
		
		private var folder:File;
		
		private var flvEncoder:FileStreamFlvEncoder;
		
		private var urlList:Vector.<String>;
		private var imageIndex:int;
		
		private var field:TextField;
		
		
		public function RenderVideo()
		{
			field = new TextField();
			field.autoSize = TextFieldAutoSize.LEFT;
			field.defaultTextFormat = new TextFormat("_sans", 20, 0xffffff, true);
			field.x = 20;
			field.y = 20;
			addChild(field);
		}
		
		public function init():void
		{
			var directory:File = File.desktopDirectory.resolvePath("TimeLapse");
			directory.browseForDirectory("Select a folder with images");
			directory.addEventListener(Event.SELECT, selectRenderFolder);
		}
		
		private function selectRenderFolder(e:Event):void
		{
			folder = File(e.target);
			
			//images
			urlList = new Vector.<String>();
			var files:Array = folder.getDirectoryListing();
			for (var i:uint = 0; i < files.length; i++) {
				if (!files[i].isDirectory 
					&& (files[i].extension == 'png' || files[i].extension == 'jpg' || files[i].extension == 'gif')) { 
					urlList.push(files[i].url);
				}
			}
			
			//encoder
			
			//init
			imageIndex = 0;
			loadImage();
		}
		
		private function loadImage():void
		{
			var loader:ImageLoader = new ImageLoader(urlList[imageIndex], { onComplete:encode });
			loader.load();
			
			field.text = "Encoding frames: " + String(int(imageIndex+1)) + " / " + urlList.length;
		}
		
		private function encode(e:LoaderEvent):void
		{	
			var loader:ImageLoader = ImageLoader(e.target);
			
			if (!flvEncoder) {
				var file:File = folder.resolvePath("TimeLapse_"+folder.name+".flv");
				flvEncoder = new FileStreamFlvEncoder(file, 15);
				flvEncoder.setVideoProperties(loader.content.width, loader.content.height, VideoPayloadMakerAlchemy);
				flvEncoder.fileStream.openAsync(flvEncoder.file, FileMode.UPDATE);
				flvEncoder.start();
			}
			flvEncoder.addFrame(loader.rawContent.bitmapData, null);
			
			loader.dispose(true);
			
			imageIndex++;
			
			if (imageIndex < urlList.length) {
				loadImage();
			} else {
				finish();
			}
		}
		
		private function finish():void
		{	
			flvEncoder.updateDurationMetadata();
			flvEncoder.fileStream.close();
			flvEncoder.kill();
		}
		
	}
}

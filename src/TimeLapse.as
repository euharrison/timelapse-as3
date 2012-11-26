package
{
	import com.greensock.TweenMax;
	import com.greensock.easing.Expo;
	import com.greensock.easing.Linear;
	import com.greensock.events.LoaderEvent;
	import com.greensock.loading.ImageLoader;
	
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.StageDisplayState;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.media.Camera;
	import flash.media.Video;
	import flash.ui.Keyboard;
	import flash.ui.Mouse;
	
	
	[SWF(width='1280',height='720',backgroundColor='#000000',frameRate='15')]
	
	
	/**
	 * TODO
	 * - Interface de controle
	 * - Resolução da camera dinamica
	 * - Pasta de destino (resolver)
	 * - Exportar video em formato H264
	 */ 
	
	public class TimeLapse extends Sprite
	{
		
		private const VIDEO_WIDTH:int = 1280;
		private const VIDEO_HEIGHT:int = 720;
		
		private var createPNGDelay:int = 5;
		private var timelapseFPS:int = 15;
		
		private var camera:Camera;
		private var video:Video;
		
		private var progressBar:Sprite;
		private var folderName:String;
		
		private var photosURL:Vector.<String>;
		private var currentIndex:int;
		private var previousImageLoader:ImageLoader;
		private var currentImageLoader:ImageLoader;
		
		private var timelapseLayer:Sprite;
		private var cameraLayer:Sprite;
		
		private var render:RenderVideo;
		
		
		public function TimeLapse()
		{
			photosURL = new Vector.<String>();
			currentIndex = 0;
			
			folderName = "TimeLapse/" + getDateName() + "/";
			
			//controles
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyUp);
			
			//layers
			timelapseLayer = new Sprite();
			timelapseLayer.scaleX = -1;
			timelapseLayer.x = stage.stageWidth;
			addChild(timelapseLayer);
			cameraLayer = new Sprite();
			cameraLayer.scaleX = cameraLayer.scaleY = 0.25;
			cameraLayer.x = 50;
			cameraLayer.y = 50;
			cameraLayer.graphics.beginFill(0x000000);
			cameraLayer.graphics.drawRect(-5, -5, VIDEO_WIDTH+10, VIDEO_HEIGHT+25);
			cameraLayer.addEventListener(MouseEvent.MOUSE_DOWN, startDragCamera);
			stage.addEventListener(MouseEvent.MOUSE_UP, stopDragCamera);
			addChild(cameraLayer);
			
			//camera
			camera = Camera.getCamera();
			camera.setMode(VIDEO_WIDTH, VIDEO_HEIGHT, 15);
			video = new Video(camera.width, camera.height);
			video.attachCamera(camera);
			video.scaleX = -1;
			video.x = video.width;
			cameraLayer.addChild(video);
			
			//progreesBar
			progressBar = new Sprite();
			progressBar.graphics.beginFill(0xff0000);
			progressBar.graphics.drawRect(0,0,camera.width,10);
			progressBar.y = camera.height+5;
			cameraLayer.addChild(progressBar);
			
			//render
			render = new RenderVideo();
		}
		
		private function init():void
		{
			createPNG();
			nextFrame();
		}
		
		private function createPNG():void
		{
			var data:BitmapData = new BitmapData(video.width, video.height, false);
			data.draw(video);
			var file:File = File.desktopDirectory.resolvePath(folderName + getDateName() + ".png");
			var stream:FileStream = new FileStream();
			stream.open(file, FileMode.WRITE);
			//usando o alchemy pelo swc precompilado
			PNGEncoder2.level = CompressionLevel.FAST;
			stream.writeBytes(PNGEncoder2.encode(data));
			//usando somente flash
			//stream.writeBytes(PNGEncoderOptimized.encode(data));
			stream.close();
			photosURL.push(file.url);
			
			//gc
			data.dispose();
			
			//delay para o efeito visual pois trava ao criar o PNG
			TweenMax.delayedCall(0.2, afterCreatePNG);
		}
		
		private function afterCreatePNG():void
		{
			//blink
			TweenMax.fromTo(video, .5, { colorMatrixFilter:{contrast:3, brightness:3} }, { colorMatrixFilter:{contrast:1, brightness:1}, ease:Expo.easeInOut });
			
			//progressBar
			TweenMax.fromTo(progressBar, createPNGDelay, { scaleX:1 } , { scaleX:0, ease:Linear.easeNone });
			
			//timer para a proxima foto
			TweenMax.delayedCall(createPNGDelay, createPNG);
		}
		
		private function nextFrame():void
		{
			currentImageLoader = new ImageLoader(photosURL[currentIndex], { onComplete:completeNextFrame });
			currentImageLoader.load();
			timelapseLayer.addChild(currentImageLoader.content);
		}
		
		private function completeNextFrame(e:LoaderEvent):void
		{
			if (previousImageLoader) previousImageLoader.dispose(true);
			previousImageLoader = currentImageLoader;
			
			//next index
			currentIndex++;
			if (currentIndex >= photosURL.length) currentIndex = 0;
			
			//timer next image
			TweenMax.delayedCall(1/timelapseFPS, nextFrame);
		}
		
		private function getDateName():String
		{
			var date:Date = new Date();
			return "" + date.fullYear + "-" + addZero(date.month+1) + "-" + addZero(date.date) + " " + addZero(date.hours) + "." + addZero(date.minutes) + "." + addZero(date.seconds);
		}
		
		private function addZero(value:int):String
		{
			return (value<10) ? "0"+value : ""+value;
		}
		
		//
		// Controles
		//
		
		
		private function startDragCamera(e:MouseEvent):void
		{
			cameraLayer.startDrag();
		}
		
		private function stopDragCamera(e:MouseEvent):void
		{
			cameraLayer.stopDrag();
		}
		
		private function keyUp(e:KeyboardEvent):void
		{
			switch (e.keyCode)
			{
				case Keyboard.ENTER:
					init();
					break;
				case Keyboard.F:
					stage.displayState = (stage.displayState == StageDisplayState.NORMAL) ? StageDisplayState.FULL_SCREEN_INTERACTIVE : StageDisplayState.NORMAL;
					break;
				case Keyboard.M:
					e.ctrlKey ? Mouse.hide() : Mouse.show();
					break;
				case Keyboard.MINUS: // -
					if (createPNGDelay>1) createPNGDelay--;
					break;
				case Keyboard.EQUAL: // +
					createPNGDelay++;
					break;
				case Keyboard.NUMBER_9: // (
					if (timelapseFPS>1) timelapseFPS--;
					break;
				case Keyboard.NUMBER_0: // )
					if (timelapseFPS<30) timelapseFPS++;
					break;
				case Keyboard.R:
					addChild(render);
					render.init();
					break;
			}
		}

	}
}